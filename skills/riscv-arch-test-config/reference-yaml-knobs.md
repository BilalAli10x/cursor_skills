# Which knobs change per DUT

Start from [templates/cpu1b-rv64imac/](templates/cpu1b-rv64imac/). Change only what the DUT requires.

## `<name>.yaml`

- `name` / `description` — config id
- `implemented_extensions` — exact DUT ISA. Implies: M → keep M+Zmmul; A → A+Zaamo+Zalrsc; C → C+Zca; always I; Zicsr if the DUT has CSRs; `Sm` if machine-mode CSRs exist
- `params.MXLEN` — 32 or 64
- Trap-related `TRAP_ON_*` — match DUT (cpu1b leaves ecall/ebreak/unimplemented as non-trapping)
- `PHYS_ADDR_WIDTH`, `NUM_PMP_ENTRIES`, `MISALIGNED_LDST` — from DUT

## `link.ld`

Must match the DUT sim memory. cpu1b: RAM `0x80000000` / 32 MiB. CVA6: inspect that config’s linker / boot address. `TEST_BASE` stays inside RAM.

## `sail.json`

- `base.xlen`
- `extensions` booleans (M/A/C/F/D/V) aligned with yaml
- `memory.regions` — same origin/size as `link.ld` RAM; keep an MMIO region that covers halt/UART if those addresses are outside RAM

## `rvmodel_macros.h`

Pick **one** halt style and stick to it:

- MMIO store (cpu1b): `sw` to `0x10000000`
- `tohost` symbol (cva6/cvw): `la t0, tohost; sw`
- Other cores (cve2/cve4): often `0x20000000` with a magic pass code — copy that family

Putchar: MMIO `sb`/`sw` to the DUT UART or mailbox. Empty interrupt macros unless the DUT implements them.

## `run_cmd.txt`

First token is the **PATH name** of the runner that `riscv-arch-test-integrate` will add:

```
run-<config-name>.sh {debug:--trace __TRACEFILE__.fst} --elf
```

CVA6 may pass extra `--cfg` arguments if that sim requires them. cve4 example: `run-cve4.sh --cfg rv32imc --elf`.

## `test_config.yaml`

`compiler_exe` / `objdump_exe`: `riscv64-unknown-elf-gcc` is typical even for RV32 (with `-march`). `ref_model_exe: sail_riscv_sim`. `udb_config` and `name` match the directory.
