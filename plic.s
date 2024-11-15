/* Copyright 2024 Nikos Leivadaris <nikosleiv@gmail.com>.
 SPDX-License-Identifier: MIT 
 
  https://github.com/hubbsvtgc/LearnRISC-V/tree/release
  https://marz.utk.edu/my-courses/cosc562c/riscv/#plic
 */


.equ PLIC_BASE, 0x0c000000
.equ PLIC_PENDING_BASE, 0x1000
.equ PLIC_ENABLE_OFFSET, 0x2000
.equ PLIC_THRESHOLD_OFFSET, 0x200000

.equ PLIC_MODE_MACHINE, 0x0

# #define PLIC_PRIORITY(interrupt) \
#     (PLIC_BASE + PLIC_PRIORITY_BASE * interrupt)
# #define PLIC_THRESHOLD(hart, mode) \
#     (PLIC_BASE + PLIC_CONTEXT_BASE + PLIC_CONTEXT_STRIDE * (2 * hart + mode))
# #define PLIC_CLAIM(hart, mode) \
#     (PLIC_THRESHOLD(hart, mode) + 4)
# #define PLIC_ENABLE(hart, mode) \
#     (PLIC_BASE + PLIC_ENABLE_BASE + PLIC_ENABLE_STRIDE * (2 * hart + mode))

.global plic_set_threshold
.global plic_set_priority
.global plic_enable_src
.global plic_claim

.section .text
plic_set_priority:
    /**
     * set the priority of an interrupt sources.
     * Interrupt priority levels 7
     * 
     * 0 - never interrupt/disables interrupt
     * 1 - lowest active priority
     * 7 - highest priority
     *
     * @param source interrupt source
     * @param priority priority level
     */

    /*
     * void plic_set_priority(uint32_t source, uint32_t priority)
     * a0: interrupt
     * a1: priority
     */

    li t0, PLIC_BASE
    slli a0, a0, 2 /* priority_base = 4
                    * priority_offset = priority_base * interrupt */
    add t0, a0, t0 /* plic_base + priority_offset */
    sw a1, (t0)   /* write priority to register */
    ret

/*******************************************
* FUNCTION to enable a source interrupt in PLIC CORE.
* Argument: Register a0 with interrupt src id
********************************************/
plic_enable_src:
    /*************************************************
     count of 32: x in input source id a0 = mod(a0, 32).
     Enable bits register offset to source = x * 4
     Bit position in enable bit register is a0 - (x * 32)
     ****************************************************/

    srli t0, a0, 5; /* t0 -> x */
    slli t1, t0, 2;
    li t2, PLIC_BASE;
    add t1, t1, t2;
    li t2, PLIC_ENABLE_OFFSET;
    add t1, t1, t2; /* t1 -> enable register addr */
    slli t2, t0, 5;
    sub t0, a0, t2;
    li t2, 1;
    sll t2, t2, t0; /* t2 -> value to be written to enable bit */
    sw t2, 0(t1);
    ret

/*******************************************
* FUNCTION to set priority threshold per target.
* Argument: Register a0 with target/context,
* Register a1 with threshold value
********************************************/
plic_set_threshold:
    li t0, PLIC_BASE
    li t1, PLIC_THRESHOLD_OFFSET
    add t1, t1, t0
    sw a0, (t1)
    ret

plic_claim:
    li t0, PLIC_BASE
    li t1, PLIC_THRESHOLD_OFFSET
    addi    t1, t1, 4
    add t1, t1, t0
    lw    a0, (t1)
    sw a0, (t1)
    ret
