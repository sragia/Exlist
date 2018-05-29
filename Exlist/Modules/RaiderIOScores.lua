local key = "raiderIO"
local prio = 20
local Exlist = Exlist
local L = Exlist.L
local CM = C_ChallengeMode
local table,print, string= table,print, string
local WrapTextInColorCode = WrapTextInColorCode
local RaiderIO = RaiderIO
local UnitLevel = UnitLevel
local DUNGEON_NAME = {
  (CM.GetMapInfo(206)), -- NL
  (CM.GetMapInfo(200)), -- HoV
  (CM.GetMapInfo(198)), -- DHT
  (CM.GetMapInfo(207)), -- VOTW
  (CM.GetMapInfo(199)), -- BRH
  (CM.GetMapInfo(208)), -- MOS
  (CM.GetMapInfo(209)), -- ARC
  (CM.GetMapInfo(197)), -- EOA
  (CM.GetMapInfo(210)), -- COS
  (CM.GetMapInfo(233)), -- CATH
  (CM.GetMapInfo(239)), -- SEAT
  (CM.GetMapInfo(227)), -- LOWER
  (CM.GetMapInfo(234)), -- UPPER
}


local function Updater(event,...)
  if not RaiderIO then
    Exlist.Debug("RaiderIO not installed -",key)
    return
  elseif UnitLevel("player") < Exlist.CONSTANTS.MAX_CHARACTER_LEVEL then
    return
  end

  local playerInfo = RaiderIO.GetScore('player')
  if playerInfo then
    local score = playerInfo.allScore
    local scoreColor = Exlist.ColorDecToHex(RaiderIO.GetScoreColor(score))
    local dungeonLvls = {}
    local d = playerInfo.dungeons
    for i=1,#d do
      table.insert(dungeonLvls,{name=DUNGEON_NAME[i],lvl = d[i],})
    end
    table.sort(dungeonLvls,function(a,b) return a.lvl > b.lvl end)
    local t = {
      playerName = playerInfo.name,
      score = score,
      dungeons = dungeonLvls,
      scoreColor = scoreColor,
    }
    Exlist.UpdateChar(key,t)

  else
    Exlist.Debug("Did not find any data -",key)
  end
end

local function Linegenerator(tooltip,data,character)
  if not data then return end
  local info = {
    character = character,
    moduleName = key,
    priority = prio,
    titleName = L["RaiderIO M+ score"],
    data = data.score
  }
  local s = {}
  for i=1,#data.dungeons do
    s[i] = {data.dungeons[i].name,data.dungeons[i].lvl}
  end
  local sideTooltip = {body = s,title=WrapTextInColorCode(string.format("%s - %s",data.playerName,data.score),"ffffd200")}
  info.OnEnter = Exlist.CreateSideTooltip()
  info.OnEnterData = sideTooltip
  info.OnLeave = Exlist.DisposeSideTooltip()
  Exlist.AddData(info)
end

local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
end

local data = {
  name = L['RaiderIO M+ Score'],
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"PLAYER_ENTERING_WORLD","PLAYER_ENTERING_WORLD_DELAYED"},
  description = L["Uses Raider.IO addon (Needs to be installed) to display your m+ score"],
  weeklyReset = false,
  -- modernize = Modernize
}

Exlist.RegisterModule(data)
