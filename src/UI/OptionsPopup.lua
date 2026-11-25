-- The small box next to the active box: which way the windows stack (Grow up / down) and the X and Y of the box.
local LA = LootAnchor
local UI = LA.UI
local THEME = UI.THEME
local Fill, AddBorder, SetBorderColor = UI.Fill, UI.AddBorder, UI.SetBorderColor
local L = LA.Loc

local WIDTH = 150
local popup

-- The colour of the active box.
local function BoxColor()
  return LA.active and UI.TargetColor(LA.active) or THEME.ACCENT
end

-- A box with a label in front, for a number.
local function CreateNumberField(o, label, x)
  local text = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT", x, -32)
  text:SetText(label)
  text:SetTextColor(THEME.MUTED[1], THEME.MUTED[2], THEME.MUTED[3])
  local field = CreateFrame("EditBox", nil, o)
  field:SetSize(52, 18)
  field:SetPoint("TOPLEFT", x + 11, -28)
  field:SetFontObject("GameFontHighlightSmall")
  field:SetTextInsets(6, 4, 0, 0)
  field:SetAutoFocus(false)
  field:SetNumeric(true)
  field:SetMaxLetters(5)
  UI.StyleField(field)
  field:SetScript("OnEditFocusGained", function(self) SetBorderColor(self.edges, BoxColor()) end)
  field:SetScript("OnEditFocusLost", function(self)
    SetBorderColor(self.edges, THEME.BORDER)
    self:HighlightText(0, 0)
  end)
  field:SetScript("OnEnterPressed", function(self)
    LA.SetPosition(o.x:GetNumber(), o.y:GetNumber())
    self:ClearFocus()
  end)
  field:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    LA.RefreshOptions()
  end)
  return field
end

local function Build()
  local o = CreateFrame("Frame", nil, UIParent)
  o:SetSize(WIDTH, 52)
  o:SetFrameStrata("FULLSCREEN_DIALOG")
  o:SetFrameLevel(5000)
  o:EnableMouse(true)
  o:Hide()
  Fill(o, unpack(THEME.HANDLE_BG))
  o.edges = AddBorder(o, THEME.ACCENT, 0.9)

  local drop = CreateFrame("Button", nil, o)
  drop:SetSize(WIDTH - 16, 18)
  drop:SetPoint("TOPLEFT", 8, -6)
  UI.StyleField(drop)
  drop.text = drop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  drop.text:SetPoint("LEFT", 8, 0)
  UI.CreateCaret(drop, THEME.MUTED):SetPoint("RIGHT", -8, 0)
  drop:SetScript("OnEnter", function() SetBorderColor(drop.edges, BoxColor()) end)
  drop:SetScript("OnLeave", function() SetBorderColor(drop.edges, THEME.BORDER) end)
  UI.AddTooltip(drop, L("tip_grow"), nil, nil, "RIGHT")
  o.drop = drop
  o.list = UI.CreateMenu(o, drop, { L("grow_up"), L("grow_down") }, WIDTH - 16, function(n)
    if LA.active then
      LA.SetGrowDown(LA.active, n == 2)
      LA.RefreshOptions()
    end
  end, BoxColor)
  drop:SetScript("OnClick", function() o.list:SetShown(not o.list:IsShown()) end)

  o.x, o.y = CreateNumberField(o, L("field_x"), 8), CreateNumberField(o, L("field_y"), 79)
  o:SetScript("OnHide", function()
    o.list:Hide()
    o.x:ClearFocus()
    o.y:ClearFocus()
  end)
  UI.ApplyOutline(o)
  popup = o
  return o
end

-- Puts the numbers of the active box in the X and Y fields (not while you type in one).
function LA.UpdateFields()
  local h = LA.active and LA.active.handle
  if not (popup and popup:IsShown() and h and h:GetLeft()) then return end
  if not popup.x:HasFocus() then popup.x:SetText(math.floor(h:GetLeft() + 0.5)) end
  if not popup.y:HasFocus() then popup.y:SetText(math.floor(h:GetBottom() + 0.5)) end
end

-- Shows the box next to the active box, or hides it when no box is active.
function LA.RefreshOptions()
  local t = LA.active
  local h = t and t.handle
  if not (h and h:IsShown() and h:GetRight()) then
    if popup then popup:Hide() end
    return
  end
  local o = popup or Build()
  SetBorderColor(o.edges, UI.TargetColor(t), 0.9)
  o.drop.text:SetText(LA.db[t.growKey] and L("grow_down") or L("grow_up"))
  o:ClearAllPoints()
  if h:GetRight() + 28 + WIDTH <= UIParent:GetWidth() then
    o:SetPoint("LEFT", h, "RIGHT", 28, 0)
  else
    o:SetPoint("RIGHT", h, "LEFT", -28, 0)
  end
  o:Show()
  LA.UpdateFields()
end

-- Is the mouse over this box (or its list)? (A click there keeps the box active.)
function UI.OverPopup()
  return popup and ((popup:IsVisible() and popup:IsMouseOver()) or (popup.list:IsVisible() and popup.list:IsMouseOver()))
end
