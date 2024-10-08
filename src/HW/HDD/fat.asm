FAT_UnmountAll:
    xor A
    ld b, 26
    ld hl, HDD_DISKA
_UnmountAll:
    ld (hl), a
    call _NextDriveData
    djnz _UnmountAll
    ret

_NextDriveData
    push de
    ld de, DISKLOCATIONDATA
    add hl, de
    pop de
    ret

;   returns:
;   D   :   Disk index (0=A, 1=B, 2=C ...)
;   HL  :   Memory of first available Disk slot
FAT_FIRST_UNMOUNTED:
    PUSH    AF
    PUSH    BC
    LD      HL,     HDD_DISKA
    LD      BC,     HDD_DISKZ
    LD      D,      FFh
_FAT_FIRST_UNMOUNTED_LOOP
    INC     D
    LD      A,      (HL)
    CP      0
    JR      Z,      _FAT_FIRST_UNMOUNTED_DONE
    CALL    _NextDriveData
    ; Check if Disk Z:
    LD      A,      H                           ; If high byte of address is not
    CP      B                                   ; equal to Drive Z, check next
    JR      NZ,     _FAT_FIRST_UNMOUNTED_LOOP   
    LD      A,      L                           ; Then if low byte of address is
    CP      C                                   ; not is equal to drive Z, check
    JR      NZ,     _FAT_FIRST_UNMOUNTED_LOOP   ; next
_FAT_FIRST_UNMOUNTED_DONE:
    POP     BC
    POP     AF
    RET

; Mount Disk
MountDrive:
    ; Check first partition
    ; If ext, read, then recursive call,
    ; after recursive call, reload sector
    ; Find first available letter
    ; Copy data to first drive
    ; Repeat, also recursive on ext partitions

