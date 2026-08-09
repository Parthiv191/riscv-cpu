`timescale 1ns/1ps

module tb_control;

    reg  [6:0] opcode; // instr[6:0]
    reg  [2:0] funct3; // instr[14:12]
    reg  [6:0] funct7; // instr[31:25]
    reg        alu_zero; // for branch resolution
    wire       reg_write;
    wire       mem_write;
    wire [1:0] result_src; // WB mux select: 00=ALU, 01=MEM, 10=PC+4
    wire       alu_src_a; // ALU port A mux: 0=rs1, 1=pc  (for AUIPC)
    wire       alu_src_b; // ALU port B mux: 0=rs2, 1=imm
    wire [3:0] alu_op;
    wire [2:0] imm_src; // 000=I-type, 001=S-type, 010=B-type, 011=U-type, 100=J-type
    wire [1:0] pc_src; // PC mux: 0=pc+4, 1=branch, 2=jal, 3=jalr

    control dut(
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

    // Error tracking
    integer errors = 0;

    task run_test;
        input [8*48-1:0] name;
        input [6:0] op_in;
        input [2:0] f3_in;
        input [6:0] f7_in;
        input az_in;
        input exp_reg_write;
        input exp_mem_write;
        input [1:0] exp_result_src;
        input exp_alu_src_a;
        input exp_alu_src_b;
        input [3:0] exp_alu_op;
        input [2:0] exp_imm_src;
        input [1:0] exp_pc_src;
        begin
            opcode = op_in;
            funct3 = f3_in;
            funct7 = f7_in;
            alu_zero = az_in;
            #1;

            if (reg_write !== exp_reg_write) begin
                errors = errors + 1;
                $display("FAIL [%0s] reg_write: %0b, expected %0b", name, reg_write, exp_reg_write);
            end
            if (mem_write !== exp_mem_write) begin
                errors = errors + 1;
                $display("FAIL [%0s] mem_write: %0b, expected %0b", name, mem_write, exp_mem_write);
            end
            if (result_src !== exp_result_src) begin
                errors = errors + 1;
                $display("FAIL [%0s] result_src: %0b, expected %0b", name, result_src, exp_result_src);
            end
            if (alu_src_a !== exp_alu_src_a) begin
                errors = errors + 1;
                $display("FAIL [%0s] alu_src_a: %0b, expected %0b", name, alu_src_a, exp_alu_src_a);
            end
            if (alu_src_b !== exp_alu_src_b) begin
                errors = errors + 1;
                $display("FAIL [%0s] alu_src_b: %0b, expected %0b", name, alu_src_b, exp_alu_src_b);
            end
            if (alu_op !== exp_alu_op) begin
                errors = errors + 1;
                $display("FAIL [%0s] alu_op: %0b, expected %0b", name, alu_op, exp_alu_op);
            end
            if (imm_src !== exp_imm_src) begin
                errors = errors + 1;
                $display("FAIL [%0s] imm_src: %0b, expected %0b", name, imm_src, exp_imm_src);
            end
            if (pc_src !== exp_pc_src) begin
                errors = errors + 1;
                $display("FAIL [%0s] pc_src: %0b, expected %0b", name, pc_src, exp_pc_src);
            end
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_control);

        // LOAD (lw)
        run_test("lw", 7'b0000011, 3'b010, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b01, 1'b0, 1'b1, 4'b0000, 3'b000, 2'b00);

        // R-Type
        run_test("add", 7'b0110011, 3'b000, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 3'b000, 2'b00);
        run_test("sub", 7'b0110011, 3'b000, 7'b0100000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b0, 4'b1000, 3'b000, 2'b00);
        run_test("sra", 7'b0110011, 3'b101, 7'b0100000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b0, 4'b1101, 3'b000, 2'b00);

        // Store (sw)
        run_test("sw", 7'b0100011, 3'b010, 7'b0000000, 1'b0, 1'b0, 1'b1, 2'b00, 1'b0, 1'b1, 4'b0000, 3'b001, 2'b00);

        // Branch
        run_test("beq not equal", 7'b1100011, 3'b000, 7'b0000000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 4'b1000, 3'b010, 2'b00);
        run_test("beq", 7'b1100011, 3'b000, 7'b0000000, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 4'b1000, 3'b010, 2'b01);
        run_test("bne", 7'b1100011, 3'b001, 7'b0000000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 4'b1000, 3'b010, 2'b01);
        run_test("blt", 7'b1100011, 3'b100, 7'b0000000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0010, 3'b010, 2'b01);
        run_test("bge", 7'b1100011, 3'b101, 7'b0000000, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0010, 3'b010, 2'b01);
        run_test("bltu", 7'b1100011, 3'b110, 7'b0000000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0011, 3'b010, 2'b01);
        run_test("bgeu", 7'b1100011, 3'b111, 7'b0000000, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0011, 3'b010, 2'b01);

        // AUIPC
        run_test("auipc", 7'b0010111, 3'b000, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b1, 1'b1, 4'b0000, 3'b011, 2'b00);

        // LUI
        run_test("lui", 7'b0110111, 3'b000, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b1010, 3'b011, 2'b00);

        // JAL
        run_test("jal", 7'b1101111, 3'b000, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0, 1'b0, 4'b0000, 3'b100, 2'b10);

        // OP-IMM
        run_test("addi (funct7 bit set on purpose)", 7'b0010011, 3'b000, 7'b0100000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0000, 3'b000, 2'b00);
        run_test("slli", 7'b0010011, 3'b001, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0001, 3'b000, 2'b00);
        run_test("slti", 7'b0010011, 3'b010, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0010, 3'b000, 2'b00);
        run_test("sltiu", 7'b0010011, 3'b011, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0011, 3'b000, 2'b00);
        run_test("xori", 7'b0010011, 3'b100, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0100, 3'b000, 2'b00);
        run_test("srli", 7'b0010011, 3'b101, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0101, 3'b000, 2'b00);
        run_test("srai", 7'b0010011, 3'b101, 7'b0100000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b1101, 3'b000, 2'b00);
        run_test("ori", 7'b0010011, 3'b110, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0110, 3'b000, 2'b00);
        run_test("andi", 7'b0010011, 3'b111, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b1, 4'b0111, 3'b000, 2'b00);

        // JALR
        run_test("jalr", 7'b1100111, 3'b000, 7'b0000000, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0, 1'b1, 4'b0000, 3'b000, 2'b11);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
