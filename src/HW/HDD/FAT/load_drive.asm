; Used to convert drive letter to drive index
; A Drive letter
FAT_LOAD_DRIVE:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    CP 60h                              ; Convert lower case to uppercase
    JR C, _FAT_LOAD_DRIVE_CAP_
    SUB 20h
_FAT_LOAD_DRIVE_CAP_:
    CP 40h                              ; Convert upper case to index
    JR C, _FAT_LOAD_DRIVE_INDEX_
    SUB 'A'
_FAT_LOAD_DRIVE_INDEX_:
    CP 1Ah
    JR C, _FAT_LOAD_DRIVE_START_        ; Jump to disk loading sequence
_FAT_LOAD_NOT_AVALIABLE_:
    LD HL, _FAT_LOAD_DRIVE_OUT_OF_RANGE1_
    CALL printstring
    ADD 'A'
    CALL printChar
    LD HL, _FAT_LOAD_DRIVE_OUT_OF_RANGE2_
    CALL printstring
    POP HL
    POP DE
    POP BC
    POP AF
    RET

_FAT_LOAD_DRIVE_OUT_OF_RANGE1_:
    db 0Dh,0Ah,"ERROR: Disk ",0
_FAT_LOAD_DRIVE_OUT_OF_RANGE2_:
    db " does not exist.",0Dh,0Ah,0
_FAT_DISK_INFO1_:
    db 0Dh,0Ah,"Disk ",0
_FAT_DISK_INFO2_:
    db " formatted [",0

_FAT_LOAD_DRIVE_START_:             ; Try to load drive at index [A]
    CALL _FAT_LOCATE_DRIVE_DATA_    ; HL = Drive data
    LD B, A     ; Save disk index for later use
    LD A, (HL)  ; Check partition format
    CP 1        ; if partition is missing.
    LD A, B ; Load index back to A
    JR C, _FAT_LOAD_NOT_AVALIABLE_  ; Drive is not loaded. Jump to error.
   
    ; Load the drive
    LD      DE,     HDD_CURRENT_DRIVE_INDEX     ; Save the current drive letter
    LD      (DE),   A
    CALL    FAT_SET_CURRENT_LOCATION            ; HL = New location data
    LD      DE,     DISKSECTORA
    CALL    FAT_LOAD_CURRENT_LOCATION           ; Load the current location indo DISKSECTORA

_FAT_LOAD_DRIVE_WRITE_INFO_:                    ; Write some disk information
    LD HL, _FAT_DISK_INFO1_
    CALL printstring
    LD DE, HDD_CURRENT_DRIVE_INDEX
    LD A, (DE)
    ADD 'A'
    CALL printChar
    LD A, ':'
    CALL printChar
    LD A, ' '
    CALL printChar
    LD HL, DISKSECTORA+3
    LD B, 8
    CALL printstringLength
    LD HL, _FAT_DISK_INFO2_
    CALL printstring

    LD DE, HDD_CURRENT_LOCATION
    LD A, (DE)  ; Load partition format

    CP  MBR_TYPE_FAT32                              ; Check if partition
    JR  z, _FAT_LOAD_DRIVE_WRITE_INFO_NAME_FAT32_   ; format is FAT32
    CP  MBR_TYPE_FAT32_1
    JR  z, _FAT_LOAD_DRIVE_WRITE_INFO_NAME_FAT32_

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
    CALL printCRLF

    ld HL, HDD_CURRENT_DRIVE_INDEX
    ld a, (HL)
    call FAT_LOAD_ROOT_FOLDER

    POP HL
    POP DE
    POP BC
    POP AF
    RET




; A: Disk index
; Contents of Disksectora is FAT data
FAT_LOAD_ROOT_FOLDER:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD HL, HDD_CURRENT_DRIVE_INDEX
    LD (HL), A
    ; Save root address
    CALL _FAT_LOCATE_DRIVE_DATA_
    CALL FAT_SET_CURRENT_LOCATION               ; Set current location to FAT root

    ; Set the root folder to FAT table
    LD DE, HDD_ROOT_FOLDER
    CALL FAT_COPY_CURRENT_LOCATION              ; Initialize the root folder to FAT root

    ; Load the FAT table
    LD DE, DISKSECTORA
    CALL FAT_LOAD_CURRENT_LOCATION              ; Reload the FAT root
    ; Save number of sectors per cluster for the current drive
    LD DE, HDD_SECTORS_PER_CLUSTER
    LD HL, FAT_SECTORS_PER_CLUSTER
    LDI                                         ; Store cluster size
    ; Add reserved sectors
    LD DE, HDD_ROOT_FOLDER + 2
    LD A, (DE)
    ADD A, (HL)
    LD (DE), A  
    INC DE
    INC HL
    LD A, (DE)
    ADC A, (HL)
    LD (DE), A

    ; Multiply sectors per fat by number of FAT sectors (2)
    LD DE, HDD_ROOT_FOLDER
    LD A, (DE)  ; Load partition format
    CP  MBR_TYPE_FAT32
    JR  z, _FAT_LOCATE_ROOT_FOLDER_FAT32
    CP  MBR_TYPE_FAT32_1
    JR  z, _FAT_LOCATE_ROOT_FOLDER_FAT32
_FAT_LOCATE_ROOT_FOLDER_FAT16:
    LD HL, FAT16_FAT_SECTOR_SIZE_
    LD DE, SCRATCHPAD
    AND A ; Clear carry flag
    LD B, 2
    JR _FAT_LOCATE_ROOT_FOLDER_MULTIPLY_
_FAT_LOCATE_ROOT_FOLDER_FAT32:
    LD HL, FAT32_FAT_SECTOR_SIZE_
;_FAT_LOCATE_ROOT_FOLDER_FINAL:
    ; Multiply 4 bytes by 2 TODO implement multiply function
    LD DE, SCRATCHPAD
    AND A ; Clear carry flag
    LD B, 4
_FAT_LOCATE_ROOT_FOLDER_MULTIPLY_:
    LD A, (HL)
    RLA                 ;RL (HL)
    LD (DE), A
    INC HL
    INC DE
    DJNZ _FAT_LOCATE_ROOT_FOLDER_MULTIPLY_
    ; Add to address
    LD DE, SCRATCHPAD
    LD HL, HDD_ROOT_FOLDER +2
    AND A ; Clear carry flag
    LD B, 4
_FAT_LOCATE_ROOT_FOLDER_ADD_:
    LD A, (DE)
    ADC A, (HL)
    LD (HL), A
    INC HL
    INC DE
    DJNZ _FAT_LOCATE_ROOT_FOLDER_ADD_
; Set root-folder as current location
    LD HL, HDD_ROOT_FOLDER                          ; Root folder calculated
    CALL FAT_SET_CURRENT_LOCATION                   ; Set current location
; Save the root folder to current folder
    LD DE, HDD_FOLDER_LOCATION
    CALL FAT_COPY_CURRENT_LOCATION
; Read folder contents
;    LD DE, DISKSECTORA
;    CALL FAT_LOAD_CURRENT_LOCATION
; Reset the folder depth
    LD HL,  FAT_FOLDER_DEPTH
    XOR A
    LD (HL), A

    POP HL
    POP DE
    POP BC
    POP AF
    RET
; HDD_ROOT_FOLDER and HDD_FOLDER_LOCATION is set.



; A : Drive index
; Retruns
; HL : Location of drive data
_FAT_LOCATE_DRIVE_DATA_:
    PUSH AF
    PUSH BC
    LD      HL,     HDD_DISKA
    LD      C,      DISKLOCATIONDATALENGTH      ; Multiply index by length
    CALL    MUL                                 ; (A * C) + HL -> HL
    POP BC
    POP AF
    RET