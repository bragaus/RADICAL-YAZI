## Repo Shape
- This repo is a Yazi config, not an app. The real entrypoints are `yazi.toml`, `init.lua`, and `package.toml`.
- There is no repo-local build, test, lint, or CI config. Verification is manual: launch `yazi` from a terminal and restart it after every change.
- Lua/runtime failures surface in `ya.notify()` and terminal stderr when Yazi starts.

## Dependency Workflow
- `package.toml` is the source of truth for package-managed contents under `plugins/` and `flavors/`. After changing dependency entries, run `ya pkg install`.
- `flavors/lain.yazi/` is installed, but this repo does not enable it: there is no `theme.toml`, and `yazi.toml` does not select a flavor.

## Git Plugin Wiring
- Git status depends on both sides being present:
  - `pcall(require, "git")` / `require("git"):setup { order = 1500 }` in `init.lua`
  - both `[[plugin.prepend_fetchers]]` entries in `yazi.toml` for `id = "git"` with `url = "*"` and `url = "*/"`
- If you change git signs/styles, keep the `th.git.*` assignments above `require("git"):setup()`.

## `init.lua` Gotchas
- `init.lua` runs inside Yazi and depends on Yazi globals (`th`, `ui`, `ya`, `cx`, `Header`, `Status`). Preserve those exact API names even though the local code is Portuguese/Turing-themed.
- The `Header.children_add` -> `Status.children_add` fallback is intentional compatibility code.
- The permission display path is Unix-only and returns an empty UI when `cha:perm()` is missing or shorter than 10 chars.
- The only live custom linemode implementation is `Linemode:size_and_mtime()`, but `yazi.toml` currently enables no linemode. If you enable one, the name must match exactly.

## Misc
- Preview cache is hardcoded to `/tmp/yazi-cache` in `yazi.toml`.
- `yazi-hud` and `hud_pulse.sh` are standalone helper scripts; the main config does not invoke them.
