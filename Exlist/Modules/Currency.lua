local key = "currency"
local prio = 0
local currencyAmount = {
}
local GetMoney, GetCurrencyInfo, GetItemCount = GetMoney, GetCurrencyInfo, GetItemCount
local GetItemInfo = GetItemInfo
local math, table = math, table
local WrapTextInColorCode = WrapTextInColorCode
local Exlist = Exlist
local config_defaults = {
  icon = "",
  name = "Name",
  type = "currency",
  enabled = false,
  showSeparate = false
}

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
  -- Check Setting Table
  for name, t in pairs(cur) do
    for i,v in pairs(config_defaults) do
      if t[i] == nil then
        t[i] = v
      end
    end
  end 

  for i=1, GetCurrencyListSize() do
    local name, isHeader, _, _, _, count, icon = GetCurrencyListInfo(i)
    if cur[name] then
      currencyAmount[name] = count
    elseif not isHeader then
      cur[name] = {icon = icon,name = name,type = "currency",enabled = false,showSeparate = false}
      currencyAmount[name] = count
    end 
  end

  for name,v in pairs(cur) do
    if v.type == "item" and v.enabled then
      local amount = GetItemCount(v.name,true)
      table.insert(t.currency,{name=name,amount = amount, texture=v.icon,showSeparate = v.showSeparate})
    elseif v.enabled then
      table.insert(t.currency,{name = name,amount = currencyAmount[name], texture=v.icon,showSeparate = v.showSeparate})
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
        spacer0 = {
          type = "description",
          order = 1.05,
          width = "full",
          name = ""
        },
        label1 = {
          type = "description",
          order = 1.1,
          fontSize = "medium",
          width = "normal",
          name = WrapTextInColorCode("Name","ffffd200")
        },
        label2 = {
          type = "description",
          order = 1.2,
          fontSize = "medium",
          width = "half",
          name = WrapTextInColorCode("Enable","ffffd200")
        },
        label3 = {
          type = "description",
          order = 1.3,
          fontSize = "medium",
          width = "half",
          name = WrapTextInColorCode("Show Separate","ffffd200")
        },
        spacer1 = {
          type = "description",
          order = 1.4,
          width = "normal",
          name = ""
        },
        spacer2 = {
          type = "description",
          order = 998,
          width = "full",
          name = "\n"
        },

    }
  }
  -- update currencies
  Updater()
  local n = 1
  for name,t in pairs(cur) do
    n = n + 1  
    options.args[name..'desc'] = {
        type = "description",
        order = n,
        name = string.format("|T%s:15|t %s",t.icon,name),
        width = "normal"
    }
    options.args[name..'enable'] = {
      type = "toggle",
      order = n+.1,
      name = "  ",
      width = "half",
      get = function() return t.enabled end,
      set = function(self,v) t.enabled = v  AddRefreshOptions() end
    }
    options.args[name..'showSeparate'] = {
      type = "toggle",
      order = n+.2,
      width = "half",
      name = "  ",
      disabled = function() return not t.enabled end,
      get = function() return t.showSeparate end,
      set = function(self,v) t.showSeparate = v  AddRefreshOptions() end
    }
    options.args[name..'spacer'] = {
      type = "description",
      order = n+.3,
      width = "normal",
      name = "",
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
    priority = prio,
    titleName = "Currency",
    data = data.money.gold .. "|cFFd8b21ag|r " .. data.money.silver .. "|cFFadadads|r " .. data.money.coppers .. "|cFF995813c|r",
  }
  local extraInfos = {}

  local currency = data.currency
  if currency then
    local sideTooltip = {body = {},title= WrapTextInColorCode("Currency","ffffd200")}
    local cur = Exlist.ConfigDB.settings.currencies
    for i=1,#currency do
      if currency[i].showSeparate or cur[currency[i].name].showSeparate then
        table.insert(extraInfos,{
          character = character,
          moduleName = key .. currency[i].name,
          priority = prio+i/10,
          titleName = "|T".. (currency[i].texture or "") ..":0|t" .. (currency[i].name or ""),
          data = currency[i].amount,
        })
      end
      table.insert(sideTooltip.body,{"|T".. (currency[i].texture or "") ..":0|t" .. (currency[i].name or ""), currency[i].maxed and WrapTextInColorCode(currency[i].amount, "FFFF0000") or currency[i].amount})
    end
    table.insert(sideTooltip.body,"|cfff2b202To add additional items/currency check out config!")
    info.OnEnter = Exlist.CreateSideTooltip()
    info.OnEnterData = sideTooltip
    info.OnLeave = Exlist.DisposeSideTooltip()
  end
  for i,t in ipairs(extraInfos) do
    Exlist.AddData(t)
  end
  Exlist.AddData(info)
end

local data = {
  name = 'Currency',
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"CURRENCY_DISPLAY_UPDATE","PLAYER_MONEY"},
  weeklyReset = false
}
Exlist.RegisterModule(data)
