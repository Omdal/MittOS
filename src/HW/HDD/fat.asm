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

; A Drive letter
FAT_LOAD_DRIVE:
    PUSH HL
    CP 60h ; Lower case
    JR C, _FAT_LOAD_DRIVE_CAP_
    SUB 20h
_FAT_LOAD_DRIVE_CAP_:
    CP 40h ; Upper case
    JR C, _FAT_LOAD_DRIVE_INDEX_
    SUB 'A'
_FAT_LOAD_DRIVE_INDEX_:
    CP 1Ah
    JR C, _FAT_LOAD_DRIVE_START_
    ; Out of range
_FAT_LOAD_NOT_AVALIABLE_:
    LD HL, _FAT_LOAD_DRIVE_OUT_OF_RANGE1_
    CALL printstring
    ADD 'A'
    CALL printChar
    LD HL, _FAT_LOAD_DRIVE_OUT_OF_RANGE2_
    CALL printstring
    POP HL
    RET
_FAT_LOAD_NOT_AVAILABLE_B_:
    LD A, B ; Load index back to A
    JR _FAT_LOAD_NOT_AVALIABLE_

_FAT_LOAD_DRIVE_START_:
    ; multiply by DISKLOCATIONDATA (6), TODO create multiplication function
    LD B, A
    SLA A
    ADD B
    SLA A
    LD E, A
    LD D, 0
    LD HL, HDD_DISKA
    ADD HL, DE
    LD A, (HL)  ; Check partition format
    CP 1        ; if partition is missing.
    JR C, _FAT_LOAD_NOT_AVAILABLE_B_
_FAT_LOAD_DRIVE_START_AVAILABLE_:
    PUSH AF
    LD DE, HDD_CURRENT_DRIVE
    LD A, B
    LD (DE), A
    POP AF
    LD DE, HDD_CURRENT_LOCATION
    LD (DE), A ; save partition format
    INC HL
    INC DE
    LD C, (HL)
    LD A, C
    LD (DE), A ; save HDD address
    LD B, 4
_FAT_LOAD_DRIVE_START_AVAILABLE_ADDRESS_:
    INC HL
    INC DE
    LD A, (HL)
    LD (DE), A
    DJNZ _FAT_LOAD_DRIVE_START_AVAILABLE_ADDRESS_
    
    LD DE, DISKSECTORA
    LD HL, HDD_CURRENT_LOCATION+2
    CALL HDDReadSector

    ;LD HL, DISKSECTORA
    ;CALL printsectorContent     ; DEBUG INFO

_FAT_LOAD_DRIVE_WRITE_INFO_:
    LD HL, _FAT_DISK_INFO1_
    CALL printstring
    LD DE, HDD_CURRENT_DRIVE
    LD A, (DE)
    ADD 'A'
    CALL printChar
    LD A, ':'
    CALL printChar
    LD A, ' '
    CALL printChar
    LD HL, DISKSECTORA+3
    CALL printstring    ; Gamble on 512 byte sectors
    LD HL, _FAT_DISK_INFO2_
    CALL printstring

    LD DE, HDD_CURRENT_LOCATION
    LD A, (DE)  ; Load partition format

    cp  MBR_TYPE_FAT32
    jr  z, _FAT_LOAD_DRIVE_WRITE_INFO_NAME_FAT32_
    cp  MBR_TYPE_FAT32_1
    jr  z, _FAT_LOAD_DRIVE_WRITE_INFO_NAME_FAT32_

    ; Handle other format as FAT16
    LD HL, DISKSECTORA + 2Bh    ;2B for FAT16
    JR _FAT_LOAD_DRIVE_WRITE_INFO_NAME_COMMON_
_FAT_LOAD_DRIVE_WRITE_INFO_NAME_FAT32_:
    LD HL, DISKSECTORA + 47h    ;2B for FAT16
_FAT_LOAD_DRIVE_WRITE_INFO_NAME_COMMON_:
    LD B, 11
_FAT_LOAD_DRIVE_WRITE_INFO_NAME_:
    LD A, (HL)
    INC HL
    CALL printChar
    DJNZ _FAT_LOAD_DRIVE_WRITE_INFO_NAME_
    LD A, ']'
    CALL printChar
    LD A, '('
    CALL printChar
    LD B, 8
_FAT_LOAD_DRIVE_WRITE_INFO_TYPE_:
    LD A, (HL)
    INC HL
    CALL printChar
    DJNZ _FAT_LOAD_DRIVE_WRITE_INFO_TYPE_
    LD A, ')'
    CALL printChar
    ;CALL printCRLF
    POP HL
    RET



_FAT_LOAD_DRIVE_OUT_OF_RANGE1_:
    db 0Dh,0Ah,"ERROR: Disk ",0
_FAT_LOAD_DRIVE_OUT_OF_RANGE2_:
    db " does not exist.",0Dh,0Ah,0
_FAT_DISK_INFO1_:
    db 0Dh,0Ah,"Disk ",0
_FAT_DISK_INFO2_:
    db " formatted [",0