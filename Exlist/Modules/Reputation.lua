---@class Exlist
local EXL = select(2, ...)

---@class ExalityFrames
local EXFrames = EXL.EXFrames

---@class ExalityFramesInputDialogFrame
local inputDialog = EXFrames:GetFrame('input-dialog-frame')

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

---@class EXLOptionsFields
local optionsFields = EXL:GetModule('options-fields')

local key = "reputation"
local prio = 95
local Exlist = Exlist
local L = Exlist.L
local settings
local colors = Exlist.Colors

local standingNames = {
   [1] = L["Hated"],
   [2] = L["Hostile"],
   [3] = L["Unfriendly"],
   [4] = L["Neutral"],
   [5] = L["Friendly"],
   [6] = L["Honored"],
   [7] = L["Revered"],
   [8] = L["Exalted"],
   [100] = L["Paragon"]
}

local reputationModule = EXL:GetModule('module-reputation')

reputationModule.dialog = nil

reputationModule.Init = function(self)
   optionsController:RegisterModule(self)

   self.dialog = inputDialog:Create()
   self.dialog:SetSuccessButtonText(L['Set'])
   self.dialog:SetCancelButtonText(L['Cancel'])
end

reputationModule.GetName = function(self)
   return L["Reputation"]
end

reputationModule.GetOrder = function(self)
   return prio
end

local function AddReputationToCache(name, factionID)
   if not name or not factionID then
      return
   end
   local found = false
   for _, faction in ipairs(settings.reputation.cache) do
      if name == faction.name then
         found = true
      end
   end
   if not found then
      table.insert(settings.reputation.cache, { name = name, factionID = factionID })
      table.sort(
         settings.reputation.cache,
         function(a, b)
            return a.name < b.name
         end
      )
   end
end

local function UpdateReputationCache(factionID)
   local ret = false
   factionID = tonumber(factionID)
   if factionID and type(factionID) == "number" then
      local factionData = C_Reputation.GetFactionDataByID(factionID)
      AddReputationToCache(factionData.name, factionID)
      ret = factionData.name
   end
   local numFactions = C_Reputation.GetNumFactions()
   for i = 1, numFactions do
      local factionData = C_Reputation.GetFactionDataByIndex(i)
      if factionData and not factionData.isHeader and factionData.factionID ~= 1168 then -- 1168 = guild rep
         AddReputationToCache(factionData.name, factionData.factionID)
      end
   end
   return ret
end

local function Updater(event)
   local t = {}
   if event == "UPDATE_FACTION" then
      C_Timer.After(
         0.5,
         function()
            Exlist.SendFakeEvent("UPDATE_FACTION_DELAY")
         end
      )
   end
   for _, faction in ipairs(settings.reputation.cache) do
      local factionData = C_Reputation.GetFactionDataByID(faction.factionID)
      local friendshipReputation = C_GossipInfo.GetFriendshipReputation(faction.factionID)
      local isMajorFaction = faction.factionID and C_Reputation.IsMajorFaction(faction.factionID)
      if factionData then
         local curr = factionData.currentStanding - factionData.currentReactionThreshold      -- current
         local max = factionData.nextReactionThreshold - factionData.currentReactionThreshold -- max
         local paragonReward, friendStandingLevel
         local isFriend = false
         local isMax = false
         if (not isMajorFaction and friendshipReputation and friendshipReputation.friendshipFactionID ~= 0) then
            -- Friendship
            curr = friendshipReputation.standing - friendshipReputation.reactionThreshold
            if (friendshipReputation.nextThreshold) then
               max = friendshipReputation.nextThreshold - friendshipReputation.reactionThreshold
            else
               isMax = true
            end
            isFriend = true
            friendStandingLevel = friendshipReputation.reaction
         end
         if
             (not isMajorFaction and factionData.reaction >= (isFriend and 6 or 8) and
                C_Reputation.IsFactionParagon(faction.factionID))
         then
            -- Paragon stuff
            factionData.reaction = 100
            local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon =
                C_Reputation.GetFactionParagonInfo(faction.factionID)
            paragonReward = hasRewardPending
            curr = mod(currentValue, threshold)
            max = threshold
            if hasRewardPending then
               curr = curr + threshold
            end
         end

         if (isMajorFaction) then
            local majorFactionData = C_MajorFactions.GetMajorFactionData(faction.factionID)
            isMax = C_MajorFactions.HasMaximumRenown(faction.factionID)
            local barValue =
                isMax and majorFactionData.renownLevelThreshold or majorFactionData.renownReputationEarned or 0
            local barMax = majorFactionData.renownLevelThreshold
            curr = barValue
            max = barMax
            factionData.reaction = majorFactionData.renownLevel
         end
         t[faction.factionID] = {
            name = factionData.name,
            description = factionData.description,
            standing = factionData.reaction,
            curr = curr,
            isFriend = isFriend,
            isMax = isMax,
            isMajorFaction = isMajorFaction,
            friendStandingLevel = friendStandingLevel,
            max = max,
            paragonReward = paragonReward
         }
      end
   end
   Exlist.UpdateChar(key, t)
end

local function Linegenerator(tooltip, data, character)
   if not data then
      return
   end
   local info = {
      character = character,
      priority = prio,
      moduleName = key,
      titleName = L["Reputation"]
   }

   local ret = false
   local paragonAvailable = false
   local charKey = character.name .. "-" .. character.realm
   if settings.reputation.charOption[charKey] and settings.reputation.charOption[charKey] ~= 0 then
      ret = true
      local factionInfo = data[settings.reputation.charOption[charKey]]
      if (not factionInfo) then
         return
      end
      local text =
          string.format(
             "%s %s",
             Exlist.ShortenText(factionInfo.name, "", true),
             WrapTextInColorCode(
                factionInfo.isMajorFaction and
                string.format(
                   L["R-%s %s/%s"],
                   factionInfo.standing,
                   Exlist.ShortenNumber(factionInfo.curr),
                   Exlist.ShortenNumber(factionInfo.max)
                ) or
                string.format("%s/%s", Exlist.ShortenNumber(factionInfo.curr), Exlist.ShortenNumber(factionInfo.max)),
                factionInfo.isMajorFaction and colors.majorFaction or
                factionInfo.isFriend and colors.friendColors[factionInfo.standing] or
                colors.repColors[factionInfo.standing]
             )
          )
      if factionInfo.paragonReward then
         text = Exlist.AddCheckmark(text, true)
      end
      info.data = text
   else
      info.data = L["None"]
   end
   local sideTooltip = { title = WrapTextInColorCode(L["Reputations"], colors.sideTooltipTitle), body = {} }
   for factionID, factionInfo in pairs(settings.reputation.enabled) do
      if factionInfo.enabled then
         ret = true
         local r = data[factionID]
         if r then
            local text1 = r.name
            local text2 = ""
            if (not r.isMajorFaction and r.standing == 8) or r.isMax then
               text2 =
                   WrapTextInColorCode(
                      r.isMajorFaction and string.format(L["Renown %s"], r.standing) or
                      r.isFriend and r.friendStandingLevel or
                      standingNames[r.standing],
                      r.isMajorFaction and colors.majorFaction or r.isFriend and colors.friendColors[r.standing] or
                      colors.repColors[r.standing]
                   )
            else
               text2 =
                   string.format(
                      "%s (%s/%s)",
                      WrapTextInColorCode(
                         r.isMajorFaction and string.format(L["Renown %s"], r.standing) or
                         r.isFriend and r.friendStandingLevel or
                         standingNames[r.standing],
                         r.isMajorFaction and colors.majorFaction or r.isFriend and colors.friendColors[r.standing] or
                         colors.repColors[r.standing]
                      ),
                      Exlist.ShortenNumber(r.curr),
                      Exlist.ShortenNumber(r.max)
                   )
            end
            if r.paragonReward then
               paragonAvailable = true
               text2 = Exlist.AddCheckmark(text2, true)
            end
            table.insert(sideTooltip.body, { text1, text2 })
         end
      end
   end
   info.OnEnter = Exlist.CreateSideTooltip()
   info.OnEnterData = sideTooltip
   info.OnLeave = Exlist.DisposeSideTooltip()
   info.pulseAnim = paragonAvailable
   if ret then
      Exlist.AddData(info)
   end
end

local function init()
   -- code that will run before any other function
   settings = Exlist.ConfigDB.settings
   UpdateReputationCache()
end

local selectedFaction = 0
reputationModule.GetOptions = function(self)
   -- Make reputation list
   local reps = {}
   local repLookup = {}
   reps[0] = "None"
   repLookup[0] = 0
   for i, reputation in ipairs(settings.reputation.cache) do
      repLookup[i] = reputation.factionID
      reps[i] = reputation.name
   end
   local options = {
      {
         type = 'title',
         width = 100,
         label = L['Reputation']
      },
      {
         type = 'description',
         width = 100,
         label = L['Pick and choose reputations you want to see.']
      },
      {
         type = 'button',
         width = 30,
         label = L['Add Faction ID to list'],
         onClick = function()
            self.dialog:SetLabel(L['Faction ID'])
            self.dialog:SetOnSuccess(function(value)
               local name = UpdateReputationCache(value)
               if name then
                  DevTool:AddData(settings)
                  settings.reputation.enabled[tonumber(value)] = { name = name, enabled = true }
               end
               optionsFields:RefreshFields()
            end)
            self.dialog:ShowDialog()
         end,
         color = { 249 / 255, 95 / 255, 9 / 255, 1 }
      },
      {
         type = 'spacer',
         width = 70,
      },
      {
         type = 'dropdown',
         width = 30,
         label = L['Or Select Faction'],
         getOptions = function()
            return reps
         end,
         currentValue = function()
            return selectedFaction
         end,
         onChange = function(value)
            selectedFaction = value
         end
      },
      {
         type = 'button',
         width = 10,
         label = L['Enable'],
         onClick = function()
            settings.reputation.enabled[repLookup[selectedFaction]] = { name = reps[selectedFaction], enabled = true }
            selectedFaction = 0
            optionsFields:RefreshFields()
         end,
         color = { 249 / 255, 95 / 255, 9 / 255, 1 }
      },
      {
         type = 'description',
         label = L['Curently enabled reputations:'],
         width = 100
      }
   }

   local enabledReps = {}
   enabledReps[0] = "None"
   local added = false
   for factionID, info in pairs(settings.reputation.enabled) do
      if info.enabled then
         added = true
         enabledReps[factionID] = info.name
         table.insert(options, {
            type = 'toggle',
            width = 100,
            label = info.name,
            currentValue = function()
               return info.enabled
            end,
            onChange = function(value)
               info.enabled = value
               for char, fID in pairs(settings.reputation.charOption) do
                  if (factionID == fID) then
                     settings.reputation.charOption[char] = 0
                  end
               end
               optionsFields:RefreshOptions()
            end
         })
      end
   end
   if not added then
      table.insert(options, {
         type = 'description',
         label = L['None'],
         width = 100
      })
   end

   table.insert(options, {
      type = 'spacer',
      width = 100
   })

   table.insert(options, {
      type = 'title',
      size = 14,
      width = 100,
      label = L['Character Reputations']
   })
   table.insert(options, {
      type = 'description',
      label = L['Pick reputation that are shown as main one for each character'],
      width = 100
   })

   for char, v in EXL.utils.spairs(
      settings.allowedCharacters,
      function(t, a, b)
         return t[a].order < t[b].order
      end
   ) do
      if v.enabled then
         table.insert(options, {
            type = 'dropdown',
            width = 30,
            getOptions = function()
               return enabledReps
            end,
            label = string.format("|c%s%s", v.classClr, v.name),
            currentValue = function()
               return settings.reputation.charOption[char] or 0
            end,
            onChange = function(value)
               settings.reputation.charOption[char] = value
            end
         })
         table.insert(options, {
            type = 'spacer',
            width = 70,
         })
      end
   end

   return options
end

local data = {
   name = L["Reputation"],
   key = key,
   linegenerator = Linegenerator,
   priority = prio,
   updater = Updater,
   event = {
      "PLAYER_ENTERING_WORLD",
      "UPDATE_FACTION",
      "UPDATE_FACTION_DELAY",
      "QUEST_TURNED_IN",
      "QUEST_REMOVED",
      "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
      "MAJOR_FACTION_UNLOCKED"
   },
   weeklyReset = false,
   dailyReset = false,
   description = L["Allows to select different reputation progress for your characters"],
   init = init
}

Exlist.RegisterModule(data)
