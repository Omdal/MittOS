
    ld sp, F000h
    jp Main

    org 0066h
NMI:
    retn

    org 0100h
    reti
Main:
    
    im 2
    ld b,1
    ld c,0
    out (c),b

;    ld c,  82h
;    call init_sio

    ld c,  80h
    call init_sio

    ld  hl, WelcomeMsg
    ld c, 80h
    call printstring

    ld b,2
    ld c,0
    out (c),b
    ld c, 80h
loop:
    ld c, 80h
    call sio_rx_blocking
    call sio_tx_blocking
    jr loop


INCLUDE 'sio_init.asm'
INCLUDE 'sio_io.asm'


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

    END