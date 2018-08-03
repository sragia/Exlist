local key = "dungeons"
local prio =  110
local L = Exlist.L
local NUMBER_OF_DUNGEONS_LEGION = 13
local GetNumSavedInstances, GetSavedInstanceInfo = GetNumSavedInstances, GetSavedInstanceInfo
local GetLFGDungeonInfo = GetLFGDungeonInfo
local WrapTextInColorCode = WrapTextInColorCode
local pairs, table,ipairs = pairs, table,ipairs
local Exlist = Exlist
local colors = Exlist.Colors
local dungeonNames = {}
local legionDungeons = {
  1208, -- Violet Hold
  1205, -- Black Rock Hold
  1488, -- Cathedral of Eternal Light
  1319, -- Court of Stars
  1202, -- Darkheart Thicket
  1175, -- Eye of Azshara
  1473, -- Halls of Valor
  1192, -- Maw of Souls
  1207, -- Neltharion's Lair
  1190, -- The Arcway
  1044, -- Vault of the Wardens
  1535, -- Seat of the Triumvirate
}
-- BFA
local bfaDungeons = {
  1669, -- Atal'Dazar
  1710, -- Shrine of the Storm
  1695, -- Temple of Sethraliss
  1708, -- The MOTHERLODE!!
  1712, -- The Underrot
  1714, -- Tol Dagor
  1706, -- Waycrest Manor
  1701, -- Siege of Boralus
  1785, -- Kings' Rest
}
local function Updater(event)
  local t = {
    ['done'] = 0,
    ['max'] = Exlist.GetTableNum(dungeonNames),
    ['dungeonList'] = dungeonNames
  }
  for i = 1, GetNumSavedInstances() do
    local name, _, _, _, locked, extended, _, isRaid, _, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
    if not isRaid and difficultyName == 'Mythic' then
      -- dungeons
      if locked then
        t.dungeonList[name] = true
        t.done = t.done + 1
      end
    end
  end
  Exlist.UpdateChar(key,t)
end

local function Linegenerator(tooltip,data,character)
  if not data or data.done < 1 then return end
  local info = {
    character = character,
    moduleName = key,
    priority = prio,
    titleName = WrapTextInColorCode(L['Dungeons'],colors.faded),
    data = data.done..'/'..data.max,
  }
  local sideTooltip = {title = WrapTextInColorCode(L["Mythic Dungeons"],colors.sideTooltipTitle), body = {}}
  for name,locked in pairs(data.dungeonList) do
    table.insert(sideTooltip.body,{name,locked and WrapTextInColorCode(L["Defeated"], colors.completed) or  WrapTextInColorCode(L["Available"], colors.available)})
  end
  info.OnEnter = Exlist.CreateSideTooltip()
  info.OnEnterData = sideTooltip
  info.OnLeave = Exlist.DisposeSideTooltip()
  Exlist.AddData(info)
end

local function init()
  local d = UnitLevel('player') < 120 and legionDungeons or bfaDungeons
  for _,id in ipairs(d) do
    dungeonNames[(GetLFGDungeonInfo(id))] = false
  end
end

local data = {
  name = L['Dungeons'],
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"UPDATE_INSTANCE_INFO","PLAYER_ENTERING_WORLD"},
  description = L["Tracks weekly completed mythic dungeons"],
  weeklyReset = true,
  init = init,
}

Exlist.RegisterModule(data)
