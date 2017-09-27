local key = "raids"
local LFRencounters = {
  -- [dungeonID] = {name = "", totalEncounters = 2}
  -- Emerald Nightmare
  ["The Emerald Nightmare"] = {
    [1287] = {name = "Darkbough", totalEncounters = 3},
    [1288] = {name = "Tormented Guardians", totalEncounters = 3},
    [1289] = {name = "Rift of Aln", totalEncounters = 1}
  },
  -- Trials of Valor
  ["Trials of Valor"] = {
    [1411] = {name = "Trials of Valor", totalEncounters = 3}
  },
  -- Nighthold
  ["The Nighthold"] = {
    [1290] = {name = "Arcing Aqueducts", totalEncounters = 3},
    [1291] = {name = "Royal Athenaeum", totalEncounters = 3},
    [1292] = {name = "Nightspire", totalEncounters = 3},
    [1293] = {name = "Betrayer's Rise", totalEncounters = 1}
  },
  --Tomb of Sargeras
  ["Tomb of Sargeras"] = {
    [1494] = {name = "The Gates of Hell", totalEncounters = 3},
    [1495] = {name = "Wailing Halls", totalEncounters = 3}, --?? inq +sist + deso
    [1496] = {name = "Chamber of the Avatar", totalEncounters = 2}, --?? maid + ava
    [1497] = {name = "Deceiver’s Fall", totalEncounters = 1} --?? KJ
  }
}
local ALLOWED_RAIDS = {
  ['The Nighthold'] = true,
  ["Trial of Valor"] = true,
  ["The Emerald Nightmare"] = true,
  ["Tomb of Sargeras"] = true
}

local GetNumSavedInstances, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo, GetLFGDungeonEncounterInfo = GetNumSavedInstances, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo, GetLFGDungeonEncounterInfo
local table, pairs = table, pairs
local WrapTextInColorCode = WrapTextInColorCode
local CharacterInfo = CharacterInfo

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
    for id, lfr in pairs(c) do
      total = total + lfr.totalEncounters
      for i = 1, lfr.totalEncounters do
        local bossName, _, isKilled = GetLFGDungeonEncounterInfo(id, i)
        killed = isKilled and killed + 1 or killed
        t[raid].LFR.bosses[id] = t[raid].LFR.bosses[id] or {}
        t[raid].LFR.bosses[id][lfr.name] = t[raid].LFR.bosses[id][lfr.name] or {}
        table.insert(t[raid].LFR.bosses[id][lfr.name], {name = bossName, killed = isKilled})
      end
    end
    t[raid].LFR.done = killed
    t[raid].LFR.max = total
    t[raid].LFR.locked = killed > 0
  end
  CharacterInfo.UpdateChar(key,t)
end

local function Linegenerator(tooltip,data)
  if not data then return end
  local raidOrder = {"Tomb of Sargeras","The Nighthold", "Trial of Valor","The Emerald Nightmare"}
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
            line = CharacterInfo.AddLine(tooltip,{WrapTextInColorCode(raidOrder[index],"ffc1c1c1"),"","","",""})
            added = true
            cellIndex = cellIndex + 1
          end
          local sideTooltipTable = {title = WrapTextInColorCode(raidOrder[index].. " (" .. diffOrder[difIndex] .. ")","ffffd200"),body = {}}

          -- Side Tooltip Data
          if difIndex == 1 then
            -- LFR
            for id in pairs(raidInfo.bosses) do
              for name,b in pairs(raidInfo.bosses[id]) do
                table.insert(sideTooltipTable.body,{WrapTextInColorCode(name,"ffc1c1c1"),""})
                for i=1,#b do
                  table.insert(sideTooltipTable.body,{b[i].name,
                  b[i].killed and WrapTextInColorCode("Defeated","ffff0000") or
                  WrapTextInColorCode("Available","ff00ff00")})
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
          CharacterInfo.AddToLine(tooltip,line,cellIndex,WrapTextInColorCode(raidInfo.done .. "/".. raidInfo.max.. " " .. diffShortened[diffOrder[difIndex]] ,diffColors[diffOrder[difIndex]]))
          CharacterInfo.AddScript(tooltip,line,cellIndex,"OnEnter",CharacterInfo.CreateSideTooltip(statusbar),sideTooltipTable)
          CharacterInfo.AddScript(tooltip,line,cellIndex,"OnLeave",CharacterInfo.DisposeSideTooltip())
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

CharacterInfo.RegisterModule(data)
