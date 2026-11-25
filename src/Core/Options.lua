-- The saved settings (LootAnchorDB): per target ("roll", "alert") its position { x, y } and whether it grows down
-- (growDown, growDownAlert); the position of the panel (toolbar); how long test windows stay (testDuration).
local LA = LootAnchor

-- DB_VERSION goes up when settings are renamed or removed; the steps run once.
local DB_VERSION = 2

local function Migrate(db)
  if (db.DbVersion or 0) >= DB_VERSION then return end
  db.DbVersion = DB_VERSION
end

LA.On("PLAYER_LOGIN", function()
  LootAnchorDB = LootAnchorDB or {}
  LA.db = LootAnchorDB
  Migrate(LA.db)
  if LA.BuildSettingsPage then LA.BuildSettingsPage() end
end)
