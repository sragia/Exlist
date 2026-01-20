---@class Exlist
local EXL = select(2, ...)

---------

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

optionsController.modules = {}
optionsController.selectedModule = 'General'

optionsController.Init = function(self)
    EXL.utils.addObserver(self)
end

optionsController.GetSelectedModule = function(self)
    return self.modules[self.selectedModule]
end

optionsController.GetSelectedModuleName = function(self)
    return self.selectedModule
end

optionsController.SetSelectedModule = function(self, moduleName)
    self:SetValue('selectedModule', moduleName)
end

optionsController.RegisterModule = function(self, module, optionHandler)
    self.modules[module:GetName()] = {
        module = module,
        optionHandler = optionHandler
    }
end

optionsController.GetAllModules = function(self)
    return self.modules
end
