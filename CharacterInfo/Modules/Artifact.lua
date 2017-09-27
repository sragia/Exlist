local key = "artifact"
local LAD = LibStub("LibArtifactData-1.0")
local AK_MAX_LEVEL = 40
local CG = C_Garrison
local OrderHallType = LE_GARRISON_TYPE_7_0
local IsAddOnLoaded, LoadAddOn = IsAddOnLoaded, LoadAddOn
local string, date, time = string, date, time
local table, tonumber = table, tonumber
local UnitName, GetRealmName = UnitName, GetRealmName
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local CharacterInfo = CharacterInfo


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
  local todayDate = date("*t", time()).day
  local currentAP = LAD:GetAcquiredArtifactPower(LAD:GetActiveArtifactID())
  aptable = aptable or {}
  local tableSize = #aptable
  if aptable then
    if todayDate ~= lastCheck then
      -- first check of the day
      if tableSize == 7 then
        for i = 1, tableSize - 1 do
          aptable[i] = aptable[i + 1]
        end
        aptable[7] = currentAP
      else
        table.insert(aptable, currentAP)
      end
    end
  else
    table.insert(aptable, currentAP)
  end
  return aptable, currentAP, todayDate
end

local function Updater(event)
  if not IsAddOnLoaded("LibArtifactData-1.0") then LoadAddOn("LibArtifactData-1.0") end
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
  if CharacterInfo.DB then
    table.dailyAP = {}
    local chk = CharacterInfo.DB[realm][name].artifact and CharacterInfo.DB[realm][name].artifact.dailyAP and CharacterInfo.DB[realm][name].artifact.dailyAP[currentArtifactID] and CharacterInfo.DB[realm][name].artifact.dailyAP[currentArtifactID].dateChecked or nil
    local apT = CharacterInfo.DB[realm][name].artifact and CharacterInfo.DB[realm][name].artifact.dailyAP and CharacterInfo.DB[realm][name].artifact.dailyAP[currentArtifactID] and CharacterInfo.DB[realm][name].artifact.dailyAP[currentArtifactID].apDays or nil
    local aptable, currentAP, dateChecked = GetAPperDay(chk, apT)
    table.dailyAP = CharacterInfo.DB[realm][name].artifact and CharacterInfo.DB[realm][name].artifact.dailyAP or {}
    table.dailyAP[currentArtifactID] = {
      apDays = aptable,
      dateChecked = dateChecked,
      currentAP = currentAP
    }
  end
  CharacterInfo.UpdateChar(key,table)
end

local function Linegenerator(tooltip,data)
  if not data then return end
  local l = CharacterInfo.AddLine(tooltip,{"Artifact",WrapTextInColorCode("Rank: ", "ffb2b2b2")..data.traits})
  local sideTooltip = {body= {}, title=WrapTextInColorCode("Artifact Weapon", "ffffd200")}
  table.insert(sideTooltip.body,{WrapTextInColorCode("Artifact Power: ", "ffb2b2b2"),CharacterInfo.ShortenNumber(data.AP.curr, 1) .. '/' .. CharacterInfo.ShortenNumber(data.AP.max, 1)})
  table.insert(sideTooltip.body,{WrapTextInColorCode("Artifact Knowledge level: ", "ffb2b2b2"), data.knowledge.level})

  local next = tonumber(data.knowledge.next)
  local nextIn = next and next - time or nil
  if nextIn and nextIn > 0 then
    table.insert(sideTooltip.body,{WrapTextInColorCode("Next In: ", "ffb2b2b2"), SecondsToTime(nextIn)})
  elseif nextIn then
    table.insert(sideTooltip.body,{WrapTextInColorCode("Next In: ", "ffb2b2b2"), WrapTextInColorCode("Ready!", "ff62f442")})
  end
  if data.dailyAP and data.currentID then
    local dailyAP = data.dailyAP[data.currentID]
    table.insert(sideTooltip.body,{WrapTextInColorCode("Artifact Power (Today): ", "ffb2b2b2"), CharacterInfo.ShortenNumber(dailyAP.currentAP - dailyAP.apDays[#dailyAP.apDays], 2)})
    table.insert(sideTooltip.body,{WrapTextInColorCode("Artifact Power (This Week): ", "ffb2b2b2"), CharacterInfo.ShortenNumber(dailyAP.currentAP - dailyAP.apDays[1], 2)})
    table.insert(sideTooltip.body,{WrapTextInColorCode("Artifact Power (Per day): ", "ffb2b2b2"), CharacterInfo.ShortenNumber((dailyAP.currentAP - dailyAP.apDays[1]) / #dailyAP.apDays, 2)})
  end

  CharacterInfo.AddScript(tooltip,l,nil,"OnEnter", CharacterInfo.CreateSideTooltip(), sideTooltip)
  CharacterInfo.AddScript(tooltip,l,nil,"OnLeave", CharacterInfo.DisposeSideTooltip())
  local time = time()
  local next = tonumber(data.knowledge.next)
  local nextIn = next and next - time or nil
  if nextIn and not (nextIn > 0) then
    CharacterInfo.AddLine(tooltip,{"", WrapTextInColorCode("New Knowledge level is ready!", "ff62f442")})
  end
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
CharacterInfo.RegisterModule(data)
