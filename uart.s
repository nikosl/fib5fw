/* Copyright 2024 Nikos Leivadaris <nikosleiv@gmail.com>.
 * SPDX-License-Identifier: MIT
 */

 /**
  * Uart *ns16550* driver.
  *
  * This module provides a simple interface to the UART peripheral.
  * peripheral is a [ns16550](https://uart16550.readthedocs.io/en/latest/uart16550doc.html) compatible UART.
  * 
  */

.equ UART_BASE, 0x10000000

/* Reg DLAB=0 */
.equ UART_THR, 0x0 /* WO: Transmit Holding Register */
.equ UART_RBR, 0x0 /* RO:  Receive Buffer Register */
.equ UART_IER, 1   /* RW: Interrupt Enable Register */
.equ UART_IIR, 2   /* RO:  Interrupt ID Register */
.equ UART_FCR, 2   /* WO: FIFO Control Register */
.equ UART_LCR, 3   /* RW: Line Control Register */
.equ UART_LSR, 5   /* RO:  Line Status Register */

/* Reg DLAB=1 */
.equ UART_DLL, 0x0 /* RW: Divisor Latch Low */
.equ UART_DLM, 1   /* RW: Divisor Latch High */

.equ UART_LCR_DLAB, 0x80	/* Divisor latch access bit */

.equ UART_FCR_ENABLE_FIFO, 0x01	/* Enable the FIFO */
.equ UART_FCR_CLEAR_RCVR, 0x02	/* Clear the RCVR FIFO */
.equ UART_FCR_CLEAR_XMIT, 0x04	/* Clear the XMIT FIFO */
.equ UART_FCR_TRIG_1, 0x00    	/* Receive Interrupt trigger level */
.equ UART_FCR_TRIG_4, 0x40    	/* Receive Interrupt trigger level */
.equ UART_FCR_TRIG_8, 0x80    	/* Receive Interrupt trigger level */
.equ UART_FCR_TRIG_14, 0xc0    	/* Receive Interrupt trigger level */

.equ UART_IER_RDI, 0x01		/* Enable receiver data interrupt */
.equ UART_IER_THRI, 0x02		/* Enable Transmitter holding register int. */
.equ UART_IER_RLSI, 0x04		/* Enable receiver line status interrupt */


.equ UART_IIR_MSI, 0x00	/* Modem status interrupt */
.equ UART_IIR_NO_INT, 0x01	/* No interrupts pending */
.equ UART_IIR_THRI, 0x02	/* Transmitter holding register empty */
.equ UART_IIR_RDI, 0x04	/* Receiver data interrupt */
.equ UART_IIR_RLS, 0x06	/* Receiver line status interrupt */
.equ UART_IIR_TIMEOUT, 0x0c		/* Receiver line status interrupt */
.equ UART_IIR_ID, 0x0e	/* Mask for the interrupt ID */


.equ UART_LSR_DR, 0x01	/* Receiver data ready */
.equ UART_LSR_THRE,	0x20	/* Transmit-hold-register empty */

.equ UART_FIFO_SIZE, 16		/* Number of bytes FIFO can hold */

.equ UART_BAUD_115200, 1

.equ UART_LEN_8, 0x03
.equ UART_STOP_1, 0x00
.equ UART_PAR_NONE, 0x00

.equ UART_DEFAULT_BAUD,	UART_BAUD_115200
.equ UART_DEFAULT_LEN, UART_LEN_8
.equ UART_DEFAULT_STOP,	UART_STOP_1
.equ UART_DEFAULT_PARITY, UART_PAR_NONE


.section .text

.global uart_init
.global uart_putc
.global uart_getc
.global uart_getc_b
.global uart_interrupt_handler

/*
todo: uart_putc
on int
clear int
rem sendd
check if buf empty, tx run

poll buf
stop int
check if buf empty, tx run
put buf
start tx
start int

*/

/**
 * uart_init - Initialize the UART peripheral.
 *
 * This function initializes the UART peripheral.
 * The UART peripheral is memory mapped.
 * 
 * @param baud_rate The baud rate of the UART peripheral.
 */
uart_init:
    li      t0, UART_BASE

    /* turn off interrupts */
    lb      zero, UART_LSR(t0)
    sb      zero, UART_IER(t0)

    /* set baud rate */
    li      t1, UART_LCR_DLAB
    sb      t1, UART_LCR(t0)
    li      t2, UART_DEFAULT_BAUD /* clock / 16 * baud */
    sb      t2, UART_DLL(t0)
    sb      zero, UART_DLM(t0) /* divisor >> 8 & 0xff */
    lbu     t2, UART_LCR(t0)
    not     t1, t1
    and     t2, t2, t1
    sb      t2, UART_LCR(t0)

    /* init uart */
    lbu     t1, UART_LCR(t0)
    ori     t1, t1, UART_DEFAULT_LEN
    ori     t1, t1, UART_DEFAULT_STOP
    ori     t1, t1, UART_DEFAULT_PARITY
    zext.b  t1, t1
    sb      t1, UART_LCR(t0)

    /* config FIFO */
    lbu     t1, UART_FCR(t0)
    ori     t1, t1, UART_FCR_ENABLE_FIFO
    ori     t1, t1, UART_FCR_CLEAR_RCVR
    ori     t1, t1, UART_FCR_CLEAR_XMIT
    ori     t1, t1, UART_FCR_TRIG_8
    zext.b  t1, t1
    sb      t1, UART_FCR(t0)

    /* enable rx interrupts */
    li      t1, UART_IER_RDI
    zext.b  t1, t1
    sb      t1, UART_IER(t0)

    ret
 
uart_putc:
    li      t0, UART_BASE
    lbu     t1, UART_LSR(t0)
    andi    t1, t1, UART_LSR_THRE
    beqz    t1, 1f
    sb      a0, UART_THR(t0) /* todo: check status */
1:
    ret

uart_getc:
    li      t0, UART_BASE
    lbu     t1, UART_LSR(t0)
    andi    t1, t1, UART_LSR_DR
    beqz    t1, 1f
    lb      a0, UART_RBR(t0)
1:
    ret

uart_putc_b:
    li      t0, UART_BASE
1:
    lbu     t1, UART_LSR(t0)
    andi    t1, t1, UART_LSR_THRE
    beqz    t1, 1b
    sb      a0, UART_THR(t0)
    ret

uart_getc_b:
    li      t0, UART_BASE
1:
    lbu     t1, UART_LSR(t0)
    andi    t1, t1, UART_LSR_DR
    beqz    t1, 1b
    lb      a0, UART_RBR(t0)
    ret

.align 4
uart_interrupt_handler:
    mv      s6, ra
    li      t0, UART_BASE
    lbu     t1, UART_IIR(t0)
    andi    t2, t1, UART_IIR_NO_INT
    bnez    t2, 1f
    andi    t2, t1, UART_IIR_ID

    li      t3, UART_IIR_THRI
    and     t3, t2, t3
    bnez    t3, .Luart_interrupt_handler_tx

    li      t3, UART_IIR_RDI
    li      t4, UART_IIR_TIMEOUT
    or      t3, t3, t4
    and     t3, t2, t3
    bnez    t3, .Luart_interrupt_handler_rx
    j       1f
.Luart_interrupt_handler_rx:
    call    uart_getc
    mv      ra, s6
    ret
.Luart_interrupt_handler_tx:
    call    uart_putc

    # li      t1, UART_IER_THRI
    # not     t1, t1
    # lbu     t2, UART_IER(t0)
    # and     t2, t2, t1
    # sb      t2, UART_IER(t0)
    
    mv      ra, s6
    ret
1:
    lb      zero, UART_LSR(t0)
    lb      zero, 6(t0)
    mv      ra, s6
    ret


_uart_ring_buffer_empty:
    /* a0: char
       a0: bool return 1 if buffer is full
    */
    la      t0, uart_out_buf_head
    la      t1, uart_out_buf_tail
    lw t0, 0(t0)
    lw t1, 0(t1)
    subw    t0, t0, t1
    seqz    a0, t0
    ret


_uart_ring_buffer_put:
    /* a0: char
       a0: bool return 1 if buffer is full
    */
    la      t0, uart_out_buf_head
    la      t1, uart_out_buf_tail
    lw t0, 0(t0)
    lw t1, 0(t1)
    subw    a0, t0, t1
    beqz a0, 1f

    la    t1, uart_out_buf
    add     t1, t1, t0
    sb      a0, 0(t1)
    li      a0, 1

    la      t1, uart_out_buf_mask
    addiw    t0, t0, 1
    and    t0, t0, t1
1:
    ret


_uart_ring_buffer_get:
    /* a0: char
       a0: bool return 1 if buffer is full
    */
    la      t0, uart_out_buf_head
    la      t1, uart_out_buf_tail
    lw t0, 0(t0)
    lw t1, 0(t1)
    subw    a0, t0, t1
    beqz a0, 1f

    la    t0, uart_out_buf
    add     t0, t0, t1
    lb      a1, 0(t0)
    li      a0, 1

    la      t0, uart_out_buf_mask
    addiw    t1, t1, 1
    and    t1, t1, t0
1:
    ret

    
.section .data
.align 4
uart_out_buf:
    .zero UART_FIFO_SIZE
uart_out_buf_mask:
    .word UART_FIFO_SIZE - 1
uart_out_buf_tail:
    .word 0
 uart_out_buf_head:   
    .word 0
