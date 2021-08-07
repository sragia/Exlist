local key = "maw"
local prio = 15
local Exlist = Exlist
local L = Exlist.L
local colors = Exlist.Colors

local TORGHAST_WIDGETS = {
  {name = 2925, level = 2930}, -- Fracture Chambers
  {name = 2926, level = 2932}, -- Skoldus Hall
  {name = 2924, level = 2934}, -- Soulforges
  {name = 2927, level = 2936}, -- Coldheart Interstitia
  {name = 2928, level = 2938}, -- Mort'regar
  {name = 2929, level = 2940} -- The Upper Reaches
}

local function GetTorghastProgress()
  local data = {}
  for _, widgets in ipairs(TORGHAST_WIDGETS) do
    local nameData = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(widgets.name)
    if (nameData.shownState == 1) then
      -- Available this week
      local levelData = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(widgets.level)
      if (levelData) then
        table.insert(
          data,
          {
            name = nameData.text,
            level = levelData.shownState == 1 and levelData.text or
              string.format("|c%s%s|r", colors.torghastAvailable, L["Available"])
          }
        )
      end
    end
  end

  return data
end

local function Updater(event, widgetInfo)
  local character = UnitName("player")
  local realm = GetRealmName()
  local data = Exlist.GetCharacterTableKey(realm, character, key)
  if (UnitLevel("player") < Exlist.constants.MAX_CHARACTER_LEVEL) then
    return
  end
  data.torghast = GetTorghastProgress() or data.torghast
  Exlist.UpdateChar(key, data)
end

local function Linegenerator(tooltip, data, character)
  if (not data) then
    return
  end

  -- Torghast
  if (data.torghast) then
    for i, data in ipairs(data.torghast) do
      local info = {
        character = character,
        priority = prio + (i / 10),
        moduleName = key .. data.name,
        titleName = data.name:gsub("|n", ""),
        data = data.level
      }
      Exlist.AddData(info)
    end
  end
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
local function ResetHandler(resetType)\
  local realms = Exlist.GetRealmNames()
  for _, realm in ipairs(realms) do
    local characters = Exlist.GetRealmCharacters(realm)
    for _, character in ipairs(characters) do
      local data = Exlist.GetCharacterTableKey(realm, character, key)
      local essentials = Exlist.GetCharacterEssentials(realm, character)
      if (essentials.level == 60) then
        if (resetType == "weekly") then
          data.torghast = {}
        end
        Exlist.UpdateChar(key, data, character, realm)
      end
    end
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
  name = L["Maw"],
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"UPDATE_UI_WIDGET", "PLAYER_ENTERING_WORLD"},
  weeklyReset = true,
  dailyReset = true,
  description = L["Track eye of the jailer buff for the player and Torghast"],
  -- globallgenerator = GlobalLineGenerator,
  -- type = 'customTooltip'
  -- modernize = Modernize,
  -- init = init,
  -- override = true,
  specialResetHandle = ResetHandler
}

Exlist.RegisterModule(data)
