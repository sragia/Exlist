---@class Exlist
local EXL = select(2, ...)

local L = Exlist.L

---@class EXFrames
local EXFrames = EXL.EXFrames

---@class EXLOptionsElementsCharacterRow
local optionsElementsCharacterRow = EXL:GetModule('options-elements-character-row')

optionsElementsCharacterRow.pool = nil
optionsElementsCharacterRow.headerPool = nil

optionsElementsCharacterRow.Init = function(self)
  self.pool = CreateFramePool('Frame', UIParent)
  self.headerPool = CreateFramePool('Frame', UIParent)
end

local ConfigureBaseFrame = function(f)
  f:SetHeight(40)

  local bg = f:CreateTexture(nil, 'BACKGROUND')
  bg:SetTexture(EXFrames.assets.textures.window.bg)
  bg:SetAllPoints()
  bg:SetVertexColor(0, 0, 0, 0.8)
  bg:SetTextureSliceMargins(10, 10, 10, 10)
  bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
  f.bg = bg


  local enableCell = CreateFrame('Frame', nil, f)
  enableCell:SetSize(80, 20)
  enableCell:SetPoint('LEFT', 10, 0)
  f.EnableCell = enableCell

  local nameCell = CreateFrame('Frame', nil, f)
  nameCell:SetSize(100, 20)
  nameCell:SetPoint('LEFT', enableCell, 'RIGHT', 5, 0)
  f.NameCell = nameCell

  local realmCell = CreateFrame('Frame', nil, f)
  realmCell:SetSize(100, 20)
  realmCell:SetPoint('LEFT', nameCell, 'RIGHT', 5, 0)
  f.RealmCell = realmCell

  local ilvlCell = CreateFrame('Frame', nil, f)
  ilvlCell:SetSize(100, 20)
  ilvlCell:SetPoint('LEFT', realmCell, 'RIGHT', 5, 0)
  f.IlvlCell = ilvlCell

  local orderCell = CreateFrame('Frame', nil, f)
  orderCell:SetSize(100, 20)
  orderCell:SetPoint('LEFT', ilvlCell, 'RIGHT', 5, 0)
  f.OrderCell = orderCell

  local actionsCell = CreateFrame('Frame', nil, f)
  actionsCell:SetSize(100, 20)
  actionsCell:SetPoint('LEFT', orderCell, 'RIGHT', 5, 0)
  f.ActionsCell = actionsCell


  f.SetFrameWidth = function(self, width)
    self:SetWidth(width)
  end

  f.isConfigured = true
end

local ConfigureHeaderFrame = function(f)
  ConfigureBaseFrame(f)

  local enableHeader = f.EnableCell:CreateFontString(nil, 'OVERLAY')
  enableHeader:SetFont(EXFrames.assets.font.default(), 13, 'OUTLINE')
  enableHeader:SetPoint('LEFT')
  enableHeader:SetText(L['Enable'])

  local nameHeader = f.NameCell:CreateFontString(nil, 'OVERLAY')
  nameHeader:SetFont(EXFrames.assets.font.default(), 13, 'OUTLINE')
  nameHeader:SetPoint('LEFT')
  nameHeader:SetText(L['Name'])

  local realmHeader = f.RealmCell:CreateFontString(nil, 'OVERLAY')
  realmHeader:SetFont(EXFrames.assets.font.default(), 13, 'OUTLINE')
  realmHeader:SetPoint('LEFT')
  realmHeader:SetText(L['Realm'])

  local ilvlHeader = f.IlvlCell:CreateFontString(nil, 'OVERLAY')
  ilvlHeader:SetFont(EXFrames.assets.font.default(), 13, 'OUTLINE')
  ilvlHeader:SetPoint('LEFT')
  ilvlHeader:SetText(L['iLvl'])

  local orderHeader = f.OrderCell:CreateFontString(nil, 'OVERLAY')
  orderHeader:SetFont(EXFrames.assets.font.default(), 13, 'OUTLINE')
  orderHeader:SetPoint('LEFT')
  orderHeader:SetText(L['Order'])

  local actionsHeader = f.ActionsCell:CreateFontString(nil, 'OVERLAY')
  actionsHeader:SetFont(EXFrames.assets.font.default(), 13, 'OUTLINE')
  actionsHeader:SetPoint('RIGHT')
  actionsHeader:SetText(L['Actions'])

  f.SetOptionData = function(self, option)
    self.optionData = option
  end

  f.Destroy = function(self)
    optionsElementsCharacterRow.headerPool:Release(self)
  end
end

local ConfigureCharacterFrame = function(f)
  ConfigureBaseFrame(f)

  local enableInput = EXFrames:GetFrame('checkbox'):Create()
  enableInput:SetParent(f.EnableCell)
  enableInput:SetPoint('LEFT')
  enableInput:SetFrameWidth(30)

  f.EnableInput = enableInput

  local name = f.NameCell:CreateFontString(nil, 'OVERLAY')
  name:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
  name:SetPoint('LEFT')
  name:SetText('')
  f.NameInput = name

  local realm = f.RealmCell:CreateFontString(nil, 'OVERLAY')
  realm:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
  realm:SetPoint('LEFT')
  realm:SetText('')
  f.RealmInput = realm

  local ilvl = f.IlvlCell:CreateFontString(nil, 'OVERLAY')
  ilvl:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
  ilvl:SetPoint('LEFT')
  ilvl:SetText('')
  f.IlvlInput = ilvl

  local orderUp = CreateFrame('Button', nil, f.OrderCell)
  orderUp.isDisabled = false
  orderUp:SetSize(16, 16)
  orderUp:SetPoint('LEFT')
  local orderUpIcon = orderUp:CreateTexture(nil, 'ARTWORK')
  orderUpIcon:SetTexture([[Interface\AddOns\Exlist\Media\Icons\up-arrow]])
  orderUpIcon:SetAllPoints()
  orderUp:SetScript('OnClick', function(self)
    if (self.onClick) then
      self.onClick()
    end
  end)
  orderUp.Icon = orderUpIcon
  orderUp:SetScript('OnEnter', function(self)
    if (self.isDisabled) then
      return
    end
    self.Icon:SetVertexColor(249 / 255, 95 / 255, 9 / 255, 1)
  end)
  orderUp:SetScript('OnLeave', function(self)
    if (self.isDisabled) then
      return
    end
    self.Icon:SetVertexColor(1, 1, 1, 1)
  end)
  f.OrderUp = orderUp

  local orderDown = CreateFrame('Button', nil, f.OrderCell)
  orderDown.isDisabled = false
  orderDown:SetSize(16, 16)
  orderDown:SetPoint('LEFT', orderUp, 'RIGHT', 5, 0)
  local orderDownIcon = orderDown:CreateTexture(nil, 'ARTWORK')
  orderDownIcon:SetTexture([[Interface\AddOns\Exlist\Media\Icons\down-arrow]])
  orderDownIcon:SetAllPoints()
  orderDown:SetScript('OnClick', function(self)
    if (self.isDisabled) then
      return
    end
    if (self.onClick) then
      self.onClick()
    end
  end)
  orderDown.Icon = orderDownIcon
  orderDown:SetScript('OnEnter', function(self)
    if (self.isDisabled) then
      return
    end
    self.Icon:SetVertexColor(249 / 255, 95 / 255, 9 / 255, 1)
  end)
  orderDown:SetScript('OnLeave', function(self)
    if (self.isDisabled) then
      return
    end
    self.Icon:SetVertexColor(1, 1, 1, 1)
  end)
  f.OrderDown = orderDown

  local deleteButton = EXFrames:GetFrame('button'):Create({
    size = { 80, 30 },
    color = { 110 / 255, 4 / 255, 0, 1 },
    text = L['Delete']
  }, f.ActionsCell)
  deleteButton:SetPoint('RIGHT')
  f.DeleteButton = deleteButton


  f.SetOptionData = function(self, option)
    self.optionData = option

    if (option.GetName) then
      f.NameInput:SetText(option.GetName())
    end
    if (option.GetRealm) then
      f.RealmInput:SetText(option.GetRealm())
    end
    if (option.GetIlvl) then
      f.IlvlInput:SetText(option.GetIlvl())
    end

    if (option.onOrderUp) then
      f.OrderUp.onClick = option.onOrderUp
    end
    if (option.onOrderDown) then
      f.OrderDown.onClick = option.onOrderDown
    end
    if (option.onDelete) then
      f.DeleteButton.onClick = option.onDelete
    end
    if (option.IsEnabled) then
      f.EnableInput.onChange = nil
      f.EnableInput:SetValue('value', option.IsEnabled())
    end
    if (option.OnEnableChange) then
      f.EnableInput.onChange = option.OnEnableChange
    end

    if (option.isFirst) then
      f.OrderUp.isDisabled = true
      f.OrderUp:SetAlpha(0.5)
    else
      f.OrderUp.isDisabled = false
      f.OrderUp:SetAlpha(1)
    end

    if (option.isLast) then
      f.OrderDown.isDisabled = true
      f.OrderDown:SetAlpha(0.5)
    else
      f.OrderDown.isDisabled = false
      f.OrderDown:SetAlpha(1)
    end
    if (option.onDelete) then
      f.DeleteButton:SetOnClick(option.onDelete)
    end
  end

  f.Destroy = function(self)
    optionsElementsCharacterRow.pool:Release(self)
  end
end

optionsElementsCharacterRow.Create = function(self)
  local f = self.pool:Acquire()
  if (not f.isConfigured) then
    ConfigureCharacterFrame(f)
  end

  f:Show()
  return f
end

optionsElementsCharacterRow.CreateHeader = function(self)
  local f = self.headerPool:Acquire()
  if (not f.isConfigured) then
    ConfigureHeaderFrame(f)
  end

  f:Show()
  return f
end
