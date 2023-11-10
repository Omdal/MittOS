INCLUDE 'hw/hwmap.asm'

RST0    EQU 11000111b
RST1    EQU 11001111b
RST2    EQU 11010111b
RST3    EQU 11011111b
RST4    EQU 11100111b
RST5    EQU 11101111b
RST6    EQU 11110111b
RST7    EQU 11111111b

    org 0000h
RST0_vec:
    ld sp, F000h
    jp Main

    org 0008h
RST1_vec:
    reti
    org 0010h
RST2_vec:
    reti
    org 0018h
RST3_vec:
    reti
    org 0020h
RST4_vec:
    reti
    org 0028h
RST5_vec:
    reti
    org 0030h
RST6_vec:
    reti
    org 0038h
RST7_vec:
IM1_vec:
    reti

    org 0066h
NMI_vec:
    retn

    org 00FEh
    reti
Main:
    
    im 2
    ld b,1
    ld c,DEBUG_LIGHTS
    out (c),b

;    ld c,  82h
;    call init_sio

    ld c,  SERIAL_CW_1
    call init_sio

    ld  hl, WelcomeMsg
    ld c, SERIAL_CW_1
    call printstring

    ld b,2
    ld c,DEBUG_LIGHTS
    out (c),b
    ld c, SERIAL_CW_1
    ld a, 0
loop:
    call printhex
    ld b, ' '
    call sio_tx_blocking
    inc a
    ;ld c, SERIAL_CW_1
    ;call sio_rx_blocking
    ;call sio_tx_blocking
    jr loop


INCLUDE 'hw/sio/sio_init.asm'
INCLUDE 'hw/sio/sio_io.asm'


printstring:
    push af
    push bc
printstring_loop:
    ld  a, (hl)
    cp  0
    jr z,printstring_done
    inc hl
    ld b,A
    call sio_tx_blocking
    jr printstring_loop
printstring_done:
    pop bc
    pop af
    ret

WelcomeMsg: db "Hello!",0

printhex:
    push af
    push bc
    push af
    rra
    rra
    rra
    rra
    call LowNibbleToChar
    ld b,a
    call sio_tx_blocking
    pop af
    call LowNibbleToChar
    ld b,a
    call sio_tx_blocking
    pop bc
    pop af
    ret

; Converts register A to a character representing the hex value of the lower nibble.
LowNibbleToChar:
    and 0Fh
    add A,'0'
    cp ':'
    ret M
    add A,7
    ret


; RAM area
    org 2000h
RAMSTART:


    END