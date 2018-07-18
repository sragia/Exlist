local key = "mythicPlus"
local prio = 50
local CM = C_ChallengeMode
local C_MythicPlus = C_MythicPlus
local Exlist = Exlist
local colors = Exlist.Colors
local L = Exlist.L
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local table, ipairs = table, ipairs

local mapTimes = {
  --[mapId] = {+1Time,+2Time,+3Time} in seconds
  --BFA
  [244] = {2340,1872,1405}, -- Atal'dazar
  [245] = {1800,1440,1080}, -- Freehold
  [246] = {1980,1584,1188}, -- Tol Dagor
  [247] = {2340,1872,1405}, -- The MOTHERLODE!!
  [248] = {2340,1872,1405}, -- Waycrest Manor
  [249] = {1800,1440,1080}, -- Kings' Rest
  [250] = {1980,1584,1188}, -- Temple of Sethraliss
  [251] = {1800,1440,1080}, -- The Underrot
  [252] = {2340,1872,1405}, -- Shrine of the Storm
  [353] = {2340,1872,1405}, -- Siege of Boralus

  [197] = {2100,1680,1260}, -- Eye of Azshara
  [198] = {1800,1440,1080}, -- Darkheart Thicket
  [199] = {2340,1872,1405}, -- BRH
  [200] = {2700,2160,1620}, -- HoV
  [206] = {1980,1584,1188}, -- Nelth
  [207] = {1980,1584,1188}, -- VotW
  [208] = {1440,1152,864},  -- Maw
  [209] = {2700,2160,1620}, -- Arc
  [210] = {1800,1440,1080}, -- CoS
  [227] = {2340,1872,1404}, -- Kara: Lower
  [233] = {2100,1680,1260}, -- Cath
  [234] = {2100,1680,1260}, -- Kara: Upper
  [239] = {2100,1680,1260}, -- Seat
}

local function Updater(event)
  C_MythicPlus.RequestMapInfo() -- request update
  local mapIDs = CM.GetMapTable()
  local bestLvl = 0
  local bestLvlMap = ""
  local bestMapId = 0
  local mapsDone = {}
  local savedAffixes
  for i = 1, #mapIDs do
    local bestTime, level = C_MythicPlus.GetWeeklyBestForMap(mapIDs[i])
    if level and level > bestLvl then
      -- currently best map
      bestLvl = level
      bestMapId = mapIDs[i]
      bestLvlMap = CM.GetMapUIInfo(mapIDs[i])
      table.insert(mapsDone,{mapId = mapIDs[i], name = bestLvlMap,level = level, time = bestTime})
    elseif level and level > 0 then
      local mapName = CM.GetMapUIInfo(mapIDs[i])
      table.insert(mapsDone,{mapId = mapIDs[i], name = mapName,level = level, time = bestTime})
    end
  end
  table.sort(mapsDone,function(a,b) return a.level > b.level end)
  local t= {
    ["bestLvl"] = bestLvl,
    ["bestLvlMap"] = bestLvlMap,
    ["mapId"] = bestMapId,
    ["mapsDone"] = mapsDone
  }
  Exlist.UpdateChar(key,t)
end

local function MythicPlusTimeString(time,mapId)
  if not time or not mapId then return end
  local times = mapTimes[mapId] or {}
  local rstring = ""
  local secTime = time
  local colors = colors.mythicplus.times
  for i=1, #times do
    if secTime > times[i] then
      if i == 1 then return WrapTextInColorCode("("..L["Depleted"]..") " .. Exlist.FormatTime(secTime),colors[i])
      else return WrapTextInColorCode("(+".. (i-1) .. ") " .. Exlist.FormatTime(secTime),colors[i]) end
    end
  end
  return WrapTextInColorCode("(+3) " .. Exlist.FormatTime(time),colors[#colors])
end

local function Linegenerator(tooltip,data,character)
  if not data or data.bestLvl < 2 then return end
  local settings = Exlist.ConfigDB.settings
  local dungeonName = settings.shortenInfo and Exlist.ShortenedMPlus[data.mapId] or data.bestLvlMap
  local info = {
    character = character,
    moduleName = key,
    priority = prio,
    titleName = L["Best Mythic+"],
    data = "+" .. data.bestLvl .. " " .. dungeonName,
  }

  if data.mapsDone and #data.mapsDone > 0 then
    local sideTooltip = {title = WrapTextInColorCode(L["Mythic+"],colors.sideTooltipTitle), body = {}}
    local maps = data.mapsDone
    for i=1, #maps do
      table.insert(sideTooltip.body,{"+" .. maps[i].level .. " " .. maps[i].name,MythicPlusTimeString(maps[i].time,maps[i].mapId)})
    end
    info.OnEnter = Exlist.CreateSideTooltip()
    info.OnEnterData = sideTooltip
    info.OnLeave = Exlist.DisposeSideTooltip()
  end
  Exlist.AddData(info)
end

local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
  if not data.mapId then
    CM.RequestMapInfo() -- request update
    local mapIDs = CM.GetMapTable()
    for i,id in ipairs(mapIDs) do
      if data.bestLvlMap == (CM.GetMapUIInfo(id)) then
        Exlist.Debug("Added mapId",id)
        data.mapId = id
        break
      end
    end
  end
  return data
end

local data = {
  name = L['Mythic+'],
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"CHALLENGE_MODE_MAPS_UPDATE","CHALLENGE_MODE_LEADERS_UPDATE","PLAYER_ENTERING_WORLD"},
  description = L["Tracks highest completed mythic+ in a week and all highest level runs per dungeon"],
  weeklyReset = true,
  modernize = Modernize
}

Exlist.RegisterModule(data)
