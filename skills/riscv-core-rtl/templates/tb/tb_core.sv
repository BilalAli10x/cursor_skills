// SPDX-License-Identifier: Apache-2.0
// Unified TB: core + TB RAM. Halt/putchar are ordinary stores; the core has no
// special-case. Map matches riscv-arch-test cpu1b: RAM 0x80000000, halt
// 0x10000000, putchar 0x10000008.
// `ifdef VERILATOR keeps a hook for other simulators later.

`ifdef VERILATOR
`endif

module tb_core (
    input logic clk,
    input logic rst_n
);

    localparam logic [63:0] RAM_BASE     = 64'h8000_0000;
    localparam logic [63:0] HALT_ADDR    = 64'h1000_0000;
    localparam logic [63:0] PUTCHAR_ADDR = 64'h1000_0008;
    localparam longint unsigned TIMEOUT  = 100_000_000;

    string init_file;
    initial begin
        if (!$value$plusargs("INIT_FILE=%s", init_file))
            init_file = "(elf or unknown)";
        $display("\n========================================");
        $display("  TEST START : %s", init_file);
        $display("========================================\n");
    end

    logic [63:0] ext_imem_addr;
    logic        ext_imem_valid, ext_imem_ready;
    logic [31:0] ext_imem_rdata;

    logic [63:0] ext_dmem_addr, ext_dmem_wdata, ext_dmem_rdata;
    logic [7:0]  ext_dmem_wstrb;
    logic        ext_dmem_we, ext_dmem_valid, ext_dmem_ready;

    int          exit_code = 1;
    localparam int EXIT_PASS    = 0;
    localparam int EXIT_FAIL    = 1;
    localparam int EXIT_TIMEOUT = 2;
    longint unsigned cycles = 0;

    export "DPI-C" function dpi_exit_code;
    function int dpi_exit_code();
        return exit_code;
    endfunction

    // dpi_ram_poke is exported from mem; C++ binds to TOP.tb_core.u_mem
    mem #(
        .RAM_BASE (RAM_BASE)
    ) u_mem (
        .clk           (clk),
        .rst_n         (rst_n),
        .i_imem_addr   (ext_imem_addr),
        .i_imem_valid  (ext_imem_valid),
        .o_imem_ready  (ext_imem_ready),
        .o_imem_rdata  (ext_imem_rdata),
        .i_dmem_addr   (ext_dmem_addr),
        .i_dmem_wdata  (ext_dmem_wdata),
        .i_dmem_wstrb  (ext_dmem_wstrb),
        .i_dmem_we     (ext_dmem_we),
        .i_dmem_valid  (ext_dmem_valid),
        .o_dmem_ready  (ext_dmem_ready),
        .o_dmem_rdata  (ext_dmem_rdata)
    );

    core #(
        .RESET_VECTOR (RAM_BASE)
    ) u_core (
        .clk              (clk),
        .rst_n            (rst_n),
        .o_ext_imem_addr  (ext_imem_addr),
        .o_ext_imem_valid (ext_imem_valid),
        .i_ext_imem_ready (ext_imem_ready),
        .i_ext_imem_rdata (ext_imem_rdata),
        .o_ext_dmem_addr  (ext_dmem_addr),
        .o_ext_dmem_wdata (ext_dmem_wdata),
        .o_ext_dmem_wstrb (ext_dmem_wstrb),
        .o_ext_dmem_we    (ext_dmem_we),
        .o_ext_dmem_valid (ext_dmem_valid),
        .i_ext_dmem_ready (ext_dmem_ready),
        .i_ext_dmem_rdata (ext_dmem_rdata)
    );

    always_ff @(posedge clk) begin
        cycles <= cycles + 64'd1;
    end

    always_ff @(posedge clk) begin
        if (rst_n && ext_dmem_valid && ext_dmem_we && ext_dmem_ready) begin
            if (ext_dmem_addr == PUTCHAR_ADDR) begin
                for (int i = 0; i < 8; i++) begin
                    if (ext_dmem_wstrb[i])
                        $write("%c", ext_dmem_wdata[8*i +: 8]);
                end
            end else if (ext_dmem_addr == HALT_ADDR) begin
                if (ext_dmem_wdata[31:0] == 32'd1)
                    exit_code = EXIT_PASS;
                else
                    exit_code = EXIT_FAIL;
                $display("\n========================================");
                $display("  TEST END  : %s", init_file);
                $display("  RESULT    : COMPLETE value=0x%016x", ext_dmem_wdata);
                $display("  CYCLES    : %0d", cycles);
                $display("========================================\n");
                $finish;
            end
        end
        if (cycles >= TIMEOUT) begin
            $display("\n========================================");
            $display("  TEST END  : %s", init_file);
            $display("  RESULT    : TIMEOUT after %0d cycles", cycles);
            $display("========================================\n");
            exit_code = EXIT_TIMEOUT;
            $finish;
        end
    end

endmodule
