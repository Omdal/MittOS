    ;BIT 0,(HL)  ; Read only
    ;BIT 1,(HL)  ; Hidden
    ;BIT 2,(HL)  ; System
    ;BIT 3,(HL)  ; Volume ID
    ;BIT 4,(HL)  ; Directory
FILE_ATTR_DIRECTORY     EQU 00010000b
    ;BIT 5,(HL)  ; Archive



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
    ld de, DISKLOCATIONDATALENGTH
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

INCLUDE 'FAT/load_drive.asm'




; DE: Destination pointer
FAT_LOAD_CURRENT_LOCATION:
    PUSH BC
    PUSH HL
    LD HL, HDD_CURRENT_LOCATION +1
    LD C, (HL)
    INC HL
    CALL HDDReadSector
    POP HL
    POP BC
    RET

; HL = New location data
FAT_SET_CURRENT_LOCATION:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, HDD_CURRENT_LOCATION
    LD BC, DISKLOCATIONDATALENGTH
    LDIR
    POP HL
    POP DE
    POP BC
    POP AF
    RET

; DE: Destination pointer
FAT_COPY_CURRENT_LOCATION:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD HL, HDD_CURRENT_LOCATION
    LD BC, DISKLOCATIONDATALENGTH
    LDIR
    POP HL
    POP DE
    POP BC
    POP AF
    RET


FAT_LIST_FILES:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    CALL printCRLF
    ; Start at the current folder location
    LD HL, HDD_FOLDER_LOCATION
    CALL FAT_SET_CURRENT_LOCATION
FAT_LIST_FILES_LOOP_SECTOR:
    LD DE, DISKSECTORA
    CALL FAT_LOAD_CURRENT_LOCATION
    LD HL, DE;DISKSECTORA
    LD DE, FAT_DIR_DATASIZE
    LD C, 16 ; 16 DIR-elements per sector
FAT_LIST_FILES_LOOP:
    LD A, (HL)
    CP 0
    JR Z, _FAT_LIST_FILES_END_
    CALL FAT_PRINT_DIR_LINE
    ADD HL,DE
    DEC C
    JR NZ,FAT_LIST_FILES_LOOP
    ; Check the next sector
    CALL FAT_NEXT_SECTOR
    JR FAT_LIST_FILES_LOOP_SECTOR
_FAT_LIST_FILES_END_:
;    LD HL, HDD_FOLDER_LOCATION
;    CALL FAT_SET_CURRENT_LOCATION
    POP HL
    POP DE
    POP BC
    POP AF
    RET

; Parameters:
; B: Directory = 1
; A: 0=file found
; C: 16 - file-index
; CurrentLocation = Found in this sector
FAT_FIND:
    PUSH DE
    PUSH HL
    ; Backup the location for later use
    LD HL, HDD_FOLDER_LOCATION
    CALL FAT_SET_CURRENT_LOCATION
FAT_FIND_LOOP_SECTOR:
    LD DE, DISKSECTORA
    CALL FAT_LOAD_CURRENT_LOCATION
    LD HL, DE
    LD DE, FAT_DIR_DATASIZE
    LD C, 16 ; 16 DIR-elements per sector
_FAT_FIND_LOOP:
    LD A, (HL)
    CP 0
    LD A, 1 ; File not found
    JR Z, _FAT_FIND_END_
    ; Check file
    CALL FAT_CHECK_FILE_NAME
    CP 0
    JR Z, _FAT_FIND_END_
    ADD HL,DE
    DEC C
    JR NZ, _FAT_FIND_LOOP
    ; Check the next sector
    CALL FAT_NEXT_SECTOR
    JR FAT_FIND_LOOP_SECTOR
_FAT_FIND_END_:
    POP HL
    POP DE
    RET


FAT_NEXT_SECTOR:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD HL, HDD_CURRENT_LOCATION +2
    INC (HL)
    LD B, 3
FAT_NEXT_SECTOR_LOOP_:
    INC HL
    LD A,(HL)
    ADC 0
    LD (HL),A
    DJNZ FAT_NEXT_SECTOR_LOOP_

    POP HL
    POP DE
    POP BC
    POP AF
    RET


FAT_CHECK_FILE_NAME:
    PUSH BC ;B=0 file, C File index
    PUSH DE
    PUSH HL

; Skip deleted files
    LD DE, FAT_DIR_ATTR
    LD A, (HL)
    CP E5h ; Deleted file
    JR Z, _FAT_CHECK_FILE_NAME_NOT_FOUND

    ADD HL, DE
    ; File attributes
    ; 0x_F = Long filename
    ;BIT 0,(HL)  ; Read only
    BIT 1,(HL)  ; Hidden
    JR NZ, _FAT_CHECK_FILE_NAME_NOT_FOUND
    BIT 2,(HL)  ; System
    JR NZ, _FAT_CHECK_FILE_NAME_NOT_FOUND
    BIT 3,(HL)  ; Volume ID
    JR NZ, _FAT_CHECK_FILE_NAME_NOT_FOUND
    BIT 4,(HL)  ; Directory
    JR NZ, _FAT_CHECK_FILE_NAME_DIRECTORY_
    ;BIT 5,(HL)  ; Archive
_FAT_CHECK_FILE_NAME_FILE_:
    LD A, B
    CP 0    ; Check files or folders
    JR NZ, _FAT_CHECK_FILE_NAME_NOT_FOUND
_FAT_CHECK_FILE_NAME_:
    ; Copy filename
    AND A
    SBC HL, DE ; Go back to filename
    LD DE, FAT_TEST_NAME
    LD BC, 11
    LDIR       ; Copy filename to test-location
    ; Compare filenames

    ;call printCRLF
    ;ld b, 11
    ;ld hl, FAT_TARGET_NAME
    ;call printstringLength
    ;call printCRLF
;                           Debug comparison
    ;ld b, 11
    ;ld hl, FAT_TEST_NAME
    ;call printstringLength
    ;call printCRLF

    LD  B, 11
    LD  HL, FAT_TARGET_NAME
    LD  DE, FAT_TEST_NAME
    CALL CompareStringsLength
    JR  _FAT_CHECK_DONE_

_FAT_CHECK_FILE_NAME_DIRECTORY_:
    LD A, B
    CP 0    ; Check files or folders
    JR Z, _FAT_CHECK_FILE_NAME_NOT_FOUND
    JR _FAT_CHECK_FILE_NAME_
_FAT_CHECK_FILE_NAME_NOT_FOUND:
    LD A, 1 ; Filename is different
_FAT_CHECK_DONE_:
    POP HL
    POP DE
    POP BC
    RET


FAT_PRINT_DIR_LINE:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD DE, FAT_DIR_ATTR
    LD A, (HL)
    CP E5h ; Deleted file
    JR Z, _FAT_PRINT_DIR_LINE_END_

    ADD HL, DE
    ; File attributes
    ; 0x_F = Long filename
    ;BIT 0,(HL)  ; Read only
    BIT 1,(HL)  ; Hidden
    JR NZ, _FAT_PRINT_DIR_LINE_END_
    BIT 2,(HL)  ; System
    JR NZ, _FAT_PRINT_DIR_LINE_END_
    BIT 3,(HL)  ; Volume ID
    JR NZ, _FAT_PRINT_DIR_LINE_VOLUME_LABEL_
    BIT 4,(HL)  ; Directory
    JR NZ, _FAT_PRINT_DIR_LINE_DIRECTORY_
    ;BIT 5,(HL)  ; Archive

    ; Print filedetails
    AND A
    SBC HL, DE
    LD B, 8
    CALL printstringLength
    LD A, '.'
    CALL printChar
    LD DE, 8
    ADD HL,DE
    LD B, 3
    CALL printstringLength
    CALL printCRLF
    JR _FAT_PRINT_DIR_LINE_END_

_FAT_PRINT_DIR_LINE_DIRECTORY_:
    ; Print directory
    LD A,'<'
    CALL printChar
    AND A
    SBC HL, DE
    LD B, 11
    CALL printstringLength
    LD A,'>'
    CALL printChar
    CALL printCRLF
    JR _FAT_PRINT_DIR_LINE_END_

_FAT_PRINT_DIR_LINE_VOLUME_LABEL_:
    ; Volume label
    AND A
    SBC HL, DE
    PUSH HL
    LD HL, _FAT_DISK_DIR_TITLE1_
    CALL printstring
    LD HL, HDD_CURRENT_DRIVE_INDEX
    LD A, (HL)
    ADD 'A'
    CALL printChar
    LD HL, _FAT_DISK_DIR_TITLE2_
    CALL printstring
    POP HL
    LD B,11
    CALL printstringLength
    CALL printCRLF

_FAT_PRINT_DIR_LINE_END_:
    POP HL
    POP DE
    POP BC
    POP AF
    RET    

; DE: Destination
; A: File index in current sector
FAT_LOAD_FILE:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD  A,  0   ; File
    CALL _FAT_LOAD_DIRECTORY_LOCATION_

    LD  DE, PROGRAMSECTORA
    CALL FAT_LOAD_CURRENT_LOCATION
    
    CALL PROGRAMSECTORA



    POP HL
    POP DE
    POP BC
    POP AF
    RET






; C: 16 - C = File index in current sector
; DISKSECTORA. current sector content
FAT_SWITCH_DIRECTORY:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    LD  A,  1 ;Directory
    CALL _FAT_LOAD_DIRECTORY_LOCATION_

    LD DE, HDD_FOLDER_LOCATION          ; Set the folder location
    CALL FAT_COPY_CURRENT_LOCATION

    ; Folder name = . 
    LD HL, FAT_TARGET_NAME
    LD A, (HL)
    CP '.'
    JR NZ, FAT_SWITCH_DIRECTORY_GO_DEEPER_
    INC HL
    LD A, (HL)
    CP ' '
    JR Z, FAT_SWITCH_DIRECTORY_DONE
    CP '.'
    JR NZ, FAT_SWITCH_DIRECTORY_GO_DEEPER_
    INC HL
    LD A, (HL)
    CP ' '
    JR NZ, FAT_SWITCH_DIRECTORY_GO_DEEPER_
    LD HL, FAT_FOLDER_DEPTH
    DEC (HL) ; Go to parent folder
    JR FAT_SWITCH_DIRECTORY_DONE

FAT_SWITCH_DIRECTORY_GO_DEEPER_:
    ; Increment directory counter
    LD HL, FAT_FOLDER_DEPTH
    LD A, (HL)
    INC (HL)
    ; Save folder name
    LD C, FAT_FOLDERNAME_LENGTH
    LD HL, FAT_FOLDERS
    CALL MUL
    LD DE, HL
    LD HL, FAT_TARGET_NAME
    LD BC, FAT_FOLDERNAME_LENGTH
    LDIR


FAT_SWITCH_DIRECTORY_DONE:
    POP HL
    POP DE
    POP BC
    POP AF
    RET

FAT_SWITCH_DIRECTORY_TO_ROOT:
    POP     HL  ;Pop return address off the stack
    LD HL, HDD_ROOT_FOLDER
    CALL FAT_SET_CURRENT_LOCATION
    LD DE, HDD_FOLDER_LOCATION
    CALL FAT_COPY_CURRENT_LOCATION
    XOR A
    LD HL, FAT_FOLDER_DEPTH
    LD (HL), A
    JR FAT_SWITCH_DIRECTORY_DONE


; A: 0 = File, value = Directory
; C: 16 - C = File index in current sector
; DISKSECTORA. current sector content
_FAT_LOAD_DIRECTORY_LOCATION_:
    PUSH AF
    ; "Invert" the index
    LD A, 16
    SUB C

    ; Start in the root folder
    LD HL, HDD_ROOT_FOLDER              ; Set the root-folder as the current folder
    CALL FAT_SET_CURRENT_LOCATION

    ; Locate the correct offset
    LD C, FAT_DIR_DATASIZE
    LD HL, DISKSECTORA
    CALL MUL ; Jump to the index

    ; Store base cluster
    PUSH HL
    LD DE, FAT_DIR_FIRST_CLUSTER_LOW
    ADD HL, DE
    LD DE, HDD_TEMP_CLUSTER
    LDI
    LDI
    POP HL
    PUSH DE
    LD DE, FAT_DIR_FIRST_CLUSTER_HI
    ADD HL, DE
    POP DE
    ;LD DE, HDD_TEMP_CLUSTER +2
    LDI
    LDI

    ; Subtract 2
    LD HL, HDD_TEMP_CLUSTER
    LD A, (HL)
    SUB 2
    LD (HL), A
    LD B, 3
_FAT_LOAD_DIRECTORY_LOCATION_LOOP_SUB2_:
    INC HL
    LD A, (HL)
    SBC 0
    LD (HL), A
    DJNZ _FAT_LOAD_DIRECTORY_LOCATION_LOOP_SUB2_

    JR NC, _FAT_LOAD_DIRECTORY_LOCATION_NOT_ROOT_  ; If carry, go back to root
    POP     AF
    CP      0
    JR      NZ,  FAT_SWITCH_DIRECTORY_TO_ROOT
    PUSH    AF
_FAT_LOAD_DIRECTORY_LOCATION_NOT_ROOT_
    POP AF

;    ; If Fat16, add 32  TODO: Calculate this number...
;    LD DE, HDD_ROOT_FOLDER
;    LD A, (DE)  ; Load partition format
;    CP  MBR_TYPE_FAT32
;    JR  z, FAT_SWITCH_DIRECTORY_SKIP_FAT16_
;    CP  MBR_TYPE_FAT32_1
;    JR  z, FAT_SWITCH_DIRECTORY_SKIP_FAT16_
;    
;    LD HL, HDD_TEMP_CLUSTER
;    LD A, (HL)
;    ADD 32
;    LD (HL), A
;    LD B, 3
;FAT_SWITCH_DIRECTORY_LOOP_ADD32_:
;    INC HL
;    LD A, (HL)
;    ADC 0
;    LD (HL), A
;    DJNZ FAT_SWITCH_DIRECTORY_LOOP_ADD32_
;
;FAT_SWITCH_DIRECTORY_SKIP_FAT16_
    ; Multiply by HDD_SECTORS_PER_CLUSTER
    LD HL, HDD_SECTORS_PER_CLUSTER
    LD C, (HL)
    LD B, 4
    LD DE, HDD_TEMP_CLUSTER
    LD HL, 0
_FAT_LOAD_DIRECTORY_LOCATION_LOOP_MUL_:
    LD L, H
    LD H, 0
    LD A, (DE)
    CALL MUL
    LD A, L
    LD (DE), A
    INC DE
    DJNZ _FAT_LOAD_DIRECTORY_LOCATION_LOOP_MUL_

    ; Add this to the current location
    LD HL, HDD_TEMP_CLUSTER
    LD DE, HDD_CURRENT_LOCATION+2
    LD B, 4
_FAT_LOAD_DIRECTORY_LOCATION_LOOP_ADD_:
    LD A, (DE)
    ADD A, (HL)
    LD (DE), A
    INC HL
    INC DE
    DJNZ _FAT_LOAD_DIRECTORY_LOCATION_LOOP_ADD_
    RET



DEBUG_CURRENT_LOCATION:
    push af
    push bc
    push hl
    call printCRLF
    LD HL, HDD_CURRENT_LOCATION
    ld b,6
_DEBUG_CURRENT_LOCATION_LOOP_:
    LD A, (HL)
    call printAsHex
    inc HL
    DJNZ _DEBUG_CURRENT_LOCATION_LOOP_
    call printCRLF
    pop hl
    pop bc
    pop af
    ret

_FAT_DISK_DIR_TITLE1_:
    db 0Dh,0Ah,"Volume label of drive ",0
_FAT_DISK_DIR_TITLE2_:
    db " is ",0


; 0C 10 00 08 00 00  A
; 0C 10 00 08 40 00  B
; 0C 10 00 08 80 00  C
; 0E 20 00 08 00 00  D
; 00 DC A1 D1 57 94  E
; 00 FB FD 84 44 1C  F
; 00 6D EF 8E CA AF  G
; 00 1F 91 7F 9B 62  H
; 00 E0 94 7C CC B8  I
; 00 C5 FB B1 5A 33  J
; 00 4E 5E 5D F9 8D  K
; 00 05 AB 63 BB E9  L
; 00 5B A6 EF BB F5  M
; 00 D7 C6 B8 CF 34  N
; 00 3B 9D 01 68 77  O
; 00 36 1E 0C F0 17  P
; 00 FF D1 8A AB BE  Q
; 00 FF 1A D9 2A BB  R
; 00 F7 AD 09 CE A7  S
; 00 98 78 B4 63 9F  T
; 00 74 EF 60 2F 24  U
; 00 D7 AE E8 5F 9E  V
; 00 B5 AD 57 33 DE  W
; 00 ED F4 EB FF BF  X
; 00 35 32 D6 12 DD  Y
; 00 9C 5F 02 E9 88  Z
; 0E 20 00 08 00 00  Current location (0900 4 siste)
; 03 9C 5E A3 5D E1 91 7F BC 7F C3 B5 B6 82
; FA 6D 16 C0 91 55 7C 97 94 C9 7B 4A 3E 14 14 C1
; 2F FF 60 A0 58 48 DB A5 4B 53 17 AC 32 74 F9 B5
; 36 CE 85 21 2F CD 02 99 D3 2F 2B 0F 8A F6 71 12
; FF 5B 1F EF 7A 3E DD DD 7C C9 4F FA FB 68 99 7F
; 6C B1 8C F8 E1 45 F9 36 71 E1 1E 35 FF 87 2F 91
; 40 04 00 00 AB FF 36 2D A9 36 98 B6 6E CD 15 55
; EF B7 AF F5 AB E7 27 E6 CE CF 06 6C DF ED F7 77
; 97 8B 4A 2C 9F 6F CB 35 45 18 E0 CE 59 F5 5B 75
; EA A2 4E 51 43 E7 E8 7C 0E 54 BC AE B7 C7 AF B0
; AE 50 A5 71 4A 6C B3 BA 57 06 0B A4 A0 20 5A F3
; 17 EB 7D 5E DC 7E F8 D9 EE 17 40 72 E2 FC 16 FD
; A6 65 A2 7B EC 7D 20 5F FB 1F E3 69 A8 4A 75 10
; EF 71 FD 3D B4 9B BB 55 1D 84 6F BF 07 9E 46 D1
; 94 FE 48 6A 3A 1D E7 DA 97 4F B2 53 67 72 2C 1C
; 76 5C 30 5D EF 76 AE 39 BE 78 3A 17 76 FB 8F AD
; BA 81 DC BA 20 AA 9A E3 4C 38 F2 7D 6D 34 EB FC
; C9 FB 50 D5 F4 69 CA F9 E6 EB 21 57 5A 39 7C E5
; A1 2F 74 3D CF D1 EB CE 4C 0F 63 F4 51 6D 98 E8
; 9B 63 B7 11 DB EA 94 F4 E1 33 BB BF 96 EE DD D0
; 82 61 BF 04 F4 1D C8 1A C7 A9 BF DD 88 AE F3 7D
; CA 2B F4 6E 1E 35 4A 23 BD 75 5A 84 69 56 AE BB


; 18432 24
; 18496 - Fil1.txt (18456)