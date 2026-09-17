# Testbench

`tb/` instantiates the core and a 32 MiB RAM at `0x80000000`. Halt `0x10000000`
(pass=1) and putchar `0x10000008` are ordinary stores; the core has no
special-case. `make run ELF=../test/build/hello_world.elf` converts to hex
(`+INIT_FILE=`). `make run-elf ELF=...` loads via DPI for riscv-arch-test.
