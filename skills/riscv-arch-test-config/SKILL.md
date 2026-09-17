---
name: riscv-arch-test-config
description: >-
  Clones riscv-arch-test if needed and adds config/cores/<family>/<config>/
  with the six-file layout (yaml, link.ld, run_cmd.txt, rvmodel_macros.h,
  sail.json, test_config.yaml). Use when the user asks to set up or configure
  riscv-arch-test for a core, add a CVA6 configuration, add all CVA6
  configurations, or add Ibex/cvw/other DUT configs. Writes only the
  riscv-arch-test repo. Does not run the suite. Independent of core generation.
---

# riscv-arch-test config

Independent. Writes **only** the `riscv-arch-test` repository. Does not modify the DUT. Does not run tests. Does not require `riscv-core-rtl`.

Primary future use: add **every CVA6 configuration** under `config/cores/cva6/<config>/`, then the user can open a PR to riscv-arch-test. Same skill for Ibex, cvw, or a generated Silver core.

Always write the full name **riscv-arch-test**.

## Conventions

- No clarifying questions.
- Commit in **riscv-arch-test**: `skill(riscv-arch-test-config): add <family>/<config>`.
- Do not open a PR unless the user asked.
- Discover the DUT from the prompt (path, config name like `cv64a6_imafdc_sv39_config`). Inspect **that** core’s ISA and memory map. Do not invent config names — read them from the DUT repo.

## Steps

1. Workspace root = Cursor folder that contains (or will contain) cores and `riscv-arch-test/`.
2. If `<workspace>/riscv-arch-test/` is missing:

```bash
git clone https://github.com/riscv-non-isa/riscv-arch-test.git
```

   (If this workspace already uses a fork, clone that remote instead.)

3. Identify family + config:
   - Silver generated core: `config/cores/<core-name>/<core-name>-rv{32,64}<isa>/`
   - CVA6: `config/cores/cva6/<cva6-config-name>/` — one directory **per** CVA6 config the user named. “All configurations” = enumerate configs from the CVA6 repo (do not guess). Existing `config/cores/cva6/cv32a65x/` is a structural hint only.
   - Other families: follow `config/cores/{cve2,cve4,cvw}` naming.

4. Copy structure from [templates/cpu1b-rv64imac/](templates/cpu1b-rv64imac/) (the six known-good files). Then **fill from the DUT**, using [reference-yaml-knobs.md](reference-yaml-knobs.md). Also cross-check `config/cores/{cva6,cve2,cve4,cvw}` for halt style (MMIO vs `tohost`) and `run_cmd.txt` patterns.

   Required files:

   | File | Fill from |
   | ---- | --------- |
   | `<name>.yaml` | DUT XLEN + `implemented_extensions`. Start from cpu1b yaml shape; drop M/A/C if absent. |
   | `link.ld` | DUT memory map. cpu1b default `RAM_ORIGIN=0x80000000` / `RAM_LENGTH=0x02000000` **only if** that DUT’s TB uses it. |
   | `run_cmd.txt` | `run-<config-name>.sh {debug:--trace __TRACEFILE__.fst} --elf` or that family’s existing pattern (`run-cve4.sh --cfg …`). The **script file** is created by `riscv-arch-test-integrate`, not this skill. |
   | `rvmodel_macros.h` | Halt/putchar **as the DUT already implements**. cpu1b reference: halt `0x10000000` (pass=1, fail=3), putchar `0x10000008`. CVA6 often uses `tohost` + UART — copy `config/cores/cva6/` macros. |
   | `sail.json` | `base.xlen` and `memory.regions` must match `link.ld`. Start from the template; disable unused extensions. |
   | `test_config.yaml` | `name`, `udb_config`, compiler/objdump/sail. `include_priv_tests: False` unless the DUT has traps. |

5. Do not run `make CONFIG_FILES=...`. Do not edit the DUT.
6. Commit in `riscv-arch-test`.
