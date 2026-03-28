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

| File | Description |
|------|-------------|
| `src/hello.s` | Display "ABC" in RGB colors (TEXT mode) |
| `src/square.s` | Draw a yellow square (HIRES mode) |
| `src/bounce.s` | Animated bouncing square (HIRES mode) |
| `src/hires.s` | HIRES mode test |
| `src/circle.s` | Manual circle drawing experiment |
| `src/circle_rom.s` | Cross pattern with pixel-level control |

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
