local key = "mythicKey"
local prio = 40
local CM = C_ChallengeMode
local C_MythicPlus = C_MythicPlus
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local UnitName, GetRealmName = UnitName, GetRealmName
local GetContainerNumSlots, GetContainerItemLink = GetContainerNumSlots, GetContainerItemLink
local ItemRefTooltip, UIParent, ShowUIPanel = ItemRefTooltip, UIParent, ShowUIPanel
local string, strsplit, time, tonumber = string, strsplit, time, tonumber
local WrapTextInColorCode = WrapTextInColorCode
local GetTime = GetTime
local IsShiftKeyDown = IsShiftKeyDown
local GetContainerItemID = GetContainerItemID
local ChatEdit_GetActiveWindow, ChatEdit_InsertLink, ChatFrame_OpenChat = ChatEdit_GetActiveWindow, ChatEdit_InsertLink, ChatFrame_OpenChat
local GameTooltip = GameTooltip
local ipairs = ipairs
local Exlist = Exlist
local colors = Exlist.Colors
local L = Exlist.L

local unknownIcon = "Interface\\ICONS\\INV_Misc_QuestionMark"
local lastUpdate = 0
local affixThreshold = {
  2, 
  4,
  7,
  10, 
}

local function Updater(event)
  if GetTime() - lastUpdate < 5 then return end
  lastUpdate = GetTime()
  local gt = Exlist.GetCharacterTableKey("global","global",key)
  -- Get Affixes
  C_MythicPlus.RequestCurrentAffixes()
  local affixes = C_MythicPlus.GetCurrentAffixes()
  for i,affixId in ipairs(affixes or {}) do
    local name, desc, icon = CM.GetAffixInfo(affixId)
    gt[i] = {name = name, icon = icon, desc = desc}
  end
  Exlist.UpdateChar(key,gt,"global","global")
  -- Get Key
  local challengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID() -- for map
  if not challengeMapID then return end
  local keyLevel = C_MythicPlus.GetOwnedKeystoneLevel() -- for level 
  local mapName = CM.GetMapUIInfo(challengeMapID)
  -- For Prepatch
  local keyId = UnitLevel("player") < 120 and 138019 or 158923 

  local availableAffixes = {}
  for i,affixLevel in ipairs(affixThreshold) do
    if keyLevel < affixLevel then break end
    availableAffixes[#availableAffixes+1] = affixes[i]
  end
  local t = {
    dungeon = mapName,
    mapId = challengeMapID,
    level = keyLevel,
    itemLink = string.format("\124cffa335ee\124Hkeystone:%s:%s:%s:%s:%s:%s:%s\124h[%s: %s (%s)]\124h\124r", 
                          keyId,
                          challengeMapID,
                          keyLevel,
                          availableAffixes[1] or "",
                          availableAffixes[2] or "",
                          availableAffixes[3] or "",
                          availableAffixes[4] or "",
                          L["Keystone"],
                          mapName,
                          keyLevel
                          )
  }
  Exlist.UpdateChar(key,t)
end
local function Linegenerator(tooltip,data,character)
  if not data then return end
  local settings = Exlist.ConfigDB.settings
  local mapId = tonumber(data.mapId)
  local dungeonName = settings.shortenInfo and Exlist.ShortenedMPlus[mapId] or data.dungeon
  local info = {
    data = WrapTextInColorCode("[" .. dungeonName .. " +" .. data.level .. "]", colors.mythicplus.key),
    character = character,
    moduleName = key,
    priority = prio,
    titleName = L["Key in bags"],
    OnClick = function(self, arg1,...)
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
    OnClickData = data.itemLink
  }
  Exlist.AddData(info)
end

local function GlobalLineGenerator(tooltip,data)
  if not data then return end
  if not Exlist.ConfigDB.settings.extraInfoToggles.affixes.enabled then return end
  local added = false
  for i=1,#data do
    if not added then
      Exlist.AddLine(tooltip,{WrapTextInColorCode(L["Mythic+ Affixes"],colors.sideTooltipTitle)},14)
      added = true
    end
    local line = Exlist.AddLine(tooltip,
      {string.format("|T%s:15|t %s %s",data[i].icon or unknownIcon,data[i].name or L["Unknown"],
        WrapTextInColorCode(string.format("- %s %i+", L["Level"],affixThreshold[i]),colors.faded))
      })
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

local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
  if not data.mapId then
    C_MythicPlus.RequestMapInfo() -- request update
    local mapIDs = CM.GetMapTable()
    for i,id in ipairs(mapIDs) do
      if data.dungeon == (CM.GetMapInfo(id)) then
        Exlist.Debug("Added mapId",id)
        data.mapId = id
        break
      end
    end
  end
  return data
end

local function init()
  Exlist.ConfigDB.settings.extraInfoToggles.affixes = Exlist.ConfigDB.settings.extraInfoToggles.affixes or {
      name = L["Mythic+ Weekly Affixes"],
      enabled = true,
     }
end


local data = {
  name = L['Mythic+ Key'],
  key = key,
  linegenerator = Linegenerator,
  globallgenerator = GlobalLineGenerator,
  priority = prio,
  updater = Updater,
  event = "BAG_UPDATE",
  description = L["Tracks characters mythic+ key in their bags and weekly mythic+ affixes"],
  weeklyReset = true,
  modernize = Modernize,
  init = init
}

Exlist.RegisterModule(data)
