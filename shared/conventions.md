# Shared skill conventions

Apply these on every skill run. Each SKILL.md also inlines the short form.

## Behavior

- Do not ask clarifying questions. Make a reasonable engineering decision and leave a one-line `// Engineering decision:` comment in generated code (or `#` / `/* */` as appropriate).
- Do not improvise tool installs. If a setup skill exists for that tool, read and follow it.
- Identify the target from the user prompt (folder name, git remote, configuration string). Work on **that** tree.
- Never assume the DUT was produced by `riscv-core-rtl`.
- Never overwrite `silver_cpu1b` or any existing core unless the user named that path as the target.
- Always write the full name **riscv-arch-test**. Do not abbreviate to "arch-test".

## Git

- End the skill with a commit **only in the repo that skill touched**.
- Message form: `skill(<skill-name>): <one line why>`.
- If the target folder is not a git repo (`tools/`, a newly generated core), `git init` first, then commit.
- Do not `git push` and do not open a PR unless the user asked.
- Do not skip hooks. Do not amend unless the user asked.

## Toolchain

If a setup skill exists for a missing tool, follow it. Do not improvise installs.

- Verilator missing or older than 5.021 → `verilator-setup`
- `riscv64-unknown-elf-gcc` / `riscv32-unknown-elf-gcc` missing → `riscv-gcc-setup`. Do not compile GCC from source.
