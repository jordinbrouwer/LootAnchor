-- The base: the shared table, the pictures, and the one place that listens to game events.
-- The rest: Options, Anchors (moving the windows), Test (made-up windows), Command (/la), UI/, Locale/ (texts).
LootAnchor = LootAnchor or {}
local LA = LootAnchor
LA.AddonName = ...

-- Pictures (our own .tga files in the Media folder).
local MEDIA_DIR = "Interface\\AddOns\\" .. LA.AddonName .. "\\Media\\"
LA.Media = {
  Logo = MEDIA_DIR .. "Logo",   -- the addon icon (settings page, header of the panel)
}

-- Game events: LA.On("EVENT", fn). One frame listens for all of them.
local handlers = {}
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
  for _, handler in ipairs(handlers[event]) do handler(...) end
end)

LA.On = function(event, handler)
  if not handlers[event] then
    handlers[event] = {}
    eventFrame:RegisterEvent(event)
  end
  table.insert(handlers[event], handler)
end
