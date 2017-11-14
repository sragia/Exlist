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
  local gt = CharacterInfo.GetCharacterTableKey(key,"global","global")
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local s = GetContainerItemLink(bag, slot)
      if s and string.find(s, "Keystone:") then
        local _, mapID, level,affix1,affix2,affix3 = strsplit(":", s, 8)
        local affixes = {affix1,affix2,affix3}
        local map = CM.GetMapInfo(mapID)
        for i=1,3 do
          if not gt[i] and affixes[i] and affixes[i] ~= "" then
            local id = string.match(affixes[i],"%d+")
            local name, _, icon = CM.GetAffixInfo(tonumber(id))
            gt[i] = {name = name, icon = icon}
          end
        end
        local table = {
          ["dungeon"] = map,
          ["level"] = level,
          ["itemLink"] = s,
          ["timeChecked"] = time()
        }
        CharacterInfo.UpdateChar(key,table)
        CharacterInfo.UpdateChar(key,gt,"global","global")
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

local function GlobalLineGenerator(tooltip,data)
  if not data then return end
  local added = false
  for i=1,#data do
    if not added then
      CharacterInfo.AddLine(tooltip,{WrapTextInColorCode("Mythic+ Affixes","ffffd200")})
      added = true
    end
    CharacterInfo.AddLine(tooltip,{string.format("|T%s:15|t %s",data[i].icon,data[i].name)})
  end
end

local data = {
  name = 'Mythic+ Key',
  key = key,
  linegenerator = Linegenerator,
  globallgenerator = GlobalLineGenerator,
  priority = 3,
  updater = Updater,
  event = "BAG_UPDATE",
  weeklyReset = true
}

CharacterInfo.RegisterModule(data)
