;###############################################################################
; SIO initialization procedure.
;
; Used registers:
;   HL,B,C
;
; Preload registers:
;   C = HW-port for channel control word
;###############################################################################
init_sio:
    push    hl
    push    bc
    ld      hl, init_sio_procedure  ; Load pointer to initialization data stream
    ld      b, init_sio_length      ; Load the length of the initialization procedure
    otir                            ; write B bytes from (HL) into port (C)
    pop     bc
    pop     hl
    ret

init_sio_procedure:
    db  00011000b   ; wr0 = reset everything
    db  00000100b   ; wr0 = select register 4
    db  11000100b   ; wr4 = /16 None 1
    db  00000001b   ; wr0 = Select register 1
    db  00000000b   ; wr1 = No interrupts
    db  00000010b   ; wr0 = Select register 2
    db  00000000b   ; wr2 = No address
    db  00000011b   ; wr0 = select register 3
    db  11000001b   ; wr3 = RX enable, 8 bits/character
    db  00000101b   ; wr0 = select register 5
    db  11101010b   ; wr5 = DTR=0, TX enable, 8 bits/character
    db  00010001b
    db  00000000b
init_sio_length: equ $-init_sio_procedure
