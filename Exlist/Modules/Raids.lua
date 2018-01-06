local key = "raids"
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
    [1612] = {name = "Hope's End", totalEncounters = 2, order = 3}, -- Hope's End
    [1613] = {name = "Seat of the Pantheon", totalEncounters = 1, order = 4}, -- Seat of the Pantheon
  }
}
local ALLOWED_RAIDS = {
  [GetLFGDungeonInfo(1350) or "Emerald Nightmare"] = true, -- EN
  [GetLFGDungeonInfo(1439) or "Trials of Valor"] = true, -- ToV
  [GetLFGDungeonInfo(1353) or "The Nighthold"] = true, -- Nighthold
  [GetLFGDungeonInfo(1527) or "Tomb of Sargeras"] = true, -- ToS
  [GetLFGDungeonInfo(1712) or "Antorus, the Burning Throne"] = true, -- Antorus
}
for i,v in pairs(ALLOWED_RAIDS) do print(i,v) end
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
  for i = 1, GetNumSavedInstances() do
    local name, _, _, _, locked, extended, _, isRaid, _, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
    if isRaid and ALLOWED_RAIDS[name] then
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

local raidOrder = {GetLFGDungeonInfo(1712) or "Antorus, the Burning Throne",
                   GetLFGDungeonInfo(1527) or "Tomb of Sargeras",
                   GetLFGDungeonInfo(1353) or "The Nighthold",
                   GetLFGDungeonInfo(1439) or "Trials of Valor",
                   GetLFGDungeonInfo(1350) or "Emerald Nightmare"}
local function Linegenerator(tooltip,data)
  if not data then return end
  local diffOrder = {"LFR","Normal","Heroic","Mythic"}
  local diffShortened = {
            LFR = "LFR",
            Normal = "N",
            Heroic = "HC",
            Mythic = "M"}
  local diffColors = {
            LFR = "ffffffff",
            Normal = "ffffffff",
            Heroic = "ffffffff",
            Mythic = "ffffffff"}
  for index = 1, #raidOrder do
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
            line = Exlist.AddLine(tooltip,{WrapTextInColorCode(raidOrder[index],"ffc1c1c1"),"","","",""})
            added = true
            cellIndex = cellIndex + 1
          end
          local sideTooltipTable = {title = WrapTextInColorCode(raidOrder[index].. " (" .. diffOrder[difIndex] .. ")","ffffd200"),body = {}}

          -- Side Tooltip Data
          if difIndex == 1 then
            -- LFR
            for id in spairs(raidInfo.bosses,function(t,a,b) return t[a].order < t[b].order end) do
              if Exlist.debugMode then print("Adding LFR id:",id," -",key) end
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
          Exlist.AddToLine(tooltip,line,cellIndex,WrapTextInColorCode(raidInfo.done .. "/".. raidInfo.max.. " " .. diffShortened[diffOrder[difIndex]] ,diffColors[diffOrder[difIndex]]))
          Exlist.AddScript(tooltip,line,cellIndex,"OnEnter",Exlist.CreateSideTooltip(statusbar),sideTooltipTable)
          Exlist.AddScript(tooltip,line,cellIndex,"OnLeave",Exlist.DisposeSideTooltip())
          cellIndex = cellIndex + 1
        end
      end
    end
  end
end

local data = {
  name = 'Raids',
  key = key,
  linegenerator = Linegenerator,
  priority = 7,
  updater = Updater,
  event = {"UPDATE_INSTANCE_INFO","PLAYER_ENTERING_WORLD"},
  weeklyReset = true
}

Exlist.RegisterModule(data)
