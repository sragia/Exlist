local L = Exlist.L

--@localization(locale="enUS", format="lua_additive_table")@

-- use key if there's no translation
setmetatable(
   Exlist.L,
   {
      __index = function(self, key)
         key = key or ""
         self[key] = key
          ---(key and "<LOCAL>" .. key or "")
         return key
      end
   }
)
