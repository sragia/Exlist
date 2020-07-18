local QTip = LibStub("LibQTip-1.0")
function Exlist.spairs(t, order)
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
        if keys[i] then return keys[i], t[keys[i]] end
    end
end

function Exlist.ClearFunctions(tooltip)
    if tooltip.animations then
        for _, frame in ipairs(tooltip.animations) do
            frame:SetScript("OnUpdate", nil)
            frame.fontString:SetAlpha(1)
        end
    end
end

function Exlist.setIlvlColor(ilvl)
    if not ilvl then return "ffffffff" end
    local colors = Exlist.Colors.ilvlColors
    for i = 1, #colors do
        if colors[i].ilvl > ilvl then return colors[i].str end
    end
    return "fffffb26"
end

function Exlist.GetPosition(frame)
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
    local x, y = frame:GetRect() -- from lower left
    local frameScale = frame:GetScale()
    x = x * frameScale
    y = y * frameScale
    local vPos, xPos
    if x > screenWidth / 2 then
        xPos = "right"
    else
        xPos = "left"
    end
    if y > screenHeight / 2 then
        vPos = "top"
    else
        vPos = "bottom"
    end
    return xPos, vPos
end

function Exlist.ConvertColor(color) return (color / 255) end

function Exlist.ColorHexToDec(hex)
    if not hex or strlen(hex) < 6 then return end
    local values = {}
    for i = 1, 6, 2 do
        table.insert(values, tonumber(string.sub(hex, i, i + 1), 16))
    end
    return (values[1] / 255), (values[2] / 255), (values[3] / 255)
end

function Exlist.ProfessionValueColor(value, isArch)
    local colors = Exlist.Colors.profColors
    local mod = isArch and 8 or 1
    for i = 1, #colors do
        if value <= colors[i].val * mod then return colors[i].color end
    end
    return "FFFFFF"
end

function Exlist.AttachStatusBar(frame)
    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetStatusBarTexture(
        "Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar")
    statusBar:GetStatusBarTexture():SetHorizTile(false)
    local bg = {bgFile = "Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar"}
    statusBar:SetBackdrop(bg)
    statusBar:SetBackdropColor(.1, .1, .1, .8)
    statusBar:SetStatusBarColor(Exlist.ColorHexToDec("ffffff"))
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(0)
    statusBar:SetHeight(5)
    return statusBar
end

-- Animations --
local pulseLowAlpha = 0.4
local pulseDuration = 1.2
local pulseDelta = -(1 - pulseLowAlpha)
function Exlist.AnimPulse(self)
    self.startTime = self.startTime or GetTime()
    local nowTime = GetTime()
    local progress = mod((nowTime - self.startTime), pulseDuration) /
                         pulseDuration
    local angle = (progress * 2 * math.pi) - (math.pi / 2)
    local finalAlpha = 1 + (((math.sin(angle) + 1) / 2) * pulseDelta)
    self.fontString:SetAlpha(finalAlpha)
end

function Exlist.CreateSideTooltip(statusbar)
    -- Creates Side Tooltip function that can be attached to script
    -- statusbar(optional) {} {enabled = true, curr = ##, total = ##, color = 'hex'}
    local settings = Exlist.ConfigDB.settings
    local fonts = Exlist.Fonts
    local function sideTooltip(self, info)
        -- info {} {body = {'1st lane',{'2nd lane', 'side number w/e'}},title = ""}
        local sideTooltip = QTip:Acquire("CharInf_Side", 2, "LEFT", "RIGHT")
        sideTooltip:SetScale(settings.tooltipScale or 1)
        self.sideTooltip = sideTooltip
        sideTooltip:SetHeaderFont(fonts.hugeFont)
        sideTooltip:SetFont(fonts.smallFont)
        sideTooltip:AddHeader(info.title or "")
        local body = info.body
        for i = 1, #body do
            if type(body[i]) == "table" then
                if body[i][3] then
                    if body[i][3][1] == "header" then
                        sideTooltip:SetHeaderFont(fonts.mediumFont)
                        sideTooltip:AddHeader(body[i][1], body[i][2])
                    elseif body[i][3][1] == "separator" then
                        sideTooltip:AddLine(body[i][1], body[i][2])
                        sideTooltip:AddSeparator(1, 1, 1, 1, .8)
                    elseif body[i][3][1] == "headerseparator" then
                        sideTooltip:AddHeader(body[i][1], body[i][2])
                        sideTooltip:AddSeparator(1, 1, 1, 1, .8)
                    end
                else
                    sideTooltip:AddLine(body[i][1], body[i][2])
                end
            else
                sideTooltip:AddLine(body[i])
            end
        end
        local position, vPos = Exlist.GetPosition(
                                   self:GetParent():GetParent():GetParent().parentFrame or
                                       self:GetParent():GetParent():GetParent())
        if position == "left" then
            sideTooltip:SetPoint("TOPLEFT",
                                 self:GetParent():GetParent():GetParent(),
                                 "TOPRIGHT", -1, 0)
        else
            sideTooltip:SetPoint("TOPRIGHT",
                                 self:GetParent():GetParent():GetParent(),
                                 "TOPLEFT", 1, 0)
        end
        sideTooltip:Show()
        sideTooltip:SetClampedToScreen(true)
        local parentFrameLevel = self:GetFrameLevel(self)
        sideTooltip:SetFrameLevel(parentFrameLevel + 5)
        sideTooltip:SetBackdrop(Exlist.DEFAULT_BACKDROP)
        local c = settings.backdrop
        sideTooltip:SetBackdropColor(c.color.r, c.color.g, c.color.b, c.color.a);
        sideTooltip:SetBackdropBorderColor(c.borderColor.r, c.borderColor.g,
                                           c.borderColor.b, c.borderColor.a)
        if statusbar then
            statusbar.total = statusbar.total or 100
            statusbar.curr = statusbar.curr or 0
            local statusBar = CreateFrame("StatusBar", nil, sideTooltip)
            self.statusBar = statusBar
            statusBar:SetStatusBarTexture(
                "Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar")
            statusBar:GetStatusBarTexture():SetHorizTile(false)
            local bg = {
                bgFile = "Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar"
            }
            statusBar:SetBackdrop(bg)
            statusBar:SetBackdropColor(.1, .1, .1, .8)
            statusBar:SetStatusBarColor(Exlist.ColorHexToDec(statusbar.color))
            statusBar:SetMinMaxValues(0, statusbar.total)
            statusBar:SetValue(statusbar.curr)
            statusBar:SetWidth(sideTooltip:GetWidth() - 2)
            statusBar:SetHeight(5)
            statusBar:SetPoint("TOPLEFT", sideTooltip, "BOTTOMLEFT", 1, 0)
        end

    end
    return sideTooltip
end

function Exlist.DisposeSideTooltip()
    -- requires to have saved side tooltip in tooltip.sideTooltip
    -- returns function that can be used for script
    return function(self)
        QTip:Release(self.sideTooltip)
        --  texplore(self)
        if self.statusBar then
            self.statusBar:Hide()
            self.statusBar = nil
        elseif self.sideTooltip and self.sideTooltip.statusBars then
            for i = 1, #self.sideTooltip.statusBars do
                local statusBar = self.sideTooltip.statusBars[i]
                if statusBar then
                    statusBar:Hide()
                    statusBar = nil
                end
            end
        end
        self.sideTooltip = nil
    end
end

function Exlist.MouseOverTooltips()
    for _, tooltip in ipairs(Exlist.activeTooltips or {}) do
        if (tooltip:IsMouseOver()) then return true end
    end
    return false
end

function Exlist.ReleaseActiveTooltips()
    for _, tooltip in ipairs(Exlist.activeTooltips or {}) do
        QTip:Release(tooltip)
    end
    Exlist.activeTooltips = {}
end

function Exlist.SeperateThousands(value)
    if (not value) then return 0 end
    local k
    local formatted = value
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then break end
    end
    return formatted
end

function Exlist.FormatGold(coppers)
    local money = {
        gold = math.floor(coppers / 10000),
        silver = math.floor((coppers / 100) % 100),
        coppers = math.floor(coppers % 100)
    }
    return Exlist.SeperateThousands(money.gold) .. "|cFFd8b21ag|r " ..
               money.silver .. "|cFFadadads|r " .. money.coppers ..
               "|cFF995813c|r"
end
