#!/bin/bash
FILE="$1"
if [[ "$FILE" == term://* ]] || [[ -z "$FILE" ]]; then
    echo "Error: No code file detected. Please open a file first."
    exit 1
fi
cd "$(dirname "$FILE")" || exit
BASENAME=$(basename "$FILE")
NAME="${BASENAME%.*}"
EXT="${BASENAME##*.}"
if [ "$EXT" = "rs" ]; then
    if cargo locate-project >/dev/null 2>&1; then
        if [ "$BASENAME" = "main.rs" ]; then
            PKG_NAME=$(grep '^name' Cargo.toml 2>/dev/null || grep '^name' ../Cargo.toml 2>/dev/null | head -n 1 | cut -d '"' -f 2)
            cargo run -q --bin "$PKG_NAME"
        else
            cargo run -q --bin "$NAME"
        fi
    else
        rustc "$BASENAME" && "./$NAME"
    fi
# Detect Homebrew GCC version (usually g++-15, g++-14 or g++-13)
# We search for the newest version installed via Brew
GCC_BIN=$(ls /opt/homebrew/bin/g++-* | sort -V | tail -n 1)

if [ -z "$GCC_BIN" ]; then
    echo "Error: GCC not found. Run 'brew install gcc'"
    exit 1
fi
elif [ "$EXT" = "cpp" ]; then
    # -DLOCAL allows you to use #ifdef LOCAL for debug prints that won't run on judges
    "$GCC_BIN" -std=c++20 -DLOCAL -O2 -Wall -Wextra "$BASENAME" -o "$NAME" && "./$NAME"
# === UPDATED C SECTION ===
elif [ "$EXT" = "c" ]; then
    # Use GCC for C files too
    GCC_C_BIN=$(ls /opt/homebrew/bin/gcc-* | sort -V | tail -n 1)
    "$GCC_C_BIN" "$BASENAME" -o "$NAME" && "./$NAME"
elif [ "$EXT" = "py" ]; then
    python3 "$BASENAME"
elif [ "$EXT" = "js" ]; then
    node "$BASENAME"
elif [ "$EXT" = "ts" ]; then
    ts-node "$BASENAME"
elif [ "$EXT" = "java" ]; then
    javac "$BASENAME" && java "$NAME"
else
    echo "No runner configured for .$EXT"
fi
