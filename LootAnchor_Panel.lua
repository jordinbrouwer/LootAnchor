LootAnchor = LootAnchor or {}
local LA = LootAnchor

function LA.BuildPanel()
  if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
  local panel = CreateFrame("Frame")
  panel.name = "LootAnchor"

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(40, 40)
  icon:SetPoint("TOPLEFT", 16, -16)
  icon:SetTexture("Interface\\AddOns\\LootAnchor\\LootAnchor")

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
  title:SetText("LootAnchor")

  local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  desc:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -16)
  desc:SetText("Move the loot roll windows and the \"You received\" and achievement popups.")

  local edit = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  edit:SetSize(280, 32)
  edit:SetPoint("CENTER")
  edit:SetText("Edit anchors")
  edit:SetScript("OnClick", function()
    if LA.open then return end
    if SettingsPanel then HideUIPanel(SettingsPanel) end
    LA.Toggle()
  end)

  Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(panel, "LootAnchor"))
end
