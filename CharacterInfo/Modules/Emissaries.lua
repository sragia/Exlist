local key = "emissary"
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local time = time
local IsQuestFlaggedCompleted = IsQuestFlaggedCompleted
local C_TaskQuest, C_Timer = C_TaskQuest, C_Timer
local GetNumQuestLogEntries, GetQuestLogTitle, GetQuestObjectiveInfo = GetNumQuestLogEntries, GetQuestLogTitle, GetQuestObjectiveInfo
local table,pairs = table,pairs
local CharacterInfo = CharacterInfo


local function TimeLeftColor(timeLeft, times, col)
  -- times (opt) = {red,orange} upper limit
  -- i.e {100,1000} = 0-100 Green 100-1000 Orange 1000-inf Green
  -- colors (opt) - colors to use
  times = times or {3600, 18000} --default
  local colors = col or {"FFFF0000", "FFe09602", "FF00FF00"} -- default
  for i = 1, #times do
    if timeLeft < times[i] then
      return WrapTextInColorCode(SecondsToTime(timeLeft), colors[i])
    end
  end
  return WrapTextInColorCode(SecondsToTime(timeLeft), colors[#colors])
end

local function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a, b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

local function Updater(event)
  if event == "PLAYER_ENTERING_WORLD" then C_Timer.After(20,function() CharacterInfo.SendFakeEvent("PLAYER_ENTERING_WORLD_DELAYED") end)
  elseif event == "QUEST_TURNED_IN" or event ==  "QUEST_REMOVED" then C_Timer.After(5,function() CharacterInfo.SendFakeEvent("PLAYER_ENTERING_WORLD_DELAYED") end)
  end
  local timeNow = time()
  local emissaries = {
  }
  local gt = CharacterInfo.GetCharacterTableKey("global","global",key)
  local trackedBounties = 0 -- if we already know all bounties
  for questId,info in pairs(gt) do
    -- cleanup
    if info.endTime < timeNow then
      gt[questId] = nil
    else
      trackedBounties = trackedBounties + 1
    end
  end
  if trackedBounties >= 3 then
    -- no need to look through all quests
    for questId, info in pairs(gt) do
      if not IsQuestFlaggedCompleted(questId) then
        local _, _, _, current, total = GetQuestObjectiveInfo(questId, 1, false)
        local t = {name = info.title, current = current, total = total, endTime = info.endTime}
        table.insert(emissaries, t)
      end
    end
  else
    for i = 1, GetNumQuestLogEntries() do
      local title, _, _, _, _, _, _, questID, _, _, _, _, _, isBounty = GetQuestLogTitle(i)
      if isBounty then
        local text, _, completed, current, total = GetQuestObjectiveInfo(questID, 1, false)
        local timeleft = C_TaskQuest.GetQuestTimeLeftMinutes(questID)
        local endTime = timeNow + timeleft * 60
        local t = {name = title, current = current, total = total, endTime = endTime}
        gt[questID] = {title = title, endTime = endTime}
        table.insert(emissaries, t)
      end
    end
  end
  table.sort(emissaries, function(a, b) return a.endTime < b.endTime end)
  CharacterInfo.UpdateChar(key,emissaries)
  CharacterInfo.UpdateChar(key,gt,"global","global")
end

local function Linegenerator(tooltip,data)
  if not data then return end
  local timeNow = time()
  local availableEmissaries = 0
  for i = 1, #data do
    if data[i] and data[i].endTime > timeNow then
      availableEmissaries = availableEmissaries + 1
    end
  end
  if availableEmissaries > 0 then
    local lineNum = CharacterInfo.AddLine(tooltip,{"Available Emissaries ", WrapTextInColorCode(availableEmissaries, "FF00FF00")})
    -- info {} {body = {'1st lane',{'2nd lane', 'side number w/e'}},title = ""}
    local sideTooltip = {title = WrapTextInColorCode("Available Emissaries", "ffffd200"), body = {}}
    local timeLeftColor
    for i = 1, #data do
      if data[i] and data[i].endTime > timeNow then
      table.insert(sideTooltip.body, {data[i].name.."("..TimeLeftColor(data[i].endTime - timeNow, {36000, 72000})..")", (data[i].current or 0) .. "/" .. (data[i].total or 0)})
      end
    end
    CharacterInfo.AddScript(tooltip,lineNum,nil,"OnEnter", CharacterInfo.CreateSideTooltip(), sideTooltip)
    CharacterInfo.AddScript(tooltip,lineNum,nil,"OnLeave", CharacterInfo.DisposeSideTooltip())
  end
end

local function GlobalLineGenerator(tooltip,data)
  local timeNow = time()
  CharacterInfo.AddLine(tooltip,{WrapTextInColorCode("Emissaries","ffffd200")})

  for questId,info in spairs(data or {},function(t,a,b) return t[a].endTime < t[b].endTime end) do
    CharacterInfo.AddLine(tooltip,{info.title,TimeLeftColor(info.endTime - timeNow,{36000, 72000})})
  end
end

local data = {
name = 'Emissary',
key = key,
linegenerator = Linegenerator,
globallgenerator = GlobalLineGenerator,
priority = 5,
updater = Updater,
event = {"QUEST_TURNED_IN","PLAYER_ENTERING_WORLD","QUEST_REMOVED","PLAYER_ENTERING_WORLD_DELAYED"},
weeklyReset = false
}

CharacterInfo.RegisterModule(data)
