local key = "mythicPlus"
local prio = 4
local CM = C_ChallengeMode
local Exlist = Exlist
local WrapTextInColorCode, SecondsToTime = WrapTextInColorCode, SecondsToTime
local table = table

local mapTimes = {
  --[mapId] = {+3Time,+2Time,+1Time} in seconds
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
  CM.RequestMapInfo() -- request update
  local mapIDs = CM.GetMapTable()
  local bestLvl = 0
  local bestLvlMap = ""
  local bestMapId = 0
  local mapsDone = {}
  local affixes
  for i = 1, #mapIDs do
    local _, bestTime, level, affixIDs = CM.GetMapPlayerStats(mapIDs[i])
    if level and level > bestLvl then
      -- currently best map
      affixes = affixIDs
      bestLvl = level
      bestMapId = mapIDs[i]
      bestLvlMap = CM.GetMapInfo(mapIDs[i])
      table.insert(mapsDone,{mapId = mapIDs[i], name = bestLvlMap,level = level, time = bestTime})
    elseif level and level > 0 then
      local mapName = CM.GetMapInfo(mapIDs[i])
      table.insert(mapsDone,{mapId = mapIDs[i], name = mapName,level = level, time = bestTime})
    end
  end
  table.sort(mapsDone,function(a,b) return a.level > b.level end)
  -- add affixes to global table
  local savedAffixes = Exlist.GetCharacterTableKey('global','global',"mythicKey")
  if #savedAffixes < 3 and affixes then
    for i=1,#affixes do
      local name, desc, icon = CM.GetAffixInfo(affixes[i])
      Exlist.Debug("Adding Affix- ID:",affixes[i]," name:",name," icon:",icon," i:",i,"key:",key)
      savedAffixes[i] = {name = name, icon = icon, desc = desc}
    end
    Exlist.UpdateChar("mythicKey",savedAffixes,'global','global')
  end
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
  local secTime = time/1000
  local colors = {"ffbfbfbf","fffaff00","fffbdb00","fffacd0c"}
  for i=1, #times do
    if secTime > times[i] then
      if i == 1 then return WrapTextInColorCode("(Depleted) " .. Exlist.FormatTimeMilliseconds(time),colors[i])
      else return WrapTextInColorCode("(+".. (i-1) .. ") " .. Exlist.FormatTimeMilliseconds(time),colors[i]) end
    end
  end
  return WrapTextInColorCode("(+3) " .. Exlist.FormatTimeMilliseconds(time),colors[#colors])
end

local function Linegenerator(tooltip,data,character)
  if not data or data.bestLvl < 2 then return end
  local settings = Exlist.ConfigDB.settings
  local dungeonName = settings.shortenInfo and Exlist.ShortenedMPlus[data.mapId] or data.bestLvlMap
  local info = {
    character = character,
    moduleName = key,
    priority = prio,
    titleName = "Best Mythic+",
    data = "+" .. data.bestLvl .. " " .. dungeonName,
  }

  if data.mapsDone and #data.mapsDone > 0 then
    local sideTooltip = {title = WrapTextInColorCode("Mythic+","ffffd200"), body = {}}
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
      if data.bestLvlMap == (CM.GetMapInfo(id)) then
        Exlist.Debug("Added mapId",id)
        data.mapId = id
        break
      end
    end
  end
  return data
end

local data = {
  name = 'Mythic+',
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"CHALLENGE_MODE_MAPS_UPDATE","CHALLENGE_MODE_LEADERS_UPDATE","PLAYER_ENTERING_WORLD"},
  description = "Tracks highest completed mythic+ in a week and all highest level runs per dungeon",
  weeklyReset = true,
  modernize = Modernize  
}

Exlist.RegisterModule(data)
