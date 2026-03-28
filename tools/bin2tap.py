#!/usr/bin/env python3
"""
bin2tap.py - Convert binary files to ORIC TAP format
Based on OSDK Header tool format
Usage: bin2tap.py input.bin output.tap [start_address] [name]
"""

import sys

def create_tap(input_file, output_file, start_addr=0x0600, name="PROGRAM", auto_run=False):
    """Create an ORIC TAP file from a binary."""

    # Read the binary data
    with open(input_file, 'rb') as f:
        data = f.read()

    end_addr = start_addr + len(data) - 1

    # ORIC TAP format (from OSDK header.cpp):
    #
    # 0x16, 0x16, 0x16  - 3 Sync bytes
    # 0x24              - Sync terminator
    # 0x00              - Always 0
    # 0x00              - Always 0
    # 0x80              - File type: 0x00=BASIC, 0x80=Binary/Machine code
    # 0x00 or 0xC7      - Auto-run: 0x00=no auto, 0xC7=assembly autostart
    # END_H, END_L      - End address (HIGH byte first!)
    # START_H, START_L  - Start address (HIGH byte first!)
    # 0x00              - Separator
    # filename + 0x00   - Null-terminated filename
    # data...           - Program data

    tap_data = bytearray()

    # Sync bytes (3 bytes as per OSDK)
    tap_data.extend([0x16, 0x16, 0x16])

    # Sync terminator
    tap_data.append(0x24)

    # Header bytes 4-5: always 00 00
    tap_data.append(0x00)
    tap_data.append(0x00)

    # Byte 6: File type - 0x80 = machine code
    tap_data.append(0x80)

    # Byte 7: Auto-run flag - 0xC7 = assembly autostart, 0x00 = no autostart
    if auto_run:
        tap_data.append(0xC7)
    else:
        tap_data.append(0x00)

    # Bytes 8-9: End address (HIGH byte, LOW byte)
    tap_data.append((end_addr >> 8) & 0xFF)
    tap_data.append(end_addr & 0xFF)

    # Bytes 10-11: Start address (HIGH byte, LOW byte)
    tap_data.append((start_addr >> 8) & 0xFF)
    tap_data.append(start_addr & 0xFF)

    # Byte 12: Separator (always 0x00)
    tap_data.append(0x00)

    # Filename (null-terminated)
    name_bytes = name.upper()[:15].encode('ascii')
    tap_data.extend(name_bytes)
    tap_data.append(0x00)

    # Program data
    tap_data.extend(data)

    # Write the TAP file
    with open(output_file, 'wb') as f:
        f.write(tap_data)

    print(f"Created TAP file: {output_file}")
    print(f"  Program: {name}")
    print(f"  Start address: ${start_addr:04X}")
    print(f"  End address: ${end_addr:04X}")
    print(f"  Size: {len(data)} bytes")

def main():
    if len(sys.argv) < 3:
        print("Usage: bin2tap.py input.bin output.tap [start_address] [name]")
        print("  start_address: hex address like 0x0500 or 500 (default: 0x0500)")
        print("  name: program name (default: PROGRAM)")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Parse start address
    start_addr = 0x0500
    if len(sys.argv) > 3:
        addr_str = sys.argv[3]
        if addr_str.startswith('0x') or addr_str.startswith('$'):
            start_addr = int(addr_str.replace('$', '0x'), 16)
        else:
            start_addr = int(addr_str)

    # Program name
    name = sys.argv[4] if len(sys.argv) > 4 else "PROGRAM"

    create_tap(input_file, output_file, start_addr, name)

if __name__ == "__main__":
    main()
