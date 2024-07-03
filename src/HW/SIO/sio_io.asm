;###############################################################################
; SIO transmit character procedure, blocking until sending starts.
;
; Used registers:
;   A,C
;
; Preload registers:
;   A = Character to print
;   C = HW-port for channel control word
;###############################################################################
sio_tx_blocking:
    push    AF
    push    BC
    ld      B, A                    ; Move character to B register
_sio_tx_blocking_retry:
    xor     A
    out     (C),A                   ; Switch to register 0
    in      A,(C)                   ; Read control status word
    and     4                       ; check if xmtr empty bit
    jr      Z,_sio_tx_blocking_retry ; if busy, wait

    inc     C                       ; switch to data register
    out     (C),B                   ; send the character
    pop     BC                      ; Put c register back to original state
    pop     AF
    ret



;###############################################################################
; SIO transmit character procedure, non-blocking.
;
; Used registers:
;   A,B,C
;
; Preload registers:
;   B = Character to print
;   C = HW-port for channel control word
;
; Return registers:
;   A = SIO Status. 0 = function successful
;###############################################################################
sio_tx:
    xor     a
    out     (c),a                   ; Switch to register 0
    in      a,(c)                   ; Read control status word
    and     4                       ; check if xmtr empty bit
    jr      z,sio_tx_fail           ; if busy, return

    inc     c                       ; switch to data register (2 addresses below)
    out     (c),b                   ; send the character
    dec     c                       ; Put c register back to original state
    xor     a                       ; Reset A to indicate success
    ret
sio_tx_fail:
    cpl
    ret



;###############################################################################
; SIO receive character procedure, blocking until character is received.
;
; Used registers:
;   A,B,C
;
; Preload registers:
;   C = HW-port for channel control word
;
; Returned registers:
;   B = Character received
;###############################################################################
sio_rx_blocking:
    push    af
sio_rx_blocking_retry
    xor     a
    out     (c),a                   ; Switch to register 0
    in      a,(c)                   ; Read control status word
    and     1                       ; check if data is received
    jr      z,sio_rx_blocking_retry ; if nothing, wait

    inc     c                       ; switch to data register (2 addresses below)
    in      b,(c)                   ; receive the character
    dec     c                       ; Put c register back to original state
    pop     af
    ret



;###############################################################################
; SIO receive character procedure, non-blocking.
;
; Used registers:
;   A,B,C
;
; Preload registers:
;   C = HW-port for channel control word
;
; Returned registers:
;   A = 0 = function successful
;   B = Character received
;###############################################################################
sio_rx:
    xor     a
    out     (c),a                   ; Switch to register 0
    in      a,(c)                   ; Read control status word
    and     1                       ; check if data is received
    jr      z,sio_rx_fail           ; if nothing, return

    inc     c                       ; switch to data register (2 addresses below)
    in      b,(c)                   ; send the character
    dec     c                       ; Put c register back to original state
    xor     a                       ; reset A, indicate success
    ret
sio_rx_fail:
    cpl
    ret



;###############################################################################
; SIO transmit ready check.
;
; Used registers:
;   A,C
;
; Preload registers:
;   C = HW-port for channel control word
;
; Return registers:
;   A = 0: Not ready
;###############################################################################
sio_tx_ready:
    in      a, (c)                  ; Read control status word
    and     4                       ; Check if register is empty
    ret
    


;###############################################################################
; SIO received data check.
;
; Used registers:
;   A,C
;
; Preload registers:
;   C = HW-port for channel control word
;
; Return registers:
;   A = 0: Nothing received
;###############################################################################
sio_rx_received:
    in      a, (c)                  ; Read control status word
    and     1                       ; Check if data is received
    ret


