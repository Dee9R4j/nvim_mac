#!/bin/bash
FILE="$1"

find_latest_versioned_binary() {
    local pattern="$1"
    ls /opt/homebrew/bin/${pattern} /usr/local/bin/${pattern} 2>/dev/null | sort -V | tail -n 1
}

resolve_cpp_compiler() {
    local detected
    detected="$(find_latest_versioned_binary 'g++-*')"
    if [[ -n "$detected" ]]; then
        echo "$detected"
        return 0
    fi

    if command -v g++ >/dev/null 2>&1; then
        command -v g++
        return 0
    fi

    if command -v clang++ >/dev/null 2>&1; then
        command -v clang++
        return 0
    fi

    return 1
}

resolve_c_compiler() {
    local detected
    detected="$(find_latest_versioned_binary 'gcc-*')"
    if [[ -n "$detected" ]]; then
        echo "$detected"
        return 0
    fi

    if command -v gcc >/dev/null 2>&1; then
        command -v gcc
        return 0
    fi

    if command -v cc >/dev/null 2>&1; then
        command -v cc
        return 0
    fi

    return 1
}

resolve_cargo_package_name() {
    local manifest
    manifest="$(cargo locate-project --message-format plain 2>/dev/null)"
    if [[ -z "$manifest" || ! -f "$manifest" ]]; then
        return 1
    fi

    sed -nE 's/^name[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$manifest" | head -n 1
}

if [[ "$FILE" == term://* ]] || [[ -z "$FILE" ]]; then
    echo "Error: No code file detected. Please open a file first."
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "Error: File does not exist: $FILE"
    exit 1
fi

cd "$(dirname "$FILE")" || exit
BASENAME=$(basename "$FILE")
NAME="${BASENAME%.*}"
EXT="${BASENAME##*.}"

if [ "$EXT" = "rs" ]; then
    if cargo locate-project >/dev/null 2>&1; then
        if [ "$BASENAME" = "main.rs" ]; then
            PKG_NAME=$(resolve_cargo_package_name)
            if [ -n "$PKG_NAME" ]; then
                cargo run -q --bin "$PKG_NAME"
            else
                cargo run -q
            fi
        else
            cargo run -q --bin "$NAME"
        fi
    else
        rustc "$BASENAME" && "./$NAME"
    fi

elif [ "$EXT" = "cpp" ]; then
    GCC_BIN=$(resolve_cpp_compiler)

    if [ -z "$GCC_BIN" ]; then
        echo "Error: No C++ compiler found. Install gcc/clang or configure PATH."
        exit 1
    fi
    
    # -DLOCAL enables local debug blocks; stack_size avoids macOS recursion stack overflows
    if command -v gtimeout >/dev/null 2>&1; then
        "$GCC_BIN" -std=c++20 -DLOCAL -O2 -Wall -Wextra -Wl,-stack_size,0x10000000 "$BASENAME" -o "$NAME" && gtimeout 3s "./$NAME"
    else
        "$GCC_BIN" -std=c++20 -DLOCAL -O2 -Wall -Wextra -Wl,-stack_size,0x10000000 "$BASENAME" -o "$NAME" && "./$NAME"
    fi

# === UPDATED C SECTION ===
elif [ "$EXT" = "c" ]; then
    GCC_C_BIN=$(resolve_c_compiler)
    if [ -z "$GCC_C_BIN" ]; then
        echo "Error: No C compiler found. Install gcc/clang or configure PATH."
        exit 1
    fi
    "$GCC_C_BIN" "$BASENAME" -o "$NAME" && "./$NAME"

elif [ "$EXT" = "py" ]; then
    python3 "$BASENAME"

elif [ "$EXT" = "js" ]; then
    node "$BASENAME"

elif [ "$EXT" = "ts" ]; then
    if command -v ts-node >/dev/null 2>&1; then
        ts-node "$BASENAME"
    else
        echo "Error: ts-node is not installed. Install it globally or in your project."
        exit 1
    fi

elif [ "$EXT" = "java" ]; then
    javac "$BASENAME" && java "$NAME"

else
    echo "No runner configured for .$EXT"
fi
