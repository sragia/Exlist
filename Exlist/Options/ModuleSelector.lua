---@class Exlist
local EXL = select(2, ...)

---@class ExalityFrames
local EXFrames = EXL.EXFrames

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

---@class ExalityFramesModuleItem
local moduleItem = EXFrames:GetFrame('module-item')

----------------

---@class EXLOptionsModuleSelector
local optionsModuleSelector = EXL:GetModule('options-module-selector')

optionsModuleSelector.container = nil
optionsModuleSelector.buttons = {}

optionsModuleSelector.Init = function(self)
    EXL.utils.addObserver(self)
    optionsController:Observe('selectedModule', function(value)
        for _, button in pairs(self.buttons) do
            button:SetSelected(button.data:GetName() == value)
        end
    end)
end

optionsModuleSelector.Create = function(self, container)
    self.container = container

    self:Populate()
end

optionsModuleSelector.Populate = function(self)
    local modules = optionsController:GetAllModules()

    for _, module in EXL.utils.spairs(modules, function(t, a, b) return t[a].module:GetOrder() < t[b].module:GetOrder() end) do
        local item = moduleItem:Create({
            onClick = function(self)
                optionsController:SetSelectedModule(self.data:GetName())
            end
        }, self.container)
        item:SetModule(module.module)
        item:SetSelected(module.module:GetName() == optionsController.selectedModule)
        table.insert(self.buttons, item)
    end

    EXL.utils.organizeFramesInList(self.buttons, 5, self.container)
end
