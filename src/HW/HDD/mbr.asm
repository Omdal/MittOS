MBR_PARTITION1  EQU 01BEh
MBR_PARTITION2  EQU 01CEh
MBR_PARTITION3  EQU 01DEh
MBR_PARTITION4  EQU 01EEh

MBR_SIGNATURE   EQU 01FEh

MBR_SIGNATURE_BYTE0     EQU 55h
MBR_SIGNATURE_BYTE1     EQU AAh

MBR_BOOTABLE    EQU 0
MBR_START_HEAD  EQU 1   ; Ignored
MBR_START_SECT  EQU 2   ; Ignored
MBR_START_CYL   EQU 3   ; Ignored
MBR_TYPE        EQU 4
MBR_END_HEAD    EQU 5   ; Ignored
MBR_END_SECT    EQU 6   ; Ignored
MBR_END_CYL     EQU 7   ; Ignored
MBR_REL_START3  EQU 8
MBR_REL_START2  EQU 9
MBR_REL_START1  EQU 10
MBR_REL_START0  EQU 11
MBR_LENGTH3     EQU 12
MBR_LENGTH4     EQU 13
MBR_LENGTH5     EQU 14
MBR_LENGTH6     EQU 15

; BOOTABLE values
MBR_NOT_BOOTABLE    EQU 00h
MBR_IS_BOOTABLE     EQU 80h

; Partition types:
MBR_TYPE_EMPTY          EQU 00h
MBR_TYPE_FAT12          EQU 01h
MBR_TYPE_FAT16          EQU 04h
MBR_TYPE_MSEXTENDED     EQU 05h
MBR_TYPE_FAT16_1        EQU 06h
MBR_TYPE_NTFS           EQU 07h
MBR_TYPE_FAT32          EQU 0Bh
MBR_TYPE_FAT32_1        EQU 0Ch
MBR_TYPE_FAT16_2        EQU 0Eh
MBR_TYPE_MSEXTENDED_1   EQU 0Fh
MBR_TYPE_HIDDENFAT12    EQU 11h
MBR_TYPE_HIDDENFAT16    EQU 14h
MBR_TYPE_HIDDENFAT16_1  EQU 16h
MBR_TYPE_HIDDENFAT32    EQU 1Bh
MBR_TYPE_HIDDENFAT32_1  EQU 1Ch
MBR_TYPE_HIDDENFAT16_2  EQU 1Eh
MBR_TYPE_MSDYNAMIC      EQU 42h
MBR_TYPE_SOLARISX86     EQU 82h
MBR_TYPE_LINUXSWAP      EQU 82h
MBR_TYPE_LINUX          EQU 83h
MBR_TYPE_HIBERNATION    EQU 84h
MBR_TYPE_LINUXEXTENDED  EQU 85h
MBR_TYPE_NTFSVOLUMESET  EQU 86h
MBR_TYPE_NTFSVOLUMESET1 EQU 87h
MBR_TYPE_HIBERNATION1   EQU A0h
MBR_TYPE_HIBERNATION2   EQU A1h
MBR_TYPE_FREEBSD        EQU A5h
MBR_TYPE_OPENBSD        EQU A6h
MBR_TYPE_MACOSX         EQU A8h
MBR_TYPE_NETBSD         EQU A9h
MBR_TYPE_MACOSXBOOT     EQU ABh
MBR_TYPE_BSDI           EQU B7h
MBR_TYPE_BSDISWAP       EQU B8h
MBR_TYPE_EFIGPTDISK     EQU EEh
MBR_TYPE_EFISYSTEMPART  EQU EFh
MBR_TYPE_VMWAREFILESYST EQU FBh
MBR_TYPE_VMWARESWAP     EQU FCh

;   C   :   HDD_Disk_Data address
HDD_READ_MBR:
    push DE
    push HL

    ; Read the boot-sector
    ld  DE, DISKSECTORA                         ; Disk scratchpad
    ld  HL, _HDD_DETECT_PARTITIONS_BOOTSECTOR_  ; 0,0,0,0
    call HDDReadSector

    pop HL
    pop DE
    ret

HDD_DETECT_PARTITIONS:
    push AF
    push BC
    push DE
    push HL

    ld  hl, DISKSECTORA + MBR_SIGNATURE             ; Check signature
    ld  a,  (HL)
    cp  MBR_SIGNATURE_BYTE0
    jr  nz, _HDD_DETECT_PARTITIONS_ERROR_
    inc HL
    ld  A, (HL)
    cp  MBR_SIGNATURE_BYTE1
    jr  z, _HDD_DETECT_PARTITIONS_OK_
_HDD_DETECT_PARTITIONS_ERROR_:
    ld  hl, _HDD_DETECT_PARTITIONS_BAD_SECTOR_MESSAGE_
    call printstring
;----------------------------------------------------------------------    
    pop HL
    pop DE
    pop BC
    pop AF
    ret
 
_HDD_DETECT_PARTITIONS_OK_:                         ; Signature OK

    ld  de, 0010h
    ld  hl, DISKSECTORA + MBR_PARTITION1 + MBR_TYPE - 0010h
    ld  b,4
_HDD_DETECT_PARTITIONS_CHECK_PARTITION_:
    add HL, DE
    push HL
    ld  a, (HL)

    cp  MBR_TYPE_EMPTY
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_EMPTY_

    cp  MBR_TYPE_FAT12
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_FAT12_

    cp  MBR_TYPE_FAT16
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_FAT16_
    cp  MBR_TYPE_FAT16_1
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_FAT16_
    cp  MBR_TYPE_FAT16_2
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_FAT16_

    cp  MBR_TYPE_FAT32
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_FAT32_
    cp  MBR_TYPE_FAT32_1
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_FAT32_

    cp  MBR_TYPE_MSEXTENDED
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_MSEXTENDED_ 
    cp  MBR_TYPE_MSEXTENDED_1
    jr  z, _HDD_DETECT_PARTITIONS_TYPE_MSEXTENDED_ 

    ; Unknown partition
    jr _HDD_DETECT_PARTITIONS_NEXT_ ; Unknown

_HDD_DETECT_PARTITIONS_TYPE_FAT12_:
    call _HDD_DETECT_PARTITIONS_MESSAGE_
    ld  hl, _HDD_DETECT_PARTITIONS_TYPE_FAT12_MESSAGE_
    call printstring
    jr _HDD_DETECT_PARTITIONS_NEXT_

_HDD_DETECT_PARTITIONS_TYPE_FAT16_:
    call _HDD_DETECT_PARTITIONS_MESSAGE_
    ld  hl, _HDD_DETECT_PARTITIONS_TYPE_FAT16_MESSAGE_
    call printstring
    jr _HDD_DETECT_PARTITIONS_MOUNT_

_HDD_DETECT_PARTITIONS_TYPE_FAT32_:
    call _HDD_DETECT_PARTITIONS_MESSAGE_
    ld  hl, _HDD_DETECT_PARTITIONS_TYPE_FAT32_MESSAGE_
    call printstring
    jr _HDD_DETECT_PARTITIONS_MOUNT_

_HDD_DETECT_PARTITIONS_TYPE_MSEXTENDED_:
    ; read partition location, then scan again
    call _HDD_DETECT_PARTITIONS_MESSAGE_
    ld  hl, _HDD_DETECT_PARTITIONS_TYPE_MSEXTENDED_MESSAGE_
    call printstring
    jr _HDD_DETECT_PARTITIONS_NEXT_

_HDD_DETECT_PARTITIONS_TYPE_EMPTY_:
_HDD_DETECT_PARTITIONS_NEXT_:
    pop HL
    DJNZ _HDD_DETECT_PARTITIONS_CHECK_PARTITION_
    pop HL
    pop DE
    pop BC
    pop AF
    ret

_HDD_DETECT_PARTITIONS_MOUNT_:
    ; A contains partition type
    ; B contains partition index (Inverted)
    ; C conatins HDD address

    pop hl      ; Refresh source-address
    push hl
    push de
    push bc

    push hl                     ; Push source-address
    call FAT_FIRST_UNMOUNTED    ; Get first available mounting slot (HL)

    ld (HL), A                  ; Save partition type
    inc HL
    ld (HL), C                  ; Save HDD-IO address
    inc HL
    ld C,D                      ; Move drive index to C
    pop de                      ; Pop source-address to DE
    ld A, E                     ; Move source-pointer from partition
    add A, 4                    ; type to first address byte
    ld E, A    
    ld b, 4                     ; Copy four bytes
_HDD_DETECT_PARTITIONS_MOUNT_SAVE_ADDRESS_:
    LD A, (DE)
    LD (HL),A
    inc HL
    inc DE
    djnz _HDD_DETECT_PARTITIONS_MOUNT_SAVE_ADDRESS_

    ld HL, _HDD_DETECT_PARTITIONS_MOUNTED_MESSAGE_
    call printstring
    ld a, C
    add a, 'A'
    call printChar

    pop bc
    pop de
    jr _HDD_DETECT_PARTITIONS_NEXT_


_HDD_DETECT_PARTITIONS_MESSAGE_:
    push hl
    push af
    ld  HL, _HDD_DETECT_PARTITIONS_DETECTED_MESSAGE_
    call printstring
    ld  a, '4'
    sub B
    call printChar
    ld  HL, _HDD_DETECT_PARTITIONS_OF_TYPE_MESSAGE_
    call printstring
    pop af
    pop hl
    ret


_HDD_DETECT_PARTITIONS_BOOTSECTOR_: db 0,0,0,0
_HDD_DETECT_PARTITIONS_BAD_SECTOR_MESSAGE_:         db 0Dh,0Ah,"Bad partition table. Please format drive.",0
_HDD_DETECT_PARTITIONS_DETECTED_MESSAGE_:           db 0Dh,0Ah,"Detected partition ",0
_HDD_DETECT_PARTITIONS_OF_TYPE_MESSAGE_:            db ". Partition type: ",0
_HDD_DETECT_PARTITIONS_TYPE_FAT12_MESSAGE_:         db "FAT12",0
_HDD_DETECT_PARTITIONS_TYPE_FAT16_MESSAGE_:         db "FAT16",0
_HDD_DETECT_PARTITIONS_TYPE_FAT32_MESSAGE_:         db "FAT32",0
_HDD_DETECT_PARTITIONS_TYPE_MSEXTENDED_MESSAGE_:    db "MS Extended.",0
_HDD_DETECT_PARTITIONS_MOUNTED_MESSAGE_:            db ". Mounted as drive ",0