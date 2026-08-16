`timescale 1ns/1ps

module tb_imm_gen;

    reg [31:0] instr;
    reg [2:0] imm_src;
    wire [31:0] imm;

    imm_gen dut(
        .instr(instr),
        .imm_src(imm_src),
        .imm(imm)
    );

    // Error tracking
    integer errors = 0;

    task run_test;
        input [8*48-1:0] name;
        input [31:0] instr_in;
        input [2:0] imm_src_in;
        input [31:0] expected;
        begin
            instr = instr_in;
            imm_src = imm_src_in;
            #1;

            if (imm !== expected) begin
                errors = errors + 1;
                $display("FAIL [%0s] imm: 0x%08h, expected 0x%08h", name, imm, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_imm_gen);

        // I-type -- addi x1, x0, -1 (all-ones immediate, sign-extend boundary)
        run_test("I-type: addi x1,x0,-1", 32'hFFF00093, 3'b000, 32'hFFFFFFFF);
        // I-type -- addi x5, x6, 5 (small positive, no sign extension)
        run_test("I-type: addi x5,x6,5", 32'h00530293, 3'b000, 32'd5);

        // S-type -- sw x2, 100(x1)
        run_test("S-type: sw x2,100(x1)", 32'h0620A223, 3'b001, 32'd100);

        // B-type -- beq x1, x2, -8 (negative, implicit LSB=0)
        run_test("B-type: beq x1,x2,-8", 32'hFE208CE3, 3'b010, 32'hFFFFFFF8);

        // U-type -- lui x1, 0x12345
        run_test("U-type: lui x1,0x12345", 32'h123450B7, 3'b011, 32'h12345000);

        // J-type -- jal x1, 4096 (positive, implicit LSB=0)
        run_test("J-type: jal x1,4096", 32'h000010EF, 3'b100, 32'h00001000);

        // Undefined imm_src -- must fall through to 0, not X
        run_test("undefined imm_src -> 0", 32'hFFFFFFFF, 3'b101, 32'd0);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
