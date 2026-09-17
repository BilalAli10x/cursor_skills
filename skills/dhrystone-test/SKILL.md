---
name: dhrystone-test
description: >-
  Adds the already-fixed C99 Dhrystone 2.1 port to a named RISC-V core (Silver
  generated core, CVA6, Ibex, or any cloned GitHub RTL) after inspecting that
  core's testbench halt/putchar/UART/tohost mechanism. Use when the user asks
  to add a Dhrystone test. Do not re-download Weicker C89 sources.
---

# Add Dhrystone Test

Independent. Target is whatever core path the user named. Do not assume `riscv-core-rtl` produced it.

## Conventions

- No clarifying questions.
- Commit in the **DUT repo** only: `skill(dhrystone-test): add C99 Dhrystone`.
- Do not invent printf/UART. Wire to the DUT’s existing output.

## Steps

1. Locate the DUT (folder name, `cwd`, or path in the prompt).
2. **Inspect** the DUT testbench and existing tests for the completion and character-output mechanism. Grep for addresses and symbols such as `0x10000000`, `0x10000008`, `0x80000000`, `0x80000008`, `tohost`, `putchar`, `UART`. Use **that** mechanism. Do not hardcode Silver-core mailboxes.
3. Copy [templates/](templates/) (`dhrystone.c`, `dhrystone.h`, `dhrystone_main.c`, `dhrystone_sys.c`) into the DUT’s software/test tree:
   - Silver-style: `test/dhrystone/`
   - Otherwise: that repo’s equivalent test or `sw/` directory
4. Patch only the glue:
   - `dhrystone_sys.c` — `PUTCHAR` (template ships with `0x80000008` from the original port)
   - `dhrystone_main.c` — final store (template ships with `0x80000000`)
   - Timing: keep `csrr mcycle` if the DUT has Zicsr; otherwise use the DUT’s cycle counter
5. Do **not** re-download Dhrystone from the web. The templates are already C99 with a freestanding `printf`.
6. If the DUT uses a wildcard Makefile (`TEST ?= ...`), `make TEST=dhrystone` should work with zero Makefile edits. Otherwise add the minimum recipe that repo already uses for C tests.
7. Build. Fix compile errors locally; do not revert to C89 sources.
8. Commit in the DUT repo.

## Template note

The copied C files still mention `0x80000000` / `0x80000008`. That is the historical port, **not** a default to keep. Always rewrite those two sites after step 2. Silver-style generated cores use halt `0x10000000` and putchar `0x10000008`.
