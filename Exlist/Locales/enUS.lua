local L = Exlist.L



-- use key if there's no translation
setmetatable(Exlist.L, {__index = function(self, key)
  self[key] = (key or "")
  return key
end})