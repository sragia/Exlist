local key = "dungeons"
local prio =  10
local NUMBER_OF_DUNGEONS_LEGION = 13
local GetNumSavedInstances, GetSavedInstanceInfo = GetNumSavedInstances, GetSavedInstanceInfo
local WrapTextInColorCode = WrapTextInColorCode
local pairs, table = pairs, table
local Exlist = Exlist
--[[ TODO:
  LOCALIZE THIS
]]
local function Updater(event)
  local dungeonList = {
    ['Assault on Violet Hold'] = false,
    ['Black Rook Hold'] = false,
    ['Cathedral of Eternal Night'] = false,
    ['Court of Stars'] = false,
    ['Darkheart Thicket'] = false,
    ['Eye of Azshara'] = false,
    ['Halls of Valor'] = false,
    ['Maw of Souls'] = false,
    ["Neltharion's Lair"] = false,
    ['Return to Karazhan'] = false,
    ['The Arcway'] = false,
    ['Vault of the Wardens'] = false,
    ['Seat of the Triumvirate'] = false
  }
  local t = {
    ['done'] = 0,
    ['max'] = NUMBER_OF_DUNGEONS_LEGION,
    ['dungeonList'] = dungeonList
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
  if not data or data.done == 0 then return end
  local info = {
    character = character,
    moduleName = key,
    priority = prio,
    titleName = WrapTextInColorCode('Dungeons',"ffc1c1c1"),
    data = data.done..'/'..data.max,
  }
  local sideTooltip = {title = WrapTextInColorCode("Mythic Dungeons","ffffd200"), body = {}}
  for name,locked in pairs(data.dungeonList) do
    table.insert(sideTooltip.body,{name,locked and WrapTextInColorCode("Defeated", "FFFF0000") or  WrapTextInColorCode("Available", "FF00FF00")})
  end
  info.OnEnter = Exlist.CreateSideTooltip()
  info.OnEnterData = sideTooltip
  info.OnLeave = Exlist.DisposeSideTooltip()
  Exlist.AddData(info)
end

local data = {
  name = 'Dungeons',
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"UPDATE_INSTANCE_INFO","PLAYER_ENTERING_WORLD"},
  description = "Tracks weekly completed mythic dungeons",
  weeklyReset = true
}

Exlist.RegisterModule(data)
