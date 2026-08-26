# Author: Aaron Dill
# Date: {{$DATE}}
# Description: ______________________________

.include "SysCalls.asm"

.data
# Data segment: constant and variable definitions go here
msg: .asciiz "Hello, World!\n"

.text
# Text segment: assembly instructions go here
    li $v0, SysPrintString # print string
    la $a0, msg
    syscall
    li $v0, SysExit # exit
    syscall

