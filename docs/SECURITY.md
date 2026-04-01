# Security

## Threat Model

- Primary boundary: local workstation execution with user-level privileges.
- Attack surface: shell command construction, AppleScript invocation, plugin source repositories, and generated files.

## Hardening Controls

- Prefer argument-array command execution where supported to reduce shell injection risk.
- Escape command payloads before embedding in AppleScript strings.
- Escape opened file/folder paths before issuing Ex commands.
- Validate plugin repo format (`owner/name`) before persistence.
- Treat state writes as failure-sensitive and notify on write errors.

## Supply Chain Considerations

- Plugins are fetched from remote repositories through lazy.nvim.
- Managed plugin installation should remain explicit and user-driven.
- Lockfile drift should be reviewed intentionally when plugin sync is triggered.

## Least Privilege and Data Scope

- Files written by control center are limited to Neovim config/data/state paths.
- No credential storage is introduced by this repository.

## Security Review Checklist

- No unescaped user input in shell command strings.
- No silent persistence failures.
- No startup crash path from optional generated artifacts.
- No broad filesystem writes outside Neovim-owned directories.
