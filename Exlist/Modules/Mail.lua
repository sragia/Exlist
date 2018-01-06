local key = "mail"
local Exlist = Exlist
local WrapTextInColorCode = WrapTextInColorCode
local HasNewMail, GetLatestThreeSenders = HasNewMail, GetLatestThreeSenders
local table = table

local function Updater(event)
  local t = {}
  if HasNewMail() then
    local senders = {GetLatestThreeSenders()};
    t.new = true
    t.senders = senders
  end
  Exlist.UpdateChar(key,t)
end

local function Linegenerator(tooltip,data)
  if not data or not data.new then return end
  local line = Exlist.AddLine(tooltip,{WrapTextInColorCode("Got Mail!","FF00FF00")})
  local t = {title = WrapTextInColorCode("Senders","ffffd200"), body = {}}
  for i=1, #data.senders do
    table.insert(t.body,{data.senders[i]})
  end
  Exlist.AddScript(tooltip,line,nil,"OnEnter",Exlist.CreateSideTooltip(),t)
  Exlist.AddScript(tooltip,line,nil,"OnLeave",Exlist.DisposeSideTooltip())
end

local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
end

local data = {
  name = 'Mail',
  key = key,
  linegenerator = Linegenerator,
  priority = -100,
  updater = Updater,
  event = {"PLAYER_ENTERING_WORLD","UPDATE_PENDING_MAIL"},
  weeklyReset = false,
  -- modernize = Modernize
}
  
Exlist.RegisterModule(data)
