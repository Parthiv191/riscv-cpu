`timescale 1ns/1ps

module tb_top;

    // Clock
    reg clk = 0;
    always #5 clk = ~clk;

    reg rst;
    wire [31:0] debug_pc;
    wire [31:0] debug_instr;

    riscv_top dut(
        .clk(clk),
        .rst(rst),
        .debug_pc(debug_pc),
        .debug_instr(debug_instr)
    );

    // Error tracking
    integer errors = 0;

    // Registers and dmem aren't ports, so these reach into the DUT's own
    // instances directly -- that's fine for a testbench, it's exactly what
    // hierarchical references are for.
    task check_reg;
        input [8*48-1:0] name;
        input [4:0] addr;
        input [31:0] expected;
        begin
            if (dut.regfile_inst.regs[addr] !== expected) begin
                errors = errors + 1;
                $display("FAIL [%0s] x%0d: 0x%08h, expected 0x%08h", name, addr, dut.regfile_inst.regs[addr], expected);
            end
        end
    endtask

    task check_not_reg;
        input [8*48-1:0] name;
        input [4:0] addr;
        input [31:0] not_expected;
        begin
            if (dut.regfile_inst.regs[addr] === not_expected) begin
                errors = errors + 1;
                $display("FAIL [%0s] x%0d: 0x%08h, should NOT have this value (branch/jump didn't skip it)", name, addr, not_expected);
            end
        end
    endtask

    task check_mem;
        input [8*48-1:0] name;
        input [31:0] word_addr;
        input [31:0] expected;
        begin
            if (dut.dmem_inst.mem[word_addr] !== expected) begin
                errors = errors + 1;
                $display("FAIL [%0s] mem[%0d]: 0x%08h, expected 0x%08h", name, word_addr, dut.dmem_inst.mem[word_addr], expected);
            end
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);

        rst = 1'b1;

        // Preloaded directly through imem's own array, bypassing $readmemh
        // -- same convention as tb_imem.v. Covers arithmetic, load/store,
        // both branch directions, lui, auipc, jal, and jalr all wired
        // together, not just each block in isolation.
        dut.imem_inst.mem[0] = 32'h00500093;  // addi x1, x0, 5
        dut.imem_inst.mem[1] = 32'h00A08113;  // addi x2, x1, 10
        dut.imem_inst.mem[2] = 32'h002081B3;  // add  x3, x1, x2
        dut.imem_inst.mem[3] = 32'h00302023;  // sw   x3, 0(x0)
        dut.imem_inst.mem[4] = 32'h00002203;  // lw   x4, 0(x0)
        dut.imem_inst.mem[5] = 32'h00320463;  // beq  x4, x3, +8   (taken)
        dut.imem_inst.mem[6] = 32'h3E700293;  // addi x5, x0, 999  (skipped)
        dut.imem_inst.mem[7] = 32'h00209463;  // bne  x1, x2, +8   (taken)
        dut.imem_inst.mem[8] = 32'h37800313;  // addi x6, x0, 888  (skipped)
        dut.imem_inst.mem[9] = 32'h123453B7;  // lui  x7, 0x12345
        dut.imem_inst.mem[10] = 32'h00001417; // auipc x8, 0x1
        dut.imem_inst.mem[11] = 32'h03C00613; // addi x12, x0, 60  (address of the halt loop)
        dut.imem_inst.mem[12] = 32'h008004EF; // jal  x9, +8
        dut.imem_inst.mem[13] = 32'h30900513; // addi x10, x0, 777 (skipped)
        dut.imem_inst.mem[14] = 32'h000605E7; // jalr x11, 0(x12)
        dut.imem_inst.mem[15] = 32'h0000006F; // jal  x0, 0        (halt)

        @(posedge clk);
        #1;
        rst = 1'b0;

        repeat (25) @(posedge clk);
        #1;

        check_reg("addi",  5'd1,  32'd5);
        check_reg("addi",  5'd2,  32'd15);
        check_reg("add",   5'd3,  32'd20);
        check_reg("lw",    5'd4,  32'd20);
        check_reg("lui",   5'd7,  32'h12345000);
        check_reg("auipc", 5'd8,  32'd4136); // pc(40) + (0x1<<12)
        check_reg("jal ra",5'd9,  32'd52);   // pc_of_jal(48) + 4
        check_reg("jalr addr", 5'd12, 32'd60);
        check_reg("jalr ra", 5'd11, 32'd60); // pc_of_jalr(56) + 4

        check_not_reg("beq should've skipped this", 5'd5, 32'd999);
        check_not_reg("bne should've skipped this", 5'd6, 32'd888);
        check_not_reg("jal should've skipped this", 5'd10, 32'd777);

        check_mem("sw", 32'd0, 32'd20);

        if (debug_pc !== 32'd60) begin
            errors = errors + 1;
            $display("FAIL [final pc] pc: %0d, expected 60 (looping on the halt jal)", debug_pc);
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
