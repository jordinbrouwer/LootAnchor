# Contributing

Contributions are welcome.

## How to contribute

1. Fork the repository and create a branch from `main`.
2. Make one feature or fix per pull request, and follow the existing code style.
3. Run the checks (see below).
4. Open a pull request against `main`. The checks run on it automatically.

## Guidelines

- Write commits as [Conventional Commits](https://www.conventionalcommits.org/): `feat: ...`, `fix: ...`, `docs: ...`. Write the description for players, because it becomes the changelog line.
- Don't change `CHANGELOG.md` or version numbers; that happens automatically when a release is made.
- Everything that ships with the addon lives in `src/`. Keep the `.toc` file list in load order.
- To test in game, link `src/` into your AddOns folder as `LootAnchor`.

## Code layout

The load order is in `src/LootAnchor.toc`.

```
src/
  LootAnchor.toc        the file list, in load order
  LootAnchor.tga        the addon icon the CI checks need (the same picture as Media/Logo.tga)
  Locale/enUS.lua       all texts: LootAnchor.Loc("key") (a missing key shows the key itself)
  Core/
    Core.lua            the shared LootAnchor table, picture paths (LootAnchor.Media) and LootAnchor.On("EVENT", fn) for game events
    Options.lua         the saved settings (LootAnchorDB), DB_VERSION and Migrate
    Anchors.lua         moving the game's windows: anchors, hooks, grow up / down, back to Blizzard's place
    Test.lua            the stand-in windows of the Test tab
    Command.lua         /la and /lootanchor
  Media/                our own .tga pictures (Logo.tga)
  UI/                   every file takes its parts from the UI table
    Base.lua            the UI table, colours (THEME), sizes (LAYOUT) and one-pixel borders
    Tooltip.lua         our own tooltip (UI.Tip, UI.AddTooltip in Widgets.lua)
    Widgets.lua         window frame, header band, close cross, buttons, dropdown list, field, box
    Handles.lua         the boxes you drag, snapping, the arrow keys, the dark layer over the screen
    OptionsPopup.lua    the small box next to the selected box: grow up / down, X and Y
    EditBox.lua         the "Move the boxes" box (Reset, Defaults)
    TestBox.lua         the "Try them out" box (test buttons, duration, Clear)
    Panel.lua           the LootAnchor window: header, tabs, boxes, footer; opening and closing (LootAnchor.ToggleOptions)
    SettingsPage.lua    the page under Settings > AddOns
```

Rules of thumb:

- Colours and sizes live in `src/UI/Base.lua`, texts in `src/Locale/enUS.lua`, picture paths in `src/Core/Core.lua`.
- A new window to move is one more entry in `targets` in `src/Core/Anchors.lua` (and its colour in `THEME.TARGET` in `src/UI/Base.lua`).
- Renamed or removed settings are handled in `Migrate` in `src/Core/Options.lua`; raise `DB_VERSION` with it.

## Checks

The checks live in [wow-addon-ci](https://github.com/jordinbrouwer/wow-addon-ci). Clone it next to this repository; it needs Python 3 and `luacheck`. From this repository's root:

- `python3 ../wow-addon-ci/scripts/checks/run.py quick`: fast structural checks.
- `python3 ../wow-addon-ci/scripts/checks/run.py`: everything CI runs.

## Releases (maintainers)

A `feat`, `fix` or breaking commit in `src/` on `main` releases automatically: the pipeline writes the changelog, tags the version and publishes it to GitHub and CurseForge. **Actions > Pipeline > Run workflow** on `main` can force a `patch`, `minor` or `major` release.

Descriptions, website and images on GitHub and CurseForge can only be changed on their websites. The pipeline compares them with the code and, when they differ, shows a warning and a summary with what to paste.

Repository setup:

- Secrets `CF_API_TOKEN` and `CF_PROJECT_ID` for the CurseForge upload.
- `github-actions` must be allowed to push to `main` (for the release commit and the README release block).
