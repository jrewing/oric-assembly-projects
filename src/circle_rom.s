; circle_rom.s - Draw circle using ROM routines
;
; Based on ORIC BASIC manual - when calling ROM routines from ML,
; we need to put parameters in specific memory locations that the
; BASIC interpreter uses.
;
; Key addresses for graphics routines:
;   HIRES  = $EC33  - switch to HIRES mode
;   TEXT   = $EC21  - switch to TEXT mode
;
; For direct pixel manipulation, let's write to HIRES memory directly.
; HIRES screen starts at $A000, 40 bytes per line, 200 lines.
;
; Screen layout: $A000 + (Y * 40) + (X / 6)
; Each byte contains 6 pixels (bits 5-0), with bits 7-6 for attributes.

.org $0600

HIRES_BASE = $A000

start:
    ; Switch to HIRES mode
    jsr $EC33           ; HIRES

    ; Set INK to yellow (color 3) for all lines where we draw
    ; INK attribute = color value (0-7), written to screen memory
    ; We need to set it at the start of lines 50-150 (vertical line range)
    ; and line 100 (horizontal line)

    ; Set yellow ink on lines 50-150
    lda #50
    sta $05             ; Y counter for ink setup

set_ink:
    ; Calculate line address
    lda $05
    sta $00
    lda #0
    sta $01
    asl $00             ; *2
    rol $01
    asl $00             ; *4
    rol $01
    asl $00             ; *8
    rol $01
    lda $00
    sta $03
    lda $01
    sta $04             ; save Y*8
    asl $00             ; *16
    rol $01
    asl $00             ; *32
    rol $01
    lda $00
    clc
    adc $03
    sta $00
    lda $01
    adc $04
    sta $01             ; Y*40
    lda $00
    clc
    adc #<HIRES_BASE
    sta $00
    lda $01
    adc #>HIRES_BASE
    sta $01

    ; Write INK 3 (yellow) attribute at start of line
    lda #3              ; INK yellow
    ldy #0
    sta ($00),y

    inc $05
    lda $05
    cmp #151
    bne set_ink

    ; Draw a simple test pattern - a horizontal line in the middle
    ; Line at Y=100, from X=0 to X=239 (full width)

    ; Calculate address: $A000 + (100 * 40) = $A000 + $FA0 = $AFA0

    ldx #1              ; X counter (bytes) - start at 1 to skip attribute
draw_line:
    lda #$3F            ; All 6 pixels on (bits 0-5 set, bits 6-7 = 00 for normal)
    sta $AFA0,x         ; Store at line 100
    inx
    cpx #40             ; 40 bytes per line
    bne draw_line

    ; Draw vertical line at X=120 (byte 20, all pixels in that byte)
    ; From Y=50 to Y=150
    lda #50
    sta $02             ; Y counter in zero page

draw_vert:
    ; Calculate address: $A000 + (Y * 40) + 20
    ; Y * 40 = Y * 8 + Y * 32 (need 16-bit math!)

    ; First: Y * 8 (16-bit result)
    lda $02             ; get Y
    sta $00             ; low byte
    lda #0
    sta $01             ; high byte = 0

    asl $00             ; *2
    rol $01
    asl $00             ; *4
    rol $01
    asl $00             ; *8
    rol $01             ; $00-$01 = Y * 8

    ; Save Y*8
    lda $00
    sta $03
    lda $01
    sta $04             ; $03-$04 = Y * 8

    ; Continue to Y * 32
    asl $00             ; *16
    rol $01
    asl $00             ; *32
    rol $01             ; $00-$01 = Y * 32

    ; Add Y*8 to get Y*40
    lda $00
    clc
    adc $03
    sta $00
    lda $01
    adc $04
    sta $01             ; $00-$01 = Y * 40

    ; Add base address $A000
    lda $00
    clc
    adc #<HIRES_BASE
    sta $00
    lda $01
    adc #>HIRES_BASE
    sta $01

    ; Add X offset (20 bytes = X position 120)
    lda $00
    clc
    adc #20
    sta $00
    lda $01
    adc #0
    sta $01

    ; Write single pixel (X=120, which is byte 20, bit 5)
    ; Pixel bits in byte: bit5=px0, bit4=px1, bit3=px2, bit2=px3, bit1=px4, bit0=px5
    ; X=120: 120/6=20 (byte), 120 mod 6=0 (pixel 0 = bit 5)
    ; Use OR to preserve existing pixels (don't erase horizontal line)
    ldy #0
    lda ($00),y         ; Read existing byte
    ora #%00100000      ; OR in bit 5 for our pixel
    sta ($00),y         ; Write back

    ; Next Y
    inc $02
    lda $02
    cmp #150
    bne draw_vert

halt:
    jmp halt
