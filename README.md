# SilverLining EDA Skills (`sle-skills`)

Cursor skills that automate RISC-V core design, simulation setup, Dhrystone, and **riscv-arch-test** bring-up. Each skill is **independent**: it works on whatever target you name (a generated Silver core, CVA6, Ibex, cvw, or any cloned GitHub RTL). Skills do not assume another skill already ran.

## One-time manual setup

1. Create a workspace folder (example name: `silver_work`).
2. Open Cursor in that folder.
3. Clone this repo as `.cursor` so the skills load:

```bash
git clone https://github.com/SilverLining-EDA/sle-skills .cursor
```

Cursor reads `.cursor/skills/*/SKILL.md`. From here, invoke skills with natural language.

## Skills

| Skill | When to use |
| ----- | ----------- |
| [verilator-setup](skills/verilator-setup/SKILL.md) | Verilator is missing or too old. Any workspace (CVA6, Ibex, generated core). |
| [riscv-gcc-setup](skills/riscv-gcc-setup/SKILL.md) | `riscv64-unknown-elf-gcc` is missing. Pinned official prebuilt — do not compile GCC. |
| [riscv-core-rtl](skills/riscv-core-rtl/SKILL.md) | Design or extend a Silver-style RISC-V core (stage count + ISA). |
| [dhrystone-test](skills/dhrystone-test/SKILL.md) | Add Dhrystone to a named core after inspecting that core’s output mechanism. |
| [riscv-arch-test-config](skills/riscv-arch-test-config/SKILL.md) | Add `config/cores/<family>/<config>/` to the **riscv-arch-test** repo (including all CVA6 configurations). |
| [riscv-arch-test-integrate](skills/riscv-arch-test-integrate/SKILL.md) | Add `run-<config>.sh` (+ `.md`) **inside the DUT repo** (including one script per CVA6 config). |

Always write the full name **riscv-arch-test**. Do not abbreviate it.

Shared rules: [shared/conventions.md](shared/conventions.md).

## Optional composition

Skills may call each other only when something is missing:

- `riscv-core-rtl` follows `verilator-setup` if Verilator is not on PATH.
- `riscv-core-rtl` follows `riscv-gcc-setup` if `riscv64-unknown-elf-gcc` is not on PATH.
- `riscv-arch-test-integrate` follows `riscv-arch-test-config` if the config directory does not exist yet.

“Design RV64IMA” does not require riscv-arch-test. “Integrate riscv-arch-test to cva6 configuration cv64a6_imafdc_sv39_config” does not require `riscv-core-rtl`.

## Two-repo commits (not PRs)

`riscv-arch-test-config` commits in **riscv-arch-test**. `riscv-arch-test-integrate` commits in the **DUT** (e.g. CVA6). Opening GitHub PRs is a separate user request.

## Future skills (not in this repo yet)

Formal verification of `<path>`, GDSII/LibreLane of `<path>`, and debug of riscv-arch-test failures. Those will also take any RTL path, not only generated cores.
