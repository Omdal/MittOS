INCLUDE 'hw/hwmap.asm'

RST0    EQU 11000111b
RST1    EQU 11001111b
RST2    EQU 11010111b
RST3    EQU 11011111b
RST4    EQU 11100111b
RST5    EQU 11101111b
RST6    EQU 11110111b
RST7    EQU 11111111b

    org 0000h
RST0_vec:
    ld sp, F000h
    jp Main

    org 0008h
RST1_vec:
    reti
    org 0010h
RST2_vec:
    reti
    org 0018h
RST3_vec:
    reti
    org 0020h
RST4_vec:
    reti
    org 0028h
RST5_vec:
    reti
    org 0030h
RST6_vec:
    reti
    org 0038h
RST7_vec:
IM1_vec:
    reti

    org 0066h
NMI_vec:
    retn

    org 00FEh
    reti
Main:
    im 2
    ld b,1
    ld c,DEBUG_LIGHTS
    out (c),b

;    ld c,  82h
;    call init_sio

    ld c,  SERIAL_CW_1
    call init_sio

; Serial is initialized. Write start message
    ld  hl, WelcomeMsg
    ld c, SERIAL_CW_1
    call printstring

    ld b,2
    ld c,DEBUG_LIGHTS
    out (c),b

    call HDDDetectA
    cp 0
    jr  z,  HDDA_Detected
    ld  c,  SERIAL_CW_1
    ld  hl, _string_DISK
    call printstring
    ld  B, '1'
    call sio_tx_blocking
    ld  hl, _string_NOTDET
    call printstring
    jr DETECT_HDDB
HDDA_Detected:
; Initialize the disk
    ld  hl, DISKSECTORA
    ld  a,  HDD1Addr
    call HDDInit
    ld  a,  1
    call printDiskInfo


DETECT_HDDB:
    call HDDDetectB
    cp 0
    jr z,HDDB_Detected
    ld c,SERIAL_CW_1
    ld  hl, _string_DISK
    call printstring
    ld  B, '2'
    call sio_tx_blocking
    ld  hl, _string_NOTDET
    call printstring
    jr DETECT_HDDC
HDDB_Detected:
    ld  hl, DISKSECTORA
    ld  a,  HDD2Addr
    call HDDInit
    ld  a,  2
    call printDiskInfo


DETECT_HDDC:
    call HDDDetectC
    cp 0
    jr z,HDDC_Detected
    ld c,SERIAL_CW_1
    ld  hl, _string_DISK
    call printstring
    ld  B, '3'
    call sio_tx_blocking
    ld  hl, _string_NOTDET
    call printstring
    jr DETECT_HDDD
HDDC_Detected:
    ld  hl, DISKSECTORA
    ld  a,  HDD3Addr
    call HDDInit
    ld  a,  3
    call printDiskInfo


DETECT_HDDD:


    ld a, 13
    call printChar
    ld a, 10
    call printChar



    ; Read boot-sector of HDDA
    ld  hl, DISKSECTORA
    ld  c,  HDD1Addr

    call HDDReadSector
    call printSectorContent

    ld a, 0

loop:
    ; Print command prompt
    ld hl, PROMPT
    ld c, SERIAL_CW_1
    call printstring
    ; Reset input
    ld  hl, COMMANDLINE
getbutton:
    ; Read a button press
    call sio_rx_blocking
    ld  (hl), b
    inc hl
    ld  a, b
    call sio_tx_blocking
    ; If character is 0D, goto evaluate
    cp  0Dh
    jr  Z, EvaluateInput
    jp  getbutton


EvaluateInput:
    ld  (hl),0
    ld  a, l
    cp  1
    jp  z, EvaluateInputEnd     ; if no input, get new command
    ld  hl, Error
    call printstring

    ld  hl, COMMANDLINE
    ld  a,(HL)
    call printAsHex
    inc hl
    ld  a,(hl)
    call printAsHex
    inc hl
    ld  a,(hl)
    call printAsHex
    inc hl
    ld  a,(hl)
    call printAsHex
    inc hl   
    
    ld  hl, COMMANDLINE
    call printstring
EvaluateInputEnd
    ld  b, 0Ah
    call sio_tx_blocking
    jp loop


    call printAsHex
    ld b, ' '
    call sio_tx_blocking
    inc a
    ;ld c, SERIAL_CW_1
    ;call sio_rx_blocking
    ;call sio_tx_blocking
    jp getbutton


INCLUDE 'hw/sio/sio_init.asm'
INCLUDE 'hw/sio/sio_io.asm'
INCLUDE 'hw/HDD/hdd_io.asm'


printstring:
    push af
    push bc
    push hl
printstring_loop:
    ld  a, (hl)
    cp  0
    jr z,printstring_done
    inc hl
    ld b,A
    call sio_tx_blocking
    jr printstring_loop
printstring_done:
    pop hl
    pop bc
    pop af
    ret

printstringLength:
    push af
    push bc
    push de
    push hl
printstringLength_loop:
    ld d,B
    ld b,(HL)
    call sio_tx_blocking
    inc hl
    ld b,D
    djnz    printstringLength_loop
    pop hl
    pop de
    pop bc
    pop af
    ret

WelcomeMsg:     db 12,0Dh,0Ah,0Dh,0Ah,"MicroBIOS v0.1b by Olav Andr",C3h,A9h," Omdal",0Dh,0Ah,0Dh,0Ah,"Checking for installed disk drives.",0Dh,0Ah,0
Prompt:         db 0Dh,0Ah,"$>",0
Error:          db 0Dh,0Ah,"Bad command or filename: ", 0
DISK_DETECTED:  db 0Dh,0Ah,"Disk detected", 0
DISK_REMOVED:   db 0Dh,0Ah,"Disk not detected", 0
_string_CRLF:   db 0Dh,0Ah,0
_string_DISK:   db 0Dh,0Ah,"Disk ",0
_string_TYPE:   db " type: ",0
_string_SERIAL: db " serial number: ",0
_string_FIRMWR: db " firmware version: ",0
_string_CAPAC:  db " capacity: ",0
_string_NOTDET: db " not detected.",0

; Register A contains disk number
printDiskInfo:
    push    HL
    push    DE
    push    BC
    push    AF
    add     '0'                     ; Convert disk number to character
    ld      E,      A               ; Store it in register E for later use
    cp      '1'
    jr      NZ,     printDiskInfo2
    ld      A,      HDD1Addr
    jr      printDiskInfoFetch
printDiskInfo2:
    cp      '2'
    jr      NZ,     printDiskInfo3
    ld      A,      HDD2Addr
    jr      printDiskInfoFetch
printDiskInfo3:
    cp      '3'
    jr      NZ,     printDiskInfoErr; Only 3 disks supported
    ld      A,      HDD3Addr
printDiskInfoFetch:
    ld      HL,     DISKSECTORA
    call    HDDInfo
; Print disk info
    ld      C,  SERIAL_CW_1
; Disk type
    ld      HL,     _string_DISK
    call    printstring
    ld      B,      E
    call    sio_tx_blocking
    ld      HL,     _string_TYPE
    call    printstring
    ld      HL,     DISKSECTORA + 36h
    ld      B,      28
    call    printstringLength
; Serial number
    ld      HL,     _string_DISK
    call    printstring
    ld      B,      E
    call    sio_tx_blocking
    ld      HL,     _string_SERIAL
    call    printstring
    ld      HL,     DISKSECTORA + 14h
    ld      B,      14
    call printstringLength
; Firmware version
    ld      HL,     _string_DISK
    call    printstring
    ld      B,      E
    call    sio_tx_blocking
    ld      HL,     _string_FIRMWR
    call    printstring
    ld      HL,     DISKSECTORA + 2Eh
    ld      B,      8
    call    printstringLength
; Disk capacity
    ld      HL,     _string_DISK
    call    printstring
    ld      B,      E
    call    sio_tx_blocking
    ld      HL,     _string_CAPAC
    call    printstring
    ld      A,      (DISKSECTORA+116)
    call    printAsHex
    ld      A,(DISKSECTORA+117)
    call    printAsHex
    ld      A,(DISKSECTORA+114)
    call    printAsHex
    ld      A,(DISKSECTORA+115)
    call    printAsHex
    pop     AF
    xor     A
    jr      printDiskInfoReturn
printDiskInfoErr:
    pop     AF
    ld      A,      1
printDiskInfoReturn:
    pop     BC
    pop     DE
    pop     HL
    ret



printChar:
    push bc
    ld      c,  SERIAL_CW_1
    ld      b,  a
    call    sio_tx_blocking
    pop bc
    ret



printAsHex:
    push af
    push bc
    push af
    ld      c,  SERIAL_CW_1
    rra
    rra
    rra
    rra
    call LowNibbleToChar
    ld b,a
    call sio_tx_blocking
    pop af
    call LowNibbleToChar
    ld b,a
    call sio_tx_blocking
    pop bc
    pop af
    ret

; Converts register A to a character representing the hex value of the lower nibble.
LowNibbleToChar:
    and 0Fh         ; Isolate lower nibble
    add A,  '0'     ; Add Zero-character to start at '0'
    cp  ':'         ; Check if character is greater than '9'
    ret M           ; Return if character is a number
    add A,  7       ; Add 7 to change character to a letter
    ret

CharToNibble:
    sub A,  '0'
    jr  C, CharToNibble_Error
    cp  10
    jr  C, CharToNibble_Store
    sub A,  7       ; Convert A-F to 10-15
    jr  C, CharToNibble_Error   ; Char was between 9 and A (Invalid)
    cp  10h
    jr  C, CharToNibble_Error   ; Char is higher than F     TODO: convert a-f too
CharToNibble_Store:
    sla B
    sla B
    sla B
    sla B                       ; Shift out upper Nibble
    or  B                       ; Combine upper and lower Nibble
    ld  B,  A                   ; Move back to B register
    xor A
    ret
CharToNibble_Error:
    ld A,   -1      ; Char is not a number
    ret







printSectorContent:
    ld a, 13
    call printChar
    ld a, 10
    call printChar
    ld  hl, DISKSECTORA
    ld  c, 32
printSectorContentLine:
    ld  a, 32
    sub C
    call printAsHex
    ld  a, 0,
    call printAsHex
    ld  a, ' '
    call printChar
    ld  b, 16
printSectorContentByte:
    ld  a, (hl)
    call printAsHex
    ld  a, ' '
    call printChar
    inc hl
    dec b
    jp nz, printSectorContentByte

    ld a, 13
    call printChar
    ld a, 10
    call printChar
    dec C
    jp nz, printSectorContentLine
    ret


; RAM area
    org 2000h
RAMSTART:


    org 9000h
COMMANDLINE:

    org A000h
DISKSECTORA:
    org A200h
DISKSECTORB:


    END