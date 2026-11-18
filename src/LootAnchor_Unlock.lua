LootAnchor = LootAnchor or {}
local LA = LootAnchor
local W, H, TEAL, targets = LA.W, LA.H, LA.TEAL, LA.targets

local EDGE = { 0.23, 0.30, 0.34 }
local MUTED = { 0.56, 0.64, 0.68 }
local WHITE = { 1, 1, 1 }
LA.MUTED = MUTED

local overlay, toolbar, options, guideV, guideH
local topLevel = 10

local function Fill(frame, r, g, b, a)
  local tex = frame:CreateTexture(nil, "BACKGROUND")
  tex:SetAllPoints()
  tex:SetColorTexture(r, g, b, a)
  return tex
end

local SIDES = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }

local function SetBorder(edges, color, alpha)
  for _, e in ipairs(edges) do e:SetColorTexture(color[1], color[2], color[3], alpha or 1) end
end

local function Border(frame, color, alpha)
  local edges = {}
  for i, side in ipairs(SIDES) do
    local e = frame:CreateTexture(nil, "BORDER")
    e:SetPoint(side[1])
    e:SetPoint(side[2])
    if i < 3 then e:SetHeight(1) else e:SetWidth(1) end
    edges[i] = e
  end
  SetBorder(edges, color, alpha)
  return edges
end

local LOOKS = {
  flat = { rest = { 0.10, 0.18, 0.24 }, hover = { 0.13, 0.24, 0.31 }, edge = EDGE },
  primary = { rest = { 0.07, 0.38, 0.31 }, hover = { 0.09, 0.47, 0.39 }, edge = TEAL },
  segment = { rest = { 0.10, 0.18, 0.24 }, hover = { 0.13, 0.24, 0.31 } },
  ghost = {},
}

local function Press(b)
  local point, rel, relPoint, x, y = b.text:GetPoint(1)
  b.pressed = { point, rel, relPoint, x, y }
  b.text:SetPoint(point, rel, relPoint, x, y - 1)
end

local function Release(b)
  local p = b.pressed
  if p then b.text:SetPoint(p[1], p[2], p[3], p[4], p[5]) end
  b.pressed = nil
end

function LA.Button(parent, label, width, height, style, tip)
  local look = LOOKS[style or "flat"]
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(width, height)
  local fill = look.rest and Fill(b, 0, 0, 0, 0)
  local edges = look.edge and Border(b, look.edge)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("CENTER")
  b.text:SetText(label)

  local function Paint(hover)
    local l = b.selected and LOOKS.primary or look
    if fill then
      local c = hover and l.hover or l.rest
      fill:SetColorTexture(c[1], c[2], c[3], 1)
    else
      local c = hover and WHITE or MUTED
      b.text:SetTextColor(c[1], c[2], c[3])
    end
    if edges then SetBorder(edges, hover and TEAL or l.edge) end
  end
  Paint(false)

  function b.SetSelected(_, value)
    b.selected = value
    b:SetFrameLevel(parent:GetFrameLevel() + (value and 3 or 1))
    Paint(false)
  end

  b:SetScript("OnEnter", function(self)
    Paint(true)
    if tip and not self.clicked then
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetText(tip)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function(self)
    Paint(false)
    self.clicked = nil
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
  end)
  b:SetScript("PostClick", function(self)
    self.clicked = true
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
  end)
  b:SetScript("OnMouseDown", Press)
  b:SetScript("OnMouseUp", Release)
  return b
end

function LA.ButtonGroup(parent, items, height)
  local group = CreateFrame("Frame", nil, parent)
  local edge = CreateFrame("Frame", nil, group)
  edge:SetAllPoints()
  edge:SetFrameLevel(group:GetFrameLevel() + 5)
  Border(edge, TEAL, 0.75)
  local x = 0
  for i, item in ipairs(items) do
    local b = LA.Button(group, item[1], item[2], height, "segment", item[4])
    b:SetPoint("LEFT", x, 0)
    b:SetScript("OnClick", item[3])
    if i > 1 then
      local divider = edge:CreateTexture(nil, "OVERLAY")
      divider:SetColorTexture(EDGE[1], EDGE[2], EDGE[3], 1)
      divider:SetWidth(1)
      divider:SetPoint("TOP", group, "TOPLEFT", x, -1)
      divider:SetPoint("BOTTOM", group, "BOTTOMLEFT", x, 1)
    end
    x = x + item[2]
  end
  group:SetSize(x, height)
  return group
end

function LA.Caret(parent, color)
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

function LA.Menu(parent, anchor, names, width, onPick, color)
  local list = CreateFrame("Frame", nil, parent)
  list:SetSize(width, #names * 20 + 4)
  list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  list:SetFrameLevel(parent:GetFrameLevel() + 20)
  list:EnableMouse(true)
  list:Hide()
  Fill(list, 0.08, 0.14, 0.19, 1)
  Border(list, EDGE)
  for n, name in ipairs(names) do
    local item = CreateFrame("Button", nil, list)
    item:SetSize(width - 4, 20)
    item:SetPoint("TOPLEFT", 2, -2 - (n - 1) * 20)
    local text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 6, 0)
    text:SetText(name)
    local hi = Fill(item, 0, 0, 0, 0)
    item:SetScript("OnEnter", function()
      local c = color and color() or TEAL
      hi:SetColorTexture(c[1], c[2], c[3], 0.2)
    end)
    item:SetScript("OnLeave", function() hi:SetColorTexture(0, 0, 0, 0) end)
    item:SetScript("OnClick", function()
      list:Hide()
      onPick(n)
    end)
  end
  return list
end

local OPT_W = 150

local function BoxColor()
  return LA.active and LA.active.color or TEAL
end

local function Field(frame)
  Fill(frame, 0.04, 0.08, 0.11, 1)
  frame.edges = Border(frame, EDGE)
end

local function BuildOptions()
  local o = CreateFrame("Frame", nil, UIParent)
  o:SetSize(OPT_W, 52)
  o:SetFrameStrata("FULLSCREEN_DIALOG")
  o:SetFrameLevel(5000)
  o:EnableMouse(true)
  o:Hide()
  Fill(o, 0.06, 0.11, 0.15, 0.95)
  o.edges = Border(o, TEAL, 0.9)

  local drop = CreateFrame("Button", nil, o)
  drop:SetSize(OPT_W - 16, 18)
  drop:SetPoint("TOPLEFT", 8, -6)
  Field(drop)
  drop.text = drop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  drop.text:SetPoint("LEFT", 8, 0)
  LA.Caret(drop, MUTED):SetPoint("RIGHT", -8, 0)
  drop:SetScript("OnEnter", function() SetBorder(drop.edges, BoxColor()) end)
  drop:SetScript("OnLeave", function() SetBorder(drop.edges, EDGE) end)
  o.drop = drop
  o.list = LA.Menu(o, drop, { "Grow up", "Grow down" }, OPT_W - 16, function(n)
    if LA.active then
      LA.SetGrowDown(LA.active, n == 2)
      LA.RefreshOptions()
    end
  end, BoxColor)
  drop:SetScript("OnClick", function() o.list:SetShown(not o.list:IsShown()) end)

  local function Number(label, x)
    local text = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", x, -32)
    text:SetText(label)
    text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    local e = CreateFrame("EditBox", nil, o)
    e:SetSize(52, 18)
    e:SetPoint("TOPLEFT", x + 11, -28)
    e:SetFontObject("GameFontHighlightSmall")
    e:SetTextInsets(6, 4, 0, 0)
    e:SetAutoFocus(false)
    e:SetNumeric(true)
    e:SetMaxLetters(5)
    Field(e)
    e:SetScript("OnEditFocusGained", function(self) SetBorder(self.edges, BoxColor()) end)
    e:SetScript("OnEditFocusLost", function(self)
      SetBorder(self.edges, EDGE)
      self:HighlightText(0, 0)
    end)
    e:SetScript("OnEnterPressed", function(self)
      LA.SetPosition(o.x:GetNumber(), o.y:GetNumber())
      self:ClearFocus()
    end)
    e:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
      LA.RefreshOptions()
    end)
    return e
  end
  o.x, o.y = Number("X", 8), Number("Y", 79)

  o:SetScript("OnHide", function()
    o.list:Hide()
    o.x:ClearFocus()
    o.y:ClearFocus()
  end)
  options = o
  return o
end

local function UpdateXY()
  local h = LA.active and LA.active.handle
  if not (options and options:IsShown() and h and h:GetLeft()) then return end
  if not options.x:HasFocus() then options.x:SetText(math.floor(h:GetLeft() + 0.5)) end
  if not options.y:HasFocus() then options.y:SetText(math.floor(h:GetBottom() + 0.5)) end
end

function LA.RefreshOptions()
  local t = LA.active
  local h = t and t.handle
  if not (h and h:IsShown() and h:GetRight()) then
    if options then options:Hide() end
    return
  end
  local o = options or BuildOptions()
  SetBorder(o.edges, t.color, 0.9)
  o.drop.text:SetText(LA.db[t.growKey] and "Grow down" or "Grow up")
  o:ClearAllPoints()
  if h:GetRight() + 28 + OPT_W <= UIParent:GetWidth() then
    o:SetPoint("LEFT", h, "RIGHT", 28, 0)
  else
    o:SetPoint("RIGHT", h, "LEFT", -28, 0)
  end
  o:Show()
  UpdateXY()
end

local function RefreshBoxes()
  for _, t in ipairs(targets) do
    if t.handle then
      local active = LA.active == t
      SetBorder(t.edges, t.color, (active or t.hover) and 1 or 0.75)
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

local function ShowGuides(snapX, snapY)
  guideV:SetAlpha(snapX and 0.95 or 0.18)
  guideH:SetAlpha(snapY and 0.95 or 0.18)
end

local function Nearest(v, list)
  local best, dist = nil, LA.SNAP_DIST + 0.001
  for _, c in ipairs(list) do
    local d = math.abs(v - c)
    if d < dist then best, dist = c, d end
  end
  return best
end

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

local function Repeat(btn, dx, dy)
  local since = 0
  local function Stop(self) self:SetScript("OnUpdate", nil) end
  btn:SetScript("OnMouseDown", function(self)
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
  btn:SetScript("OnMouseUp", Stop)
  btn:SetScript("OnHide", Stop)
end

local PAD = {
  { -1, 0, math.pi * 1.5, "RIGHT", "LEFT", -4, 0 },
  { 1, 0, math.pi / 2, "LEFT", "RIGHT", 4, 0 },
  { 0, 1, math.pi, "BOTTOM", "TOP", 0, 4 },
  { 0, -1, 0, "TOP", "BOTTOM", 0, -4 },
}

local function MakeHandle(t)
  local h = CreateFrame("Frame", nil, UIParent)
  h:SetSize(W, H)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(true)
  h:RegisterForDrag("LeftButton")
  h:Hide()
  Fill(h, 0.06, 0.11, 0.15, 0.88)

  local c = t.color
  t.edges = Border(h, c, 0.75)

  local label = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint(t.labelAt, 0, t.labelAt == "TOP" and -8 or 8)
  label:SetText(t.label)
  label:SetTextColor(c[1], c[2], c[3])

  t.pad = CreateFrame("Frame", nil, h)
  t.pad:SetAllPoints()
  t.pad:Hide()
  t.padButtons = {}
  for _, a in ipairs(PAD) do
    local btn = CreateFrame("Button", nil, t.pad)
    btn:SetSize(18, 18)
    btn:SetPoint(a[4], h, a[5], a[6], a[7])
    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetRotation(a[3])
    icon:SetDesaturated(true)
    icon:SetVertexColor(c[1], c[2], c[3])
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    Repeat(btn, a[1], a[2])
    t.padButtons[#t.padButtons + 1] = btn
  end

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
      UpdateXY()
    end)
  end)
  h:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    ShowGuides(false, false)
    LA.db[t.key] = { x = self:GetLeft(), y = self:GetBottom() }
    LA.Place(t)
    LA.RefreshOptions()
  end)
  t.handle = h
  return h
end

local function PositionHandle(t)
  local h = t.handle or MakeHandle(t)
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

function LA.SetPosition(x, y)
  if LA.active and LA.active.handle then Move(LA.active, x, y) end
end

function LA.Nudge(dx, dy)
  local t = LA.active
  local h = t and t.handle
  if not (h and h:GetLeft()) then return end
  local px = 1 / UIParent:GetEffectiveScale()
  Move(t, h:GetLeft() + dx * px, h:GetBottom() + dy * px)
end

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

local function MouseOver(frame)
  return frame and frame:IsVisible() and frame:IsMouseOver()
end

local function OverUI()
  if not toolbar then return false end
  if MouseOver(toolbar) or MouseOver(toolbar.editBar) or MouseOver(options) or MouseOver(options and options.list) then
    return true
  end
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

local function BuildChrome()

  overlay = CreateFrame("Frame", nil, UIParent)
  overlay:SetAllPoints(UIParent)
  overlay:SetFrameStrata("FULLSCREEN")
  overlay:Hide()
  Fill(overlay, 0, 0, 0, 0.35)

  guideV = overlay:CreateTexture(nil, "ARTWORK")
  guideV:SetColorTexture(TEAL[1], TEAL[2], TEAL[3], 1)
  guideV:SetWidth(1)
  guideV:SetPoint("TOP")
  guideV:SetPoint("BOTTOM")
  guideH = overlay:CreateTexture(nil, "ARTWORK")
  guideH:SetColorTexture(TEAL[1], TEAL[2], TEAL[3], 1)
  guideH:SetHeight(1)
  guideH:SetPoint("LEFT")
  guideH:SetPoint("RIGHT")
  ShowGuides(false, false)

  toolbar = CreateFrame("Frame", nil, UIParent)
  toolbar:SetSize(312, 40)
  toolbar:SetFrameStrata("FULLSCREEN_DIALOG")
  toolbar:SetClampedToScreen(true)
  toolbar:SetMovable(true)
  toolbar:EnableMouse(true)
  toolbar:RegisterForDrag("LeftButton")
  toolbar:Hide()
  local saved = LA.db.toolbar
  if saved then
    toolbar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
  else
    toolbar:SetPoint("TOP", UIParent, "TOP", 0, 0)
  end
  toolbar:SetScript("OnDragStart", toolbar.StartMoving)
  toolbar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetLeft(), self:GetTop()
    if x then
      LA.db.toolbar = { x = x, y = y }
      self:ClearAllPoints()
      self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    end
  end)
  Fill(toolbar, 0.06, 0.11, 0.15, 0.88)
  local barEdges = Border(toolbar, TEAL, 0.75)
  toolbar:SetScript("OnEnter", function() SetBorder(barEdges, TEAL, 1) end)
  toolbar:SetScript("OnLeave", function() SetBorder(barEdges, TEAL, 0.75) end)

  local title = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("LEFT", 12, 0)
  title:SetText("LootAnchor")
  title:SetTextColor(TEAL[1], TEAL[2], TEAL[3])

  toolbar.editTab = LA.Button(toolbar, "Edit", 46, 24, "flat", "Move the boxes.")
  toolbar.editTab:SetPoint("LEFT", 104, 0)
  toolbar.editTab:SetScript("OnClick", function() LA.SetMode("edit") end)
  toolbar.testTab = LA.Button(toolbar, "Test", 46, 24, "flat", "Try the loot rolls and popups with your current settings.")
  toolbar.testTab:SetPoint("LEFT", toolbar.editTab, "RIGHT", -1, 0)
  toolbar.testTab:SetScript("OnClick", function() LA.SetMode("test") end)

  local save = LA.Button(toolbar, "Save & Exit", 96, 24, "primary", "Keep your changes and close LootAnchor.")
  save:SetPoint("RIGHT", -8, 0)
  save:SetScript("OnClick", function() LA.Toggle() end)

  local function SubBar()
    local f = CreateFrame("Frame", nil, toolbar)
    f:SetHeight(32)
    f:SetPoint("TOP", toolbar, "BOTTOM", 0, -4)
    f:EnableMouse(true)
    f:Hide()
    Fill(f, 0.06, 0.11, 0.15, 0.88)
    Border(f, EDGE)
    return f
  end

  toolbar.editBar = SubBar()
  local group = LA.ButtonGroup(toolbar.editBar, {
    { "Reset", 60, LA.RevertAll, "Undo your changes since opening LootAnchor." },
    { "Defaults", 72, LA.DefaultsAll, "Reset to Blizzard's initial location." },
  }, 22)
  group:SetPoint("LEFT", 8, 0)
  toolbar.editBar:SetWidth(group:GetWidth() + 16)

  toolbar.testBar = SubBar()
  toolbar.testBar:SetWidth(LA.BuildTestControls(toolbar.testBar))
end

function LA.SetMode(mode)
  if not LA.open then return end
  local editing = mode == "edit"
  LA.mode, LA.unlocked, LA.active = mode, editing, nil
  keys:SetShown(editing)
  keys:EnableKeyboard(editing and not InCombatLockdown())
  overlay:SetShown(editing)
  for _, t in ipairs(targets) do
    if editing then PositionHandle(t) end
    if t.handle then t.handle:SetShown(editing) end
  end
  RefreshBoxes()
  toolbar.editTab:SetSelected(editing)
  toolbar.testTab:SetSelected(not editing)
  toolbar.editBar:SetShown(editing)
  toolbar.testBar:SetShown(not editing)
  if editing then
    LA.HideTests()
  else
    LA.Apply()
  end
end

function LA.Toggle()
  if not overlay then BuildChrome() end
  if LA.open then
    LA.SetMode("test")
    LA.open, LA.mode = false, nil
    LA.HideTests()
    toolbar:Hide()
    return
  end

  LA.snapshot = {}
  for _, t in ipairs(targets) do
    local s = LA.db[t.key]
    LA.snapshot[t.key] = { x = s and s.x, y = s and s.y, grow = LA.db[t.growKey] }
  end
  LA.open = true
  toolbar:Show()
  LA.SetMode("edit")
end
