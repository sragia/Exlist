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

local key = "currency"
local L = Exlist.L
local prio = 10
local currencyAmount = {}
local GetMoney, GetItemCount = GetMoney, GetItemCount
local math, table, pairs = math, table, pairs
local WrapTextInColorCode = WrapTextInColorCode
local print, string, ipairs = print, string, ipairs
local Exlist = Exlist
local colors = Exlist.Colors

local config_defaults = {
   icon = "",
   name = "Name",
   type = "currency",
   enabled = false,
   showSeparate = false
}

--------------------

local currency = EXL:GetModule('module-currency')

currency.useTabs = false
currency.useSplitView = false
currency.dialog = nil

local statusMap = {
   disabled = string.format('|cffdb0012%s|r', L['Disabled']),
   enabled = string.format('|cff00fa11%s|r', L['Enabled']),
   enabledSeparate = string.format('|cff00fa11%s|r', L['Enabled (and show separate)'])
}

currency.Init = function(self)
   optionsController:RegisterModule(self)

   self.dialog = inputDialog:Create()
   self.dialog:SetSuccessButtonText(L['Set'])
   self.dialog:SetCancelButtonText(L['Cancel'])
end

currency.GetName = function(self)
   return L['Currency']
end

currency.GetOrder = function(self)
   return prio
end

currency.Updater = function()
   if (not Exlist.ConfigDB) then
      return
   end
   local t = {}
   local coppers = GetMoney()
   local money = {
      ["gold"] = math.floor(coppers / 10000),
      ["silver"] = math.floor((coppers / 100) % 100),
      ["coppers"] = math.floor(coppers % 100),
      ["totalCoppers"] = coppers
   }
   t.money = money
   t.currency = {}
   local cur = Exlist.ConfigDB.settings.currencies

   -- update all currencies
   -- Check Setting Table
   for name, t in pairs(cur) do
      t = Exlist.AddMissingTableEntries(t, config_defaults)
   end

   for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
      local currency = C_CurrencyInfo.GetCurrencyListInfo(i)
      if cur[currency.name] then
         currencyAmount[currency.name] = currency.quantity
      elseif not currency.isHeader then
         cur[currency.name] = {
            icon = currency.iconFileID,
            name = currency.name,
            type = "currency",
            enabled = false
         }
         currencyAmount[currency.name] = currency.quantity
      end
   end

   for name, v in pairs(cur) do
      if v.type == "item" and v.enabled then
         local amount = GetItemCount(v.name, true)
         table.insert(t.currency, { name = name, amount = amount, texture = v.icon })
      elseif v.enabled then
         table.insert(
            t.currency,
            {
               name = name,
               amount = currencyAmount[name] or (v.id and C_CurrencyInfo.GetCurrencyInfo(v.id).quantity),
               texture = v.icon
            }
         )
      end
   end
   table.sort(t.currency, function(a, b) return a.name < b.name end)
   Exlist.UpdateChar(key, t)
end

currency.GetOptions = function(self)
   local cur = Exlist.ConfigDB.settings.currencies
   local options = {
      {
         type = 'title',
         width = 100,
         label = L['Currency']
      },
      {
         type = 'description',
         width = 100,
         label = L['Enable/Disable Currencies you want to see']
      },
      {
         type = 'toggle',
         width = 100,
         label = L['Hide Empty Currencies'],
         currentValue = function()
            return Exlist.ConfigDB.settings.hideEmptyCurrency
         end,
         onChange = function(value)
            Exlist.ConfigDB.settings.hideEmptyCurrency = value
         end
      },
      {
         type = 'button',
         width = 20,
         label = L['Add Item'],
         onClick = function()
            self.dialog:SetLabel(L['Item ID or Item Name'])
            self.dialog:SetOnSuccess(function(value)
               local iInfo = Exlist.GetCachedItemInfo(value)
               if iInfo and iInfo.name then
                  cur[iInfo.name] = {
                     enabled = true,
                     icon = iInfo.texture,
                     name = iInfo.name,
                     type = "item"
                  }
                  optionsFields:RefreshFields()
               else
                  print(Exlist.debugString, L["Couldn't add item:"], value)
               end
            end)
            self.dialog:ShowDialog()
         end,
         tooltip = {
            text = L['Add Item by item ID or item name'],
         },
         color = { 249 / 255, 95 / 255, 9 / 255, 1 }
      },
      {
         type = 'button',
         width = 20,
         label = L['Add Currency'],
         onClick = function()
            self.dialog:SetLabel(L['Currency ID'])
            self.dialog:SetOnSuccess(function(value)
               local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(value)
               if currencyInfo and currencyInfo.name then
                  cur[currencyInfo.name] = {
                     enabled = true,
                     icon = currencyInfo.iconFileID,
                     name = currencyInfo.name,
                     id = value,
                     type = "currency"
                  }
                  optionsFields:RefreshFields()
               else
                  print(Exlist.debugString, L["Couldn't add currency:"], value)
               end
            end)
            self.dialog:ShowDialog()
         end,
         color = { 249 / 255, 95 / 255, 9 / 255, 1 }
      },
      {
         type = 'spacer',
         width = 60
      }
   }

   self.Updater()

   for name, t in EXL.utils.spairs(cur, function(t, a, b) return t[a].name < t[b].name end) do
      table.insert(options, {
         type = 'description',
         width = 30,
         label = string.format("|T%s:15|t %s", t.icon, name),
      })
      table.insert(options, {
         type = 'dropdown',
         label = L['Status'],
         width = 20,
         getOptions = function()
            return statusMap
         end,
         currentValue = function()
            return t.enabled and t.showSeparate and 'enabledSeparate' or t.enabled and 'enabled' or 'disabled'
         end,
         onChange = function(value)
            if (value == 'enabled') then
               t.enabled = true
               t.showSeparate = false
            elseif (value == 'enabledSeparate') then
               t.showSeparate = true
               t.enabled = true
            elseif (value == 'disabled') then
               t.enabled = false
               t.showSeparate = false
            end
            optionsFields:RefreshFields()
         end
      })
      table.insert(options, {
         type = 'spacer',
         width = 50
      })
   end

   return options
end

currency.Linegenerator = function(tooltip, data, character)
   if not data or not data.money then
      return
   end
   local info = {
      character = character,
      moduleName = key,
      priority = prio,
      titleName = L["Currency"],
      data = Exlist.SeperateThousands(data.money.gold) ..
          "|cFFd8b21ag|r " .. data.money.silver .. "|cFFadadads|r " .. data.money.coppers .. "|cFF995813c|r"
   }
   local extraInfos = {}
   local currency = data.currency
   if currency then
      local sideTooltip = {
         body = {},
         title = WrapTextInColorCode(L["Currency"], colors.sideTooltipTitle)
      }
      local settings = Exlist.ConfigDB.settings
      for i = 1, #currency do
         if
             not (settings.hideEmptyCurrency and not (currency[i].amount and currency[i].amount > 0)) and
             settings.currencies[currency[i].name] and
             settings.currencies[currency[i].name].enabled
         then
            if settings.currencies[currency[i].name].showSeparate then
               table.insert(
                  extraInfos,
                  {
                     character = character,
                     moduleName = key .. currency[i].name,
                     priority = prio + i / 1000,
                     titleName = "|T" .. (currency[i].texture or "") .. ":0|t " .. (currency[i].name or ""),
                     data = currency[i].amount
                  }
               )
            end
            table.insert(
               sideTooltip.body,
               {
                  "|T" .. (currency[i].texture or "") .. ":0|t " .. (currency[i].name or ""),
                  currency[i].maxed and WrapTextInColorCode(currency[i].amount, "FFFF0000") or currency[i].amount
               }
            )
         end
      end
      table.insert(sideTooltip.body, "|cfff2b202" .. L["To add additional items/currency check out config!"] .. "|r")
      info.OnEnter = Exlist.CreateSideTooltip()
      info.OnEnterData = sideTooltip
      info.OnLeave = Exlist.DisposeSideTooltip()
   end
   for i, t in ipairs(extraInfos) do
      Exlist.AddData(t)
   end
   Exlist.AddData(info)
end

local data = {
   name = L["Currency"],
   key = key,
   linegenerator = currency.Linegenerator,
   priority = prio,
   updater = currency.Updater,
   event = { "CURRENCY_DISPLAY_UPDATE", "PLAYER_MONEY", "BAG_UPDATE" },
   description = L["Collects information about different currencies  and user specified item amounts in inventory"],
   weeklyReset = false
}
Exlist.RegisterModule(data)
