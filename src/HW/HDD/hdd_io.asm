HDD1Addr    EQU 10h
HDD2Addr    EQU 20h
HDD3Addr    EQU 30h

HDDxDta     EQU 0  ; Data port
HDDxErr     EQU 1  ; Error / Feature
HDDxLen     EQU 2  ; Number of sectors to transfer
HDDxLBA0    EQU 3  ; Sector address LBA0 [0:7]
HDDxLBA1    EQU 4  ; Sector address LBA1 [8:15] 
HDDxLBA2    EQU 5  ; Sector address LBA2 [16:23] 
HDDxLBA3    EQU 6  ; Sector address LBA3 [24:31]
HDDxSts     EQU 7  ; Status / Command

HDD_CMD_IDENTIFY_DRIVE  EQU ECh
HDD_CMD_READ            EQU 21h

HDDWaitForReady:
    IN      A,  (C)
    AND     80h
    JR      NZ, HDDWaitForReady
HDDIsNotReady:
    IN      A,  (C)
    AND     40h
    JR      Z,  HDDIsNotReady
    RET 

HDDHasDataReady:
    IN      A,  (C)
    AND     08h
    JR      Z, HDDHasDataReady
    RET

HDDReadChunk:
    LD      B,      0
HDDReadChunkRepeat:
    IN      A,      (C)
    IN      D,      (C)
    LD      (HL),   D  
    INC     HL
    LD      (HL),   A
    INC     HL
    DJNZ    HDDReadChunkRepeat
    RET



HDDInit:
    PUSH    BC
    ADD     HDDxSts             ; Switch to Status/Command register
    LD      C,      A
    LD      B,      A           
    CALL    HDDWaitForReady
    LD      A,      C
    SUB     HDDxSts-HDDxErr     ; Switch to Error-register
    LD      C,      A
    LD      A,      1
    OUT     (C),    A           ; Command 1 - 8-bit mode
    LD      C,      B
    LD      A,      EFh
    OUT     (C),    A           ; Set command
    POP     BC
    RET

;   HL  :   Where to store the data
;   A   :   HDDx address
HDDInfo:
    ADD     HDDxSts                 ; Switch to status register
    LD      c,      a
    call    HDDWaitForReady
    dec     c                       ; Switch to LBA3 address
    xor     a
    out     (C),    A               ; Select master disk
    ld      a,      HDD_CMD_IDENTIFY_DRIVE
    inc     C                       ; Switch back to status register
    out     (C),    a
    call    HDDHasDataReady
    ld      a,      c
    sub     HDDxSts                 ; Switch back to Data register
    ld      c,      a
    call    HDDReadChunk
    ret

HDDDetectA:
    push    BC
    ld      C,      HDD1Addr
    inc     C
    in      B,      (C)
    in      A,      (HDD1Addr+1)
    cp      B
    jr      Z,      HDDDetected
    ld      A,      1
    pop     BC
    ret

HDDDetected:
    xor     A
    pop     BC
    ret

HDDDetectB:
    push    BC
    ld      C,      HDD2Addr
    inc     C
    in      B,      (c)
    in      A,      (HDD2Addr+1)
    cp      B
    jr      Z,      HDDDetected
    ld      A,      1
    pop     BC
    ret

HDDDetectC:
    push    BC
    ld      C,      HDD3Addr
    inc     C
    in      B,      (C)
    in      A,      (HDD3Addr+1)
    cp      B
    jr      Z,      HDDDetected
    ld      A,      1
    pop     BC
    ret

;   Start with HL pointing to the address, and C indicating disk data address
;   Ends with C pointing to disk command address
HDDSetAddress:
    push AF
    inc     C                       ; Error / Feature
    inc     C                       ; Number of sectors to transfer
    ld      A, 1
    out     (C), A

    ld      b, 4
    scf                             ; Set carry flag to increment address by 1
_HDDSetAddress_Out:
    inc     C                       ; Move to sector address LBA0 [0:7]
    ld      A, (HL)                 ; Get LBA0
    inc     HL
    adc     A,  0                   ; Increment address by 1
    out     (C), A
    DJNZ    _HDDSetAddress_Out      ; Repeat for LBA1-3

    inc     C                       ; Move to status / Command
    pop     AF
    ret


HDDReadSector:
    push    AF
    push    BC
    push    HL
    push    BC                      ; Save Disk address for later use
    call    HDDSetAddress
    ld      A, HDD_CMD_READ
    out     (C), A                  ; Issue read command
    call    HDDHasDataReady         ; Wait for the disk to be ready
    pop     BC                      ; Reset to Disk-address
    ld      HL,DE                   ; Switch to destination address
    ld      B,  0
    inir                            ; Read 256 bytes
    inir                            ; Read 256 bytes
    pop     HL
    pop     BC
    pop     AF
    ret

;0040 3fff c837 0010 8856 022a 003f 0000
;0000 0000 3053 4644 314a 4c49 3232 3132
;0037 0000 0000 0000 0003 4000 0004 4d5a
;3031 2d30 0033 4153 534d 4e55 2047 4448
;3631 4a30 2f4a 0050 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 8010
;0000 2f00 4000 0200 0200 0007 3fff 0010
;003f fc10 00fb 0110 ffff 0fff 0000 0007
;0003 0078 0078 0078 0078 0000 0000 0000
;0000 0000 0000 001f 0706 0000 004c 0040
;00fe 0021 746b 7f01 4023 7469 3e01 4023
;40ff 003c 003c 0000 fffe 0000 fe80 0000
;0000 0000 0000 0000 9eb0 12a1 0000 0000
;0000 0000 0000 0000 5000 0f00 0bdf 0100
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0021 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 ffff 0400 1700 0000
;0000 9a00 0300 2400 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 003f 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 0000
;0000 0000 0000 0000 0000 0000 0000 9aa5