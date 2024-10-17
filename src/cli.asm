CLI:
    CALL CLI_PROMPT
    CALL CLI_IN
    CALL CLI_EXECUTE
    JR CLI ; Keep running



; Print the command prompt
CLI_PROMPT:
    CALL printCRLF
    CALL printCRLF
    ;Drive letter followed by :
    ; Folders and subfolders separated by \
    LD A, '$'
    CALL printChar

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
    OR      A                       ; Reset carry
    LD      DE,     COMMANDLINE
    PUSH    HL                      ; Save HL before messing with it.
    SBC     HL,     DE
    LD      A,      L               ; Get the length of the input string
    POP     HL
    CP      1
    RET     C                       ; The string is empty. Wait for new input
    ; Check command

    ; No command found?
    LD      HL,     Error
    CALL    printstring
    LD      HL,     COMMANDLINE
    CALL    printstring
    
    RET
    
Error:          db 0Dh,0Ah,"Bad command or filename: ", 0
