std = "lua51"
max_line_length = false
exclude_files = { ".git/**" }

globals = { "LootAnchor", "LootAnchorDB", "SLASH_LOOTANCHOR1", "SLASH_LOOTANCHOR2", "SlashCmdList" }

read_globals = {
  "CreateFrame", "UIParent", "GroupLootContainer", "AlertFrame",
  "hooksecurefunc", "wipe", "unpack", "GetCursorPosition", "GameTooltip", "GameTooltip_Hide", "C_Timer", "UIParent_ManageFramePositions", "AlertFrame_FixAnchors", "GroupLootContainer_Update", "_G", "Settings", "SettingsPanel", "InterfaceOptionsFrame", "HideUIPanel",
}
