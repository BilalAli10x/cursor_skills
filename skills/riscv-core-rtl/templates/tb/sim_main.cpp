// SPDX-License-Identifier: Apache-2.0
// Minimal Verilator driver: optional ELF DPI load, then clk/rst until $finish.
// Hex images are loaded in mem.sv via +INIT_FILE=. --elf is the riscv-arch-test path.

#include "Vtb_core.h"
#include "Vtb_core__Dpi.h"
#include "svdpi.h"
#include "verilated.h"

#if VM_TRACE
#include "verilated_fst_c.h"
#endif

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

namespace {

constexpr uint64_t kRamBase = 0x80000000ULL;
constexpr uint64_t kRamSize = 32ULL * 1024ULL * 1024ULL;

struct Args {
    const char *elf = nullptr;
    const char *trace = nullptr;
};

Args parse_args(int argc, char **argv) {
    Args a;
    for (int i = 1; i < argc; i++) {
        if (std::strcmp(argv[i], "--elf") == 0) {
            if (i + 1 < argc && argv[i + 1][0] != '\0')
                a.elf = argv[++i];
        } else if (std::strncmp(argv[i], "--elf=", 6) == 0) {
            a.elf = argv[i] + 6;
        } else if (std::strcmp(argv[i], "--trace") == 0) {
            if (i + 1 < argc)
                a.trace = argv[++i];
        } else if (std::strncmp(argv[i], "--trace=", 8) == 0) {
            a.trace = argv[i] + 8;
        } else if (argv[i][0] != '-' && argv[i][0] != '+') {
            a.elf = argv[i];
        }
    }
    return a;
}

bool load_elf(const char *path) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        std::fprintf(stderr, "error: cannot open ELF '%s'\n", path);
        return false;
    }
    std::vector<uint8_t> data((std::istreambuf_iterator<char>(in)),
                              std::istreambuf_iterator<char>());
    if (data.size() < 52 || std::memcmp(data.data(), "\x7f""ELF", 4) != 0) {
        std::fprintf(stderr, "error: '%s' is not an ELF file\n", path);
        return false;
    }
    if (data[5] != 1) {
        std::fprintf(stderr, "error: only little-endian ELF is supported\n");
        return false;
    }

    auto u16 = [&](size_t off) {
        return static_cast<uint16_t>(data[off] | (data[off + 1] << 8));
    };
    auto u32 = [&](size_t off) {
        return static_cast<uint32_t>(data[off] | (data[off + 1] << 8) |
                                     (data[off + 2] << 16) | (data[off + 3] << 24));
    };
    auto u64 = [&](size_t off) {
        uint64_t v = 0;
        for (int i = 0; i < 8; i++)
            v |= static_cast<uint64_t>(data[off + i]) << (8 * i);
        return v;
    };

    const uint8_t ei_class = data[4];
    uint64_t e_phoff = 0;
    uint16_t e_phentsize = 0;
    uint16_t e_phnum = 0;
    const bool elf64 = (ei_class == 2);
    if (elf64) {
        e_phoff = u64(32);
        e_phentsize = u16(54);
        e_phnum = u16(56);
    } else if (ei_class == 1) {
        e_phoff = u32(28);
        e_phentsize = u16(42);
        e_phnum = u16(44);
    } else {
        std::fprintf(stderr, "error: only ELF32/ELF64 are supported\n");
        return false;
    }

    bool loaded = false;
    for (uint16_t i = 0; i < e_phnum; i++) {
        const size_t off = static_cast<size_t>(e_phoff + static_cast<uint64_t>(i) * e_phentsize);
        uint32_t p_type = 0;
        uint64_t p_offset = 0, p_vaddr = 0, p_filesz = 0, p_memsz = 0;
        if (elf64) {
            if (off + 56 > data.size())
                return false;
            p_type = u32(off);
            p_offset = u64(off + 8);
            p_vaddr = u64(off + 16);
            p_filesz = u64(off + 32);
            p_memsz = u64(off + 40);
        } else {
            if (off + 32 > data.size())
                return false;
            p_type = u32(off);
            p_offset = u32(off + 4);
            p_vaddr = u32(off + 8);
            p_filesz = u32(off + 16);
            p_memsz = u32(off + 20);
        }
        if (p_type != 1 || p_memsz == 0)
            continue;
        if (p_vaddr < kRamBase || (p_vaddr + p_memsz) > (kRamBase + kRamSize)) {
            std::fprintf(stderr, "error: ELF segment outside RAM\n");
            return false;
        }
        for (uint64_t b = 0; b < p_memsz; b++) {
            uint8_t byte = 0;
            if (b < p_filesz && (p_offset + b) < data.size())
                byte = data[static_cast<size_t>(p_offset + b)];
            dpi_ram_poke(p_vaddr - kRamBase + b, byte);
        }
        loaded = true;
    }
    if (!loaded) {
        std::fprintf(stderr, "error: no loadable ELF segments\n");
        return false;
    }
    return true;
}

}  // namespace

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    const Args args = parse_args(argc, argv);

    Vtb_core *top = new Vtb_core;

    if (args.elf != nullptr) {
        const svScope mem_scope = svGetScopeFromName("TOP.tb_core.u_mem");
        if (mem_scope == nullptr) {
            std::fprintf(stderr, "error: DPI scope TOP.tb_core.u_mem not found\n");
            delete top;
            return 2;
        }
        svSetScope(mem_scope);
        if (!load_elf(args.elf)) {
            delete top;
            return 2;
        }
    }

    uint64_t main_time = 0;
#if VM_TRACE
    VerilatedFstC *tfp = nullptr;
    if (args.trace != nullptr) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedFstC;
        top->trace(tfp, 99);
        tfp->open(args.trace);
    }
#endif

    auto tick = [&]() {
        top->clk = 0;
        top->eval();
#if VM_TRACE
        if (tfp) tfp->dump(main_time);
#endif
        main_time += 5;
        top->clk = 1;
        top->eval();
#if VM_TRACE
        if (tfp) tfp->dump(main_time);
#endif
        main_time += 5;
    };

    top->clk = 0;
    top->rst_n = 0;
    top->eval();

    const int reset_cycles = 8;
    for (int i = 0; i < reset_cycles; i++)
        tick();

    top->rst_n = 1;

    while (!Verilated::gotFinish())
        tick();

    int code = 0;
    const svScope tb_scope = svGetScopeFromName("TOP.tb_core");
    if (tb_scope != nullptr) {
        svSetScope(tb_scope);
        code = dpi_exit_code();
    }
#if VM_TRACE
    if (tfp) {
        tfp->close();
        delete tfp;
    }
#endif
    top->final();
    delete top;
    return code;
}
