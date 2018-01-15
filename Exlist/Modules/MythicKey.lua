local key = "mythicKey"
local CM = C_ChallengeMode
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local UnitName, GetRealmName = UnitName, GetRealmName
local GetContainerNumSlots, GetContainerItemLink = GetContainerNumSlots, GetContainerItemLink
local ItemRefTooltip, UIParent, ShowUIPanel = ItemRefTooltip, UIParent, ShowUIPanel
local string, strsplit, time = string, strsplit, time
local WrapTextInColorCode = WrapTextInColorCode
local Exlist = Exlist

local unknownIcon = "Interface\\ICONS\\INV_Misc_QuestionMark"
local lastUpdate = 0
local function Updater(event)
  if GetTime() - lastUpdate < 5 then return end
  lastUpdate = GetTime()
  local gt = Exlist.GetCharacterTableKey("global","global",key)
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
            local name, desc, icon = CM.GetAffixInfo(tonumber(id))
            Exlist.Debug("Adding Affix- ID:",id," name:",name," icon:",icon," i:",i," key:",key)
            gt[i] = {name = name, icon = icon, desc = desc}
          end
        end
        local table = {
          ["dungeon"] = map,
          ["level"] = level,
          ["itemLink"] = s,
        }
        Exlist.UpdateChar(key,table)
        Exlist.UpdateChar(key,gt,"global","global")
        break;
      end
    end
  end
end

local function Linegenerator(tooltip,data)
  if not data then return end
  local lineNum = Exlist.AddLine(tooltip,{"Key in bags",WrapTextInColorCode("[" .. data.dungeon .. " +" .. data.level .. "]", "ffd541e2")})
  Exlist.AddScript(tooltip,lineNum, 2, "OnMouseDown", function(self, arg1,...)
    if IsShiftKeyDown() then
      if not arg1 then return end
      if ChatEdit_GetActiveWindow() then
        ChatEdit_InsertLink(arg1)
      else
        ChatFrame_OpenChat(arg1, DEFAULT_CHAT_FRAME)
      end
    else
      ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
      ItemRefTooltip:SetHyperlink(arg1)
      ShowUIPanel(ItemRefTooltip) 
    end
  end,
  data.itemLink)
end

local function GlobalLineGenerator(tooltip,data)
  if not data then return end
  local added = false
  for i=1,#data do
    if not added then
      Exlist.AddLine(tooltip,{WrapTextInColorCode("Mythic+ Affixes","ffffd200")})
      added = true
    end
    local line = Exlist.AddLine(tooltip,{string.format("|T%s:15|t %s",data[i].icon or unknownIcon,data[i].name or "Unknown")})
    if data[i].desc then
      Exlist.AddScript(tooltip,line,nil,"OnEnter",function(self)
        GameTooltip:SetOwner(self)
        GameTooltip:SetFrameLevel(self:GetFrameLevel()+10)
        GameTooltip:ClearLines()
        GameTooltip:SetWidth(300)
        GameTooltip:SetText(data[i].desc,nil,nil,nil,nil,true)
        GameTooltip:Show()
       end)
       Exlist.AddScript(tooltip,line,nil,"OnLeave",GameTooltip_Hide)
    end
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

Exlist.RegisterModule(data)
