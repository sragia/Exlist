---@class Exlist
local EXL = select(2, ...)

local L = Exlist.L

---@class EXLOptionsController
local optionsController = EXL:GetModule('options-controller')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

--------------------

---@class EXLOptionsGeneral
local optionsGeneral = EXL:GetModule('options-general')

optionsGeneral.useTabs = false
optionsGeneral.useSplitView = true

optionsGeneral.tabsIDs = {
  GENERAL = 'general',
  TOOLTIP = 'tooltip',
  FONTS = 'fonts',
}

optionsGeneral.Init = function(self)
  optionsController:RegisterModule(self)
end

optionsGeneral.GetName = function(self)
  return L['General']
end

optionsGeneral.GetOrder = function(self)
  return 1
end

optionsGeneral.GetSplitViewItems = function(self)
  return {
    {
      label = L['General'],
      ID = optionsGeneral.tabsIDs.GENERAL
    },
    {
      label = L['Tooltip'],
      ID = optionsGeneral.tabsIDs.TOOLTIP
    },
    {
      label = L['Fonts'],
      ID = optionsGeneral.tabsIDs.FONTS
    }
  }
end

optionsGeneral.GetGeneralOptions = function(self)
  return {
    {
      type = 'range',
      label = L['Icon Scale'],
      min = 0.2,
      max = 2,
      step = 0.01,
      width = 20,
      currentValue = function()
        return Exlist.ConfigDB.settings.iconScale or 1
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.iconScale = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'range',
      label = L['Icon Alpha'],
      min = 0,
      max = 1,
      step = 0.05,
      width = 20,
      currentValue = function()
        return Exlist.ConfigDB.settings.iconAlpha or 1
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.iconAlpha = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'spacer',
      width = 60,
    },
    {
      type = 'range',
      label = L['Min Level to track'],
      min = 1,
      max = 100,
      step = 1,
      width = 20,
      currentValue = function()
        return Exlist.ConfigDB.settings.minLevelToTrack or 70
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.minLevelToTrack = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'toggle',
      label = L['Show Icon'],
      width = 100,
      currentValue = function()
        return Exlist.ConfigDB.settings.showIcon
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.showIcon = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'toggle',
      label = L['Lock Icon'],
      width = 100,
      currentValue = function()
        return Exlist.ConfigDB.settings.lockIcon
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.lockIcon = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'toggle',
      label = L['Announce instance reset'],
      width = 100,
      currentValue = function()
        return Exlist.ConfigDB.settings.announceReset
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.announceReset = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'toggle',
      label = L['Show Minimap Icon'],
      width = 100,
      currentValue = function()
        return Exlist.ConfigDB.settings.showMinimapIcon
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.showMinimapIcon = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'toggle',
      label = L['Show Character Totals Tooltip'],
      width = 100,
      currentValue = function()
        return Exlist.ConfigDB.settings.showTotalsTooltip
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.showTotalsTooltip = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'toggle',
      label = L['Show Extra Info Tooltip'],
      width = 100,
      currentValue = function()
        return Exlist.ConfigDB.settings.showExtraInfoTooltip
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.showExtraInfoTooltip = value
        Exlist.RefreshAppearance()
      end
    },
    {
      type = 'toggle',
      label = L['Slim Version'],
      width = 100,
      tooltip = {
        text = L
            ["Slimmed down version of main tooltip i.e. +15 Neltharions Lair -> +15 NL\nMostly affects tooltip in horizontal orientation"]
      },
      currentValue = function()
        return Exlist.ConfigDB.settings.shortenInfo
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.shortenInfo = value
        Exlist.RefreshAppearance()
      end
    },


  }
end

optionsGeneral.GetTooltipOptions = function(self)
  return {
    {
      type = 'dropdown',
      label = L['Tooltip Orientation'],
      getOptions = function()
        return {
          V = L['Vertical'],
          H = L['Horizontal']
        }
      end,
      currentValue = function()
        return Exlist.ConfigDB.settings.horizontalMode and 'H' or 'V'
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.horizontalMode = value == 'H'
      end,
      width = 40,
    },
    {
      type = 'spacer',
      width = 60
    },
    {
      type = 'range',
      label = L['Tooltip Max Height'],
      min = 100,
      max = 2200,
      step = 10,
      currentValue = function()
        return Exlist.ConfigDB.settings.tooltipHeight or 600
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.tooltipHeight = value
      end,
      width = 20,
    },
    {
      type = 'range',
      label = L['Tooltip Scale'],
      min = 0.1,
      max = 1,
      step = 0.05,
      currentValue = function()
        return Exlist.ConfigDB.settings.tooltipScale or 1
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.tooltipScale = value
      end,
      width = 20,
    },
    {
      type = 'spacer',
      width = 60
    },
    {
      type = 'color-picker',
      label = L["Background Color"],
      currentValue = function()
        return Exlist.ConfigDB.settings.backdrop.color
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.backdrop.color = value
      end,
      width = 20
    },
    {
      type = 'color-picker',
      label = L["Border Color"],
      currentValue = function()
        return Exlist.ConfigDB.settings.backdrop.borderColor
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.backdrop.borderColor = value
      end,
      width = 20
    }
  }
end

optionsGeneral.GetFontsOptions = function(self)
  return {
    {
      type = 'dropdown',
      label = L['Font'],
      getOptions = function()
        local fonts = LSM:List('font')
        local options = {}
        for _, font in ipairs(fonts) do
          options[font] = font
        end
        return options
      end,
      currentValue = function()
        return Exlist.ConfigDB.settings.Font
      end,
      isFontDropdown = true,
      onChange = function(value)
        Exlist.ConfigDB.settings.Font = value
        Exlist.RefreshAppearance()
      end,
      width = 40
    },
    {
      type = 'spacer',
      width = 60
    },
    {
      type = 'range',
      label = L['Info Size'],
      min = 1,
      max = 50,
      step = 0.5,
      currentValue = function()
        return Exlist.ConfigDB.settings.fonts.small.size or 12
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.fonts.small.size = value
        Exlist.RefreshAppearance()
      end,
      width = 20
    },
    {
      type = 'range',
      label = L['Character Title Size'],
      min = 1,
      max = 50,
      step = 0.5,
      currentValue = function()
        return Exlist.ConfigDB.settings.fonts.medium.size or 12
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.fonts.medium.size = value
        Exlist.RefreshAppearance()
      end,
      width = 20
    },
    {
      type = 'range',
      label = L['Extra Info Title Size'],
      min = 1,
      max = 50,
      step = 0.5,
      currentValue = function()
        return Exlist.ConfigDB.settings.fonts.big.size or 12
      end,
      onChange = function(value)
        Exlist.ConfigDB.settings.fonts.big.size = value
        Exlist.RefreshAppearance()
      end,
      width = 20
    }
  }
end

optionsGeneral.GetOptions = function(self, _, currItemID)
  if (not currItemID) then
    currItemID = optionsGeneral.tabsIDs.GENERAL
  end

  if (currItemID == optionsGeneral.tabsIDs.GENERAL) then
    return optionsGeneral:GetGeneralOptions()
  elseif (currItemID == optionsGeneral.tabsIDs.TOOLTIP) then
    return optionsGeneral:GetTooltipOptions()
  elseif (currItemID == optionsGeneral.tabsIDs.FONTS) then
    return optionsGeneral:GetFontsOptions()
  end
  return {}
end
