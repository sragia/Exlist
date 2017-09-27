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
  [47061] = {eid = 1956}, -- Apocron
  [46947] = {eid = 1883}, -- Brutalus
  [46948] = {eid = 1884}, -- Malificus
  [46945] = {eid = 1885}, -- Si'vash
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
  [5376] = {questId = 49165, eid = 2013}, -- Occularus
  [5377] = {questId = 49170, eid = 2015}, -- Pit Lord Vilemus
  [5379] = {questId = 49172, eid = 2012}, -- Inquisitor Meto
  [5380] = {questId = 49171, eid = 2014}, -- Sotanathor
  [5381] = {questId = 49169, eid = 2010, name=EJ_GetEncounterInfo(2010)}, -- Matron Foluna
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
local GetCurrentMapAreaID, SetMapByID = GetCurrentMapAreaID, SetMapByID
local GetNumMapLandmarks, GetMapLandmarkInfo = GetNumMapLandmarks, GetMapLandmarkInfo

local function Updater(event)
  if not( UnitLevel('player') == MAX_CHARACTER_LEVEL ) or
  GetTime() - lastUpdate < 60 or -- throtle update every 10 seconds max
  not WorldMapButton:IsShown() then -- only update when map is open
    return
  end
  lastUpdate = GetTime()
  local realm = GetRealmName()
  local name = UnitName('player')
  local t = CharacterInfo.GetCharacterTableKey(realm,name,key)
  local timeNow = time()
  local currMapId = GetCurrentMapAreaID()
  -- broken isles world bosses
  for i=1,#BrokenIslesZones do
    SetMapByID(BrokenIslesZones[i])
    local wqs = C_TaskQuest.GetQuestsForPlayerByMapID(BrokenIslesZones[i])
    for _,info in pairs(wqs or {}) do
      if worldBossIDs[info.questId] then
        t[info.questId] = {
          name = worldBossIDs[info.questId].name or select(2,EJ_GetCreatureInfo(1,worldBossIDs[info.questId].eid)),
          defeated = false,
          endTime = timeNow + (C_TaskQuest.GetQuestTimeLeftMinutes(info.questId)*60)
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
        local timeLeft = C_WorldMap.GetAreaPOITimeLeft(poiId) or 0
        t[greaterInvasionPOIId[poiId].questId] = {
          name = greaterInvasionPOIId[poiId].name or select(2,EJ_GetCreatureInfo(1,greaterInvasionPOIId[poiId].eid)),
          defeated = false,
          endTime = timeNow + timeLeft*60
        }
      end
    end
  end
  SetMapByID(currMapId)
  -- cleanup table
  for questId,info in pairs(t) do
    if info.endTime ~= 0 and info.endTime < timeNow then
      t[questId] = nil
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
          endTime = 0,
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
          endTime = 0,
          defeated = true
        }
      end
    end
  end
  CharacterInfo.UpdateChar(key,t)
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

local data = {
  name = 'World Bosses',
  key = key,
  linegenerator = Linegenerator,
  priority = 50,
  updater = Updater,
  event = {"PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE"},
  weeklyReset = true
}

CharacterInfo.RegisterModule(data)
