-- The panel: a header (logo, name, close), two tabs (Edit and Test), the box of the chosen tab, and a footer with
-- "Save & exit". Opening it lets you drag the boxes; /la opens and closes it.
local LA = LootAnchor
local UI = LA.UI
local THEME, LAYOUT = UI.THEME, UI.LAYOUT
local L = LA.Loc

local TEAL_CODE = "|cff1ad9ad"   -- the teal of the addon, as a colour code (for the hint)
local panel, tabs = nil, {}
local boxes = {}      -- edit, test

---------------------------------------------------------------- the parts
-- The frame: where it was left, or else at the top of the screen. You drag it by its header.
local function BuildFrame()
  local frame = CreateFrame("Frame", "LootAnchorPanel", UIParent)
  frame:SetWidth(LAYOUT.PANEL_W)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:Hide()
  local saved = LA.db.toolbar
  if saved then
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
  else
    frame:SetPoint("TOP", UIParent, "TOP", 0, -20)
  end
  UI.StyleWindow(frame)
  return frame
end

local function BuildHeader(frame)
  local bar = UI.CreateHeaderBand(frame, LAYOUT.HEADER - 3)
  bar:EnableMouse(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", function() frame:StartMoving() end)
  bar:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    local x, y = frame:GetLeft(), frame:GetTop()
    if x then
      LA.db.toolbar = { x = x, y = y }
      frame:ClearAllPoints()
      frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    end
  end)

  local logo = bar:CreateTexture(nil, "ARTWORK")
  logo:SetSize(34, 34)
  logo:SetPoint("LEFT", bar, "LEFT", 12, 0)
  logo:SetTexture(LA.Media.Logo)
  local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetTextColor(unpack(THEME.TITLE_TEXT))
  title:SetText(LA.AddonName)
  local subtitle = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
  subtitle:SetTextColor(unpack(THEME.SUBTITLE_TEXT))
  subtitle:SetWidth(LAYOUT.PANEL_W - 56 - 40)   -- stays clear of the close button
  subtitle:SetJustifyH("LEFT")
  subtitle:SetWordWrap(true)   -- a long text goes on over more lines; the band grows with it
  subtitle:SetText(L("header_sub"))
  title:SetPoint("LEFT", bar, "LEFT", 56, (subtitle:GetStringHeight() + 2) / 2)
  -- as tall as the name and description need, with the same air above and below (at least the default);
  -- LAYOUT.HEADER follows, so the tabs, the boxes and the panel height place themselves under it
  local h = math.max(LAYOUT.HEADER - 3, math.ceil(title:GetStringHeight() + 2 + subtitle:GetStringHeight() + 14))
  bar:SetHeight(h)
  LAYOUT.HEADER = h + 3

  local close = UI.CreateCloseButton(bar, function() LA.ToggleOptions() end)
  close:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -9, 0)
end

-- The two tabs: they look like a row of two buttons where one is chosen.
local function BuildTabs(frame)
  local width = (LAYOUT.PANEL_W - LAYOUT.OUTER * 2 - 4) / 2
  tabs.edit = UI.FlatChip(frame, L("tab_edit"), width, LAYOUT.TAB_H, "flat", L("tip_edit"))
  tabs.edit:SetPoint("TOPLEFT", frame, "TOPLEFT", LAYOUT.OUTER, -(LAYOUT.HEADER + LAYOUT.TOP))
  tabs.edit:SetScript("OnClick", function() LA.SetMode("edit") end)
  tabs.test = UI.FlatChip(frame, L("tab_test"), width, LAYOUT.TAB_H, "flat", L("tip_test"))
  tabs.test:SetPoint("LEFT", tabs.edit, "RIGHT", 4, 0)
  tabs.test:SetScript("OnClick", function() LA.SetMode("test") end)
end

-- The footer band: a hint, and the main button.
local function BuildFooter(frame)
  local band = frame:CreateTexture(nil, "ARTWORK")
  band:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
  band:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  band:SetHeight(LAYOUT.FOOTER)
  band:SetColorTexture(unpack(THEME.HEADER))
  local line = frame:CreateTexture(nil, "ARTWORK")
  line:SetPoint("BOTTOMLEFT", band, "TOPLEFT", 0, 0)
  line:SetPoint("BOTTOMRIGHT", band, "TOPRIGHT", 0, 0)
  UI.OnePixel(line, true)
  line:SetColorTexture(THEME.BORDER[1], THEME.BORDER[2], THEME.BORDER[3], 1)
  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hint:SetPoint("LEFT", band, "LEFT", 10, 0)
  hint:SetTextColor(unpack(THEME.MUTED))
  hint:SetText(L("footer_hint", TEAL_CODE .. "/la|r"))
  local save = UI.FlatChip(frame, L("panel_save"), 68, 16, "primary", L("tip_save"))
  save:SetPoint("RIGHT", band, "RIGHT", -8, 0)
  save:SetScript("OnClick", function() LA.ToggleOptions() end)
end

local function BuildBoxes(frame)
  boxes.edit = UI.BuildEditBox(frame)
  boxes.test = UI.BuildTestBox(frame)
  for _, box in pairs(boxes) do
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", LAYOUT.OUTER, -(LAYOUT.HEADER + LAYOUT.TOP + LAYOUT.TAB_H + LAYOUT.TAB_GAP))
    box:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -LAYOUT.OUTER, -(LAYOUT.HEADER + LAYOUT.TOP + LAYOUT.TAB_H + LAYOUT.TAB_GAP))
    box:Hide()
  end
end

local function Build()
  panel = BuildFrame()
  BuildHeader(panel)
  BuildTabs(panel)
  BuildFooter(panel)
  BuildBoxes(panel)
  UI.ApplyOutline(panel)
end

---------------------------------------------------------------- modes
-- Is the mouse over the panel or the box next to a box you drag? (A click there keeps the active box.)
function UI.OverChrome()
  return (panel and panel:IsVisible() and panel:IsMouseOver()) or UI.OverPopup() or false
end

-- "edit": the boxes can be dragged. "test": the real windows are in place, and made-up ones can be shown.
function LA.SetMode(mode)
  if not LA.open then return end
  local editing = mode == "edit"
  LA.mode = mode
  UI.SetEditing(editing)
  tabs.edit:SetSelected(editing)
  tabs.test:SetSelected(not editing)
  boxes.edit:SetShown(editing)
  boxes.test:SetShown(not editing)
  local box = editing and boxes.edit or boxes.test
  panel:SetHeight(LAYOUT.HEADER + LAYOUT.TOP + LAYOUT.TAB_H + LAYOUT.TAB_GAP + box:GetHeight() + LAYOUT.TAB_GAP + LAYOUT.FOOTER)
  if editing then
    LA.HideTests()
  else
    LA.Apply()
  end
end

-- Opens the panel (edit mode), or closes it: what you changed is kept.
function LA.ToggleOptions()
  if not panel then Build() end
  if LA.open then
    LA.SetMode("test")
    LA.open, LA.mode = false, nil
    LA.HideTests()
    panel:Hide()
    return
  end

  -- what it looked like when the panel opened, for the Reset button
  LA.snapshot = {}
  for _, t in ipairs(LA.targets) do
    local saved = LA.db[t.key]
    LA.snapshot[t.key] = { x = saved and saved.x, y = saved and saved.y, grow = LA.db[t.growKey] }
  end
  LA.open = true
  panel:Show()
  LA.SetMode("edit")
end
