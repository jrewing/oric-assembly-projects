; hello.s - ORIC Assembly: RGB colored text
; Displays A B C in Red, Green, Blue
;
; ORIC Color Attributes (ink/paper):
;   $00 = Black    $04 = Blue
;   $01 = Red      $05 = Magenta
;   $02 = Green    $06 = Cyan
;   $03 = Yellow   $07 = White
;
; To set INK color: write value 0-7 to screen
; To set PAPER color: write value 16-23 to screen

.org $0600

start:
    ; Red 'A'
    lda #1              ; INK = Red (attribute)
    sta $BB80
    lda #65             ; 'A'
    sta $BB81

    ; Green 'B'
    lda #2              ; INK = Green
    sta $BB82
    lda #66             ; 'B'
    sta $BB83

    ; Blue 'C'
    lda #4              ; INK = Blue
    sta $BB84
    lda #67             ; 'C'
    sta $BB85

    ; Reset to white
    lda #7              ; INK = White
    sta $BB86

    ; Infinite loop - press F2 (NMI) to break out
halt:
    jmp halt
