local key = "maw"
local prio = 15
local Exlist = Exlist
local L = Exlist.L
--local colors = Exlist.Colors
--local strings = Exlist.Strings

local MAW_WIDGETS = {
  [2359] = 2873,
  [2360] = 2874,
  [2361] = 2875,
  [2362] = 2876,
  [2363] = 2877
}

local EOJ_STAGES = {
  [2359] = 0,
  [2360] = 1,
  [2361] = 2,
  [2362] = 3,
  [2363] = 4
}

local STAGE_COLORS = {
  [0] = "ffffffff",
  [1] = "fffbffb5",
  [2] = "fffce914",
  [3] = "ffff8000",
  [4] = "ffff0000"
}

local function GetStageString(stage)
  return string.format("|c%s%s %i|r", STAGE_COLORS[stage or 0], L["Tier"], stage)
end

local function GetEyeOfTheJailerProgress(widgetId)
  local info = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo(widgetId)
  local stage = EOJ_STAGES[widgetId] or 0
  if (info.barValue == 0) then
    -- Returns as 0 when returning to Oribos
    -- Cant catch it by zoneId as we are still in maw theoretically
    return false
  end
  local stageProgress = info.barValue - info.barMin
  return {
    stage = stage or 0,
    stageProgress = stageProgress > 0 and stageProgress or 0,
    stageMax = info.barMax - info.barMin,
    tooltip = info.tooltip
  }
end

local function FindEyeOfTheJailerWidget()
  for widgetId, shownWidgetId in pairs(MAW_WIDGETS) do
    local info = C_UIWidgetManager.GetTextureWithAnimationVisualizationInfo(shownWidgetId)

    if (info and info.shownState == 1) then
      return GetEyeOfTheJailerProgress(widgetId)
    end
  end
  return false
end

local function Updater(event, widgetInfo)
  local character = UnitName("player")
  local realm = GetRealmName()
  local data = Exlist.GetCharacterTableKey(realm, character, key)
  if (event == "UPDATE_UI_WIDGET") then
    local widgetId = widgetInfo and widgetInfo.widgetID
    if (widgetInfo and MAW_WIDGETS[widgetId]) then
      local widget = MAW_WIDGETS[widgetId]
      local widgetInfo = C_UIWidgetManager.GetTextureWithAnimationVisualizationInfo(widget)
      if (widgetInfo and widgetInfo.shownState == 1) then
        data.eoj = GetEyeOfTheJailerProgress(widgetId) or data.eoj
      end
    end
  else
    local data = FindEyeOfTheJailerWidget()

    if (data) then
      data.eoj = data
    end
  end
  Exlist.UpdateChar(key, data)
end

local function Linegenerator(tooltip, data, character)
  if (not data or not data.eoj) then
    return
  end
  local info = {
    character = character,
    priority = prio,
    moduleName = key,
    titleName = L["Eye of the Jailer"],
    data = string.format(
      "%s %.1f%%",
      GetStageString(data.eoj.stage),
      (data.eoj.stageProgress / data.eoj.stageMax) * 100
    )
    -- colOff = 0,
    -- dontResize = false,
    -- pulseAnim = false,
    -- OnClick = function() end,
    -- OnClickData = {},
  }

  if (data.eoj.tooltip) then
    info.OnEnter = Exlist.CreateSideTooltip()
    info.OnEnterData = {
      body = {
        data.eoj.tooltip
      },
      title = GetStageString(data.eoj.stage)
    }
    info.OnLeave = Exlist.DisposeSideTooltip()
  end

  Exlist.AddData(info)
end

--[[
local function GlobalLineGenerator(tooltip,data)

end
]]
--[[
local function customGenerator(tooltip, data)

end
]]
--[[
local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
  return data
end
]]
--[[
local function init()
  -- code that will run before any other function
end
]]
local function ResetHandler(resetType)
  -- code that will be run at reset for this module
  -- instead of just wiping all data that is keyed
  -- by this module key
  local realms = Exlist.GetRealmNames()
  for _, realm in ipairs(realms) do
    local characters = Exlist.GetRealmCharacters(realm)
    for _, character in ipairs(characters) do
      local data = Exlist.GetCharacterTableKey(realm, character, key)
      local essentials = Exlist.GetCharacterEssentials(realm, character)
      if (essentials.level == 60) then
        -- Reset Eye of the Jailer debuff progress
        if (resetType == "daily") then
          data.eoj = {
            stage = 0,
            stageProgress = 0,
            stageMax = 1000
          }
        end

        Exlist.UpdateChar(key, data, character, realm)
      end
    end
  end
  -- reset Bonus quest
  if resetType == "weekly" then
    Exlist.ConfigDB.settings.unsortedFolder.weekly.bonusQuestId = nil
  end
end

--[[
local function AddOptions()
  local options = {
    type = "group",
    name = L["Reputations"],
    args = {}
  }
  Exlist.AddModuleOptions(key,options,L["Reputation"])
end
Exlist.ModuleToBeAdded(AddOptions)
]]
local data = {
  name = L["Currency"],
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"UPDATE_UI_WIDGET", "PLAYER_ENTERING_WORLD"},
  weeklyReset = false,
  dailyReset = true,
  description = L["Track eye of the jailer buff for the player"],
  -- globallgenerator = GlobalLineGenerator,
  -- type = 'customTooltip'
  -- modernize = Modernize,
  -- init = init,
  -- override = true,
  specialResetHandle = ResetHandler
}

Exlist.RegisterModule(data)
