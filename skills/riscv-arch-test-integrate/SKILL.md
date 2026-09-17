---
name: riscv-arch-test-integrate
description: >-
  Adds a DUT-side run-<config>.sh (and a short .md) so riscv-arch-test can
  execute ELFs on that core or configuration. Use when the user asks to
  integrate or run riscv-arch-test on a core, add run scripts for CVA6
  configurations (one per config, inside the CVA6 repo), or wrap Ibex/cvw/other
  GitHub RTL. Independent of core generation. Writes the DUT repo; opens no PR
  unless asked.
---

# riscv-arch-test integrate

Independent. Writes the **DUT** repository (CVA6, Ibex, generated Silver core, or any clone). Optionally runs the suite only if the user said **run**.

If `config/cores/<family>/<config>/` is missing, follow `riscv-arch-test-config` first, then continue. That is optional composition, not a requirement that `riscv-core-rtl` ran.

Always write the full name **riscv-arch-test**.

## Conventions

- No clarifying questions.
- Commit in the **DUT** repo: `skill(riscv-arch-test-integrate): add run-<config>.sh`.
- If `run_cmd.txt` in riscv-arch-test must change, make a **separate** small commit there.
- Do not open GitHub PRs unless the user asked. The DUT commit is what a later CVA6 (or other) PR is made from.
- Discover sim from the named DUT. Do not assume a Silver `tb/` layout.

## Integrate vs run

- **Integrate** (default if the user said integrate / add run scripts): harness + `run-*.sh --help` dry run. Stop.
- **Run**: after the harness exists, invoke riscv-arch-test with that `test_config.yaml` (from the riscv-arch-test tree: `make CONFIG_FILES=config/cores/<family>/<config>/test_config.yaml` or that repo’s documented command).

## Steps

1. Resolve DUT path and config name(s) from the prompt. “All CVA6 configurations” = one script **and** one `.md` per config, all inside the CVA6 repo.
2. If the matching riscv-arch-test config dir is missing, follow `riscv-arch-test-config`.
3. Add the thinnest ELF-in harness:

### Silver-style `tb/` (`tb_core.sv` + `tb/Makefile`)

Do **not** create a second testbench. Copy [templates/run-core.sh](templates/run-core.sh) to `tb/run-<name>.sh`. Substitute `CORE_ROOT` discovery and `make -C tb run-elf ELF=...` (or exec `sim/obj_dir/Vtb_core --elf`). Flock-serialize the Verilator build like the template. Wire plusargs only; reuse `tb/` as-is.

Place [templates/sourceme.sh](templates/sourceme.sh) next to the script (`tb/sourceme.sh`).

### CVA6 (first-class)

Inspect the CVA6 repo for how that configuration is simulated (Verilator target, `cv64a6_imafdc_sv39_config`, work-directory, plusargs, tohost). Wrap **that** flow:

- `run-<config>.sh` in the CVA6 tree (root or a small `riscv-arch-test/` / `tb/` dir the repo already uses)
- `<config>.md` documenting how to run one ELF and how riscv-arch-test finds the script

Repeat for every named config. Do not invent a Silver `tb_core.sv` inside CVA6.

### Any other GitHub RTL

Inspect sim (Verilator/VCS, linker map, halt). Create `run-<name>.sh` + `<name>.md`. Add extra TB files **only if** there is no usable ELF-in / halt-out path.

4. Make `run-*.sh` findable:
   - `chmod +x`
   - Idempotent `PATH` block in `~/.bashrc` (comment marker `sle-skills riscv-arch-test-integrate <config>`)
   - **and** `sourceme.sh` next to the script (bashrc is machine-local and cannot be the only mechanism)
5. `run_cmd.txt` first token must match the script’s **basename** (PATH lookup). Patch riscv-arch-test only if the name differs.
6. Commit in the DUT. If the user asked to run, execute riscv-arch-test next.
