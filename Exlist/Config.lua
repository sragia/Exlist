local name = ...
local Exlist = Exlist
local AceGUI = LibStub("AceGUI-3.0")
local AceConfReg = LibStub("AceConfigRegistry-3.0")
local AceConfDia = LibStub("AceConfigDialog-3.0")
local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
local addonVersion = GetAddOnMetadata(name, "version")
--@debug@
if addonVersion == "@project-version@" then		  
    addonVersion = "Development"		 
end
--@end-debug@
local addingOpt = {}

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

local function RegisterAdditionalOptions(modName, optionTbl, displayName)
	AceConfReg:RegisterOptionsTable(name..modName, optionTbl, true)
	AceConfDia:AddToBlizOptions(name..modName, displayName, name)
end
local function RefreshAdditionalOptions(modName, optionTbl, displayName)
	AceConfReg:RegisterOptionsTable(name..modName, optionTbl, true)
end

local options = {
    type = "group",
	name = name,
	args = {
        logo = {
            order = 0,
            type = "description",
            image = function()
                return [[Interface/Addons/Exlist/Media/Icons/ExlistLogo.tga]],
                150,150
            end,
            name ="",
            width = "normal"
        },
        version ={
            order = 0.1,
            name = "|cfff4bf42Version:|r " .. addonVersion,
            type = "description",
            width = "full"
        },
        author ={
            order = 0.2,
            name = "|cfff4bf42Author:|r Exality - Silvermoon EU\n\n",
            type = "description",
            width = "full"
        },
        general = {
            type="group",
            name = "General",
            order = 1,
            args = {
                lock = {
                    order = 3,
                    name = "Lock Icon",
                    type = "toggle",
                    width = "full",
                    get = function()
                        return Exlist.ConfigDB.settings.lockIcon
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.lockIcon = v
                        Exlist_RefreshAppearance()
                    end,
                },
                iconscale = {
                    order = 1,
                    type = "range",
                    name = "Icon Scale",
                    min = 0.2,
                    max = 2.0,
                    step = 0.01,
                    bigStep = 0.01,
                    width = "normal",
                    get = function(info)
                        return Exlist.ConfigDB.settings.iconScale or 1
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.iconScale = v
                        Exlist_RefreshAppearance()
                    end,
                },
                iconalpha = {
                    order = 2,
                    type = "range",
                    name = "Icon Alpha",
                    min = 0,
                    max = 1,
                    step = 0.05,
                    get = function(self)
                        return Exlist.ConfigDB.settings.iconAlpha or 1
                    end,
                    set = function(self,v)
                        Exlist.ConfigDB.settings.iconAlpha = v
                        Exlist_RefreshAppearance()
                    end,
                },
                announceReset = {
                    order = 4,
                    name = "Announce instance reset",
                    type = "toggle",
                    width = "full",
                    get = function()
                        return Exlist.ConfigDB.settings.announceReset
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.announceReset = v
                        Exlist_RefreshAppearance()
                    end,
                },
                showMinimapIcon = {
                    order = 5,
                    name = "Show Minimap Icon",
                    type = "toggle",
                    width = "full",
                    get = function()
                        return Exlist.ConfigDB.settings.showMinimapIcon
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.showMinimapIcon = v
                        Exlist_RefreshAppearance()
                    end,
                },
                showIcon = {
                    order = 2.9,
                    name = "Show Icon",
                    type = "toggle",
                    width = "full",
                    get = function()
                        return Exlist.ConfigDB.settings.showIcon
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.showIcon = v
                        Exlist_RefreshAppearance()
                    end,
                },             
            }
        },
        fonts ={
            type="group",
            name = "Fonts",
            order = 3,
            args ={
                font = {
                    type = "select",
                    name = "Font",
                    order = 4,
                    dialogControl = "LSM30_Font",
                    values = AceGUIWidgetLSMlists.font,
                    get = function()
                        return Exlist.ConfigDB.settings.Font
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.Font = v
                        Exlist_RefreshAppearance()
                    end
                },
                spacer2 ={
                    type = "description",
                    name = " ",
                    order = 5,
                    width = "double" 
                },
                smallFontSize = {
                    order = 6,
                    type = "range",
                    name = "Info Size",
                    min = 1,
                    max = 50,
                    step = 0.5,
                    bigStep = 1,
                    width = "normal",
                    get = function(info)
                        return Exlist.ConfigDB.settings.fonts.small.size or 12
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.fonts.small.size = v
                        Exlist_RefreshAppearance()
                    end,
                },
                mediumFontSize = {
                    order = 7,
                    type = "range",
                    name = "Character Title Size",
                    min = 1,
                    max = 50,
                    step = 0.5,
                    bigStep = 1,
                    width = "normal",
                    get = function(info)
                        return Exlist.ConfigDB.settings.fonts.medium.size or 12
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.fonts.medium.size = v
                        Exlist_RefreshAppearance()
                    end,
                },
                bigFontSize = {
                    order = 8,
                    type = "range",
                    name = "Extra Info Title Size",
                    min = 1,
                    max = 50,
                    step = 0.5,
                    bigStep = 1,
                    width = "normal",
                    get = function(info)
                        return Exlist.ConfigDB.settings.fonts.big.size or 12
                    end,
                    set = function(info, v)
                        Exlist.ConfigDB.settings.fonts.big.size = v
                        Exlist_RefreshAppearance()
                    end,
                },
            }
        },
        tooltip = {
            type = "group",
            name = "Tooltip",
            order = 2,
            args = {
                des = {
                    type = "description",
                    name = " ",
                    order = 1
                },
                tooltipHeight = {
                    type = "range",
                    name = "Tooltip Max Height",
                    width = "normal",
                    order = 2,
                    min = 100,
                    max = 2200,
                    step = 10,
                    bigStep = 10,
                    get = function(self)
                        return Exlist.ConfigDB.settings.tooltipHeight or 600
                    end,
                    set = function(self,v)
                        Exlist.ConfigDB.settings.tooltipHeight = v
                    end
                },
                tooltipScale = {
                    type = "range",
                    name = "Tooltip Scale",
                    width = "normal",
                    order = 2.1,
                    min = 0.1,
                    max = 1,
                    step = 0.05,
                    get = function(self)
                        return Exlist.ConfigDB.settings.tooltipScale or 1
                    end,
                    set = function(self,v)
                        Exlist.ConfigDB.settings.tooltipScale = v
                    end
                },
                bgColor = {
                    type = "color",
                    name = "Background Color",
                    order = 3,
                    width = "half",
                    hasAlpha = true,
                    get = function(self)
                        local c = Exlist.ConfigDB.settings.backdrop.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(self,r,g,b,a)
                        local c = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        Exlist.ConfigDB.settings.backdrop.color = c
                    end
                },
                borderColor = {
                    type = "color",
                    name = "Border Color",
                    order = 4,
                    width = "half",
                    hasAlpha = true,
                    get = function(self)
                        local c = Exlist.ConfigDB.settings.backdrop.borderColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(self,r,g,b,a)
                        local c = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        Exlist.ConfigDB.settings.backdrop.borderColor = c
                    end
                }
            }
        }
    }
}


local moduleOptions = {
    type = "group",
    name = "Modules",
    args ={
        desc = {
            type = "description",
            order = 1,
            width = "full",
            name = "Enable/Disable modules that you want to use"
        },

    }
}

local charOptions = {
    type = "group",
    name = "Characters",
    args = {
        desc = {
            type = "description",
            order = 1,
            width = "full",
            name = "Enable and set order in which characters are to be displayed (0 shows above 5)"
        },
        orderByIlvl = {
            type = "toggle",
            order = 1.1,
            name = "Order by item level",
            width = "full",
            get = function()
                return Exlist.ConfigDB.settings.orderByIlvl
            end,
            set = function(info,value)
                Exlist.ConfigDB.settings.orderByIlvl = value
                Exlist.ConfigDB.settings.reorder = true
            end
        }

    }

}
Exlist.SetupConfig = function()
    local modules = Exlist.ConfigDB.settings.allowedModules
    local n = 1
    for i,v in pairs(modules) do
        n = n + 1
        local t = {
            type = "toggle",
            order = n,
            width = "normal",
            name = i,
            get = function()
                return modules[i]
            end,
            set = function(info, value) 
                modules[i] = value
            end
        }
        moduleOptions.args[i] = t
    end
    local characters = Exlist.ConfigDB.settings.allowedCharacters
    n = 1
    for char,v in spairs(characters,function(t,a,b) 
        if not t[a].enabled then return false
        elseif not t[b].enabled then return true
        else 
            return t[a].order<t[b].order 
        end     
    end) do
        n = n+1
        local t1 = {
            type = "toggle",
            order = n,
            name = string.format("|c%s%s",v.classClr,char),
            width = "normal",
            get = function()
                return characters[char].enabled
            end,
            set = function(info,value)
                characters[char].enabled = value
                Exlist.ConfigDB.settings.reorder = true
            end
        }
        charOptions.args[char.."name"] = t1
        n = n+1
        t1 = {
            type = "input",
            order = n,
            name = "Order",
            width = "half",
            disabled = function() return not characters[char].enabled or Exlist.ConfigDB.settings.orderByIlvl end,
            get = function()
                if characters[char].enabled then
                    return tostring(characters[char].order or 0)
                else
                    return "Disabled"
                end
            end,
            set = function(info,value)
                value = tonumber(value)
                if value then
                    characters[char].order = value
                    Exlist.ConfigDB.settings.reorder = true
                end
            end,
        }
        charOptions.args[char.."order"] = t1
        --[[n = n + 1
        charOptions.args[char.."filler"] = {
            type = "description",
            order = n,
            name = "",
            width = "normal"
        }]]
    end
    AceConfReg:RegisterOptionsTable(name, options)
    AceConfDia:AddToBlizOptions(name)
    RegisterAdditionalOptions("Modules",moduleOptions,"Modules")
    RegisterAdditionalOptions("Characters",charOptions,"Characters")
    for i=1,#addingOpt do
        addingOpt[i]()
    end
end
Exlist.AddModuleOptions = RegisterAdditionalOptions
Exlist.RefreshModuleOptions = RefreshAdditionalOptions
Exlist.ModuleToBeAdded = function(func)
    table.insert(addingOpt,func)
end