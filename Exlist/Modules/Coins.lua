local key = "coins"
local prio = 60
local MAX_CHARACTER_LEVEL = 110
local UnitLevel, IsQuestFlaggedCompleted, GetCurrencyInfo = UnitLevel, IsQuestFlaggedCompleted, GetCurrencyInfo
local pairs, table = pairs, table
local WrapTextInColorCode = WrapTextInColorCode
local Exlist = Exlist

local function Updater(event)
  if UnitLevel('player') < MAX_CHARACTER_LEVEL then return end
  local coinsQuests = UnitLevel'player' <= 100 and {[36058] = 1, [36055] = 1, [37452] = 1, [37453] = 1, [36056] = 1, [37457] = 1, [37456] = 1, [36054] = 1, [37455] = 1, [37454] = 1, [36057] = 1, [37458] = 1, [37459] = 1, [36060] = 1, } or
  {
    [43895] = 1, 
    [43897] = 1, 
    [43896] = 1, 
    [43892] = 1, 
    [43893] = 1, 
    [43894] = 1, 
    [43510] = 1, -- Order Hall
    [47851] = 1, 
    [47864] = 1,
    [47865] = 1, 
  }
  local coinsCurrency = UnitLevel'player' <= 100 and 1129 or 1273
  local count = 0
  local quests = {}
  for id, _ in pairs(coinsQuests) do
    if IsQuestFlaggedCompleted(id) then
      local title = Exlist.GetCachedQuestTitle(id)
      table.insert(quests,title)
      count = count + 1
    end
  end
  local _, amount, _, _, _, totalMax, _, _ = GetCurrencyInfo(coinsCurrency)
  local table = {
    ["curr"] = amount,
    ["max"] = totalMax,
    ["available"] = 3 - count,
    ["quests"] = quests
  }
  Exlist.UpdateChar(key,table)
end

local function Linegenerator(tooltip,data,character)
  if not data then return end
  local settings = Exlist.ConfigDB.settings
  local availableCoins = data.available > 0 and WrapTextInColorCode(settings.shortenInfo and "+" .. data.available or (data.available .. " available!"), "ff00ff00") or ""
  local info = {
    data = data.curr .. "/" .. data.max .. " " .. availableCoins,
    character = character,
    priority = prio,
    moduleName = key,
    titleName = "Coins"
  }
  if data.quests and #data.quests > 0 then
    local sideTooltip = {title = WrapTextInColorCode("Quests Done This Week","ffffd200"), body = {}}
    for i=1,#data.quests do
      table.insert(sideTooltip.body,WrapTextInColorCode("[" .. data.quests[i] .. "]","fffee400"))
    end
    info.OnEnter = Exlist.CreateSideTooltip()
    info.OnEnterData = sideTooltip
    info.OnLeave = Exlist.DisposeSideTooltip()
  end
  Exlist.AddData(info)
end

local data = {
  name = 'Coins',
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"CURRENCY_DISPLAY_UPDATE","QUEST_FINISHED","QUEST_TURNED_IN"},
  description = "Tracks currently available bonus roll coins and amount of coins available from weekly quests",
  weeklyReset = false
}

Exlist.RegisterModule(data)
