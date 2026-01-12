---@class Exlist
local EXL = select(2, ...)

local L = Exlist.L

---@class ExalityFrames
local EXFrames = EXL.EXFrames

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

---@class EXLOptionsFields
local optionsFields = EXL:GetModule('options-fields')

--------------------

---@class EXLOptionsCharacters
local optionsCharacters = EXL:GetModule('options-characters')

optionsCharacters.useTabs = false
optionsCharacters.useSplitView = false

optionsCharacters.dialog = nil

optionsCharacters.Init = function(self)
  optionsController:RegisterModule(self)

  self.dialog = EXFrames:GetFrame('dialog-frame'):Create()
end

optionsCharacters.GetName = function(self)
  return L['Characters']
end

optionsCharacters.GetOrder = function(self)
  return 3
end

optionsCharacters.MoveCharacterOrder = function(self, currentChar, direction)
  local chars = Exlist.ConfigDB.settings.allowedCharacters
  local currentCharData = chars[currentChar]

  -- Only allow reordering enabled characters
  if not currentCharData.enabled then
    return
  end

  -- Don't allow reordering if ordering by item level
  if Exlist.ConfigDB.settings.orderByIlvl then
    return
  end

  local currentOrder = currentCharData.order
  local targetOrder = direction == 'up' and (currentOrder - 1) or (currentOrder + 1)

  -- Prevent moving beyond valid boundaries
  if targetOrder < 0 then
    return
  end

  -- Find the character at the target order position (must be enabled)
  local targetChar = nil
  for charKey, charData in pairs(chars) do
    if charKey ~= currentChar and charData.enabled and charData.order == targetOrder then
      targetChar = charKey
      break
    end
  end

  -- Swap orders if target character found
  if targetChar then
    chars[currentChar].order = targetOrder
    chars[targetChar].order = currentOrder

    -- Refresh options to reflect the changes
    optionsFields:RefreshFields()
    Exlist.ConfigDB.settings.reorder = true
  end
end

optionsCharacters.UpdateCharacterStatus = function(self, currentChar, value)
  local chars = Exlist.ConfigDB.settings.allowedCharacters

  -- First, update enabled status
  chars[currentChar].enabled = value

  -- Collect enabled and disabled characters (excluding current)
  local enabledChars = {}
  local disabledChars = {}

  for charKey, charData in pairs(chars) do
    if charKey ~= currentChar then
      if charData.enabled then
        table.insert(enabledChars, { key = charKey, data = charData })
      else
        table.insert(disabledChars, { key = charKey, data = charData })
      end
    end
  end

  -- Sort by current order to preserve relative positions
  table.sort(enabledChars, function(a, b)
    return a.data.order < b.data.order
  end)
  table.sort(disabledChars, function(a, b)
    return a.data.order < b.data.order
  end)

  -- Reassign orders
  -- Enabled characters get orders 0, 1, 2, ...
  local order = 0
  for i, entry in ipairs(enabledChars) do
    entry.data.order = order
    order = order + 1
  end

  if value then
    -- Character is being enabled: place it at the end of enabled characters
    chars[currentChar].order = order
    order = order + 1

    -- Disabled characters get orders after all enabled (including the one we just enabled)
    for i, entry in ipairs(disabledChars) do
      entry.data.order = order
      order = order + 1
    end
  else
    -- Character is being disabled: place it right after all enabled characters
    -- The current disabled character gets order right after all enabled
    local enabledCount = #enabledChars
    chars[currentChar].order = enabledCount

    -- Other disabled characters get orders after the current disabled one
    -- Current disabled is at position enabledCount, so others start at enabledCount + 1
    for i, entry in ipairs(disabledChars) do
      entry.data.order = enabledCount + i
    end
  end

  -- Refresh options to reflect the changes
  optionsFields:RefreshFields()
  Exlist.ConfigDB.settings.reorder = true
end

optionsCharacters.GetOptions = function(self)
  local settings = Exlist.ConfigDB.settings
  local options = {
    {
      type = 'title',
      width = 100,
      label = L['Characters']
    },
    {
      type = 'description',
      width = 100,
      label = L['Enable and set order in which characters are to be displayed']
    },
    {
      type = 'toggle',
      width = 100,
      label = L['Order by item level'],
      currentValue = function()
        return Exlist.ConfigDB.settings.orderByIlvl
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.orderByIlvl = value
        Exlist.ConfigDB.settings.reorder = true
        optionsFields:RefreshOptions()
      end
    },
    {
      type = 'toggle',
      width = 100,
      label = L['Only current realm'],
      tooltip = {
        text = L["Show only characters from currently logged in realm in tooltips"],
      },
      currentValue = function()
        return Exlist.ConfigDB.settings.showCurrentRealm
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.showCurrentRealm = value
      end
    },

    -- Table Header
    {
      type = 'character-row-header',
      width = 100,
    }
  }

  local characters = Exlist.ConfigDB.settings.allowedCharacters
  -- Collect sorted character keys first to determine last one
  local sortedChars = {}
  for char, v in EXL.utils.spairs(characters, function(t, a, b)
    if (settings.orderByIlvl) then
      return t[a].ilvl > t[b].ilvl
    else
      return characters[a].order < characters[b].order
    end
  end) do
    table.insert(sortedChars, char)
  end

  -- Now iterate through sorted characters
  for i, char in ipairs(sortedChars) do
    local v = characters[char]
    local name = v.name
    local isFirst = (i == 1)
    local isLast = (i == #sortedChars)
    local realm = char:match('^.*-(.*)')
    table.insert(options, {
      type = 'character-row',
      width = 100,
      IsEnabled = function()
        return characters[char].enabled
      end,
      OnEnableChange = function(value)
        optionsCharacters:UpdateCharacterStatus(char, value)
      end,
      GetName = function()
        return string.format('|c%s%s|r', v.classClr, name)
      end,
      GetRealm = function()
        return realm
      end,
      GetIlvl = function()
        return string.format("%.1f", v.ilvl or 0)
      end,
      isLast = isLast or not characters[char].enabled,
      isFirst = isFirst or not characters[char].enabled,
      onOrderUp = function()
        optionsCharacters:MoveCharacterOrder(char, 'up')
      end,
      onOrderDown = function()
        optionsCharacters:MoveCharacterOrder(char, 'down')
      end,
      onDelete = function()
        optionsCharacters.dialog:SetText(string.format(L['Do you really want to delete all data for %s-%s?'], name, realm))
        optionsCharacters.dialog:SetButtons({
          {
            text = L['Delete'],
            onClick = function()
              Exlist.DeleteCharacterFromDB(name, realm)
              optionsCharacters.dialog:HideDialog()
              optionsFields:RefreshFields()
            end,
            color = { 168 / 255, 25 / 255, 0, 1 }
          },
          {
            text = L['Cancel'],
            onClick = function()
              optionsCharacters.dialog:HideDialog()
            end,
            color = { 46 / 255, 46 / 255, 46 / 255, 1 }
          }
        })
        optionsCharacters.dialog:ShowDialog()
      end
    })
  end

  return options
end
