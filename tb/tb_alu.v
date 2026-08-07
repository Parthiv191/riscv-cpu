`timescale 1ns/1ps

module tb_alu;

    reg [31:0] a;
    reg [31:0] b;
    reg [3:0] alu_op;
    wire [31:0] result;
    wire zero;

    alu dut(
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );


    // Error tracking
    integer errors = 0;

    // run_test takes in test name, drives inputs, and checks results
    task run_test;
        input [8*48-1:0] name;
        input [31:0] a_in;
        input [31:0] b_in;
        input [3:0] op_in;
        input [31:0] expected_result;
        reg expected_zero;
        begin
            a = a_in;
            b = b_in;
            alu_op = op_in;
            expected_zero = (expected_result == 32'b0);

            #1;

            if (result !== expected_result) begin
                errors = errors + 1;
                $display("FAIL [%0s] result: 0x%08h, expected 0x%08h", name, result, expected_result);
            end

            if (zero !== expected_zero) begin
                errors = errors + 1;
                $display("FAIL [%0s] zero: %0b, expected %0b", name, zero, expected_zero);
            end
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_alu);

        // ADD
        run_test("ADD pos+pos", 32'd7, 32'd8, 4'b0000, 32'd15);
        run_test("ADD wraparound (-1+1=0)", 32'hFFFFFFFF, 32'd1, 4'b0000, 32'd0);

        // SUB 
        run_test("SUB pos-pos", 32'd20, 32'd5, 4'b1000, 32'd15);
        run_test("SUB equal operands (zero)", 32'd7, 32'd7, 4'b1000, 32'd0);
        run_test("SUB negative result", 32'd5, 32'd20, 4'b1000, 32'hFFFFFFF1);

        // SLL
        run_test("SLL normal", 32'h00000001, 32'd4, 4'b0001, 32'h00000010);
        run_test("SLL shift amt >32", 32'h00000001, 32'd33, 4'b0001, 32'h00000002);

        // SRL vs SRA
        run_test("SRL", 32'h80000000, 32'd4, 4'b0101, 32'h08000000);
        run_test("SRA", 32'h80000000, 32'd4, 4'b1101, 32'hF8000000);

        // SLT vs SLTU
        run_test("SLT signed", 32'hFFFFFFFF, 32'd1, 4'b0010, 32'd1);
        run_test("SLTU unsigned", 32'hFFFFFFFF, 32'd1, 4'b0011, 32'd0);

        // XOR / OR / AND 
        run_test("XOR", 32'hAAAAAAAA, 32'h55555555, 4'b0100, 32'hFFFFFFFF);
        run_test("OR", 32'h0F0F0F0F, 32'hF0F0F0F0, 4'b0110, 32'hFFFFFFFF);
        run_test("AND mixed pattern", 32'hFF00FF00, 32'h0FF00FF0, 4'b0111, 32'h0F000F00);

        // Test for LUI, b = result
        run_test("LUI: result = b", 32'hDEADBEEF, 32'h12345678, 4'b1010, 32'h12345678);

        // Undefined alu_op
        run_test("undefined alu_op -> 0", 32'hFFFFFFFF, 32'hFFFFFFFF, 4'b1001, 32'd0);

        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
