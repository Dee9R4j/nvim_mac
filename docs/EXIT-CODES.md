# Exit Codes

## run_code.sh

- `0`: command executed successfully.
- `1`: invalid input (missing file, invalid path, or terminal pseudo-buffer path).
- `1`: missing required compiler/runtime tool.
- `1`: unsupported configuration for requested execution path.

Note: language toolchain failures (compile/runtime errors) propagate their non-zero exit status through shell command chaining.
