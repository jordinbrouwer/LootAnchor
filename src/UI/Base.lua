-- The look and the shared parts of the windows. Every UI file takes its tools from the UI table.
-- Colours and sizes live here only, as in AutomaticRoleCheck, in LootAnchor's own colours (teal and amber).
LootAnchor = LootAnchor or {}
local UI = {}
LootAnchor.UI = UI

UI.THEME = {
  ACCENT = { 0.10, 0.85, 0.68, 1 },          -- teal: LootAnchor's own colour
  AMBER = { 1.0, 0.72, 0.2, 1 },             -- the colour of the "You received & achievements" box
  WINDOW = { 0.06, 0.11, 0.15, 0.96 },
  HEADER = { 0.04, 0.15, 0.19, 1 },          -- the band at the top of the panel
  TITLE_TEXT = { 0.85, 1, 0.97, 1 },
  SUBTITLE_TEXT = { 0.35, 0.95, 0.80, 1 },
  BORDER = { 0.23, 0.30, 0.34, 1 },
  BOX_BG = { 0.04, 0.08, 0.11, 0.6 },        -- the boxes round the sections (as in AutomaticRoleCheck)
  BOX_BORDER = { 0.23, 0.30, 0.34, 0.9 },
  FIELD = { 0.04, 0.08, 0.11, 1 },           -- a field you type in, the closed dropdown
  BUTTON = { 0.10, 0.18, 0.24, 1 },
  BUTTON_HOVER = { 0.13, 0.24, 0.31, 1 },
  BUTTON_ON = { 0.07, 0.38, 0.31, 1 },       -- a chosen button, and the main button
  BUTTON_ON_HOVER = { 0.09, 0.47, 0.39, 1 },
  MENU_BG = { 0.08, 0.14, 0.19, 1 },         -- the list of a dropdown
  OVERLAY = { 0, 0, 0, 0.35 },               -- over the screen while the boxes are dragged
  HANDLE_BG = { 0.06, 0.11, 0.15, 0.88 },    -- the inside of a box you drag, of the small bars
  TIP_BG = { 0.06, 0.11, 0.15, 0.98 },
  MUTED = { 0.56, 0.64, 0.68, 1 },           -- quiet text and icons at rest
  BRIGHT = { 1, 1, 1, 1 },                   -- the same under the mouse
}
local THEME = UI.THEME
THEME.TARGET = { roll = THEME.ACCENT, alert = THEME.AMBER }   -- the colour of the box of each target

-- The size of the panel (pixels).
UI.LAYOUT = {
  PANEL_W = 360,
  HEADER = 47,         -- the teal line (3) and the header band (44)
  OUTER = 10,            -- between the edge of the panel and the boxes (the same as in AutomaticRoleCheck)
  TOP = 10,            -- between the header and the first thing under it
  TAB_H = 24,
  TAB_GAP = 8,         -- between the tabs and the box
  ROW_H = 18,          -- the height of a button in a box (the same as the chips of AutomaticRoleCheck)
  BOX_INDENT = 8,      -- between the left edge of a box and what is in it (the same as the title)
  BOX_HEADER = 18,     -- the title row of a box
  BOX_BOTTOM = 8,
  BOX_GAP = 4,         -- between two boxes under each other
  FOOTER = 24,         -- the band at the bottom
}

-- The colour of the box of a target.
function UI.TargetColor(target)
  return THEME.TARGET[target.key] or THEME.ACCENT
end

-- A filled texture over the whole frame.
function UI.Fill(frame, r, g, b, a)
  local tex = frame:CreateTexture(nil, "BACKGROUND")
  tex:SetAllPoints()
  tex:SetColorTexture(r, g, b, a)
  return tex
end

-- Makes a line exactly one screen pixel thick, whatever the UI scale (a plain 1 can render as 0, 1 or 2
-- pixels, so lines looked uneven and corners did not meet).
function UI.OnePixel(line, horizontal)
  line:SetTexelSnappingBias(0)
  line:SetSnapToPixelGrid(false)
  if PixelUtil then
    if horizontal then PixelUtil.SetHeight(line, 1, 1) else PixelUtil.SetWidth(line, 1, 1) end
  else
    if horizontal then line:SetHeight(1) else line:SetWidth(1) end
  end
end

-- A thin border of one-pixel lines: top and bottom full width, the sides in between (no doubled corners).
-- color = { r, g, b, a }; alpha replaces its alpha when given. Gives back the lines (for UI.SetBorderColor).
function UI.AddBorder(frame, color, alpha)
  local top, bottom, left, right = frame:CreateTexture(nil, "BORDER"), frame:CreateTexture(nil, "BORDER"),
    frame:CreateTexture(nil, "BORDER"), frame:CreateTexture(nil, "BORDER")
  top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);              top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);     bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  left:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, 0);            left:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT", 0, 0)
  right:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT", 0, 0);         right:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT", 0, 0)
  UI.OnePixel(top, true); UI.OnePixel(bottom, true); UI.OnePixel(left, false); UI.OnePixel(right, false)
  local lines = { top, bottom, left, right }
  UI.SetBorderColor(lines, color, alpha)
  return lines
end

function UI.SetBorderColor(lines, color, alpha)
  for _, line in ipairs(lines) do line:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1) end
end
-- Gives every text in a frame (and in everything inside it) a thin outline.
function UI.ApplyOutline(frame)
  for _, region in ipairs({ frame:GetRegions() }) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then
      local path, size = region:GetFont()
      if path then region:SetFont(path, size, "OUTLINE") end
    end
  end
  for _, child in ipairs({ frame:GetChildren() }) do UI.ApplyOutline(child) end
end
