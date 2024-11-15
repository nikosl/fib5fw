/* Copyright 2024 Nikos Leivadaris <nikosleiv@gmail.com> */
/* SPDX-License-Identifier: MIT */

OUTPUT_ARCH("riscv")

OUTPUT_FORMAT("elf64-littleriscv")

ENTRY(_start)

/**
 * Qemu virt machine memory map
 */
MEMORY
{
    rom (rx)  : ORIGIN = 0x80000000, LENGTH = 0x100000
    prog (rx) : ORIGIN = 0x80100000, LENGTH = 0x100000
    ram (rw) : ORIGIN = 0x80200000, LENGTH = 0x200000
}

SECTIONS
{
    __stack_size = 4096;

    .text : ALIGN(4) {
        *(.text)
        *(.text.*) 
    } >rom

    .rodata : ALIGN(4) {
        *(.rodata)
    } >rom

    .data : ALIGN(4) {
        *(.data)
        . = ALIGN(4);
        PROVIDE( __global_pointer$ = . + 0x800 );
        *(.sdata)
    } >ram

    _fib_data_dst_begin = ADDR(.data);
    _fib_data_dst_end = _fib_data_dst_begin + SIZEOF(.data);
    _fib_data_src_begin = LOADADDR(.data);
    
    .bss (NOLOAD): ALIGN(4) {
        *(.bss);
        *(.sbss);
        *(COMMON)
    } >ram

    _fib_bss_begin = ADDR(.bss);
    _fib_bss_end = _fib_bss_begin + SIZEOF(.bss);

    .stack (NOLOAD): ALIGN(16) { 
        PROVIDE(fib_segment_stack_begin = .);
        . += __stack_size;
        PROVIDE(_sp = .);
        PROVIDE(fib_segment_stack_end = .);
    } >ram

    _end = .;

    /* store build id */
    .gnu_build_id : {
        PROVIDE(g_note_build_id = .);
        *(.note.gnu.build-id)
    } >rom

    .debug : { *(.debug) } >rom 

}