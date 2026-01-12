---@class Exlist
local EXL = select(2, ...)

local QTip = LibStub("LibQTip-1.0")
function Exlist.spairs(t, order)
   -- collect the keys
   local keys = {}
   for k in pairs(t) do
      keys[#keys + 1] = k
   end

   -- if order function given, sort by it by passing the table and keys a, b,
   -- otherwise just sort the keys
   if order then
      table.sort(
         keys,
         function(a, b)
            return order(t, a, b)
         end
      )
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

local function AddMissingTableEntries(data, DEFAULT, forceKeys)
   if not data or not DEFAULT then
      return data
   end
   local rv = data
   for k, v in pairs(DEFAULT) do
      if (forceKeys and tContains(forceKeys, k)) then
         rv[k] = v
      elseif rv[k] == nil then
         rv[k] = v
      elseif type(v) == "table" then
         if type(rv[k]) == "table" then
            rv[k] = AddMissingTableEntries(rv[k], v, forceKeys)
         else
            rv[k] = AddMissingTableEntries({}, v, forceKeys)
         end
      end
   end
   return rv
end
Exlist.AddMissingTableEntries = AddMissingTableEntries

function Exlist.ClearFunctions(tooltip)
   if tooltip.animations then
      for _, frame in ipairs(tooltip.animations) do
         frame:SetScript("OnUpdate", nil)
         frame.fontString:SetAlpha(1)
      end
   end
end

function Exlist.setIlvlColor(ilvl)
   if not ilvl then
      return "ffffffff"
   end
   local colors = Exlist.Colors.ilvlColors
   for i = 1, #colors do
      if colors[i].ilvl > ilvl then
         return colors[i].str
      end
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

function Exlist.ConvertColor(color)
   return (color / 255)
end

function Exlist.ColorHexToDec(hex)
   if not hex or strlen(hex) < 6 then
      return
   end
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
      if value <= colors[i].val * mod then
         return colors[i].color
      end
   end
   return "FFFFFF"
end

function Exlist.AttachStatusBar(frame)
   local statusBar = CreateFrame("StatusBar", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
   statusBar:SetStatusBarTexture("Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar")
   statusBar:GetStatusBarTexture():SetHorizTile(false)
   local bg = { bgFile = "Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar" }
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
   local progress = mod((nowTime - self.startTime), pulseDuration) / pulseDuration
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
      local position, vPos =
          Exlist.GetPosition(
             self:GetParent():GetParent():GetParent().parentFrame or self:GetParent():GetParent():GetParent()
          )
      if position == "left" then
         sideTooltip:SetPoint("TOPLEFT", self:GetParent():GetParent():GetParent(), "TOPRIGHT", -1, 0)
      else
         sideTooltip:SetPoint("TOPRIGHT", self:GetParent():GetParent():GetParent(), "TOPLEFT", 1, 0)
      end
      sideTooltip:Show()
      sideTooltip:SetClampedToScreen(true)
      local parentFrameLevel = self:GetFrameLevel(self)
      sideTooltip:SetFrameLevel(parentFrameLevel + 5)

      Mixin(sideTooltip.NineSlice, BackdropTemplateMixin)
      SharedTooltip_SetBackdropStyle(sideTooltip, nil, sideTooltip.IsEmbedded)
      sideTooltip.NineSlice:SetScript("OnSizeChanged", sideTooltip.NineSlice.OnBackdropSizeChanged)
      sideTooltip.NineSlice:SetBackdrop(Exlist.DEFAULT_BACKDROP)
      local c = settings.backdrop
      sideTooltip.NineSlice:SetCenterColor(c.color.r, c.color.g, c.color.b, c.color.a)
      sideTooltip.NineSlice:SetBorderColor(c.borderColor.r, c.borderColor.g, c.borderColor.b, c.borderColor.a)
      if statusbar then
         statusbar.total = statusbar.total or 100
         statusbar.curr = statusbar.curr or 0
         local statusBar = CreateFrame("StatusBar", nil, sideTooltip, BackdropTemplateMixin and "BackdropTemplate")
         self.statusBar = statusBar
         statusBar:SetStatusBarTexture("Interface\\AddOns\\Exlist\\Media\\Texture\\statusBar")
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
      if (tooltip:IsMouseOver()) then
         return true
      end
   end
   return false
end

function Exlist.ReleaseActiveTooltips()
   for _, tooltip in ipairs(Exlist.activeTooltips or {}) do
      Exlist.ClearFunctions(tooltip)
      QTip:Release(tooltip)
   end
   Exlist.activeTooltips = {}
end

function Exlist.SeperateThousands(value)
   if (not value) then
      return 0
   end
   local k
   local formatted = value
   while true do
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
      if (k == 0) then
         break
      end
   end
   return formatted
end

function Exlist.FormatGold(coppers)
   local money = {
      gold = math.floor(coppers / 10000),
      silver = math.floor((coppers / 100) % 100),
      coppers = math.floor(coppers % 100)
   }
   return Exlist.SeperateThousands(money.gold) ..
       "|cFFd8b21ag|r " .. money.silver .. "|cFFadadads|r " .. money.coppers .. "|cFF995813c|r"
end

local randCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

function Exlist.GenerateRandomString(length)
   length = length or 10
   local output = ""
   for i = 1, length do
      local rand = math.random(#randCharSet)
      output = output .. string.sub(randCharSet, rand, rand)
   end
   return output
end

function Exlist.Switch(condition, cases)
   return (cases[condition] or cases.default)()
end

local function isArray(table)
   if type(table) ~= "table" then
      return false
   end

   local tableNum = 0
   local arrayNum = #table

   for _ in pairs(table) do
      tableNum = tableNum + 1
   end

   return tableNum == arrayNum
end

local function copyTableInternal(source, seen)
   if type(source) ~= "table" then
      return source
   end
   if seen[source] then
      return seen[source]
   end
   local rv = {}
   seen[source] = rv
   for k, v in pairs(source) do
      rv[copyTableInternal(k, seen)] = copyTableInternal(v, seen)
   end
   return rv
end

function Exlist.copyTable(source)
   return copyTableInternal(source, {})
end

local function tableMerge(t1, t2, rewriteArrays)
   for k, v in pairs(t2) do
      if type(v) == "table" then
         if type(t1[k] or false) == "table" then
            if (rewriteArrays and isArray(t2[k])) then
               t1[k] = v
            else
               tableMerge(t1[k] or {}, t2[k] or {}, rewriteArrays)
            end
         else
            t1[k] = v
         end
      else
         t1[k] = v
      end
   end
   return t1
end
Exlist.tableMerge = tableMerge

local function diffTable(t1, t2, result, ignoreArrays)
   for k, v in pairs(t2) do
      local t1Type = type(t1[k])
      local t2Type = type(t2[k])
      if (t1Type ~= t2Type) then
         result[k] = t2[k]
      elseif (t1Type == "table") then
         if (ignoreArrays and isArray(t1[k])) then
            result[k] = t2[k]
         else
            result[k] = diffTable(t1[k], t2[k], {}, ignoreArrays)
         end
      elseif (t1[k] ~= t2[k]) then
         result[k] = t2[k]
      end
   end

   return result
end

local function removeEmptyTable(t)
   if (type(t) ~= "table") then
      return t
   end
   local i = 0
   for k, v in pairs(t) do
      if (type(v) == "table") then
         t[k] = removeEmptyTable(v)
         if (t[k]) then
            i = i + 1
         end
      else
         i = i + 1
      end
   end
   if (i > 0) then
      return t
   else
      return nil
   end
end

function Exlist.diffTable(t1, t2, ignoreArrays)
   local diff = diffTable(t1, t2, {}, ignoreArrays)
   return removeEmptyTable(diff)
end

function Exlist.Fade(f, duration, from, to)
   local ag = f:CreateAnimationGroup()
   local fade = ag:CreateAnimation("Alpha")
   fade:SetFromAlpha(from or 0)
   fade:SetToAlpha(to or 1)
   fade:SetDuration(duration or 1)
   fade:SetSmoothing((from > to) and "OUT" or "IN")
   ag:SetScript(
      "OnFinished",
      function()
         f:SetAlpha(to)
      end
   )
   return ag
end

function Exlist.AttachText(f, font, size, outline)
   local textFrame = CreateFrame("Frame", nil, f)
   local fs = textFrame:CreateFontString(nil, "OVERLAY")
   textFrame.text = fs
   textFrame:SetWidth(0)
   textFrame.SetText = function(self, text)
      self.text:SetText(text)
   end
   textFrame.SetFont = function(self, font, size, outline)
      self.text:SetFont(font, size, outline)
   end
   fs:SetFont(font, size, outline or "OUTLINE")
   fs:SetPoint("CENTER")
   textFrame:SetSize(1, 1)

   return textFrame
end

function Exlist.ShortenNumber(number)
   if type(number) ~= "number" then
      number = tonumber(number)
   end
   if not number then
      return
   end
   local affixes = { "", "k", "m", "b", "t" }
   local affix = 1
   local dec = 0
   local num1 = math.abs(number)
   while num1 >= 1000 and affix < #affixes do
      num1 = num1 / 1000
      affix = affix + 1
   end
   if affix > 1 then
      dec = 2
      local num2 = num1
      while num2 >= 10 and dec > 0 do
         num2 = num2 / 10
         dec = dec - 1
      end
   end
   if number < 0 then
      num1 = -num1
   end

   return string.format("%." .. dec .. "f" .. affixes[affix], num1)
end

function Exlist.GetSettings(key)
   return Exlist.ConfigDB.settings[key] or {}
end

local statusMarks = {
   [true] = [[Interface/Addons/Exlist/Media/Icons/ok-icon]],
   [false] = [[Interface/Addons/Exlist/Media/Icons/cancel-icon]]
}

function Exlist.AddCheckmark(text, status)
   return string.format("|T%s:0|t %s", statusMarks[status], text)
end

function Exlist.GetMythicPlusLevelColor(level)
   for _, color in ipairs(Exlist.Colors.mythicplus.level) do
      if (color.level <= level) then
         return color.color
      end
   end
end

local rowFramePool = CreateFramePool('Frame', UIParent)
local rowFrames = {}

local function CreateRowFrame(parent)
   local frame = rowFramePool:Acquire()
   frame.Destroy = function(self)
      rowFramePool:Release(self)
   end
   frame:SetParent(parent)

   return frame
end

EXL.utils = {
   isEmpty = function(t)
      for _ in pairs(t) do
         return false
      end
      return true
   end,
   spairs = function(t, order)
      -- collect the keys
      local keys = {}
      for k in pairs(t) do
         keys[#keys + 1] = k
      end

      -- if order function given, sort by it by passing the table and keys a, b,
      -- otherwise just sort the keys
      if order then
         table.sort(
            keys,
            function(a, b)
               return order(t, a, b)
            end
         )
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
   end,
   getKeys = function(t)
      local keys = {}
      for k in pairs(t) do
         keys[#keys + 1] = k
      end
      return keys
   end,
   degToRad = function(degrees)
      return degrees * math.pi / 180
   end,
   animation = {
      getAnimationGroup = function(f)
         return f:CreateAnimationGroup();
      end,
      fade = function(f, duration, from, to, ag)
         ag = ag or f:CreateAnimationGroup()
         local fade = ag:CreateAnimation('Alpha')
         fade:SetFromAlpha(from or 0)
         fade:SetToAlpha(to or 1)
         fade:SetDuration(duration or 1)
         fade:SetSmoothing((from > to) and 'OUT' or 'IN')
         local finishScript = ag:GetScript('OnFinished')
         ag:SetScript(
            'OnFinished',
            function(...)
               if (finishScript) then finishScript(...) end
               f:SetAlpha(to)
            end
         )
         return ag
      end,
      diveIn = function(f, duration, xOff, yOff, smoothing, ag)
         ag = ag or f:CreateAnimationGroup()
         local translate = ag:CreateAnimation('Translation')
         translate:SetOffset(xOff, -yOff)
         translate:SetDuration(duration)
         translate:SetSmoothing(smoothing)
         ag:SetScript('OnPlay', function()
            if (smoothing == 'OUT') then
               return
            end

            for i = 1, f:GetNumPoints() do
               local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
               f:SetPoint(point, relativeTo, relativePoint, xOfs + xOff, yOfs + yOff)
            end
         end)
         local finishScript = ag:GetScript('OnFinished')
         ag:SetScript('OnFinished', function(...)
            if (finishScript) then finishScript(...) end

            if (smoothing == 'OUT') then
               return
            end

            for i = 1, f:GetNumPoints() do
               local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
               f:SetPoint(point, relativeTo, relativePoint, xOfs - xOff, yOfs - yOff)
            end
         end)

         return ag
      end,
      move = function(f, duration, xOff, yOff, ag)
         ag = ag or f:CreateAnimationGroup()
         local translate = ag:CreateAnimation('Translation')
         translate:SetOffset(xOff, yOff)
         translate:SetDuration(duration)
         local finishScript = ag:GetScript('OnFinished')
         ag:SetScript('OnFinished', function(...)
            if (finishScript) then finishScript(...) end

            for i = 1, f:GetNumPoints() do
               local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
               f:SetPoint(point, relativeTo, relativePoint, xOfs + xOff, yOfs + yOff)
            end
         end)

         return ag
      end
   },
   addObserver = function(t, force)
      if (t.observable and not force) then
         return t
      end

      t.observable = {}
      t.Observe = function(_, key, onChangeFunc)
         if (type(key) == 'table') then
            for _, k in ipairs(key) do
               t.observable[k] = t.observable[k] or {}
               table.insert(t.observable[k], onChangeFunc)
            end
         else
            t.observable[key] = t.observable[key] or {}
            table.insert(t.observable[key], onChangeFunc)
         end
      end
      t.SetValue = function(self, key, value)
         local oldValue = t[key]
         t[key] = value
         if (t.observable[key]) then
            for _, func in ipairs(t.observable[key]) do
               func(value, oldValue, key, self)
            end
         end
         if (t.observable['']) then
            for _, func in ipairs(t.observable['']) do
               func(value, oldValue, key, self)
            end
         end
      end
      t.ObserveAll = function(_, onChangeFunc)
         t.observable[''] = t.observable[''] or {}
         table.insert(t.observable[''], onChangeFunc)
      end

      t.ClearObservable = function(self)
         self.observable = {}
      end

      return t
   end,
   printOut = function(outputString)
      print("|cffc334eb[Exlist]|r " .. outputString)
   end,
   debugWithDevTools = function(data)
      C_Timer.After(1, function()
         if (not DevTool) then
            print('DEBUG no devtool')
            return
         end
         if (DevTool.AddData) then
            DevTool:AddData(data)
         elseif (DevTool_AddData) then
            DevTool_AddData(data)
         else
            print('Devtool Available but no AddData function')
         end
      end)
   end,
   suggestMatch = function(userInput, source)
      local suggestions = {}
      for _, data in pairs(source) do
         local matchinString = (data.id or '')
         local matchStart, matchEnd = string.find(string.lower(matchinString), string.lower(userInput), 1, true)
         if matchStart ~= nil then
            table.insert(suggestions,
               {
                  str = matchinString,
                  score = matchEnd - matchStart + 1 + (matchStart - 1) / #matchinString,
                  data = data
               })
         else
            local words = {}
            for word in string.gmatch(string.lower(userInput), '%S+') do
               table.insert(words, word)
            end
            local pattern = ''
            for j = 1, #words do
               pattern = pattern .. words[j] .. '%S*'
            end
            local phraseStart, phraseEnd = string.find(string.lower(matchinString), pattern, 1, true)
            if phraseStart ~= nil then
               table.insert(suggestions, {
                  str = matchinString,
                  score = phraseEnd - phraseStart + 1 +
                      (phraseStart - 1) / #matchinString,
                  data = data
               })
            end
         end
      end
      table.sort(suggestions, function(a, b) return a.score < b.score end)
      return suggestions
   end,
   switch = function(condition, cases)
      return (cases[condition] or cases.default)()
   end,
   generateRandomString = function(length)
      length = length or 10
      local output = ""
      for i = 1, length do
         local rand = math.random(#randCharSet)
         output = output .. string.sub(randCharSet, rand, rand)
      end
      return output
   end,
   arrayIndexForvalue = function(arr, value)
      for index, val in ipairs(arr) do
         if val == value then
            return index + 1
         end
      end
      return nil
   end,
   organizeFramesInList = function(children, gap, parentContainer)
      local prev = nil

      for _, child in ipairs_reverse(children) do
         child:ClearAllPoints()
      end

      for indx, child in ipairs(children) do
         if (not prev) then
            child:SetPoint('TOPLEFT', parentContainer, 'TOPLEFT', 0, -gap)
            child:SetPoint('TOPRIGHT', parentContainer, 'TOPRIGHT', 0, -gap)
         else
            child:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -gap)
            child:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, -gap)
         end
         child:Show()
         prev = child
      end
   end,
   organizeFramesInGrid = function(gridId, children, gap, parentContainer, startOffsetX, startOffsetY)
      local maxWidth = parentContainer:GetWidth() - startOffsetX * 2

      if (rowFrames[gridId]) then
         for _, frame in ipairs(rowFrames[gridId]) do
            frame:Destroy()
         end
         rowFrames[gridId] = {}
      else
         rowFrames[gridId] = {}
      end
      for _, child in ipairs_reverse(children) do
         child:ClearAllPoints()
      end

      local rows = { {} }
      local runningPerc = 100
      for _, child in ipairs(children) do
         local childPerc = child.optionData and child.optionData.width or 25
         if ((runningPerc - childPerc) < 0) then
            table.insert(rows, { child })
            runningPerc = 100 - childPerc
         else
            table.insert(rows[#rows], child)
            runningPerc = runningPerc - childPerc
         end
      end
      local prevRowFrame = nil

      for _, row in ipairs(rows) do
         local rowFrame = CreateRowFrame(parentContainer)
         table.insert(rowFrames[gridId], rowFrame)
         if (prevRowFrame) then
            rowFrame:SetPoint('TOPLEFT', prevRowFrame, 'BOTTOMLEFT', 0, -gap)
            rowFrame:SetPoint('TOPRIGHT', prevRowFrame, 'BOTTOMRIGHT', 0, -gap)
         else
            rowFrame:SetPoint('TOPLEFT', startOffsetX, -startOffsetY)
            rowFrame:SetPoint('TOPRIGHT', -startOffsetX, -startOffsetY)
         end
         local rowFrames = #row
         local rowMaxWidth = maxWidth - (rowFrames * gap)
         local rowMaxHeight = 0
         local prev = nil
         for _, child in ipairs(row) do
            child:SetParent(rowFrame)
            local perc = child.optionData and child.optionData.width or 25
            child:SetFrameWidth(perc / 100 * rowMaxWidth)
            if (prev) then
               child:SetPoint('TOPLEFT', prev, 'TOPRIGHT', gap, 0)
            else
               child:SetPoint('TOPLEFT', rowFrame, 'TOPLEFT', 0, 0)
            end
            local childHeight = child:GetHeight()
            if (childHeight > rowMaxHeight) then
               rowMaxHeight = childHeight
            end
            prev = child
         end

         -- center child in row vertically
         local prevPad = 0
         for _, child in ipairs(row) do
            local childHeight = child:GetHeight()
            local topPad = (rowMaxHeight - childHeight) / 2
            if (prevPad > 0) then
               topPad = topPad - prevPad
            end
            prevPad = topPad
            local point, relativeTo, relativePoint, xOfs, yOfs = child:GetPoint(1)
            child:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - topPad)
         end
         rowFrame:SetHeight(rowMaxHeight)
         rowFrame:Show()
         prevRowFrame = rowFrame
      end
   end,
   getJustifyHFromAnchor = function(anchor)
      if (string.find(anchor, 'LEFT')) then
         return 'LEFT'
      elseif (string.find(anchor, 'RIGHT')) then
         return 'RIGHT'
      elseif (string.find(anchor, 'CENTER')) then
         return 'CENTER'
      end
      return 'LEFT'
   end,
   capitalize = function(str)
      return str:gsub('^%l', string.upper)
   end,
   combineArrays = function(...)
      local output = {}
      for _, array in ipairs(...) do
         tAppendAll(output, array)
      end
      return output
   end,
   getTexCoords = function(width, height, zoom)
      zoom = zoom or 0
      local zoomReduction = (zoom / 100) / 2
      if (width > height) then
         local ratio = 1 - (height / width)
         return 0 + zoomReduction, 1 - zoomReduction, 0 + zoomReduction + ratio / 2, 1 - zoomReduction - ratio / 2
      else
         local ratio = 1 - (width / height)
         return 0 + zoomReduction + ratio / 2, 1 - zoomReduction - ratio / 2, 0 + zoomReduction, 1 - zoomReduction
      end
   end,
   formatTime = function(seconds, excludeSeconds)
      local hours = math.floor(seconds / 3600)
      local minutes = math.floor((seconds % 3600) / 60)
      local seconds = seconds % 60
      if (hours > 0) then
         if (excludeSeconds) then
            return string.format('%dh %dm', hours, minutes)
         else
            return string.format('%dh %dm %ds', hours, minutes, seconds)
         end
      elseif (minutes > 0) then
         if (excludeSeconds) then
            return string.format('%dm', minutes)
         else
            return string.format('%dm %ds', minutes, seconds)
         end
      else
         -- Ignore excludeseconds as that's all we have left
         return string.format('%ds', seconds)
      end
   end,
   formatNumber = function(number)
      if not number then return "0" end
      local absNum = math.abs(number)
      if absNum >= 1e9 then
         return string.format("%.2fB", number / 1e9)
      elseif absNum >= 1e6 then
         return string.format("%.2fM", number / 1e6)
      elseif absNum >= 1e3 then
         return string.format("%.2fK", number / 1e3)
      else
         return tostring(math.floor(number + 0.5))
      end
   end,
   formatNumberWithCommas = function(number)
      local formatted = number
      while true do
         formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
         if (k == 0) then
            break
         end
      end
      return formatted
   end
}
