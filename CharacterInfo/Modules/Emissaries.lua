local key = "emissary"
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local time = time
local C_TaskQuest, C_Timer = C_TaskQuest, C_Timer
local GetNumQuestLogEntries, GetQuestLogTitle, GetQuestObjectiveInfo = GetNumQuestLogEntries, GetQuestLogTitle, GetQuestObjectiveInfo
local table = table
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

local function Updater(event)
  if event == "PLAYER_ENTERING_WORLD" then C_Timer.After(20,function() CharacterInfo.SendFakeEvent("PLAYER_ENTERING_WORLD_DELAYED") end)
  elseif event == "QUEST_TURNED_IN" or event ==  "QUEST_REMOVED" then C_Timer.After(5,function() CharacterInfo.SendFakeEvent("PLAYER_ENTERING_WORLD_DELAYED") end)
  end
  local emissaries = {
  }
  local timeNow = time()
  for i = 1, GetNumQuestLogEntries() do
    local title, _, _, _, _, _, _, questID, _, _, _, _, _, isBounty = GetQuestLogTitle(i)
    if isBounty then
      local text, _, completed, current, total = GetQuestObjectiveInfo(questID, 1, false)
      local timeleft = C_TaskQuest.GetQuestTimeLeftMinutes(questID)
      local t = {name = title, current = current, total = total, endTime = timeNow + (timeleft * 60)}
      table.insert(emissaries, t)
    end
  end
  table.sort(emissaries, function(a, b) return a.endTime < b.endTime end)
  CharacterInfo.UpdateChar(key,emissaries)
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
      table.insert(sideTooltip.body, {data[i].name.."("..TimeLeftColor(data[i].endTime - timeNow, {36000, 72000})..")", data[i].current .. "/" .. data[i].total})
      end
    end
    CharacterInfo.AddScript(tooltip,lineNum,nil,"OnEnter", CharacterInfo.CreateSideTooltip(), sideTooltip)
    CharacterInfo.AddScript(tooltip,lineNum,nil,"OnLeave", CharacterInfo.DisposeSideTooltip())
  end
end

local data = {
name = 'Emissary',
key = key,
linegenerator = Linegenerator,
priority = 5,
updater = Updater,
event = {"QUEST_TURNED_IN","PLAYER_ENTERING_WORLD","QUEST_REMOVED","PLAYER_ENTERING_WORLD_DELAYED"},
weeklyReset = false
}

CharacterInfo.RegisterModule(data)
