# Changelog

## 1.1.0 - 2026-11-08

### Added
- Grow direction arrow in the top right corner of the Loot Rolls box: stack the loot rolls downwards instead of upwards. Reset and Defaults restore the previous / default (up) direction.
- The unlock toolbar can be dragged; its position is remembered.
- Boxes get their own colour and label edge so overlapping boxes stay readable, and they light up on hover.
- Snapping to the screen edges, the screen centre (with guide lines) and the other box.
- Settings panel: one **Open LootAnchor** button in the middle of the panel.

### Changed
- The code is split into `LootAnchor.lua`, `LootAnchor_Unlock.lua`, `LootAnchor_Panel.lua` and `LootAnchor_Command.lua`.
- Defaults is no longer in the settings panel, only on the unlock screen toolbar.
- Defaults keeps the toolbar position.

## 1.0.0 - 2026-11-07

First release.

### Added
- Move the default loot roll windows and the "You received" popups.
- `/la` (or `/lootanchor`) opens an unlock screen with draggable boxes, snapping to a 10 pixel grid.
- Toolbar with **Reset** (undo changes since unlocking), **Defaults** (Blizzard's own positions) and **Save & Exit**.
- `/la reset` restores Blizzard's positions.
- Settings panel under Options > AddOns with Unlock and Defaults buttons.
- Addon icon.
- Works on WoW Forever and retail.

### Notes
- Positions are saved and re-applied after login, `/reload` and Blizzard layout passes.
- Resetting does not need a `/reload`.
