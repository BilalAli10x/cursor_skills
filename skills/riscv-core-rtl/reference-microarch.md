# Microarchitecture rules for generated Silver cores

Apply when `riscv-core-rtl` generates or extends a core. Do **not** copy `silver_cpu1b` TCM, combinational mul/div, or `0x80000000` tohost.

## File split

One SystemVerilog file per pipeline stage plus helpers. Typical 5-stage:

- `rtl/rv32_pkg.sv` or `rtl/rv64_pkg.sv` — opcodes, `ctrl_t`, helpers
- `rtl/if_stage.sv`, `rtl/id_stage.sv`, `rtl/ex_stage.sv`, `rtl/mem_stage.sv`, `rtl/wb_stage.sv`
- `rtl/alu.sv`, `rtl/muldiv.sv` (if M), `rtl/decoder.sv`, `rtl/regfile.sv`, `rtl/csr_file.sv`
- `rtl/compressed.sv` if C; `rtl/amo.sv` if A
- `rtl/core.sv` — thin interconnect + parameters + memory-window mux (no pipeline body)

6-stage: add `if2_stage` (or split EX). 7-stage: IF1/IF2 plus split EX. Default to **5** if the user omitted stage count.

**No `tcm.sv`.** No internal memories.

## Timing (≤100 MHz WNS)

Engineering decision: **iterative/sequential** multiply and divide in EX. Stall EX (and upstream) until the unit finishes. Restoring or non-restoring divider is fine; a compact iterative multiplier (one partial product per cycle, or radix-4) is fine. Do **not** infer combinational `*` `/` `%` on XLEN-wide values.

AMOs: 2-cycle RMW in MEM if A is present. `aq`/`rl` ignored unless the user asked for ordering.

## Interfaces

```
clk, rst_n                          // rst_n active-low
o_ext_imem_addr[63:0], o_ext_imem_valid, i_ext_imem_ready, i_ext_imem_rdata[31:0]
o_ext_dmem_addr[63:0], o_ext_dmem_wdata[63:0], o_ext_dmem_wstrb[7:0],
o_ext_dmem_we, o_ext_dmem_valid, i_ext_dmem_ready, i_ext_dmem_rdata[63:0]
```

Add `irq` / debug ports **only** if the prompt asks. No AXI/AHB on the core. Buses are single-cycle valid/ready from the core’s point of view.

Keep parameterized windows (`ITCM_BASE/SIZE`, `DTCM_BASE/SIZE`) defaulting **SIZE=0** so all traffic goes external. That mux stays so TCM can be added later without touching the pipeline.

`RESET_VECTOR [63:0]` defaults to the instruction-memory base (`64'h8000_0000` for the unified TB). Overridable at instantiate.

## Hazards

- EX/MEM → EX and MEM/WB → EX forwarding for RAW
- Load-use stall (load in EX, consumer in ID)
- Flush in-flight instructions on taken branch/jump (not-taken predict is fine)

## Branch

Target address **and** condition are evaluated in **ID**, not EX.

## CSRs

- I always: `mcycle`, `minstret` (plus `mcycleh`/`minstreth` on RV32)
- Zicsr + interrupts: also `mstatus`, `mtvec`, `mepc`, `mcause`, `mie`, `mip` as needed
- No extra CSRs unless the user asked
- `ecall`/`ebreak`/`mret`/`wfi`/`fence` and illegal encodings: NOP unless interrupts/traps were requested

## Memory map (generated cores only)

This map is for cores **this skill** generates so later `riscv-arch-test-integrate` can reuse `tb/` with no second testbench. CVA6 and other GitHub cores keep their own maps.

| Region | Address | Owner |
| ------ | ------- | ----- |
| RAM / reset | `0x80000000`, 32 MiB | TB `mem.sv` |
| Halt / complete | `0x10000000` | TB watches data port (pass=1) |
| Putchar | `0x10000008` | TB `$write` byte |

The core has **no** special-case logic for halt/putchar.
