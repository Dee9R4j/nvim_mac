# Error Handling

## Principles

- Fail closed for writes: if state cannot be written, do not continue as if it succeeded.
- Fail soft on optional startup artifacts: missing cache files should not abort editor startup.
- Surface actionable messages to the user through `vim.notify` with clear reason and scope.

## Error Categories

### Startup Resilience

- Location: `init.lua`
- Rule: optional cache files are loaded via guarded checks and `pcall`.
- Outcome: startup continues when cache files are missing or invalid.

### State Persistence

- Location: `lua/configs/control_center.lua`
- Rule: JSON encode, directory creation, and write operations are wrapped and validated.
- Outcome: failed writes are reported and caller receives failure status.

### External Command and Dialog Execution

- Location: `lua/mappings.lua`
- Rule: AppleScript invocations use argument lists (not shell concatenation) where possible.
- Outcome: fewer shell-escaping failures and explicit cancellation handling.

### Toolchain and Runner Resolution

- Location: `run_code.sh`
- Rule: compiler and runtime discovery is explicit with fallback order.
- Outcome: missing toolchain errors are deterministic and non-zero.

## Notification Levels

- INFO: user cancellation and expected status transitions.
- WARN: recoverable runtime degradation.
- ERROR: failed persistence or invalid command environment.

## Exit Code Model

- `run_code.sh` exits non-zero for invalid input path, missing compiler/runtime, and unsupported operations that cannot proceed.
