local key = "raids"
local prio = 7

local LFRencounters = {
  -- [dungeonID] = {name = "", totalEncounters = 2}
  -- Emerald Nightmare
  [GetLFGDungeonInfo(1350) or "Emerald Nightmare"] = {
    [1287] = {name = "Darkbough", totalEncounters = 3, order = 1},
    [1288] = {name = "Tormented Guardians", totalEncounters = 3, order = 2},
    [1289] = {name = "Rift of Aln", totalEncounters = 1, order = 3}
  },
  -- Trials of Valor
  [GetLFGDungeonInfo(1439) or "Trials of Valor"] = {
    [1411] = {name = "Trials of Valor", totalEncounters = 3, order = 1}
  },
  -- Nighthold
  [GetLFGDungeonInfo(1353) or "The Nighthold"] = {
    [1290] = {name = "Arcing Aqueducts", totalEncounters = 3, order = 1},
    [1291] = {name = "Royal Athenaeum", totalEncounters = 3, order = 2},
    [1292] = {name = "Nightspire", totalEncounters = 3, order = 3},
    [1293] = {name = "Betrayer's Rise", totalEncounters = 1, order = 4}
  },
  --Tomb of Sargeras
  [GetLFGDungeonInfo(1527) or "Tomb of Sargeras"] = {
    [1494] = {name = "The Gates of Hell", totalEncounters = 3, order = 1},
    [1495] = {name = "Wailing Halls", totalEncounters = 3, order = 2}, --?? inq +sist + deso
    [1496] = {name = "Chamber of the Avatar", totalEncounters = 2, order = 3}, --?? maid + ava
    [1497] = {name = "Deceiver’s Fall", totalEncounters = 1, order = 4} --?? KJ
  },
  -- Antorus
  [GetLFGDungeonInfo(1712) or "Antorus, the Burning Throne"] = {
    [1610] = {name = "Light's Breach", totalEncounters = 3, order = 1}, -- Light's Breach
    [1611] = {name = "Forbidden Descent", totalEncounters = 3, order = 2}, -- Forbidden Descent
    [1612] = {name = "Hope's End", totalEncounters = 3, order = 3}, -- Hope's End
    [1613] = {name = "Seat of the Pantheon", totalEncounters = 2, order = 4}, -- Seat of the Pantheon
  }
}
local ALLOWED_RAIDS = {
  [GetLFGDungeonInfo(1350) or "Emerald Nightmare"] = true, -- EN
  [GetLFGDungeonInfo(1439) or "Trials of Valor"] = true, -- ToV
  [GetLFGDungeonInfo(1353) or "The Nighthold"] = true, -- Nighthold
  [GetLFGDungeonInfo(1527) or "Tomb of Sargeras"] = true, -- ToS
  [GetLFGDungeonInfo(1712) or "Antorus, the Burning Throne"] = true, -- Antorus
}

local expansions = {
  "Vanilla",
  "The Burning Crusade",
  "Wrath of The Lich King",
  "Cataclysm",
  "Mists of Pandaria",
  "Warlords of Draenor",
  "Legion"
}

local defaultSettings = {
  -- LEGION
  [GetLFGDungeonInfo(1712) or "Antorus, the Burning Throne"] = {enabled = true, expansion = 7,order = 1}, 
  [GetLFGDungeonInfo(1527) or "Tomb of Sargeras"] = {enabled = true, expansion = 7,order = 2},
  [GetLFGDungeonInfo(1353) or "The Nighthold"] = {enabled = true, expansion = 7,order = 3},
  [GetLFGDungeonInfo(1439) or "Trials of Valor"] = {enabled = true, expansion = 7,order = 4},
  [GetLFGDungeonInfo(1350) or "Emerald Nightmare"] = {enabled = true, expansion = 7,order = 5},
  -- WoD
  [GetLFGDungeonInfo(987) or "Hellfire Citadel"] = {enabled = false, expansion = 6,order = 1},
  [GetLFGDungeonInfo(898) or "Blackrock Foundry"] = {enabled = false, expansion = 6,order = 2},
  [GetLFGDungeonInfo(895) or "Highmaul"] = {enabled = false, expansion = 6,order = 3},
  -- MoP
  [GetLFGDungeonInfo(714) or "Siege of Orgrimmar"] = {enabled = false, expansion = 5,order = 1},
  [GetLFGDungeonInfo(633) or "Throne of Thunder"] = {enabled = false, expansion = 5,order = 2},
  [GetLFGDungeonInfo(834) or "Terrace of Endless Spring"] = {enabled = false, expansion = 5,order = 3},
  [GetLFGDungeonInfo(533) or "Heart of Fear"] = {enabled = false, expansion = 5,order = 4},
  [GetLFGDungeonInfo(531) or "Mogu'shan Vaults"] = {enabled = false, expansion = 5,order = 5},
  -- Cata
  [GetLFGDungeonInfo(447) or "Dragon Soul"] = {enabled = false, expansion = 4,order = 1},
  [GetLFGDungeonInfo(361) or "Firelands"] = {enabled = false, expansion = 4,order = 2},
  [GetLFGDungeonInfo(317) or "Throne of the Four Winds"] = {enabled = false, expansion = 4,order = 3},
  [GetLFGDungeonInfo(315) or "The Bastion of Twilight"] = {enabled = false, expansion = 4,order = 4},
  [GetLFGDungeonInfo(313) or "Blackwing Descent"] = {enabled = false, expansion = 4,order = 5},
  [GetLFGDungeonInfo(328) or "Baradin Hold"] = {enabled = false, expansion = 4,order = 6},
  -- Wotlk
  [GetLFGDungeonInfo(293) or "Ruby Sanctum"] = {enabled = false, expansion = 3,order = 1},
  [GetLFGDungeonInfo(279) or "Icecrown Citadel"] = {enabled = false, expansion = 3,order = 2},
  [GetLFGDungeonInfo(257) or "Onyxia's Lair"] = {enabled = false, expansion = 3,order = 3},
  [GetLFGDungeonInfo(248) or "Trial of the Crusader"] = {enabled = false, expansion = 3,order = 4},
  [GetLFGDungeonInfo(243) or "Ulduar"] = {enabled = false, expansion = 3,order = 5},
  [GetLFGDungeonInfo(237) or "The Eye of Eternity"] = {enabled = false, expansion = 3,order = 6},
  [GetLFGDungeonInfo(238) or "The Obsidian Sanctum"] = {enabled = false, expansion = 3,order = 7},
  [GetLFGDungeonInfo(227) or "Naxxramas"] = {enabled = false, expansion = 3,order = 8},
  [GetLFGDungeonInfo(239) or "Vault of Archavon"] = {enabled = false, expansion = 3,order = 9},
  -- TBC
  [GetLFGDungeonInfo(199) or "The Sunwell"] = {enabled = false, expansion = 2,order = 1},
  [GetLFGDungeonInfo(196) or "Black Temple"] = {enabled = false, expansion = 2,order = 2},
  [select(19,GetLFGDungeonInfo(195)) or "The Battle for Mount Hyjal"] = {enabled = false, expansion = 2,order = 3},
  [GetLFGDungeonInfo(193) or "Tempest Keep"] = {enabled = false, expansion = 2,order = 4}, 
  [GetLFGDungeonInfo(194) or "Serpentshrine Cavern"] = {enabled = false, expansion = 2,order = 5},
  [GetLFGDungeonInfo(176) or "Magtheridon's Lair"] = {enabled = false, expansion = 2,order = 6},
  [GetLFGDungeonInfo(177) or "Gruul's Lair"] = {enabled = false, expansion = 2,order = 7},
  [GetLFGDungeonInfo(175) or "Karazhan"] = {enabled = false, expansion = 2,order = 8},
  -- Vanilla
  [select(19,GetLFGDungeonInfo(161)) or "Temple of Ahn'Qiraj"] = {enabled = false, expansion = 1,order = 1}, 
  [select(19,GetLFGDungeonInfo(160)) or "Ruins of Ahn'Qiraj"] = {enabled = false, expansion = 1,order = 2}, 
  [GetLFGDungeonInfo(50) or "Blackwing Lair"] = {enabled = false, expansion = 1,order = 3},
  [GetLFGDungeonInfo(48) or "Molten Core"] = {enabled = false, expansion = 1,order = 4},
}

local function AddRaidOptions()
  local settings = Exlist.ConfigDB.settings
  settings.raids = settings.raids or {}
  -- add missing raids
  for raid,opt in pairs(defaultSettings) do
    if settings.raids[raid] == nil then
      settings.raids[raid] = opt
    end
  end
  -- Options
  local numExpansions = #expansions
  local configOpt = {
    type = "group",
    name = "Raids",
    args = {
      desc = {
        type = "description",
        name = "Enable raids you want to see\n",
        width = "full",
        order = 0,
      }
    }
  }
  -- add labels
  for i=numExpansions,1,-1 do
    configOpt.args["expac"..i] = {
      type = "description",
      name = WrapTextInColorCode(expansions[i],"ffffd200"),
      fontSize = "large",
      width = "full",
      order = numExpansions - i + 1,
    }
  end
  
  -- add raids
  for raid,opt in pairs(settings.raids) do
    configOpt.args[raid] = {
      type = "toggle",
      order = (numExpansions - opt.expansion + 1) + opt.order/100,
      width = "full",
      name = raid,
      get = function() return opt.enabled end,
      set = function(self,v) opt.enabled = v end
    }
  end
  Exlist.AddModuleOptions(key,configOpt,"Raids")
end
Exlist.ModuleToBeAdded(AddRaidOptions)

local GetNumSavedInstances, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo, GetLFGDungeonEncounterInfo = GetNumSavedInstances, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo, GetLFGDungeonEncounterInfo
local table, pairs = table, pairs
local WrapTextInColorCode = WrapTextInColorCode
local Exlist = Exlist

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

local function Updater(event)
  local t = {}
  local raids = Exlist.ConfigDB.settings.raids or {}
  for i = 1, GetNumSavedInstances() do
    local name, _, _, _, locked, extended, _, isRaid, _, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
    if isRaid then
      t[name] = t[name] or {}
      t[name][difficultyName] = {
        ['done'] = encounterProgress,
        ['max'] = numEncounters,
        ['locked'] = locked,
        ['extended'] = extended,
        ['bosses'] = {}
      }
      if locked then
        local tt = t[name][difficultyName]
        -- add info about killed bosses too
        for j = 1, numEncounters do
          local bName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
          table.insert(tt.bosses, {name = bName, killed = isKilled})
          --t.bosses[bName] = isKilled
        end
      end
    end
  end
  -- lfr
  for raid, c in pairs(LFRencounters) do
    if raids[raid] and raids[raid].enabled then
      local killed = 0
      local total = 0
      t[raid] = t[raid] or {}
      t[raid].LFR = t[raid].LFR or {}
      t[raid].LFR = {bosses = {}}
      for id, lfr in spairs(c,function(t,a,b) return t[a].order < t[b].order end) do
        total = total + lfr.totalEncounters
        for i = 1, lfr.totalEncounters do
          local bossName, _, isKilled = GetLFGDungeonEncounterInfo(id, i)
          killed = isKilled and killed + 1 or killed
          t[raid].LFR.bosses[id] = t[raid].LFR.bosses[id] or {}
          t[raid].LFR.bosses[id].order = lfr.order
          t[raid].LFR.bosses[id][lfr.name] = t[raid].LFR.bosses[id][lfr.name] or {}
          table.insert(t[raid].LFR.bosses[id][lfr.name], {name = bossName, killed = isKilled})
        end
      end
      t[raid].LFR.done = killed
      t[raid].LFR.max = total
      t[raid].LFR.locked = killed > 0
    end
    Exlist.UpdateChar(key,t)
  end
end

 local function Linegenerator(tooltip,data,character)
  if not data then return end
  local raids = Exlist.ConfigDB.settings.raids or {}
  local diffOrder = {"LFR","10 Player","25 Player","40 Player","Normal","Heroic","Mythic"}
  local diffShortened = {
            LFR = " LFR",
            Normal = " N",
            Heroic = " HC",
            ["25 Player"] = "",
            ["10 Player"] = "",
            ["40 Player"] = "",
            Mythic = " M"}
  local info = {character=character}
  local infoTables = {}
  -- setup order
  local raidOrder = {}
  for raid in pairs(data) do 
    if raids[raid] and raids[raid].enabled then
      raidOrder[#raidOrder+1] = raid
    end
  end
  table.sort(raidOrder,function(a,b) 
    local aValue = (raids[a].expansion or 0) * 100 + (50 - (raids[a].order or 0))
    local bValue = (raids[a].expansion or 0) * 100 + (50 - (raids[a].order or 0))
    return aValue > bValue
  end)

  for index = 1, #raidOrder do
    info.priority = prio + index
    if data[raidOrder[index]] then
      -- Raid
      local added = false
      local cellIndex = 1
      local line
      for difIndex=1,#diffOrder do
        -- difficulties
        local raidInfo = data[raidOrder[index]][diffOrder[difIndex]]
        if raidInfo and raidInfo.locked then
          --killed something
          if not added then
            -- raid shows up first time
            info.moduleName = raidOrder[index]
            info.titleName = WrapTextInColorCode(raidOrder[index],"ffc1c1c1")
            added = true
            cellIndex = cellIndex + 1
          end
          local sideTooltipTable = {title = WrapTextInColorCode(raidOrder[index].. " (" .. diffOrder[difIndex] .. ")","ffffd200"),body = {}}

          -- Side Tooltip Data
          if difIndex == 1 then
            -- LFR
            for id in spairs(raidInfo.bosses,function(t,a,b) return t[a].order < t[b].order end) do
              Exlist.Debug("Adding LFR id:",id," -",key) 
              for name,b in pairs(raidInfo.bosses[id]) do
                if type(b) == "table" then
                  table.insert(sideTooltipTable.body,{WrapTextInColorCode(name,"ffc1c1c1"),""})
                  for i=1,#b do
                    table.insert(sideTooltipTable.body,{b[i].name,
                    b[i].killed and WrapTextInColorCode("Defeated","ffff0000") or
                    WrapTextInColorCode("Available","ff00ff00")})
                  end
                end
              end
            end
          else
            -- normal people difficulties
            for boss=1,#raidInfo.bosses do
              table.insert(sideTooltipTable.body,{raidInfo.bosses[boss].name,
              raidInfo.bosses[boss].killed and WrapTextInColorCode("Defeated","ffff0000") or
              WrapTextInColorCode("Available","ff00ff00")})
            end
          end

          local statusbar = {curr = raidInfo.done,total=raidInfo.max,color = "9b016a"}
          info.data = raidInfo.done .. "/".. raidInfo.max .. diffShortened[diffOrder[difIndex]]
          
          info.colOff = cellIndex - 2
          info.OnEnter = Exlist.CreateSideTooltip(statusbar)
          info.OnEnterData = sideTooltipTable
          info.dontResize = true
          info.OnLeave = Exlist.DisposeSideTooltip()
          infoTables[info.moduleName] = infoTables[info.moduleName] or {}
          table.insert(infoTables[info.moduleName],Exlist.copyTable(info))
          cellIndex = cellIndex + 1
        end
      end
    end
  end
  for raid,t in pairs(infoTables) do
    for i=1,#t do
      if i>=#t then t[i].dontResize = false end
      Exlist.AddData(t[i])
    end
  end
end

local data = {
  name = 'Raids',
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"UPDATE_INSTANCE_INFO","PLAYER_ENTERING_WORLD"},
  description = "Tracks lockouts for current expansion raids",
  weeklyReset = true
}

Exlist.RegisterModule(data)
