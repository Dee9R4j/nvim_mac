# CLI Usage

## Script

- `run_code.sh <absolute-or-relative-file-path>`

## Purpose

Compile or execute the provided file using language-specific toolchains.

## Supported Extensions

- `rs`: Cargo-aware run with fallback to `rustc`.
- `cpp`: compile with detected C++ compiler and execute.
- `c`: compile with detected C compiler and execute.
- `py`: execute with `python3`.
- `js`: execute with `node`.
- `ts`: execute with `ts-node`.
- `java`: compile with `javac` then run.

## Behavior

- The script changes working directory to the file directory before execution.
- For unsupported extensions, it prints a clear message.
- For missing compilers/runtimes, it exits non-zero with an explicit error.
