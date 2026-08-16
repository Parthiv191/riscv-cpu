// Data memory for RISC-V core

module dmem (
    input clk,
    input we,
    /* verilator lint_off UNUSEDSIGNAL */
    input [31:0] addr, // only addr[15:2] is used -- 64KB region, word-only access
    /* verilator lint_on UNUSEDSIGNAL */
    input [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] mem [16383:0];
    integer i;

    initial begin
        for (i = 0; i < 16384; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    assign rdata = mem[addr[15:2]];

    always @(posedge clk) begin
        if (we) begin
            mem[addr[15:2]] <= wdata;
        end
    end

endmodule
