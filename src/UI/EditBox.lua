-- The box "Move the boxes" in the panel (edit mode): what to do, and the buttons Reset and Defaults.
local LA = LootAnchor
local UI = LA.UI
local THEME, LAYOUT = UI.THEME, UI.LAYOUT
local L = LA.Loc

local HINT_COLOR = THEME.MUTED

-- Builds the box into `parent`. Gives back the box; its height is set.
function UI.BuildEditBox(parent)
  local box = UI.CreateBox(parent, L("box_edit"))
  local hint = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", box, "TOPLEFT", LAYOUT.BOX_INDENT, -LAYOUT.BOX_HEADER - 2)
  hint:SetWidth(LAYOUT.PANEL_W - LAYOUT.OUTER * 2 - LAYOUT.BOX_INDENT * 2)
  hint:SetJustifyH("LEFT")
  hint:SetTextColor(HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])
  hint:SetText(L("edit_hint"))
  local hintHeight = math.ceil(hint:GetStringHeight())

  local row = UI.CreateButtonRow(box, {
    { L("btn_reset"), 60, LA.RevertAll, L("tip_reset") },
    { L("btn_defaults"), 72, LA.DefaultsAll, L("tip_defaults") },
  }, LAYOUT.ROW_H, 4)
  row:SetPoint("TOPLEFT", box, "TOPLEFT", LAYOUT.BOX_INDENT, -(LAYOUT.BOX_HEADER + 2 + hintHeight + 6))
  box:SetHeight(LAYOUT.BOX_HEADER + 2 + hintHeight + 6 + LAYOUT.ROW_H + LAYOUT.BOX_BOTTOM)
  UI.ApplyOutline(box)
  return box
end
