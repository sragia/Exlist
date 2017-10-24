local key = "currency"
local CURRENCIES = {
  1220, -- Order Hall Resources
  1342, -- Legionfall War Supplies
  1226, -- Nethershards
  1275, -- Curious Coins
  1508, -- Veiled Argunite
}
local ITEMS = {
  124124, -- Blood of Sargeras
  153190, -- Fel-Spotted Egg
}
local GetMoney, GetCurrencyInfo, GetItemCount = GetMoney, GetCurrencyInfo, GetItemCount
local GetItemInfo = GetItemInfo
local math, table = math, table
local WrapTextInColorCode = WrapTextInColorCode
local CharacterInfo = CharacterInfo

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
  for i = 1, #CURRENCIES do
    local name, amount, texture, _, _, max = GetCurrencyInfo(CURRENCIES[i])
    local temp = {
      name = name,
      amount = amount,
      texture = texture,
      maxed = max > 0 and amount >= max or false
    }
    table.insert(t.currency, temp)
  end
  for i = 1, #ITEMS do
    local amount = GetItemCount(ITEMS[i],true)
    local itemInfo = CharacterInfo.GetCachedItemInfo(ITEMS[i])
    local temp = {
      name = itemInfo.name,
      amount = amount,
      texture = itemInfo.texture
    }
    table.insert(t.currency, temp)

  end
  CharacterInfo.UpdateChar(key,t)
end

local function Linegenerator(tooltip,data)
  if not data or not data.money then return end
  local lineNum = CharacterInfo.AddLine(tooltip,data.money.gold .. "|cFFd8b21ag|r " .. data.money.silver .. "|cFFadadads|r " .. data.money.coppers .. "|cFF995813c|r")
  local currency = data.currency
  if currency then
    local sideTooltip = {body = {},title= WrapTextInColorCode("Currency","ffffd200")}
    for i=1,#currency do
      table.insert(sideTooltip.body,{"|T".. (currency[i].texture or "") ..":0|t" .. (currency[i].name or ""), currency[i].maxed and WrapTextInColorCode(currency[i].amount, "FFFF0000") or currency[i].amount})
    end
    CharacterInfo.AddScript(tooltip,lineNum,nil,"OnEnter",CharacterInfo.CreateSideTooltip(),sideTooltip)
    CharacterInfo.AddScript(tooltip,lineNum,nil,"OnLeave", CharacterInfo.DisposeSideTooltip())
  end
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
CharacterInfo.RegisterModule(data)
