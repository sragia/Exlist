---@class Exlist
local EXL = select(2, ...)

---@class ExalityFrames
local EXFrames = EXL.EXFrames

---@class ExalityFramesPanelFrame
local panel = EXFrames:GetFrame('panel-frame')

---@class EXLOptionsModuleSelector
local optionsModuleSelector = EXL:GetModule('options-module-selector')

---@class EXLOptionsFields
local optionsFields = EXL:GetModule('options-fields')

----------------

---@class EXLOptionsMain
local optionsMain = EXL:GetModule('options-main')

optionsMain.window = nil

optionsMain.CreateWindow = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 1300, 900 },
        title = 'Exlist',
    })

    local modulesPanel = panel:Create()
    modulesPanel:SetParent(window.container)
    modulesPanel:SetPoint('TOPLEFT')
    modulesPanel:SetPoint('BOTTOMRIGHT', window.container, 'BOTTOMLEFT', 200, 0)
    modulesPanel:Show()

    optionsModuleSelector:Create(modulesPanel)

    local configPanel = panel:Create()
    configPanel:SetParent(window.container)
    configPanel:SetPoint('TOPLEFT', modulesPanel, 'TOPRIGHT', 10, 0)
    configPanel:SetPoint('BOTTOMRIGHT')
    configPanel:Show()
    optionsFields:Create(configPanel)

    return window
end

optionsMain.Show = function(self)
    if (not self.window) then
        self.window = self:CreateWindow()
    end
    self.window:ShowWindow()
end
