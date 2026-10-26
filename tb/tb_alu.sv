`timescale 1ns/1ps

module tb_alu;

    // ALU opcodes
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SLL  = 4'b0001,
        ALU_SLT  = 4'b0010,
        ALU_SLTU = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_SRL  = 4'b0101,
        ALU_OR   = 4'b0110,
        ALU_AND  = 4'b0111,
        ALU_SUB  = 4'b1000,
        ALU_LUI  = 4'b1010,
        ALU_SRA  = 4'b1101
    } alu_op_t;

    logic [31:0] a;
    logic [31:0] b;
    alu_op_t alu_op;
    logic [31:0] result;
    logic zero;

    alu dut(.*);


    // Error tracking
    int errors = 0;

    // Golden Model
    function automatic logic [31:0] alu_model (
        input logic [31:0] a_in,
        input logic [31:0] b_in,
        input alu_op_t op
    );
        case (op)
            ALU_ADD:  return a_in + b_in;
            ALU_SUB:  return a_in - b_in;
            ALU_SLL:  return a_in << b_in[4:0];                      // only low 5 bits of shamt
            ALU_SRL:  return a_in >> b_in[4:0];                      // zero-fill
            ALU_SRA:  return $signed(a_in) >>> b_in[4:0];            // sign-fill
            ALU_SLT:  return {31'b0, $signed(a_in) < $signed(b_in)};
            ALU_SLTU: return {31'b0, a_in < b_in};
            ALU_XOR:  return a_in ^ b_in;
            ALU_OR:   return a_in | b_in;
            ALU_AND:  return a_in & b_in;
            ALU_LUI:  return b_in;                                   // imm already shifted by imm_gen
            default:  return 32'b0;                                  // undefined op
        endcase
    endfunction

    // run_test takes in test name, drives inputs, and checks results
    task automatic run_test (
        input string name,
        input [31:0] a_in,
        input [31:0] b_in,
        input alu_op_t op_in,
        input [31:0] expected_result
    );
        logic expected_zero;
        a = a_in;
        b = b_in;
        alu_op = op_in;
        expected_zero = (expected_result == 32'b0);

        #1;

        assert (result === expected_result) else begin
            errors += 1;
            $error("FAIL [%0s] result: 0x%08h, expected 0x%08h", name, result, expected_result);
        end

        assert (zero === expected_zero) else begin
            errors += 1;
            $error("FAIL [%0s] zero: %0b, expected %0b", name, zero, expected_zero);
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_alu);

        // ADD
        run_test("ADD pos+pos", 32'd7, 32'd8, ALU_ADD, 32'd15);
        run_test("ADD wraparound (-1+1=0)", 32'hFFFFFFFF, 32'd1, ALU_ADD, 32'd0);

        // SUB 
        run_test("SUB pos-pos", 32'd20, 32'd5, ALU_SUB, 32'd15);
        run_test("SUB equal operands (zero)", 32'd7, 32'd7, ALU_SUB, 32'd0);
        run_test("SUB negative result", 32'd5, 32'd20, ALU_SUB, 32'hFFFFFFF1);

        // SLL
        run_test("SLL normal", 32'h00000001, 32'd4, ALU_SLL, 32'h00000010);
        run_test("SLL shift amt >32", 32'h00000001, 32'd33, ALU_SLL, 32'h00000002);

        // SRL / SRA
        run_test("SRL", 32'h80000000, 32'd4, ALU_SRL, 32'h08000000);
        run_test("SRA", 32'h80000000, 32'd4, ALU_SRA, 32'hF8000000);

        // SLT / SLTU
        run_test("SLT signed", 32'hFFFFFFFF, 32'd1, ALU_SLT, 32'd1);
        run_test("SLTU unsigned", 32'hFFFFFFFF, 32'd1, ALU_SLTU, 32'd0);

        // XOR / OR / AND 
        run_test("XOR", 32'hAAAAAAAA, 32'h55555555, ALU_XOR, 32'hFFFFFFFF);
        run_test("OR", 32'h0F0F0F0F, 32'hF0F0F0F0, ALU_OR, 32'hFFFFFFFF);
        run_test("AND mixed pattern", 32'hFF00FF00, 32'h0FF00FF0, ALU_AND, 32'h0F000F00);

        // Test for LUI, b = result
        run_test("LUI: result = b", 32'hDEADBEEF, 32'h12345678, ALU_LUI, 32'h12345678);

        // Undefined alu_op
        run_test("undefined alu_op -> 0", 32'hFFFFFFFF, 32'hFFFFFFFF, alu_op_t'(4'b1001), 32'd0);

        // Random tests; expected values come from the golden model
        repeat (10000) begin
            logic [31:0] rand_a;
            logic [31:0] rand_b;
            alu_op_t rand_op;

            // Pick a random legal opcode
            rand_op = rand_op.first();
            repeat ($urandom_range(rand_op.num() - 1, 0)) rand_op = rand_op.next();

            rand_a = $urandom;
            rand_b = $urandom;

            run_test({"random ", rand_op.name()}, rand_a, rand_b, rand_op, alu_model(rand_a, rand_b, rand_op));
        end

        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
