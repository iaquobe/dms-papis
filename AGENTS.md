# AGENTS.md - DMS Papis Launcher

## Project Overview
A DankMaterialShell (DMS) launcher plugin that lists documents from a papis library and opens them.

**Language**: QML
**Type**: Launcher plugin for DankMaterialShell
**Plugin id**: `papisLauncher`
**Default Trigger**: `:p`
**Version**: 2.0.0

History: this repository was previously an emoji/unicode launcher (up to v1.7.3, commit `fc38590`). All emoji catalog code and data were removed in 2.0.0.

## Files
- **plugin.json** - metadata, version, trigger
- **PapisLauncher.qml** - launcher component
- **PapisLauncherSettings.qml** - settings UI (trigger, clipboard program)
- **tests/papis-launcher.test.cjs** + **tests/shell.qml** - offscreen Quickshell test using a fake `papis` on `PATH`

## How it works
- `listProcess` runs `papis list --all --format "{doc[papis_id]}\t{doc[title]}\t{doc[author]}\t{doc[year]}"`; output is parsed one document per line, tab-separated. Missing fields are printed as empty strings by papis.
- The list is fetched on startup and refreshed from `getItems()` when older than `refreshIntervalMs` (60s). `itemsChanged()` is emitted after each load.
- Search: every query token must appear in title, author or year; title matches rank higher. Max 50 results.
- Enter: `papis open papis_id:<id>` (detached via `setsid`). Falls back to a title query if a document has no `papis_id`.
- Shift+Enter (`getPasteText`/`getPasteArgs`): copies/pastes the title.

## Testing
```bash
node --test tests/*.test.cjs
```
Requires `qs` (Quickshell). papis itself is not needed. Note: in sandboxed environments real papis may fail to index because it uses multiprocessing; `PAPIS_NP=0` disables that.

## Git Workflow
Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`). Bump `plugin.json` version accordingly.
