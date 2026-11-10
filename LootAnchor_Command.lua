SLASH_LOOTANCHOR1 = "/la"
SLASH_LOOTANCHOR2 = "/lootanchor"
SlashCmdList["LOOTANCHOR"] = function()
  if LootAnchor.db then LootAnchor.Toggle() end
end
