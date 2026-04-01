# Architecture

## Project Type

- Type: systems configuration (Neovim runtime and automation glue)
- Language stack: mixed (Lua + Bash)
- Runtime: mixed (Neovim Lua runtime + shell)

## Module Boundaries

### Bootstrap and Runtime Wiring

- `init.lua`
- Responsibility: bootstrap lazy.nvim, initialize NvChad modules, register global autocmds, and route specific files to external apps.
- Constraints: startup must not fail if optional generated cache files are absent.

### Runtime Options and Editor Policies

- `lua/options.lua`
- Responsibility: editor defaults, diagnostic policy, autosave behavior, and terminal buffer ergonomics.
- Constraints: should not perform heavy IO; should be deterministic on startup.

### User Interaction and Keymap Workflow

- `lua/mappings.lua`
- Responsibility: user-facing workflows for save/quit/open/run, clipboard behavior, and terminal orchestration.
- Constraints: all shell and AppleScript boundaries must be escaped and error-aware.

### Control Center Domain Logic

- `lua/configs/control_center.lua`
- Responsibility: persistent state model, menu orchestration, and managed plugin list generation.
- Constraints: file writes must fail safely with actionable user feedback.

### Plugin Composition

- `lua/plugins/init.lua`
- Responsibility: plugin catalog and plugin-specific setup hooks.
- Constraints: plugin configuration should remain declarative where possible.

### CLI Execution Helper

- `run_code.sh`
- Responsibility: compile/run current file by extension with language-specific toolchains.
- Constraints: deterministic error messages and explicit non-zero exit codes on failure.

## Dependency Direction

- Bootstrap (`init.lua`) -> options and mappings.
- Mappings -> control center API and Neovim/plugin commands.
- Control center -> persisted state files and generated plugin declaration file.
- `run_code.sh` is called at the edge by keymaps and does not import Lua modules.

## Side-Effect Boundaries

- Neovim UI and keymaps: `lua/mappings.lua`, `lua/options.lua`.
- Disk writes: `lua/configs/control_center.lua`.
- External process execution: `lua/mappings.lua`, `run_code.sh`.

## Design Constraints

- Keep Neovim startup path resilient to missing generated artifacts.
- Keep shell and AppleScript integration centralized and escaped.
- Keep persistent state schema backward compatible with defaults.
