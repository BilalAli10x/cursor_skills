/* Linked image in TB RAM at 0x80000000 (riscv-arch-test map).
   Halt/putchar are outside this window (0x10000000 / 0x10000008). */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 1M
}

SECTIONS
{
    .text : {
        *(.text.init)
        *(.text .text.*)
        . = ALIGN(8);
    } > RAM

    .rodata : {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
        . = ALIGN(8);
    } > RAM

    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
        . = ALIGN(8);
    } > RAM

    .bss : {
        _sbss = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        . = ALIGN(8);
        _ebss = .;
    } > RAM

    /* Stack grows down from the top of this 1 MiB window. */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
