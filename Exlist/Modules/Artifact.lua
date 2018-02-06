local key = "artifact"
local LAD 
local AK_MAX_LEVEL = 40
local CG = C_Garrison
local OrderHallType = LE_GARRISON_TYPE_7_0
local IsAddOnLoaded, LoadAddOn = IsAddOnLoaded, LoadAddOn
local string, date, time = string, date, time
local table, tonumber = table, tonumber
local UnitName, GetRealmName = UnitName, GetRealmName
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local Exlist = Exlist


local ArtifactInfo = function()
  local loaded = IsAddOnLoaded('LibArtifactData-1.0') or LoadAddOn('LibArtifactData-1.0')
  if not loaded then return end
  
  local artifactID, unspentPower, power, maxPower, powerForNextRank, numRanksPurchased, numRanksPurchasable
  if not LAD:GetActiveArtifactID() then
    LAD:ForceUpdate()
  end
  artifactID, unspentPower, power, maxPower, powerForNextRank, numRanksPurchased, numRanksPurchasable = LAD:GetArtifactPower(LAD:GetActiveArtifactID())
  --[[
    artifactID - artifact ID
    unspentPower - power that I havent spent ( same as power until you have power to put in point)
    power - power i have put in for this rank
    maxPower - full power to complete
    powerForNextRank - remaining power to complete
    numRanksPurchased - Ranks atm
    numRanksPurchasable - Available ranks to purchase
    ]]
  if not power or not maxPower then
    power = 0
    maxPower = 1
  end
  local r = {
    ['id'] = artifactID,
    ['unspentPower'] = unspentPower,
    ['power'] = power,
    ['maxPower'] = maxPower,
    ['powNextRank'] = powerForNextRank,
    ['ranks'] = numRanksPurchased,
    ['availableRanks'] = numRanksPurchasable
  }
  return r
end

local GetNextAK = function()
  local currLevel = LAD:GetArtifactKnowledge()
  if currLevel >= AK_MAX_LEVEL then return end
  local shipments = CG.GetLooseShipments(OrderHallType)
  if shipments then
    for i = 1, #shipments do
      local name, _, _, shipmentsReady, _, creationTime, duration, _ = CG.GetLandingPageShipmentInfoByContainerID(shipments[i])
      if name and string.find(name, "Artifact Research") then
        if shipmentsReady > 0 then return 0 end
        return creationTime + duration
      end
    end
  end
end

local function GetAPperDay(lastCheck, aptable)
  if not IsAddOnLoaded("LibArtifactData-1.0") then LoadAddOn("LibArtifactData-1.0") end
  if not LAD:GetActiveArtifactID() then return end
  local todayDate = date("*t", time()).yday
  local currentAP = LAD:GetAcquiredArtifactPower(LAD:GetActiveArtifactID())
  aptable = aptable or {}
  lastCheck = lastCheck or 0
  local tableSize = #aptable
  if aptable then
    local dayDiff = todayDate-lastCheck
    if dayDiff > 350 then
      -- just dont deal with new year, too much work
      if tableSize == 7 then
        for i = 1, tableSize - 1 do
          aptable[i] = aptable[i + 1]
        end
        aptable[7] = currentAP
      else
        table.insert(aptable, currentAP)
      end
    elseif dayDiff > 0 then
      -- first check of the day
      for c=1,dayDiff do
        local value = currentAP
        if c < dayDiff then
          -- skipped a day
          value = 0
        end
        if tableSize == 7 then
          for i = 1, tableSize - 1 do
            aptable[i] = aptable[i + 1]
          end
          aptable[7] = value
        else
          table.insert(aptable, value)
        end
      end
    end
  else
    table.insert(aptable, currentAP)
  end
  return aptable, currentAP, todayDate
end

local function Updater(event)
  if not IsAddOnLoaded("LibArtifactData-1.0") then LoadAddOn("LibArtifactData-1.0") end
  if not LAD then LAD = LibStub("LibArtifactData-1.0") end
  if not LAD:GetActiveArtifactID() then return end
  local name = UnitName('player')
  local realm = GetRealmName()
  local currentArtifactID = LAD:GetActiveArtifactID()
  --[[ artifact:
          traits
          AP for next trait (now/max - %% mby)
          knowledge (current - next in ..)
        ]]
  local table = {}
  local a = ArtifactInfo()
  if a then
    table.currentID = currentArtifactID
    table.traits = a.ranks
    table.AP = {
      ["curr"] = a.power,
      ["max"] = a.maxPower,
      ["perc"] = (a.power / a.maxPower) * 100
    }
    table.knowledge = {
      ["level"] = LAD:GetArtifactKnowledge(),
      ["next"] = GetNextAK() -- check nil
    }
    if Exlist.DB then
      table.dailyAP = {}
      local chk = Exlist.DB[realm][name].artifact and Exlist.DB[realm][name].artifact.dailyAP and Exlist.DB[realm][name].artifact.dailyAP[currentArtifactID] and Exlist.DB[realm][name].artifact.dailyAP[currentArtifactID].dateChecked or nil
      local apT = Exlist.DB[realm][name].artifact and Exlist.DB[realm][name].artifact.dailyAP and Exlist.DB[realm][name].artifact.dailyAP[currentArtifactID] and Exlist.DB[realm][name].artifact.dailyAP[currentArtifactID].apDays or nil
      local aptable, currentAP, dateChecked = GetAPperDay(chk, apT)
      table.dailyAP = Exlist.DB[realm][name].artifact and Exlist.DB[realm][name].artifact.dailyAP or {}
      table.dailyAP[currentArtifactID] = {
        apDays = aptable,
        dateChecked = dateChecked,
        currentAP = currentAP
      }
    end
    Exlist.UpdateChar(key,table)
  end
end

local function Linegenerator(tooltip,data,character)
  if not data then return end
  local info = {
    character = character,
    moduleName = key,
    titleName = "Artifact",
    data = WrapTextInColorCode("Rank: ", "ffb2b2b2")..data.traits,
  }
  local sideTooltip = {body= {}, title=WrapTextInColorCode("Artifact Weapon", "ffffd200")}
  table.insert(sideTooltip.body,{WrapTextInColorCode("Artifact Power: ", "ffb2b2b2"),Exlist.ShortenNumber(data.AP.curr, 1) .. '/' .. Exlist.ShortenNumber(data.AP.max, 1)})
  table.insert(sideTooltip.body,{WrapTextInColorCode("Artifact Knowledge level: ", "ffb2b2b2"), data.knowledge.level})

  local next = tonumber(data.knowledge.next)
  local nextIn = next and next - time or nil
  if nextIn and nextIn > 0 then
    table.insert(sideTooltip.body,{WrapTextInColorCode("Next In: ", "ffb2b2b2"), SecondsToTime(nextIn)})
  elseif nextIn then
    table.insert(sideTooltip.body,{WrapTextInColorCode("Next In: ", "ffb2b2b2"), WrapTextInColorCode("Ready!", "ff62f442")})
  end          
  info.OnEnter = Exlist.CreateSideTooltip()
  info.OnEnterData = sideTooltip
  info.OnLeave = Exlist.DisposeSideTooltip()
  Exlist.AddData(tooltip,info)
end

local data = {
  name = "Artifact",
  key = key,
  linegenerator = Linegenerator,
  priority = 1,
  updater = Updater,
  event = {"ARTIFACT_UPDATE"},
  weeklyReset = false
}
Exlist.RegisterModule(data)
