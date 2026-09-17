# <core> — RISC-V core

Fill: ISA string, stage count, XLEN.

## Layout

```
README.md
rtl/     SystemVerilog (one file per stage + ALU, decoder, CSR, regfile; no TCM)
sim/     Verilator build output (obj_dir) — no sources
tb/      SV testbench + Verilator C++ driver + mem.sv
test/    crt0, linker, C tests
docs/    rtl / tb / test notes
```

## Memory map

| Region | Address | Owner |
| ------ | ------- | ----- |
| RAM / reset | `0x80000000` (32 MiB in TB) | `tb/mem.sv` |
| Halt / complete | `0x10000000` (store `1` = pass) | TB watches data port |
| Putchar | `0x10000008` | TB `$write` |

The core has no special-case for halt/putchar.

## Build and run

Toolchain: `riscv64-unknown-elf-gcc` (or `riscv32-...`) and Verilator ≥ 5.021.

```bash
cd test && make
cd ../tb && make run ELF=../test/build/hello_world.elf

cd ../test && make TEST=isa_smoke
cd ../tb && make run ELF=../test/build/isa_smoke.elf
```
