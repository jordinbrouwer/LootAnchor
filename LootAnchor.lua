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
    t.anchor:SetSize(W, 1)
  end
  t.anchor:ClearAllPoints()
  t.anchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
  busy = true
  f.ignoreFramePositionManager = true
  f:ClearAllPoints()
  f:SetPoint("BOTTOM", t.anchor, "BOTTOM", 0, 0)
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
  local bar = db.toolbar -- the toolbar position is not a loot position
  wipe(db)
  db.toolbar = bar
  for _, t in ipairs(targets) do RestoreDefault(t) end
  RelayoutBlizzard()
  LA.RefreshHandles()
end

-- Reset: back to how it was when the unlock screen opened.
function LA.RevertAll()
  local db, snapshot = LA.db, LA.snapshot
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

local function PlaceAll()
  if LA.unlocked then return end
  for _, t in ipairs(targets) do LA.Place(t) end
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
    if type(_G[name]) == "function" then hooksecurefunc(name, PlaceAll) end
  end
  if AlertFrame and type(AlertFrame.UpdateAnchors) == "function" then
    hooksecurefunc(AlertFrame, "UpdateAnchors", PlaceAll)
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
