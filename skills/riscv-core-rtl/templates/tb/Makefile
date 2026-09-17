# Verilator build + run. ELF path is an argument; converted to hex and
# passed as +INIT_FILE=. Also accepts a prebuilt HEX=.
# Example: make run ELF=../test/build/hello_world.elf
#
# Engineering decision: HEX path stays for quick reruns; ELF is the documented interface.

VERILATOR ?= verilator
ELF       ?= ../test/build/hello_world.elf
HEX       ?= ../test/build/hello_world.hex
SIM_DIR   := ../sim
OBJ_DIR   := $(SIM_DIR)/obj_dir
RTL_DIR   := ../rtl

# Package must be compiled first so importers see rv*_pkg.
RTL_SRCS  := $(abspath $(wildcard $(RTL_DIR)/*_pkg.sv)) \
             $(filter-out $(abspath $(wildcard $(RTL_DIR)/*_pkg.sv)),$(abspath $(wildcard $(RTL_DIR)/*.sv)))
TB_SRCS   := $(abspath mem.sv) $(abspath tb_core.sv) $(abspath sim_main.cpp)

VERILATOR_FLAGS := --cc --exe --build -sv \
                   --top-module tb_core \
                   --trace-fst --trace-structs \
                   -Mdir $(OBJ_DIR) \
                   -I$(RTL_DIR) \
                   -Wall -Wno-fatal -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -Wno-BLKANDNBLK \
                   -CFLAGS "-std=c++17"

.PHONY: all sim run run-elf clean

all: sim

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

sim: $(OBJ_DIR) $(RTL_SRCS) $(TB_SRCS)
	$(VERILATOR) $(VERILATOR_FLAGS) $(RTL_SRCS) $(TB_SRCS) -o Vtb_core

# Smoke-test path: ELF → hex → +INIT_FILE (relative to RAM_BASE).
run: sim
	@if [ -f "$(ELF)" ]; then python3 $(abspath asm2hex.py) --ram-base 0x80000000 $(ELF) $(HEX); fi
	$(OBJ_DIR)/Vtb_core +INIT_FILE=$(HEX)

# riscv-arch-test path: load ELF via DPI (--elf). run-*.sh uses this.
run-elf: sim
	$(OBJ_DIR)/Vtb_core --elf $(ELF)

clean:
	rm -rf $(OBJ_DIR)
