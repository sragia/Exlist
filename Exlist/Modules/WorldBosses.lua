local key = "worldboss"
local prio = 120
local Exlist = Exlist
local colors = Exlist.Colors
local L = Exlist.L
local EJ_GetEncounterInfo = EJ_GetEncounterInfo
local UnitLevel,GetRealmName,UnitName = UnitLevel,GetRealmName,UnitName
local IsQuestFlaggedCompleted = IsQuestFlaggedCompleted
local WrapTextInColorCode = WrapTextInColorCode
local string,table = string,table
local C_TaskQuest, C_WorldMap, EJ_GetCreatureInfo,C_ContributionCollector, C_Timer = C_TaskQuest, C_WorldMap ,EJ_GetCreatureInfo, C_ContributionCollector, C_Timer
local pairs,ipairs,time,select = pairs,ipairs,time,select
local GetTime = GetTime
local IsInRaid, IsInInstance = IsInRaid, IsInInstance
local GetCurrentMapAreaID, SetMapByID,GetMapNameByID = GetCurrentMapAreaID, SetMapByID,GetMapNameByID
local GetNumMapLandmarks, GetMapLandmarkInfo = GetNumMapLandmarks, GetMapLandmarkInfo
local GetSpellInfo = GetSpellInfo
local GameTooltip = GameTooltip

-- TODO: Figure out BFA World Bosses questIDs
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

	-- BFA
	[52847] = {eid = 2213}, -- Doom's Howl
	[52196]  = {eid = 2210}, -- Dunegorger Kraulok
	[52181] =  {eid = 2139}, -- T'zane
	[52169] =  {eid = 2141}, -- Ji'arak
	[52157] =  {eid = 2197}, -- Hailstone Construct
	[0] =  {eid = 2199}, -- Azurethos, The Winged Typhoon
	[52166] =  {eid = 2198}, -- Warbringer Yenajz
}
local ArgusZones = {
	-- TODO PrePatch
	830, -- Krokuun
	885,  --Antoran Wastes
	882 -- Macree
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
local unknownIcon = "Interface\\ICONS\\INV_Misc_QuestionMark"

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
local filterBuffs = {
	[239648] = true, -- Fel Treasures
	[239645] = true, -- Forces of Order
	[239647] = true, -- Epic Hunter
}

--TODO: Retire
local function GetBrokenShoreBuildings()
	local t = {}
	for i=1,4,1 do
		 local name = C_ContributionCollector.GetName(i);
		 if (name ~= "") then
				-- get status
				local state, contribed, timeNext = C_ContributionCollector.GetState(i);
				local reward1,reward2 = C_ContributionCollector.GetBuffs(i)
				local reward
				if filterBuffs[reward1] then
					-- thanks Blizz for not sorting buffs the same way always :)
					reward = reward2
				else
					reward = reward1
				end
				if (state == 2 or state == 3) and timeNext then
					local bonustime = state == 2 and 86400 or 0
					--local reward = C_ContributionCollector.GetBuffs(i)
					local spellname,_,icon = GetSpellInfo(reward)
					t[i] = {name = name,state = state, timeEnd = timeNext + bonustime, rewards = {name = spellname, icon = icon, spellId = reward}}
				elseif contribed then
					--local _,reward = C_ContributionCollector.GetBuffs(i)
					local spellname,_,icon = GetSpellInfo(reward)
					t[i] = {name= name, state=state,progress = string.format("%.1f%%",contribed*100),rewards = {name = spellname, icon = icon, spellId = reward}}
				end
		 end
	end
	return t
end

--TOOD: Retire
local function ScanArgus()
	if GetExpansionLevel() > 6 then return {} end
	Exlist.Debug("Scanning Argus -",key)
	local t = {
	--  worldBoss = {},
	--  invasions = {}
	}
	local timeNow = time()
	--local currMapId = GetCurrentMapAreaID()
	for _,mapId in ipairs(ArgusZones) do
		local POIs = C_AreaPoiInfo.GetAreaPOIForMap(mapId)
		for _,poiId in ipairs(POIs) do
			if greaterInvasionPOIId[poiId] then
				t.worldBoss = {
					questId = greaterInvasionPOIId[poiId].questId,
					name = greaterInvasionPOIId[poiId].name or select(2,EJ_GetCreatureInfo(1,greaterInvasionPOIId[poiId].eid)),
					endTime = Exlist.GetNextWeeklyResetTime() or 0,
					eid = greaterInvasionPOIId[poiId].eid,
					zoneId = mapId,
				}
			elseif invasionPointPOIId[poiId] then -- assuming that same invasion isn't up in 2 places
				local timeLeft = C_AreaPoiInfo.GetAreaPOITimeLeft(poiId)
				local desc = C_AreaPoiInfo.GetAreaPOIInfo(mapId,poiId).description
				if timeLeft then
					local mapInfo = C_Map.GetMapInfo(mapId) 
					t.invasions = t.invasions or {}
					t.invasions[mapId] = {
						name = desc,
						endTime = timeNow + timeLeft * 60,
						map = mapInfo.name
					}
				end
			end
		end
	end
	return t
end

local function Updater(e,info)
	if e == "WORLD_QUEST_SPOTTED" and #info > 0 then
		-- got info from WQ module
		local t = Exlist.GetCharacterTableKey((GetRealmName()),(UnitName('player')),key)
		local gt = Exlist.GetCharacterTableKey("global","global",key)
		gt.worldbosses = gt.worldbosses or {}
		-- update brokenshore building
		gt.brokenshore = GetBrokenShoreBuildings() --TODO: Only Prepatch
		local db = gt.worldbosses
		for _,wq in ipairs(info) do
			local defaultInfo = worldBossIDs[wq.questId]
			if defaultInfo then
				t[wq.questId] = {
					name = defaultInfo.name or select(2,EJ_GetCreatureInfo(1,defaultInfo.eid)),
					defeated = IsQuestFlaggedCompleted(wq.questId),
					endTime = defaultInfo.endTime and defaultInfo.endTime==0 and (gt.brokenshore[4] and gt.brokenshore[4].timeEnd or 0) or wq.endTime,
				}
				db[wq.questId] = {
					name = defaultInfo.name or select(2,EJ_GetCreatureInfo(1,defaultInfo.eid)),
					endTime = defaultInfo.endTime and defaultInfo.endTime==0 and (gt.brokenshore[4] and gt.brokenshore[4].timeEnd or 0) or wq.endTime,
					zoneId = wq.zoneId,
					questId = wq.questId
				}
			end
		end
		Exlist.UpdateChar(key,t)
		Exlist.UpdateChar(key,gt,'global','global')
		return
	elseif not( UnitLevel('player') == Exlist.CONSTANTS.MAX_CHARACTER_LEVEL ) or
	GetTime() - lastUpdate < 5 or
	IsInRaid() or
	select(2,IsInInstance()) ~= "none"
	then
		-- Check for cached WB kill status
		local t = Exlist.GetCharacterTableKey((GetRealmName()),(UnitName("player")),key)
			local changed = false
			for questId,info in pairs(t) do
				if not info.defeated and IsQuestFlaggedCompleted(questId) then
					t[questId].defeated = true
					changed = true
				end
			end
			if changed then Exlist.UpdateChar(key,t) end
		return
	end
	if e == "PLAYER_ENTERING_WORLD" or e == "EJ_DIFFICULTY_UPDATE" then
		C_Timer.After(1,function() Exlist.SendFakeEvent("PLAYER_ENTERING_WORLD_DELAYED") end) -- delay update
		return
	end
	lastUpdate = GetTime()
	local t = Exlist.GetCharacterTableKey((GetRealmName()),(UnitName('player')),key)
	local gt = Exlist.GetCharacterTableKey("global","global",key)
	gt.invasions = gt.invasions or {}
	gt.brokenshore = gt.brokenshore or {}
	gt.worldbosses = gt.worldbosses or {}
	local timeNow = time()
	-- update brokenshore building
	gt.brokenshore = GetBrokenShoreBuildings()
	local argusScan = ScanArgus()
	-- Check global
	for questId,info in pairs(gt.worldbosses) do
		if not t[questId] then
			local defaultInfo = worldBossIDs[questId]
			t[questId] = {
				name = info.name or "",
				defeated = IsQuestFlaggedCompleted(questId),
				endTime = defaultInfo.endTime and defaultInfo.endTime==0 and (gt.brokenshore[4] and gt.brokenshore[4].timeEnd or 0) or info.endTime,
			}
		end
	end
	--TODO:Prepatch
	local argusScan = ScanArgus()
	if argusScan.worldBoss then
		local info = argusScan.worldBoss
		t[info.questId] = {
			name = info.name or select(2,EJ_GetCreatureInfo(1,info.eid)),
			defeated = false,
			endTime = info.endTime
		}
		gt.worldbosses[info.questId] = {
			name = info.name or select(2,EJ_GetCreatureInfo(1,info.eid)),
			endTime = info.endTime,
			questId = info.questId,
			zoneId = info.zoneId
		}
	end
	--TODO:Prepatch
	-- Invasions
	local count = 0
	-- cleanup table and count elements in it
	for poiId,info in pairs(gt.invasions or {}) do
		if not info.endTime or info.endTime < timeNow then
			gt.invasions[poiId] = nil
		else
			count = count + 1
		end
	end
	if count < 3 then
		-- only update if there's already all 3 invasions up
		argusScan = argusScan or ScanArgus()
		for mapId,info in pairs(argusScan.invasions or {}) do
			gt.invasions[mapId] = info
		end
	end

	Exlist.UpdateChar(key,t)
	Exlist.UpdateChar(key,gt,'global','global')
end

local function Linegenerator(tooltip,data,character)
	if not data then return end

	local availableWB = 0
	local killed = 0
	local strings = {}
	local timeNow = time()
	for spellId,info in pairs(data) do
		availableWB = availableWB + 1
		killed = info.defeated and killed + 1 or killed
		table.insert(strings,{string.format("%s (%s)",info.name,info.endTime and info.endTime > timeNow and Exlist.TimeLeftColor(info.endTime-timeNow) or WrapTextInColorCode(L["Not Available"],colors.notavailable)),
																					info.defeated and WrapTextInColorCode(L["Defeated"],colors.completed) or WrapTextInColorCode(L["Available"],colors.available)})
	end
	if availableWB > 0 then
		local sideTooltip = {body = strings,title=WrapTextInColorCode(L["World Bosses"],colors.sideTooltipTitle)}
		local info = {
			character = character,
			moduleName = key,
			priority = prio,
			titleName = WrapTextInColorCode(L["World Bosses"] .. ":",colors.faded),
			data = string.format("%i/%i",killed,availableWB),
			OnEnter = Exlist.CreateSideTooltip(),
			OnEnterData = sideTooltip,
			OnLeave = Exlist.DisposeSideTooltip()
		}
		Exlist.AddData(info)
	end
end

local function GlobalLineGenerator(tooltip,data)
	local timeNow = time()
	if not data then return end
	if data.invasions and Exlist.ConfigDB.settings.extraInfoToggles.invasions.enabled then
		local added = false
		for questId,info in spairs((data.invasions or {}),function(t,a,b) return (t[a].endTime or 0) < (t[b].endTime or 0) end) do
			if info.endTime and info.endTime > timeNow then
				if not added then 
					added = true
					Exlist.AddLine(tooltip,{WrapTextInColorCode(L["Invasion Points"],colors.sideTooltipTitle)},14)
				end
				Exlist.AddLine(tooltip,{info.name,Exlist.TimeLeftColor(info.endTime - timeNow,{1800, 3600}),WrapTextInColorCode(info.map or "",colors.faded)})
			end
		end
	end
	if data.brokenshore and Exlist.ConfigDB.settings.extraInfoToggles.brokenshore.enabled then
		local added = false
		for i,info in pairs(data.brokenshore or {}) do
			if not added then 
				added = true
				Exlist.AddLine(tooltip,{WrapTextInColorCode(L["Broken Shore"],colors.sideTooltipTitle)},14)
			end
			local line = Exlist.AddLine(tooltip,{info.name,info.timeEnd and Exlist.TimeLeftColor(info.timeEnd - timeNow) or info.progress,(info.state == 4 and WrapTextInColorCode(L["Destroyed"],colors.faded) or
			(info.rewards and (info.state == 2 or info.state == 3) and string.format("|T%s:15|t|c%s %s",info.rewards.icon or unknownIcon,colors.sideTooltipTitle,info.rewards.name or "") or info.state == 1 and string.format("|T%s:15|t|c%s %s",info.rewards.icon or unknownIcon,colors.hardfaded,info.rewards.name or "")))})
			if info.rewards and info.state ~= 4 then
				Exlist.AddScript(tooltip,line,3,"OnEnter",function(self)
					GameTooltip:SetOwner(self)
					GameTooltip:SetFrameLevel(self:GetFrameLevel()+10)
					GameTooltip:ClearLines()
					GameTooltip:SetSpellByID(info.rewards.spellId)
					GameTooltip:Show()
				 end)
				 Exlist.AddScript(tooltip,line,3,"OnLeave",GameTooltip_Hide)
			end
		end
	end
	if data.worldbosses and Exlist.ConfigDB.settings.extraInfoToggles.worldbosses.enabled then
		local added = false
		for questId,info in pairs(data.worldbosses) do
			if info.endTime > timeNow then
				if not added then 
					added = true
					Exlist.AddLine(tooltip,{WrapTextInColorCode(L["World Bosses"],colors.sideTooltipTitle)},14)
				end
				local lineNum = Exlist.AddLine(tooltip,{info.name,Exlist.TimeLeftColor(info.endTime - timeNow)})
				Exlist.AddScript(tooltip,lineNum,nil,"OnMouseDown",function(self)
					if not WorldMapFrame:IsShown() then
						ToggleWorldMap()
					end
					WorldMapFrame:SetMapID(info.zoneId)
					BonusObjectiveTracker_TrackWorldQuest(questId)
				end)
			end
		end
	end
end

local function init()
	local t = {}
	for questId in pairs(worldBossIDs) do
		t[#t+1] = questId
	end
	Exlist.RegisterWorldQuests(t,true)
	Exlist.ConfigDB.settings.extraInfoToggles.worldbosses = Exlist.ConfigDB.settings.extraInfoToggles.worldbosses or {
			name = L["World Bosses"],
			enabled = true,
	}
	Exlist.ConfigDB.settings.extraInfoToggles.invasions = Exlist.ConfigDB.settings.extraInfoToggles.invasions or {
			name = L["Argus Lesser Invasions"],
			enabled = true,
	}
	Exlist.ConfigDB.settings.extraInfoToggles.brokenshore = Exlist.ConfigDB.settings.extraInfoToggles.brokenshore or {
			name = L["Broken Shore Buildings"],
			enabled = true,
	}

	local gt = Exlist.GetCharacterTableKey("global","global",key)
	if gt.worldbosses and gt.worldbosses.argus then
		local t = {}
		for _,quests in pairs(gt.worldbosses) do
			for questId,info in pairs(quests) do
				t[questId] = info
			end
		end
		gt.worldbosses = t 
		Exlist.UpdateChar(key,gt,"global","global")
	end

end




local data = {
	name = L['World Bosses'],
	key = key,
	linegenerator = Linegenerator,
	globallgenerator = GlobalLineGenerator,
	priority = prio,
	updater = Updater,
	event = {"PLAYER_ENTERING_WORLD","WORLD_MAP_OPEN","EJ_DIFFICULTY_UPDATE","PLAYER_ENTERING_WORLD_DELAYED","WORLD_QUEST_SPOTTED"},
	description = L["Tracks World Boss availability for each character. Also tracks Broken Shore buildings status and invasion points on Argus."],
	weeklyReset = true,
	init = init,
}

Exlist.RegisterModule(data)
