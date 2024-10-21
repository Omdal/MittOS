; When multiplying two bytes, HL must be set to 0 first.
; When multiplying larger numbers, Reset H, and set L to previous H
; (A * C) + HL -> HL
MUL:
    PUSH AF
    PUSH BC
    PUSH DE
    LD D, 0     ; Set DE = C 
    LD E, C
    LD B, 8     ; Repeat 8 times
_MUL_LOOP:
    RRCA        ; Check if value should be added
    JR NC, _MUL_NEXT
    ADD HL, DE  ; Add the (shifted) value
_MUL_NEXT:
    SLA E        ; Shift DE by 1
    RL D
    DJNZ _MUL_LOOP ; Check next bit
    POP DE
    POP BC
    POP AF
    RET