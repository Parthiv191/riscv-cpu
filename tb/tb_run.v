`timescale 1ns/1ps

module tb_run #(
    parameter [8*32-1:0] MEMFILE = "program.mem"
) ();

    // Clock
    reg clk = 0;
    always #5 clk = ~clk;

    reg rst;
    wire [31:0] debug_pc;
    wire [31:0] debug_instr;

    riscv_top #(.MEMFILE(MEMFILE)) dut(
        .clk(clk),
        .rst(rst),
        .debug_pc(debug_pc),
        .debug_instr(debug_instr)
    );

    integer i;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_run);

        rst = 1'b1;
        @(posedge clk);
        #1;
        rst = 1'b0;

        repeat (300) @(posedge clk);
        #1;

        $display("final pc = %0d, final instr = 0x%08h", debug_pc, debug_instr);
        for (i = 1; i < 32; i = i + 1) begin
            $display("x%0d = %0d (0x%08h)", i, $signed(dut.regfile_inst.regs[i]), dut.regfile_inst.regs[i]);
        end

        $finish;
    end

endmodule
