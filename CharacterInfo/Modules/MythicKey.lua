local key = "mythicKey"
local CM = C_ChallengeMode
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local UnitName, GetRealmName = UnitName, GetRealmName
local GetContainerNumSlots, GetContainerItemLink = GetContainerNumSlots, GetContainerItemLink
local ItemRefTooltip, UIParent, ShowUIPanel = ItemRefTooltip, UIParent, ShowUIPanel
local string, strsplit, time = string, strsplit, time
local WrapTextInColorCode = WrapTextInColorCode
local CharacterInfo = CharacterInfo

local function Updater(event)
  local name = UnitName('player')
  local realm = GetRealmName()

  if CharacterInfo.DB
  and CharacterInfo.DB[realm]
  and CharacterInfo.DB[realm][name]
  and CharacterInfo.DB[realm][name].mythicKey
  and CharacterInfo.DB[realm][name].mythicKey.timeChecked
  and time() - CharacterInfo.DB[realm][name].mythicKey.timeChecked < 60 then
  return end -- BAG_UPDATE updated too much, limit it to every minute

  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local s = GetContainerItemLink(bag, slot)
      if s and string.find(s, "Keystone:") then
        local _, mapID, level = strsplit(":", s, 7)
        local map = CM.GetMapInfo(mapID)
        local table = {
          ["dungeon"] = map,
          ["level"] = level,
          ["itemLink"] = s,
          ["timeChecked"] = time()
        }
        CharacterInfo.UpdateChar(key,table)
        break;
      end
    end
  end
end

local function Linegenerator(tooltip,data)
  if not data then return end
  local lineNum = CharacterInfo.AddLine(tooltip,{"Key in bags",WrapTextInColorCode("[" .. data.dungeon .. " +" .. data.level .. "]", "ffd541e2")})
  CharacterInfo.AddScript(tooltip,lineNum, 2, "OnMouseDown", function(self, arg1)
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    ItemRefTooltip:SetHyperlink(arg1)
    ShowUIPanel(ItemRefTooltip) end,
  data.itemLink)
end

local data = {
  name = 'Mythic+ Key',
  key = key,
  linegenerator = Linegenerator,
  priority = 3,
  updater = Updater,
  event = "BAG_UPDATE",
  weeklyReset = true
}

CharacterInfo.RegisterModule(data)
