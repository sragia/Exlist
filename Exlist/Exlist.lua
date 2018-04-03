--[[
  TODO:
  Changing icon 
]]

local addonName, addonTable = ...
local QTip = LibStub("LibQTip-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
  local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBI = LibStub("LibDBIcon-1.0")
-- SavedVariables localized
local db = {}
local config_db = {}
Exlist_Config = Exlist_Config or {}
local debugMode = false
local debugString = "|cffc73000[Exlist Debug]|r"
Exlist = {}
Exlist.debugMode = debugMode
Exlist.debugString = debugString
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
local tooltipData = {
 --[[
    [character] = {
      [modules] = {
		[module] =  {
          data = {{},{},{}}
		  priority = number
		  name = string
          num = number
		  }
	  }
	  num = number
	}
  ]]
}
local tooltipColCoords = {
  --[[
    [character] = starting column
  ]]
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
LSM:Register("font","PT_Sans_Narrow",[[Interface\Addons\Exlist\Media\Font\font.ttf]])
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
local settings = { -- default settings
  minLevel = 80,
  fonts = {
    big = { size = 15},
    medium = { size = 13},
    small = { size = 11}
  },
  Font = "PT_Sans_Narrow",
  tooltipHeight = 600,
  delay = 0.2,
  iconScale = .8,
  tooltipScale = 1,
  allowedCharacters = {},
  reorder = true,
  characterOrder = {},
  orderByIlvl = false,
  allowedModules = {},
  lockIcon = false,
  iconAlpha = 1,
  backdrop = {
    color = {r = 0,g = 0, b = 0, a = .9},
    borderColor = {r = .2,b = .2,g = .2,a = 1}
  },
  currencies = {},
  announceReset = false,
  showMinimapIcon = false,
  minimapTable = {},
  showIcon = true,
  horizontalMode = false,
  hideEmptyCurrency = false,
}
local iconPaths = {
  --[specId] = [[path]]
  [250] = [[Interface\AddOns\Exlist\Media\Icons\DEATHKNIGHTBlood.tga]],
  [251] = [[Interface\AddOns\Exlist\Media\Icons\DEATHKNIGHTFrost.tga]],
  [252] = [[Interface\AddOns\Exlist\Media\Icons\DEATHKNIGHTUnholy.tga]],

  [577] = [[Interface\AddOns\Exlist\Media\Icons\DEMONHUNTERHavoc.tga]],
  [581] = [[Interface\AddOns\Exlist\Media\Icons\DEMONHUNTERVengeance.tga]],

  [102] = [[Interface\AddOns\Exlist\Media\Icons\DRUIDBalance.tga]],
  [103] = [[Interface\AddOns\Exlist\Media\Icons\DRUIDFeral.tga]],
  [104] = [[Interface\AddOns\Exlist\Media\Icons\DRUIDGuardian.tga]],
  [105] = [[Interface\AddOns\Exlist\Media\Icons\DRUIDRestoration.tga]],

  [253] = [[Interface\AddOns\Exlist\Media\Icons\HUNTERBeastmastery.tga]],
  [254] = [[Interface\AddOns\Exlist\Media\Icons\HUNTERMarksmanship.tga]],
  [255] = [[Interface\AddOns\Exlist\Media\Icons\HUNTERSurvival.tga]],

  [62] = [[Interface\AddOns\Exlist\Media\Icons\MAGEArcane.tga]],
  [63] = [[Interface\AddOns\Exlist\Media\Icons\MAGEFire.tga]],
  [64] = [[Interface\AddOns\Exlist\Media\Icons\MAGEFrost.tga]],

  [268] = [[Interface\AddOns\Exlist\Media\Icons\MONKBrewmaster.tga]],
  [270] = [[Interface\AddOns\Exlist\Media\Icons\MONKMistweaver.tga]],
  [269] = [[Interface\AddOns\Exlist\Media\Icons\MONKWindwalker.tga]],

  [65] = [[Interface\AddOns\Exlist\Media\Icons\PALADINHoly.tga]],
  [66] = [[Interface\AddOns\Exlist\Media\Icons\PALADINProtection.tga]],
  [70] = [[Interface\AddOns\Exlist\Media\Icons\PALADINRetribution.tga]],

  [256] = [[Interface\AddOns\Exlist\Media\Icons\PRIESTDiscipline.tga]],
  [257] = [[Interface\AddOns\Exlist\Media\Icons\PRIESTHoly.tga]],
  [258] = [[Interface\AddOns\Exlist\Media\Icons\PRIESTShadow.tga]],

  [259] = [[Interface\AddOns\Exlist\Media\Icons\ROGUEAssasination.tga]],
  [260] = [[Interface\AddOns\Exlist\Media\Icons\ROGUEOutlaw.tga]],
  [261] = [[Interface\AddOns\Exlist\Media\Icons\ROGUESubtlety.tga]],

  [262] = [[Interface\AddOns\Exlist\Media\Icons\SHAMANElemental.tga]],
  [263] = [[Interface\AddOns\Exlist\Media\Icons\SHAMANEnhancement.tga]],
  [264] = [[Interface\AddOns\Exlist\Media\Icons\SHAMANRestoration.tga]],

  [265] = [[Interface\AddOns\Exlist\Media\Icons\WARLOCKAffliction.tga]],
  [266] = [[Interface\AddOns\Exlist\Media\Icons\WARLOCKDemonology.tga]],
  [267] = [[Interface\AddOns\Exlist\Media\Icons\WARLOCKDestruction.tga]],

  [71] = [[Interface\AddOns\Exlist\Media\Icons\WARRIORArms.tga]],
  [72] = [[Interface\AddOns\Exlist\Media\Icons\WARRIORFury.tga]],
  [73] = [[Interface\AddOns\Exlist\Media\Icons\WARRIORProtection.tga]],

  [0] = [[Interface\AddOns\Exlist\Media\Icons\SpecNone.tga]],
}
local butTool

-- fonts
local fontSet = settings.fonts
local font = LSM:Fetch("font",settings.Font)
local hugeFont = CreateFont("Exlist_HugeFont")
--hugeFont:CopyFontObject(GameTooltipText)
hugeFont:SetFont(font, fontSet.big.size)
local smallFont = CreateFont("Exlist_SmallFont")
---smallFont:CopyFontObject(GameTooltipText)
smallFont:SetFont(font, fontSet.small.size)
local mediumFont = CreateFont("Exlist_MediumFont")
--mediumFont:CopyFontObject(GameTooltipText)
mediumFont:SetFont(font, fontSet.medium.size)
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
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("Exlist_DELAY")

-- utility
Exlist.ShortenNumber = function(number, digits)
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

function Exlist.copyTable(source)
  return copyTableInternal(source, {})
end

function Exlist.ConvertColor(color)
  return (color / 255)
end

function Exlist.ColorHexToDec(hex)
  if not hex or strlen(hex) < 6 then return end
  local values = {}
  for i = 1, 6, 2 do
    table.insert(values, tonumber(string.sub(hex, i, i + 1), 16))
  end
  return (values[1]/ 255),(values[2]/ 255),(values[3]/ 255)
end

function Exlist.ColorDecToHex(col1,col2,col3)
  col1 = col1 or 0
  col2 = col2 or 0
  col3 = col3 or 0
  local hexColor = string.format("%02x%02x%02x",col1*255,col2*255,col3*255)
  return hexColor
end

function Exlist.TimeLeftColor(timeLeft, times, col)
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
local MyScanningTooltip = CreateFrame("GameTooltip", "ExlistScanningTooltip", UIParent, "GameTooltipTemplate")

function MyScanningTooltip.ClearTooltip(self)
  local TooltipName = self:GetName()
  self:ClearLines()
  for i = 1, 10 do
     _G[TooltipName..'Texture'..i]:SetTexture(nil)
     _G[TooltipName..'Texture'..i]:ClearAllPoints()
     _G[TooltipName..'Texture'..i]:SetPoint('TOPLEFT', self)
  end
end

Exlist.QuestTitleFromID = setmetatable({}, { __index = function(t, id)
         MyScanningTooltip:ClearTooltip()
         MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
         MyScanningTooltip:SetHyperlink("quest:"..id)
         local title = ExlistScanningTooltipTextLeft1:GetText()
         MyScanningTooltip:Hide()
         if title and title ~= RETRIEVING_DATA then
            t[id] = title
            return title
         end
end })

function Exlist.GetItemEnchant(itemLink)
  MyScanningTooltip:ClearTooltip()
  MyScanningTooltip:SetOwner(UIParent,"ANCHOR_NONE")
  MyScanningTooltip:SetHyperlink(itemLink)
  local enchantKey = ENCHANTED_TOOLTIP_LINE:gsub('%%s', '(.+)')
  for i=1,MyScanningTooltip:NumLines() do
    if _G["ExlistScanningTooltipTextLeft"..i]:GetText() and _G["ExlistScanningTooltipTextLeft"..i]:GetText():match(enchantKey) then
      -- name,id
      local name = _G["ExlistScanningTooltipTextLeft"..i]:GetText()
      name = name:match("^%w+: (.*)")
      local _,_,enchantId = strsplit(":",itemLink)
      return name, enchantId
    end
  end
end

function Exlist.GetItemGems(itemLink)
  local t = {}
  for i=1,MAX_NUM_SOCKETS do
    local name,iLink = GetItemGem(itemLink,i)
    if iLink then
      local icon = select(10,GetItemInfo(iLink))
      table.insert(t,{name = name,icon = icon})
    end
  end
  MyScanningTooltip:ClearTooltip()
  MyScanningTooltip:SetOwner(UIParent,"ANCHOR_NONE")
  MyScanningTooltip:SetHyperlink(itemLink)
  for i=1,MAX_NUM_SOCKETS do
    local tex = _G["ExlistScanningTooltipTexture"..i]:GetTexture()
    if tex then
      tex = tostring(tex)
      if tex:find("Interface\\ItemSocketingFrame\\UI--Empty") then
        table.insert(t,{name = "|cFFccccccEmpty Slot",icon = tex})
      end
    end
  end
  return t
end

function Exlist.QuestInfo(questid)
  if not questid or questid == 0 then return nil end
  MyScanningTooltip:ClearTooltip()
  MyScanningTooltip:SetOwner(UIParent,"ANCHOR_NONE")
  MyScanningTooltip:SetHyperlink("\124cffffff00\124Hquest:"..questid..":90\124h[]\124h\124r")
  local l = _G[MyScanningTooltip:GetName().."TextLeft1"]
  l = l and l:GetText()
  if not l or #l == 0 then return nil end -- cache miss
  return l, "\124cffffff00\124Hquest:"..questid..":90\124h["..l.."]\124h\124r"
end

Exlist.FormatTimeMilliseconds = function(time)
  if not time then return end
  local minutes = math.floor((time/1000)/60)
  local seconds = math.floor((time - (minutes*60000))/1000)
  local milliseconds = time-(minutes*60000)-(seconds*1000)
  return string.format("%02d:%02d:%02d",minutes,seconds,milliseconds)
end

function Exlist.GetTableNum(t)
  if type(t) ~= "table" then
    return 0
  end
  local count = 0
  for i in pairs(t) do
    count = count + 1
  end
  return count
end

function Exlist.Debug(...) 
  if debugMode then
    print(debugString,...)
  end
end


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
            order = 100,
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

function Exlist.UpdateChar(key,data,charname,charrealm)
  if not data or not key then return end
  charrealm = charrealm or GetRealmName()
  charname = charname or UnitName('player')
  db[charrealm] = db[charrealm] or {}
  db[charrealm][charname] = db[charrealm][charname] or {}
  local charToUpdate = db[charrealm][charname]
  charToUpdate[key] = data
end

function Exlist.GetCachedItemInfo(itemId)
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
  Exlist.Debug('wiped ' .. key)
  for realm in pairs(db) do
    for name in pairs(db[realm]) do
      for keys in pairs(db[realm][name]) do
        if keys == key then
            Exlist.Debug(' - wiping ',key, ' Fromn:',name,'-',realm)
          db[realm][name][key] = nil
        end
      end
    end
  end
    Exlist.Debug(' Wiping Key (',key,') completed.')
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
  Exlist.UpdateChar("talents",t)
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
      local relics = {}
      local enchant,gem
      if not (order[i] == 16 or order[i] == 17 or order[i] == 18) then
        enchant = Exlist.GetItemEnchant(iLink)
        gem = Exlist.GetItemGems(iLink)
      end
      table.insert(t,{slot = slotNames[order[i]], name = itemName,itemTexture = itemTexture, itemLink = itemLink,
                      ilvl = itemLevel, enchant = enchant, gem = gem})
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
  Exlist.UpdateChar("gear",t)
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
  Exlist.UpdateChar("professions",t)
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
  local specId, spec = GetSpecializationInfo(GetSpecialization())
  local realm = GetRealmName()
  local table = {}
  table.level = level
  table.class = class
  table.iLvl = iLvl
  table.spec = spec
  table.specId = specId
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

local function GetPosition(point,xpos,ypos)
  local screenWidth = GetScreenWidth()
  xpos = xpos or 0 
  ypos = ypos or 0
  local vPos,xPos
  if point:find("LEFT") then
    if xpos > (screenWidth/2) then
      xPos = "left" -- left side
    else
      xPos = "right" -- right side
    end
  elseif point:find("RIGHT") then
    if xpos < (screenWidth/2) then
      xPos = "left" -- left side
    else
      xPos = "right" -- right side
    end
  else
    if xpos > 0 then
      xPos = "left"-- left side
    else
      xPos = "right" -- right side
    end
  end
  if point:find("TOP") then
    vPos = "bottom"
  else
    vPos = "top"
  end
  return xPos,vPos
end

local function AttachStatusBar(frame)
  local statusBar = CreateFrame("StatusBar", nil, frame)
  statusBar:SetStatusBarTexture("Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar")
  statusBar:GetStatusBarTexture():SetHorizTile(false)
  local bg = {
    bgFile = "Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar"
  }
  statusBar:SetBackdrop(bg)
  statusBar:SetBackdropColor(.1, .1, .1, .8)
  statusBar:SetStatusBarColor(Exlist.ColorHexToDec("ffffff"))
  statusBar:SetMinMaxValues(0, 100)
  statusBar:SetValue(0)
  statusBar:SetHeight(5)
--  print('createdNewStatusBar')
  return statusBar
end

-- Modules/API
-- Info attaching to tooltip
function Exlist.AddLine(tooltip,info)
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

local lineNums = {} -- only for Horizontal
local columnNums = {} -- only for Horizontal
local lastLineNum = 1 -- only for Horizontal
local lastColNum = -2 -- only for Horizontal
local function releasedTooltip()
  lineNums = {} -- only for Horizontal
  columnNums = {} -- only for Horizontal
  lastLineNum = 1 -- only for Horizontal
  lastColNum = -2 
end

function Exlist.AddData(info)
  --[[
      info = {
        data = "string" text to be displayed
        character = "name-realm" which column to display
        moduleName = "key" Module key
        titleName = "string" row title
        colOff = number (optional) offset from first column defaults:0
        dontResize = boolean (optional) if cell should span across
        OnEnter = function (optional) script
        OnEnterData = {} (optional) scriptData
        OnLeave = function (optional) script
        OnLeaveData = {} (optional) scriptData
        OnClick = function (optional) script
        OnClickData = {} (optional) scriptData
      }
  ]]
  if not info then return end 
  info.colOff = info.colOff or 0
  tooltipData[info.character] =  tooltipData[info.character] or {modules = {},num = 0}
  local t = tooltipData[info.character]
  if t.modules[info.moduleName] then
    table.insert(t.modules[info.moduleName].data,info)
    t.modules[info.moduleName].num = t.modules[info.moduleName].num + 1
  else
    if info.moduleName ~= "_Header" and info.moduleName ~= "_HeaderSmall" then
      t.num = t.num + 1
    end
    t.modules[info.moduleName] = {
      data  = {info},
      priority = info.priority,
      name = info.titleName,
      num = 1
    }
  end
end


function Exlist.AddToLine(tooltip,row,col,text)
  -- Add text to lines column
  if not tooltip or not row or not col or not text then return end
  tooltip:SetCell(row,col,text)
end

function Exlist.AddScript(tooltip,row,col,event,func,arg)
  -- Script for cell
  if not tooltip or not row or not event or not func then return end
  if col then
    tooltip:SetCellScript(row,col,event,func,arg)
  else
    tooltip:SetLineScript(row,event,func,arg)
  end
end

function Exlist.CreateSideTooltip(statusbar)
  -- Creates Side Tooltip function that can be attached to script
  -- statusbar(optional) {} {enabled = true, curr = ##, total = ##, color = 'hex'}
  local function a(self, info)
    -- info {} {body = {'1st lane',{'2nd lane', 'side number w/e'}},title = ""}
    local sideTooltip = QTip:Acquire("CharInf_Side", 2, "LEFT", "RIGHT")
    sideTooltip:SetScale(settings.tooltipScale or 1)
    self.sideTooltip = sideTooltip
    sideTooltip:SetHeaderFont(hugeFont)
    sideTooltip:SetFont(smallFont)
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
    local point,_,_,xpos,ypos = butTool:GetPoint()
    local position,vPos = GetPosition(point,xpos,ypos)
    if position == "left" then 
      sideTooltip:SetPoint("TOPRIGHT", self:GetParent(), "TOPLEFT", - 9, 10)
    else 
      sideTooltip:SetPoint("TOPLEFT", self:GetParent(), "TOPRIGHT", 9, 10)
    end
    sideTooltip:Show()
    sideTooltip:SetClampedToScreen(true)
    local parentFrameLevel = self:GetFrameLevel(self)
    sideTooltip:SetFrameLevel(parentFrameLevel + 5)
    sideTooltip:SetBackdrop(DEFAULT_BACKDROP)
    local c = settings.backdrop
    sideTooltip:SetBackdropColor(c.color.r, c.color.g, c.color.b, c.color.a);
    sideTooltip:SetBackdropBorderColor(c.borderColor.r, c.borderColor.g, c.borderColor.b, c.borderColor.a)
    if statusbar then
      statusbar.total = statusbar.total or 100
      statusbar.curr = statusbar.curr or 0
      local statusBar = CreateFrame("StatusBar", nil, sideTooltip)
      self.statusBar = statusBar
      statusBar:SetStatusBarTexture("Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar")
      statusBar:GetStatusBarTexture():SetHorizTile(false)
      local bg = {
        bgFile = "Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar"
      }
      statusBar:SetBackdrop(bg)
      statusBar:SetBackdropColor(.1, .1, .1, .8)
      statusBar:SetStatusBarColor(Exlist.ColorHexToDec(statusbar.color))
      statusBar:SetMinMaxValues(0, statusbar.total)
      statusBar:SetValue(statusbar.curr)
      statusBar:SetWidth(sideTooltip:GetWidth() - 2)
      statusBar:SetHeight(5)
      statusBar:SetPoint("TOPLEFT", sideTooltip, "BOTTOMLEFT", 1, 0)
    end

  end
  return a
end

function Exlist.DisposeSideTooltip()
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
function Exlist.RegisterModule(data)
  --[[
  data = table
    {
    name = string (name of module)
    key = string (module key that will be used in db)
    linegenerator = func  (function that adds text to tooltip   function(tooltip,Exlist) ...)
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

function Exlist.GetRealmNames()
  local t = {}
  for i in pairs(db) do
    if i ~= "global" then
      t[#t+1] = i
    end
  end
  return t
end

function Exlist.GetRealmCharacters(realm)
  local t = {}
  if db[realm] then
    for i in pairs(db[realm]) do
      t[i] = true
    end
  end
  return t
end

function Exlist.GetCharacterTable(realm,name)
  local t = {}
  if db[realm] and db[realm][name] then
    t = db[realm][name]
  end
  return t
end

function Exlist.GetCharacterTableKey(realm,name,key)
  local t = {}
  if db[realm] and db[realm][name] and db[realm][name][key] then
    t = db[realm][name][key]
  end
  return t
end

function Exlist.CharacterExists(realm,name)
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

local function GetCharacterOrder()
  if not settings.reorder then
    return settings.characterOrder
  end
  local t ={}
  for i,v in pairs(settings.allowedCharacters) do
    if v.enabled then
      if settings.orderByIlvl then
        table.insert(t,{name = v.name,realm = i:match("^.*-(.*)"),ilvl = v.ilvl or 0})
      else
        table.insert(t,{name = v.name,realm = i:match("^.*-(.*)"),order = v.order or 0})
      end
    end
  end
  if settings.orderByIlvl then
    table.sort(t,function(a,b) return a.ilvl>b.ilvl end)
  else
    table.sort(t,function(a,b) return a.order<b.order end)
  end
  settings.characterOrder = t
  settings.reorder = false
  return t
end


local function AddNote(tooltip,data,realm,name)
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
  
  geartooltip:SetScale(settings.tooltipScale or 1)
  self.sideTooltip = geartooltip
  geartooltip:SetHeaderFont(hugeFont)
  geartooltip:SetFont(smallFont)
  local fontName, fontHeight, fontFlags = geartooltip:GetFont()
  local specIcon = info.specId and iconPaths[info.specId] or iconPaths[0]
  -- character name header
  local header = "|T" .. specIcon ..":25:25|t "..
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
        if type(gear[i].gem) == 'table' then
          if gear[i].enchant then
            enchantements = string.format("%s%s|r","|cff00ff00",gear[i].enchant or "")
          end
          for b=1,#gear[i].gem do
            if enchantements ~= "" then
              enchantements = string.format("%s\n|T%s:20|t%s",enchantements,gear[i].gem[b].icon,gear[i].gem[b].name)
            else
              enchantements = string.format("|T%s:20|t%s",gear[i].gem[b].icon,gear[i].gem[b].name)
            end
          end
        end
      elseif hasEnchantSlot[gear[i].slot] then
        enchantements = WrapTextInColorCode("No Enchant!","ffff0000")
      end
      local line = geartooltip:AddLine(gear[i].slot)
      geartooltip:SetCell(line,2,string.format("|c%s%-5d|r",setIlvlColor(gear[i].ilvl),gear[i].ilvl or 0))
      geartooltip:SetCell(line,3,string.format("|T%s:20|t %s",gear[i].itemTexture or "",gear[i].itemLink or ""),"LEFT",2)
      geartooltip:SetFont(fontName, fontHeight and fontHeight-2 or 10, fontFlags)
      geartooltip:SetCell(line,5,enchantements,"LEFT",3)
      geartooltip:SetFont(smallFont)
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
  if info.professions and #info.professions > 0 then
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
      statusBar:SetStatusBarColor(Exlist.ColorHexToDec(ProfessionValueColor(p[i].curr)))
      statusBar:SetPoint("LEFT",geartooltip.lines[line].cells[2],"LEFT",5,0)
    end
    geartooltip:AddSeparator(1,.8,.8,.8,1)
  end
  local line = geartooltip:AddLine("Last Updated:")
  geartooltip:SetCell(line, 2,info.updated,"LEFT",3)

  local point,_,_,xpos,ypos = butTool:GetPoint()
  local position,vPos = GetPosition(point,xpos,ypos)
  if position == "left" then 
    geartooltip:SetPoint("TOPRIGHT", self:GetParent(), "TOPLEFT", - 9, 10)
  else 
    geartooltip:SetPoint("TOPLEFT", self:GetParent(), "TOPRIGHT", 9, 10)
  end
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
  local c = settings.backdrop
  geartooltip:SetBackdropColor(c.color.r, c.color.g, c.color.b, c.color.a);
  geartooltip:SetBackdropBorderColor(c.borderColor.r, c.borderColor.g, c.borderColor.b, c.borderColor.a)
  local tipWidth = geartooltip:GetWidth()
  for i=1,#geartooltip.statusBars do
    geartooltip.statusBars[i]:SetWidth(tipWidth+tipWidth/3)
  end
end




-- DISPLAY INFO
butTool = CreateFrame("Frame", "Exlist_Tooltip", UIParent)
local bg = butTool:CreateTexture("CharInf_BG", "HIGH")
butTool:SetSize(32, 32)
bg:SetTexture("Interface\\AddOns\\Exlist\\Media\\Icons\\logo")
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

local function Exlist_StopMoving(self)
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




local function PopulateTooltip(tooltip)
  -- Setup Tooltip (Add appropriate amounts of rows)
  local modulesAdded = {} -- for horizontal
  local moduleLine = {} -- for horizontal
  local charHeaderRows = {} -- for vertical
  local charOrder = GetCharacterOrder()
  for i=1,#charOrder do
    local character = charOrder[i].name .. charOrder[i].realm
    local t = tooltipData[character]
    if t then
      if settings.horizontalMode then
        for module,info in pairs(t.modules) do
          if not modulesAdded[module] and (module ~= "_Header" and module ~= "_HeaderSmall") then
            modulesAdded[module] = {prio=info.priority, name = info.name}
          end
        end
      else
        -- for vertical we add rows already because we need to know where to put seperator
        tooltip:AddHeader()
        local l = tooltip:AddLine()
        table.insert(charHeaderRows,l)
        for i=1,t.num do
          tooltip:AddLine()
        end
        if i ~= #charOrder then
          tooltip:AddSeparator(1, 1, 1, 1, .85)
        end
      end
    end
  end
  -- add rows for horizontal
  if settings.horizontalMode then 
    tooltip:AddHeader()
    tooltip:AddLine()
    tooltip:AddSeparator(1, 1, 1, 1, .85)
    -- Add Module Texts
    for module,info in spairs(modulesAdded,function(t,a,b) return t[a].prio<t[b].prio end) do
      moduleLine[module] = tooltip:AddLine(info.name)
    end
  end

  -- Add Char Info
  local rowHeadNum = 2
  for i=1,#charOrder do
    local character = charOrder[i].name .. charOrder[i].realm
    if tooltipData[character] then
      local col = tooltipColCoords[character]
      local justification = settings.horizontalMode and "CENTER" or "LEFT"
      -- Add Headers
      local headerCol = settings.horizontalMode and col or 1
      local headerWidth = settings.horizontalMode and 3 or 4
      local header = tooltipData[character].modules["_Header"]
      if settings.horizontalMode then
        tooltip:SetCell(1,1,"|T"..[[Interface/Addons/Exlist/Media/Icons/ExlistLogo2.tga]]..":40:80|t","CENTER")
        tooltip:SetCell(rowHeadNum-1,headerCol,header.data[1].data.."             " .. header.data[2].data,"CENTER",4)
        tooltip:SetCellScript(rowHeadNum-1,headerCol,"OnEnter",header.data[1].OnEnter,header.data[1].OnEnterData)
        tooltip:SetCellScript(rowHeadNum-1,headerCol,"OnLeave",header.data[1].OnLeave,header.data[1].OnLeaveData)
      else
        tooltip:SetCell(rowHeadNum-1,headerCol,header.data[1].data,"LEFT",headerWidth)
        tooltip:SetCell(rowHeadNum-1,headerCol+headerWidth,header.data[2].data,"RIGHT")
        tooltip:SetLineScript(rowHeadNum-1,"OnEnter",header.data[1].OnEnter,header.data[1].OnEnterData)
        tooltip:SetLineScript(rowHeadNum-1,"OnLeave",header.data[1].OnLeave,header.data[1].OnLeaveData)
      end
      local smallHeader = tooltipData[character].modules["_HeaderSmall"]
      tooltip:SetCell(rowHeadNum,headerCol,smallHeader.data[1].data,justification,4,nil,nil,nil,2000,170)
      -- Add Module Data
      local offsetRow = 0
      local row = 0
      for module,info in spairs(tooltipData[character].modules,function(t,a,b) return t[a].priority<t[b].priority end) do
        if module ~= "_HeaderSmall" and module ~= "_Header" then
          offsetRow = offsetRow + 1
          -- Find Row
          if settings.horizontalMode then
            row = moduleLine[module]
          else
            row = rowHeadNum + offsetRow
            tooltip:SetCell(row,1,info.name) -- Add Module Name
          end
          -- how many rows should 1 data object take (Spread them out)
          local width = math.floor(4/info.num)
          local spreadMid = info.num == 3
          local offsetCol = 0
          -- Add Module Data
          for i=1,info.num do 
            local data = info.data[i]
            local column = col + width*data.colOff
            if i == 2 and spreadMid then width = 2 end
            tooltip:SetCell(row,col + offsetCol,data.data,justification,width)
            if data.OnEnter then
              tooltip:SetCellScript(row,col + offsetCol,"OnEnter",data.OnEnter,data.OnEnterData)
            end
            if data.OnLeave then
              tooltip:SetCellScript(row,col + offsetCol,"OnLeave",data.OnLeave,data.OnLeaveData)
            end
            if data.OnClick then
              tooltip:SetCellScript(row,col + offsetCol,"OnMouseDown",data.OnClick,data.OnClickData)
            end
            offsetCol = offsetCol + width
            if i == 2 then width = 1 end
          end
        end
      end
      rowHeadNum = settings.horizontalMode and 2 or charHeaderRows[i+1]
    end
  end
  -- Color every second line for horizontal orientation
  if settings.horizontalMode then
    for i=4,tooltip:GetLineCount() do 
      if i%2 == 0 then
        tooltip:SetLineColor(i,1,1,1,0.2)
      end
    end
  end
end

butTool:SetScript("OnDragStop", Exlist_StopMoving)

local function OnEnter(self)
  if QTip:IsAcquired("Exlist_Tooltip") then return end
  self:SetAlpha(1)
  tooltipData = {}
  -- sort line generators
  table.sort(registeredLineGenerators,function(a,b) return a.prio < b.prio end)

  local charOrder = GetCharacterOrder()
  local tooltip 
  if settings.horizontalMode then
    tooltip = QTip:Acquire("Exlist_Tooltip", (#charOrder*4)+1)
  else
    tooltip = QTip:Acquire("Exlist_Tooltip", 5)
  end
  tooltip:SetCellMarginV(3)
  tooltip:SetScale(settings.tooltipScale or 1)
  self.tooltip = tooltip

  tooltip:SetHeaderFont(mediumFont)
  tooltip:SetFont(smallFont)

  --[[if settings.horizontalMode then 
    -- Setup Header for horizontal
    tooltip:AddHeader() 
    tooltip:SetFont(smallFont)
    tooltip:AddLine()
    tooltip:AddSeparator(1, 1, 1, 1, .85)
  end]]
  -- character info main tooltip
  for i=1,#charOrder do
    local name = charOrder[i].name
    local realm = charOrder[i].realm
    local character = name..realm
    local charData = Exlist.GetCharacterTable(realm,name)
    charData.name = name
    -- header
    local specIcon = charData.specId and iconPaths[charData.specId] or iconPaths[0]

    -- Header Info
    Exlist.AddData({
      data = "|T" .. specIcon ..":25:25|t ".. "|c" .. RAID_CLASS_COLORS[charData.class].colorStr .. name .. "|r ",
      character = character,
      priority = -1000,
      moduleName = "_Header",
      titleName = "Header",
      OnEnter = GearTooltip,
      OnEnterData = charData,
      OnLeave = Exlist.DisposeSideTooltip()

    })
    Exlist.AddData({
      data = string.format("%i ilvl", charData.iLvl or 0),
      character = character,
      priority = -1000,
      moduleName = "_Header",
      titleName = "Header",
    })
    Exlist.AddData({
      data = string.format("|c%s%s - Level %i","ffffd200",realm,charData.level),
      character = character,
      priority = -999,
      moduleName = "_HeaderSmall",
      titleName = "Header",
      OnEnter = GearTooltip,
      OnEnterData = charData,
      OnLeave = Exlist.DisposeSideTooltip()
    })

    
    local col = settings.horizontalMode and ((i-1)*4)+2 or 2
    tooltipColCoords[character] = col


    --[[if settings.horizontalMode then
      tooltip:SetHeaderFont(mediumFont)
      local col = ((i-1)*4)+2
      tooltipColCoords[character] = col
      tooltip:SetCell(1,col,"|T" .. specIcon ..":25:25|t "..
      "|c" .. RAID_CLASS_COLORS[charData.class].colorStr .. name .. "|r ")
      tooltip:SetCell(1, col+1, string.format("%i ilvl", charData.iLvl or 0), "RIGHT",3)
      tooltip:SetCellScript(1,col,"OnEnter",GearTooltip,charData)
      tooltip:SetCellScript(1,col,"OnLeave",Exlist.DisposeSideTooltip())
      tooltip:SetFont(smallFont)
      tooltip:SetCell(2,col,string.format("|c%s%s - Level %i","ffffd200",realm,charData.level), "CENTER",4)
    else
      tooltipColCoords[character] = 2
      tooltip:SetHeaderFont(mediumFont)
      local l = tooltip:AddHeader("|T" .. specIcon ..":25:25|t "..
      "|c" .. RAID_CLASS_COLORS[charData.class].colorStr .. name .. "|r ")
      tooltip:SetHeaderFont(smallFont)
      tooltip:SetHeaderFont(mediumFont)
      tooltip:SetCell(l, 2, string.format("%i ilvl", charData.iLvl or 0), "RIGHT",4,nil,nil,5)
      tooltip:SetLineScript(l,"OnEnter",GearTooltip,charData)
      tooltip:SetLineScript(l,"OnLeave",Exlist.DisposeSideTooltip())
      tooltip:SetFont(smallFont)
      tooltip:AddLine(string.format("|c%s%s - Level %i","ffffd200",realm,charData.level))
      tooltip:AddLine()
    end]]


    -- Add Info
    for i = 1, #registeredLineGenerators do
      if settings.allowedModules[registeredLineGenerators[i].name] then
        registeredLineGenerators[i].func(tooltip,charData[registeredLineGenerators[i].key],character)
      end
    end
    --AddNote(tooltip,charData,realm,name)
    --[[if i < #charOrder and not settings.horizontalMode then
      tooltip:AddSeparator(1, 1, 1, 1, .85)
    end]]
  end
  -- Add Data
  PopulateTooltip(tooltip)
  -- global data
  local gData = db.global and db.global.global or nil
  if gData and #globalLineGenerators > 0 then
    local gTip = QTip:Acquire("Exlist_Tooltip_Global", 5, "LEFT", "LEFT", "LEFT", "LEFT","LEFT")
    
    gTip:SetScale(settings.tooltipScale or 1)
    gTip:SetFont(smallFont)
    tooltip.globalTooltip = gTip
    for i=1, #globalLineGenerators do
      globalLineGenerators[i].func(gTip,gData[globalLineGenerators[i].key])
    end
    local screenWidth = GetScreenWidth()
    local position = "left"
    if self:GetParent():GetName() == "Minimap" then
      -- ehhh Fix Minimap Button Location later
      -- Leave Position as left for now
    else
      local point,_,_,xpos,ypos = self:GetPoint()
      position,vpos = GetPosition(point,xpos,ypos)
    end
    if position == "left" then 
      if settings.horizontalMode then
        if vpos == "bottom" then
          gTip:SetPoint("TOPRIGHT",tooltip,"BOTTOMRIGHT",0,1)
        else
          gTip:SetPoint("BOTTOMRIGHT",tooltip,"TOPRIGHT",0,-1)
        end
      else
        gTip:SetPoint("BOTTOMRIGHT",tooltip,"BOTTOMLEFT",1,0)
      end
    else 
      if settings.horizontalMode then
        if vpos == "bottom" then
          gTip:SetPoint("TOPLEFT",tooltip,"BOTTOMLEFT",0,1)
        else
          gTip:SetPoint("BOTTOMLEFT",tooltip,"TOPLEFT",0,-1)
        end
      else
        gTip:SetPoint("BOTTOMLEFT",tooltip,"BOTTOMRIGHT")
      end
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
    local c = settings.backdrop
    gTip:SetBackdropColor(c.color.r, c.color.g, c.color.b, c.color.a);
    gTip:SetBackdropBorderColor(c.borderColor.r, c.borderColor.g, c.borderColor.b, c.borderColor.a)
  end

  -- Tooltip visuals
  tooltip:SmartAnchorTo(self)
  --tooltip:SetAutoHideDelay(settings.delay, self)
  tooltip.parent = self
  tooltip.time = 0
  tooltip.elapsed = 0
  tooltip:SetScript("OnUpdate",function(self, elapsed)
    self.time = self.time + elapsed
    if self.time > 0.1 then
      if self.globalTooltip and self.globalTooltip:IsMouseOver() or self:IsMouseOver() or self.parent:IsMouseOver() then
        self.elapsed = 0
      else
        self.elapsed = self.elapsed + self.time
        if self.elapsed > settings.delay then
            self.parent:SetAlpha(settings.iconAlpha or 1)
            releasedTooltip()
            QTip:Release(self)
        end
      end
      self.time = 0
    end
  end)
  tooltip:Show()
  tooltip:SetBackdrop(DEFAULT_BACKDROP)
  local c = settings.backdrop
  tooltip:SetBackdropColor(c.color.r, c.color.g, c.color.b, c.color.a);
  tooltip:SetBackdropBorderColor(c.borderColor.r, c.borderColor.g, c.borderColor.b, c.borderColor.a)
  tooltip:UpdateScrolling(settings.tooltipHeight)
end

butTool:SetScript("OnEnter", OnEnter)




-- config --

local function OpenConfig(self, button)
    InterfaceOptionsFrame_OpenToCategory(addonName)
		InterfaceOptionsFrame_OpenToCategory(addonName)
end
butTool:SetScript("OnMouseUp", OpenConfig)


-- LibDataBroker Button

local LDB_Exlist = LDB:NewDataObject("Exlist",{
  type = "data source",
  text = "Exlist",
  icon = "Interface\\AddOns\\Exlist\\Media\\Icons\\logo",
  OnClick = OpenConfig,
  OnEnter = OnEnter
})



-- refresh
function Exlist_RefreshAppearance()
  --texplore(fontSet)
  butTool:SetAlpha(settings.iconAlpha or 1)
  butTool:SetMovable(not settings.lockIcon)
  butTool:RegisterForDrag("LeftButton")
  butTool:SetScript("OnDragStart", not settings.lockIcon and butTool.StartMoving or function() end)
  local font = LSM:Fetch("font",settings.Font)
  hugeFont:SetFont(font, settings.fonts.big.size)
  smallFont:SetFont(font, settings.fonts.small.size)
  mediumFont:SetFont(font, settings.fonts.medium.size)
  butTool:SetScale(settings.iconScale)
  if settings.showMinimapIcon then
    LDBI:Show("Exlist")
  else
    LDBI:Hide("Exlist")
  end
  if settings.showIcon then
    butTool:Show()
  else
    butTool:Hide()
  end
end

-- addon loaded
local function IsNewCharacter()
  local name = UnitName('player')
  local realm = GetRealmName()
  return db[realm] == nil or db[realm][name] == nil
end
function Exlist.SetupConfig()
end
local function init()
  Exlist_DB = Exlist_DB or db
  Exlist_Config = Exlist_Config or config_db
  if not Exlist_Config.settings then
    Exlist_Config.settings = settings
  else
   -- set Defaults
    for i,v in pairs(settings) do
      if Exlist_Config.settings[i] == nil then
        Exlist_Config.settings[i] = v
      end
   end
  end
  db = Exlist.copyTable(Exlist_DB)
  db.global = db.global or {}
  db.global.global = db.global.global or {}
  Exlist.DB = db
  config_db = Exlist.copyTable(Exlist_Config)
  settings = config_db.settings
  Exlist.ConfigDB = config_db
  settings.reorder = true 
  -- Minimap Icon
  LDBI:Register("Exlist",LDB_Exlist,settings.minimapTable)

  ModernizeCharacters()  

  if IsNewCharacter() then
    -- for config page if it's first time that character logins
    C_Timer.After(0.2, function()
      UpdateCharacterSpecifics()
      AddMissingCharactersToSettings()
      AddModulesToSettings()
      Exlist.SetupConfig()
    end)
  else
    AddMissingCharactersToSettings()
    AddModulesToSettings()
    Exlist.SetupConfig()
  end
  C_Timer.After(0.5, function() Exlist_RefreshAppearance() end)
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

function Exlist.GetNextWeeklyResetTime()
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
local GetNextWeeklyResetTime = Exlist.GetNextWeeklyResetTime


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

local function AnnounceReset(msg)
  local channel = IsInRaid() and "raid" or "party"
  if IsInGroup() then
    SendChatMessage(string.format("[%s] %s",addonName,msg),channel)
  end
end

-- Updaters

function Exlist.SendFakeEvent(event) end
local delay = true
local delayedEvents = {}
local running = false

local runEvents = {}
local function IsEventEligible(event)
  if runEvents[event] then
      if GetTime() - runEvents[event] > 0.5 then
        runEvents[event] = nil
        return true
      else
        Exlist.Debug("Denied running event(",event,")")
        return false
      end
  else
    runEvents[event] = GetTime()
    return true
  end
end

function frame:OnEvent(event, ...)
  --print(event,arg1)
  if not IsEventEligible(event) then return end
  if event == "PLAYER_LOGOUT" then
    -- save things
    if db then
      Exlist_DB = db
    end
    if config_db then
      Exlist_Config = config_db
    end
    return
  end
  if event == "VARIABLES_LOADED" then
    init()
    SetTooltipBut()
	C_Timer.After(10,function() ResetHandling() end)
  end
  if event == "Exlist_DELAY" then
    delay = false
    for event,f in pairs(registeredUpdaters) do
      for i=1, #f do
          local started = debugprofilestop()
          f[i].func(event,...)
          Exlist.Debug(registeredUpdaters[event][i].name .. ' (delayed) finished: ' .. debugprofilestop() - started)
          GetLastUpdateTime()
      end
    end
    return
  end
  if delay then
    if not running then
      C_Timer.After(4,function() Exlist.SendFakeEvent("Exlist_DELAY") end)
      running = true
    end
    return
  end
  if InCombatLockdown() then return end -- Don't update in combat
  Exlist.Debug('Event ',event)
  if registeredUpdaters[event] then
    for i=1,#registeredUpdaters[event] do
      if not settings.allowedModules[registeredUpdaters[event][i].name] then return end
      local started = debugprofilestop()
      registeredUpdaters[event][i].func(event,...)
      Exlist.Debug(registeredUpdaters[event][i].name .. ' finished: ' .. debugprofilestop() - started)
      GetLastUpdateTime()
      
    end
  end
  if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
    UpdateCharacterSpecifics(event)
  elseif event == "CHAT_MSG_SYSTEM" then

    if settings.announceReset and ... then
      local resetString = INSTANCE_RESET_SUCCESS:gsub("%%s",".+")
      local msg = ...
      if msg:match("^"..resetString.."$") then
        AnnounceReset(msg)
      end
    end
  end
end
frame:SetScript("OnEvent", frame.OnEvent)

function Exlist.SendFakeEvent(event)
   frame.OnEvent(nil,event)
 end

 local function func(...)
    Exlist.SendFakeEvent("WORLD_MAP_OPEN")
 end

 hooksecurefunc(WorldMapFrame,"Show",func)

function Exlist_PrintUpdates()
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

SLASH_CHARINF1, SLASH_CHARINF2 = '/EXL', '/Exlist'; -- 3.
function SlashCmdList.CHARINF(msg, editbox) -- 4.
  local args = {strsplit(" ",msg)}
  if args[1] == "" then
    OpenConfig()
  elseif args[1] == "refresh" then
    UpdateCharacterSpecifics()
  elseif args[1] == "update" then
    Exlist_PrintUpdates()
  elseif args[1] == "debug" then
    print(debugMode and 'Debug: stopped' or 'Debug: started')
    debugMode = not debugMode
    Exlist.debugMode = debugMode
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

