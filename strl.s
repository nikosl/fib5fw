/* Copyright 2024 Nikos Leivadaris <nikosleiv@gmail.com>.
 * SPDX-License-Identifier: MIT */

.equ NUM_BASE, 10

.global str_put_s
.global str_itoa_s
.global str_is_num

.section .text
str_put_s:
    mv      a7, a0
    mv      a6, ra
1:
    lbu     a0, 0(a7)
    beqz    a0, 2f
    call    uart_putc
    addi    a7, a7, 1
    j       1b
2:
    # li     a0, '\n'
    # call   uart_putc
    mv      ra, a6
    ret

str_itoa_s:
    mv      t0, a0
    mv      a7, a1
    li      t1, NUM_BASE
    mv      t3, zero
    bnez    t0, 1f
    li      t2, '0' 
    j       3f
1:
    remu    t2, t0, t1   # int rem = num % base;
    divu    t0, t0, t1   # num = num / base;
    addi    t2, t2, '0'
3:
    sb      t2, (a7)
    addi    a7, a7, 1
    addi    t3, t3, 1
    bnez    t0, 1b 
    sb      zero, (a7)
    /* reverse string */
    mv      t0, a1      /* tail */
    addi    a7, a7, -1  /* head */
    srli    t3, t3, 1
1:
    beqz    t3, 2f
    lbu     t2, (a7)
    lbu     t1, (t0)
    sb      t2, (t0)
    sb      t1, (a7)
    addi    a7, a7, -1
    addi    t0, t0, 1
    addi    t3, t3, -1
    j       1b
2:
    ret

str_is_num:
    mv      t0, a0
    li      t1, '0'
    sub     t0, t0, t1
    sltiu   a0, t0, 10
    ret
