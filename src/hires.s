; hires.s - ORIC HIRES mode experiment
; Displays colored text in HIRES mode
;
; HIRES screen: $A000-$BF3F (240x200 pixels)
; Text area in HIRES: $BF68-$BFE7 (3 lines of 40 chars at bottom)
;
; To enter HIRES: call $EC33 or write to control registers
; To exit HIRES: call $EC3F (TEXT mode)

.org $0600

start:
    ; Switch to HIRES mode
    jsr $EC33           ; ROM: HIRES

    ; Clear some of the hires screen area with a pattern
    ldx #0
clear_loop:
    lda #$55            ; Alternating pattern
    sta $A000,x
    sta $A100,x
    sta $A200,x
    sta $A300,x
    inx
    bne clear_loop

    ; Write colored text to the text area at bottom of HIRES
    ; Text area starts at $BF68 (3 lines of 40 chars)

    ; Red 'A'
    lda #1              ; INK = Red
    sta $BF68
    lda #65             ; 'A'
    sta $BF69

    ; Green 'B'
    lda #2              ; INK = Green
    sta $BF6A
    lda #66             ; 'B'
    sta $BF6B

    ; Blue 'C'
    lda #4              ; INK = Blue
    sta $BF6C
    lda #67             ; 'C'
    sta $BF6D

    ; Reset to white
    lda #7
    sta $BF6E

    ; Infinite loop - press F2 to exit
halt:
    jmp halt
