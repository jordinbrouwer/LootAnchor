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

  local unlock = LA.Button(panel, "Unlock", 120)
  unlock:SetSize(120, 26)
  unlock:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
  unlock:SetScript("OnClick", function()
    if not LA.unlocked then
      if SettingsPanel and HideUIPanel then HideUIPanel(SettingsPanel)
      elseif InterfaceOptionsFrame and HideUIPanel then HideUIPanel(InterfaceOptionsFrame) end
      LA.Toggle()
    end
  end)

  local reset = LA.Button(panel, "Defaults", 120)
  reset:SetSize(120, 26)
  reset:SetPoint("LEFT", unlock, "RIGHT", 10, 0)
  reset:SetScript("OnClick", LA.DefaultsAll)
  reset:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Reset to Blizzard's initial location.")
    GameTooltip:Show()
  end)
  reset:SetScript("OnLeave", GameTooltip_Hide)

  local category = Settings.RegisterCanvasLayoutCategory(panel, "LootAnchor")
  Settings.RegisterAddOnCategory(category)
end
