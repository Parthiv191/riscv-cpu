// 32 x 32-bit register file for RISC-V core, reg x0 must always be 0

module regfile (
    input clk,
    input we, // write enable
    input [4:0] rs1_addr, rs2_addr, rd_addr,
    input [31:0] rd_data,
    output [31:0] rs1_data, rs2_data
);
    reg [31:0] regs [31:0];

    // Whenever addressing x0, assign 0, value doesn't matter
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs [rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs [rs2_addr];

    always @(posedge clk) begin
        if (we & rd_addr !== 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

endmodule
