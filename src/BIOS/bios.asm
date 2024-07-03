; Interrupt vector (Register A)
BIOS_IV_SCREEN      EQU 10h
BIOS_IV_DISK        EQU 13h
BIOS_IV_SERIAL      EQU 14h
BIOS_IV_KEYBOARD    EQU 16h
BIOS_IV_PRINTER     EQU 17h

; Parameter 1&2 (Register B & C)



    org E000h
BIOS_PARAM0:
    org E001h
BIOS_PARAM1:
    org E002h
BIOS_PARAM2:
    org E003h
BIOS_PARAM3:
    org E004h
BIOS_PARAM4:
    org E005h
BIOS_PARAM5:
    org E006h
BIOS_PARAM6:
    org E007h
BIOS_PARAM7:
    org E008h
BIOS_PARAM8:
    org E009h
BIOS_PARAM9:
    org E00Ah
BIOS_PARAMA:
    org E00Bh
BIOS_PARAMB:
    org E00Ch
BIOS_PARAMC:
    org E00Dh
BIOS_PARAMD:
    org E00Eh
BIOS_PARAME:
    org E00Fh
BIOS_PARAMF:
    org E010h
BIOS_CALL:
