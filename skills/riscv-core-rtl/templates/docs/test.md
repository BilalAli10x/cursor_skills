# Tests

Freestanding C under `test/<name>/`. `make TEST=<name>` globs `${TEST}*.c` and
`${TEST}/*.c` plus `include/crt0.s`. Image links at `0x80000000`. Every test
stores a code to `0x10000000` then spins (`1` = pass).
