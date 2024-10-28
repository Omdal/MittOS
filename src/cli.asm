CLI:
    CALL CLI_PROMPT
    CALL CLI_IN
    CALL CLI_EXECUTE
    JR CLI ; Keep running

CLI_PRINT_WO_SPACES:
    PUSH BC
    LD B, FAT_FOLDERNAME_LENGTH
CLI_STRIP_SPACES_LOOP:
    LD A, (HL)
    CP ' '
    JR Z, CLI_STRIP_SPACES_SKIP
    CALL printChar
CLI_STRIP_SPACES_SKIP:
    INC HL
    DJNZ CLI_STRIP_SPACES_LOOP
    POP BC
    RET

; Print the command prompt
CLI_PROMPT:
    CALL printCRLF
    ;Drive letter followed by :
    LD HL, HDD_CURRENT_DRIVE_INDEX
    LD A, (HL)
    ADD 'A'
    CALL printChar
    CP 'A'
    JR C, _CLI_PROMPT_SKIP_COLON_
    LD A, ':'
    CALL printChar
    ; Folders and subfolders separated by \
    LD HL, FAT_FOLDER_DEPTH
    LD A, (HL)
    CP 0
    JR Z, _CLI_PROMPT_SKIP_COLON_
    LD B, A
    LD HL, FAT_FOLDERS
    LD DE, FAT_FOLDERNAME_LENGTH
CLI_PROMPT_FOLDERS:
    LD A, '\\'
    CALL printChar
    CALL CLI_PRINT_WO_SPACES
    DJNZ, CLI_PROMPT_FOLDERS
_CLI_PROMPT_SKIP_COLON_:
    LD A, '>'
    CALL printChar
    RET



CLI_IN:
    LD      HL,     COMMANDLINE     ; Reset input string
_CLI_IN_NEXT_LETTER:
    LD      C,      SERIAL_CW_1     ; Use serial port for input
    CALL    sio_rx_blocking         ; Read button press
    LD      (HL),   B               ; Save the input
    INC     HL                      ; increment the pointer
    LD      A,      B               ; Echo the buttonpress back to the user
    ; Check for special inputs
_CLI_IN_CHECK_BACKSPACE:
    CP      7Fh
    JR      NZ,     _CLI_IN_DONE_BACKSPACE
    DEC     HL                      ; Step back to backspace character
    DEC     HL                      ; Step back to previous letter
    LD      DE,     COMMANDLINE
    LD      A,      H               ; Check if backspace is at the start of
    CP      D                       ; the command line
    JR      C,      CLI_IN
    JR      NZ,     _CLI_IN_DONE_BACKSPACE
    LD      A,      L
    CP      E
    JR      C,      CLI_IN
_CLI_IN_DONE_BACKSPACE:
    LD      A,      B
    LD      C,      SERIAL_CW_1
    CALL    sio_tx_blocking
_CLI_IN_CHECK_ENTER:
    CP      0Dh                     ; If character is not 0D, read next character
    JR      NZ,     _CLI_IN_NEXT_LETTER
    DEC     HL                      ; Delete enter
    LD      (HL),   0               ; Set string end character
_CLI_IN_DONE:
    RET



CLI_EXECUTE:
    PUSH    HL                      ; Save HL before messing with it.
    LD      HL,     COMMANDLINE
    CALL    ToUpper
    OR      A                       ; Reset carry
    LD      DE,     COMMANDLINE
    POP     HL
    SBC     HL,     DE
    LD      A,      L               ; Get the length of the input string
    CP      1
    RET     C                       ; The string is empty. Wait for new input
    ; Check command
    CP      2
    JR      Z,      CLI_TWO_LETTER

    ; CD ***
    LD      HL, COMMANDLINE
    LD      A, (HL)
    CP      'C'
    JR      NZ, _CLI_CD_DONE
    INC     HL
    LD      A, (HL)
    CP      'D'
    JR      NZ, _CLI_CD_DONE
    INC     HL
    LD      A, (HL)
    CP      ' '
    JR      NZ, _CLI_CD_DONE
    LD      B, 11
    LD      DE, FAT_TARGET_NAME
    INC     HL
_CLI_COPY_FOLDER_LOOP_:
    LD      A, (HL)
    CP      0
    JR      NZ, _CLI_COPY_FOLDER_LOOP_COPY_
    LD      A, ' '
    JR      _CLI_COPY_FOLDER_LOOP_SPACE_NEXT_
_CLI_COPY_FOLDER_LOOP_COPY_:
    INC HL
_CLI_COPY_FOLDER_LOOP_SPACE_NEXT_:
    LD      (DE), A
    INC     DE
    DJNZ    _CLI_COPY_FOLDER_LOOP_
    ; Parameters:
    ; B: Directory = 1
    ; A: 0=file found
    ; C: 16 - file-index
    ; CurrentLocation = Found in this sector
    LD B, 1
    CALL FAT_FIND
    CP      0
    JR      NZ, CLI_BAD_COMMAND
    ; Switch folder
    CALL    FAT_SWITCH_DIRECTORY
    RET
_CLI_CD_DONE:
    ; Look for file
    LD      HL, COMMANDLINE
    LD      B, 8
    LD      DE, FAT_TARGET_NAME
_CLI_COPY_FILE_LOOP_:
    LD      A, (HL)
    CP      0
    JR      NZ, _CLI_COPY_FILE_LOOP_COPY_
    LD      A, ' '
    JR      _CLI_COPY_FILE_LOOP_SPACE_NEXT_
_CLI_COPY_FILE_LOOP_COPY_:
    INC HL
_CLI_COPY_FILE_LOOP_SPACE_NEXT_:
    LD      (DE), A
    INC     DE
    DJNZ    _CLI_COPY_FILE_LOOP_
    ; Parameters:
    ; B: Directory = 1
    ; A: 0=file found
    ; C: 16 - file-index
    ; CurrentLocation = Found in this sector
    LD      A,  'C'
    LD      (DE), A
    INC     DE
    LD      A,  'O'
    LD      (DE), A
    INC     DE
    LD      A,  'M'
    LD      (DE), A
    LD B, 0
    CALL FAT_FIND
    CP      0
    JR      NZ, CLI_BAD_COMMAND
    ; Execute file..
    CALL FAT_LOAD_FILE
    RET



    ; No command found?
CLI_BAD_COMMAND:
    LD      HL,     Error
    CALL    printstring
    LD      HL,     COMMANDLINE
    CALL    printstring
    
    RET

CLI_TWO_LETTER:
    LD      HL,     COMMANDLINE +1
    LD      A,      (HL)
    CP      ':'
    JR      Z,      CLI_SWITCH_DRIVE
    CP      'S'
    JR      NZ,     CLI_BAD_COMMAND
    DEC     HL
    LD      A,      (HL)
    CP      'L'
    JR      NZ,     CLI_BAD_COMMAND
    CALL    FAT_LIST_FILES
    RET


CLI_SWITCH_DRIVE:
    DEC     HL
    LD      A,      (HL)
    ;CALL    FAT_LOAD_DRIVE
    CALL    FAT_LOAD_DRIVE

    LD      B, A
    
    ;ld hl, HDD_DISKA
    ;call printSectorContent
    RET

Error:          db 0Dh,0Ah,"Bad command or filename: ", 0
