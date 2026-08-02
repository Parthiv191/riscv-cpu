// Control unit for RISC-V core

module control (
    input  [6:0] opcode, // instr[6:0]
    input  [2:0] funct3, // instr[14:12]
    input  [6:0] funct7, // instr[31:25]
    input        alu_zero, // for branch resolution
    output  reg  reg_write,
    output  reg  mem_write,
    output  reg  [1:0] result_src, // WB mux select: 00=ALU, 01=MEM, 10=PC+4
    output  reg  alu_src_a, // ALU port A mux: 0=rs1, 1=pc  (for AUIPC)
    output  reg  alu_src_b, // ALU port B mux: 0=rs2, 1=imm
    output  reg  [3:0] alu_op,
    output  reg  [2:0] imm_src, // 000=I-type, 001=S-type, 010=B-type, 011=U-type, 100=J-type
    output  reg  [1:0] pc_src // PC mux: 0=pc+4, 1=branch, 2=jal, 3=jalr
);

    reg branch_taken; // internal helper, not a port

    always @(*) begin
        reg_write = 1'b0;
        mem_write = 1'b0;
        result_src= 2'b00; // Default ALU
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        alu_op = 4'b0000;
        imm_src = 3'b000;
        pc_src = 2'b00;
        branch_taken = 1'b0;

        case (opcode)
        // Load-Type
        // NOTE: This is just lw for rn, probably will include halfbyte stuff, but haven't thought this through
            7'b0000011: begin
                reg_write = 1'b1;
                result_src = 2'b01;
                alu_src_a = 1'b0;
                alu_src_b = 1'b1;
            end

        // R-Type
            7'b0110011: begin
                reg_write = 1'b1;
                result_src = 2'b00; // ALU
                alu_src_a = 1'b0; // rs1
                alu_src_b = 1'b0; // rs2
                alu_op = {funct7[5], funct3};
            end

        // Store-Type
        // NOTE: Same at I-type, maybe will include half stuff later
            7'b0100011: begin 
                mem_write = 1'b1;
                alu_src_b = 1'b1;
                imm_src = 3'b001;
            end

        // Branch-Type
            7'b1100011: begin
                imm_src = 3'b010; // B-type

                // funct3[2:1]:
                // 00 = SUB (beq/bne), 10 = SLT (blt/bge), 11 = SLTU (bltu/bgeu)
                case (funct3[2:1])
                    2'b00: alu_op = 4'b1000; // SUB
                    2'b10: alu_op = 4'b0010; // SLT
                    2'b11: alu_op = 4'b0011; // SLTU
                    default: alu_op = 4'b1000;
                endcase

                branch_taken = funct3[2] ? ~alu_zero : alu_zero;

                if (funct3[0])
                    branch_taken = ~branch_taken;

                if (branch_taken)
                    pc_src = 2'b01;
            end

        // AUIPC, add upper immediate to PC
            7'b0010111: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                imm_src = 3'b011;
            end

        // LUI, load upper immediate
            7'b0110111: begin
                reg_write = 1'b1;
                mem_write = 1'b0;
                result_src = 2'b00;
                alu_src_b = 1'b1;
                alu_op = 4'b1010;
                imm_src = 3'b011;
            end

        // JAL, jump and link
            7'b1101111: begin
                reg_write = 1'b1;
                mem_write = 1'b0;
                result_src = 2'b10;
                imm_src = 3'b100;
                pc_src = 2'b10;
            end 

        // Immediate-op type
            7'b0010011: begin
                reg_write = 1'b1;
                result_src = 2'b00; // ALU
                alu_src_a  = 1'b0;
                alu_src_b = 1'b1;
                if (funct3 == 3'b101)
                    alu_op = {funct7[5], funct3};
                else
                    alu_op = {1'b0, funct3};
                imm_src = 3'b000;
            end

        // JALR, jump and link register
            7'b1100111: begin
                reg_write = 1'b1;
                mem_write = 1'b0;
                result_src = 2'b10;
                alu_src_a = 1'b0;
                alu_src_b = 1'b1;
                alu_op = 4'b0000;
                imm_src = 3'b000;
                pc_src = 2'b11;
            end
        endcase
    end

endmodule
