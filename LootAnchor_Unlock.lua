-- The unlock screen: dimmed screen, one box per frame, snapping, and the toolbar.
LootAnchor = LootAnchor or {}
local LA = LootAnchor
local W, H, SNAP, SNAP_DIST, TEAL = LA.W, LA.H, LA.SNAP, LA.SNAP_DIST, LA.TEAL
local targets = LA.targets

local topLevel = 10
local overlay, toolbar
local guideV, guideH -- centre lines of the screen, made in BuildChrome

local function Border(frame, r, g, b, a)
  local edges = {}
  for i = 1, 4 do
    edges[i] = frame:CreateTexture(nil, "BORDER")
    edges[i]:SetColorTexture(r, g, b, a)
  end
  edges[1]:SetPoint("TOPLEFT");     edges[1]:SetPoint("TOPRIGHT");     edges[1]:SetHeight(1)
  edges[2]:SetPoint("BOTTOMLEFT");  edges[2]:SetPoint("BOTTOMRIGHT");  edges[2]:SetHeight(1)
  edges[3]:SetPoint("TOPLEFT");     edges[3]:SetPoint("BOTTOMLEFT");   edges[3]:SetWidth(1)
  edges[4]:SetPoint("TOPRIGHT");    edges[4]:SetPoint("BOTTOMRIGHT");  edges[4]:SetWidth(1)
  return edges
end

local function SetBorder(edges, r, g, b, a)
  for _, e in ipairs(edges) do e:SetColorTexture(r, g, b, a) end
end

local function ShowGuides(snapX, snapY)
  if guideV then guideV:SetAlpha(snapX and 0.95 or 0.18) end
  if guideH then guideH:SetAlpha(snapY and 0.95 or 0.18) end
end

-- Snap a box (left, bottom) to the screen edges, the screen centre and the other box.
local function Snap(t, left, bottom)
  local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
  local cx, cy = sw / 2 - W / 2, sh / 2 - H / 2
  local xs, ys = { 0, cx, sw - W }, { 0, cy, sh - H }
  for _, o in ipairs(targets) do
    local oh = o.handle
    if o ~= t and oh and oh:IsShown() and oh:GetLeft() and oh:GetBottom() then
      local ol, ob = oh:GetLeft(), oh:GetBottom()
      xs[#xs + 1] = ol; xs[#xs + 1] = ol + W; xs[#xs + 1] = ol - W
      ys[#ys + 1] = ob; ys[#ys + 1] = ob + H; ys[#ys + 1] = ob - H
    end
  end
  local function Nearest(v, list)
    local best, dist = nil, SNAP_DIST + 0.001
    for _, cand in ipairs(list) do
      local d = math.abs(v - cand)
      if d < dist then best, dist = cand, d end
    end
    return best
  end
  local x, y = Nearest(left, xs), Nearest(bottom, ys)
  local onX, onY = x and math.abs(x - cx) < 0.5, y and math.abs(y - cy) < 0.5
  x = x or math.floor(left / SNAP + 0.5) * SNAP
  y = y or math.floor(bottom / SNAP + 0.5) * SNAP
  x = math.max(0, math.min(sw - W, x))
  y = math.max(0, math.min(sh - H, y))
  return x, y, onX, onY
end

local function MakeHandle(t)
  local h = CreateFrame("Frame", nil, UIParent)
  h:SetSize(W, H)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:SetMovable(true)
  h:EnableMouse(true)
  h:RegisterForDrag("LeftButton")
  h:Hide()

  local bg = h:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.06, 0.11, 0.15, 0.88)

  -- Each box has its own colour and its label on its own edge (top / bottom),
  -- so two overlapping boxes stay readable; the one you touch comes to the front.
  local r, g, b = t.color[1], t.color[2], t.color[3]
  local edges = Border(h, r, g, b, 0.75)
  local function Raise()
    topLevel = topLevel + 1
    h:SetFrameLevel(topLevel)
  end
  h:SetScript("OnEnter", function() SetBorder(edges, r, g, b, 1); Raise() end)
  h:SetScript("OnLeave", function() SetBorder(edges, r, g, b, 0.75) end)

  local text = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint(t.labelAt, 0, t.labelAt == "TOP" and -8 or 8)
  text:SetText(t.label)
  text:SetTextColor(r, g, b)

  -- The loot roll box carries the grow direction option itself.
  if t.key == "roll" then
    local arrow = LA.GrowButton(h)
    LA.growCheck = arrow
  end

  -- Dragging is done by hand so the box can snap while it moves.
  h:SetScript("OnDragStart", function(self)
    Raise()
    local scale = UIParent:GetEffectiveScale()
    local mx, my = GetCursorPosition()
    local grabX, grabY = mx / scale - self:GetLeft(), my / scale - self:GetBottom()
    self:SetScript("OnUpdate", function(box)
      local cx, cy = GetCursorPosition()
      local x, y, onX, onY = Snap(t, cx / scale - grabX, cy / scale - grabY)
      box:ClearAllPoints()
      box:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
      ShowGuides(onX, onY)
    end)
  end)
  h:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    ShowGuides(false, false)
    LA.db[t.key] = { x = self:GetLeft(), y = self:GetBottom() }
    LA.Place(t)
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
  elseif f and f:GetCenter() and f:GetBottom() then
    h:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", f:GetCenter() - W / 2, f:GetBottom())
  else
    h:SetPoint("CENTER")
  end
end

-- Move the boxes to wherever the frames are now (after Reset / Defaults).
function LA.RefreshHandles()
  if not LA.unlocked then return end
  local function Apply()
    if not LA.unlocked then return end
    if LA.growCheck then LA.growCheck:Refresh() end
    for _, t in ipairs(targets) do PositionHandle(t) end
  end
  Apply()
  if C_Timer and C_Timer.After then
    C_Timer.After(0.1, Apply)
    C_Timer.After(0.5, Apply)
  end
end

local function BuildChrome()
  -- Dim screen. Mouse is not captured, so the game stays usable underneath.
  overlay = CreateFrame("Frame", nil, UIParent)
  overlay:SetAllPoints(UIParent)
  overlay:SetFrameStrata("FULLSCREEN")
  overlay:Hide()

  local dim = overlay:CreateTexture(nil, "BACKGROUND")
  dim:SetAllPoints()
  dim:SetColorTexture(0, 0, 0, 0.35)

  -- Centre lines: faint while idle, bright while a box is snapped to the centre.
  guideV = overlay:CreateTexture(nil, "ARTWORK")
  guideV:SetColorTexture(TEAL[1], TEAL[2], TEAL[3], 1)
  guideV:SetWidth(1)
  guideV:SetPoint("TOP", overlay, "TOP", 0, 0)
  guideV:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 0)
  guideH = overlay:CreateTexture(nil, "ARTWORK")
  guideH:SetColorTexture(TEAL[1], TEAL[2], TEAL[3], 1)
  guideH:SetHeight(1)
  guideH:SetPoint("LEFT", overlay, "LEFT", 0, 0)
  guideH:SetPoint("RIGHT", overlay, "RIGHT", 0, 0)
  ShowGuides(false, false)

  -- Top toolbar.
  toolbar = CreateFrame("Frame", nil, UIParent)
  toolbar:SetSize(420, 40)
  toolbar:SetPoint("TOP", UIParent, "TOP", 0, 0)
  toolbar:SetFrameStrata("FULLSCREEN_DIALOG")
  toolbar:Hide()

  -- Drag the bar anywhere empty (title area); the spot is remembered.
  toolbar:SetMovable(true)
  toolbar:SetClampedToScreen(true)
  toolbar:EnableMouse(true)
  toolbar:RegisterForDrag("LeftButton")
  toolbar:SetScript("OnDragStart", toolbar.StartMoving)
  toolbar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetLeft(), self:GetTop()
    if x and y then
      LA.db.toolbar = { x = x, y = y }
      self:ClearAllPoints()
      self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    end
  end)
  local tp = LA.db.toolbar
  if tp then
    toolbar:ClearAllPoints()
    toolbar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", tp.x, tp.y)
  end

  local bg = toolbar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.06, 0.11, 0.15, 0.88)
  local barEdges = Border(toolbar, TEAL[1], TEAL[2], TEAL[3], 0.75)
  toolbar:SetScript("OnEnter", function() SetBorder(barEdges, TEAL[1], TEAL[2], TEAL[3], 1) end)
  toolbar:SetScript("OnLeave", function() SetBorder(barEdges, TEAL[1], TEAL[2], TEAL[3], 0.75) end)

  local title = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("LEFT", 12, 0)
  title:SetText("LootAnchor")
  title:SetTextColor(TEAL[1], TEAL[2], TEAL[3])

  local save = LA.Button(toolbar, "Save & Exit", 100)
  save:SetPoint("RIGHT", -8, 0)
  save:SetScript("OnClick", function() LA.Toggle() end)

  local function Tip(btn, text)
    btn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetText(text)
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
  end

  local defaults = LA.Button(toolbar, "Defaults", 80)
  defaults:SetPoint("RIGHT", save, "LEFT", -6, 0)
  defaults:SetScript("OnClick", LA.DefaultsAll)
  Tip(defaults, "Reset to Blizzard's initial location.")

  local reset = LA.Button(toolbar, "Reset", 70)
  reset:SetPoint("RIGHT", defaults, "LEFT", -6, 0)
  reset:SetScript("OnClick", LA.RevertAll)
  Tip(reset, "Undo your changes since opening this screen.")
end

function LA.Toggle()
  LA.unlocked = not LA.unlocked
  local unlocked = LA.unlocked
  if unlocked then
    LA.snapshot = {}
    LA.snapGrow = LA.db.growDown
    for _, t in ipairs(targets) do
      local s = LA.db[t.key]
      LA.snapshot[t.key] = s and { x = s.x, y = s.y } or nil
    end
  end
  if not overlay then BuildChrome() end
  overlay:SetShown(unlocked)
  toolbar:SetShown(unlocked)

  for _, t in ipairs(targets) do
    local h = t.handle or MakeHandle(t)
    if unlocked then PositionHandle(t) end
    h:SetShown(unlocked)
  end
end
