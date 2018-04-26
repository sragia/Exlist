local key = "quests"
local prio = 7
local Exlist = Exlist
local colors = Exlist.Colors
local strings = Exlist.Strings

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

local checkFunctions = {}
local questTypes = {
  ["daily"] = "Daily",
  ["weekly"] = "Weekly"
}
local questTypeOrder = {"daily","weekly"}

local trackedQuests = {
  -- [questId] = {enabled = bool,type = string, checkFunction = function,default = bool,showSeparate = bool}
}

local bquestIds = {
  {questId = 44175,name = "World Quest Bonus Event", spellId = 225788}, -- WQ
  {questId = 44171,name = "Legion Dungeon Event", spellId = 225787}, -- Dungeons
  {questId = 44173,name = "Battleground Bonus Event", spellId = 186403}, -- BGs
  {questId = 44172,name = "Arena Skirmish Bonus Event", spellId = 186401}, -- Arenas
  {questId = 44174,name = "Pet Battle Bonus Event", spellId = 186406}, -- Pet Battles
  -- timewalking
  {questId = 44164,name = "Timewalking Dungeon Event", icon = 1129673}, -- BC
  {questId = 44166,name = "Timewalking Dungeon Event", icon = 1129685}, -- Wotlk
  {questId = 45799,name = "Timewalking Dungeon Event", icon = 1530589}, -- MoP
  {questId = 44167,name = "Timewalking Dungeon Event", icon = 1304687} -- Cata
}
local bonusQuestId
function checkFunctions.WeeklyBonusQuest(questId)
  -- Unfortunately can't find this weeks by simple API calls
  local settings = Exlist.ConfigDB.settings
  if bonusQuestId and bonusQuestId == questId then
    -- already have found what quest is this week 
    local name = Exlist.GetCachedQuestTitle(questId)
    local completed = IsQuestFlaggedCompleted(questId)
    settings.unsortedFolder.weekly.bonusQuestId = questId
    return name,true,completed
  elseif bonusQuestId then
    return nil,false,false
  end
  if settings.unsortedFolder.weekly.bonusQuestId and settings.unsortedFolder.weekly.bonusQuestId == questId then
    -- already found it in previous sessions
    bonusQuestId = questId
    local name = Exlist.GetCachedQuestTitle(questId)
    local completed = IsQuestFlaggedCompleted(questId)
    return name,true,completed
  elseif settings.unsortedFolder.weekly.bonusQuestId then
    return nil,false,false
  end
  local holidayNames = {}
  for _,qId in ipairs(bquestIds) do
  -- maybe have already completed
    if IsQuestFlaggedCompleted(qId.questId) then
      bonusQuestId = qId.questId
      if qId.questId == questId then 
        local name = Exlist.GetCachedQuestTitle(questId)
        return name,true,true
      end
      return nil,false,false
    end
    -- Most bonus events have buff associated with them
    if qId.spellId then
      local name = Exlist.AuraFromId("player",qId.spellId,"HELPFUL")
      if name then
        bonusQuestId = qId.questId
        if qId.questId == questId then
          local questName = Exlist.GetCachedQuestTitle(quest)
          return questName,true,false
        end
        return nil,false,false
      end
    end
    holidayNames[qId.name] = qId.questId
  end
  -- oh well time to go hard way
  -- TODO: Somehow make this not rely on holiday name
  local todayDate = date("*t", time()).day
  for i=1,5 do
    local holiday = C_Calendar.GetHolidayInfo(0,todayDate,i)
    if holiday then
      if holidayNames[holiday.name] then
        if holiday.endTime.monthDay > todayDate then
          -- found it !!
          bonusQuestId = holidayNames[holiday.name]
          settings.unsortedFolder.weekly.bonusQuestId = holidayNames[holiday.name]
          if questId == bonusQuestId then
            local name = Exlist.GetCachedQuestTitle(questId)
            local completed = IsQuestFlaggedCompleted(questId)
            return name,true,completed
          end
        end
      end
    end
  end
  -- nope
  return nil,false,false
end

local DEFAULT_QUESTS = {
  -- Same as trackedQuests
  [48799] = {enabled = true, type = "weekly", default = true, showSeparate = false}, -- Fuel of a Doomed World
  [49293] = {enabled = true, type = "weekly", default = true, showSeparate = false}, -- Invasion Onslaught
  [44175] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"}, -- BQ_WQ
  [44171] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_Dungeons
  [44173] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_BGs
  [44172] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_Arenas
  [44174] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_PetBatles
  [44164] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_TW_BC
  [44166] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_TW_Wotlk
  [45799] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_TW_MoP
  [44167] = {enabled = true, type = "weekly", default = true, showSeparate = false, checkFunction = "WeeklyBonusQuest"},-- BQ_TW_Cata
}

local function AddQuest(questId,t)
  -- mby
  if type(questId) ~= "number" then
    print(Exlist.debugString,"Invalid QuestId")
    return
  end
  local dbQuests = Exlist.ConfigDB.settings.quests
  dbQuests[questId] = {enabled = true,type = t,showSeparate = false}
  trackedQuests[questId] = {enabled = true,type = t,showSeparate = false}
end

local function RemoveQuest(questId)
  local dbQuests = Exlist.ConfigDB.settings.quests
  dbQuests[questId] = nil
  trackedQuests[questId] = nil
end

local function ChangeType(questId,oldType,newType)
  trackedQuests[questId].type = newType
  local dbQuests = Exlist.ConfigDB.settings.quests
  dbQuests[questId].type = newType

  local realms = Exlist.GetRealmNames()
  for _,realm in ipairs(realms) do
    local characters = Exlist.GetRealmCharacters(realm)
    for _,character in ipairs(characters) do
      Exlist.Debug("Reset",type,"quests for:",character,"-",realm)
      local data = Exlist.GetCharacterTableKey(realm,character,key)
      if data[oldType] and data[oldType][questId] then
        -- found
        data[newType] = data[newType] or {}
        data[newType][questId] = data[oldType][questId]
        data[oldType][questId] = nil
      end
      Exlist.UpdateChar(key,data,character,realm)
    end
  end

end

local function Updater(event)
  local t = {}
  for questId,v in pairs(trackedQuests) do
    if v.checkFunction then
      local name,available,completed = checkFunctions[v.checkFunction](questId) 
      if available then
        t[v.type] = t[v.type] or {}
        t[v.type][questId] = {name= name,completed = completed}
      end
    else
      local name = Exlist.QuestInfo(questId)
      local completed = IsQuestFlaggedCompleted(questId)
      t[v.type] = t[v.type] or {}
      t[v.type][questId] = {name = name, completed = completed}
    end
  end
  Exlist.UpdateChar(key,t)
end

local function Linegenerator(tooltip,data,character)
  if not data then return end
  local info = {
    character = character,
    priority = prio,
    moduleName = key,
    titleName = "Quests",
  }
  local extraInfos = {}
  local done,available = 0,0
  local sideTooltip = {title = "Quests", body ={}}
  local i = 1
  for _,type in ipairs(questTypeOrder) do
    local v = data[type] or {}
    local added = false
    for questId,values in pairs(v) do
      if trackedQuests[questId].enabled then
        if not added then 
          table.insert(sideTooltip.body,{WrapTextInColorCode(questTypes[type],colors.QuestTypeTitle[type]),"",{"headerseparator"}})
          added = true
        end
        available = available + 1
        done = values.completed and done + 1 or done
        local name = Exlist.GetCachedQuestTitle(questId)
        table.insert(sideTooltip.body,{
          WrapTextInColorCode(name,colors.QuestTitle),
          (values.completed and WrapTextInColorCode("Completed", "FFFF0000") or  WrapTextInColorCode("Available", "FF00FF00"))
        })
        if trackedQuests[questId].showSeparate then
          local settings = Exlist.ConfigDB.settings
          local completedString,availableString = "Completed","Available"
          if settings.shortenInfo then 
            completedString,availableString = "Done","Avail"
          end
          table.insert(extraInfos,{
            character = character,
            moduleName = key .. questId,
            priority = prio+i/1000,
            titleName = WrapTextInColorCode(name,colors.QuestTypeTitle[type]),
            data = (values.completed and WrapTextInColorCode(completedString, "FFFF0000") or  WrapTextInColorCode(availableString, "FF00FF00")),
          })
          i = i + 1
        end
      end
    end
  end
  info.data  = string.format("%i/%i",done,available)
  info.OnEnter = Exlist.CreateSideTooltip()
  info.OnEnterData = sideTooltip
  info.OnLeave = Exlist.DisposeSideTooltip()

  for i,t in ipairs(extraInfos) do
    Exlist.AddData(t)
  end
  if available > 0 then
    Exlist.AddData(info)
  end
end

local function GlobalLineGenerator(tooltip,data)
  if Exlist.ConfigDB.settings.showQuestsInExtra then
    local charData = Exlist.GetCharacterTableKey(GetRealmName(),UnitName("player"),key)
    if charData then
      for _,type in ipairs(questTypeOrder) do
        local v = charData[type] or {}
        local added = false
        for questId,values in pairs(v) do
          if trackedQuests[questId].enabled then
            if not added then 
              Exlist.AddLine(tooltip,WrapTextInColorCode(questTypes[type] .. " Quests",colors.QuestTypeTitle[type]),14)
              added = true
            end
            Exlist.AddLine(tooltip,{
              Exlist.GetCachedQuestTitle(questId),
              (values.completed and WrapTextInColorCode("Completed", "FFFF0000") or  WrapTextInColorCode("Available", "FF00FF00"))
            })
          end
        end
      end
    end
  end
end

local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
end

local function ResetHandle(type)
  local realms = Exlist.GetRealmNames()
  for _,realm in ipairs(realms) do
    local characters = Exlist.GetRealmCharacters(realm)
    for _,character in ipairs(characters) do
      Exlist.Debug("Reset",type,"quests for:",character,"-",realm)
      local data = Exlist.GetCharacterTableKey(realm,character,key)
      wipe(data[type])
      Exlist.UpdateChar(key,data,character,realm)
    end
  end
end

local function SetupQuestConfig(refresh)
  if not Exlist.ConfigDB then return end
  local settings = Exlist.ConfigDB.settings
  local dbQuests = settings.quests
  local options = {
    type = "group",
    name = "Quests",
    args ={
      desc = {
          type = "description",
          order = 1,
          width = "full",
          name = "Controls quests that are being tracked by addon\n"
      },
      note = {
        type = "description",
        order = 1,
        width = "full",
        fontSize = "medium",
        name = strings.Note .. "  Due to restrictions to API Quest Titles might take couple reloads to appear\n"
      },
      showExtraTooltip = {
        order = 1.05,
        name = "Show in Extra Tooltip",
        desc = "Show selected quests and their completetion in extra tooltip for current character",
        type = "toggle",
        width = "full",
        get = function()
            return settings.showQuestsInExtra
        end,
        set = function(self, v)
          settings.showQuestsInExtra = v 
        end,
      },
      itemInput = {
        type = "input",
        order = 1.1,
        name = "Add Quest ID",
        get = function() return "" end,
        set = function(self,v)
          local questId = tonumber(v)
          AddQuest(questId,"daily")
          SetupQuestConfig(true)
          Exlist.SendFakeEvent("EXLIST_REFRESH_QUESTS")
        end,
        width = "full",
      },
      spacer0 = {
        type = "description",
        order = 1.19,
        width = 0.15,
        name = ""
      },
      nameLabel = {
        type = "description",
        order = 1.2,
        width = 1.35,
        fontSize = "large",
        name = WrapTextInColorCode("Quest Title","ffffd200")
      },
      typeLabel = {
        type = "description",
        order = 1.3,
        width = 0.55,
        fontSize = "large",
        name = WrapTextInColorCode("Type","ffffd200")
      },
      separatelabel = {
        type = "description",
        order = 1.4,
        width = 0.75,
        fontSize = "large",
        name = WrapTextInColorCode("Show Separate","ffffd200")
      },
      spacer1 = {
        type = "description",
        order = 1.5,
        width = 0.45,
        name = ""
      },
    }
  }
  local n = 2
  for questId,info in spairs(trackedQuests, function(t,a,b) 
    return t[a].default and not t[b].default
  end) do
    local o = options.args
    o[questId.."enabled"] = {
        order = n,
        name = WrapTextInColorCode(Exlist.GetCachedQuestTitle(questId),Exlist.Colors.QuestTitle),
        type = "toggle",
        width = 1.5,
        get = function()
            return info.enabled
        end,
        set = function(self, v)
            info.enabled = v 
        end,
    }
    n = n + 1
    o[questId.."type"] = {
      order = n,
      name = "",
      type = "select",
      values = questTypes,
      width = 0.5,
      disabled = function() return info.default end,
      get = function()
          return info.type
      end,
      set = function(self, v)
        ChangeType(questId,info.type,v)
      end,
    }
    n = n + 1
    o[questId.."spacer"] = {
      type = "description",
      order = n,
      width = 0.3,
      name = ""
    }
    n = n + 1
    o[questId..'showSeparate'] = {
      type = "toggle",
      order = n,
      width = 0.45,
      descStyle = "inline",
      name = "  ",
      disabled = function() return not info.enabled end,
      get = function() return info.showSeparate end,
      set = function(self,v) 
        info.showSeparate = v
        dbQuests[questId].showSeparate = v
      end
    }
    n = n + 1
    o[questId.."delete"] = {
      type = "execute",
      order = n,
      name = "Delete",
      disabled = function() return info.default end,
      width = 0.5,
      func = function()
        StaticPopupDialogs["DeleteQDataPopup_"..questId] = {
          text = "Do you really want to delete "..WrapTextInColorCode(Exlist.GetCachedQuestTitle(questId),Exlist.Colors.QuestTitle).."?",
          button1 = "Ok",
          button3 = "Cancel",
          hasEditBox = false,
          OnAccept = function(self)
            StaticPopup_Hide("DeleteQDataPopup_"..questId)
            RemoveQuest(questId)
            SetupQuestConfig(true)
            Exlist.NotifyOptionsChange(key)
          end,
          timeout = 0,
          cancels = "DeleteQDataPopup_"..questId,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 4,
          showAlert = 1,
          enterClicksFirstButton = 1
        }
        StaticPopup_Show("DeleteQDataPopup_"..questId)
      end
    }
    n = n + 1
  end
  if not refresh then
    Exlist.AddModuleOptions(key,options,"Quests")
  else
    Exlist.RefreshModuleOptions(key,options,"Quests")
  end
end
Exlist.ModuleToBeAdded(SetupQuestConfig)

local function init()
  -- setup quests
  local dbQuests = Exlist.ConfigDB.settings.quests
  for questId,t in pairs(DEFAULT_QUESTS) do
    if dbQuests[questId] == nil then
      dbQuests[questId] = t 
    end
  end
  -- add all to tracked
  for questId,t in pairs(dbQuests) do
    trackedQuests[questId] = t
  end
end

local data = {
  name = 'Quests',
  key = key,
  linegenerator = Linegenerator,
  globallgenerator = GlobalLineGenerator,
  priority = prio,
  updater = Updater,
  event = {"QUEST_TURNED_IN","PLAYER_ENTERING_WORLD","QUEST_REMOVED","PLAYER_ENTERING_WORLD_DELAYED","EXLIST_REFRESH_QUESTS"},
  weeklyReset = true,
  dailyReset = true,
  description = "Allows user to track different daily or weekly quests",
  specialResetHandle = ResetHandle,
  init = init,
  -- modernize = Modernize  
}

Exlist.RegisterModule(data)
