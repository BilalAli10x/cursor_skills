---
name: verilator-setup
description: >-
  Installs Verilator v5.036 from source into <workspace>/tools/verilator using a
  pinned, standalone script. Use when Verilator is missing or older than 5.021,
  when the user asks to install Verilator, or when another skill (core RTL,
  CVA6, Ibex, riscv-arch-test, any cloned GitHub RTL) needs a usable Verilator
  binary. Independent of core generation.
---

# Verilator Setup

Independent workspace tool. Does not create a core. Works in any workspace (CVA6, Ibex, generated Silver core, other clones).

## Conventions

- No clarifying questions. Note decisions as comments.
- Do not invent install steps. Run `scripts/install-verilator.sh` in this skill directory.
- Commit only under `<workspace>/tools/` with message `skill(verilator-setup): ...`.
- Identify workspace root as the Cursor folder that contains (or will contain) cores and `tools/`.

## Steps

1. Resolve workspace root (`WORKSPACE`). Prefer the Cursor workspace folder (parent of cores), not a core subdirectory.
2. If `verilator` is on `PATH` **or** `$WORKSPACE/tools/verilator/bin/verilator` exists:
   - Run `verilator --version`.
   - If the version is **≥ 5.021**, stop. Do not rebuild. Say which binary you found.
3. Otherwise run this skill’s installer (absolute path to the clone of sle-skills / `.cursor`):

```bash
WORKSPACE="<workspace-root>" bash "<this-skill>/scripts/install-verilator.sh"
```

4. Prepending `PATH` is done by the script (idempotent `~/.bashrc` block plus a `tools/env.sh` block). Do not overwrite RISC-V GCC env entries.
5. Git:
   - `mkdir -p "$WORKSPACE/tools"`
   - If `tools/` is not a git repo, `git init` there.
   - Ensure `tools/.gitignore` ignores the Verilator source/build/prefix trees.
   - Commit the stamp files (`verilator.version`, `README.md`, `.gitignore`, `env.sh`) only — **not** the installed binaries or cloned source.

## What the script pins

- Version: **v5.036**
- Prefix: `$WORKSPACE/tools/verilator`
- Source clone (build-time only): `$WORKSPACE/tools/src/verilator`

## After install

Confirm:

```bash
"$WORKSPACE/tools/verilator/bin/verilator" --version
```
