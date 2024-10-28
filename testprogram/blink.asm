    ld c, 0
    ld a, FFh
    add 2       ; Set carry, and set value to 1
    ld b, 5    ; Repeat 5 times
left:
    push bc
    ld b, 8     ; Repeat 8 times
loop_l:
    push BC
    ld b, 127    
    out (c), A
outer_l:
    push BC
    ld b, 255
inner_l:
    djnz inner_l
    pop BC
    djnz outer_l
    rl A
    pop BC
    djnz loop_l
right:
    ld b, 8     ; Repeat 8 times
loop_r:
    push BC
    ld b, 127    
    out (c), A
outer_r:
    push BC
    ld b, 255
inner_r:
    djnz inner_r
    pop BC
    djnz outer_r
    rr A
    pop BC
    djnz loop_r
    pop BC
    djnz left
    out (c), A
    ret