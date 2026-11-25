-- The small flat parts: window frame, header band, close cross, button, row of buttons, dropdown list, field, box.
-- The look is the same as in AutomaticRoleCheck.
local LA = LootAnchor
local UI = LA.UI
local THEME = UI.THEME
local Fill, AddBorder, SetBorderColor = UI.Fill, UI.AddBorder, UI.SetBorderColor

-- UI.AddTooltip(frame, text, title, owner, anchor): text and title are strings or functions that return one.
-- The tooltip hangs on `owner` (default: the frame), at `anchor` (default: under it).
function UI.AddTooltip(frame, text, title, owner, anchor)
  local function Resolve(value) if type(value) == "function" then return value() end return value end
  frame:HookScript("OnEnter", function(self)
    if self.clicked then return end   -- a button does not show its tooltip again right after a click
    UI.Tip.Show(owner or self, anchor or "BOTTOM", Resolve(title), Resolve(text))
  end)
  frame:HookScript("OnLeave", function(self) UI.Tip.Hide(owner or self) end)
end

-- A window frame: flat dark, a thin border and the teal line along the top.
function UI.StyleWindow(frame)
  Fill(frame, unpack(THEME.WINDOW))
  AddBorder(frame, THEME.BORDER)
  local accent = frame:CreateTexture(nil, "ARTWORK")
  accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  accent:SetHeight(2)
  accent:SetColorTexture(unpack(THEME.ACCENT))
end

-- The header band under the teal line (3 pixels from the top of the window).
function UI.CreateHeaderBand(parent, height)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -3)
  bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -3)
  bar:SetHeight(height)
  Fill(bar, unpack(THEME.HEADER))
  return bar
end

-- A drawn cross: muted, bright under the mouse.
function UI.CreateCloseButton(parent, onClick)
  local close = CreateFrame("Button", nil, parent)
  close:SetSize(24, 22)
  local bars = {}
  for _, angle in ipairs({ math.pi / 4, -math.pi / 4 }) do
    local bar = close:CreateTexture(nil, "ARTWORK")
    bar:SetSize(11, 1.5)
    bar:SetPoint("CENTER")
    bar:SetRotation(angle)
    bars[#bars + 1] = bar
  end
  local function Paint(color) for _, bar in ipairs(bars) do bar:SetColorTexture(color[1], color[2], color[3], 1) end end
  Paint(THEME.MUTED)
  close:SetScript("OnEnter", function() Paint(THEME.BRIGHT) end)
  close:SetScript("OnLeave", function() Paint(THEME.MUTED) end)
  close:SetScript("OnClick", onClick)
  return close
end

---------------------------------------------------------------- buttons
-- The looks of a button: the colours at rest and under the mouse, and the edge.
local LOOKS = {
  flat = { rest = THEME.BUTTON, hover = THEME.BUTTON_HOVER, edge = THEME.BORDER },
  primary = { rest = THEME.BUTTON_ON, hover = THEME.BUTTON_ON_HOVER, edge = THEME.ACCENT },
  ghost = {},   -- no fill and no edge: only the text
}

local function Press(button)
  local point, rel, relPoint, x, y = button.text:GetPoint(1)
  button.pressed = { point, rel, relPoint, x, y }
  button.text:SetPoint(point, rel, relPoint, x, y - 1)
end

local function Release(button)
  local p = button.pressed
  if p then button.text:SetPoint(p[1], p[2], p[3], p[4], p[5]) end
  button.pressed = nil
end

-- A flat button. style: "flat" (default), "primary" (the main or chosen one) or "ghost" (only text).
-- SetSelected(true) gives the primary look. tip: the tooltip.
function UI.FlatChip(parent, label, width, height, style, tip)
  local look = LOOKS[style or "flat"]
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(width, height)
  local fill = look.rest and Fill(button, 0, 0, 0, 0)
  local edges = look.edge and AddBorder(button, look.edge)
  button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  button.text:SetPoint("CENTER")
  button.text:SetText(label)

  local function Paint(hover)
    local l = button.selected and LOOKS.primary or look
    if fill then
      local c = hover and l.hover or l.rest
      fill:SetColorTexture(c[1], c[2], c[3], 1)
    else
      local c = hover and THEME.BRIGHT or THEME.MUTED
      button.text:SetTextColor(c[1], c[2], c[3])
    end
    if edges then SetBorderColor(edges, hover and THEME.ACCENT or l.edge) end
  end
  Paint(false)

  function button.SetSelected(_, value)
    button.selected = value
    button:SetFrameLevel(parent:GetFrameLevel() + (value and 3 or 1))
    Paint(false)
  end

  button:HookScript("OnEnter", function() Paint(true) end)
  button:HookScript("OnLeave", function(self)
    Paint(false)
    self.clicked = nil
  end)
  button:SetScript("PostClick", function(self)
    self.clicked = true
    UI.Tip.Hide(self)
  end)
  button:SetScript("OnMouseDown", Press)
  button:SetScript("OnMouseUp", Release)
  if tip then UI.AddTooltip(button, tip, label) end
  return button
end

-- A row of separate buttons: items = { { label, width, onClick, tip }, ... }. Gives back the row.
function UI.CreateButtonRow(parent, items, height, gap)
  local row = CreateFrame("Frame", nil, parent)
  local x = 0
  for _, item in ipairs(items) do
    local button = UI.FlatChip(row, item[1], item[2], height, "flat", item[4])
    button:SetPoint("LEFT", x, 0)
    button:SetScript("OnClick", item[3])
    x = x + item[2] + gap
  end
  row:SetSize(math.max(1, x - gap), height)
  return row
end

-- A small arrow pointing down, for something that opens a list.
function UI.CreateCaret(parent, color)
  local caret = CreateFrame("Frame", nil, parent)
  caret:SetSize(9, 5)
  for row = 1, 5 do
    local line = caret:CreateTexture(nil, "OVERLAY")
    line:SetColorTexture(color[1], color[2], color[3], 1)
    line:SetSize(11 - row * 2, 1)
    line:SetPoint("TOP", 0, 1 - row)
  end
  return caret
end

-- A field: dark with a thin edge (a closed dropdown, a box you type in). frame.edges: its border lines.
function UI.StyleField(frame)
  Fill(frame, unpack(THEME.FIELD))
  frame.edges = AddBorder(frame, THEME.BORDER)
end

-- The list of a dropdown, under `anchor`: names = the texts, onPick(n) runs when one is chosen.
-- colorFn (optional) gives the colour of the highlight under the mouse.
function UI.CreateMenu(parent, anchor, names, width, onPick, colorFn)
  local list = CreateFrame("Frame", nil, parent)
  list:SetSize(width, #names * 20 + 4)
  list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  list:SetFrameLevel(parent:GetFrameLevel() + 20)
  list:EnableMouse(true)
  list:Hide()
  Fill(list, unpack(THEME.MENU_BG))
  AddBorder(list, THEME.BORDER)
  for index, name in ipairs(names) do
    local item = CreateFrame("Button", nil, list)
    item:SetSize(width - 4, 20)
    item:SetPoint("TOPLEFT", 2, -2 - (index - 1) * 20)
    local text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 6, 0)
    text:SetText(name)
    local highlight = Fill(item, 0, 0, 0, 0)
    item:SetScript("OnEnter", function()
      local c = colorFn and colorFn() or THEME.ACCENT
      highlight:SetColorTexture(c[1], c[2], c[3], 0.2)
    end)
    item:SetScript("OnLeave", function() highlight:SetColorTexture(0, 0, 0, 0) end)
    item:SetScript("OnClick", function()
      list:Hide()
      onPick(index)
    end)
  end
  UI.ApplyOutline(list)
  return list
end

---------------------------------------------------------------- boxes
-- A box like the ones in AutomaticRoleCheck: dark, a thin border, the title in the corner.
function UI.CreateBox(parent, titleText)
  local box = CreateFrame("Frame", nil, parent)
  Fill(box, unpack(THEME.BOX_BG))
  AddBorder(box, THEME.BOX_BORDER)
  box.Title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  box.Title:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -6)
  box.Title:SetTextColor(unpack(THEME.ACCENT))
  box.Title:SetText(titleText)
  return box
end
