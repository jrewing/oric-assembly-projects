; bounce.s - Bouncing yellow square animation
;
; HIRES screen: $A000, 40 bytes per line, 200 lines
; Each byte = 6 pixels (bits 5-0)

.org $0600

HIRES_BASE = $A000

; Square size
SIZE = 40           ; 40 pixels tall

; Movement bounds
MIN_Y = 10
MAX_Y = 150         ; 200 - SIZE - some margin

; Variables in zero page
Y_POS    = $10      ; current Y position of top of square
DIR      = $11      ; direction: 0=down, 1=up
LINE_Y   = $05      ; temp for line calculations

LEFT_BYTE = 15
RIGHT_BYTE = 25

start:
    jsr $EC33           ; HIRES mode

    ; Set yellow ink for entire screen area we might use
    lda #MIN_Y
    sta LINE_Y
set_ink:
    jsr calc_line_addr
    lda #3              ; INK yellow
    ldy #0
    sta ($00),y
    inc LINE_Y
    lda LINE_Y
    cmp #MAX_Y+SIZE+1
    bne set_ink

    ; Initialize position and direction
    lda #MIN_Y
    sta Y_POS
    lda #0              ; start moving down
    sta DIR

main_loop:
    ; XOR square at current position (draws it)
    jsr xor_square

    ; Delay for visibility
    jsr delay

    ; XOR square again at current position (erases it)
    jsr xor_square

    ; Update position based on direction
    lda DIR
    bne move_up

move_down:
    inc Y_POS
    lda Y_POS
    cmp #MAX_Y
    bne main_loop
    ; Hit bottom, reverse direction
    lda #1
    sta DIR
    jmp main_loop

move_up:
    dec Y_POS
    lda Y_POS
    cmp #MIN_Y
    bne main_loop
    ; Hit top, reverse direction
    lda #0
    sta DIR
    jmp main_loop

; ============================================
; xor_square: XOR square at Y_POS (draws or erases)
; ============================================
xor_square:
    ; Top line
    lda Y_POS
    sta LINE_Y
    jsr calc_line_addr
    ldy #LEFT_BYTE
xor_top:
    lda ($00),y
    eor #$3F            ; toggle all 6 pixels
    sta ($00),y
    iny
    cpy #RIGHT_BYTE+1
    bne xor_top

    ; Bottom line
    lda Y_POS
    clc
    adc #SIZE
    sta LINE_Y
    jsr calc_line_addr
    ldy #LEFT_BYTE
xor_bottom:
    lda ($00),y
    eor #$3F
    sta ($00),y
    iny
    cpy #RIGHT_BYTE+1
    bne xor_bottom

    ; Left line (skip top and bottom corners - already done)
    lda Y_POS
    clc
    adc #1              ; start 1 below top
    sta LINE_Y
xor_left:
    jsr calc_line_addr
    ldy #LEFT_BYTE
    lda ($00),y
    eor #%00100000      ; toggle leftmost pixel
    sta ($00),y
    inc LINE_Y
    lda LINE_Y
    sec
    sbc Y_POS
    cmp #SIZE           ; stop 1 before bottom
    bne xor_left

    ; Right line (skip top and bottom corners - already done)
    lda Y_POS
    clc
    adc #1
    sta LINE_Y
xor_right:
    jsr calc_line_addr
    ldy #RIGHT_BYTE
    lda ($00),y
    eor #%00000001      ; toggle rightmost pixel
    sta ($00),y
    inc LINE_Y
    lda LINE_Y
    sec
    sbc Y_POS
    cmp #SIZE
    bne xor_right

    rts

; ============================================
; delay: Simple delay loop
; ============================================
delay:
    ldx #$10
delay_outer:
    ldy #$FF
delay_inner:
    dey
    bne delay_inner
    dex
    bne delay_outer
    rts

; ============================================
; calc_line_addr: Calculate address for line LINE_Y
; Result in $00-$01
; ============================================
calc_line_addr:
    lda LINE_Y
    sta $00
    lda #0
    sta $01

    ; Multiply by 8
    asl $00
    rol $01
    asl $00
    rol $01
    asl $00
    rol $01

    ; Save Y*8
    lda $00
    sta $03
    lda $01
    sta $04

    ; Continue to Y*32
    asl $00
    rol $01
    asl $00
    rol $01

    ; Add Y*8 to get Y*40
    lda $00
    clc
    adc $03
    sta $00
    lda $01
    adc $04
    sta $01

    ; Add base address
    lda $00
    clc
    adc #<HIRES_BASE
    sta $00
    lda $01
    adc #>HIRES_BASE
    sta $01

    rts
