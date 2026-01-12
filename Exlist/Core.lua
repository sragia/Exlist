local addonName = ...
---@class Exlist
local EXL = select(2, ...)

local initIndx = 0

EXL.modules = {}

---Get and Initialize a module
---@param self Exlist
---@param id any
---@return unknown
EXL.GetModule = function(self, id)
  if (not self.modules[id]) then
    initIndx = initIndx + 1
    self.modules[id] = {
      _index = initIndx
    }
  end

  return self.modules[id]
end

EXL.InitModules = function(self)
  for _, module in EXL.utils.spairs(self.modules, function(t, a, b) return t[a]._index < t[b]._index end) do
    if (module.Init) then
      module:Init()
    end
  end
end


EXL.handler = CreateFrame('Frame')
EXL.handler:RegisterEvent('ADDON_LOADED')
EXL.handler:RegisterEvent('PLAYER_LOGOUT')

EXL.handler.eventHandlers = {
  --[[
  [event] = {
      [id] = function(event, ...)
  }
  ]]
}

---Register a new event handler
---@param self Exlist
---@param event string | string[]
---@param id any
---@param func function
EXL.RegisterEventHandler = function(self, event, id, func)
  if (type(event) ~= 'table') then
    event = { event }
  end

  for _, event in ipairs(event) do
    if (not self.handler.eventHandlers[event]) then
      self.handler:RegisterEvent(event)
    end
    self.handler.eventHandlers[event] = self.handler.eventHandlers[event] or {}
    self.handler.eventHandlers[event][id] = func
  end
end

EXL.UnregisterEventHandler = function(self, event, id)
  self.handler.eventHandlers[event] = self.handler.eventHandlers[event] or {}
  self.handler.eventHandlers[event][id] = nil
  if (not next(self.handler.eventHandlers[event])) then
    self.handler:UnregisterEvent(event)
  end
end

EXL.handler:SetScript('OnEvent', function(self, event, ...)
  if (event == 'ADDON_LOADED' and ... == addonName) then
    EXL:InitModules()
  end

  if (self.eventHandlers[event]) then
    for id, func in pairs(self.eventHandlers[event]) do
      func(event, ...)
    end
  end
end)

--- Callbacks
--[[
    {
        events = { 'event1', 'event2' },
        func = function(event, ...)
    }
]]
EXL.callbacks = {}

EXL.RegisterCallback = function(self, config)
  table.insert(EXL.callbacks, config)
end

EXL.Callback = function(self, event, ...)
  for _, callback in ipairs(self.callbacks) do
    if (FindInTable(callback.events, event)) then
      callback.func(event, ...)
    end
  end
end
