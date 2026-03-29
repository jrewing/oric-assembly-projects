/*
 * bounce.c - Bouncing square in C for ORIC
 *
 * Compile with cc65 toolchain:
 *   cc65 -t atmos -O bounce.c -o bounce.s
 *   ca65 -t atmos bounce.s -o bounce.o
 *   ld65 -t atmos -o bounce.bin bounce.o atmos.lib
 */

#include <stdio.h>

/* HIRES screen base address */
#define HIRES_BASE  0xA000

/* ROM routine addresses */
#define HIRES_ROM   0xEC33

/* Square parameters */
#define SIZE        40
#define MIN_Y       10
#define MAX_Y       150
#define LEFT_BYTE   15
#define RIGHT_BYTE  25

/* Function pointer to call ROM routines */
typedef void (*rom_func)(void);

/* Call HIRES ROM routine */
void hires(void) {
    rom_func func = (rom_func)HIRES_ROM;
    func();
}

/* Calculate screen address for a line */
unsigned char* line_addr(unsigned char y) {
    return (unsigned char*)(HIRES_BASE + (unsigned int)y * 40);
}

/* Set ink color for lines */
void set_ink(unsigned char from, unsigned char to, unsigned char color) {
    unsigned char y;
    for (y = from; y <= to; y++) {
        line_addr(y)[0] = color;
    }
}

/* XOR a horizontal line */
void xor_hline(unsigned char y, unsigned char x1, unsigned char x2) {
    unsigned char* line = line_addr(y);
    unsigned char x;
    for (x = x1; x <= x2; x++) {
        line[x] ^= 0x3F;
    }
}

/* XOR a vertical line (single pixel) */
void xor_vline(unsigned char x_byte, unsigned char y1, unsigned char y2, unsigned char pixel_mask) {
    unsigned char y;
    for (y = y1; y <= y2; y++) {
        line_addr(y)[x_byte] ^= pixel_mask;
    }
}

/* XOR draw the square at position y_pos */
void xor_square(unsigned char y_pos) {
    /* Top and bottom horizontal lines */
    xor_hline(y_pos, LEFT_BYTE, RIGHT_BYTE);
    xor_hline(y_pos + SIZE, LEFT_BYTE, RIGHT_BYTE);

    /* Left and right vertical lines (skip corners) */
    xor_vline(LEFT_BYTE, y_pos + 1, y_pos + SIZE - 1, 0x20);   /* bit 5 */
    xor_vline(RIGHT_BYTE, y_pos + 1, y_pos + SIZE - 1, 0x01);  /* bit 0 */
}

/* Simple delay */
void delay(void) {
    unsigned int i;
    for (i = 0; i < 2000; i++) {
        /* do nothing */
    }
}

/* Main program */
int main(void) {
    unsigned char y_pos = MIN_Y;
    unsigned char dir = 0;  /* 0 = down, 1 = up */

    /* Switch to HIRES mode */
    hires();

    /* Set yellow ink for entire movement area */
    set_ink(MIN_Y, MAX_Y + SIZE, 3);

    /* Main loop */
    while (1) {
        /* Draw square */
        xor_square(y_pos);

        /* Delay */
        delay();

        /* Erase square */
        xor_square(y_pos);

        /* Move */
        if (dir == 0) {
            /* Moving down */
            y_pos++;
            if (y_pos >= MAX_Y) {
                dir = 1;
            }
        } else {
            /* Moving up */
            y_pos--;
            if (y_pos <= MIN_Y) {
                dir = 0;
            }
        }
    }

    return 0;
}
