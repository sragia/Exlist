local key = "mythicPlus"
local CM = C_ChallengeMode
local CharacterInfo = CharacterInfo
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local table = table

local mapTimes = {
  --[mapId] = {+1Time,+2Time,+3Time} in miliseconds
  [197] = {2100000,1680000,1260000}, -- Eye of Azshara
  [198] = {1800000,1440000,1080000}, -- Darkheart Thicket
  [199] = {2340000,1872000,1405000}, -- BRH
  [200] = {2700000,2160000,1620000}, -- HoV
  [206] = {1980000,1584000,1188000}, -- Nelth
  [207] = {1980000,1584000,1188000}, -- VotW
  [208] = {1440000,1152000,864000}, -- Maw
  [209] = {2700000,2160000,1620000}, -- Arc
  [210] = {1800000,1440000,1080000}, -- CoS
  [227] = {2340000,1872000,1404000}, -- Kara: Lower
  [233] = {2100000,1680000,1260000}, -- Cath
  [234] = {2100000,1680000,1260000}, -- Kara: Upper
  [239] = {2100000,1680000,1260000}, -- Seat
}

local function Updater(event)
  local mapIDs = CM.GetMapTable()
  local bestLvl = 0
  local bestLvlMap = ""
  local mapsDone = {}
  for i = 1, #mapIDs do
    local _, bestTime, level = CM.GetMapPlayerStats(mapIDs[i])
    if level and level > bestLvl then
      -- currently best map
      bestLvl = level
      bestLvlMap = CM.GetMapInfo(mapIDs[i])
      table.insert(mapsDone,{mapId = mapIDs[i], name = bestLvlMap,level = level, time = bestTime})
    elseif level and level > 0 then
      local mapName = CM.GetMapInfo(mapIDs[i])
      table.insert(mapsDone,{mapId = mapIDs[i], name = mapName,level = level, time = bestTime})
    end
  end
  table.sort(mapsDone,function(a,b) return a.level > b.level end)
  local t= {
    ["bestLvl"] = bestLvl,
    ["bestLvlMap"] = bestLvlMap,
    ["mapsDone"] = mapsDone
  }
  CharacterInfo.UpdateChar(key,t)
end

local function MythicPlusTimeString(time,mapId)
  if not time or not mapId then return end
  local times = mapTimes[mapId] or {}
  local rstring = ""
  local colors = {"ffbfbfbf","fffaff00","fffbdb00","fffacd0c"}
  for i=1, #times do
    if time > times[i] then
      if i == 1 then return WrapTextInColorCode("(Depleted) " .. CharacterInfo.FormatTimeMilliseconds(time),colors[i])
      else return WrapTextInColorCode("(+".. (i-1) .. ") " .. CharacterInfo.FormatTimeMilliseconds(time),colors[i]) end
    end
  end
  return WrapTextInColorCode("(+3) " .. CharacterInfo.FormatTimeMilliseconds(time),colors[#colors])
end

local function Linegenerator(tooltip,data)
  if not data or data.bestLvl < 2 then return end
  local line = CharacterInfo.AddLine(tooltip,{"Best Mythic+","+" .. data.bestLvl .. " " .. data.bestLvlMap})
  if data.mapsDone and #data.mapsDone > 0 then
    local sideTooltip = {title = WrapTextInColorCode("Mythic+","ffffd200"), body = {}}
    local maps = data.mapsDone
    for i=1, #maps do
      table.insert(sideTooltip.body,{"+" .. maps[i].level .. " " .. maps[i].name,MythicPlusTimeString(maps[i].time,maps[i].mapId)})
    end
    CharacterInfo.AddScript(tooltip,line,nil,"OnEnter",CharacterInfo.CreateSideTooltip(),sideTooltip)
    CharacterInfo.AddScript(tooltip,line,nil,"OnLeave",CharacterInfo.DisposeSideTooltip())
  end
end

local data = {
  name = 'Mythic+',
  key = key,
  linegenerator = Linegenerator,
  priority = 4,
  updater = Updater,
  event = {"CHALLENGE_MODE_MAPS_UPDATE","CHALLENGE_MODE_LEADERS_UPDATE"},
  weeklyReset = true
}

CharacterInfo.RegisterModule(data)
