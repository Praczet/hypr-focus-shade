# Changelog

## 0.1.0 - 2026-06-11

Initial usable release of `hypr-focus-shade`.

### Added

- Focus-aware sibling window shading for configured classes.
- Lua rule API:
  - `hl.plugin.focus_shade.rule(...)`
  - `hl.plugin.focus_shade.load_shader(...)`
  - `hl.plugin.focus_shade.dsp_shade(...)`
- `focusshade` predefined shader with:
  - `saturation`
  - `brightness`
  - `contrast`
- `desaturate` predefined shader.
- Runtime commands:
  - `hyprctl focus-shade status`
  - `hyprctl focus-shade rules`
  - `hyprctl focus-shade shaded`
  - `hyprctl focus-shade enable`
  - `hyprctl focus-shade disable`
  - `hyprctl focus-shade toggle`
- JSON output for status/debug commands.
- Development reload helper: `scripts/dev-reload`.
- HyprPM and Nix packaging metadata.

### Changed

- Renamed the plugin surface to `hypr-focus-shade`.
- Kept upstream `Hypr-DarkWindow` shader/window-rule behavior as compatibility
  plumbing.
- Documented the tested Ghostty rule:
  `focusshade saturation=0.25 brightness=0.86 contrast=0.82`.

### Fixed

- Plugin-owned focus shaders are cleared on unload.
- Runtime hooks/listeners/config state is cleaned up during plugin exit.
- `focusshade` and `desaturate` shader arguments are validated before use.

### Known Limits

- Rules are class-based.
- Only one shader can be active on a window at a time.
- Runtime enable/disable state resets to config on reload.
- Hyprland plugin ABI must match the running compositor build.
