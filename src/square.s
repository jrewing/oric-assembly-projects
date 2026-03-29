; square.s - Draw a yellow square
;
; HIRES screen: $A000, 40 bytes per line, 200 lines
; Each byte = 6 pixels (bits 5-0)
;
; ============================================
; ASSEMBLY BASICS - A TUTORIAL
; ============================================
;
; REGISTERS - The CPU has only 3 "variables" built-in:
;   A  = Accumulator (8-bit) - main register for math/data
;   X  = Index register (8-bit) - often used for loops/offsets
;   Y  = Index register (8-bit) - often used for loops/offsets
;
; FLAGS - The CPU also tracks status after operations:
;   Z (Zero)     - set if result was 0
;   C (Carry)    - set if overflow/borrow occurred
;   N (Negative) - set if bit 7 of result is 1
;
; KEY INSTRUCTIONS used in this file:
;   lda #value  - Load A with immediate value (# means literal number)
;   lda addr    - Load A from memory address
;   sta addr    - Store A to memory address
;   ldx, ldy    - Load X or Y register
;   inx, iny    - Increment X or Y by 1
;   inc addr    - Increment value at memory address
;   asl         - Arithmetic Shift Left (multiply by 2)
;   rol         - Rotate Left through Carry (for 16-bit shifts)
;   clc         - Clear Carry flag (do before addition)
;   adc         - Add with Carry (A = A + value + carry)
;   cmp         - Compare A with value (sets flags, doesn't change A)
;   cpx, cpy    - Compare X or Y with value
;   bne label   - Branch if Not Equal (if Z flag is clear)
;   jsr label   - Jump to SubRoutine (pushes return address to stack)
;   rts         - Return from Subroutine (pops address from stack)
;   jmp label   - Jump (goto, never returns)
;   ora         - OR with Accumulator (A = A | value)
;
; ADDRESSING MODES:
;   #$3F        - Immediate: literal value $3F (63 decimal)
;   $05         - Zero Page: memory address $0005 (fast, 1 byte address)
;   $A000       - Absolute: memory address $A000 (2 byte address)
;   ($00),y     - Indirect Indexed: address at $00-$01, offset by Y
;                 Example: if $00=$40, $01=$A0, Y=5, reads from $A045
;
; ============================================

.org $0600                  ; Tell assembler: put this code at address $0600

; ============================================
; CONSTANTS - these are replaced at assembly time (like #define in C)
; ============================================
HIRES_BASE = $A000          ; HIRES screen starts here

; Square bounds (in screen coordinates)
TOP     = 60                ; Y coordinate of top edge
BOTTOM  = 140               ; Y coordinate of bottom edge
LEFT_BYTE = 10              ; Byte offset (10 * 6 = pixel 60)
RIGHT_BYTE = 30             ; Byte offset (30 * 6 = pixel 180)

; ============================================
; PROGRAM ENTRY POINT
; ============================================
start:                      ; Label marking program start
    jsr $EC33               ; Call ROM routine: switch to HIRES mode
                            ; JSR = Jump to SubRoutine, will return here

    ; ----------------------------------------
    ; SET INK COLOR FOR ALL LINES WE'LL DRAW
    ; We store yellow (3) at start of each line
    ; ----------------------------------------
    lda #TOP                ; A = 60 (the # means "literal value")
    sta $05                 ; Store A to memory address $05 (our Y counter)
                            ; Zero page ($00-$FF) is fast to access

set_ink:                    ; Label - we'll loop back here
    jsr calc_line_addr      ; Call our subroutine, result in $00-$01
    lda #3                  ; A = 3 (yellow ink attribute)
    ldy #0                  ; Y = 0 (offset)
    sta ($00),y             ; Store A to address ($00-$01) + Y
                            ; This is "indirect indexed" addressing
    inc $05                 ; Increment our Y counter at address $05
    lda $05                 ; Load counter back to A
    cmp #BOTTOM+1           ; Compare A with 141
    bne set_ink             ; Branch if Not Equal - loop back if A != 141
                            ; (cmp sets Z flag if equal)

    ; ----------------------------------------
    ; DRAW TOP HORIZONTAL LINE
    ; ----------------------------------------
    lda #TOP                ; A = 60
    sta $05                 ; Set Y position
    jsr calc_line_addr      ; Calculate screen address -> $00-$01
    ldy #LEFT_BYTE          ; Y = 10 (starting byte offset)

draw_top:                   ; Loop label
    lda #$3F                ; A = %00111111 (all 6 pixels on)
    sta ($00),y             ; Write to screen at calculated address + Y
    iny                     ; Y = Y + 1 (move to next byte)
    cpy #RIGHT_BYTE+1       ; Compare Y with 31
    bne draw_top            ; Loop if Y != 31

    ; ----------------------------------------
    ; DRAW BOTTOM HORIZONTAL LINE
    ; Same pattern as top, just at Y=BOTTOM
    ; ----------------------------------------
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

    ; ----------------------------------------
    ; DRAW LEFT VERTICAL LINE
    ; Loop through Y values, plot single pixel
    ; ----------------------------------------
    lda #TOP
    sta $05                 ; Start at top Y position

draw_left:
    jsr calc_line_addr      ; Get address for current line
    ldy #LEFT_BYTE          ; Byte offset
    lda ($00),y             ; Read existing byte (preserve other pixels!)
    ora #%00100000          ; OR with bit 5 = leftmost pixel in byte
                            ; ORA preserves existing bits, just adds ours
    sta ($00),y             ; Write back
    inc $05                 ; Next Y line
    lda $05
    cmp #BOTTOM+1
    bne draw_left           ; Loop until done

    ; ----------------------------------------
    ; DRAW RIGHT VERTICAL LINE
    ; Same as left, but at RIGHT_BYTE with bit 0
    ; ----------------------------------------
    lda #TOP
    sta $05

draw_right:
    jsr calc_line_addr
    ldy #RIGHT_BYTE
    lda ($00),y             ; Read existing
    ora #%00000001          ; OR with bit 0 = rightmost pixel in byte
    sta ($00),y
    inc $05
    lda $05
    cmp #BOTTOM+1
    bne draw_right

; ----------------------------------------
; INFINITE LOOP - program stays here forever
; Without this, CPU would execute random memory!
; ----------------------------------------
halt:
    jmp halt                ; Jump to self = infinite loop

; ============================================
; SUBROUTINE: calc_line_addr
; ============================================
; Input:  $05 = Y line number (0-199)
; Output: $00-$01 = screen address for that line
;
; Formula: address = $A000 + (Y * 40)
;
; Since 6502 can only do 8-bit math, we need tricks:
;   Y * 40 = Y * 32 + Y * 8
;   We compute this with shifts (multiply by 2)
; ============================================
calc_line_addr:
    lda $05                 ; Load Y line number
    sta $00                 ; Store in $00 (low byte of result)
    lda #0
    sta $01                 ; High byte = 0

    ; Multiply by 8 using left shifts
    ; ASL = Arithmetic Shift Left = multiply by 2
    ; ROL = Rotate Left = shift high byte, bring in carry
    asl $00                 ; $00 *= 2
    rol $01                 ; $01 catches overflow
    asl $00                 ; $00 *= 2 (total: *4)
    rol $01
    asl $00                 ; $00 *= 2 (total: *8)
    rol $01                 ; Now $00-$01 = Y * 8

    ; Save Y*8 for later
    lda $00
    sta $03
    lda $01
    sta $04                 ; $03-$04 = Y * 8

    ; Continue shifting to get Y*32
    asl $00                 ; *16
    rol $01
    asl $00                 ; *32
    rol $01                 ; Now $00-$01 = Y * 32

    ; Add Y*8 to get Y*40
    ; CLC = Clear Carry (required before ADC)
    ; ADC = Add with Carry
    lda $00
    clc                     ; Clear carry before addition
    adc $03                 ; A = low(Y*32) + low(Y*8)
    sta $00
    lda $01
    adc $04                 ; A = high(Y*32) + high(Y*8) + carry
    sta $01                 ; Now $00-$01 = Y * 40

    ; Add base address $A000
    ; #<HIRES_BASE = low byte of $A000 = $00
    ; #>HIRES_BASE = high byte of $A000 = $A0
    lda $00
    clc
    adc #<HIRES_BASE        ; Add low byte ($00)
    sta $00
    lda $01
    adc #>HIRES_BASE        ; Add high byte ($A0)
    sta $01                 ; Now $00-$01 = $A000 + Y*40

    rts                     ; Return from Subroutine
                            ; CPU pops return address from stack
                            ; and continues after the JSR that called us
