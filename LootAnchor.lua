-- LootAnchor: moves Blizzard's own frames: GroupLootContainer (roll windows) and AlertFrame ("You received").
-- This file holds the shared state and the placing logic; the unlock screen, settings panel
-- and slash command live in LootAnchor_Unlock.lua, LootAnchor_Panel.lua and LootAnchor_Command.lua.
LootAnchor = LootAnchor or {}
local LA = LootAnchor

LA.W, LA.H = 220, 60
LA.SNAP = 10        -- positions fall on this pixel grid when nothing else is close
LA.SNAP_DIST = 14   -- how close (pixels) a box must be to snap to an edge or the centre
LA.TEAL = { 0.10, 0.85, 0.68 }
LA.unlocked = false
LA.snapshot = nil   -- positions as they were when the unlock screen opened

local W = LA.W
local busy = false

-- Used by Defaults when Blizzard never told us where a frame belongs
-- (GroupLootContainer has no anchor until a roll shows up).
local FALLBACK = { n = 5, "BOTTOM", UIParent, "BOTTOM", 0, 128 }

local targets = {
  { key = "roll",  label = "Loot Rolls",   color = LA.TEAL,            labelAt = "TOP",    get = function() return GroupLootContainer end },
  { key = "alert", label = "You Received", color = { 1.0, 0.72, 0.2 }, labelAt = "BOTTOM", get = function() return AlertFrame end },
}
LA.targets = targets

function LA.Button(parent, label, width)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 22)
  b:SetText(label)
  return b
end

-- Grow direction arrow, in the top right corner of the Loot Rolls box of the unlock screen.
-- Up arrow = rolls grow up (Blizzard's default), down arrow = rolls grow down.
function LA.GrowButton(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(22, 22)
  local function Refresh()
    local dir = (LA.db and LA.db.growDown) and "Down" or "Up"
    b:SetNormalTexture("Interface\\Buttons\\Arrow-" .. dir .. "-Up")
    b:SetPushedTexture("Interface\\Buttons\\Arrow-" .. dir .. "-Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    -- The up arrow is drawn lower in its texture than the down arrow; nudge it so both sit alike.
    b:ClearAllPoints()
    b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, dir == "Down" and -4 or 3)
  end
  b.Refresh = Refresh
  Refresh()
  b:SetScript("OnShow", Refresh)
  b:SetScript("OnClick", function()
    LA.SetGrowDown(not (LA.db and LA.db.growDown))
    Refresh()
    if GameTooltip:GetOwner() == b then b:GetScript("OnEnter")(b) end
  end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    if LA.db and LA.db.growDown then
      GameTooltip:SetText("Loot rolls grow down. Click to grow up.")
    else
      GameTooltip:SetText("Loot rolls grow up. Click to grow down.")
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

-- t.blizz = the anchors Blizzard itself last asked for (never our own), so Defaults
-- can put a frame back exactly where Blizzard wants it.
local function Remember(t, ...)
  -- Ignore anchors that point at our own anchor frame: Blizzard's frame manager
  -- replays a frame's current anchor, which would otherwise pass for "Blizzard's".
  local rel = select(2, ...)
  if rel and rel == t.anchor then return end
  if t.clearing or not t.blizz then
    t.blizz = {}
    t.clearing = false
  end
  local a = { n = select("#", ...), ... }
  for i, old in ipairs(t.blizz) do
    if old[1] == a[1] then t.blizz[i] = a return end
  end
  t.blizz[#t.blizz + 1] = a
end

-- Read the frame's starting anchors, in case Blizzard set them before we hooked in.
local function Capture(t)
  local f = t.get()
  if t.blizz or t.moved or not f or f:GetNumPoints() == 0 then return end
  for i = 1, f:GetNumPoints() do Remember(t, f:GetPoint(i)) end
end

function LA.Place(t)
  local f, pos = t.get(), LA.db and LA.db[t.key]
  if not (f and pos) then return end
  Capture(t)
  if not t.anchor then
    t.anchor = CreateFrame("Frame", nil, UIParent)
    t.anchor:SetSize(W, LA.H)
  end
  t.anchor:ClearAllPoints()
  t.anchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
  busy = true
  f.ignoreFramePositionManager = true
  f:ClearAllPoints()
  local edge = (t.key == "roll" and LA.db.growDown) and "TOP" or "BOTTOM"
  f:SetPoint(edge, t.anchor, edge, 0, 0)
  busy = false
  t.moved = true
end

local function RestoreDefault(t)
  local f = t.get()
  if not (f and t.moved) then return end
  t.moved = false
  f.ignoreFramePositionManager = nil
  busy = true
  f:ClearAllPoints()
  if t.blizz and #t.blizz > 0 then
    for _, a in ipairs(t.blizz) do f:SetPoint(unpack(a, 1, a.n)) end
  else
    f:SetPoint(unpack(FALLBACK, 1, FALLBACK.n))
  end
  busy = false
end

-- Let Blizzard lay its frames out again.
local function RelayoutBlizzard()
  if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions) end
  if AlertFrame and AlertFrame.UpdateAnchors then
    pcall(AlertFrame.UpdateAnchors, AlertFrame)
  elseif AlertFrame_FixAnchors then
    pcall(AlertFrame_FixAnchors)
  end
  if GroupLootContainer_Update and GroupLootContainer then
    pcall(GroupLootContainer_Update, GroupLootContainer)
  end
end

-- Defaults: back to Blizzard's own positions.
function LA.DefaultsAll()
  local db = LA.db
  local bar = db.toolbar -- the toolbar position is not a loot position, so Defaults keeps it
  wipe(db)              -- (this also sets the rolls back to growing up, Blizzard's default)
  db.toolbar = bar
  for _, t in ipairs(targets) do RestoreDefault(t) end
  RelayoutBlizzard()
  LA.RefreshHandles()
end

-- Reset: back to how it was when the unlock screen opened.
function LA.RevertAll()
  local db, snapshot = LA.db, LA.snapshot
  db.growDown = LA.snapGrow
  for _, t in ipairs(targets) do
    local s = snapshot and snapshot[t.key]
    if s then
      db[t.key] = { x = s.x, y = s.y }
    else
      db[t.key] = nil
      RestoreDefault(t)
    end
  end
  RelayoutBlizzard()
  for _, t in ipairs(targets) do
    if db[t.key] then LA.Place(t) end
  end
  LA.RefreshHandles()
end

-- Grow down (loot rolls only): Blizzard stacks each roll frame on top of the previous one.
-- After every layout pass, mirror those anchors (TOP <-> BOTTOM, offset flipped) so the stack
-- builds downwards from the box instead. A frame is only mirrored once per Blizzard layout.
-- The "You received" popups are never touched.
local function Swap(s)
  if s:find("BOTTOM") then return (s:gsub("BOTTOM", "TOP")) end
  return (s:gsub("TOP", "BOTTOM"))
end

local function Mirror(frame)
  if not frame or frame:GetNumPoints() ~= 1 then return end
  local p, rel, rp, x, y = frame:GetPoint(1)
  local mark = frame.laMirrored
  if mark and mark[1] == p and mark[2] == rel and mark[3] == rp and mark[4] == x and mark[5] == y then return end
  local np, nrp, ny = Swap(p), Swap(rp or p), -(y or 0)
  frame:ClearAllPoints()
  frame:SetPoint(np, rel, nrp, x or 0, ny)
  frame.laMirrored = { np, rel, nrp, x or 0, ny }
end

local function MirrorStacks()
  if not (LA.db and LA.db.growDown) then return end
  if GroupLootContainer and GroupLootContainer.rollFrames then
    for _, frame in pairs(GroupLootContainer.rollFrames) do Mirror(frame) end
  end
end

local function PlaceAll()
  if LA.unlocked then return end
  for _, t in ipairs(targets) do LA.Place(t) end
end

local function AfterLayout()
  MirrorStacks()
  PlaceAll()
end

-- Loot roll grow direction: down (true) or up (false, Blizzard default).
function LA.SetGrowDown(value)
  LA.db.growDown = value and true or nil
  RelayoutBlizzard()
  AfterLayout()
end

local hooked = false
local function InstallHooks()
  if hooked then return end
  hooked = true
  -- Blizzard re-anchors these frames on layout passes; put them back every time.
  for _, t in ipairs(targets) do
    Capture(t)
    local f = t.get()
    if f then
      hooksecurefunc(f, "ClearAllPoints", function()
        if not busy then t.clearing = true end
      end)
      hooksecurefunc(f, "SetPoint", function(_, ...)
        if busy then return end
        Remember(t, ...)
        if not LA.unlocked then LA.Place(t) end
      end)
    end
  end
  for _, name in ipairs({ "UIParent_ManageFramePositions", "AlertFrame_FixAnchors", "GroupLootContainer_Update" }) do
    if type(_G[name]) == "function" then hooksecurefunc(name, AfterLayout) end
  end
  if AlertFrame and type(AlertFrame.UpdateAnchors) == "function" then
    hooksecurefunc(AlertFrame, "UpdateAnchors", AfterLayout)
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    LootAnchorDB = LootAnchorDB or {}
    LA.db = LootAnchorDB
    InstallHooks()
    LA.BuildPanel()
  end
  if not LA.db then return end
  PlaceAll()
  -- Other UI code may lay out after us during login / reload; apply again shortly after.
  if C_Timer and C_Timer.After then
    C_Timer.After(1, PlaceAll)
    C_Timer.After(4, PlaceAll)
  end
end)
