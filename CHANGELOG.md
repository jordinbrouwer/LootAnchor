# Changelog
Written by the release pipeline from the commits; see `CONTRIBUTING.md`.

## [Unreleased](https://github.com/jordinbrouwer/LootAnchor/compare/1.3.2...main)

## [1.3.2 (2026-11-27)](https://github.com/jordinbrouwer/LootAnchor/releases/tag/1.3.2)

### Fixed
- The header no longer cuts off the second line of its description when the window opens. ([6964f5e](https://github.com/jordinbrouwer/LootAnchor/commit/6964f5ef11fc861920443c2b76da62500af61852))

## [1.3.1 (2026-11-27)](https://github.com/jordinbrouwer/LootAnchor/releases/tag/1.3.1)

### Fixed
- The header description goes on over more lines instead of being cut off, and the header grows with it. ([399851f](https://github.com/jordinbrouwer/LootAnchor/commit/399851f5ef198a27cb14ba051c9176822603e84e))

## [1.3.0 (2026-11-25)](https://github.com/jordinbrouwer/LootAnchor/releases/tag/1.3.0)

### Added
- Close button (the cross in the top right corner) and a reminder at the bottom of the window: "Type /la in chat to open this again."
- A tooltip on the **Grow up** / **Grow down** list: "Which way the windows stack."

### Changed
- The toolbar is now a LootAnchor window: a header with the logo, the name and "Move the loot and achievement popups.", the **Edit** and **Test** tabs, a box for each tab ("Move the boxes" with a short hint, **Reset** and **Defaults**; "Try them out" with the test buttons, duration and **Clear**) and **Save & exit** at the bottom. Drag it by its header.
- Tooltips are LootAnchor's own: a dark box with a teal edge, the button name as a teal title and the help text under it.
- Borders are exactly one screen pixel at any UI scale, and texts have a thin outline, in the window, the boxes you drag and the settings page.
- The settings page button is now a flat **Open LootAnchor** button (was **Edit anchors**), with "or type /la" under it.
- The code is split into the `Core`, `UI`, `Locale` and `Media` folders.

## [1.2.0 (2026-11-10)](https://github.com/jordinbrouwer/LootAnchor/releases/tag/1.2.0)

### Added
- Test tab on the LootAnchor bar: show a test loot roll, "You received" popup or achievement to see where they land and which way they grow. Click again for more.
- Test duration: 5 seconds, 10 seconds, 20 seconds or until clicked away. **Clear** removes all test windows.
- Achievement popups move with the "You received" box.
- Grow direction for the "You received" popups, separate from the loot rolls.
- Settings window of the selected box with its grow direction and a typed X / Y position.
- Arrow buttons around the selected box, and the arrow keys, move it. Hold a button to keep moving.

### Changed
- `/la` opens the anchor editor, which now also has the Test tab.
- The settings panel has one **Edit anchors** button and mentions achievements.
- Reset in the toolbar goes back to how things were when you opened LootAnchor.
- Defaults keeps the bar position and the test duration.
- Each box keeps its own colour and label, and its border lights up when it is selected or hovered.

### Removed
- `/la reset` and `/lootanchor reset`. Use **Defaults** in the toolbar instead.

## [1.1.0 (2026-11-08)](https://github.com/jordinbrouwer/LootAnchor/releases/tag/1.1.0)

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

## [1.0.0 (2026-11-07)](https://github.com/jordinbrouwer/LootAnchor/releases/tag/1.0.0)

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
