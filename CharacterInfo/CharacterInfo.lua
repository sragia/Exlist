--[[
  TODO:
]]

local addonName, addonTable = ...
local QTip = LibStub("LibQTip-1.0")
-- SavedVariables localized
local db = {}
local config_db = {}
CharacterInfo_Config = CharacterInfo_Config or {}
local debugMode = false 
CharacterInfo = {}
CharacterInfo.debugMode = debugMode
local registeredUpdaters = {
 --[event] = func or {func,func}
}
local registeredLineGenerators = {
  -- [name] = {func = func, prio = prio}
}
local globalLineGenerators ={
  -- [name] = {func = func, prio = prio}
}
local registeredModules = {
  --'name','name1','name2' etc
}
local modernizeFunctions = {
  -- func,func,func
}
local keysToReset = {}
-- localized API
local _G = _G
local CreateFrame = CreateFrame
local GetRealmName = GetRealmName
local UnitName = UnitName
local GetCVar = GetCVar
local GetMoney = GetMoney
local WrapTextInColorCode,SecondsToTime = WrapTextInColorCode, SecondsToTime
local UnitClass, UnitLevel = UnitClass, UnitLevel
local GetAverageItemLevel, GetSpecialization, GetSpecializationInfo = GetAverageItemLevel, GetSpecialization, GetSpecializationInfo
local C_Timer = C_Timer
local C_ArtifactUI = C_ArtifactUI
local HasArtifactEquipped = HasArtifactEquipped
local GetItemInfo,GetInventoryItemLink = GetItemInfo,GetInventoryItemLink
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GetGameTime,GetTime,debugprofilestop = GetGameTime,GetTime,debugprofilestop
local InCombatLockdown = InCombatLockdown
local strsplit = strsplit
-- local
local MAX_CHARACTER_LEVEL = 110
local MAX_PROFESSION_LEVEL = 800
local defaultFont = [[Interface\Addons\CharacterInfo\Media\Font\font.ttf]]
local settings = { -- default settings
  minLevel = 80,
  fonts = {
    big = { size = 15, fontName = defaultFont},
    medium = { size = 13, fontName = defaultFont},
    small = { size = 11, fontName = defaultFont}
  },
  tooltipHeight = 600,
  delay = 0.2,
  iconScale = .8,
  allowedCharacters = {},
  allowedModules = {},
  lockIcon = false,
}
local DEFAULT_BACKDROP = { bgFile = "Interface\\BUTTONS\\WHITE8X8.blp",
  edgeFile = "Interface\\BUTTONS\\WHITE8X8.blp",
  tile = false,
  tileSize = 0,
  edgeSize = 1,
  insets = {
    left = 0,
    right = 0,
    top = 0,
bottom = 0 }}
-- fonts
local fontSet = settings.fonts
local hugeFont = CreateFont("CharacterInfo_HugeFont")
--hugeFont:CopyFontObject(GameTooltipText)
hugeFont:SetFont(defaultFont, fontSet.big.size)
local smallFont = CreateFont("CharacterInfo_SmallFont")
---smallFont:CopyFontObject(GameTooltipText)
smallFont:SetFont(defaultFont, fontSet.small.size)
local mediumFont = CreateFont("CharacterInfo_MediumFont")
--mediumFont:CopyFontObject(GameTooltipText)
mediumFont:SetFont(defaultFont, fontSet.medium.size)
local monthNames = {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'}

-- lua api
local tonumber = _G.tonumber
local floor = _G.math.floor
local format = _G.format
local string = string
local strlen = strlen
local type,pairs,table = type,pairs,table
local print,select,date,math,time = print,select,date,math,time
-- register events
local frame = CreateFrame("FRAME")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("CHINFO_DELAY")

-- utility
CharacterInfo.ShortenNumber = function(number, digits)
  digits = tonumber(digits) or 0 -- error
  number = tonumber(number) or 0 -- error
  local affix = {'', 'k', 'm', 'b', 't', 'p'}
  local pastPoint = number
  local i = 1
  while number > 1000 do
    number = number / 1000
    i = i + 1
  end
  pastPoint = string.sub(pastPoint, strlen(floor(number)) + 1, strlen(floor(number)) + digits)
  pastPoint = pastPoint == "" and 0 or pastPoint
  if digits > 0 and tonumber(pastPoint) > 0 then
    return format("%i", number).. "." .. pastPoint .. affix[i]
  elseif digits > 0 and tonumber(pastPoint) <= 0 then
    return format("%i", number).. ".0" .. affix[i]
  else
    return format("%i", number) .. affix[i]
  end
end

local function copyTableInternal(source, seen)
  if type(source) ~= "table" then return source end
  if seen[source] then return seen[source] end
  local rv = {}
  seen[source] = rv
  for k, v in pairs(source) do
    rv[copyTableInternal(k, seen)] = copyTableInternal(v, seen)
  end
  return rv
end

function CharacterInfo.copyTable(source)
  return copyTableInternal(source, {})
end

function CharacterInfo.ConvertColor(color)
  return (color / 255)
end

function CharacterInfo.ColorHexToDec(hex)
  if not hex or strlen(hex) < 6 then return end
  local values = {}
  for i = 1, 6, 2 do
    table.insert(values, tonumber(string.sub(hex, i, i + 1), 16))
  end
  return (values[1]/ 255),(values[2]/ 255),(values[3]/ 255)
end

function CharacterInfo.ColorDecToHex(col1,col2,col3)
  col1 = col1 or 0
  col2 = col2 or 0
  col3 = col3 or 0
  local hexColor = string.format("%02x%02x%02x",col1*255,col2*255,col3*255)
  return hexColor
end

function CharacterInfo.TimeLeftColor(timeLeft, times, col)
  -- times (opt) = {red,orange} upper limit
  -- i.e {100,1000} = 0-100 Green 100-1000 Orange 1000-inf Green
  -- colors (opt) - colors to use
  times = times or {3600, 18000} --default
  local colors = col or {"FFFF0000", "FFe09602", "FF00FF00"} -- default
  for i = 1, #times do
    if timeLeft < times[i] then
      return WrapTextInColorCode(SecondsToTime(timeLeft), colors[i])
    end
  end
  return WrapTextInColorCode(SecondsToTime(timeLeft), colors[#colors])
end

-- To find quest name from questID
local MyScanningTooltip = CreateFrame("GameTooltip", "ChInfoScanningTooltip", UIParent, "GameTooltipTemplate")

CharacterInfo.QuestTitleFromID = setmetatable({}, { __index = function(t, id)
         MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
         MyScanningTooltip:SetHyperlink("quest:"..id)
         local title = MyScanningTooltipTextLeft1:GetText()
         MyScanningTooltip:Hide()
         if title and title ~= RETRIEVING_DATA then
            t[id] = title
            return title
         end
end })

function CharacterInfo.QuestInfo(questid)
  if not questid or questid == 0 then return nil end
  MyScanningTooltip:SetOwner(UIParent,"ANCHOR_NONE")
  MyScanningTooltip:SetHyperlink("\124cffffff00\124Hquest:"..questid..":90\124h[]\124h\124r")
  local l = _G[MyScanningTooltip:GetName().."TextLeft1"]
  l = l and l:GetText()
  if not l or #l == 0 then return nil end -- cache miss
  return l, "\124cffffff00\124Hquest:"..questid..":90\124h["..l.."]\124h\124r"
end

CharacterInfo.FormatTimeMilliseconds = function(time)
  local minutes = math.floor((time/1000)/60)
  local seconds = math.floor((time - (minutes*60000))/1000)
  local milliseconds = time-(minutes*60000)-(seconds*1000)
  return string.format("%02d:%02d:%02d",minutes,seconds,milliseconds)
end

function CharacterInfo.GetTableNum(t)
  if type(t) ~= "table" then
    return 0
  end
  local count = 0
  for i in pairs(t) do
    count = count + 1
  end
  return count
end
--------------
local function AddMissingCharactersToSettings()
  if not settings.allowedCharacters then settings.allowedCharacters = {} end
  local t = settings.allowedCharacters
  for i, v in pairs(db) do
    -- i=server
    if i ~= "global" then
      for b, c in pairs(v) do
        --b = name
        local s = b.."-"..i
        if (t[s] == nil or type(t[s]) ~= "table") or (not t[s].ilvl) then
          t[s] = {
            enabled = true,
            name = b,
            classClr = v[b].class and RAID_CLASS_COLORS[v[b].class].colorStr or b == UnitName('player') and RAID_CLASS_COLORS[select(2, UnitClass('player'))].colorStr or "FFFFFFFF",
            ilvl = v[b].iLvl or 0
          }
        else
          t[s].ilvl = v[b].iLvl
        end
      end
    end
  end
end

local function AddModulesToSettings()
  if not settings.allowedModules then settings.allowedModules = {} end
  local t = settings.allowedModules
  for i=1,#registeredModules do
    if t[registeredModules[i]] == nil then
      -- first time seeing it
      t[registeredModules[i]] = true
    end
  end
end

function CharacterInfo.UpdateChar(key,data,charname,charrealm)
  if not data or not key then return end
  charrealm = charrealm or GetRealmName()
  charname = charname or UnitName('player')
  db[charrealm] = db[charrealm] or {}
  db[charrealm][charname] = db[charrealm][charname] or {}
  local charToUpdate = db[charrealm][charname]
  charToUpdate[key] = data
end

function CharacterInfo.GetCachedItemInfo(itemId)
  if config_db.item_cache and config_db.item_cache[itemId] then
    return config_db.item_cache[itemId]
  else
    local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemId)
    local t = {name = name, texture = texture}
    if name and texture then
      -- only save if GetItemInfo actually gave info
      config_db.item_cache = config_db.item_cache or {}
      config_db.item_cache[itemId] = t
    end
    return t
  end
end

-- charinfo updater functions
local UpdateCharacter = function(name, realm, updatedInfo)
  -- check if realm and/or character is already in table, if isn't create them
  -- in updatedInfo table check all keys only in first level
  -- update them 1 by 1
  realm = realm or GetRealmName()
  name = name or UnitName('player')
  db[realm] = db[realm] or {}
  db[realm][name] = db[realm][name] or {}
  if not updatedInfo then return end
  local charToUpdate = db[realm][name]
  for i, v in pairs(updatedInfo) do
    charToUpdate[i] = v
  end
end

local DeleteCharacterKey = function(name, realm, key)
  if not key or not db[realm] or not db[realm][name] then return end
  db[realm][name][key] = nil
end

local WipeKey = function(key)
  -- ... yea
  -- if i need to delete 1 key info from all characters on all realms
  if debugMode then print('wiped ' .. key) end
  for realm in pairs(db) do
    for name in pairs(db[realm]) do
      for keys in pairs(db[realm][name]) do
        if keys == key then
          if debugMode then
            print('|cFF995813CharacterInfo|r - wiping ',key, ' Fromn:',name,'-',realm)
          end
          db[realm][name][key] = nil
        end
      end
    end
  end
  if debugMode then
    print('|cFF995813CharacterInfo|r - Wiping Key (',key,') completed.')
  end
end

local function UpdateCharacterTalents()
  local t = {}
  --[[
  {
    {-- tier 1
      {name,icon,selected} -- talent 1
      {} -- talent 2
      {} -- talent 3
    }
  }
  ]]
  for tier=1,7 do
    -- tiers
    t[tier] = {}
    local tierT = t[tier]
    for talent=1,3 do
      local _, name, texture, selected, _, _, _, _,_,_, selectedalt = GetTalentInfo(tier,talent,1)
      table.insert(tierT,{name=name,icon=texture,selected = selected or selectedalt})
    end
  end
  CharacterInfo.UpdateChar("talents",t)
end

local enchantNames = {
  --neck
  [5889] = "Mark of Heavy Hide",
  [5891] = "Mark of the Ancient Priestess",
  [5437] = "Mark of the Claw",
  [5438] = "Mark of the Distant Army",
  [5889] = "Mark of Heavy Hide",
  [5439] = "Mark of the Hidden Satyr",
  [5890] = "Mark of the Trained Soldier",
  --ring
  [5430] = "+200 Versatility",
  [5429] = "+200 Mastery",
  [5427] = "+200 Critical Strike",
  [5428] = "+200 Haste",
  [5426] = "+150 Versatility",
  [5424] = "+150 Haste",
  [5425] = "+150 Mastery",
  [5423] = "+150 Critical Strike",
  --cloak
  [5434] = "+200 Strength",
  [5436] = "+200 Intellect",
  [5435] = "+200 Agility",
  [5431] = "+150 Strength",
  [5433] = "+150 Intellect",
  [5432] = "+150 Agility",
}
local slotNames = {"Head","Neck","Shoulders","Shirt","Chest","Waist","Legs","Feet","Wrists",
"Hands","Ring","Ring","Trinket","Trinket","Back","Main Hand","Off Hand","Ranged"}

local function UpdateCharacterGear()
  local t = {}
  local order = {1,2,3,15,5,9,10,6,7,8,11,12,13,14,16,17,18}
  for i=1,#order do
    local iLink = GetInventoryItemLink('player',order[i])
    if iLink then
      local itemName, itemLink, itemRarity, itemLevel, _, _, _, _, _, itemTexture, _ = GetItemInfo(iLink)
      local _,enchantId,gem,gemId
      local relics = {}
      if not (order[i] == 16 or order[i] == 17 or order[i] == 18) then
        -- check for enhancements (gem/enchant)
        _,_,enchantId,gemId = strsplit(":",iLink)
        enchantId = tonumber(enchantId)
        gemId = tonumber(gemId)
        if gemId then
          gem = GetItemInfo(gemId)
        end
      end
      table.insert(t,{slot = slotNames[order[i]], name = itemName,itemTexture = itemTexture, itemLink = itemLink,
                      ilvl = itemLevel, enchant = enchantNames[enchantId], gem = gem})
    end
  end
  if HasArtifactEquipped() then
    for i=1,3 do
      local name,icon,slotTypeName,link = C_ArtifactUI.GetEquippedArtifactRelicInfo(i)
      if name then
        local _,_,_,ilvl=GetItemInfo(link)
        table.insert(t,{slot = slotTypeName .. " Relic", name = name,itemTexture = icon, itemLink = link,
                      ilvl = ilvl})
      end
    end
  end
  CharacterInfo.UpdateChar("gear",t)
end
local function UpdateCharacterProfessions()
  local profIndexes = {GetProfessions()}
  local t = {}
  for i=1,#profIndexes do
    if profIndexes[i] then
      local name, texture, rank, maxRank = GetProfessionInfo(profIndexes[i])
      table.insert(t,{name=name,icon=texture,curr=rank,max=maxRank})
    end
  end
  CharacterInfo.UpdateChar("professions",t)
end

local UpdateCharacterSpecifics = function(event)
  if event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
    UpdateCharacterGear()
  --elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
    --UpdateCharacterTalents()
  end
  UpdateCharacterProfessions()
  local name = UnitName('player')
  local level = UnitLevel('player')
  local _, class = UnitClass('player')
  local _, iLvl = GetAverageItemLevel()
  local _, spec = GetSpecializationInfo(GetSpecialization())
  local realm = GetRealmName()
  local table = {}
  table.level = level
  table.class = class
  table.iLvl = iLvl
  table.spec = spec
  table.realm = realm
  UpdateCharacter(name, realm, table)
end

local function GetRealms()
  -- returns table with realm names and number of realms
  local realms = {}
  local n = 1
  for i in pairs(db) do
    if i ~= "global" then
      realms[n] = i
      n = n + 1
    end
  end
  local numRealms = #realms
  local function itemsInTable(table)
    local i = 0
    for _ in pairs(table) do i = i + 1 end
    return i
  end
  table.sort(realms, function(a, b) return itemsInTable(db[a]) > itemsInTable(db[b]) end)
  return realms, numRealms
end

local function GetRealmCharInfo(realm)
  if not db[realm] then return end
  local charInfo = {}
  local charNum = 0

  for char in pairs(db[realm]) do
    if not settings.allowedCharacters[char.."-"..realm] then AddMissingCharactersToSettings() end
    if settings.allowedCharacters[char.."-"..realm].enabled then
      charNum = charNum + 1
      charInfo[charNum] = {}
      charInfo[charNum].name = char
      for key, value in pairs(db[realm][char]) do
        charInfo[charNum][key] = value
      end
    end
  end
  table.sort(charInfo, function(a, b) return a.iLvl > b.iLvl end)
  return charInfo, charNum
end

local function AttachStatusBar(frame)
  local statusBar = CreateFrame("StatusBar", nil, frame)
  statusBar:SetStatusBarTexture("Interface\\AddOns\\CharacterInfo\\Media\\Texture\\statusBar")
  statusBar:GetStatusBarTexture():SetHorizTile(false)
  local bg = {
    bgFile = "Interface\\AddOns\\CharacterInfo\\Media\\Texture\\statusBar"
  }
  statusBar:SetBackdrop(bg)
  statusBar:SetBackdropColor(.1, .1, .1, .8)
  statusBar:SetStatusBarColor(CharacterInfo.ColorHexToDec("ffffff"))
  statusBar:SetMinMaxValues(0, 100)
  statusBar:SetValue(0)
  statusBar:SetHeight(5)
--  print('createdNewStatusBar')
  return statusBar
end

-- Modules/API
-- Info attaching to tooltip
function CharacterInfo.AddLine(tooltip,info)
  -- info =  {'1st cell','2nd cell','3rd cell' ...} or "string"
  if not tooltip or not info or (type(info) ~= 'table' and type(info) ~= 'string') then return end
  local maxColumns = 5
  local n = tooltip:AddLine()
  if type(info) == 'string' then
    tooltip:SetCell(n,1,info,"LEFT",maxColumns-1)
  else
    for i=1,#info do
      if i<#info then
        tooltip:SetCell(n,i,info[i])
      else
        tooltip:SetCell(n,i,info[i],"LEFT",maxColumns-i)
      end
    end
  end
  -- return line number
  return n
end

function CharacterInfo.AddToLine(tooltip,row,col,text)
  -- Add text to lines column
  if not tooltip or not row or not col or not text then return end
  tooltip:SetCell(row,col,text)
end

function CharacterInfo.AddScript(tooltip,row,col,event,func,arg)
  -- Script for cell
  if not tooltip or not row or not event or not func then return end
  if col then
    tooltip:SetCellScript(row,col,event,func,arg)
  else
    tooltip:SetLineScript(row,event,func,arg)
  end
end

function CharacterInfo.CreateSideTooltip(statusbar)
  -- Creates Side Tooltip function that can be attached to script
  -- statusbar(optional) {} {enabled = true, curr = ##, total = ##, color = 'hex'}
  local function a(self, info)
    -- info {} {body = {'1st lane',{'2nd lane', 'side number w/e'}},title = ""}
    local sideTooltip = QTip:Acquire("CharInf_Side", 2, "LEFT", "RIGHT")
    self.sideTooltip = sideTooltip
    sideTooltip:SetHeaderFont(hugeFont)
    sideTooltip:AddHeader(info.title or "")
    local body = info.body
    for i = 1, #body do
      if type(body[i]) == "table" then
        if body[i][3] then
          if body[i][3][1] == "header" then
            sideTooltip:SetHeaderFont(mediumFont)
            sideTooltip:AddHeader(body[i][1], body[i][2])
          elseif body[i][3][1] == "separator" then
            sideTooltip:AddLine(body[i][1], body[i][2])
            sideTooltip:AddSeparator(1,1,1,1,.8)
          elseif body[i][3][1] == "headerseparator" then
            sideTooltip:AddHeader(body[i][1], body[i][2])
            sideTooltip:AddSeparator(1,1,1,1,.8)
          end
        else
          sideTooltip:AddLine(body[i][1], body[i][2])
        end
      else
        sideTooltip:AddLine(body[i])
      end
    end
    sideTooltip:SetPoint("TOPRIGHT", self:GetParent(), "TOPLEFT", - 9, 10)
    sideTooltip:Show()
    sideTooltip:SetClampedToScreen(true)
    local parentFrameLevel = self:GetFrameLevel(self)
    sideTooltip:SetFrameLevel(parentFrameLevel + 5)
    sideTooltip:SetBackdrop(DEFAULT_BACKDROP)
    sideTooltip:SetBackdropColor(0, 0, 0, .9);
    sideTooltip:SetBackdropBorderColor(.2, .2, .2, 1)
    if statusbar then
      statusbar.total = statusbar.total or 100
      statusbar.curr = statusbar.curr or 0
      local statusBar = CreateFrame("StatusBar", nil, sideTooltip)
      self.statusBar = statusBar
      statusBar:SetStatusBarTexture("Interface\\AddOns\\CharacterInfo\\Media\\Texture\\statusBar")
      statusBar:GetStatusBarTexture():SetHorizTile(false)
      local bg = {
        bgFile = "Interface\\AddOns\\CharacterInfo\\Media\\Texture\\statusBar"
      }
      statusBar:SetBackdrop(bg)
      statusBar:SetBackdropColor(.1, .1, .1, .8)
      statusBar:SetStatusBarColor(CharacterInfo.ColorHexToDec(statusbar.color))
      statusBar:SetMinMaxValues(0, statusbar.total)
      statusBar:SetValue(statusbar.curr)
      statusBar:SetWidth(sideTooltip:GetWidth() - 2)
      statusBar:SetHeight(5)
      statusBar:SetPoint("TOPLEFT", sideTooltip, "BOTTOMLEFT", 1, 0)
    end

  end
  return a
end

function CharacterInfo.DisposeSideTooltip()
  -- requires to have saved side tooltip in tooltip.sideTooltip
  -- returns function that can be used for script
  return function(self)
    QTip:Release(self.sideTooltip)
  --  texplore(self)
    if self.statusBar then
      self.statusBar:Hide()
      self.statusBar = nil
    elseif self.sideTooltip.statusBars then
    --  print('disposing statusBars')
      for i=1,#self.sideTooltip.statusBars do
        local statusBar = self.sideTooltip.statusBars[i]
        if statusBar then
          statusBar:Hide()
          statusBar = nil
        end
      end
    end
    self.sideTooltip = nil
  end
end

local registeredEvents = {
  --[event] = true
}
local function RegisterEvents()
  for i in pairs(registeredUpdaters) do
    if not registeredEvents[i] then
      frame:RegisterEvent(i)
      registeredEvents[i] = true
    end
  end
end
function CharacterInfo.RegisterModule(data)
  --[[
  data = table
    {
    name = string (name of module)
    key = string (module key that will be used in db)
    linegenerator = func  (function that adds text to tooltip   function(tooltip,characterInfo) ...)
    priority = numberr (data priority in tooltip lower>higher)
    updater = func (function that updates data in db)
    event = {} or string (table or string that contains events that triggers updater func)
    weeklyReset = bool (should this be reset on weekly reset)
    }
  ]]
  if not data then return end

  -- add updater
  if data.updater and data.event then
    if type(data.event) == "table" then
      -- multiple events
      for i=1,#data.event do
        registeredUpdaters[data.event[i]] = registeredUpdaters[data.event[i]] or {}
        table.insert(registeredUpdaters[data.event[i]],{func = data.updater, name = data.name})
      end
    elseif type(data.event) == "string" then
      -- single event
      registeredUpdaters[data.event] = registeredUpdaters[data.event] or {}
      table.insert(registeredUpdaters[data.event],{func = data.updater, name = data.name})
    end
  end
  RegisterEvents()

  -- add modernizers
  if data.modernize then
    table.insert(modernizeFunctions,{func = data.modernize,key = data.key})
  end
  -- add line generator
  table.insert(registeredLineGenerators,{name = data.name, func = data.linegenerator, prio = data.priority, key = data.key})
  -- add global line generator
  if data.globallgenerator then
    table.insert(globalLineGenerators,{name=data.name,func = data.globallgenerator,prio=data.priority,key=data.key})
  end
  -- Add module name to list
  table.insert(registeredModules,data.name)
  if data.weeklyReset then
    table.insert(keysToReset,data.key)
  end
end

function CharacterInfo.GetRealmNames()
  local t = {}
  for i in pairs(db) do
    if i ~= "global" then
      t[#t+1] = i
    end
  end
  return t
end

function CharacterInfo.GetRealmCharacters(realm)
  local t = {}
  if db[realm] then
    for i in pairs(db[realm]) do
      t[i] = true
    end
  end
  return t
end

function CharacterInfo.GetCharacterTable(realm,name)
  local t = {}
  if db[realm] and db[realm][name] then
    t = db[realm][name]
  end
  return t
end

function CharacterInfo.GetCharacterTableKey(realm,name,key)
  local t = {}
  if db[realm] and db[realm][name] and db[realm][name][key] then
    t = db[realm][name][key]
  end
  return t
end

function CharacterInfo.CharacterExists(realm,name)
    if db[realm] and db[realm][name] then
      return true
    end
    return false
end

local function ModernizeCharacters()
  if #modernizeFunctions < 1 then return end
  for realm in pairs(db) do
    if realm ~= "global" then
      for character in pairs(db[realm]) do
        for i=1,#modernizeFunctions do
          if db[realm][character][modernizeFunctions[i].key] then
            db[realm][character][modernizeFunctions[i].key] = modernizeFunctions[i].func(db[realm][character][modernizeFunctions[i].key])
          end
        end
      end
    end
  end
end

local function AddNote(tooltip,data,realm)
  local name = data.name
  if data.note then
    -- show note
    StaticPopupDialogs["DeleteNotePopup_"..name..realm] = {
      text = "Delete Note?",
      button1 = "Yes",
      button3 = "Cancel",
      hasEditBox = false,
      OnAccept = function()
        StaticPopup_Hide("DeleteNotePopup_"..name..realm)
        DeleteCharacterKey(name, realm, "note")
      end,
      timeout = 0,
      cancels = "DeleteNotePopup_"..name..realm,
      whileDead = true,
      hideOnEscape = false,
      preferredIndex = 4,
      showAlert = false
    }
    local lineNum = tooltip:AddLine(WrapTextInColorCode("Note:", "fff4c842"), data.note)
    tooltip:SetLineScript(lineNum, "OnMouseDown", function() StaticPopup_Show("DeleteNotePopup_"..name..realm) end)
  else
    -- Add note
    StaticPopupDialogs["AddNotePopup_"..name..realm] = {
      text = "Add Note",
      button1 = "Ok",
      button3 = "Cancel",
      hasEditBox = 1,
      editBoxWidth = 200,
      OnShow = function(self)
        self.editBox:SetText("")
      end,
      OnAccept = function(self)
        StaticPopup_Hide("AddNotePopup_"..name..realm)
        UpdateCharacter(name, realm, {note = self.editBox:GetText()})
      end,
      timeout = 0,
      cancels = "AddNotePopup_"..name..realm,
      whileDead = true,
      hideOnEscape = false,
      preferredIndex = 4,
      showAlert = false,
      enterClicksFirstButton = 1
    }
    local lineNum = tooltip:AddLine(WrapTextInColorCode("Add Note", "fff4c842"))
    tooltip:SetLineScript(lineNum, "OnMouseDown", function() StaticPopup_Show("AddNotePopup_"..name..realm) end)
  end
end

local ilvlColors = {
  {ilvl = 750 , str = "ff26ff3f"},
  {ilvl = 800 , str ="ff26ffba"},
  {ilvl = 850 , str ="ff26e2ff"},
  {ilvl = 880 , str ="ff26a0ff"},
  {ilvl = 900 , str ="ff2663ff"},
  {ilvl = 910 , str ="ff8e26ff"},
  {ilvl = 920 , str ="ffe226ff"},
  {ilvl = 935 ,str = "ffff2696"},
  {ilvl = 950 , str ="ffff2634"},
  {ilvl = 980 , str ="ffff7526"},
  {ilvl = 1000 , str ="ffffc526"}
}
local setIlvlColor = function(ilvl)
  if not ilvl then return "ffffffff" end
  for i=1,#ilvlColors do
    if ilvlColors[i].ilvl > ilvl then
      return ilvlColors[i].str
    end
  end
  return "fffffb26"
end
local hasEnchantSlot = {
  Neck = true,
  Ring = true,
  Back = true
}
local profColors = {
  {val = 75, color = "c6c3b4"},
  {val = 150, color = "dbd3ab"},
  {val = 225, color = "e2d388"},
  {val = 300, color = "efd96b"},
  {val = 400, color = "ffe254"},
  {val = 500, color = "ffde3d"},
  {val = 600, color = "ffd921"},
  {val = 700, color = "ffd50c"},
  {val = 800, color = "ffae00"}
}
local function ProfessionValueColor(value)
  for i=1,#profColors do
    if value <= profColors[i].val then
      return profColors[i].color
    end
  end
  return "FFFFFF"
end

local function GearTooltip(self,info)
  local geartooltip = QTip:Acquire("CharInf_GearTip",7,"CENTER","LEFT","LEFT","LEFT","LEFT","LEFT","LEFT")
  geartooltip.statusBars = {}
  self.sideTooltip = geartooltip
  geartooltip:SetHeaderFont(hugeFont)
  local specIcon = info.spec and info.class .. info.spec or "SpecNone"
  -- character name header
  local header = "|TInterface\\AddOns\\CharacterInfo\\Media\\Icons\\" .. specIcon ..":25:25|t "..
    "|c" .. RAID_CLASS_COLORS[info.class].colorStr .. info.name .. "|r " ..
  (info.level or 0) .. ' level'
  local line = geartooltip:AddHeader()
  geartooltip:SetCell(line,1,header,"LEFT",3)
  geartooltip:SetCell(line,7,string.format("%i ilvl",(info.iLvl or 0)),"RIGHT")
  geartooltip:AddSeparator(1,.8,.8,.8,1)
  line = geartooltip:AddHeader()
  geartooltip:SetCell(line,1,WrapTextInColorCode("Gear","ffffb600"),"CENTER",7)
  local gear = info.gear
  if gear then
    for i=1,#gear do
      local enchantements = ""
      if gear[i].enchant or gear[i].gem then
        if gear[i].enchant and gear[i].gem then
          enchantements = string.format("%s%s\n%s","|cff00ff00",gear[i].enchant or "",gear[i].gem or "")
        else
          enchantements = string.format("%s%s","|cff00ff00",gear[i].enchant or gear[i].gem )
        end
      elseif hasEnchantSlot[gear[i].slot] then
        enchantements = WrapTextInColorCode("No Enchant!","ffff0000")
      end
      local line = geartooltip:AddLine(gear[i].slot)
      geartooltip:SetCell(line,2,string.format("|c%s%i|r   |T%s:20|t %s",setIlvlColor(gear[i].ilvl),gear[i].ilvl or 0,gear[i].itemTexture or "",gear[i].itemLink or ""),"LEFT",3)
      geartooltip:SetCell(line,5,enchantements,"LEFT",3)
    end
    geartooltip:AddSeparator(1,.8,.8,.8,1)
  end
  --[[if info.talents then
    line = geartooltip:AddHeader()
    geartooltip:SetCell(line,1,WrapTextInColorCode("Talents","ffffb600"),"CENTER",7)
    local selectedColor = "ffffaa00"
    local defaultColor = "ff3f3f3f"
    local talentstr = {"","",""}
    local tierNames = {"Tier 15","Tier 30","Tier 45","Tier 60","Tier 75","Tier 90","Tier 100"}
    for tier=1,#info.talents do
      local tierTalents = info.talents[tier]
      for talent=1,#tierTalents do
        talentstr[talent] = WrapTextInColorCode(
                      string.format("|T%s:20|t %s",tierTalents[talent].icon,tierTalents[talent].name),
                      tierTalents[talent].selected and selectedColor or defaultColor)
      end
      local line = geartooltip:AddLine(tierNames[tier])--,talentstr[1],talentstr[2],talentstr[3])
      geartooltip:SetCell(line,2,talentstr[1],"LEFT",2)
      geartooltip:SetCell(line,4,talentstr[2],"LEFT",2)
      geartooltip:SetCell(line,6,talentstr[3],"LEFT",2)
    end
    geartooltip:AddSeparator(1,.8,.8,.8,1)
  end]]
  if info.professions then
    -- professsions
    line = geartooltip:AddHeader()
    geartooltip:SetCell(line,1,WrapTextInColorCode("Professions","ffffb600"),"CENTER",7)
    local p = info.professions
    local tipWidth = geartooltip:GetWidth()
    for i=1,#p do
      line = geartooltip:AddLine()
      geartooltip:SetCell(line,1,string.format("|T%s:20|t%s",p[i].icon,p[i].name),"LEFT")
      geartooltip:SetCell(line,2,string.format("|cff%s%s|r",ProfessionValueColor(p[i].curr),p[i].curr),"RIGHT",6)

      local statusBar = AttachStatusBar(geartooltip.lines[line].cells[2])
      table.insert(geartooltip.statusBars,statusBar)
      statusBar:SetMinMaxValues(0,MAX_PROFESSION_LEVEL)
      statusBar:SetValue(p[i].curr)
      statusBar:SetWidth(tipWidth)
      statusBar:SetStatusBarColor(CharacterInfo.ColorHexToDec(ProfessionValueColor(p[i].curr)))
      statusBar:SetPoint("LEFT",geartooltip.lines[line].cells[2],"LEFT",5,0)
    end
    geartooltip:AddSeparator(1,.8,.8,.8,1)
  end
  local line = geartooltip:AddLine("Last Updated:")
  geartooltip:SetCell(line,2,info.updated,"LEFT",3)
  geartooltip:SetPoint("TOPRIGHT", self:GetParent(), "TOPLEFT", - 9, 10)
  geartooltip:Show()
  geartooltip:SetClampedToScreen(true)
  local parentFrameLevel = self:GetFrameLevel(self)
  geartooltip:SetFrameLevel(parentFrameLevel + 5)
  local backdrop = { bgFile = "Interface\\BUTTONS\\WHITE8X8.blp",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8.blp",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = {
      left = 0,
      right = 0,
      top = 0,
  bottom = 0 }}
  geartooltip:SetBackdrop(backdrop)
  geartooltip:SetBackdropColor(0, 0, 0, .9);
  geartooltip:SetBackdropBorderColor(.2, .2, .2, 1)
  local tipWidth = geartooltip:GetWidth()
  for i=1,#geartooltip.statusBars do
    geartooltip.statusBars[i]:SetWidth(tipWidth+tipWidth/3)
  end
end




-- DISPLAY INFO
local butTool = CreateFrame("Frame", "CharacterInfo_Tooltip", UIParent)
local bg = butTool:CreateTexture("CharInf_BG", "HIGH")
butTool:SetSize(32, 32)
bg:SetTexture("Interface\\AddOns\\CharacterInfo\\Media\\Icons\\logo")
bg:SetSize(32, 32)
butTool:SetScale(settings.iconScale)
bg:SetAllPoints()
local function SetTooltipBut()
  if not config_db.config then
    butTool:SetPoint("CENTER", UIParent, "CENTER", 200, - 50)
  else
    local point = config_db.config.point
    local relativeTo = config_db.config.relativeTo
    local relativePoint = config_db.config.relativePoint
    local xOfs = config_db.config.xOfs
    local yOfs = config_db.config.yOfs
    butTool:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
  end
end
SetTooltipBut()
butTool:SetFrameStrata("HIGH")
butTool:EnableMouse(true)
-- make icon draggable
butTool:SetMovable(true)
butTool:RegisterForDrag("LeftButton")
butTool:SetScript("OnDragStart", butTool.StartMoving)

local function CharacterInfo_StopMoving(self)
  self:StopMovingOrSizing();
  self.isMoving = false;
  local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
  local config = {}
  config.point = point
  config.relativeTo = relativeTo
  config.relativePoint = relativePoint
  config.xOfs = xOfs
  config.yOfs = yOfs
  config_db.config = config
end

butTool:SetScript("OnDragStop", CharacterInfo_StopMoving)

local function OnEnter(self)
  if QTip:IsAcquired("CharacterInfo_Tooltip") then return end
  local tooltip = QTip:Acquire("CharacterInfo_Tooltip", 5, "LEFT", "LEFT", "LEFT", "LEFT","LEFT")
  self.tooltip = tooltip
  local rData, rNum = GetRealms()
  -- sort line generators
  table.sort(registeredLineGenerators,function(a,b) return a.prio < b.prio end)

  for rIndex = 1, rNum do
    -- Realms
    local cData, cNum = GetRealmCharInfo(rData[rIndex])
    if cNum > 0 then
      -- check if realm has characters that met requirements
      tooltip:SetHeaderFont(hugeFont)
      tooltip:AddHeader(WrapTextInColorCode(rData[rIndex],"ffffd200"))
      tooltip:AddSeparator(3, 1, 0.8039, 0.3098)
    end
    for cIndex = 1, cNum do
      -- character
      tooltip:SetHeaderFont(mediumFont)
      tooltip:SetFont(smallFont)
      if settings.allowedCharacters[cData[cIndex].name .. "-" .. rData[rIndex]].enabled then
        -- make sure character is allowed
        local specIcon = cData[cIndex].spec and cData[cIndex].class .. cData[cIndex].spec or "SpecNone"
        -- character name header
        local l = tooltip:AddHeader("|TInterface\\AddOns\\CharacterInfo\\Media\\Icons\\" .. specIcon ..":25:25|t "..
          "|c" .. RAID_CLASS_COLORS[cData[cIndex].class].colorStr .. cData[cIndex].name .. "|r " ..
        (cData[cIndex].level or 0) .. ' level')
        tooltip:SetCell(l, 2, string.format("%i", cData[cIndex].iLvl or 0).. ' ilvl', "RIGHT",4,nil,nil,5)

        tooltip:SetLineScript(l,"OnEnter",GearTooltip,cData[cIndex])
        tooltip:SetLineScript(l,"OnLeave",CharacterInfo.DisposeSideTooltip())
        -- Line generators
        for i = 1, #registeredLineGenerators do
          if settings.allowedModules[registeredLineGenerators[i].name] then
            registeredLineGenerators[i].func(tooltip,cData[cIndex][registeredLineGenerators[i].key])
          end
        end
        -- Add Note to character
        AddNote(tooltip,cData[cIndex],rData[rIndex])
        --Separator for each character
        if cIndex < cNum then
          tooltip:AddSeparator(1, 1, 1, 1, .85)
        end
      end
    end
  end
  -- global data
  local gData = db.global and db.global.global or nil
  if gData and #globalLineGenerators > 0 then
    local gTip = QTip:Acquire("CharacterInfo_Tooltip_Global", 5, "LEFT", "LEFT", "LEFT", "LEFT","LEFT")
    tooltip.globalTooltip = gTip
    for i=1, #globalLineGenerators do
      globalLineGenerators[i].func(gTip,gData[globalLineGenerators[i].key])
    end
    local point = self:GetPoint()
    if config_db.config.point and config_db.config.point:find("RIGHT") then
      gTip:SetPoint("BOTTOMRIGHT",tooltip,"BOTTOMLEFT",1,0)
    else
      gTip:SetPoint("BOTTOMLEFT",tooltip,"BOTTOMRIGHT")
    end
    gTip:Show()
    local parentFrameLevel = tooltip:GetFrameLevel(tooltip)
    gTip:SetFrameLevel(parentFrameLevel)
    gTip.parent = self
    gTip.time = 0
    gTip.elapsed = 0
    gTip:SetScript("OnUpdate",function(self, elapsed)
      self.time = self.time + elapsed
      if self.time > 0.1 then
        if self.parent:IsMouseOver() or tooltip:IsMouseOver() or self:IsMouseOver() then
          self.elapsed = 0
        else
          self.elapsed = self.elapsed + self.time
          if self.elapsed > settings.delay then
              QTip:Release(self)
          end
        end
        self.time = 0
      end
    end)
    gTip:SetBackdrop(DEFAULT_BACKDROP)
    gTip:SetBackdropColor(0, 0, 0, .9);
    gTip:SetBackdropBorderColor(.2, .2, .2, 1)
  end

  -- Tooltip visuals
  tooltip:SmartAnchorTo(self)
  tooltip:SetScale(1)
  --tooltip:SetAutoHideDelay(settings.delay, self)
  tooltip.parent = self
  tooltip.time = 0
  tooltip.elapsed = 0
  tooltip:SetScript("OnUpdate",function(self, elapsed)
    self.time = self.time + elapsed
    if self.time > 0.1 then
      if self.globalTooltip:IsMouseOver() or self:IsMouseOver() or self.parent:IsMouseOver() then
        self.elapsed = 0
      else
        self.elapsed = self.elapsed + self.time
        if self.elapsed > settings.delay then
            QTip:Release(self)
        end
      end
      self.time = 0
    end
  end)
  tooltip:Show()
  tooltip:SetBackdrop(DEFAULT_BACKDROP)
  tooltip:SetBackdropColor(0, 0, 0, .9);
  tooltip:SetBackdropBorderColor(.2, .2, .2, 1)
  tooltip:UpdateScrolling(settings.tooltipHeight)
end

butTool:SetScript("OnEnter", OnEnter)

local function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a, b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

-- config --

-- control creating functions shamefully stolen from ls- toasts
-- refreshing controls
local function RegisterControlForRefresh(parent, control)
  if not parent or not control then
    return
  end

  parent.controls = parent.controls or {}
  table.insert(parent.controls, control)
end

local function RefreshOptions(panel)
  for _, control in pairs(panel.controls) do
    if control.RefreshValue then
      control:RefreshValue()
    end
  end
end
-- sliders
local function Slider_RefreshValue(self)
  local value = self:GetValue()

  self.value = value
  self:SetDisplayValue(value)
  self.CurrentValue:SetText(value)
end

local function Slider_OnValueChanged(self, value, userInput)
  if userInput then
    value = tonumber(string.format("%.2f", value))

    if value ~= self.value then
      self:SetValue(value)
      self:RefreshValue()
    end
  end
end

local function CreateConfigSlider(panel, params)
  params = params or {}

  local object = _G.CreateFrame("Slider", params.name, params.parent or panel, "OptionsSliderTemplate")
  object.type = "Slider"
  object:SetMinMaxValues(params.min, params.max)
  object:SetValueStep(params.step)
  object:SetObeyStepOnDrag(true)
  object.SetDisplayValue = object.SetValue -- default
  object.GetValue = params.get
  object.SetValue = params.set
  object.RefreshValue = Slider_RefreshValue
  object:SetScript("OnValueChanged", Slider_OnValueChanged)

  local text = _G[object:GetName().."Text"]
  text:SetText(params.text)
  text:SetVertexColor(1, 0.82, 0)
  object.Text = text

  local lowText = _G[object:GetName().."Low"]
  lowText:SetText(params.min)
  object.LowValue = lowText

  local curText = object:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  curText:SetPoint("TOP", object, "BOTTOM", 0, 3)
  object.CurrentValue = curText

  local highText = _G[object:GetName().."High"]
  highText:SetText(params.max)
  object.HighValue = highText

  RegisterControlForRefresh(panel, object)

  return object
end

-- dropdowns
local function DropDownMenu_RefreshValue(self)
  _G.UIDropDownMenu_Initialize(self, self.initialize)
  _G.UIDropDownMenu_SetSelectedValue(self, self:GetValue())
end

local function CreateConfigDropDownMenu(panel, params)
  params = params or {}

  local object = _G.CreateFrame("Frame", params.name, params.parent or panel, "UIDropDownMenuTemplate")
  object.type = "DropDownMenu"
  object.SetValue = params.set
  object.GetValue = params.get
  object.RefreshValue = DropDownMenu_RefreshValue
  _G.UIDropDownMenu_Initialize(object, params.init)
  _G.UIDropDownMenu_SetWidth(object, params.width or 128)

  local text = object:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  text:SetPoint("BOTTOMLEFT", object, "TOPLEFT", 16, 3)
  text:SetJustifyH("LEFT")
  text:SetText(params.text)
  object.Label = text

  RegisterControlForRefresh(panel, object)

  return object
end

-- divider
local function CreateConfigDivider(panel, params)
  params = params or {}

  local object = panel:CreateTexture(nil, "ARTWORK")
  object:SetHeight(4)
  object:SetPoint("LEFT", 10, 0)
  object:SetPoint("RIGHT", - 10, 0)
  object:SetTexture("Interface\\AchievementFrame\\UI-Achievement-RecentHeader")
  object:SetTexCoord(0, 1, 0.0625, 0.65625)
  object:SetAlpha(0.5)

  local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
  label:SetWordWrap(false)
  label:SetPoint("LEFT", object, "LEFT", 12, 1)
  label:SetPoint("RIGHT", object, "RIGHT", - 12, 1)
  label:SetText(params.text)
  object.Text = label

  return object
end

-- checkbox
local function CheckButton_RefreshValue(self)
  self:SetChecked(self:GetValue())
end

local function CheckButton_OnClick(self)
  self:SetValue(self:GetChecked())
end

local function CheckButton_OnEnter(self)
  _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  _G.GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
  _G.GameTooltip:Show()
end

local function CheckButton_OnLeave()
  _G.GameTooltip:Hide()
end

local function CreateConfigCheckButton(panel, params)
  params = params or {}

  local object = _G.CreateFrame("CheckButton", params.name, params.parent or panel, "InterfaceOptionsCheckButtonTemplate")
  object:SetHitRectInsets(0, 0, 0, 0)
  object.type = "Button"
  object.GetValue = params.get
  object.SetValue = params.set
  object.RefreshValue = CheckButton_RefreshValue
  object:SetScript("OnClick", params.click or CheckButton_OnClick)
  object.Text:SetText(params.text)

  if params.tooltip_text then
    object.tooltipText = params.tooltip_text
    object:SetScript("OnEnter", CheckButton_OnEnter)
    object:SetScript("OnLeave", CheckButton_OnLeave)
  end

  RegisterControlForRefresh(panel, object)

  return object
end

-- create and populate config page
local function setupConfigPage()
  local panel = CreateFrame("Frame", "CharacterInfoConfigPanel", InterfaceOptionsFramePanelContainer)
  panel.name = "CharacterInfo"
  panel:Hide()
  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, - 16)
  title:SetJustifyH("LEFT")
  title:SetJustifyV("TOP")
  title:SetText('CharacterInfo')
  -- icon lock
  local lockIconCheck = CreateConfigCheckButton(panel, {
    name = "$parentLockIconToggle",
    text = "Lock Icon",
    get = function() return settings.lockIcon end,
    set = function(_, value)
      settings.lockIcon = value
      CharacterInfo_RefreshAppearance()
    end,
  })
  lockIconCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, - 25)
  -- icon scale slider
  local scaleSlider = CreateConfigSlider(panel, {
    name = "$parentScaleSlider",
    text = "Icon scale",
    min = 0.1,
    max = 1,
    step = 0.05,
    get = function() return settings.iconScale end,
    set = function(_, value)
      settings.iconScale = value
      CharacterInfo_RefreshAppearance()
    end,
  })
  scaleSlider:SetPoint("TOPLEFT", lockIconCheck, "BOTTOMLEFT", 5, - 17)
  -- font divider
  local fontDivider = CreateConfigDivider(panel, {text = "Fonts"})
  fontDivider:SetPoint("TOP", scaleSlider, "BOTTOM", 5, - 20)
  -- tooltip max height
  local tooltipHeightSlider = CreateConfigSlider(panel, {
    name = "$parentTooltipMaxHeight",
    text = "Tooltip Max Height",
    min = 100,
    max = 1600,
    step = 20,
    get = function() return settings.tooltipHeight end,
    set = function(_, value) settings.tooltipHeight = value end,
  })
  tooltipHeightSlider:SetPoint("BOTTOM", fontDivider, "TOP", 0, 20)
  -- min level to track
  local minLevelSlider = CreateConfigSlider(panel, {
    name = "$parentMinLevelSlider",
    text = "Tracking (min character level)",
    min = 0,
    max = MAX_CHARACTER_LEVEL,
    step = 1,
    get = function() return settings.minLevel end,
    set = function(_, value) settings.minLevel = value end,
  })
  minLevelSlider:SetPoint("BOTTOMRIGHT", fontDivider, "TOPRIGHT", - 10, 20)
  -- Module Selector
  local ModuleButton = CreateFrame("Button", "CharInfo_ModuleSelector", panel, "UIPanelButtonTemplate")
  ModuleButton:SetPoint("BOTTOM",minLevelSlider,"TOP",10,30)
  ModuleButton:SetSize(120,20)
  ModuleButton:SetText("Modules")
  ModuleButton:RegisterForClicks("LeftButtonUp")
  local moduleDropdown = CreateFrame("Frame", "ModuleDropDown", panel, "UIDropDownMenuTemplate")
  local function DropdownInit(frame, level, menu)
    local info = _G.UIDropDownMenu_CreateInfo()
    local t = settings.allowedModules
    for i=1,#registeredModules do
      info.text = registeredModules[i]
      info.isNotRadio = true
      info.checked = function() return t[registeredModules[i]] end
      info.func =  function() t[registeredModules[i]] = not t[registeredModules[i]] end
      info.keepShownOnClick = true
      _G.UIDropDownMenu_AddButton(info)
    end
  end
  _G.UIDropDownMenu_Initialize(moduleDropdown,DropdownInit,"MENU")
  ModuleButton:SetScript("OnClick",function(self,button,down)
    _G.ToggleDropDownMenu(1,nil,moduleDropdown,minLevelSlider,20,45) end)
  -- fonts
  local hugeFontSlider = CreateConfigSlider(panel, {
    name = "$parentHugeFontSlider",
    text = "Big Font (like server name)",
    min = 5,
    max = 30,
    step = 1,
    get = function() return settings.fonts.big.size end,
    set = function(_, value)
      settings.fonts.big.size = value
      CharacterInfo_RefreshAppearance()
    end,
  })
  hugeFontSlider:SetPoint("TOPLEFT", fontDivider, "BOTTOMLEFT", 10, -30)
  local mediumFontSlider = CreateConfigSlider(panel, {
    name = "$parentMediumFontSlider",
    text = "Medium Font (like character name)",
    min = 5,
    max = 30,
    step = 1,
    get = function() return settings.fonts.medium.size end,
    set = function(_, value)
      settings.fonts.medium.size = value
      CharacterInfo_RefreshAppearance()
    end,
  })
  mediumFontSlider:SetPoint("TOP", fontDivider, "BOTTOM", 0, -30)
  local smallFontSlider = CreateConfigSlider(panel, {
    name = "$parentSmallFontSlider",
    text = "Small Font (information)",
    min = 5,
    max = 30,
    step = 1,
    get = function() return settings.fonts.small.size end,
    set = function(_, value)
      settings.fonts.small.size = value
      CharacterInfo_RefreshAppearance()
    end,
  })
  smallFontSlider:SetPoint("TOPRIGHT", fontDivider, "BOTTOMRIGHT", - 10, - 30)
  -- characters
  local charDivider = CreateConfigDivider(panel, {text = "Characters"})
  charDivider:SetPoint("TOP", mediumFontSlider, "BOTTOM", 0, - 20)
  local charSubtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  charSubtext:SetPoint("TOPLEFT", charDivider, "BOTTOMLEFT", 10, - 8)
  charSubtext:SetHeight(20)
  charSubtext:SetJustifyH("LEFT")
  charSubtext:SetJustifyV("TOP")
  charSubtext:SetNonSpaceWrap(true)
  charSubtext:SetMaxLines(2)
  charSubtext:SetText("Enable which characters to show.")


  local counter = 1
  local charToggles = {}
  --texplore(settings.allowedCharacters)
  for i, v in spairs(settings.allowedCharacters, function(t, a, b) return t[a].ilvl > t[b].ilvl end) do
    -- i= name-server v= tabl
    local temp = CreateConfigCheckButton(panel, {
      name = "$parent"..counter .."Toggle",
      text = WrapTextInColorCode(i, v.classClr),
      get = function() return settings.allowedCharacters[i].enabled end,
      set = function(_, value)
        settings.allowedCharacters[i].enabled = value
      end,
    })
    table.insert(charToggles, temp)
    if counter == 1 then
      temp:SetPoint("TOPLEFT", charSubtext, "BOTTOMLEFT", 0, - 5)
    elseif counter > 5 and (counter - 1)%5 == 0 then
      temp:SetPoint("LEFT", charToggles[counter - 5], "RIGHT", 150, 0)
    else
      temp:SetPoint("TOPLEFT", charToggles[counter - 1], "BOTTOMLEFT", 0, - 5)
    end
    counter = counter + 1
  end

  RefreshOptions(panel)
  -- add panel to interface
  InterfaceOptions_AddCategory(panel, true)
  InterfaceAddOnsList_Update()
  InterfaceOptionsOptionsFrame_RefreshAddOns()
end

local function OpenConfig(self, button)
  if _G.CharacterInfoConfigPanel:IsShown() then
    _G.InterfaceOptionsFrame_OpenToCategory(_G.CharacterInfoConfigPanel)
  else
    _G.InterfaceOptionsFrameOkay_OnClick(_G.CharacterInfoConfigPanel)
    _G.InterfaceOptionsFrame_OpenToCategory(_G.CharacterInfoConfigPanel)
  end
end
butTool:SetScript("OnMouseUp", OpenConfig)

-- refresh
function CharacterInfo_RefreshAppearance()
  --texplore(fontSet)
  butTool:SetMovable(not settings.lockIcon)
  butTool:RegisterForDrag("LeftButton")
  butTool:SetScript("OnDragStart", not settings.lockIcon and butTool.StartMoving or function() end)
  hugeFont:SetFont(defaultFont, settings.fonts.big.size)
  smallFont:SetFont(defaultFont, settings.fonts.small.size)
  mediumFont:SetFont(defaultFont, settings.fonts.medium.size)
  butTool:SetScale(settings.iconScale)
end

-- addon loaded
local function IsNewCharacter()
  local name = UnitName('player')
  local realm = GetRealmName()
  return db[realm] == nil or db[realm][name] == nil
end

local function init()
  CharacterInfo_DB = CharacterInfo_DB or db
  CharacterInfo_Config = CharacterInfo_Config or config_db
  if not CharacterInfo_Config.settings then
    CharacterInfo_Config.settings = settings
  elseif not CharacterInfo_Config.settings.lockIcon then
    CharacterInfo_Config.settings.lockIcon = settings.lockIcon
  end
  db = CharacterInfo.copyTable(CharacterInfo_DB)
  db.global = db.global or {}
  db.global.global = db.global.global or {}
  CharacterInfo.DB = db
  config_db = CharacterInfo.copyTable(CharacterInfo_Config)
  settings = config_db.settings
  ModernizeCharacters()
  CharacterInfo_RefreshAppearance()
  if IsNewCharacter() then
    -- for config page if it's first time that character logins
    C_Timer.After(0.2, function()
      UpdateCharacterSpecifics()
      AddMissingCharactersToSettings()
      AddModulesToSettings()
      setupConfigPage()
    end)
  else
    AddMissingCharactersToSettings()
    AddModulesToSettings()
    setupConfigPage()
  end
end

-- Reset handling
local function GetRegion()
  if not config_db.region then
    local reg = GetCVar("portal")
    if reg == "public-test" then -- PTR uses US region resets, despite the misleading realm name suffix
      reg = "US"
    end
    if not reg or #reg ~= 2 then
      local gcr = GetCurrentRegion()
      reg = gcr and ({ "US", "KR", "EU", "TW", "CN" })[gcr]
    end
    if not reg or #reg ~= 2 then
      reg = (GetCVar("realmList") or ""):match("^(%a+)%.")
    end
    if not reg or #reg ~= 2 then -- other test realms?
      reg = (GetRealmName() or ""):match("%((%a%a)%)")
    end
    reg = reg and reg:upper()
    if reg and #reg == 2 then
      config_db.region = reg
    end
  end
  return config_db.region
end

local function GetServerOffset()
  local serverDay = CalendarGetDate() - 1 -- 1-based starts on Sun
  local localDay = tonumber(date("%w")) -- 0-based starts on Sun
  local serverHour, serverMinute = GetGameTime()
  local localHour, localMinute = tonumber(date("%H")), tonumber(date("%M"))
  if serverDay == (localDay + 1)%7 then -- server is a day ahead
    serverHour = serverHour + 24
  elseif localDay == (serverDay + 1)%7 then -- local is a day ahead
    localHour = localHour + 24
  end
  local server = serverHour + serverMinute / 60
  local localT = localHour + localMinute / 60
  local offset = floor((server - localT) * 2 + 0.5) / 2
  return offset
end

local function GetNextDailyResetTime()
  local resettime = GetQuestResetTime()
  --print('resetTimedaily',resettime)
  if not resettime or resettime <= 0 or -- ticket 43: can fail during startup
  resettime > 24 * 3600 + 30 then -- can also be wrong near reset in an instance
    return nil
  end
  if false then
    local serverHour, serverMinute = GetGameTime()
    local serverResetTime = (serverHour * 3600 + serverMinute * 60 + resettime) % 86400 -- GetGameTime of the reported reset
    local diff = serverResetTime - 10800 -- how far from 3AM server
    if math.abs(diff) > 3.5 * 3600 -- more than 3.5 hours - ignore TZ differences of US continental servers
    and GetRegion() == "US" then
      local diffhours = math.floor((diff + 1800) / 3600)
      resettime = resettime - diffhours * 3600
      if resettime < - 900 then -- reset already passed, next reset
        resettime = resettime + 86400
      elseif resettime > 86400 + 900 then
        resettime = resettime - 86400
      end
      --debug("Adjusting GetQuestResetTime() discrepancy of %d seconds (%d hours). Reset in %d seconds", diff, diffhours, resettime)
    end
  end
  return time() + resettime
end

function CharacterInfo.GetNextWeeklyResetTime()
  if not config_db.resetDays then
    local region = GetRegion()
	--print('Getnextweekly region: ', region)
    if not region then return nil end
    config_db.resetDays = {}
    config_db.resetDays.DLHoffset = 0
    if region == "US" then
      config_db.resetDays["2"] = true -- tuesday
      -- ensure oceanic servers over the dateline still reset on tues UTC (wed 1/2 AM server)
      config_db.resetDays.DLHoffset = -3
    elseif region == "EU" then
      config_db.resetDays["3"] = true -- wednesday
    elseif region == "CN" or region == "KR" or region == "TW" then -- XXX: codes unconfirmed
      config_db.resetDays["4"] = true -- thursday
    else
      config_db.resetDays["2"] = true -- tuesday?
    end
  end
  local offset = (GetServerOffset() + config_db.resetDays.DLHoffset) * 3600
  local nightlyReset = GetNextDailyResetTime()
  --print('Getnextweekly nightreset: ',nightlyReset)
  --print('Getnextweekly offset: ',offset)
  if not nightlyReset then return nil end
  --while date("%A",nightlyReset+offset) ~= WEEKDAY_TUESDAY do
  while not config_db.resetDays[date("%w", nightlyReset + offset)] do
    nightlyReset = nightlyReset + 24 * 3600
  end
  return nightlyReset
end
local GetNextWeeklyResetTime = CharacterInfo.GetNextWeeklyResetTime


local function HasResetHappened()
  if not config_db.resetTime then return end
  local weeklyReset = GetNextWeeklyResetTime()
  if weeklyReset ~= config_db.resetTime then
    -- reset has happened because next weekly reset time is different from stored one
    return true
  end
  return false
end

local function ResetCoins()
  local realm, numRealms = GetRealms()
  for i = 1, numRealms do
    local charInfo, charNum = GetRealmCharInfo(realm[i])
    for ci = 1, charNum do
      if charInfo[ci].coins and charInfo[ci].level == MAX_CHARACTER_LEVEL then
        -- char can have coins
        charInfo[ci].coins.available = 3
      end
    end
  end
end

local function WipeKeysForReset()
  local keys = keysToReset
  ResetCoins()
  for i = 1, #keys do
    WipeKey(keys[i])
  end
end

local function GetLastUpdateTime()
  local d = date("*t", time())
  local gameTime = GetGameTime()
  local t = {updated = string.format("%d %s %02d:%02d",d.day,monthNames[d.month],d.hour,d.min)}
  UpdateCharacter(nil, nil, t)
end

local function ResetHandling()
  if HasResetHappened() then
    -- check for reset
    WipeKeysForReset()
  end
  config_db.resetTime = GetNextWeeklyResetTime()
end
-- Updaters

function CharacterInfo.SendFakeEvent(event) end

local delay = true
local delayedEvents = {}
local running = false
function frame:OnEvent(event, ...)
  --print(event,arg1)
  if event == "PLAYER_LOGOUT" then
    -- save things
    if db then
      CharacterInfo_DB = db
    end
    if config_db then
      CharacterInfo_Config = config_db
    end
    return
  end
  if event == "VARIABLES_LOADED" then
    init()
    SetTooltipBut()
	C_Timer.After(10,function() ResetHandling() end)
  end
  if event == "CHINFO_DELAY" then
    delay = false
    for c=1,#delayedEvents do
      local event = delayedEvents[c]
      if registeredUpdaters[event] then
        for i=1,#registeredUpdaters[event] do
          if not settings.allowedModules[registeredUpdaters[event][i].name] then return end
          if debugMode then
            local started = debugprofilestop()
            registeredUpdaters[event][i].func(event,...)
            print(registeredUpdaters[event][i].name .. ' (delayed) finished: ' .. debugprofilestop() - started)
            GetLastUpdateTime()
          else
            registeredUpdaters[event][i].func(event,...)
            GetLastUpdateTime()
          end
        end
      end
    end
    return
  end
  if delay then
    if not running then
      C_Timer.After(4,function() CharacterInfo.SendFakeEvent("CHINFO_DELAY") end)
      running = true
    end
    table.insert(delayedEvents,event)
    return
  end
  if InCombatLockdown() then return end -- Don't update in combat
  if debugMode then print('Event ',event) end
  if registeredUpdaters[event] then
    for i=1,#registeredUpdaters[event] do
      if not settings.allowedModules[registeredUpdaters[event][i].name] then return end
      if debugMode then
        local started = debugprofilestop()
        registeredUpdaters[event][i].func(event,...)
        print(registeredUpdaters[event][i].name .. ' finished: ' .. debugprofilestop() - started)
        GetLastUpdateTime()
      else
        registeredUpdaters[event][i].func(event,...)
        GetLastUpdateTime()
      end
    end
  end
  if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
    UpdateCharacterSpecifics(event)
  end
end
frame:SetScript("OnEvent", frame.OnEvent)

function CharacterInfo.SendFakeEvent(event)
   frame.OnEvent(nil,event)
 end

 local function func(...)
    CharacterInfo.SendFakeEvent("WORLD_MAP_OPEN")
 end

 hooksecurefunc(WorldMapFrame,"Show",func)

function CharacterInfo_PrintUpdates()
  local realms, numRealms = GetRealms()
  for j = 1, numRealms do
    local charInfo, charNum = GetRealmCharInfo(realms[j])
    for i = 1, charNum do
      if charInfo[i].updated then
        print(realms[j] .. ' - ' .. charInfo[i].name .. ' : ' .. charInfo[i].updated)
      end
    end
  end
end
SLASH_CHARINF1, SLASH_CHARINF2 = '/CHINFO', '/characterinfo'; -- 3.
function SlashCmdList.CHARINF(msg, editbox) -- 4.
  local args = {strsplit(" ",msg)}
  if args[1] == "" then
    OpenConfig()
  elseif args[1] == "refresh" then
    UpdateCharacterSpecifics()
  elseif args[1] == "update" then
    CharacterInfo_PrintUpdates()
  elseif args[1] == "debug" then
    print(debugMode and 'Debug: stopped' or 'Debug: started')
    debugMode = not debugMode
    CharacterInfo.debugMode = debugMode
  elseif args[1] == "reset" then
    print('Reset in: ' .. SecondsToTime(GetNextWeeklyResetTime()-time()))
  elseif args[1] == "wipe" then
    if args[2] then
      -- testing purposes
      WipeKey(args[2])
    end
  end
  --WipeKey(msg)
end
