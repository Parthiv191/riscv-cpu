// Control unit for RISC-V core

module control (
    input  [6:0] opcode,         // instr[6:0]
    input  [2:0] funct3,         // instr[14:12]
    input  [6:0] funct7,         // instr[31:25]
    input        alu_zero,       // for branch resolution
    output       reg_write,
    output       mem_write,
    output       mem_to_reg,     // WB mux: 0=alu, 1=mem, 2=pc+4  (widen if needed)
    output [1:0] result_src,     // result mux select
    output       alu_src_a,      // ALU port A mux: 0=rs1, 1=pc  (for AUIPC)
    output       alu_src_b,      // ALU port B mux: 0=rs2, 1=imm
    output [3:0] alu_op,
    output [2:0] imm_src,
    output [1:0] pc_src          // PC mux: 0=pc+4, 1=branch, 2=jal, 3=jalr
);

    // TODO: implementation

endmodule
