local key = "currency"
local currencyAmount = {
}
local GetMoney, GetCurrencyInfo, GetItemCount = GetMoney, GetCurrencyInfo, GetItemCount
local GetItemInfo = GetItemInfo
local math, table = math, table
local WrapTextInColorCode = WrapTextInColorCode
local Exlist = Exlist
local function AddRefreshOptions() end
local function Updater(event)
  local t = {}
  local coppers = GetMoney()
  local money = {
    ["gold"] = math.floor(coppers / 10000),
    ["silver"] = math.floor((coppers / 100)%100),
    ["coppers"] = math.floor(coppers%100)
  }
  t.money = money
  t.currency = {}
  local cur = Exlist.ConfigDB.settings.currencies

  -- update all currencies
  for i=1, GetCurrencyListSize() do
    local name, isHeader, _, _, _, count, icon = GetCurrencyListInfo(i)
    if cur[name] then
      currencyAmount[name] = count
    elseif not isHeader then
      cur[name] = {icon = icon,name = name,type = "currency",enabled = false}
      currencyAmount[name] = count
    end 
  end
  for name,v in pairs(cur) do
    if v.type == "item" and v.enabled then
      local amount = GetItemCount(v.name,true)
      table.insert(t.currency,{name=name,amount = amount, texture=v.icon})
    elseif v.enabled then
      table.insert(t.currency,{name = name,amount = currencyAmount[name], texture=v.icon})
    end
  end
  Exlist.UpdateChar(key,t)
end
local added = false
local function AddRefreshOptions()
  if not Exlist.ConfigDB then return end
  local cur = Exlist.ConfigDB.settings.currencies
  local options = {
    type = "group",
    name = "Currency",
    args ={
        desc = {
            type = "description",
            order = 1,
            width = "full",
            name = "Enable/Disable Currencies you want to see"
        },
        spacer1 = {
          type = "description",
          order = 998,
          width = "full",
          name = "\n\n"
        },
        spacer2 = {
          type = "description",
          order = 999   ,
          width = "full",
          name = "\n\n"
        }

    }
  }
  -- update currencies
  Updater()

  local n = 1
  for name,t in pairs(cur) do
    n = n + 1  
    options.args[name] = {
        type = "toggle",
        order = n,
        name = string.format("|T%s:20|t %s",t.icon,name),
        get = function() return t.enabled end,
        set = function(self,v) t.enabled = v  AddRefreshOptions() end
    }
  end
  options.args["itemInput"] ={
    type = "input",
    order = 1000,
    name = " Add Item (|cffffffffInput itemID or item name|r)",
    get = function() return "" end,
    set = function(self,v)
      local iInfo = Exlist.GetCachedItemInfo(v)
      cur[iInfo.name] = {
        enabled = true,
        icon = iInfo.texture,
        name = iInfo.name,
        type = "item"
      }
      AddRefreshOptions()
    end
  }
  if not added then
    Exlist.AddModuleOptions(key,options,"Currency")
    added = true
  else
    Exlist.RefreshModuleOptions(key,options,"Currency")
  end
end
Exlist.ModuleToBeAdded(AddRefreshOptions)

local function Linegenerator(tooltip,data,character)
  if not data or not data.money then return end
  local info = {
    character = character,
    moduleName = key,
    titleName = "Currency",
    data = data.money.gold .. "|cFFd8b21ag|r " .. data.money.silver .. "|cFFadadads|r " .. data.money.coppers .. "|cFF995813c|r",
  }

  local currency = data.currency
  if currency then
    local sideTooltip = {body = {},title= WrapTextInColorCode("Currency","ffffd200")}
    for i=1,#currency do
      table.insert(sideTooltip.body,{"|T".. (currency[i].texture or "") ..":0|t" .. (currency[i].name or ""), currency[i].maxed and WrapTextInColorCode(currency[i].amount, "FFFF0000") or currency[i].amount})
    end
    table.insert(sideTooltip.body,"|cfff2b202To add additional items/currency check out config!")
    info.OnEnter = Exlist.CreateSideTooltip()
    info.OnEnterData = sideTooltip
    info.OnLeave = Exlist.DisposeSideTooltip()
  end
  Exlist.AddData(tooltip,info)
end

local data = {
  name = 'Currency',
  key = key,
  linegenerator = Linegenerator,
  priority = 0,
  updater = Updater,
  event = {"CURRENCY_DISPLAY_UPDATE","PLAYER_MONEY"},
  weeklyReset = false
}
Exlist.RegisterModule(data)
