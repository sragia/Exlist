local key = "worldquests"
local prio = 100
local Exlist = Exlist
local table,pairs,ipairs,type,math,time,GetTime,string,tonumber,print = table,pairs,ipairs,type,math,time,GetTime,string,tonumber,print
local C_TaskQuest, IsQuestFlaggedCompleted = C_TaskQuest, IsQuestFlaggedCompleted
local GetQuestLogRewardInfo,GetNumQuestLogRewardCurrencies,GetQuestLogRewardCurrencyInfo,GetQuestLogRewardMoney = GetQuestLogRewardInfo,GetNumQuestLogRewardCurrencies,GetQuestLogRewardCurrencyInfo,GetQuestLogRewardMoney
local GetCurrentMapAreaID, SetMapByID, ToggleWorldMap = GetCurrentMapAreaID, SetMapByID, ToggleWorldMap
local GetCurrencyInfo, GetSpellInfo, GetItemSpell = GetCurrencyInfo, GetSpellInfo, GetItemSpell
local loadstring = loadstring
local WrapTextInColorCode = WrapTextInColorCode
local trackedQuests = {
}
local updateFrq = 30 -- every x minutes max
local lastTrigger = 0
local colors = Exlist.Colors

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

local rewardRules = {}
local tmpConfigRule = {
  ruleType = "",
  compareValue = ">",
  rewardName = "",
  amount = 0
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

local apSpell = GetSpellInfo(228111)
local function IsAPItem(itemId)
  local itemSpell = GetItemSpell(itemId)
  return itemSpell and itemSpell == apSpell
end


local function GetQuestRewards(questId)
    local rewards = {}
    C_TaskQuest.RequestPreloadRewardData(questId)
    local name, texture, numItems, quality, isUsable, itemId = GetQuestLogRewardInfo(1,questId)
    if name then
      local itemType = "item"
      if IsAPItem(itemId) then
        itemType = "artifactpower"
        name = "Artifact Power"
        numItems = Exlist.GetCachedArtifactPower(itemId)
      end
      table.insert( rewards,{name = name,amount = numItems,texture = texture, type = itemType})
    end
    local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questId)
    if numQuestCurrencies > 0 then
       for i=1,numQuestCurrencies do
         local name, texture, numItems = GetQuestLogRewardCurrencyInfo(i,questId)
         if name then
            table.insert( rewards, {name = name, amount = numItems,texture = texture, type = "currency"})
        end
       end
    end
    local coppers = GetQuestLogRewardMoney(questId)
    if coppers and coppers > 0 then
        table.insert(rewards,{name = "Gold",amount = {
          ["gold"] = math.floor(coppers / 10000),
          ["silver"] = math.floor((coppers / 100)%100),
          ["coppers"] = math.floor(coppers%100)
        }, type = "money"})
    end
    return rewards
end

local function compare(current,target,comp)
  if not current or not target then return false end
  comp = comp or ">="
  -- reduce numbers because of overflows
  current = current / 1000
  target = target / 1000
  local ret = loadstring(string.format("return %f %s %f",current,comp,target))
  return ret()
end

local function CheckRewardRules(rewards)
  if not rewards then return end
  local rules = Exlist.ConfigDB.settings.wqRules
  for i,reward in ipairs(rewards) do
    if rules[reward.type] and rules[reward.type][reward.name] then
      local rule = rules[reward.type][reward.name]
      -- rule for this
      if reward.type == "money" then
        return compare(reward.amount.gold,rule.amount,rule.compare), rule.id
      else
        return compare(reward.amount,rule.amount,rule.compare), rule.id
      end
    end
  end
  return false
end

local function CleanTable(id)
  if not id then return end
  local gt = Exlist.GetCharacterTableKey("global","global",key)
  for questId, info in pairs(gt) do
    if info.ruleid and info.ruleid == id then
      gt[questId] = nil
    end
  end
  Exlist.UpdateChar(key,gt,"global","global")
end

local function RemoveRule(rewardId,rewardType)
  if not rewardId or not rewardType then return end
  local rules = Exlist.ConfigDB.settings.wqRules
  CleanTable(rules[rewardType][rewardId].id)
  rules[rewardType][rewardId] = nil
end

local function SetQuestRule(rewardId,rewardType,amount,compare)
  if not rewardId or not rewardType then return end
  amount = amount or 1
  compare = compare or ">="
  local name = rewardId
  if type(tonumber(name) or "") == "number" then
    if rewardType == "item" then
      name = Exlist.GetCachedItemInfo(rewardId).name
    elseif rewardType == "currency" then
      name = GetCurrencyInfo(rewardId)
    end
  else
    name = rewardRules.DEFAULT[rewardType].values[rewardId] or rewardId
  end
  local rules = Exlist.ConfigDB.settings.wqRules
  if rules[rewardType] and rules[rewardType][name] then
    RemoveRule(name,rewardType) -- remove previously set rule
  end
  local id = GetTime() -- for cleaning up when removed
  rules[rewardType] = rules[rewardType] or {}
  rules[rewardType][name] = {amount = amount, compare = compare, id = id}
end

function Exlist.ScanQuests()
  -- add refresh quests
  if not Exlist.ConfigDB then return end
  local settings = Exlist.ConfigDB.settings
  local rt = {}
  local tl = 100
  for questId,info in pairs(settings.worldQuests) do
    trackedQuests[questId] = {enabled = info.enabled , readOnly = false}
  end
  if Exlist.GetTableNum(trackedQuests) < 1 then return end
  local currMapId = GetCurrentMapAreaID()
  for index,zoneId in ipairs(zones) do
    SetMapByID(zoneId)
    local wqs = C_TaskQuest.GetQuestsForPlayerByMapID(zoneId)
    for _,info in pairs(wqs or {}) do
      local timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(info.questId)
      local rewards = GetQuestRewards(info.questId)
      local checkRules,ruleid = CheckRewardRules(rewards)
      if (trackedQuests[info.questId] and trackedQuests[info.questId].enabled) or checkRules then
        local name = C_TaskQuest.GetQuestInfoByQuestID(info.questId)
        local endTime = time() + (timeLeft * 60)
        Exlist.Debug("Spotted",name,"world quest - ",key)
        rt[#rt+1] = {
          name = name,
          questId = info.questId,
          endTime = endTime,
          rewards = rewards,
          zoneId = zoneId,
          ruleid = ruleid, 
        }
      end
      -- optimization (scan only once an half hour)
      tl = tl > timeLeft and timeLeft or tl
    end
  end
  SetMapByID(currMapId)
  if tl < updateFrq then
    lastTrigger = lastTrigger - ((updateFrq - tl) * 60)
  end
  if #rt > 0 then
    Exlist.SendFakeEvent("WORLD_QUEST_SPOTTED",rt)
  end
end

local function RemoveExpiredQuest(questId)
  local gt = Exlist.GetCharacterTableKey("global","global",key)
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
    GetTime() - lastTrigger > (60 * updateFrq)
  then 
    lastTrigger = GetTime()
    Exlist.ScanQuests()
    return 
  elseif event == "WORLD_QUEST_SPOTTED" then
    local gt = Exlist.GetCharacterTableKey("global","global",key)
    if questInfo and #questInfo > 0 then
      local wq = Exlist.ConfigDB.settings.worldQuests
      for i,info in ipairs(questInfo) do
        if (wq[info.questId] or info.ruleid) and not gt[info.questId] then
          gt[info.questId] = info
        elseif wq[info.questId] or info.ruleid then
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
      if info.endTime < timeNow or (wq[questId] and not wq[questId].enabled) then 
        RemoveExpiredQuest(questId)
      else
        if first then Exlist.AddLine(tooltip,{WrapTextInColorCode("World Quests","ffffd200")},14) first = false end
        local lineNum = Exlist.AddLine(tooltip,{info.name,
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

        local sideTooltip = {title = WrapTextInColorCode("Rewards", colors.QuestTitle), body = {}}
        for i,reward in ipairs(info.rewards) do
          if reward.name == "Gold" then
          table.insert(sideTooltip.body,{reward.amount.gold .. "|cFFd8b21ag|r " .. reward.amount.silver .. "|cFFadadads|r " .. reward.amount.coppers .. "|cFF995813c|r"})
          elseif reward.type == "artifactpower" then
            table.insert(sideTooltip.body,{string.format("%s Artifact Power", Exlist.ShortenNumber(reward.amount))})
          else
            if reward.amount > 1 then
              table.insert(sideTooltip.body,string.format( "%ix|T%s:12|t%s",reward.amount,reward.texture,reward.name))
            else
             table.insert(sideTooltip.body,string.format( "|T%s:12|t%s",reward.texture,reward.name))
            end
          end
        end
        Exlist.AddScript(tooltip,lineNum,nil,"OnEnter",Exlist.CreateSideTooltip(),sideTooltip)
        Exlist.AddScript(tooltip,lineNum,nil,"OnLeave",Exlist.DisposeSideTooltip())
      end
    end 
  end
end


local function SetupWQConfig(refresh)
  if not Exlist.ConfigDB then return end
  local wq = Exlist.ConfigDB.settings.worldQuests
  local wqRules = Exlist.ConfigDB.settings.wqRules
  local options = {
    type = "group",
    name = "World Quests",
    args ={
        desc = {
            type = "description",
            order = 1,
            width = "full",
            name = "Add World Quests you want to see"
        },
        forceRefresh = {
          type = "execute",
          order = 1.1,
          width = 1,
          desc = "Force Refresh World Quests",
          name = "Force Refresh",
          func = function()
            lastTrigger = 0
            ToggleWorldMap()
            ToggleWorldMap()
            
          end,
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
            else
              print(Exlist.debugString,"Invalid World Quest ID:",v)
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
          return WrapTextInColorCode(name,colors.QuestTitle)
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
          text = "Do you really want to delete "..WrapTextInColorCode(info.name,colors.QuestTitle).."?",
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

  -- Rules
  n = n + 1
  options.args["WQRulesTitle"] = {
    type = "description",
    order = n,
    fontSize = "large",
    width = "full",
    name = WrapTextInColorCode("\nWorld Quest rules", colors.Config.heading2)
  }
  n = n + 1
  options.args["WQRulesdesc"] = {
    type = "description",
    order = n,
    width = "full",
    name = "Add rules by which addon is going to track world quests. \nFor example, show all world quest that have more than 3 Bloods of Sargeras"
  }
  n = n + 1
  options.args["WQRulesType"] = {
    type = "select",
    order = n,
    width = 1,
    name = "Reward Type",
    values = rewardRules.types,
    get = function() 
      if tmpConfigRule.ruleType == "" then
        tmpConfigRule.ruleType = rewardRules.defaultType
      end
      return tmpConfigRule.ruleType
    end,
    set = function(_,v) 
      tmpConfigRule.ruleType = v
      tmpConfigRule.rewardName = rewardRules.DEFAULT[v].defaultValue
      SetupWQConfig(true)
     end,
  }
  n = n + 1
  options.args["WQRulesName"] = {
    type = "select",
    order = n,
    width = 1,
    name = "Reward Name",
    disabled = function() 
      if not rewardRules.DEFAULT[tmpConfigRule.ruleType] then
        tmpConfigRule.ruleType = rewardRules.defaultType
      end
      return rewardRules.DEFAULT[tmpConfigRule.ruleType].disableItems
    end,
    values = function()
      if not rewardRules.DEFAULT[tmpConfigRule.ruleType] then
        tmpConfigRule.ruleType = rewardRules.defaultType
      end
      return rewardRules.DEFAULT[tmpConfigRule.ruleType].values
    end,
    get = function() 
      if tmpConfigRule.rewardName == "" then
          tmpConfigRule.rewardName = rewardRules.DEFAULT[tmpConfigRule.ruleType].defaultValue
      end
      return tmpConfigRule.rewardName 
    end,
    set = function(_,v) 
      tmpConfigRule.rewardName = v
      SetupWQConfig(true)
     end,
  }
  n = n + 1
  options.args["WQRulesCompare"] = {
    type = "select",
    order = n,
    width = 0.3,
    name = "Amount",
    values = rewardRules.compareValues,
    get = function() return tmpConfigRule.compareValue end,
    set = function(_,v) 
      tmpConfigRule.compareValue = v
      SetupWQConfig(true)
     end,
  }
  n = n + 1
  options.args["WQRulesAmount"] = {
    type = "input",
    order = n,
    width = 0.6,
    name = "",
    get = function() 
      return tostring(tmpConfigRule.amount) 
    end,
    set = function(_,v) 
      tmpConfigRule.amount = tonumber(v) or 0
      SetupWQConfig(true)
     end,
  }
  n = n + 1
  options.args["WQRulesSaveBtn"] = {
    type = "execute",
    order = n,
    width = 0.4,
    name = "Save",
    func = function() 
    local name = rewardRules.DEFAULT[tmpConfigRule.ruleType].customFieldValue == tmpConfigRule.rewardName and tmpConfigRule.customReward or tmpConfigRule.rewardName 
      SetQuestRule(name,tmpConfigRule.ruleType,tmpConfigRule.amount,tmpConfigRule.compareValue)
      lastTrigger = 0
      SetupWQConfig(true)
    end,
  }

  -- for custom rewards
  if rewardRules.DEFAULT[tmpConfigRule.ruleType].useCustom and rewardRules.DEFAULT[tmpConfigRule.ruleType].customFieldValue == tmpConfigRule.rewardName then
    n = n + 1
    options.args["WQRulesCustomName"] = {
    type = "input",
    order = n,
    width = "full",
    name = "Custom Reward",
    get = function()
    return tmpConfigRule.customReward or "" end,
    set = function(_,v) 
      tmpConfigRule.customReward = v
      SetupWQConfig(true)
     end,
    }
  end

  -- setup all rules 
  local wqRules = Exlist.ConfigDB.settings.wqRules
  for rewardType,t in pairs(wqRules) do
    for rewardName,info in pairs(t) do
      n = n + 1
      options.args["WQRulesListItemName"..rewardName] = {
        type = "description",
        order = n,
        width = 0.8,
        fontSize = "small",
        name = rewardName or "",
      }
      n = n + 1
      options.args["WQRulesListItemCompare"..rewardName] = {
        type = "description",
        order = n,
        width = 0.1,
        fontSize = "small",
        name = info.compare or "",
      }
      n = n + 1
      options.args["WQRulesListItemAmount"..rewardName] = {
        type = "description",
        order = n,
        width = 1.5,
        fontSize = "small",
        name = Exlist.ShortenNumber(info.amount or 0,1),
      }
      n = n + 1
      options.args["WQRulesListItemDelete"..rewardName] = {
      type = "execute",
      order = n,
      name = "Delete",
      width = 0.5,
      func = function()
        StaticPopupDialogs["DeleteWQRuleDataPopup_"..rewardName] = {
          text = "Do you really want to delete this rule?",
          button1 = "Ok",
          button3 = "Cancel",
          hasEditBox = false,
          OnAccept = function(self)
            StaticPopup_Hide("DeleteWQRuleDataPopup_"..rewardName)
            RemoveRule(rewardName,rewardType)
            SetupWQConfig(true)
            Exlist.NotifyOptionsChange(key)
          end,
          timeout = 0,
          cancels = "DeleteWQRuleDataPopup_"..rewardName,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 4,
          showAlert = 1,
          enterClicksFirstButton = 1
        }
        StaticPopup_Show("DeleteWQRuleDataPopup_"..rewardName)
      end
    }
    end
  end



  if not refresh then
    Exlist.AddModuleOptions(key,options,"World Quests")
  else
    Exlist.RefreshModuleOptions(key,options,"World Quests")
  end
end
Exlist.ModuleToBeAdded(SetupWQConfig)

local function init()
  rewardRules = {
    types = {
      currency = "Currency",
      item = "Item",
      money = "Gold",
      artifactpower = "Artifact Power"
    },
    compareValues = {
      ["<"] = "<",
      ["<="] = "<=",
      ["="] = "=",
      [">"] = ">",
      [">="] = ">="
    },
    DEFAULT = {
      currency = {
        values = {
          [1220] = GetCurrencyInfo(1220), -- Order Resources
          [1508] = GetCurrencyInfo(1508), -- Veiled Argunite
          [1226] = GetCurrencyInfo(1226), -- Nethershard
          [0] = "Custom Currency",
        },
        defaultValue = 1220,
        disableItems = false,
        useCustom = true,
        customFieldValue = 0,
      },
      artifactpower = {
        values = {
          artifactpower = "Artifact Power",
        },
        defaultValue = "artifactpower",
        disableItems = true,
        useCustom = false
      },
      item = {
        values = {
        [124124] = Exlist.GetCachedItemInfo(124124).name, -- Blood of Sargeras
        [137642] = Exlist.GetCachedItemInfo(137642).name, -- Mark of Honor
        [151568] = Exlist.GetCachedItemInfo(151568).name, -- Primal Sargerite
        [0] = "Custom",
        },
        defaultValue = 124124,
        disableItems = false,
        useCustom = true,
        customFieldValue = 0,
      },
      money = {
        values = {
          gold = "Gold",
        },
        defaultValue = "gold",
        disableItems = true,
        useCustom = false,
      },
    },
    defaultType = "currency",
  }
  tmpConfigRule.ruleType = rewardRules.defaultType
end

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
  override = true,
  init = init,
}

Exlist.RegisterModule(data)
