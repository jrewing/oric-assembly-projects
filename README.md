# ORIC Assembly Programs

Assembly language programs for the ORIC-1/Atmos 8-bit computer.

## Requirements

- **cc65** toolchain (ca65 assembler, ld65 linker): `brew install cc65`
- **Oricutron** emulator (or real hardware)
- **Python 3** (for bin2tap.py)

## Building

```bash
# Build a program
./build.sh src/bounce.s

# Build and launch in emulator
./build.sh src/bounce.s --run
```

## Programs

| File               | Description                             |
| ------------------ | --------------------------------------- |
| `src/hello.s`      | Display "ABC" in RGB colors (TEXT mode) |
| `src/square.s`     | Draw a yellow square (HIRES mode)       |
| `src/bounce.s`     | Animated bouncing square (HIRES mode)   |
| `src/hires.s`      | HIRES mode test                         |
| `src/circle.s`     | Manual circle drawing experiment        |
| `src/circle_rom.s` | Cross pattern with pixel-level control  |

## Running in Oricutron

1. Load the TAP file: `CLOAD""`
2. Run the program: `CALL#600`

## Technical Notes

- Programs load at address `$0600`
- HIRES screen memory: `$A000-$BF3F` (40 bytes × 200 lines)
- Each byte = 6 pixels (bits 0-5), bits 6-7 for attributes
- Line address calculation: `$A000 + (Y × 40) + (X ÷ 6)`

## Tools

- `tools/bin2tap.py` - Convert binary to ORIC TAP format
- `build.sh` - Build script for assembling and linking
- `oric1.cfg` - Linker configuration

## License

Public domain / educational use

## Building Oricutron on macOS

This is how I was able to build and run Oricutron on a Mac.

### 1. Install dependencies

```bash
brew install sdl2 cmake pkg-config
```

If you don't have Xcode command line tools:

```bash
xcode-select --install
```

### 2. Clone and set up the build directory

```bash
git clone https://github.com/pete-gordon/oricutron.git
cd oricutron
mkdir build && cd build
```

### 3. Create symlinks so the compiler can find SDL2 headers

```bash
sudo mkdir -p /usr/local/include/SDL
sudo ln -s $(brew --prefix sdl2)/include/SDL2/* /usr/local/include/SDL/
sudo ln -s $(brew --prefix sdl2)/include/SDL2 /usr/local/include/SDL2
```

### 4. Run cmake

```bash
cmake .. \
  -DSDL_INCLUDE_DIR=$(brew --prefix sdl2)/include/SDL2 \
  -DSDL_LIBRARY=$(brew --prefix sdl2)/lib/libSDL2.dylib
```

### 5. Patch the build files

```bash
# Remove Linux-only libraries from the linker command
sed -i '' 's/-lSDL -lGL -lX11//' CMakeFiles/Oricutron.dir/link.txt

# Remove gui_x11.c (Linux only) from the build
sed -i '' 's/gui_x11\.c//' ../CMakeLists.txt
```

### 6. Compile the macOS GUI file and add it to the build

```bash
cc -arch arm64 \
  -I$(brew --prefix sdl2)/include/SDL2 \
  -I.. \
  -c ../gui_osx.m \
  -o CMakeFiles/Oricutron.dir/gui_osx.m.o

sed -i '' 's/-o Oricutron/CMakeFiles\/Oricutron.dir\/gui_osx.m.o -o Oricutron/' \
  CMakeFiles/Oricutron.dir/link.txt

sed -i '' 's/-lintl/-lintl -framework CoreFoundation -framework Cocoa/' \
  CMakeFiles/Oricutron.dir/link.txt
```

### 7. Build

```bash
make
```

### 8. Copy ROM and image files

```bash
cp -r ../roms .
cp -r ../images .
```

### 9. Add the Oric-1 ROM

You need `basic10.rom` from the Oric community (not included in the repo for copyright reasons). Place it in the `roms/` folder.

And maybe more roms, I found a bunch here: https://www.defence-force.org/ftp/forum/amo76/Euphoric/ROMS/

### 10. Run

```bash
./Oricutron --machine atmos
# or for Oric-1:
./Oricutron --machine oric1
```
