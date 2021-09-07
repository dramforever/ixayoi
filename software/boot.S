.section .text.start, "ax", @progbits
.global _start
_start:
    li a0, 0xd0000000
    li a1, 0xc0000000
    li a2, 0xc0010000
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

.section .text, "ax", @progbits
.global main
main:
    call print
    li a0, 100000000
    call waste
    j main

print:
    li a0, 0x40600000
    la a1, msg
.loop:
    lbu a2, 0(a1)
    addi a1, a1, 1
    beqz a2, .end
    sb a2, 4(a0)
.wait:
    lw a2, 8(a0)
    andi a2, a2, 8
    bnez a2, .wait
    j .loop

.end:
    ret

msg:
    .string "Hello from Ixayoi!\n"

waste:
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    addi a0, a0, -1
    bgtz a0, waste
    ret
