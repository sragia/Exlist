local key = "missions"
local prio = 6
local CG = C_Garrison
local LE_FOLLOWER_TYPE_GARRISON_7_0 = LE_FOLLOWER_TYPE_GARRISON_7_0
local time, table, strlen, string, type, math = time, table, strlen, string, type, math
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local GetCurrencyInfo = GetCurrencyInfo
local GetMoneyString = GetMoneyString
local Exlist = Exlist

local unknownIcon = "Interface\\ICONS\\INV_Misc_QuestionMark"

local function Updater(event)
  if event == "Exlist_DELAY" then return end
  local mission = CG.GetInProgressMissions(LE_FOLLOWER_TYPE_GARRISON_7_0)
  local availMissions = CG.GetAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_7_0)
  local t =  {
  }
  if mission then
    -- in progress/finished
    for i = 1, #mission do
      local endTime = mission[i].missionEndTime
      local successChance = CG.GetMissionSuccessChance(mission[i].missionID)
      -- rewards
      local r = mission[i].rewards
      local reward = {}
      for i=1,#r do
        if r[i].currencyID and r[i].currencyID == 0 then
          -- gold
          reward.icon = r[i].icon
          reward.quantity = GetMoneyString(r[i].quantity)
          reward.name = r[i].title
        elseif r[i].itemID then
          -- item
          local itemInfo = Exlist.GetCachedItemInfo(r[i].itemID)
          reward.quantity = r[i].quantity
          reward.name = itemInfo.name
          reward.icon = itemInfo.texture
        elseif r[i].currencyID then
          local name,_,icon = GetCurrencyInfo(r[i].currencyID)
          reward.quantity = r[i].quantity
          reward.name = name
          reward.icon = icon
        end
      end
      local mis = {
        ["name"] = mission[i].name,
        ["endTime"] = endTime,
        ["rewards"] = reward,
        ["successChance"] = successChance
      }
      table.insert(t, mis)
    end
  end
  if availMissions then
    -- available
    for i = 1, #availMissions do
      -- rewards
      local r = availMissions[i].rewards
      local reward = {}
      for i=1,#r do
        if r[i].currencyID and r[i].currencyID == 0 then
          -- gold
          reward.icon = r[i].icon
          reward.quantity = GetMoneyString(r[i].quantity)
          reward.name = r[i].title
        elseif r[i].itemID then
          -- item
          local itemInfo = Exlist.GetCachedItemInfo(r[i].itemID)
          reward.quantity = r[i].quantity
          reward.name = itemInfo.name
          reward.icon = itemInfo.texture
        elseif r[i].currencyID then
          local name,_,icon = GetCurrencyInfo(r[i].currencyID)
          reward.quantity = r[i].quantity
          reward.name = name
          reward.icon = icon
        elseif r[i].followerXP then
          reward.quantity = 1
          reward.icon = r[i].icon
          reward.name = r[i].title
        end
      end
      local mis = {
        ["name"] = availMissions[i].name,
        ["rewards"] = reward
      }
      table.insert(t, mis)
    end
  end
  if #t > 0 then
    Exlist.UpdateChar(key,t)
  end
end

local function missionStrings(source,hasSuccess)
  local t = {}
  local col = "ffffd200"
  if type(source) ~= "table" then return end
  for i=1,#source do
    if hasSuccess then
      local ti = time()
      if source[i].endTime > ti then
        table.insert(t,{WrapTextInColorCode(source[i].name,col),string.format("Time Left: %s (%i%%)",Exlist.TimeLeftColor((source[i].endTime - ti) or 0,{1800,7200},{"FF00FF00","FFf4a142","fff44141"}),source[i].successChance)})
      else
        table.insert(t,{WrapTextInColorCode(source[i].name,col),string.format("%i%%",source[i].successChance)})
      end
    else
      table.insert(t,{WrapTextInColorCode(source[i].name,col),""})
    end
    local reward = source[i].rewards
    local rewardString = ""
    if type(reward.quantity) == "number" and reward.quantity > 1 then
      rewardString = string.format("%ix|T%s:15:15|t %s",reward.quantity or "",reward.icon or unknownIcon,reward.name or "Unknown")
    elseif type(reward.quantity) == "string" then
      rewardString = string.format("|T%s:15:15|t%s",reward.icon or unknownIcon,reward.quantity or "")
    else
      rewardString = string.format("|T%s:15:15|t %s",reward.icon or unknownIcon,reward.name or "Unknown")
    end
    table.insert(t,{"Reward: " .. rewardString,""})
  end
  return t
end

local function Linegenerator(tooltip,data,character)
  local t = time()
  local m = data
  if not m then return end
  local info = {
    character = character,
    priority = prio,
    moduleName = key,
    titleName = "Missions"
  }

  local available,inprogress,done = {},{},{}
  local ip = 0
  local completed = 0
  for i=1,#m do
    if m[i].endTime then
      ip = ip + 1
      if t >= m[i].endTime then
        completed = completed + 1
        table.insert(done,m[i])
      else
        table.insert(inprogress,m[i])
      end
    else
      table.insert(available,m[i])
    end
  end
  if completed > 0 then completed = "|cFF00FF00" .. completed end
  local t2 = string.format("%s/%i",completed,ip) or ""
  info.data = t2
  local sideTooltip = {body={},title = WrapTextInColorCode("Order Hall Missions","ffffd200")}
  if #done > 0 then
    table.insert(sideTooltip.body,{WrapTextInColorCode("Completed","FF00FF00"),"",{"headerseparator"}})
    local t = missionStrings(done,true)
    for i=1,#t do
      table.insert(sideTooltip.body,t[i])
    end
  end
  if #inprogress > 0 then
    table.insert(sideTooltip.body,{WrapTextInColorCode("In Progress","FFf48642"),"",{"headerseparator"}})
    local t = missionStrings(inprogress,true)
    for i=1,#t do
      table.insert(sideTooltip.body,t[i])
    end
  end
  if #available > 0 then
    table.insert(sideTooltip.body,{WrapTextInColorCode("Available","FFefe704"),"",{"headerseparator"}})
    local t = missionStrings(available)
    for i=1,#t do
      table.insert(sideTooltip.body,t[i])
    end
  end
  info.OnEnter = Exlist.CreateSideTooltip()
  info.OnEnterData = sideTooltip
  info.OnLeave = Exlist.DisposeSideTooltip()

  Exlist.AddData(info)
end

local data = {
  name = 'Missions',
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"GARRISON_MISSION_COMPLETE_RESPONSE","GARRISON_MISSION_STARTED","GARRISON_MISSION_NPC_OPENED"},
  description = "Garrison mission progress",
  weeklyReset = false
}

Exlist.RegisterModule(data)
