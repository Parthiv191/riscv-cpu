// 32 x 32-bit register file for RISC-V core

module regfile (
    input         clk,
    input         we,             // write enable
    input  [4:0]  rs1_addr, rs2_addr, rd_addr,
    input  [31:0] rd_data,
    output [31:0] rs1_data, rs2_data
);

    // TODO: implementation

endmodule
