local key = "character"
local prio = 10
local Exlist = Exlist
local L = Exlist.L
local colors = Exlist.Colors

local function Updater(event, ...)
   local name = UnitName("player")
   local realm = GetRealmName()
   local t = Exlist.GetCharacterTableKey(realm, name, key) or {}
   if (event == "TIME_PLAYED_MSG") then
      local totalTimePlayed, timePlayedThisLevel = ...
      if (totalTimePlayed) then
         t.totalPlayed = totalTimePlayed
         t.totalPlayedLevel = timePlayedThisLevel
         t.totalPlayedReqTime = time()
      end
   elseif (event == "PLAYER_LOGOUT" and t.totalPlayedReqTime) then
      local sessionTime = time() - t.totalPlayedReqTime
      t.totalPlayed = t.totalPlayed + sessionTime
      t.totalPlayedLevel = t.totalPlayedLevel + sessionTime
      t.totalPlayedReqTime = nil
   end

   Exlist.UpdateChar(key, t)
end

local function Linegenerator(tooltip, data, character)
   -- Module doesnt show anything in main tooltip
end

local function customGenerator(tooltip, db)
   -- data here will be all db
   local totalPlayed = 0
   local totalGold = 0

   for realmName, realm in pairs(db) do
      for charName, char in pairs(realm) do
         if (UnitName('player') == charName and realmName == GetRealmName() and char[key] and char[key].totalPlayedReqTime) then
            totalPlayed = totalPlayed + (time() - char[key].totalPlayedReqTime) -- Add session time to total played
         end
         totalPlayed = totalPlayed + (char[key] and char[key].totalPlayed or 0)
         totalGold = totalGold + (char.currency and char.currency.money.totalCoppers or 0)
      end
   end

   Exlist.AddLine(
      tooltip,
      {
         WrapTextInColorCode(L["Total Played"], colors.sideTooltipTitle),
         SecondsToTime(totalPlayed)
      }
   )
   Exlist.AddLine(
      tooltip,
      {
         WrapTextInColorCode(L["Total Gold"], colors.sideTooltipTitle),
         Exlist.FormatGold(totalGold)
      }
   )
end

local function init()
   C_Timer.After(1, function()
      RequestTimePlayed()
   end)
end

local data = {
   name = L["Character"],
   key = key,
   linegenerator = Linegenerator,
   priority = prio,
   updater = Updater,
   event = { "TIME_PLAYED_MSG", "PLAYER_LOGOUT" },
   weeklyReset = false,
   dailyReset = false,
   description = L["Gathers various data about character"],
   type = "totals",
   customGenerator = customGenerator,
   init = init
}

Exlist.RegisterModule(data)
