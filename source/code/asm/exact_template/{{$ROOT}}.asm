# Author: Aaron Dill
# Date: {{$DATE}}
# Description: ______________________________

.data
# Data segment: constant and variable definitions go here
msg: .asciiz "Hello, World!\n"

.text
# Text segment: assembly instructions go here
    li $v0, 4 # print string
    la $a0, msg
    syscall
    li $v0, 10 # exit
    syscall

