#!/bin/bash
# build.sh - Build ORIC assembly programs
# Usage: ./build.sh [source.s] [--run]

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$PROJECT_DIR/src"
BUILD_DIR="$PROJECT_DIR/build"
TOOLS_DIR="$PROJECT_DIR/tools"
ORICUTRON="/Users/marvin/oric/oricutron/build/Oricutron"

# Default source file
SOURCE="${1:-hello.s}"
SOURCE_NAME=$(basename "$SOURCE" .s)
RUN_AFTER=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --run|-r)
            RUN_AFTER="yes"
            ;;
        *.s)
            SOURCE="$arg"
            SOURCE_NAME=$(basename "$SOURCE" .s)
            ;;
    esac
done

# Create build directory
mkdir -p "$BUILD_DIR"

echo "=== Building $SOURCE_NAME ==="

# Step 1: Assemble with ca65
echo "[1/3] Assembling..."
ca65 -t none -o "$BUILD_DIR/$SOURCE_NAME.o" "$SRC_DIR/$SOURCE"

# Step 2: Link with ld65
echo "[2/3] Linking..."
ld65 -C "$PROJECT_DIR/oric1.cfg" -o "$BUILD_DIR/$SOURCE_NAME.bin" "$BUILD_DIR/$SOURCE_NAME.o"

# Step 3: Create TAP file
echo "[3/3] Creating TAP file..."
python3 "$TOOLS_DIR/bin2tap.py" \
    "$BUILD_DIR/$SOURCE_NAME.bin" \
    "$BUILD_DIR/$SOURCE_NAME.tap" \
    0x0600 \
    "$SOURCE_NAME"

echo ""
echo "=== Build Complete ==="
echo "Output: $BUILD_DIR/$SOURCE_NAME.tap"
echo ""

# Run in emulator if requested
if [ -n "$RUN_AFTER" ]; then
    echo "=== Launching Oricutron ==="
    if [ -f "$ORICUTRON" ]; then
        # --turbotape: fast tape loading
        # Copy TAP to oricutron folder for easier access
        cp "$BUILD_DIR/$SOURCE_NAME.tap" "$(dirname "$ORICUTRON")/"
        "$ORICUTRON" --machine atmos --turbotape on &
        echo ""
        echo "Oricutron started (ATMOS mode) with turbo tape ON."
        echo "TAP file copied to Oricutron folder."
        echo ""
        echo "In Oricutron:"
        echo "  1. Press F1 to open menu"
        echo "  2. Go to 'Tape' and insert: $SOURCE_NAME.tap"
        echo "  3. Type: CLOAD\"\""
        echo "  4. After loading, type: CALL#600"
    else
        echo "Warning: Oricutron not found at $ORICUTRON"
        echo "Please update the ORICUTRON path in build.sh"
    fi
fi
