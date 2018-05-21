local name = ...
local Exlist = Exlist
local AceGUI = LibStub("AceGUI-3.0")
local AceConfReg = LibStub("AceConfigRegistry-3.0")
local AceConfDia = LibStub("AceConfigDialog-3.0")

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


Exlist.SetupConfig = function(refresh)
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
                    showExtraInfo = {
                        order = 6,
                        name = "Show Extra Info Tooltip",
                        type = "toggle",
                        width = "full",
                        get = function()
                            return Exlist.ConfigDB.settings.showExtraInfoTooltip
                        end,
                        set = function(info, v)
                            Exlist.ConfigDB.settings.showExtraInfoTooltip = v
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
                    shortenInfo = {
                        order = 7,
                        name = "Shorten Info",
                        type = "toggle",
                        desc = "Shortens text in main tooltip that you see in tooltip i.e. +15 Neltharions Lair -> +15 NL",
                        width = "full",
                        get = function()
                            return Exlist.ConfigDB.settings.shortenInfo
                        end,
                        set = function(info, v)
                            Exlist.ConfigDB.settings.shortenInfo = v
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
                    tooltipOrientation = {
                        type = "select",
                        order = 1.1,
                        width = "full",
                        name = "Tooltip Orientation",
                        values = {
                            V = "Vertical",
                            H = "Horizontal"
                        },
                        set = function(self,v)
                            Exlist.ConfigDB.settings.horizontalMode = v == "H"
                        end,
                        get = function(self)
    
                            return Exlist.ConfigDB.settings.horizontalMode and "H" or "V"
                        end
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
                        width = "normal",
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
                        width = "normal",
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
            },
            extratooltip = {
            type = "group",
            order = 4,
            name = "Extra Tooltip Info",
            args = {
                description = {
                    type = "description",
                    order = 0,
                    name = "Select data you want to see in Extra tooltip",
                    width = "full",
                }
            },   
            },
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
                    Exlist.SetupConfig(true)
                end
            },
            showCurrentRealm = {
                type = "toggle",
                order = 1.11,
                name = "Only current realm",
                desc = "Show only characters from currently logged in realm in tooltips",
                width = "full",
                get = function()
                    return Exlist.ConfigDB.settings.showCurrentRealm
                end,
                set = function(info,value)
                    Exlist.ConfigDB.settings.showCurrentRealm = value
                end
            },
            spacer0 = {
                type = "description",
                order = 1.19,
                width = 0.2,
                name = ""
            },
            nameLabel = {
                type = "description",
                order = 1.2,
                width = 0.5,
                fontSize = "large",
                name = WrapTextInColorCode("Name","ffffd200")
            },
            realmLabel = {
                type = "description",
                order = 1.3,
                width = 1,
                fontSize = "large",
                name = WrapTextInColorCode("Realm","ffffd200")
            },
            ilvlLabel = {
                type = "description",
                order = 1.4,
                width = 0.5,
                fontSize = "large",
                name = WrapTextInColorCode("Item Level","ffffd200")
            },
            OrderLabel = {
                type = "description",
                order = 1.5,
                width = 1.2,
                fontSize = "large",
                name = WrapTextInColorCode("Order","ffffd200")
            },
    
        }
    
    }
    local settings = Exlist.ConfigDB.settings
    local modules = settings.allowedModules
    local n = 1
    -- Modules
    for i,v in pairs(modules) do
        n = n + 1
        moduleOptions.args[i] = {
            type = "toggle",
            order = n,
            width = 0.7,
            name = WrapTextInColorCode(i,"ffffd200"),
            get = function()
                return modules[i]
            end,
            set = function(info, value) 
                modules[i] = value
            end
        }
        n = n + 1
        moduleOptions.args[i.."desc"] = {
            type = "description",
            order = n,
            width = 2.5,
            name = Exlist.ModuleDesc[i] or ""
        }
    end

    -- Characters
    local characters = settings.allowedCharacters
    n = 1
    for char,v in spairs(characters,function(t,a,b) 
        if not t[a].enabled then return false
        elseif not t[b].enabled then return true
        else 
            if settings.orderByIlvl then
                return t[a].ilvl>t[b].ilvl 
            else
                return t[a].order<t[b].order 
            end
        end     
    end) do
        local charname = v.name
        local realm = char:match("^.*-(.*)")
        n = n+1
        -- ENABLE 
        charOptions.args[char.."enable"] = {
            type = "toggle",
            order = n,
            name = "",
            width = 0.2,
            get = function()
                return characters[char].enabled
            end,
            set = function(info,value)
                characters[char].enabled = value
                Exlist.ConfigDB.settings.reorder = true
                Exlist.SetupConfig(true)
            end
        }

        -- NAME
        n = n+1
        charOptions.args[char.."name"] = {
            type = "description",
            order = n,
            name = string.format("|c%s%s",v.classClr,charname),
            fontSize = "medium",
            width = 0.5,
        }
        -- REALM
        n = n+1
        charOptions.args[char.."realm"] = {
            type = "description",
            order = n,
            name = realm,
            fontSize = "medium",
            width = 1,
        }

        -- ILVL
        n = n+1
        charOptions.args[char.."ilvl"] = {
            type = "description",
            order = n,
            name = string.format("%.1f",v.ilvl or 0),
            fontSize = "medium",
            width = 0.5,
        }
        
        -- ORDER
        n = n+1
        charOptions.args[char.."order"] = {
            type = "input",
            order = n,
            name = "",
            width = 0.4,
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
                    Exlist.SetupConfig(true)
                end
            end,
        }
        -- Spacer
        n = n+1
        charOptions.args[char.."spacer"] = {
            type = "description",
            order = n,
            name =  "",
            width = 0.3,
        }

        -- Delete Data
        n = n+1
        charOptions.args[char.."delete"] = {
            type = "execute",
            order = n,
            name = "Delete",
            width = 0.5,
            func = function()
                StaticPopupDialogs["DeleteDataPopup_"..charname..realm] = {
                    text = "Do you really want to delete all data for "..charname.."-"..realm.."?\n\nType \"DELETE\" into the field to confirm.",
                    button1 = "Ok",
                    button3 = "Cancel",
                    hasEditBox = 1,
                    editBoxWidth = 200,
                    OnShow = function(self)
                      self.editBox:SetText("")
                      self.button1:Disable()
                    end,
                    EditBoxOnTextChanged = function(self)
                        if strupper(self:GetParent().editBox:GetText()) == "DELETE" then
                            self:GetParent().button1:Enable()
                        end
                    end,
                    EditBoxOnEnterPressed = function(self)
                        if strupper(self:GetParent().editBox:GetText()) == "DELETE" then
                            self:GetParent():Hide()
                            Exlist.DeleteCharacterFromDB(charname,realm)
                            Exlist.SetupConfig(true)
                            AceConfReg:NotifyChange(name.."Characters")
                        end
                    end, 
                    OnAccept = function(self)
                      StaticPopup_Hide("DeleteDataPopup_"..charname..realm)
                      Exlist.DeleteCharacterFromDB(charname,realm)
                      Exlist.SetupConfig(true)
                      AceConfReg:NotifyChange(name.."Characters")
                    end,
                    timeout = 0,
                    cancels = "DeleteDataPopup_"..charname..realm,
                    whileDead = true,
                    hideOnEscape = 1,
                    preferredIndex = 4,
                    showAlert = 1,
                    enterClicksFirstButton = 1
                  }
                  StaticPopup_Show("DeleteDataPopup_"..charname..realm)
            end
        }
    
    -- Extra Tooltip Options
    local etargs = options.args.extratooltip.args
    n = 0
    for key,v in pairs(settings.extraInfoToggles) do
        n = n + 1
        etargs[key] = {
            type = "toggle",
            name = v.name,
            order = n,
            width = "full",
            get = function() return v.enabled end,
            set = function(_,value) v.enabled = value end,
        }
    end

    end
    if refresh then
        RefreshAdditionalOptions("Characters",charOptions,"Characters")
        RefreshAdditionalOptions("Modules",moduleOptions,"Modules")
    else
        AceConfReg:RegisterOptionsTable(name, options)
        AceConfDia:AddToBlizOptions(name)
        RegisterAdditionalOptions("Modules",moduleOptions,"Modules")
        RegisterAdditionalOptions("Characters",charOptions,"Characters")
        for i=1,#addingOpt do
            addingOpt[i]()
        end
    end
end
Exlist.AddModuleOptions = RegisterAdditionalOptions
Exlist.RefreshModuleOptions = RefreshAdditionalOptions
Exlist.NotifyOptionsChange = function(module)
  AceConfReg:NotifyChange(name..module)
end
Exlist.ModuleToBeAdded = function(func)
    table.insert(addingOpt,func)
end