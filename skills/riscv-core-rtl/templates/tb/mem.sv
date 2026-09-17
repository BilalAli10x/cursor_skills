// SPDX-License-Identifier: Apache-2.0
// Single-cycle TB RAM. 32 MiB at RAM_BASE, stored as 32-bit words so $readmemh
// matches asm2hex.py. ELF load uses dpi_ram_poke (byte offset from RAM_BASE).
// Engineering decision: RAM lives in the TB, not the core (no TCM).

module mem #(
    parameter logic [63:0] RAM_BASE = 64'h8000_0000,
    parameter int unsigned RAM_SIZE = 32 * 1024 * 1024
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [63:0] i_imem_addr,
    input  logic        i_imem_valid,
    output logic        o_imem_ready,
    output logic [31:0] o_imem_rdata,

    input  logic [63:0] i_dmem_addr,
    input  logic [63:0] i_dmem_wdata,
    input  logic [7:0]  i_dmem_wstrb,
    input  logic        i_dmem_we,
    input  logic        i_dmem_valid,
    output logic        o_dmem_ready,
    output logic [63:0] o_dmem_rdata
);

    localparam int unsigned NWORDS = RAM_SIZE / 4;

    // verilator tracing_off
    logic [31:0] ram [0:NWORDS-1];
    // verilator tracing_on

    string init_file;
    initial begin
        if ($value$plusargs("INIT_FILE=%s", init_file) && init_file != "")
            $readmemh(init_file, ram);
    end

    function automatic bit ram_hit(input logic [63:0] addr, input int unsigned nbytes);
        return (addr >= RAM_BASE) && ((addr + nbytes) <= (RAM_BASE + RAM_SIZE));
    endfunction

    function automatic int unsigned word_off(input logic [63:0] addr);
        return (addr[31:0] - RAM_BASE[31:0]) >> 2;
    endfunction

    export "DPI-C" function dpi_ram_poke;
    function void dpi_ram_poke(input longint unsigned off, input byte unsigned data);
        int unsigned woff;
        int unsigned sh;
        if (off >= RAM_SIZE)
            return;
        woff = off[24:0] >> 2;
        sh = {off[1:0], 3'b000};
        ram[woff] = (ram[woff] & ~(32'hFF << sh)) | ({24'b0, data} << sh);
    endfunction

    assign o_imem_ready = 1'b1;
    assign o_imem_rdata = ram_hit(i_imem_addr, 4) ? ram[word_off(i_imem_addr)] : 32'h0000_0013;

    assign o_dmem_ready = 1'b1;
    assign o_dmem_rdata = ram_hit({i_dmem_addr[63:3], 3'b000}, 8)
                        ? {ram[word_off({i_dmem_addr[63:3], 3'b100})],
                           ram[word_off({i_dmem_addr[63:3], 3'b000})]}
                        : 64'b0;

    always_ff @(posedge clk) begin
        if (rst_n && i_dmem_valid && i_dmem_we && o_dmem_ready &&
            ram_hit({i_dmem_addr[63:3], 3'b000}, 8)) begin
            int unsigned w0, w1;
            w0 = word_off({i_dmem_addr[63:3], 3'b000});
            w1 = word_off({i_dmem_addr[63:3], 3'b100});
            if (i_dmem_wstrb[0]) ram[w0][ 7: 0] <= i_dmem_wdata[ 7: 0];
            if (i_dmem_wstrb[1]) ram[w0][15: 8] <= i_dmem_wdata[15: 8];
            if (i_dmem_wstrb[2]) ram[w0][23:16] <= i_dmem_wdata[23:16];
            if (i_dmem_wstrb[3]) ram[w0][31:24] <= i_dmem_wdata[31:24];
            if (i_dmem_wstrb[4]) ram[w1][ 7: 0] <= i_dmem_wdata[39:32];
            if (i_dmem_wstrb[5]) ram[w1][15: 8] <= i_dmem_wdata[47:40];
            if (i_dmem_wstrb[6]) ram[w1][23:16] <= i_dmem_wdata[55:48];
            if (i_dmem_wstrb[7]) ram[w1][31:24] <= i_dmem_wdata[63:56];
        end
    end

endmodule
