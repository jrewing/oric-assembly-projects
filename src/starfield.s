; starfield.s - Parallax starfield effect
;
; Three layers of stars moving at different speeds
; Simple and clean implementation

.org $0600

HIRES_BASE = $A000
NUM_STARS = 12          ; stars per layer

; Zero page variables
FRAME_COUNT = $10
BYTE_OFFSET = $12
PIXEL_MASK = $13
CURRENT_X = $14
CURRENT_Y = $15
SPEED = $16

start:
    jsr $EC33           ; HIRES mode

    ; Set white ink for whole screen
    ldx #0
set_ink:
    txa
    jsr calc_line_addr
    lda #7              ; white ink
    ldy #0
    sta ($00),y
    inx
    cpx #200
    bne set_ink

    lda #0
    sta FRAME_COUNT

    ; Draw initial stars (so first XOR will erase them properly)
    jsr draw_initial_stars

; ============================================
; MAIN LOOP
; ============================================
main_loop:
    ; --- Layer 1: Fast stars (speed 2) ---
    lda #2
    sta SPEED
    ldx #0
layer1_loop:
    ; Erase old star
    lda stars1_x,x
    sta CURRENT_X
    lda stars1_y,x
    sta CURRENT_Y
    stx $17             ; save X
    jsr plot_star
    ldx $17             ; restore X

    ; Move star left
    lda stars1_x,x
    sec
    sbc SPEED
    bcs l1_no_wrap
    lda #239            ; wrap to right
l1_no_wrap:
    sta stars1_x,x

    ; Draw new star
    sta CURRENT_X
    stx $17
    jsr plot_star
    ldx $17

    inx
    cpx #NUM_STARS
    bne layer1_loop

    ; --- Layer 2: Medium stars (speed 1) ---
    lda #1
    sta SPEED
    ldx #0
layer2_loop:
    lda stars2_x,x
    sta CURRENT_X
    lda stars2_y,x
    sta CURRENT_Y
    stx $17
    jsr plot_star
    ldx $17

    lda stars2_x,x
    sec
    sbc SPEED
    bcs l2_no_wrap
    lda #239
l2_no_wrap:
    sta stars2_x,x
    sta CURRENT_X
    stx $17
    jsr plot_star
    ldx $17

    inx
    cpx #NUM_STARS
    bne layer2_loop

    ; --- Layer 3: Slow stars (every other frame) ---
    lda FRAME_COUNT
    and #1
    bne skip_layer3

    ldx #0
layer3_loop:
    lda stars3_x,x
    sta CURRENT_X
    lda stars3_y,x
    sta CURRENT_Y
    stx $17
    jsr plot_star
    ldx $17

    lda stars3_x,x
    sec
    sbc #1
    bcs l3_no_wrap
    lda #239
l3_no_wrap:
    sta stars3_x,x
    sta CURRENT_X
    stx $17
    jsr plot_star
    ldx $17

    inx
    cpx #NUM_STARS
    bne layer3_loop

skip_layer3:
    inc FRAME_COUNT

    ; Small delay for visibility
    jsr delay

    jmp main_loop

; ============================================
; draw_initial_stars: Draw all stars once at startup
; ============================================
draw_initial_stars:
    ; Layer 1
    ldx #0
init_l1:
    lda stars1_x,x
    sta CURRENT_X
    lda stars1_y,x
    sta CURRENT_Y
    stx $17
    jsr plot_star
    ldx $17
    inx
    cpx #NUM_STARS
    bne init_l1

    ; Layer 2
    ldx #0
init_l2:
    lda stars2_x,x
    sta CURRENT_X
    lda stars2_y,x
    sta CURRENT_Y
    stx $17
    jsr plot_star
    ldx $17
    inx
    cpx #NUM_STARS
    bne init_l2

    ; Layer 3
    ldx #0
init_l3:
    lda stars3_x,x
    sta CURRENT_X
    lda stars3_y,x
    sta CURRENT_Y
    stx $17
    jsr plot_star
    ldx $17
    inx
    cpx #NUM_STARS
    bne init_l3

    rts

; ============================================
; plot_star: XOR a pixel at (CURRENT_X, CURRENT_Y)
; ============================================
plot_star:
    ; Calculate line address
    lda CURRENT_Y
    jsr calc_line_addr

    ; Calculate byte offset = X / 6
    lda CURRENT_X
    ldy #0              ; byte counter
divide_by_6:
    cmp #6
    bcc divide_done
    sec
    sbc #6
    iny
    bne divide_by_6     ; always branches
divide_done:
    ; A = remainder (0-5), Y = byte offset
    sty BYTE_OFFSET
    tax                 ; X = pixel position (0-5)
    lda pixel_masks,x
    sta PIXEL_MASK

    ; XOR pixel onto screen
    ldy BYTE_OFFSET
    lda ($00),y
    eor PIXEL_MASK
    sta ($00),y

    rts

; ============================================
; calc_line_addr: Address for line A -> $00-$01
; ============================================
calc_line_addr:
    sta $00
    lda #0
    sta $01

    ; Y * 8
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

    ; Y * 32
    asl $00
    rol $01
    asl $00
    rol $01

    ; Add for Y*40
    lda $00
    clc
    adc $03
    sta $00
    lda $01
    adc $04
    sta $01

    ; Add base
    lda $00
    clc
    adc #<HIRES_BASE
    sta $00
    lda $01
    adc #>HIRES_BASE
    sta $01

    rts

; ============================================
; delay
; ============================================
delay:
    ldx #$06
delay_outer:
    ldy #$FF
delay_inner:
    dey
    bne delay_inner
    dex
    bne delay_outer
    rts

; ============================================
; DATA
; ============================================

; Pixel masks for positions 0-5 within a byte
pixel_masks:
    .byte %00100000     ; pixel 0 (leftmost)
    .byte %00010000     ; pixel 1
    .byte %00001000     ; pixel 2
    .byte %00000100     ; pixel 3
    .byte %00000010     ; pixel 4
    .byte %00000001     ; pixel 5 (rightmost)

; Layer 1 - fast stars (12 stars)
; Y values unique to this layer (no overlap with other layers)
stars1_x:
    .byte 17, 189, 82, 231, 39, 147, 5, 168, 103, 58, 211, 124
stars1_y:
    .byte 101, 5, 149, 37, 181, 69, 117, 21, 165, 85, 53, 133

; Layer 2 - medium stars (12 stars)
; Y values unique to this layer
stars2_x:
    .byte 142, 29, 183, 71, 214, 97, 156, 43, 199, 115, 62, 171
stars2_y:
    .byte 74, 154, 26, 106, 186, 42, 138, 10, 170, 58, 122, 90

; Layer 3 - slow stars (12 stars)
; Y values unique to this layer
stars3_x:
    .byte 89, 203, 51, 167, 23, 138, 76, 219, 104, 187, 33, 152
stars3_y:
    .byte 143, 47, 175, 79, 15, 127, 63, 191, 31, 111, 159, 95
