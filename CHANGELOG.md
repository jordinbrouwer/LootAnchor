# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased](https://github.com/jordinbrouwer/LootAnchor/compare/1.0.0...main)

## [1.0.0 (2026-11-07)](https://github.com/jordinbrouwer/LootAnchor/releases/tag/1.0.0)

### Added
- Move the default loot roll windows and the "You received" popups.
- `/la` (or `/lootanchor`) opens an unlock screen with draggable boxes, snapping to a 10 pixel grid.
- Toolbar with **Reset** (undo changes since unlocking), **Defaults** (Blizzard's own positions) and **Save & Exit**.
- `/la reset` restores Blizzard's positions.
- Settings panel under Options > AddOns with Unlock and Defaults buttons.
- Addon icon.
- Positions are saved and re-applied after login, `/reload` and Blizzard layout passes.
- Resetting does not need a `/reload`.
- CD workflow that packages tagged releases, creates a GitHub release and publishes to CurseForge (requires the `CF_API_TOKEN` and `CF_PROJECT_ID` secrets).
