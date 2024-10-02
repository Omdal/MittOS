printsector:
    push bc
    ld b, 32
_printsectorRepeat:
    call _printMemLine
    djnz _printsectorRepeat
    pop bc
    ret

_printMemLine:
    ld a, h
    call printAsHex
    ld a, l
    call printAsHex
    push bc
    ld b, 16
_printMemLineRepeat:
    ld a, ' '
    call printChar
    ld a, (hl)
    inc hl
    call printAsHex
    djnz _printMemLineRepeat
    call printCRLF
    pop bc
    ret