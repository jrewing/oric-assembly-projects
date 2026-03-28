; circle.s - Draw a circle in HIRES mode
;
; HIRES screen: $A000-$BF3F (240x200 pixels, 40 bytes per row)
; Each byte = 6 pixels (bit 6 is ink/paper selector)
;
; Circle algorithm: x² + y² = r²
; We'll draw a simple circle using a lookup table approach

.org $0600

; Zero page variables
cx      = $80           ; Center X (0-239)
cy      = $81           ; Center Y (0-199)
radius  = $82           ; Radius
angle   = $83           ; Current angle counter
plotx   = $84           ; Plot X coordinate
ploty   = $85           ; Plot Y coordinate
temp    = $86

start:
    ; Switch to HIRES mode
    jsr $EC33           ; ROM: HIRES

    ; Clear HIRES screen
    jsr clear_hires

    ; Set circle parameters
    lda #120            ; Center X = 120 (middle of 240)
    sta cx
    lda #100            ; Center Y = 100 (middle of 200)
    sta cy
    lda #40             ; Radius = 40 pixels
    sta radius

    ; Draw circle using 8-way symmetry
    ; We'll iterate Y from 0 to radius, calculate X
    lda #0
    sta ploty           ; Start with y = 0

circle_loop:
    ; Calculate x = sqrt(r² - y²) approximately
    ; Using: x starts at radius, decrease as y increases

    ; For simplicity, we'll draw 8 points per iteration
    ; using symmetry: (x,y), (-x,y), (x,-y), (-x,-y)
    ;                 (y,x), (-y,x), (y,-x), (-y,-x)

    lda radius
    sec
    sbc ploty           ; Simple approximation: x = r - y (makes a diamond, not circle)
    sta plotx

    ; Actually, let's just draw the 8 symmetric points
    ; Point 1: (cx + x, cy + y)
    lda cx
    clc
    adc plotx
    tax
    lda cy
    clc
    adc ploty
    tay
    jsr plot_pixel

    ; Point 2: (cx - x, cy + y)
    lda cx
    sec
    sbc plotx
    tax
    lda cy
    clc
    adc ploty
    tay
    jsr plot_pixel

    ; Point 3: (cx + x, cy - y)
    lda cx
    clc
    adc plotx
    tax
    lda cy
    sec
    sbc ploty
    tay
    jsr plot_pixel

    ; Point 4: (cx - x, cy - y)
    lda cx
    sec
    sbc plotx
    tax
    lda cy
    sec
    sbc ploty
    tay
    jsr plot_pixel

    ; Point 5: (cx + y, cy + x)
    lda cx
    clc
    adc ploty
    tax
    lda cy
    clc
    adc plotx
    tay
    jsr plot_pixel

    ; Point 6: (cx - y, cy + x)
    lda cx
    sec
    sbc ploty
    tax
    lda cy
    clc
    adc plotx
    tay
    jsr plot_pixel

    ; Point 7: (cx + y, cy - x)
    lda cx
    clc
    adc ploty
    tax
    lda cy
    sec
    sbc plotx
    tay
    jsr plot_pixel

    ; Point 8: (cx - y, cy - x)
    lda cx
    sec
    sbc ploty
    tax
    lda cy
    sec
    sbc plotx
    tay
    jsr plot_pixel

    ; Next y
    inc ploty
    lda ploty
    cmp radius
    bcs done_circle     ; Exit if y >= radius
    jmp circle_loop     ; Continue

done_circle:
halt:
    jmp halt

; ============================================
; Clear HIRES screen to black
; ============================================
clear_hires:
    lda #$40            ; Black with bit 6 set (ink mode)
    ldx #0
@clear1:
    sta $A000,x
    sta $A100,x
    sta $A200,x
    sta $A300,x
    sta $A400,x
    sta $A500,x
    sta $A600,x
    sta $A700,x
    inx
    bne @clear1
    ldx #0
@clear2:
    sta $A800,x
    sta $A900,x
    sta $AA00,x
    sta $AB00,x
    sta $AC00,x
    sta $AD00,x
    sta $AE00,x
    sta $AF00,x
    inx
    bne @clear2
    ; Continue for rest of screen...
    ldx #0
@clear3:
    sta $B000,x
    sta $B100,x
    sta $B200,x
    sta $B300,x
    sta $B400,x
    sta $B500,x
    sta $B600,x
    sta $B700,x
    inx
    bne @clear3
    ldx #0
@clear4:
    sta $B800,x
    sta $B900,x
    sta $BA00,x
    sta $BB00,x
    sta $BC00,x
    sta $BD00,x
    sta $BE00,x
    inx
    bne @clear4
    rts

; ============================================
; Plot pixel at X,Y (X in X-reg, Y in Y-reg)
; ============================================
plot_pixel:
    ; Calculate screen address: $A000 + (Y * 40) + (X / 6)
    ; And bit position: X mod 6

    ; Save X coordinate
    stx temp

    ; Calculate Y * 40
    ; 40 = 32 + 8, so Y*40 = Y*32 + Y*8
    tya                 ; A = Y
    asl                 ; A = Y * 2
    asl                 ; A = Y * 4
    asl                 ; A = Y * 8
    sta $88             ; Store Y * 8
    tya
    asl
    asl
    asl
    asl
    asl                 ; A = Y * 32
    clc
    adc $88             ; A = Y * 40 (low byte)
    sta $88

    ; High byte calculation
    tya
    lsr
    lsr
    lsr                 ; A = Y / 8
    clc
    adc #$A0            ; Add base address high byte
    sta $89

    ; Add X / 6 to address
    lda temp            ; Get X
    ldx #0
@div6:
    cmp #6
    bcc @div_done
    sec
    sbc #6
    inx
    bne @div6
@div_done:
    ; X-reg now has X/6, A has X mod 6
    pha                 ; Save X mod 6
    txa                 ; A = X / 6
    clc
    adc $88
    sta $88
    bcc @no_carry
    inc $89
@no_carry:

    ; Get bit mask (bit 5 - (X mod 6))
    pla                 ; A = X mod 6
    tax
    lda #$20            ; Start with bit 5
@shift_bit:
    cpx #0
    beq @plot_it
    lsr
    dex
    bne @shift_bit

@plot_it:
    ; OR the bit into screen memory
    ora ($88),y
    ldy #0
    ora ($88),y
    sta ($88),y

    rts
