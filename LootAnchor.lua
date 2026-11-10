LootAnchor = LootAnchor or {}
local LA = LootAnchor

LA.W, LA.H = 220, 60
LA.SNAP = 10
LA.SNAP_DIST = 14
LA.TEAL = { 0.10, 0.85, 0.68 }
LA.unlocked = false

local busy = false

local FALLBACK = { n = 5, "BOTTOM", UIParent, "BOTTOM", 0, 128 }

local targets = {
  { key = "roll", label = "Loot Rolls", color = LA.TEAL, labelAt = "TOP",
    growKey = "growDown", get = function() return GroupLootContainer end },
  { key = "alert", label = "You Received & Achievements", color = { 1.0, 0.72, 0.2 }, labelAt = "BOTTOM",
    growKey = "growDownAlert", get = function() return AlertFrame end },
}
LA.targets = targets

local function Remember(t, ...)
  local rel = select(2, ...)
  if rel and rel == t.anchor then return end
  if t.clearing or not t.blizz then
    t.blizz, t.clearing = {}, false
  end
  local a = { n = select("#", ...), ... }
  for i, old in ipairs(t.blizz) do
    if old[1] == a[1] then t.blizz[i] = a return end
  end
  t.blizz[#t.blizz + 1] = a
end

local function Capture(t)
  local f = t.get()
  if t.blizz or t.moved or not f then return end
  for i = 1, f:GetNumPoints() do Remember(t, f:GetPoint(i)) end
end

function LA.Place(t)
  local f, pos = t.get(), LA.db and LA.db[t.key]
  if not (f and pos) then return end
  Capture(t)
  local anchor = t.anchor
  if not anchor then
    anchor = CreateFrame("Frame", nil, UIParent)
    anchor:SetSize(LA.W, LA.H)
    t.anchor = anchor
  end
  if t.x ~= pos.x or t.y ~= pos.y then
    anchor:ClearAllPoints()
    anchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    t.x, t.y = pos.x, pos.y
  end
  t.moved = true
  local edge = LA.db[t.growKey] and "TOP" or "BOTTOM"
  local point, rel = f:GetPoint(1)
  if f:GetNumPoints() == 1 and point == edge and rel == anchor then return end
  busy = true
  f.ignoreFramePositionManager = true
  f:ClearAllPoints()
  f:SetPoint(edge, anchor, edge, 0, 0)
  busy = false
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

function LA.DefaultsAll()
  local db = LA.db
  local bar, seconds = db.toolbar, db.testDuration
  wipe(db)
  db.toolbar, db.testDuration = bar, seconds
  for _, t in ipairs(targets) do RestoreDefault(t) end
  RelayoutBlizzard()
  LA.RefreshHandles()
end

function LA.RevertAll()
  local db, snap = LA.db, LA.snapshot or {}
  for _, t in ipairs(targets) do
    local s = snap[t.key]
    db[t.growKey] = s and s.grow or nil
    if s and s.x then
      db[t.key] = { x = s.x, y = s.y }
    else
      db[t.key] = nil
      RestoreDefault(t)
    end
  end
  RelayoutBlizzard()
  for _, t in ipairs(targets) do LA.Place(t) end
  LA.RefreshHandles()
end

local function Swap(s)
  if s:find("BOTTOM") then return (s:gsub("BOTTOM", "TOP")) end
  return (s:gsub("TOP", "BOTTOM"))
end

-- Blizzard stacks upward. Grow-down flips TOP/BOTTOM and the offset.
-- Alerts may keep our last SetPoint and add Blizzard's on top (no ClearAllPoints);
-- keep Blizzard's point and flip that one.
local function Mirror(frame, want)
  local n, mark = frame:GetNumPoints(), frame.laMirrored
  if n == 0 or n > 2 or (n == 2 and not mark) then return end

  local p, rel, rp, x, y
  for i = 1, n do
    local a, b, c, dx, dy = frame:GetPoint(i)
    if not (mark and a == mark[1] and b == mark[2] and c == mark[3] and dx == mark[4] and dy == mark[5]) then
      p, rel, rp, x, y = a, b, c, dx, dy
    end
  end
  frame.laMirrored = nil
  if not p then
    if want then
      frame.laMirrored = mark
      return
    end
    p, rel, rp, x, y = Swap(mark[1]), mark[2], Swap(mark[3]), mark[4], -mark[5]
  elseif want then
    p, rp, y = Swap(p), Swap(rp), -y
    frame.laMirrored = { p, rel, rp, x, y }
  elseif n == 1 then
    return
  end
  frame:ClearAllPoints()
  frame:SetPoint(p, rel, rp, x, y)
end

local function MirrorStacks()
  local db = LA.db
  if GroupLootContainer and GroupLootContainer.rollFrames then
    for _, frame in pairs(GroupLootContainer.rollFrames) do Mirror(frame, db.growDown) end
  end
  for _, sub in ipairs(AlertFrame and AlertFrame.alertFrameSubSystems or {}) do
    local pool = sub.alertFramePool
    if pool and pool.EnumerateActive then
      for frame in pool:EnumerateActive() do Mirror(frame, db.growDownAlert) end
    end
  end
end

local function PlaceAll()
  if LA.unlocked or not LA.db then return end
  for _, t in ipairs(targets) do LA.Place(t) end
end

function LA.Apply()
  if not LA.db then return end
  MirrorStacks()
  PlaceAll()
end

function LA.SetGrowDown(t, value)
  LA.db[t.growKey] = value and true or nil
  RelayoutBlizzard()
  LA.Apply()
end

local layoutHooked, alertHooked = false, false

local function InstallHooks()
  for _, t in ipairs(targets) do
    local f = t.get()
    if f and not t.hooked then
      t.hooked = true
      Capture(t)
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
  if not layoutHooked then
    layoutHooked = true
    for _, name in ipairs({ "UIParent_ManageFramePositions", "AlertFrame_FixAnchors", "GroupLootContainer_Update" }) do
      if type(_G[name]) == "function" then hooksecurefunc(name, LA.Apply) end
    end
  end
  if not alertHooked and AlertFrame and type(AlertFrame.UpdateAnchors) == "function" then
    alertHooked = true
    hooksecurefunc(AlertFrame, "UpdateAnchors", LA.Apply)
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
    LA.BuildPanel()
  end
  if not LA.db then return end
  InstallHooks()
  PlaceAll()
  C_Timer.After(1, PlaceAll)
  C_Timer.After(4, PlaceAll)
end)
