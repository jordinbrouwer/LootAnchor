-- /la (or /lootanchor) opens and closes the panel.
local LA = LootAnchor
SLASH_LOOTANCHOR1 = "/la"
SLASH_LOOTANCHOR2 = "/lootanchor"

SlashCmdList["LOOTANCHOR"] = function()
  if LA.db then LA.ToggleOptions() end
end
