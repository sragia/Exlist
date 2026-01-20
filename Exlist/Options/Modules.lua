---@class Exlist
local EXL = select(2, ...)

local L = Exlist.L

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

--------------------

---@class EXLOptionsModules
local optionsGeneral = EXL:GetModule('options-modules')

optionsGeneral.useTabs = false
optionsGeneral.useSplitView = false

optionsGeneral.Init = function(self)
  optionsController:RegisterModule(self)
end

optionsGeneral.GetName = function(self)
  return L['Modules']
end

optionsGeneral.GetOrder = function(self)
  return 2
end

optionsGeneral.GetOptions = function(self)
  local settings = Exlist.ConfigDB.settings
  local modules = settings.allowedModules
  local options = {
    {
      type = 'title',
      width = 100,
      label = L['Modules']
    },
    {
      type = 'description',
      width = 100,
      label = L['Enable/Disable modules that you want to use']
    }
  }

  for i, v in pairs(modules) do
    table.insert(options, {
      type = 'toggle',
      width = 100,
      label = v.name,
      currentValue = function()
        return v.enabled
      end,
      onChange = function(value)
        modules[i].enabled = value
      end,
      description = Exlist.ModuleData.modules[i].description or ""
    })
  end


  return options
end
