### My homebrew operating system for Z80

See https://olav.fun/z80 for project description.

This is a work in progress, and the code may be very messy.

Tools needed:
https://github.com/EdouardBERGE/rasm

To compile:
```
rasm_win64.exe -s main.asm
```
or edit the makefile to automate copying of the compiled file to your EPROM writer folder.

The code should be compatible with RC2014 Zed with the Zilog SIO-2 serial interface.
https://rc2014.co.uk/full-kits/rc2014-pro-pride-and-rc2014-zed-pro-pride/