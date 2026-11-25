-- LA.Loc("key") gives the text (or the key itself when it is missing); LA.Loc("key", a, b) fills in the %s parts.
-- Other languages go in `locales`, with only the keys they change.
LootAnchor = LootAnchor or {}

local enUS = {
  header_sub = "Move the loot and achievement popups.",
  target_roll = "Loot Rolls",
  target_alert = "You Received & Achievements",
  tab_edit = "Edit",
  tab_test = "Test",
  tip_edit = "Move the boxes.",
  tip_test = "Try the loot rolls and popups with your current settings.",
  box_edit = "Move the boxes",
  box_test = "Try them out",
  edit_hint = "Drag a box, or click one and use the arrow keys.",
  panel_save = "Save & exit",
  tip_save = "Keep your changes and close LootAnchor.",
  footer_hint = "Type %s in chat to open this again.",
  btn_reset = "Reset",
  tip_reset = "Undo your changes since opening LootAnchor.",
  btn_defaults = "Defaults",
  tip_defaults = "Reset to Blizzard's initial location.",
  grow_up = "Grow up",
  grow_down = "Grow down",
  tip_grow = "Which way the windows stack.",
  field_x = "X",
  field_y = "Y",
  test_roll = "Roll",
  tip_test_roll = "Show a loot roll window. Click again for more.",
  test_received = "Received",
  tip_test_received = "Show a \"You received\" popup. Click again for more.",
  test_achievement = "Achievement",
  tip_test_achievement = "Show an achievement popup. Click again for more.",
  tip_duration = "How long the test windows stay.",
  btn_clear = "Clear",
  tip_clear = "Remove every test window from the screen.",
  duration_5 = "5 seconds",
  duration_5_short = "5s",
  duration_10 = "10 seconds",
  duration_10_short = "10s",
  duration_20 = "20 seconds",
  duration_20_short = "20s",
  duration_hold = "Until clicked",
  duration_hold_short = "Hold",
  card_roll_title = "Test loot roll",
  card_roll_line = "Need   Greed   Pass",
  card_received_title = "You received",
  card_received_line = "[Test item]",
  card_achievement_title = "Achievement earned",
  card_achievement_line = "Test achievement",
  page_desc = "Move the loot roll windows and the \"You received\" and achievement popups.",
  page_open = "Open LootAnchor",
  page_hint = "or type /la",
}

local locales = { enUS = enUS }

LootAnchor.Loc = function(key, ...)
  local strings = locales[GetLocale()] or enUS
  local text = strings[key] or enUS[key] or key
  if select("#", ...) > 0 then
    local ok, result = pcall(string.format, text, ...)
    return ok and result or text
  end
  return text
end
