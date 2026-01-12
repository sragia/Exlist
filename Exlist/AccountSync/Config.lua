---@class Exlist
local EXL = select(2, ...)

local configDB = Exlist.ConfigDB
local L = Exlist.L
Exlist.accountSync = {
   init = function()
      configDB = Exlist.ConfigDB
      configDB.accountSync =
          Exlist.AddMissingTableEntries(
             configDB.accountSync or {},
             {
                enabled = false,
                pairedCharacters = {},
                accountName = "Account " .. Exlist.GenerateRandomString(4),
                displaySyncProgress = true,
                tickerFrequency = 180
             }
          )
   end,
}

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

---@class EXLOptionsFields
local optionsFields = EXL:GetModule('options-fields')

--------------------

local config = EXL:GetModule('account-sync-config')

config.useTabs = false
config.useSplitView = false
config.tmpConfigs = {}

config.Init = function(self)
   optionsController:RegisterModule(self)
end

config.GetName = function(self)
   return L['Account Sync']
end

config.GetOrder = function(self)
   return 4
end

config.GetOptions = function(self)
   return {
      {
         type = 'title',
         width = 100,
         label = L['Account Sync']
      },
      {
         type = 'description',
         width = 100,
         label = L['Allow sharing character data across multiple accounts']
      },
      {
         type = 'toggle',
         width = 100,
         label = L['Enable'],
         currentValue = function()
            return configDB.accountSync.enabled
         end,
         onChange = function(value)
            configDB.accountSync.enabled = value
         end
      },
      {
         type = 'toggle',
         width = 100,
         label = L['Display Sync Progress'],
         currentValue = function()
            return configDB.accountSync.displaySyncProgress
         end,
         onChange = function(value)
            configDB.accountSync.displaySyncProgress = value
         end
      },
      {
         type = 'editbox',
         width = 30,
         label = L['User Key'],
         currentValue = function()
            return configDB.accountSync.userKey or ''
         end,
         onChange = function(value)
            configDB.accountSync.userKey = value
         end
      },
      {
         type = 'button',
         width = 20,
         label = L['Generate User Key'],
         onClick = function()
            configDB.accountSync.userKey = Exlist.GenerateRandomString(6)
            optionsFields:RefreshFields()
         end,
         color = { 249 / 255, 95 / 255, 9 / 255, 1 }
      },
      {
         type = 'spacer',
         width = 50
      },
      {
         type = 'editbox',
         width = 30,
         label = L['Account Name'],
         currentValue = function()
            return configDB.accountSync.accountName or ''
         end,
         onChange = function(value)
            configDB.accountSync.accountName = value
         end
      },
      {
         type = 'spacer',
         width = 70
      },
      {
         type = 'editbox',
         width = 30,
         label = L['Update Frequency (in seconds)'],
         currentValue = function()
            return configDB.accountSync.tickerFrequency or 180
         end,
         onChange = function(value)
            local num = tonumber(value)
            if (num) then
               configDB.accountSync.tickerFrequency = num
            end
         end
      },
      {
         type = 'spacer',
         width = 70
      },
      {
         type = 'editbox',
         width = 30,
         label = L['Character To Sync With'],
         currentValue = function()
            return config.tmpConfigs.charToSync or ''
         end,
         onChange = function(value)
            config.tmpConfigs.charToSync = value
         end
      },
      {
         type = 'button',
         width = 20,
         label = L['Sync'],
         onClick = function()
            if (config.tmpConfigs.charToSync and config.tmpConfigs.charToSync ~= "") and configDB.accountSync.userKey then
               Exlist.accountSync.pairAccount(config.tmpConfigs.charToSync, configDB.accountSync.userKey)
            end
         end,
         color = { 249 / 255, 95 / 255, 9 / 255, 1 },
      }
   }
end
