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
    output  reg  [2:0] imm_src, // 0=I-type, 1=S-type, 2=B-type, 3=U-type, 4=J-type
    output  reg  [1:0] pc_src // PC mux: 0=pc+4, 1=branch, 2=jal, 3=jalr
);

    always @(*) begin
        reg_write  = 1'b0;
        mem_write  = 1'b0;
        result_src = 2'b00; // Default ALU
        alu_src_a  = 1'b0;
        alu_src_b  = 1'b0;
        alu_op     = 4'b0000;
        imm_src    = 3'b000;
        pc_src     = 2'b00;

        case (opcode)
        // Load-Type
        // NOTE: This is just lw for rn, probably will include halfbyte stuff, but haven't thought this through
            7'b0000011: begin
                reg_write = 1'b1;
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
                alu_src_a = 0;
                alu_src_b = 1'b1;
                imm_src = 3'b011;
            end

        // JAL, jump and link
            7'b1101111: begin

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
                
            end

            default: begin

            end
        endcase
    end

endmodule
