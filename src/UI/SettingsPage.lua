-- The game's settings page: the icon, the description and a button that opens the panel.
local LA = LootAnchor
local UI = LA.UI
local THEME = UI.THEME
local L = LA.Loc

function LA.BuildSettingsPage()
  if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
  local panel = CreateFrame("Frame")
  panel.name = LA.AddonName

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(44, 44)
  icon:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -24)
  icon:SetTexture(LA.Media.Logo)

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  title:SetPoint("LEFT", icon, "RIGHT", 12, 0)
  title:SetText(LA.AddonName)

  local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  desc:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -14)
  desc:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
  desc:SetJustifyH("LEFT")
  desc:SetText(L("page_desc"))

  local open = UI.FlatChip(panel, L("page_open"), 280, 30, "flat")
  open:SetScript("OnClick", function()
    if LA.open then return end
    if SettingsPanel and HideUIPanel then HideUIPanel(SettingsPanel) end
    LA.ToggleOptions()
  end)
  open:SetPoint("CENTER", panel, "CENTER", 0, 0)

  local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hint:SetPoint("TOP", open, "BOTTOM", 0, -10)
  hint:SetTextColor(unpack(THEME.MUTED))
  hint:SetText(L("page_hint"))
  UI.ApplyOutline(panel)

  Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(panel, LA.AddonName))
end
