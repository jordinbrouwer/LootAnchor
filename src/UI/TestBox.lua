-- The box "Try them out" (test mode): buttons for made-up windows, how long they stay, and Clear.
local LA = LootAnchor
local UI = LA.UI
local THEME, LAYOUT = UI.THEME, UI.LAYOUT
local L = LA.Loc

local DURATION_W, CLEAR_W = 58, 40

-- The short name of the chosen duration, for the button.
local function ShortName()
  for _, entry in ipairs(LA.DURATIONS) do
    if entry[1] == LA.TestSeconds() then return L(entry[2]) end
  end
  return ""
end

-- Builds the box into `parent`. Gives back the box; its height is set.
function UI.BuildTestBox(parent)
  local box = UI.CreateBox(parent, L("box_test"))
  local row = UI.CreateButtonRow(box, {
    { L("test_roll"), 46, LA.TestRolls, L("tip_test_roll") },
    { L("test_received"), 66, LA.TestReceived, L("tip_test_received") },
    { L("test_achievement"), 84, LA.TestAchievement, L("tip_test_achievement") },
  }, LAYOUT.ROW_H, 4)
  row:SetPoint("TOPLEFT", box, "TOPLEFT", LAYOUT.BOX_INDENT, -(LAYOUT.BOX_HEADER + 6))   -- a little air under the title

  local duration = UI.FlatChip(box, "", DURATION_W, LAYOUT.ROW_H, "ghost", L("tip_duration"))
  duration:SetPoint("LEFT", row, "RIGHT", 8, 0)
  duration.text:ClearAllPoints()
  duration.text:SetPoint("LEFT", 8, 0)
  UI.CreateCaret(duration, THEME.MUTED):SetPoint("LEFT", duration.text, "RIGHT", 5, -1)
  local names = {}
  for index, entry in ipairs(LA.DURATIONS) do names[index] = L(entry[3]) end
  local list = UI.CreateMenu(box, duration, names, 120, function(n)
    LA.db.testDuration = LA.DURATIONS[n][1]
    duration.text:SetText(ShortName())
  end)
  duration:SetScript("OnClick", function() list:SetShown(not list:IsShown()) end)

  local clear = UI.FlatChip(box, L("btn_clear"), CLEAR_W, LAYOUT.ROW_H, "ghost", L("tip_clear"))
  clear:SetPoint("LEFT", duration, "RIGHT", 2, 0)
  clear:SetScript("OnClick", LA.HideTests)

  box:SetScript("OnShow", function() duration.text:SetText(ShortName()) end)
  box:SetScript("OnHide", function() list:Hide() end)
  box:SetHeight(LAYOUT.BOX_HEADER + 6 + LAYOUT.ROW_H + LAYOUT.BOX_BOTTOM)
  UI.ApplyOutline(box)
  return box
end
