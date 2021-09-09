.section .text.startup, "ax", @progbits
.global _start
_start:
    li a0, 0xd0000000
    li a1, 0x80000000
    li a2, 0x80010000
1:
    lw a3, 0(a0)
    sw a3, 0(a1)
    addi a1, a1, 4
    addi a0, a0, 4
    bne a1, a2, 1b

    sub a1, a1, a0
    la a0, main
    add a0, a0, a1
    jr a0
