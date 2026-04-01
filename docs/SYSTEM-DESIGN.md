# System Design

## Startup Sequence

1. `init.lua` aborts early for VS Code embedded mode.
2. lazy.nvim bootstrap occurs if not installed.
3. NvChad and user plugin specs are loaded.
4. Optional generated cache files are loaded in guarded mode.
5. options/autocmds/mappings are registered.

## Subsystems

- Bootstrap subsystem: plugin manager and cache loader.
- UI policy subsystem: diagnostics, wrapping, terminal defaults.
- Interaction subsystem: keymaps, dialogs, host-app focus.
- State subsystem: control center settings and managed plugin list files.
- Runner subsystem: language execution routing via `run_code.sh`.

## State Model

- Runtime state file: Neovim state directory JSON for control center settings.
- Plugin state file: Neovim data directory JSON listing managed plugin repos.
- Generated source file: `lua/plugins/control_center_user.lua` synthesized from plugin state.

## Failure Recovery

- Missing startup cache files: continue startup.
- State write failure: notify user and stop follow-up operations dependent on successful writes.
- Missing compiler/runtime in runner: print explicit error and exit non-zero.

## Operational Tradeoffs

- Heavy use of platform-specific automation (AppleScript) improves UX on macOS but reduces portability.
- Managed plugin sync is explicit and user-triggered from control center actions.
