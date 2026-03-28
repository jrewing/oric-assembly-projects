; square.s - Draw a yellow square
;
; HIRES screen: $A000, 40 bytes per line, 200 lines
; Each byte = 6 pixels (bits 5-0)

.org $0600

HIRES_BASE = $A000

; Square bounds (centered roughly)
TOP     = 60
BOTTOM  = 140
LEFT_BYTE = 10      ; byte 10 = pixel 60
RIGHT_BYTE = 30     ; byte 30 = pixel 180

start:
    jsr $EC33           ; HIRES mode

    ; Set yellow ink on lines TOP to BOTTOM
    lda #TOP
    sta $05

set_ink:
    jsr calc_line_addr  ; get line address in $00-$01
    lda #3              ; INK yellow
    ldy #0
    sta ($00),y
    inc $05
    lda $05
    cmp #BOTTOM+1
    bne set_ink

    ; Draw top horizontal line (Y=TOP)
    lda #TOP
    sta $05
    jsr calc_line_addr
    ldy #LEFT_BYTE
draw_top:
    lda #$3F            ; all 6 pixels
    sta ($00),y
    iny
    cpy #RIGHT_BYTE+1
    bne draw_top

    ; Draw bottom horizontal line (Y=BOTTOM)
    lda #BOTTOM
    sta $05
    jsr calc_line_addr
    ldy #LEFT_BYTE
draw_bottom:
    lda #$3F
    sta ($00),y
    iny
    cpy #RIGHT_BYTE+1
    bne draw_bottom

    ; Draw left vertical line (X=LEFT_BYTE pixel 0, Y from TOP to BOTTOM)
    lda #TOP
    sta $05
draw_left:
    jsr calc_line_addr
    ldy #LEFT_BYTE
    lda ($00),y         ; read existing
    ora #%00100000      ; set leftmost pixel (bit 5)
    sta ($00),y
    inc $05
    lda $05
    cmp #BOTTOM+1
    bne draw_left

    ; Draw right vertical line (X=RIGHT_BYTE pixel 5 = rightmost)
    lda #TOP
    sta $05
draw_right:
    jsr calc_line_addr
    ldy #RIGHT_BYTE
    lda ($00),y         ; read existing
    ora #%00000001      ; set rightmost pixel (bit 0)
    sta ($00),y
    inc $05
    lda $05
    cmp #BOTTOM+1
    bne draw_right

halt:
    jmp halt

; ============================================
; calc_line_addr: Calculate address for line $05
; Result in $00-$01
; ============================================
calc_line_addr:
    lda $05
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
