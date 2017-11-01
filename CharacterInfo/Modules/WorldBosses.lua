local key = "worldboss"
local MAX_CHARACTER_LEVEL = 110
local CharacterInfo = CharacterInfo
local worldBossIDs = {
  [42270] = {eid = 1749}, -- Nithogg
  [42269] = {eid = 1756, name = EJ_GetEncounterInfo(1756)}, -- The Soultakers
  [42779] = {eid = 1763}, -- Shar'thos
  [43192] = {eid = 1769}, -- Levantus
  [42819] = {eid = 1770}, -- Humongris
  [43193] = {eid = 1774}, -- Calamir
  [43513] = {eid = 1783}, -- Na'zak the Fiend
  [43448] = {eid = 1789}, -- Drugon the Frostblood
  [43512] = {eid = 1790}, -- Ana-Mouz
  [43985] = {eid = 1795}, -- Flotsam
  [44287] = {eid = 1796}, -- Withered Jim
  [47061] = {eid = 1956, endTime = 0}, -- Apocron
  [46947] = {eid = 1883, endTime = 0}, -- Brutalus
  [46948] = {eid = 1884, endTime = 0}, -- Malificus
  [46945] = {eid = 1885, endTime = 0}, -- Si'vash
}
local BrokenIslesZones = {
	1015, -- Aszuna
	1018, -- Val'Sharah
	1024, -- Highmountain
	1017, -- Stormheim
	1033, -- Suramar
	1021, -- Broken Shore
}
local ArgusZones = {
	1170,
	1135,
	1171,
}
local greaterInvasionPOIId = {
  [5375] = {questId = 49167, eid = 2011}, -- Mistress Alluradel
  [5376] = {questId = 49170, eid = 2013}, -- Occularus
  [5377] = {questId = 49168, eid = 2015}, -- Pit Lord Vilemus
  [5379] = {questId = 49166, eid = 2012}, -- Inquisitor Meto
  [5380] = {questId = 49171, eid = 2014}, -- Sotanathor
  [5381] = {questId = 49169, eid = 2010, name=EJ_GetEncounterInfo(2010)}, -- Matron Foluna
}
local invasionPointPOIId = {
  [5350] = true, -- Sangua
  [5359] = true, -- Cen'gar
  [5360] = true, -- Val
  [5366] = true, -- Bonich
  [5367] = true, -- Aurinor
  [5368] = true, -- Naigtal
  [5369] = true, -- Sangua
  [5370] = true, -- Cen'gar
  [5371] = true, -- Bonich
  [5372] = true, -- Bonich
  [5373] = true, -- Aurinor
  [5374] = true, -- Naigtal
}
local lastUpdate = 0

-- localize
local UnitLevel,GetRealmName,UnitName = UnitLevel,GetRealmName,UnitName
local IsQuestFlaggedCompleted = IsQuestFlaggedCompleted
local WrapTextInColorCode = WrapTextInColorCode
local string,table = string,table
local C_TaskQuest, C_WorldMap, EJ_GetCreatureInfo = C_TaskQuest, C_WorldMap ,EJ_GetCreatureInfo
local pairs,time,select = pairs,time,select
local GetTime = GetTime
local IsInRaid, IsInInstance = IsInRaid, IsInInstance
local GetCurrentMapAreaID, SetMapByID = GetCurrentMapAreaID, SetMapByID
local GetNumMapLandmarks, GetMapLandmarkInfo = GetNumMapLandmarks, GetMapLandmarkInfo

local function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a, b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end
local function GetBrokenShoreBuildings()
  local t = {}
  for i=1,4,1 do
     local name = C_ContributionCollector.GetName(i);
     if (name ~= "") then
        -- get status
        local state, contribed, timeNext = C_ContributionCollector.GetState(i);
        if state == 2 or state == 3 then
          local bonustime = state == 2 and 86400 or 0
          t[i] = {name = name,state = state, timeEnd = timeNext + bonustime}
        else
          t[i] = {name= name, state=state,progress = string.format("%.1f%%",contribed*100)}
        end
     end
  end
  return t
end

local function Updater(event)
  if not( UnitLevel('player') == MAX_CHARACTER_LEVEL ) or
  GetTime() - lastUpdate < 60 or -- throtle update every 10 seconds max
  not WorldMapButton:IsShown() or -- only update when map is open
  IsInRaid() or -- only update when outside of instances
  select(2,IsInInstance()) ~= "none" then
    return
  end
  lastUpdate = GetTime()
  local realm = GetRealmName()
  local name = UnitName('player')
  local t = CharacterInfo.GetCharacterTableKey(realm,name,key)
  local gt = CharacterInfo.GetCharacterTableKey("global","global",key)
  gt.invasions = gt.invasions or {}
  gt.brokenshore = gt.brokenshore or {}
  local timeNow = time()
  local currMapId = GetCurrentMapAreaID()
  -- update brokenshore building
  gt.brokenshore = GetBrokenShoreBuildings()
  -- broken isles world bosses
  for i=1,#BrokenIslesZones do
    SetMapByID(BrokenIslesZones[i])
    local wqs = C_TaskQuest.GetQuestsForPlayerByMapID(BrokenIslesZones[i])
    for _,info in pairs(wqs or {}) do
      if worldBossIDs[info.questId] then
        t[info.questId] = {
          name = worldBossIDs[info.questId].name or select(2,EJ_GetCreatureInfo(1,worldBossIDs[info.questId].eid)),
          defeated = false,
          endTime = worldBossIDs[info.questId].endTime and worldBossIDs[info.questId].endTime==0 and gt.brokenshore[4].timeEnd or (timeNow + (C_TaskQuest.GetQuestTimeLeftMinutes(info.questId)*60))
        }
      end
    end
  end

  -- argus greater invasions
  for i=1,#ArgusZones do
    SetMapByID(ArgusZones[i])
    for j=1,GetNumMapLandmarks() do
      local _,name,desc,_,_,_,_,_,_,_,poiId = GetMapLandmarkInfo(j)
      if greaterInvasionPOIId[poiId] and not t[greaterInvasionPOIId[poiId].questId] then
        local timeLeft = C_WorldMap.GetAreaPOITimeLeft(poiId) or CharacterInfo.GetNextWeeklyResetTime()
        t[greaterInvasionPOIId[poiId].questId] = {
          name = greaterInvasionPOIId[poiId].name or select(2,EJ_GetCreatureInfo(1,greaterInvasionPOIId[poiId].eid)),
          defeated = false,
          endTime = timeNow + timeLeft*60
        }
      elseif invasionPointPOIId[poiId] and not gt.invasions[poiId] then -- assuming that same invasion isn't up in 2 places
        local timeLeft = C_WorldMap.GetAreaPOITimeLeft(poiId)
        gt.invasions[poiId] = {
          name = desc,
          endTime = timeNow + timeLeft * 60,
          map = GetMapNameByID(ArgusZones[i])
        }
      end
    end
  end
  SetMapByID(currMapId)
  -- cleanup table
  for questId,info in pairs(t) do
    if (info.endTime ~= 0 and info.endTime < timeNow) or info.endTime > 1.5*CharacterInfo.GetNextWeeklyResetTime() then
      t[questId] = nil
    end
  end
  for poiId,info in pairs(gt.invasions) do
    if info.endTime < timeNow then
      gt.invasions[poiId] = nil
    end
  end
  -- check if have killed before update
  for questId,info in pairs(worldBossIDs) do
    if IsQuestFlaggedCompleted(questId) then
      if t[questId] then
        t[questId].defeated = true
      else
        t[questId] = {
          name = info.name or select(2,EJ_GetCreatureInfo(1,info.eid)),
          endTime = info.endTime or CharacterInfo.GetNextWeeklyResetTime(),
          defeated = true
        }
      end
    end
  end
  for poi,info in pairs(greaterInvasionPOIId) do
    if IsQuestFlaggedCompleted(info.questId) then
      if t[info.questId] then
        t[info.questId].defeated = true
      else
        t[info.questId] = {
          name = info.name or select(2,EJ_GetCreatureInfo(1,info.eid)),
          endTime = CharacterInfo.GetNextWeeklyResetTime(),
          defeated = true
        }
      end
    end
  end
  CharacterInfo.UpdateChar(key,t)
  CharacterInfo.UpdateChar(key,gt,'global','global')
end

local function Linegenerator(tooltip,data)
  if not data then return end
  local availableWB = 0
  local killed = 0
  local strings = {}
  local timeNow = time()
  for spellId,info in pairs(data) do
    if info.endTime == 0 or info.endTime > timeNow then
      availableWB = availableWB + 1
      killed = info.defeated and killed + 1 or killed
      table.insert(strings,{string.format("%s (%s)",info.name,info.endTime ~= 0 and CharacterInfo.TimeLeftColor(info.endTime-timeNow) or WrapTextInColorCode("Unknown","fff49e42")),
                                          info.defeated and WrapTextInColorCode("Defeated","ffff0000") or WrapTextInColorCode("Available","ff00ff00")})
    end
  end
  if availableWB > 0 then
    local line = CharacterInfo.AddLine(tooltip,{WrapTextInColorCode("World Bosses:","ffc1c1c1"),string.format("%i/%i",killed,availableWB)})
    local sideTooltip = {body = strings,title=WrapTextInColorCode("World Bosses","ffffd200")}
    CharacterInfo.AddScript(tooltip,line,nil,"OnEnter",CharacterInfo.CreateSideTooltip(),sideTooltip)
    CharacterInfo.AddScript(tooltip,line,nil,"OnLeave",CharacterInfo.DisposeSideTooltip())
  end
end

local function GlobalLineGenerator(tooltip,data)
  local timeNow = time()
  CharacterInfo.AddLine(tooltip,{WrapTextInColorCode("Invasion Points","ffffd200")})
  for questId,info in spairs((data.invasions or {}),function(t,a,b) return t[a].endTime < t[b].endTime end) do
    if info.endTime > timeNow then
      CharacterInfo.AddLine(tooltip,{info.name,CharacterInfo.TimeLeftColor(info.endTime - timeNow,{1800, 3600}),WrapTextInColorCode(info.map,"ffc1c1c1")})
    end
  end
  CharacterInfo.AddLine(tooltip,{WrapTextInColorCode("Broken Shore","ffffd200")})
  for i,info in pairs(data.brokenshore or {}) do
    CharacterInfo.AddLine(tooltip,{info.name,info.timeEnd and CharacterInfo.TimeLeftColor(info.timeEnd - timeNow,{1800, 3600}) or info.progress,(info.state == 4 and WrapTextInColorCode("Destroyed","ffa1a1a1") or "")})
  end
end

local data = {
  name = 'World Bosses',
  key = key,
  linegenerator = Linegenerator,
  globallgenerator = GlobalLineGenerator,
  priority = 50,
  updater = Updater,
  event = {"PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE"},
  weeklyReset = true
}

CharacterInfo.RegisterModule(data)
