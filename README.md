# Papis Launcher

A DankMaterialShell launcher plugin that lists the documents in your [papis](https://github.com/papis/papis) library and opens them from the launcher.

## Requirements

- `papis` on `PATH` with a configured library
- `dms cl copy` or `wl-copy` (only for Shift+Enter paste)

## Usage

1. Open the launcher (Ctrl+Space)
2. Type `:p` followed by words from a title, author or year, e.g. `:p attention 2017`
3. Press Enter to run `papis open papis_id:<id>` for the selected document
4. Press Shift+Enter to paste the document title into the focused app

Documents are read with:

```bash
papis list --all --format "{doc[papis_id]}\t{doc[title]}\t{doc[author]}\t{doc[year]}"
```

The list is loaded when the plugin starts and refreshed in the background at most once a minute while the launcher is used.

## Installation

```bash
cp -r . ~/.config/DankMaterialShell/plugins/papisLauncher/
```

Then open Settings → Plugins, click "Scan for Plugins" and enable "Papis Launcher".

## Configuration

Settings → Plugins → Papis Launcher:

- **Trigger** (default `:p`)
- **Clipboard Program**: `dms cl copy` with `wl-copy` fallback, or `wl-copy` only

## Development

`node --test tests/*.test.cjs` runs the component in an offscreen Quickshell instance against a fake `papis` executable, so no papis library is required.

## License

See [LICENSE](LICENSE).
