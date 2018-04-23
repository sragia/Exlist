-- TODO: Can't add some quests

local key = "worldquests"
local prio = 100
local Exlist = Exlist
local trackedQuests = {
}

local lastTrigger = 0

local zones = {
  -- Broken Isles
  1015, -- Aszuna
	1018, -- Val'Sharah
	1024, -- Highmountain
	1017, -- Stormheim
	1033, -- Suramar
  1021, -- Broken Shore
  -- Argus
  1170, -- Mac'reee
	1135, -- Kro'kuun
	1171, -- Antoran Wastes
}

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


function Exlist.RegisterWorldQuests(quests,readOnly)
  -- quests = info
  -- readOnly = can't be removed in session
    if type(quests) == 'number' then
       trackedQuests[quests] = {enabled = true, readOnly = readOnly}
    elseif type(quests) == 'table' then
        for i,questId in ipairs(quests) do
            trackedQuests[questId] = {enabled = true, readOnly = readOnly}
        end
    end
end

local function GetQuestRewards(questId)
    local rewards = {}
    C_TaskQuest.RequestPreloadRewardData(questId)
    local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(1,questId)
    if name then
        table.insert( rewards,{name = name,amount = numItems,texture = texture})
    end
    local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questId)
    if numQuestCurrencies > 0 then
       for i=1,numQuestCurrencies do
         local name, texture, numItems = GetQuestLogRewardCurrencyInfo(i,questId)
         if name then
            table.insert( rewards, {name = name, amount = numItems,texture = texture})
        end
       end
    end
    local coppers = GetQuestLogRewardMoney(questId)
    if coppers and coppers > 0 then
        table.insert(rewards,{name = "gold",amount = {
          ["gold"] = math.floor(coppers / 10000),
          ["silver"] = math.floor((coppers / 100)%100),
          ["coppers"] = math.floor(coppers%100)
        }})
    end
    return rewards
end

function Exlist.ScanQuests()
  -- add refresh quests
  if not Exlist.ConfigDB then return end
  local wq = Exlist.ConfigDB.settings.worldQuests
  local rt = {}
  local tl = 100
  for questId,info in pairs(wq) do
    trackedQuests[questId] = {enabled = info.enabled , readOnly = false}
  end
  local currMapId = GetCurrentMapAreaID()
  for index,zoneId in ipairs(zones) do
    SetMapByID(zoneId)
    local wqs = C_TaskQuest.GetQuestsForPlayerByMapID(zoneId)
    for _,info in pairs(wqs or {}) do
      local timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(info.questId)
      if trackedQuests[info.questId] and trackedQuests[info.questId].enabled  then
        local name = C_TaskQuest.GetQuestInfoByQuestID(info.questId)
        local endTime = time() + (timeLeft * 60)
        Exlist.Debug("Spotted",name,"world quest - ",key)
        rt[#rt+1] = {
          name = name,
          questId = info.questId,
          endTime = endTime,
          rewards = GetQuestRewards(info.questId),
          zoneId = zoneId
        }
      end
      -- optimization (scan only once an half hour)
      tl = tl > timeLeft and timeLeft or tl
    end
  end
  SetMapByID(currMapId)
  if tl < 30 then
    lastTrigger = lastTrigger - ((30 - tl) * 60)
  end
  if #rt > 0 then
    Exlist.SendFakeEvent("WORLD_QUEST_SPOTTED",rt)
  end
end

local function RemoveExpiredQuest(questId)
  local gt = Exlist.GetCharacterTableKey("global","global",key)
  lastTrigger = 0
  gt[questId] = nil
  Exlist.UpdateChar(key,gt,"global","global")
end

local function RemoveTrackedQuest(questId)
  if trackedQuests[questId] and not trackedQuests[questId].readOnly then
    trackedQuests[questId] = nil
  end 
  local wq = Exlist.ConfigDB.settings.worldQuests
  wq[questId] = nil
  local gt = Exlist.GetCharacterTableKey("global","global",key)
  gt[questId] = nil
  Exlist.UpdateChar(key,gt,"global","global")  
end

local function Updater(event,questInfo)
  if event == "WORLD_MAP_OPEN" and 
    GetTime() - lastTrigger > 1800
  then 
    lastTrigger = GetTime()
    Exlist.ScanQuests() 
    return 
  end

  local gt = Exlist.GetCharacterTableKey("global","global",key)
  if questInfo and #questInfo > 0 then
    local wq = Exlist.ConfigDB.settings.worldQuests
    for i,info in ipairs(questInfo) do
      if wq[info.questId] and not gt[info.questId] then
        gt[info.questId] = info
      elseif wq[info.questId] then
        for key,value in ipairs(info) do
          if gt[info.questId][key] == nil then
            gt[info.questId][key] = value -- add info that is missed in previous scans
          end
        end
      end
    end
    Exlist.UpdateChar(key,gt,"global","global")
  end
end

local function Linegenerator(tooltip,data,character)
  -- does nothing
end

local function GlobalLineGenerator(tooltip,data)
  local timeNow = time()
  if data then
    local wq = Exlist.ConfigDB.settings.worldQuests
    local first = true
    for questId,info in spairs(data,function(t,a,b) return t[a].endTime < t[b].endTime end) do
      if info.endTime < timeNow or not wq[questId].enabled then 
        RemoveExpiredQuest(questId)
      else
        if first then Exlist.AddLine(tooltip,{WrapTextInColorCode("World Quests","ffffd200")},14) first = false end
        local lineNum = Exlist.AddLine(tooltip,{WrapTextInColorCode(info.name,Exlist.Colors.QuestTitle),
        IsQuestFlaggedCompleted(info.questId) and WrapTextInColorCode("Completed","FFFF0000") or WrapTextInColorCode("Available","FF00FF00"),  
        Exlist.TimeLeftColor(info.endTime - timeNow,{3600, 14400})})
        Exlist.AddScript(tooltip,lineNum,nil,"OnMouseDown",function(self)
          if not WorldMapFrame:IsShown() then
            ToggleWorldMap()
          end
          SetMapByID(info.zoneId)
        end)
        if not info.rewards or #info.rewards < 1 then 
          info.rewards = GetQuestRewards(questId) 
        end
        local reward = info.rewards[1]
        if reward.name == "gold" then
          Exlist.AddLine(tooltip,{reward.amount.gold .. "|cFFd8b21ag|r " .. reward.amount.silver .. "|cFFadadads|r " .. reward.amount.coppers .. "|cFF995813c|r"})
        else
          if reward.amount > 1 then
            Exlist.AddLine(tooltip,string.format( "%ix|T%s:12|t%s",reward.amount,reward.texture,reward.name))
          else
            Exlist.AddLine(tooltip,string.format( "|T%s:12|t%s",reward.texture,reward.name))
          end
        end
      end
    end 
  end
end


local function SetupWQConfig(refresh)
  if not Exlist.ConfigDB then return end
  local wq = Exlist.ConfigDB.settings.worldQuests
  local options = {
    type = "group",
    name = "World Quests",
    args ={
        desc = {
            type = "description",
            order = 1,
            width = "full",
            name = "Enable World Quests you want to see"
        },
        itemInput = {
          type = "input",
          order = 1.5,
          name = "Add World Quest ID",
          get = function() return "" end,
          set = function(self,v)
            local questId = tonumber(v)
            local name = Exlist.GetCachedQuestTitle(questId)
            if name then
              wq[questId] = {name = name, 
              enabled = true,
              rewards = GetQuestRewards(v)
            }
            SetupWQConfig(true)
            lastTrigger = 0
            end
          end,
          width = "full",
        },
    }
  }
  local n = 2
  for questID,info in pairs(wq) do
    local o = options.args
    o[questID.."enabled"] = {
        order = n,
        name = function()
          local name = info.name 
          if name:find("Unknown") then
            name = Exlist.GetCachedQuestTitle(questID)
            info.name = name
          end
          return WrapTextInColorCode(name,Exlist.Colors.QuestTitle)
        end,
        type = "toggle",
        width = "normal",
        get = function()
            return info.enabled
        end,
        set = function(self, v)
            info.enabled = v 
        end,
    }
    n = n + 1
    if not info.rewards or #info.rewards < 1 then
      info.rewards = GetQuestRewards(questID)
    end
    o[questID.."rewards"] = {
      order = n,
      name = function()
        local reward = info.rewards[1]
        local s = ""
        if reward.name == "gold" then
          s = reward.amount.gold .. "|cFFd8b21ag|r " .. reward.amount.silver .. "|cFFadadads|r " .. reward.amount.coppers .. "|cFF995813c|r"
        else
          if reward.amount > 1 then
            s = string.format( "%ix|T%s:12|t%s",reward.amount,reward.texture,reward.name)
         else
            s = string.format( "|T%s:12|t%s",reward.texture,reward.name)
          end
        end
        return s
      end,
      type = "description",
      width = 1.8,
    }
    n = n + 1
    o[questID.."delete"] = {
      type = "execute",
      order = n,
      name = "Delete",
      width = 0.5,
      func = function()
        StaticPopupDialogs["DeleteWQDataPopup_"..questID] = {
          text = "Do you really want to delete "..WrapTextInColorCode(info.name,Exlist.Colors.QuestTitle).."?",
          button1 = "Ok",
          button3 = "Cancel",
          hasEditBox = false,
          OnAccept = function(self)
            StaticPopup_Hide("DeleteWQDataPopup_"..questID)
            RemoveTrackedQuest(questID)
            SetupWQConfig(true)
            Exlist.NotifyOptionsChange(key)
          end,
          timeout = 0,
          cancels = "DeleteWQDataPopup_"..questID,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 4,
          showAlert = 1,
          enterClicksFirstButton = 1
        }
        StaticPopup_Show("DeleteWQDataPopup_"..questID)
      end
    }
  end
  if not refresh then
    Exlist.AddModuleOptions(key,options,"World Quests")
  else
    Exlist.RefreshModuleOptions(key,options,"World Quests")
  end
end
Exlist.ModuleToBeAdded(SetupWQConfig)

local data = {
  name = 'World Quests',
  key = key,
  linegenerator = Linegenerator,
  globallgenerator = GlobalLineGenerator,
  priority = prio,
  updater = Updater,
  event = {"WORLD_QUEST_SPOTTED","WORLD_MAP_OPEN"},
  weeklyReset = false,
  description = "Tracks user specified world quests. Provides information like - Time Left, Reward and availability for current character", 
  override = true
}

Exlist.RegisterModule(data)
