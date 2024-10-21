HDD1Addr    EQU 10h
HDD2Addr    EQU 20h
HDD3Addr    EQU 18h

HDDxDta     EQU 0  ; Data port
HDDxErr     EQU 1  ; Error / Feature
HDDxLen     EQU 2  ; Number of sectors to transfer
HDDxLBA0    EQU 3  ; Sector address LBA0 [0:7]     sector
HDDxLBA1    EQU 4  ; Sector address LBA1 [8:15]    cyl-l
HDDxLBA2    EQU 5  ; Sector address LBA2 [16:23]   cyl-h
HDDxLBA3    EQU 6  ; Sector address LBA3 [24:31]   head
HDDxSts     EQU 7  ; Status / Command

HDD_CMD_IDENTIFY_DRIVE  EQU ECh
HDD_CMD_READ            EQU 21h ; 20h or 21h ????

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


;   A   :   HDDxData register address
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

;   HL pointing to the LBA address (LSB first, 4 bytes)
;   C indicating disk data-port address
;   Ends with C pointing to disk command address
HDDSetAddress:
    PUSH    AF
    INC     C                       ; Error / Feature
    INC     C                       ; Number of sectors to transfer
    LD      A, 1                    ; Read 1 sector
    LD      B, 4                    ; Repeat 4 times
;    scf                             ; Set carry flag to increment address by 1
_HDDSetAddress_Out:
    OUT     (C), A                  ; Write to CF-card
    INC     C                       ; Move to sector address LBA0 [0:7]
    LD      A, (HL)                 ; Get LBA0
    INC     HL
;    adc     A,  0                   ; Increment address by 1
    DJNZ    _HDDSetAddress_Out      ; Repeat for LBA1-3
    AND     0Fh                     ; After 3 low bytes, set LBA mode
    OR      E0h
    OUT     (C), A                  ; Write the modified high byte
    INC     C                       ; Move to status / Command
    CALL    HDDWaitForReady         ; Wait for the card to handle the address
    POP     AF
    RET

; HDD Read sector
;   C   :   HDD_Disk_Data address
;   DE  :   DEstination address
;   HL  :   Pointer to HDD sector ID
HDDReadSector:
    push    AF
    push    BC
    push    HL
    push    BC                      ; Save Disk address for later use
    call    HDDSetAddress
    call    HDDWaitForReady
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

;848A 3C8D 0000 0010 0000 0240 003F 
;00EE 6C00 0000
;2020 2020 2043 505A 3131 3032 3136 3034 3539 3231
;0002 0002 0004
;4844 5820 372E 3038
;5361 6E44 6973 6B20 5344 4346 4853 4E4A 432D 3030 3847 2020 2020 2020 2020 2020 2020 2020 2020 2020
;8001 0000
;2300
;-50- 0000 0200 0000 0007 
; Cylinders: 3C8D
; Heads:     0010
; Sectors pr. track: 003F
; Capacity: 6B30 00EE
; 0100 6C00 00EE 0000 0007 0003 0078 0078 0078 0078 4020 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 7020 740C 4660 7020 0404 4040 003F 0000 0000 0000 FFFE 0000 0000 0000 0000 0000 0000 0000 6C00 00EE 0000 0000 0000 0001 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 81F4 0000 0000 7082 0000 8055 0000 6000 0000 0001 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

;848A 01EA 0000 0004 0000 0200 0020
;0000 F500 0000
;5830 3331 3220 3230 3034 3131 3233 3036 3036 3536
;0001 0001 0004
;5265 7620 332E 3030
;4869 7461 6368 6920 5858 4D32 2E33 2E30 2020 2020 2020 2020 2020 2020 2020 2020 2020 2020 2020 2020
;0001 0000
;0200
;-50- 0000 0200 0000 0001
;01EA 0004 0020 F500 0000 0100 F500 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000


; C = LBA / (HPC * SPT)         LBA / ( ?? * 3F)
; H = (LBA / SPT) mod HPC       (LBA / 3F) % ??
; S = (LBA % SPT) +1            (LBA % 3F) +1

; 0800 % 3F