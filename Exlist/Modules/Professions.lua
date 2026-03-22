local key = "professions-df"
local prio = 50
local Exlist = Exlist
local L = Exlist.L

local function getProfessionData(profId)
   local profName, icon, currentSkill, maxSkill, _, _, skillId = GetProfessionInfo(profId)
   local data = {
      name = profName,
      icon = icon,
      skill = currentSkill,
      maxSkill = maxSkill,
      weeklies = {}
   }

   return data
end

local function Updater(event)
   if (event == "CURRENCY_DISPLAY_UPDATE") then
      C_Timer.After(
         0.5,
         function()
            Exlist.SendFakeEvent("REFRESH_PROFESSION")
         end
      )
   end
   local t = {}
   local prof1, prof2 = GetProfessions()
   for _, id in ipairs({ prof1, prof2 }) do
      table.insert(t, getProfessionData(id))
   end

   Exlist.UpdateChar(key, t)
end

local function Linegenerator(tooltip, data, character)
   return
end

local data = {
   name = L["Professions"],
   key = key,
   linegenerator = Linegenerator,
   priority = prio,
   updater = Updater,
   event = {
      "QUEST_TURNED_IN",
      "PLAYER_ENTERING_WORLD",
      "QUEST_REMOVED",
      "PLAYER_ENTERING_WORLD_DELAYED",
      "CURRENCY_DISPLAY_UPDATE",
      "REFRESH_PROFESSION"
   },
   weeklyReset = true,
   dailyReset = false,
   description = L["Tracks professions KPs"]
}

Exlist.RegisterModule(data)
