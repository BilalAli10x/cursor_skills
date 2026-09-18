---
name: riscv-core-rtl
description: >-
  Designs or extends a synthesizable RISC-V CPU core (RV32 or RV64, 5/6/7-stage,
  any of I/M/A/C/Zicsr, optional interrupts/debug) with split RTL, no internal
  TCM, Verilator TB, and freestanding tests. Use when the user asks to design a
  RISC-V CPU core, generate core RTL, add an ISA extension to an existing Silver
  core, or create a new silver_*_cpuN project. Not for CVA6/Ibex bring-up — those
  use riscv-arch-test skills instead.
---

# RISC-V Core RTL Generation

Independent. Only run when the user asks to **design or extend a Silver-style core**. Do not touch CVA6/Ibex/other clones unless that path was named as the thing to extend.

Read [reference-microarch.md](reference-microarch.md) before writing RTL. Copy files from [templates/](templates/) instead of regenerating Makefiles, TB, crt0, or hello_world.

## Conventions

- No clarifying questions. `// Engineering decision:` comments for underspecified items.
- Always write **riscv-arch-test** in full if mentioned in docs.
- Never overwrite `silver_cpu1b` unless the user named it.
- Commit in the **new or edited core repo** only: `skill(riscv-core-rtl): ...`.
- If Verilator is missing or `< 5.021`, follow the `verilator-setup` skill first, then continue.
- If `riscv32-unknown-elf-gcc` / `riscv64-unknown-elf-gcc` is missing, follow `riscv-gcc-setup` first, then continue. Do not compile GCC.

## Mode A — new core

### 1. Project name and tree

Workspace folder basename, strip trailing `_work` if present, then `_cpuN` with the smallest unused N.

Examples: `silver_work` → `silver_cpu1` if free; this machine already has `silver_cpu1b`, so the next free name may be `silver_cpu1`.

Create sibling of other cores (not inside this skills repo):

```
<core>/
  README.md  .gitignore
  rtl/  docs/  sim/  tb/  test/
```

Copy `templates/.gitignore`, `templates/README.md`, `templates/tb/*`, `templates/test/**`, `templates/docs/*`. Then fill ISA-specific RTL, tests, and docs.

`sim/` is Verilator output only (`obj_dir`). No sources there.

### 2. ISA / stages / ports

Parse the prompt. Defaults if omitted: **5-stage**, no interrupts, no debug.

- RV32 vs RV64 → pkg name, `XLEN`, `-march`/`-mabi` (`ilp32` vs `lp64`)
- Extensions I/M/A/C/Zicsr independently
- Extra ports (`irq`, debug) only if asked

### 3. RTL

Follow [reference-microarch.md](reference-microarch.md): split stages, no TCM, sequential mul/div, ID-stage branch, full hazards, `RESET_VECTOR`, CSR policy, unified map `0x80000000` RAM / `0x10000000` halt / `0x10000008` putchar.

### 4. Tests

`test/Makefile` already globs `$(TEST)*.c` and `$(TEST)/*.c`. Fill:

- `test/hello_world/` (template already uses halt `0x10000000`)
- `test/isa_smoke/` — one smoke covering **all included** extensions
- one folder per included extension (`i_extension/`, `m_extension/`, …)

Patch `test/Makefile` `MARCH`/`MABI` and `crt0.s` (`sd` vs `sw` for bss) for XLEN. `link.ld` stays RAM at `0x80000000`.

Every test must store a code to `0x10000000` then spin. `1` = pass.

### 5. Docs and README

Fill `docs/rtl.md`, `docs/tb.md`, `docs/test.md` for **this** core (ISA, stages, map, how to run). README: layout + `cd test && make` then `cd ../tb && make run ELF=../test/build/hello_world.elf`.

### 6. Build, run, commit

```bash
cd test && make TEST=hello_world
cd ../tb && make run ELF=../test/build/hello_world.elf
```

Fix until hello_world (and isa_smoke if it should pass) complete. Then `git init` if needed and commit.

## Mode B — add extension to an existing core

User names a core path (“add C extension”, “add D to this core”).

1. Find that core (do not create a new `*_cpuN`).
2. Update pkg, decoder, ALU/muldiv/FPU, CSR, `test/Makefile` `-march`.
3. Add `test/<ext>_extension/` (wildcard Makefile needs no edit).
4. Extend `isa_smoke` to cover the new extension.
5. Commit in **that** repo: `skill(riscv-core-rtl): add <ext> extension`.

## Templates vs generate

| Copy from templates | Generate |
| ------------------- | -------- |
| `.gitignore`, `README.md`, `docs/*.md` (fill blanks) | all `rtl/*.sv` |
| `tb/Makefile`, `sim_main.cpp`, `tb_core.sv`, `mem.sv`, `asm2hex.py` | per-extension tests beyond the I skeleton |
| `test/Makefile`, `include/crt0.s`, `include/link.ld`, `hello_world/`, `isa_smoke/`, `i_extension/` | extra extension folders; README/docs bodies |
