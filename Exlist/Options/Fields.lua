---@class Exlist
local EXL = select(2, ...)

---@class ExalityFrames
local EXFrames = EXL.EXFrames

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

---@class EXLTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

-------------

---@class EXLOptionsFields
local optionsFields = EXL:GetModule('options-fields')

optionsFields.baseContainer = nil
optionsFields.container = nil
optionsFields.splitView = nil
optionsFields.scrollChild = nil
optionsFields.tabs = nil
optionsFields.currTabID = nil
optionsFields.currItemID = nil
optionsFields.fields = {}

optionsFields.Init = function(self)
    EXL.utils.addObserver(self)

    optionsController:Observe('selectedModule', function(value)
        self:Refresh()
    end)
end

optionsFields.Create = function(self, container)
    self.container = container
    self.baseContainer = container

    self:Refresh()
end

optionsFields.AddSplitView = function(self, module)
    self.splitView = EXFrames:GetFrame('split-options-frame'):Create()
    if (self.tabs) then
        self.splitView:SetParent(self.tabs.container)
        self.splitView:SetAllPoints()
    else
        self.splitView:SetParent(self.baseContainer)
        self.splitView:SetAllPoints()
    end
    self.splitView:UpdateScroll()

    if (module.splitViewExtraButton) then
        self.splitView:AddExtraButton(module.splitViewExtraButton)
    else
        self.splitView:DisableExtraButton()
    end
    local items = module.GetSplitViewItems()
    self.splitView:AddItems(items)
    self.splitView:SetOnItemChange(function(id)
        self.currItemID = id
        self:RefreshFields()
    end)
    if (#items > 0) then
        local found = false
        for _, item in ipairs(items) do
            if (item.ID == self.currItemID) then
                self.splitView:onItemClick(item.ID)
                found = true
                break
            end
        end
        if (not found) then
            self.splitView:onItemClick(items[1].ID)
        end
    end

    self.container = self.splitView.container
end

optionsFields.AddTabs = function(self, module)
    self.tabs = EXFrames:GetFrame('tabs-frame'):Create()
    self.tabs:SetParent(self.baseContainer)
    self.tabs:SetAllPoints()
    self.container = self.tabs.container

    local tabs = module:GetTabs()
    self.tabs:AddTabs(tabs)


    self.tabs:SetOnTabChange(function(id)
        self.currTabID = id
        self:RefreshFields()
    end)

    if (#tabs > 0) then
        local found = false
        for _, tab in ipairs(tabs) do
            if (tab.ID == self.currTabID) then
                self.tabs:onTabClick(tab.ID)
                found = true
                break
            end
        end
        if (not found) then
            self.tabs:onTabClick(tabs[1].ID)
        end
    end
end

optionsFields.AddScrollChild = function(self)
    self.scrollChild = EXFrames:GetFrame('scroll-frame'):Create()
    self.scrollChild:SetParent(self.container)
    self.scrollChild:SetPoint('TOPLEFT', 5, -10)
    self.scrollChild:SetPoint('BOTTOMRIGHT', -30, 10)
    self.scrollChild:UpdateScrollChild(self.container:GetWidth() - 35, self.container:GetHeight() - 20)
    self.container = self.scrollChild.child
end

optionsFields.Refresh = function(self)
    local module = optionsController:GetSelectedModule()

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    for _, module in pairs(optionsController:GetAllModules()) do
        if (module.optionHandler) then
            module.optionHandler(self.container, true)
        end
    end
    if (self.splitView) then
        self.splitView:Destroy()
        self.splitView = nil
    end

    if (self.tabs) then
        self.tabs:Destroy()
        self.tabs = nil
    end

    if (self.scrollChild) then
        self.scrollChild:Destroy()
        self.scrollChild = nil
    end

    self.container = self.baseContainer
    self.fields = {}

    if (module.optionHandler) then
        module.optionHandler(self.container)
        return;
    end
    local currentModule = module.module

    if (currentModule) then
        if (currentModule.useTabs) then
            self:AddTabs(currentModule)
        end

        if (currentModule.useSplitView) then
            self:AddSplitView(currentModule)
        end

        if (not currentModule.useTabs and not currentModule.useSplitView) then
            self:AddScrollChild()
        end
    end

    self:RefreshFields()
end

optionsFields.RefreshOptions = function(self)
    C_Timer.After(0.3, function()
        self:RefreshFields()
    end)
end

optionsFields.CreateOrUpdateTooltip = function(self, field, tooltipInfo)
    if (not field.Tooltip and tooltipInfo) then
        local tooltip = tooltip:Get({
            text = tooltipInfo.text,
        }, field)
        field.Tooltip = tooltip
        field.isTooltipEnabled = true

        field.OriginalOnEnter = field:GetScript('OnEnter')
        field.OriginalOnLeave = field:GetScript('OnLeave')

        field:SetScript('OnEnter', function(self, ...)
            if (self.isTooltipEnabled) then
                self.Tooltip:ShowTooltip()
            end
            if (self.OriginalOnEnter) then
                self.OriginalOnEnter(self, ...)
            end
        end)
        field:SetScript('OnLeave', function(self, ...)
            if (self.isTooltipEnabled) then
                self.Tooltip:HideTooltip()
            end
            if (self.OriginalOnLeave) then
                self.OriginalOnLeave(self, ...)
            end
        end)
    end

    if (tooltipInfo and tooltipInfo.text and tooltipInfo.text ~= '') then
        field.Tooltip:SetText(tooltipInfo.text)
        field.isTooltipEnabled = true
    else
        field.isTooltipEnabled = false
    end
end

optionsFields.RefreshFields = function(self)
    local module = optionsController:GetSelectedModule()
    local currentModule = module.module

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    self.fields = {}

    local fields = currentModule:GetOptions(self.currTabID, self.currItemID)
    for _, field in ipairs(fields) do
        if (type(field) == 'function') then
            local funcFields = field()
            if (funcFields) then
                for _, funcField in ipairs(funcFields) do
                    local fieldFrame = self:GetField(funcField)
                    self:CreateOrUpdateTooltip(fieldFrame, funcField.tooltip)
                    if (fieldFrame) then
                        fieldFrame:SetOptionData(funcField)
                        fieldFrame:SetParent(self.container)
                        table.insert(self.fields, fieldFrame)
                    end
                end
            end
        elseif (not field.depends or field.depends()) then
            local fieldFrame = self:GetField(field)
            self:CreateOrUpdateTooltip(fieldFrame, field.tooltip)
            if (fieldFrame) then
                fieldFrame:SetOptionData(field)
                fieldFrame:SetParent(self.container)
                table.insert(self.fields, fieldFrame)
            end
        end
    end

    EXL.utils.organizeFramesInGrid('fields', self.fields, 10, self.container, 10, 10)
end

optionsFields.RefreshItemList = function(self)
    local module = optionsController:GetSelectedModule()
    local items = module.module:GetSplitViewItems()
    self.splitView:AddItems(items)
end

optionsFields.SetItemID = function(self, itemID)
    if (self.splitView) then
        self.splitView:onItemClick(itemID)
    end
end

optionsFields.GetField = function(self, field)
    return EXL.utils.switch(field.type, {
        ['editbox'] = function()
            local f = EXFrames:GetFrame('edit-box-input'):Create({
                label = 'Edit Box',
                onChange = field.onChange,
                initial = field.currentValue and field.currentValue() or nil,
            })
            f:SetHeight(40)
            return f
        end,
        ['range'] = function()
            local f = EXFrames:GetFrame('range-input'):Create()
            f:SetOnChange(field.onChange)
            return f
        end,
        ['button'] = function()
            local f = EXFrames:GetFrame('button'):Create()
            return f
        end,
        ['toggle'] = function()
            local f = EXFrames:GetFrame('toggle'):Create({
                text = field.label,
                value = field.currentValue and field.currentValue() or false,
            })
            return f
        end,
        ['dropdown'] = function()
            local f = EXFrames:GetFrame('dropdown'):Create({})
            return f
        end,
        ['spacer'] = function()
            local f = EXFrames:GetFrame('spacer'):Create()
            return f
        end,
        ['color-picker'] = function()
            local f = EXFrames:GetFrame('color-picker'):Create()
            return f
        end,
        ['title'] = function()
            local f = EXFrames:GetFrame('title'):Create()
            return f
        end,
        ['description'] = function()
            local f = EXFrames:GetFrame('description'):Create()
            return f
        end,
        ['edit-box'] = function()
            local f = EXFrames:GetFrame('edit-box-input'):Create({})
            f:SetHeight(40)
            return f
        end,
        ['checkbox'] = function()
            local f = EXFrames:GetFrame('checkbox'):Create()
            return f
        end,
        ['character-row'] = function()
            local f = EXL:GetModule('options-elements-character-row'):Create()
            return f
        end,
        ['character-row-header'] = function()
            local f = EXL:GetModule('options-elements-character-row'):CreateHeader()
            return f
        end,
        default = function()
            EXL.utils.printOut('Unknown Field Type: ' .. field.type)
        end
    })
end
