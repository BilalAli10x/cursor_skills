---
name: riscv-gcc-setup
description: >-
  Installs a pinned official riscv64-unknown-elf-gcc (newlib ELF, not a
  from-source GCC build) into <workspace>/tools/riscv using a standalone
  script. Use when the RISC-V GNU toolchain is missing, when the user asks
  to install riscv64-unknown-elf-gcc / riscv32-unknown-elf-gcc, or when
  another skill (core RTL, Dhrystone, riscv-arch-test, CVA6, Ibex) needs a
  cross compiler. Independent of core generation. Do not compile GCC.
---

# RISC-V GCC Setup

Independent workspace tool. Does not create a core. Works in any workspace (CVA6, Ibex, generated Silver core, other clones).

## Conventions

- No clarifying questions. Note decisions as comments.
- Do not invent install steps. Do **not** compile GCC from source.
- Run `scripts/install-riscv-gcc.sh` in this skill directory.
- Commit only under `<workspace>/tools/` with message `skill(riscv-gcc-setup): ...`.
- Identify workspace root as the Cursor folder that contains (or will contain) cores and `tools/`.

## Steps

1. Resolve workspace root (`WORKSPACE`). Prefer the Cursor workspace folder (parent of cores), not a core subdirectory.
2. If `riscv64-unknown-elf-gcc` or `riscv32-unknown-elf-gcc` is on `PATH` **or** `$WORKSPACE/tools/riscv/bin/riscv64-unknown-elf-gcc` exists:
   - Run `<triple>-gcc --version`.
   - Stop. Do not re-download. Say which binary you found.
3. Otherwise run this skill’s installer (absolute path to the clone of sle-skills / `.cursor`):

```bash
WORKSPACE="<workspace-root>" bash "<this-skill>/scripts/install-riscv-gcc.sh"
```

4. Prepending `PATH` is done by the script (idempotent `~/.bashrc` block plus a `tools/env.sh` block). Do not overwrite Verilator’s env entries.
5. Git:
   - `mkdir -p "$WORKSPACE/tools"`
   - If `tools/` is not a git repo, `git init` there.
   - Ensure `tools/.gitignore` ignores the installed prefix (`riscv/`) and `src/`.
   - Commit the stamp files (`riscv-gcc.version`, `README.md`, `.gitignore`, `env.sh`) only — **not** the tarball or unpacked toolchain.

## What the script pins

- Source: **riscv-collab/riscv-gnu-toolchain** nightly **2026.08.27**
- Artifact: `riscv64-elf-ubuntu-24.04-gcc.tar.xz` (Ubuntu 22.04 host → the 22.04 tarball)
- Prefix: `$WORKSPACE/tools/riscv`
- Binary: `$WORKSPACE/tools/riscv/bin/riscv64-unknown-elf-gcc` (use this same binary for RV32 via `-march` / `-mabi`)

## After install

Confirm:

```bash
"$WORKSPACE/tools/riscv/bin/riscv64-unknown-elf-gcc" --version
```
