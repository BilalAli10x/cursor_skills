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

## Toolchain hole

RISC-V GCC is not a skill. If `riscv64-unknown-elf-gcc` or `riscv32-unknown-elf-gcc` is required and missing, stop with a short install hint rather than building a toolchain from source.
