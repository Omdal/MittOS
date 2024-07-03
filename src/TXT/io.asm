printstring:
    push af
    push bc
    push hl
    ld  c, SERIAL_CW_1              ; Update to correct output
_printstring_loop:
    ld  a, (hl)
    cp  0
    jr z,_printstring_done
    inc hl
    call sio_tx_blocking
    jr _printstring_loop
_printstring_done:
    pop hl
    pop bc
    pop af
    ret

printstringLength:
    push af
    push bc
    push de
    push hl
    ld  c, SERIAL_CW_1              ; Update to correct output
_printstringLength_loop:
    ld a,(HL)
    call sio_tx_blocking
    inc hl
    djnz    _printstringLength_loop
    pop hl
    pop de
    pop bc
    pop af
    ret


printChar:
    push bc
    ld      c,  SERIAL_CW_1
    call    sio_tx_blocking
    pop bc
    ret

printCRLF:
    push af
    push bc
    ld c, SERIAL_CW_1
    ld a, 0Dh
    call sio_tx_blocking
    ld a, 0Ah
    call sio_tx_blocking
    pop bc
    pop af
    ret



printAsHex:
    push af
    push bc
    push af
    ld      c,  SERIAL_CW_1
    rra
    rra
    rra
    rra
    call LowNibbleToChar
    call sio_tx_blocking
    pop af
    call LowNibbleToChar
    call sio_tx_blocking
    pop bc
    pop af
    ret

; Converts register A to a character representing the hex value of the lower nibble.
LowNibbleToChar:
    and 0Fh         ; Isolate lower nibble
    add A,  '0'     ; Add Zero-character to start at '0'
    cp  ':'         ; Check if character is greater than '9'
    ret M           ; Return if character is a number
    add A,  7       ; Add 7 to change character to a letter
    ret

CharToNibble:
    sub A,  '0'
    jr  C, CharToNibble_Error
    cp  10
    jr  C, CharToNibble_Store
    sub A,  7       ; Convert A-F to 10-15
    jr  C, CharToNibble_Error   ; Char was between 9 and A (Invalid)
    cp  10h
    jr  C, CharToNibble_Error   ; Char is higher than F     TODO: convert a-f too
CharToNibble_Store:
    sla B
    sla B
    sla B
    sla B                       ; Shift out upper Nibble
    or  B                       ; Combine upper and lower Nibble
    ld  B,  A                   ; Move back to B register
    xor A
    ret
CharToNibble_Error:
    ld A,   -1      ; Char is not a number
    ret


PrintUint16_t:
    ex af, af'
    exx
    pop DE
    ld (SCRATCHPAD), DE ; Return address
    pop DE
    ld (SCRATCHPAD+2), DE ; 16bit number 

    LD HL, SCRATCHPAD +2
    LD E, (HL)     ; High byte
    LD C, 10    ; Div by 10
    LD D, 0     ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +8
    LD (HL), D ; Save modulus as last number

    LD HL, SCRATCHPAD +2
    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +7
    LD (HL), D ; Save modulus as last number

    LD HL, SCRATCHPAD +2
    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +6
    LD (HL), D ; Save modulus as last number
    LD HL, SCRATCHPAD +2

    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +5
    LD (HL), D ; Save modulus as last number
    LD HL, SCRATCHPAD +2

    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +4
    LD (HL), D ; Save modulus as last number

    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar


    ld DE, (SCRATCHPAD) ; Load return address
    push DE             ; Return it to the stack
    exx
    ex af, af'
    ret





PrintUint32_t:
    ex af, af'
    exx
    pop DE
    ld (SCRATCHPAD), DE ; Return address
    pop DE
    ld (SCRATCHPAD+2), DE ; 32bit number 
    pop DE
    ld (SCRATCHPAD+4), DE ; 32bit number 


    LD HL, SCRATCHPAD +2
    LD E, (HL)  ; 1st byte
    LD C, 10    ; Div by 10
    LD D, 0     ; Reset calculation
    Call _Divide
    LD (HL), E ; Save 1st byte
    INC HL
    LD E, (HL) ; Load 2nd byte
    Call _Divide
    LD (HL), E ; Save 2nd byte
    INC HL
    LD E, (HL) ; Load 3rd byte
    Call _Divide
    LD (HL), E ; Save 3rd byte
    INC HL
    LD E, (HL) ; Load 4th byte
    Call _Divide
    LD (HL), E ; Save 4th byte
    LD HL, SCRATCHPAD +15
    LD (HL), D

    LD HL, SCRATCHPAD +8
    LD (HL), D ; Save modulus as last number

    LD HL, SCRATCHPAD +2
    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +7
    LD (HL), D ; Save modulus as last number

    LD HL, SCRATCHPAD +2
    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +6
    LD (HL), D ; Save modulus as last number
    LD HL, SCRATCHPAD +2

    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +5
    LD (HL), D ; Save modulus as last number
    LD HL, SCRATCHPAD +2

    LD E, (HL) ; High byte
    LD D, 0              ; Reset calculation
    Call _Divide
    LD (HL), E ; Save high byte
    INC HL
    LD E, (HL) ; Load low byte
    Call _Divide
    LD (HL), E ; Save low byte
    LD HL, SCRATCHPAD +4
    LD (HL), D ; Save modulus as last number

    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar

    INC HL
    ld a,(HL)
    add a, '0'
    call printChar


    ld DE, (SCRATCHPAD) ; Load return address
    push DE             ; Return it to the stack
    exx
    ex af, af'
    ret



; --- INPUT ---
; C = Divisor
; D = Modulus from ongoing calculation
; E = Quotient
; --- OUTPUT ---
; D = Modulus
; E = Dividend
_Divide:
    PUSH BC
    LD B, 9
_Divide_Loop:
    LD A, D 
    SUB C
    CCF
    JR NC, _Divide_NF
    LD D, A
_Divide_NF:
    RL E
    RL D
    DJNZ _Divide_Loop
    RR D
    POP BC
    RET