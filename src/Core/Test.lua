-- The test windows: made-up loot roll, "You received" and achievement cards, stacked like the real ones.
-- (The buttons are in UI/TestBox.lua.)
local LA = LootAnchor

local MAX_CARDS = 4

-- How long test windows stay: seconds (0: until clicked), and the locale keys of the short and long name.
LA.DURATIONS = {
  { 5, "duration_5_short", "duration_5" },
  { 10, "duration_10_short", "duration_10" },
  { 20, "duration_20_short", "duration_20" },
  { 0, "duration_hold_short", "duration_hold" },
}

-- How many seconds a test window stays.
function LA.TestSeconds()
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
  local mine, seconds = f.token, LA.TestSeconds()
  f:Show()
  Relayout(stack)
  if seconds > 0 then
    C_Timer.After(seconds, function()
      if mine == f.token then f:Hide() end
    end)
  end
end

function LA.TestRolls() ShowCard(stacks.roll, LA.Loc("card_roll_title"), LA.Loc("card_roll_line"), 0.56, 0.64, 0.68) end
function LA.TestReceived() ShowCard(stacks.alert, LA.Loc("card_received_title"), LA.Loc("card_received_line"), 0.0, 0.44, 0.87) end
function LA.TestAchievement() ShowCard(stacks.alert, LA.Loc("card_achievement_title"), LA.Loc("card_achievement_line"), 1, 1, 1) end

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
