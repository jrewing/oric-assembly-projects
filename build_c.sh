#!/bin/bash
# build_c.sh - Build C programs for ORIC using cc65

if [ -z "$1" ]; then
    echo "Usage: $0 <source.c> [--run]"
    exit 1
fi

SOURCE="$1"
BASENAME=$(basename "$SOURCE" .c)
BUILD_DIR="build"

mkdir -p "$BUILD_DIR"

echo "=== Building $BASENAME (C) ==="

# Step 1: Compile C to assembly
echo "[1/4] Compiling C to assembly..."
cc65 -t atmos -O -o "$BUILD_DIR/$BASENAME.s" "$SOURCE"
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

# Step 2: Assemble
echo "[2/4] Assembling..."
ca65 -t atmos -o "$BUILD_DIR/$BASENAME.o" "$BUILD_DIR/$BASENAME.s"
if [ $? -ne 0 ]; then
    echo "Assembly failed!"
    exit 1
fi

# Step 3: Link (using atmos library)
echo "[3/4] Linking..."
ld65 -t atmos -o "$BUILD_DIR/$BASENAME.bin" "$BUILD_DIR/$BASENAME.o" atmos.lib
if [ $? -ne 0 ]; then
    echo "Linking failed!"
    exit 1
fi

# Step 4: cc65 already creates a proper TAP file with headers
# Just copy it (the .bin IS the .tap)
echo "[4/4] Creating TAP file..."
cp "$BUILD_DIR/$BASENAME.bin" "$BUILD_DIR/$BASENAME.tap"

# Get file size
SIZE=$(wc -c < "$BUILD_DIR/$BASENAME.bin" | tr -d ' ')

echo ""
echo "=== Build Complete ==="
echo "Output: $BUILD_DIR/$BASENAME.tap"
echo "Size: $SIZE bytes"
echo ""

# Run in emulator if --run flag is provided
if [ "$2" = "--run" ]; then
    ORICUTRON_DIR="oricutron/build"

    if [ -d "$ORICUTRON_DIR" ]; then
        cp "$BUILD_DIR/$BASENAME.tap" "$ORICUTRON_DIR/"

        echo "=== Launching Oricutron ==="
        cd "$ORICUTRON_DIR"
        ./Oricutron --machine atmos --turbotape on &

        echo ""
        echo "Oricutron started (ATMOS mode) with turbo tape ON."
        echo "TAP file copied to Oricutron folder."
        echo ""
        echo "In Oricutron:"
        echo "  1. Press F1 to open menu"
        echo "  2. Go to 'Tape' and insert: $BASENAME.tap"
        echo "  3. Type: CLOAD\"\""
        echo "  4. After loading, type: RUN"
    else
        echo "Oricutron not found at $ORICUTRON_DIR"
        echo "Copy $BUILD_DIR/$BASENAME.tap to your emulator manually."
    fi
fi
