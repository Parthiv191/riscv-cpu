`timescale 1ns/1ps

module tb_imm_gen;

    // Immediate sources
    typedef enum logic [2:0] {
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_U = 3'b011,
        IMM_J = 3'b100
    } imm_src_t;

    logic [31:0] instr;
    imm_src_t imm_src;
    logic [31:0] imm;

    imm_gen dut(
        .*
    );

    // Error tracking
    int errors = 0;

    // Golden model
    function automatic logic [31:0] imm_model (
        /* verilator lint_off UNUSEDSIGNAL */
        input logic [31:0] i, // opcode bits [6:0] never feed an immediate
        /* verilator lint_on UNUSEDSIGNAL */
        input imm_src_t src
    );
        logic [31:0] m;
        m = 32'b0;
        case (src)
            IMM_I: begin
                m[10:0]  = i[30:20];
                m[31:11] = {21{i[31]}};
            end
            IMM_S: begin
                m[4:0]   = i[11:7];
                m[10:5]  = i[30:25];
                m[31:11] = {21{i[31]}};
            end
            IMM_B: begin
                m[0]     = 1'b0;
                m[4:1]   = i[11:8];
                m[10:5]  = i[30:25];
                m[11]    = i[7];
                m[31:12] = {20{i[31]}};
            end
            IMM_U: begin
                m[11:0]  = 12'b0;
                m[31:12] = i[31:12];
            end
            IMM_J: begin
                m[0]     = 1'b0;
                m[10:1]  = i[30:21];
                m[11]    = i[20];
                m[19:12] = i[19:12];
                m[31:20] = {12{i[31]}};
            end
            default: m = 32'b0;
        endcase
        return m;
    endfunction

    task automatic run_test(
        input string name,
        input [31:0] instr_in,
        input imm_src_t imm_src_in,
        input [31:0] imm_exp
    );
        instr = instr_in;
        imm_src = imm_src_in;
        #1;

        assert (imm === imm_exp) else begin
            errors += 1;
            $error("FAIL [%0s] instr 0x%08h: imm 0x%08h, expected 0x%08h", name, instr_in, imm, imm_exp);
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_imm_gen);

        // I-type
        run_test("addi x1, x0, 5",   32'h00500093, IMM_I, 32'h00000005);
        run_test("addi x1, x0, -5",  32'hFFB00093, IMM_I, 32'hFFFFFFFB);
        // S-type
        run_test("sw x2, 8(x1)",     32'h0020A423, IMM_S, 32'h00000008);
        run_test("sw x2, -4(x1)",    32'hFE20AE23, IMM_S, 32'hFFFFFFFC);
        // B-type
        run_test("beq x4, x3, +8",   32'h00320463, IMM_B, 32'h00000008);
        run_test("beq x0, x0, -8",   32'hFE000CE3, IMM_B, 32'hFFFFFFF8);
        // U-type
        run_test("lui x7, 0x12345",  32'h123453B7, IMM_U, 32'h12345000);
        run_test("lui x1, 0xFFFFF",  32'hFFFFF0B7, IMM_U, 32'hFFFFF000);
        // J-type
        run_test("jal x9, +8",       32'h008004EF, IMM_J, 32'h00000008);
        run_test("jal x0, -8",       32'hFF9FF06F, IMM_J, 32'hFFFFFFF8);

        // Walking ones: one instr bit set at a time, for every format.
        // Catches misplaced/swapped bits, bits that should be ignored leaking in,
        // and sign extension (bit 31).
        begin
            imm_src_t src;
            src = src.first();
            repeat (src.num()) begin
                for (int bit_pos = 0; bit_pos < 32; bit_pos++) begin
                    run_test($sformatf("walk %s bit %0d", src.name(), bit_pos), 32'b1 << bit_pos, src, imm_model(32'b1 << bit_pos, src));
                end
                src = src.next();
            end
        end

        // All ones; Fixed zero bits must be 0
        run_test("all ones I", 32'hFFFFFFFF, IMM_I, 32'hFFFFFFFF);
        run_test("all ones S", 32'hFFFFFFFF, IMM_S, 32'hFFFFFFFF);
        run_test("all ones B", 32'hFFFFFFFF, IMM_B, 32'hFFFFFFFE);
        run_test("all ones U", 32'hFFFFFFFF, IMM_U, 32'hFFFFF000);
        run_test("all ones J", 32'hFFFFFFFF, IMM_J, 32'hFFFFFFFE);

        // 3 undefined imm_src -> 0
        run_test("undefined imm_src 101", 32'hFFFFFFFF, imm_src_t'(3'b101), 32'd0);
        run_test("undefined imm_src 110", 32'hFFFFFFFF, imm_src_t'(3'b110), 32'd0);
        run_test("undefined imm_src 111", 32'hFFFFFFFF, imm_src_t'(3'b111), 32'd0);

        // Random instructions against the golden model
        repeat (1000) begin
            logic [31:0] rand_instr;
            imm_src_t rand_src;

            rand_src = rand_src.first();
            repeat ($urandom_range(rand_src.num() - 1, 0)) rand_src = rand_src.next();
            rand_instr = $urandom;

            run_test({"random ", rand_src.name()}, rand_instr, rand_src, imm_model(rand_instr, rand_src));
        end

        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
