# Build ${TEST}*.c + include/crt0.s into build/${TEST}.elf/.hex.
# Override: make TEST=foo  (also finds foo/*.c — new folders need zero Makefile edits)
# The generating skill must set MARCH/MABI for the requested ISA.

TEST      ?= hello_world
CROSS     ?= riscv64-unknown-elf-
CC        := $(CROSS)gcc
OBJDUMP   := $(CROSS)objdump

BUILD     := build
INCDIR    := include
LDSCRIPT  := $(INCDIR)/link.ld

# Engineering decision: placeholders; riscv-core-rtl replaces MARCH/MABI per ISA.
MARCH     ?= rv64imac_zicsr
MABI      ?= lp64

CFLAGS    := -march=$(MARCH) -mabi=$(MABI) -ffreestanding -nostdlib \
             -nostartfiles -fno-builtin -O2 -mno-relax \
             -std=c99 -Wall -Wextra -I$(INCDIR) -I$(TEST)

C_SRCS    := $(wildcard ${TEST}*.c) $(wildcard ${TEST}/*.c)
C_OBJS    := $(patsubst %.c,$(BUILD)/%.o,$(notdir $(C_SRCS)))
AS_OBJ    := $(BUILD)/crt0.o
ELF       := $(BUILD)/${TEST}.elf
HEX       := $(BUILD)/${TEST}.hex
VPATH     := $(TEST):.

.PHONY: all clean dump
all: $(HEX)

$(BUILD):
	mkdir -p $(BUILD)

$(AS_OBJ): $(INCDIR)/crt0.s | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(ELF): $(AS_OBJ) $(C_OBJS) $(LDSCRIPT)
	$(CC) $(CFLAGS) -T $(LDSCRIPT) -o $@ $(AS_OBJ) $(C_OBJS) -Wl,-Map=$(BUILD)/${TEST}.map

$(HEX): $(ELF)
	python3 ../tb/asm2hex.py --ram-base 0x80000000 $< $@

dump: $(ELF)
	$(OBJDUMP) -d -M no-aliases $< > $(BUILD)/${TEST}.objdump

clean:
	rm -rf $(BUILD)
