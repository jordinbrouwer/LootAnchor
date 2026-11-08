-- Settings > AddOns > LootAnchor: icon, Unlock and Defaults buttons.
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
  desc:SetText("Move the loot roll windows and the \"You received\" popups.")
  desc:SetJustifyH("LEFT")

  -- Same spot and size as the GroupHighlight panel: one wide button in the middle.
  local unlock = LA.Button(panel, "Open LootAnchor", 280)
  unlock:SetSize(280, 32)
  unlock:SetPoint("CENTER", panel, "CENTER", 0, 0)
  unlock:SetScript("OnClick", function()
    if not LA.unlocked then
      if SettingsPanel and HideUIPanel then HideUIPanel(SettingsPanel)
      elseif InterfaceOptionsFrame and HideUIPanel then HideUIPanel(InterfaceOptionsFrame) end
      LA.Toggle()
    end
  end)

  local category = Settings.RegisterCanvasLayoutCategory(panel, "LootAnchor")
  Settings.RegisterAddOnCategory(category)
end
