/* Copyright 2024 Nikos Leivadaris <nikosleiv@gmail.com>.
 * SPDX-License-Identifier: MIT
 */

/* https://danielmangum.com/posts/risc-v-bytes-privilege-levels/ */

/* Machine Trap Setup Related CSR_BITPOS */
/* mstatus, mtvec, mie are 3 major to set up
   mstatus - global setup */

.equiv MSTATUS_MIE, 0x8
.equiv MIE_MTIE, 0x80 /* Bit 7 - Machint Timer Interrupt */
.equiv MIE_MEIE, 0x800 /* Bit 11 - Machine External Interrupt */

/* Machine Trap Handler Related */

.equiv MIP_MTIE, 0x80 /* Bit 7 - Machint Timer Interrupt */
.equiv MIP_MEIE, 0x800 /* Bit 11 - Machine External Interrupt */
.equ MSTATUS_MIE_BIT_MASK, 0x8
.equ UART_FIFO_SIZE, 16		/* Number of bytes FIFO can hold */

.equiv CFI_FLASH_BASE, 0x20000000
.equiv CFI_FLASH_QUERY_CMD, 0x98
.equiv CFI_FLASH_QUERY_OFFSET, 0x55
.equiv CFI_FLASH_RESET_CMD, 0xF0
.equ CFI_FLASH_BANK_WIDTH, 0x4

.equ SYSCON_BASE, 0x100000
.equ SYSCON_POWEROFF, 0x5555
.equ SYSCON_REBOOT, 0x7777

.section .text
.global _start
_start:
    /* set global pointer */
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop

    /* setup sp */
    la sp, _sp
    /* jal start */
    /* init bss data */
 
    /* disable interrupts */
    csrc    mstatus, MSTATUS_MIE_BIT_MASK
    csrw    mie, zero
 
    # li      a0, SYSCON_BASE
    # li      a1, SYSCON_POWEROFF
    # zext.w  a1, a1
    # sw      a1, (a0)


    /* initialize the PLIC */
    li      a0, 2
    call    plic_set_threshold

    /* uart interrupt priority */
    li     a0, 0x0a
    li     a1, 0x03
    call   plic_set_priority

    /* enable the UART interrupt */
    li      a0, 0x0a
    call    plic_enable_src

    la      t0, uart_interrupt_handler_m
    csrw    mtvec, t0
 
    call    uart_init

    /* flash query */
    li      a5, CFI_FLASH_BASE
    li      a1, CFI_FLASH_RESET_CMD
    sw      a1, (a5)
    li      a2, CFI_FLASH_QUERY_CMD
    li      a3, CFI_FLASH_QUERY_OFFSET
    slli    a3, a3, 2
    add     a3, a3, a5
    sw      a2, (a3)
    li      a2, 0x10
    slli    a2, a2, 2
    add     a5, a5, a2
 
    li      a3, 'Q'
    lbu     a2, (a5)
    mv      a0, a2
    call    uart_putc

    li      a3, 'R'
    addi    a5, a5, CFI_FLASH_BANK_WIDTH
    lbu     a2, (a5)
    mv      a0, a2
    call    uart_putc

    li      a3, 'Y'
    addi    a5, a5, CFI_FLASH_BANK_WIDTH
    lbu     a2, (a5)
    mv      a0, a2
    call    uart_putc

    li      a5, CFI_FLASH_BASE
    sw      a1, (a5)
/* Funtion to enable machine interrupt and
 * machine external interrupt */

   /* Read MIE csr and set bit 11 to enable external
    * interrupt */

    csrr t0, mie;

    li t1, MIE_MEIE;
    or t0, t0, t1;

    csrw mie, t0;

    /* Read MSTATUS csr and set bit 3
    to enable machine interrupt */

    csrr t0, mstatus;

    li t1, MSTATUS_MIE_BIT_MASK;
    or t0, t0, t1;

    csrw mstatus, t0;


    la      a0, msg
    call    str_put_s

    li      s1, UART_FIFO_SIZE
    addi    s1, s1, -1
    la      s2, buf

    li      a0, '\n'
    sb      a0, (s2)
    sb      zero, 1(s2)
    mv      a0, s2
    call    str_put_s
2:
    la      a0, cli_msg
    call    str_put_s
3:
    mv      a0, zero
    call    uart_getc
    wfi
    beqz    a0, 3b

    mv      s3, a0
    call    str_is_num
    beqz    a0, 2b
    andi    a0, s3, 0x0f
    mul     a0, a0, a0
    mv      a1, s2
    call    str_itoa_s
    la      a0, cli_msg_result
    call    str_put_s
    mv      a0, s2 
    call    str_put_s
    sb      zero, (s2)
    wfi
    j       2b

    la      t0, supervisor
    csrw    mepc, t0
    la      t1, m_trap
    csrw    mtvec, t1
    li      t2, 0x1800
    csrc    mstatus, t2
    li      t3, 0x800
    csrs    mstatus, t3
    li      t4, 0x100
    csrs    medeleg, t4
    mret

.balign 64
uart_interrupt_handler_m:
    mv    s6, ra
    call    plic_claim
    csrr    a1, mcause
    csrr    a2, mepc
    beqz    a0, 1f
    call    uart_interrupt_handler
1:
    mv    ra, s6
    mret

m_trap:
    csrr    t0, mepc
    csrr    t1, mcause
    la      t2, supervisor
    csrw    mepc, t2
    mret

supervisor:
    la      t0, user
    csrw    sepc, t0
    la      t1, s_trap
    csrw    stvec, t1
    sret

s_trap:
    csrr    t0, sepc
    csrr    t1, scause
    ecall

user:
    csrr    t0, instret
    ecall

.section .data
msg:
    .asciz "\n\n╔═════════════════════════════════════════════════╗\n║                                                 ║\n║         __    ______    ______   _______        ║\n║   _  _ /  |  / ____ `. / ____ `.|  ___  |_  _   ║\n║  (_)(_)`| |  `'  __) | `'  __) ||_/  / /(_)(_)  ║\n║   _  _  | |  _  |__ '. _  |__ '.    / /  _  _   ║\n║  (_)(_)_| |_| \\____) || \\____) |   / /  (_)(_)  ║\n║       |_____|\\______.' \\______.'  /_/           ║\n║                                                 ║\n╚═════════════════════════════════════════════════╝\n\n"
cli_msg:
    .asciz "[::1337::] Enter a number > "
cli_msg_result:
    .asciz "\n[::1337::] Result > "
buf:
    .zero UART_FIFO_SIZE
