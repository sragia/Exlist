local key = "azerite"
local prio = 30
local Exlist = Exlist
local L = Exlist.L
local C_AzeriteItem = C_AzeriteItem
local colors = Exlist.Colors
--local strings = Exlist.Strings

local function GetAzeriteInfo()
  if not C_AzeriteItem.HasActiveAzeriteItem() then return end
  local itemLocation = C_AzeriteItem.FindActiveAzeriteItem()
  local xp,maxXp = C_AzeriteItem.GetAzeriteItemXPInfo(itemLocation)
  local powerLevel = C_AzeriteItem.GetPowerLevel(itemLocation)
  local t = {
    xp = xp,
    maxXp = maxXp,
    powerLevel = powerLevel,
  }
  return t
end

local function Updater(event)
  Exlist.UpdateChar(key,GetAzeriteInfo())
end

local function Linegenerator(tooltip,data,character)
  if not data then return end
  local info = {
    character = character,
    priority = prio,
    moduleName = key,
    titleName = L["Azerite Power"],
    data = string.format("|c%s%s:|r %i",colors.faded,L["Level"],data.powerLevel),
    OnEnter = Exlist.CreateSideTooltip(),
    OnEnterData = {
      title = WrapTextInColorCode(L["Azerite Power"], colors.sideTooltipTitle),
      body = {
        { L["Progress"], string.format("%.1f%% (%i/%i)",(data.xp/data.maxXp)*100,data.xp,data.maxXp)},
        { L["Level"],data.powerLevel },
      }
    },
    OnLeave = Exlist.DisposeSideTooltip(),
  }
  Exlist.AddData(info)
end

--[[
local function GlobalLineGenerator(tooltip,data)

end
]]

--[[
local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
end
]]

--[[
local function init()
  -- code that will run before any other function
end
]]

--[[
local function ResetHandler(resetType)
  -- code that will be run at reset for this module
  -- instead of just wiping all data that is keyed 
  -- by this module key
end
]]

local data = {
  name = L['Azerite'],
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"AZERITE_ITEM_EXPERIENCE_CHANGED","AZERITE_ITEM_POWER_LEVEL_CHANGED"},
  weeklyReset = false,
  dailyReset = false,
  description = L["<TMP> Tracks Azerite Item's current level and progress"],
  -- globallgenerator = GlobalLineGenerator,
  -- modernize = Modernize,
  -- init = init,  
  -- override = true,
  -- specialResetHandle = ResetHandler

}

Exlist.RegisterModule(data)
