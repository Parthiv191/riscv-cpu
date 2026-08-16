// Top module for RISC-V core -- instantiates all blocks, holds the PC
// register, and wires up the muxes control.v doesn't own directly

module riscv_top (
    input clk,
    input rst,
    output [31:0] debug_pc,
    output [31:0] debug_instr
);
    reg [31:0] pc;
    reg [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire [31:0] pc_plus_imm;
    wire [31:0] instr;

    wire [6:0] opcode;
    wire [4:0] rd_addr;
    wire [2:0] funct3;
    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;
    wire [6:0] funct7;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm;

    wire reg_write;
    wire mem_write;
    wire [1:0] result_src;
    wire alu_src_a;
    wire alu_src_b;
    wire [3:0] alu_op;
    wire [2:0] imm_src;
    wire [1:0] pc_src;

    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire alu_zero;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    reg [31:0] result;

    // Instruction fields
    assign opcode = instr[6:0];
    assign rd_addr = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7 = instr[31:25];

    // PC
    assign pc_plus4 = pc + 32'd4;
    assign pc_plus_imm = pc + imm; // shared by branch target and jal target

    always @(*) begin
        case (pc_src)
            2'b00: pc_next = pc_plus4;
            2'b01: pc_next = pc_plus_imm; // branch taken
            2'b10: pc_next = pc_plus_imm; // jal
            2'b11: pc_next = alu_result & ~32'b1; // jalr, clear bit 0
            default: pc_next = pc_plus4;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

    assign debug_pc = pc;
    assign debug_instr = instr;

    // ALU operand muxes
    assign alu_a = alu_src_a ? pc : rs1_data;
    assign alu_b = alu_src_b ? imm : rs2_data;

    // Data memory
    assign mem_addr = alu_result;
    assign mem_wdata = rs2_data;

    // Writeback mux
    always @(*) begin
        case (result_src)
            2'b00: result = alu_result;
            2'b01: result = mem_rdata;
            2'b10: result = pc_plus4;
            default: result = alu_result;
        endcase
    end

    imem imem_inst (
        .addr(pc),
        .instr(instr)
    );

    regfile regfile_inst (
        .clk(clk),
        .we(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(result),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    imm_gen imm_gen_inst (
        .instr(instr),
        .imm_src(imm_src),
        .imm(imm)
    );

    control control_inst (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_zero(alu_zero),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .result_src(result_src),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_op(alu_op),
        .imm_src(imm_src),
        .pc_src(pc_src)
    );

    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    dmem dmem_inst (
        .clk(clk),
        .we(mem_write),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .rdata(mem_rdata)
    );

endmodule
