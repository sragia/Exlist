local name = ...
local CharacterInfo = CharacterInfo
local AceGUI = LibStub("AceGUI-3.0")
local AceConfReg = LibStub("AceConfigRegistry-3.0")
local AceConfDia = LibStub("AceConfigDialog-3.0")
local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")

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


local options = {
    type = "group",
	name = name,
	args = {
        lock = {
			order = 1,
			name = "Lock Icon",
			type = "toggle",
			get = function()
				return CharacterInfo.ConfigDB.settings.lockIcon
			end,
            set = function(info, v)
                CharacterInfo.ConfigDB.settings.lockIcon = v
                CharacterInfo_RefreshAppearance()
			end,
        },
        iconscale = {
			order = 2,
			type = "range",
			name = "Icon Scale",
			min = 0.2,
			max = 2.0,
			step = 0.01,
			bigStep = 0.01,
			width = "normal",
			get = function(info)
				return CharacterInfo.ConfigDB.settings.iconScale or 1
			end,
			set = function(info, v)
				CharacterInfo.ConfigDB.settings.iconScale = v
				CharacterInfo_RefreshAppearance()
			end,
        },
        spacer1 ={
            type = "description",
            name = " ",
            order = 3,
            width = "normal" 
        },
        fonts ={
            type="group",
            name = "Fonts",
            args ={
                font = {
                    type = "select",
                    name = "Font",
                    order = 4,
                    dialogControl = "LSM30_Font",
                    values = AceGUIWidgetLSMlists.font,
                    get = function()
                        return CharacterInfo.ConfigDB.settings.Font
                    end,
                    set = function(info, v)
                        CharacterInfo.ConfigDB.settings.Font = v
                        CharacterInfo_RefreshAppearance()
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
                        return CharacterInfo.ConfigDB.settings.fonts.small.size or 12
                    end,
                    set = function(info, v)
                        CharacterInfo.ConfigDB.settings.fonts.small.size = v
                        CharacterInfo_RefreshAppearance()
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
                        return CharacterInfo.ConfigDB.settings.fonts.medium.size or 12
                    end,
                    set = function(info, v)
                        CharacterInfo.ConfigDB.settings.fonts.medium.size = v
                        CharacterInfo_RefreshAppearance()
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
                        return CharacterInfo.ConfigDB.settings.fonts.big.size or 12
                    end,
                    set = function(info, v)
                        CharacterInfo.ConfigDB.settings.fonts.big.size = v
                        CharacterInfo_RefreshAppearance()
                    end,
                },
            }
        },
        tooltip = {
            type = "group",
            name = "Tooltip",
            args = {
                des = {
                    type = "description",
                    name = " ",
                    order = 1
                },
                tooltipHeight = {
                    type = "range",
                    name = "Tooltip Max Height",
                    width = "full",
                    order = 2,
                    min = 100,
                    max = 2200,
                    step = 10,
                    bigStep = 10,
                    get = function(self)
                        return CharacterInfo.ConfigDB.settings.tooltipHeight or 600
                    end,
                    set = function(self,v)
                        CharacterInfo.ConfigDB.settings.tooltipHeight = v
                    end
                },
                bgColor = {
                    type = "color",
                    name = "Background Color",
                    order = 3,
                    width = "half",
                    hasAlpha = true,
                    get = function(self)
                        local c = CharacterInfo.ConfigDB.settings.backdrop.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(self,r,g,b,a)
                        local c = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        CharacterInfo.ConfigDB.settings.backdrop.color = c
                    end
                },
                borderColor = {
                    type = "color",
                    name = "Border Color",
                    order = 4,
                    width = "half",
                    hasAlpha = true,
                    get = function(self)
                        local c = CharacterInfo.ConfigDB.settings.backdrop.borderColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(self,r,g,b,a)
                        local c = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        CharacterInfo.ConfigDB.settings.backdrop.borderColor = c
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
        }
    }

}
CharacterInfo.SetupConfig = function()
    local modules = CharacterInfo.ConfigDB.settings.allowedModules
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
    local characters = CharacterInfo.ConfigDB.settings.allowedCharacters
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
                CharacterInfo.ConfigDB.settings.reorder = true
            end
        }
        charOptions.args[char.."name"] = t1
        n = n+1
        t1 = {
            type = "input",
            order = n,
            name = "Order",
            width = "half",
            disabled = function() return not characters[char].enabled end,
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
                    CharacterInfo.ConfigDB.settings.reorder = true
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
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name, options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name)
    RegisterAdditionalOptions("Modules",moduleOptions,"Modules")
    RegisterAdditionalOptions("Characters",charOptions,"Characters")
end
CharacterInfo.AddModuleOptions = RegisterAdditionalOptions