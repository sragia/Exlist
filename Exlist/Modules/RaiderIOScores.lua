local key = "raiderIO"
local Exlist = Exlist
local CM = C_ChallengeMode
local table,print= table,print
local WrapTextInColorCode = WrapTextInColorCode
local MAX_CHARACTER_LEVEL = 110
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
      if Exlist.debugMode then print(Exlist.debugString,"RaiderIO not installed -",key) end
    return
  elseif event == "ADDON_LOADED" and ... ~= "RaiderIO" then
    return
  elseif UnitLevel("player") < MAX_CHARACTER_LEVEL then
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
  elseif Exlist.debugMode then
    print(Exlist.debugString,"Did not find any data -",key)
  end
end

local function Linegenerator(tooltip,data)
  if not data then return end
  local line = Exlist.AddLine(tooltip,{"RaiderIO M+ score",data.score})
  local s = {}
  for i=1,#data.dungeons do
    s[i] = {data.dungeons[i].name,data.dungeons[i].lvl}
  end
  local sideTooltip = {body = s,title=WrapTextInColorCode(string.format("%s - %s",data.playerName,data.score),"ffffd200")}
  Exlist.AddScript(tooltip,line,nil,"OnEnter",Exlist.CreateSideTooltip(),sideTooltip)
  Exlist.AddScript(tooltip,line,nil,"OnLeave",Exlist.DisposeSideTooltip())


end

local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
end

local data = {
  name = 'RaiderIO M+ Score',
  key = key,
  linegenerator = Linegenerator,
  priority = 0.5,
  updater = Updater,
  event = {"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_ENTERING_WORLD_DELAYED"},
  weeklyReset = false,
  -- modernize = Modernize
}

Exlist.RegisterModule(data)
