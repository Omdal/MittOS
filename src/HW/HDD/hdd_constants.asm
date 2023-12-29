; PATA - Parallel Advanced Technology bus Attachment

; S.M.A.R.T - Self-Monitoring, Analysis and Reporting Technology

; 3-bit adress port

; C C
; S S
; 1 0
;
; A N 0 0 0 Data                Data
; A N 0 0 1 Error Register      Features
; A N 0 1 0 Sector Count        Sector Count
; A N 0 1 1 Sector Number       Sector Number
; A N 0 1 1 * LBA Bits 0-7      * LBA Bits 0-7
; A N 1 0 0 Cylinder Low        Cylinder Low
; A N 1 0 0 * LBA Bits 8-15     * LBA Bits 8-15
; A N 1 0 1 Cylinder High       Cylinder High   
; A N 1 0 1 * LBA Bits 16-23    * LBA Bits 16-23
; A N 1 1 0 Drive/Head          Drive/Head
; A N 1 1 0 * LBA Bits 24-27    * LBA Bits 24-31
; A N 1 1 1 Status              Command
; X X X X X Invalid Address     Invalid Address

; 1. Write sector number or CHS
; 2. Issue Read or Write Command
; 3. Read or Write up to 512 times

; 268 435 456 (x512 bytes?)
; 262 144 k
; 256 M
; (128GB?)

; https://wiki.osdev.org/ATA_PIO_Mode#28_bit_PIO
; https://www.hackster.io/michalin70/extend-an-arduino-with-a-cf-card-or-ide-drive-d0a8f8


; Bt CC HH SS Tc CC HH SS ----LBA---- ---Length--
; 00 20 21 00 0C 35 70 05 00 08 00 00 00 00 40 00
; 00 35 71 05 0C 4B 81 0A 00 08 40 00 00 00 40 00
; 00 4B 82 0A 0C 60 D1 0F 00 08 80 00 00 00 40 00
; 00 60 D2 0F 0F FE FF CB 00 08 C0 00 00 58 2E 00

; 00 00 08 00 = 2048, 10270
; 00 40 08 00 = 4196352, 4204574
; 00 80 08 00 = 8390656, 8398878
; 00 C0 08 00 = 12584960, Partisjonstabell

; 00 20 21 00 0C 0E 11 BD 00 08 00 00 00 50 2E 00

;   00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 
; 0 53 59 53 54 45 4D 7E 31 20 20 20 16 00 12 C6 95
; 1 69 57 69 57 00 00 C7 95 69 57 03 00 00 00 00 00
; 2 E5 6C 00 65 00 00 00 FF FF FF FF 0F 00 DA FF FF
; 3 FF FF

; 7A 7B 78 79 * 512 = disk space


; MBR
; BootInd   StartingHead StartingSector StartingCylinder
; SystemID  EndHead EndSector EndCylinder
; Relative sectors X X X
; Total sectors X X X

; Boot indicator:
;   0x00 Not bootable
;   0x80 Bootable

; Sector / Cylinder is split differently
; Sector [0..5]
; Cylinder [0..15]


; System ID (https://www.win.tue.nl/~aeb/partitions/partition_types-1.html)
;   0x01    FAT12<32MB
;   0x04    FAT16<32MB
;   0x05    MS Extended partition using CHS
;   0x06    FAT16B
;   0x07    NTFS,HPFS,exFAT
;   0x0B    FAT32 CHS
;   0x0C    FAT32 LBA
;   0x0E    FAT16 LBA
;   0x0F    MS Extended partition LBA
;   0x42    Windows Dynamic volume
;   0x82    Linux swap
;   0x83    Linux
;   0x84    Windows hibernation partition
;   0x85    Linux Extended
;   0xAB    Mac OS X boot
;   0xAF    HFS, HFS+
;   0xEE    MS GPT
;   0xEF    Intel EFI


; 1B8 - 1BB = Serial number
; 1BC - 1BD = Reserved (00 00)