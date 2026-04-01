# Contributing

## Local Prerequisites

- Neovim with NvChad v2.5 compatible setup.
- `rg` for search workflows.
- Optional: `fd`, `cargo`, `node`, `python3`, language-specific compilers.

## Development Workflow

1. Make focused, single-purpose edits.
2. Keep behavior unchanged unless fixing a verified bug.
3. Add or update docs when behavior, architecture, or operational assumptions change.
4. Prefer shared helpers over duplicate shell/AppleScript snippets.

## Change Rules

- Keep startup path resilient.
- Keep shell command construction escaped and centralized.
- Keep state schema additive and backward compatible.
- Keep plugin declarations deterministic.

## Verification Checklist

- `bash -n run_code.sh`
- `nvim --headless "+lua require('configs.control_center').setup()" +qa` (optional smoke check)
- `nvim --headless "+lua dofile('init.lua')" +qa` (optional startup smoke check)

## Pull Request Expectations

- Include risk summary and behavior impact (`none`, `bug fix`, or `breaking`).
- Include touched file list and reason for each change.
- Include commands executed and observed results.
