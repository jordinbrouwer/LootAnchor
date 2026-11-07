-- /la or /lootanchor: unlock / lock. /la reset: back to Blizzard's positions.
SLASH_LOOTANCHOR1 = "/la"
SLASH_LOOTANCHOR2 = "/lootanchor"
SlashCmdList["LOOTANCHOR"] = function(msg)
  if not LootAnchor.db then return end
  if (msg or ""):lower():find("reset") then
    LootAnchor.DefaultsAll()
  else
    LootAnchor.Toggle()
  end
end
