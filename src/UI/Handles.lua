-- The boxes you drag: one for each window we move. Drag a box, or click it and use the arrow keys; it snaps to the
-- middle and edges of the screen and to the other box. Also the dark layer with the guide lines.
local LA = LootAnchor
local UI = LA.UI
local THEME = UI.THEME
local Fill, AddBorder, SetBorderColor = UI.Fill, UI.AddBorder, UI.SetBorderColor
local W, H, targets = LA.W, LA.H, LA.targets

local overlay, guideV, guideH
local topLevel = 10

---------------------------------------------------------------- the active box
local function RefreshBoxes()
  for _, t in ipairs(targets) do
    if t.handle then
      local active = LA.active == t
      SetBorderColor(t.edges, UI.TargetColor(t), (active or t.hover) and 1 or 0.75)
      t.pad:SetShown(active)
    end
  end
  LA.RefreshOptions()
end

local function SetActive(t)
  if LA.active ~= t then
    LA.active = t
    RefreshBoxes()
  end
end

---------------------------------------------------------------- snapping
local function ShowGuides(snapX, snapY)
  guideV:SetAlpha(snapX and 0.95 or 0.18)
  guideH:SetAlpha(snapY and 0.95 or 0.18)
end

local function Nearest(value, list)
  local best, dist = nil, LA.SNAP_DIST + 0.001
  for _, c in ipairs(list) do
    local d = math.abs(value - c)
    if d < dist then best, dist = c, d end
  end
  return best
end

-- Where a box lands: the middle and edges of the screen, the sides of the other box, or else a grid.
local function Snap(t, left, bottom)
  local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
  local cx, cy = sw / 2 - W / 2, sh / 2 - H / 2
  local xs, ys = { 0, cx, sw - W }, { 0, cy, sh - H }
  for _, o in ipairs(targets) do
    local oh = o.handle
    if o ~= t and oh and oh:IsShown() and oh:GetLeft() then
      local ol, ob = oh:GetLeft(), oh:GetBottom()
      for _, v in ipairs({ ol, ol + W, ol - W }) do xs[#xs + 1] = v end
      for _, v in ipairs({ ob, ob + H, ob - H }) do ys[#ys + 1] = v end
    end
  end
  local x, y = Nearest(left, xs), Nearest(bottom, ys)
  local onX, onY = x and math.abs(x - cx) < 0.5, y and math.abs(y - cy) < 0.5
  x = x or math.floor(left / LA.SNAP + 0.5) * LA.SNAP
  y = y or math.floor(bottom / LA.SNAP + 0.5) * LA.SNAP
  return math.max(0, math.min(sw - W, x)), math.max(0, math.min(sh - H, y)), onX, onY
end

---------------------------------------------------------------- moving
local function PositionHandle(t)
  local h = t.handle or UI.MakeHandle(t)
  local f, pos = t.get(), LA.db[t.key]
  h:ClearAllPoints()
  if pos then
    h:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
  elseif f and f:GetCenter() then
    h:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", f:GetCenter() - W / 2, f:GetBottom())
  else
    h:SetPoint("CENTER")
  end
  if LA.active == t then LA.RefreshOptions() end
end

function LA.RefreshHandles()
  local function Apply()
    if not LA.unlocked then return end
    for _, t in ipairs(targets) do PositionHandle(t) end
  end
  Apply()
  C_Timer.After(0.1, Apply)
  C_Timer.After(0.5, Apply)
end

local function Move(t, x, y)
  local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
  LA.db[t.key] = { x = math.max(0, math.min(sw - W, x)), y = math.max(0, math.min(sh - H, y)) }
  LA.Place(t)
  PositionHandle(t)
end

-- The active box goes to (x, y), the numbers of the X and Y fields.
function LA.SetPosition(x, y)
  if LA.active and LA.active.handle then Move(LA.active, x, y) end
end

-- The active box moves by (dx, dy) screen pixels.
function LA.Nudge(dx, dy)
  local t = LA.active
  local h = t and t.handle
  if not (h and h:GetLeft()) then return end
  local px = 1 / UIParent:GetEffectiveScale()
  Move(t, h:GetLeft() + dx * px, h:GetBottom() + dy * px)
end

---------------------------------------------------------------- one box
-- The arrow buttons round the active box: they repeat while you hold them.
local function Repeat(button, dx, dy)
  local since = 0
  local function Stop(self) self:SetScript("OnUpdate", nil) end
  button:SetScript("OnMouseDown", function(self)
    LA.Nudge(dx, dy)
    since = -0.35
    self:SetScript("OnUpdate", function(_, elapsed)
      since = since + elapsed
      if since >= 0.03 then
        since = 0
        LA.Nudge(dx, dy)
      end
    end)
  end)
  button:SetScript("OnMouseUp", Stop)
  button:SetScript("OnHide", Stop)
end

local PAD = {
  { -1, 0, math.pi * 1.5, "RIGHT", "LEFT", -4, 0 },
  { 1, 0, math.pi / 2, "LEFT", "RIGHT", 4, 0 },
  { 0, 1, math.pi, "BOTTOM", "TOP", 0, 4 },
  { 0, -1, 0, "TOP", "BOTTOM", 0, -4 },
}

local function BuildPad(t, h, c)
  t.pad = CreateFrame("Frame", nil, h)
  t.pad:SetAllPoints()
  t.pad:Hide()
  t.padButtons = {}
  for _, a in ipairs(PAD) do
    local button = CreateFrame("Button", nil, t.pad)
    button:SetSize(18, 18)
    button:SetPoint(a[4], h, a[5], a[6], a[7])
    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetRotation(a[3])
    icon:SetDesaturated(true)
    icon:SetVertexColor(c[1], c[2], c[3])
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    Repeat(button, a[1], a[2])
    t.padButtons[#t.padButtons + 1] = button
  end
end

function UI.MakeHandle(t)
  local h = CreateFrame("Frame", nil, UIParent)
  h:SetSize(W, H)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(true)
  h:RegisterForDrag("LeftButton")
  h:Hide()
  Fill(h, unpack(THEME.HANDLE_BG))

  local c = UI.TargetColor(t)
  t.edges = AddBorder(h, c, 0.75)

  local label = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint(t.labelAt, 0, t.labelAt == "TOP" and -8 or 8)
  label:SetText(t.label)
  label:SetTextColor(c[1], c[2], c[3])
  BuildPad(t, h, c)

  local function Raise()
    topLevel = topLevel + 1
    h:SetFrameLevel(topLevel)
  end
  h:SetScript("OnEnter", function()
    t.hover = true
    Raise()
    RefreshBoxes()
  end)
  h:SetScript("OnLeave", function()
    t.hover = false
    RefreshBoxes()
  end)
  h:SetScript("OnMouseDown", function()
    Raise()
    SetActive(t)
  end)

  h:SetScript("OnDragStart", function(self)
    Raise()
    SetActive(t)
    local scale = UIParent:GetEffectiveScale()
    local mx, my = GetCursorPosition()
    local grabX, grabY = mx / scale - self:GetLeft(), my / scale - self:GetBottom()
    self:SetScript("OnUpdate", function(box)
      local px, py = GetCursorPosition()
      local x, y, onX, onY = Snap(t, px / scale - grabX, py / scale - grabY)
      box:ClearAllPoints()
      box:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
      ShowGuides(onX, onY)
      LA.UpdateFields()
    end)
  end)
  h:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    ShowGuides(false, false)
    LA.db[t.key] = { x = self:GetLeft(), y = self:GetBottom() }
    LA.Place(t)
    LA.RefreshOptions()
  end)
  UI.ApplyOutline(h)
  t.handle = h
  return h
end

---------------------------------------------------------------- the arrow keys
local ARROWS = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }
local keys = CreateFrame("Frame", nil, UIParent)
keys:Hide()

local propagate = false
local function Propagate(value)
  -- SetPropagateKeyboardInput is protected in combat.
  if propagate == value or InCombatLockdown() then return end
  propagate = value
  keys:SetPropagateKeyboardInput(value)
end

keys:SetScript("OnKeyDown", function(_, key)
  if InCombatLockdown() then return end
  local step = ARROWS[key]
  if step and LA.active then
    Propagate(false)
    LA.Nudge(step[1], step[2])
  else
    Propagate(true)
  end
end)

keys:RegisterEvent("PLAYER_REGEN_DISABLED")
keys:RegisterEvent("PLAYER_REGEN_ENABLED")
keys:SetScript("OnEvent", function(_, event)
  local fighting = event == "PLAYER_REGEN_DISABLED"
  keys:EnableKeyboard(LA.unlocked and not fighting)
  if not fighting then Propagate(true) end
end)

-- A click outside the boxes and the panel makes no box active.
local function MouseOver(frame)
  return frame and frame:IsVisible() and frame:IsMouseOver()
end

local function OverUI()
  if UI.OverChrome and UI.OverChrome() then return true end
  for _, t in ipairs(targets) do
    if MouseOver(t.handle) then return true end
    for _, b in ipairs(t.padButtons or {}) do
      if MouseOver(b) then return true end
    end
  end
  return false
end

local wasDown = false
keys:SetScript("OnUpdate", function()
  local down = IsMouseButtonDown("LeftButton")
  if down and not wasDown and LA.active and not OverUI() then
    LA.active = nil
    RefreshBoxes()
  end
  wasDown = down
end)

---------------------------------------------------------------- the layer over the screen
local function BuildOverlay()
  overlay = CreateFrame("Frame", nil, UIParent)
  overlay:SetAllPoints(UIParent)
  overlay:SetFrameStrata("FULLSCREEN")
  overlay:Hide()
  Fill(overlay, unpack(THEME.OVERLAY))

  local accent = THEME.ACCENT
  guideV = overlay:CreateTexture(nil, "ARTWORK")
  guideV:SetColorTexture(accent[1], accent[2], accent[3], 1)
  UI.OnePixel(guideV, false)
  guideV:SetPoint("TOP")
  guideV:SetPoint("BOTTOM")
  guideH = overlay:CreateTexture(nil, "ARTWORK")
  guideH:SetColorTexture(accent[1], accent[2], accent[3], 1)
  UI.OnePixel(guideH, true)
  guideH:SetPoint("LEFT")
  guideH:SetPoint("RIGHT")
  ShowGuides(false, false)
end

-- Edit mode on or off: the layer, the boxes and the arrow keys.
function UI.SetEditing(editing)
  if not overlay then BuildOverlay() end
  LA.unlocked, LA.active = editing, nil
  keys:SetShown(editing)
  keys:EnableKeyboard(editing and not InCombatLockdown())
  overlay:SetShown(editing)
  for _, t in ipairs(targets) do
    if editing then PositionHandle(t) end
    if t.handle then t.handle:SetShown(editing) end
  end
  RefreshBoxes()
end
