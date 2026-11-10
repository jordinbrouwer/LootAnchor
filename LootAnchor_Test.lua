LootAnchor = LootAnchor or {}
local LA = LootAnchor

local DURATIONS = { { 5, "5s", "5 seconds" }, { 10, "10s", "10 seconds" }, { 20, "20s", "20 seconds" }, { 0, "Hold", "Until clicked" } }
local MAX_CARDS = 4

local function Seconds()
  local value = LA.db.testDuration
  if value == nil then return 10 end
  return value
end

local function Stack(cards, container, down, firstGap, gap)
  local from, to = down and "TOP" or "BOTTOM", down and "BOTTOM" or "TOP"
  local sign = down and -1 or 1
  local prev
  for _, f in ipairs(cards) do
    if f:IsShown() then
      f:ClearAllPoints()
      if prev then
        f:SetPoint(from, prev, to, 0, sign * gap)
      elseif firstGap then
        f:SetPoint(from, container, to, 0, sign * firstGap)
      else
        f:SetPoint(from, container, from, 0, 0)
      end
      prev = f
    end
  end
end

local clearing = false
local stacks = {
  roll = { cards = {}, width = 244, height = 62, color = { 0.5, 0.4, 0.2 },
    layout = function(cards) Stack(cards, GroupLootContainer, LA.db.growDown, nil, 4) end },
  alert = { cards = {}, width = 280, height = 70, color = { 0.9, 0.7, 0.2 },
    layout = function(cards) Stack(cards, AlertFrame, LA.db.growDownAlert, 10, 10) end },
}

local function Relayout(stack)
  if not clearing then stack.layout(stack.cards) end
end

local function MakeCard(stack)
  local c = stack.color
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetSize(stack.width, stack.height)
  f:SetFrameStrata("FULLSCREEN")
  f:SetFrameLevel(50)
  f:EnableMouse(true)
  f:Hide()
  local edge = f:CreateTexture(nil, "BORDER")
  edge:SetAllPoints()
  edge:SetColorTexture(c[1], c[2], c[3], 0.45)
  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", 1, -1)
  bg:SetPoint("BOTTOMRIGHT", -1, 1)
  bg:SetColorTexture(0.05, 0.05, 0.06, 0.92)
  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetSize(36, 36)
  icon:SetPoint("LEFT", 12, 0)
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
  f.line = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.line:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 2)

  f:SetScript("OnMouseDown", f.Hide)
  f:SetScript("OnHide", function() Relayout(stack) end)
  return f
end

local function ShowCard(stack, title, line, r, g, b)
  if not (GroupLootContainer and AlertFrame) then return end
  local cards, f = stack.cards, nil
  for i, card in ipairs(cards) do
    if not card:IsShown() then
      f = table.remove(cards, i)
      break
    end
  end
  if not f and #cards >= MAX_CARDS then f = table.remove(cards, 1) end
  f = f or MakeCard(stack)
  cards[#cards + 1] = f
  f.title:SetText(title)
  f.line:SetText(line)
  f.line:SetTextColor(r, g, b)
  f.token = (f.token or 0) + 1
  local mine, seconds = f.token, Seconds()
  f:Show()
  Relayout(stack)
  if seconds > 0 then
    C_Timer.After(seconds, function()
      if mine == f.token then f:Hide() end
    end)
  end
end

function LA.TestRolls() ShowCard(stacks.roll, "Test loot roll", "Need   Greed   Pass", 0.56, 0.64, 0.68) end
function LA.TestReceived() ShowCard(stacks.alert, "You received", "[Test item]", 0.0, 0.44, 0.87) end
function LA.TestAchievement() ShowCard(stacks.alert, "Achievement earned", "Test achievement", 1, 1, 1) end

function LA.HideTests()
  clearing = true
  for _, stack in pairs(stacks) do
    for _, f in ipairs(stack.cards) do
      f.token = (f.token or 0) + 1
      f:Hide()
    end
  end
  clearing = false
end

function LA.BuildTestControls(bar)
  local group = LA.ButtonGroup(bar, {
    { "Roll", 46, LA.TestRolls, "Show a loot roll window. Click again for more." },
    { "Received", 66, LA.TestReceived, "Show a \"You received\" popup. Click again for more." },
    { "Achievement", 84, LA.TestAchievement, "Show an achievement popup. Click again for more." },
  }, 22)
  group:SetPoint("LEFT", 8, 0)

  local duration = LA.Button(bar, "", 58, 22, "ghost", "How long the test windows stay.")
  duration:SetPoint("LEFT", group, "RIGHT", 8, 0)
  duration.text:ClearAllPoints()
  duration.text:SetPoint("LEFT", 8, 0)
  LA.Caret(duration, LA.MUTED):SetPoint("LEFT", duration.text, "RIGHT", 5, -1)
  local function Refresh()
    for _, entry in ipairs(DURATIONS) do
      if entry[1] == Seconds() then duration.text:SetText(entry[2]) end
    end
  end
  local names = {}
  for i, entry in ipairs(DURATIONS) do names[i] = entry[3] end
  local list = LA.Menu(bar, duration, names, 120, function(n)
    LA.db.testDuration = DURATIONS[n][1]
    Refresh()
  end)
  duration:SetScript("OnClick", function() list:SetShown(not list:IsShown()) end)

  local clear = LA.Button(bar, "Clear", 40, 22, "ghost", "Remove every test window from the screen.")
  clear:SetPoint("LEFT", duration, "RIGHT", 2, 0)
  clear:SetScript("OnClick", LA.HideTests)

  bar:SetScript("OnShow", Refresh)
  bar:SetScript("OnHide", function() list:Hide() end)
  Refresh()
  return 8 + group:GetWidth() + 8 + 58 + 2 + 40 + 8
end
