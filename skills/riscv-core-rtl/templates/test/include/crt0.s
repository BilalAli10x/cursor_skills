# Minimal startup: set SP, clear .bss, call main, then spin.
# Engineering decision: RV64 `sd`/`lla`. For RV32, the generating skill
# substitutes `sw` and 4-byte bss steps.

    .section .text.init, "ax", @progbits
    .align  2
    .globl  _start
    .type   _start, @function
_start:
    lla     sp, _stack_top

    lla     t0, _sbss
    lla     t1, _ebss
1:
    bgeu    t0, t1, 2f
    sd      zero, 0(t0)
    addi    t0, t0, 8
    j       1b
2:
    call    main
3:
    j       3b
    .size   _start, .-_start
