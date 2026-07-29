`timescale 1ns/1ps

module tb_top;

    // Clock
    reg clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // TODO: DUT signals (rst, debug_pc, debug_instr)

    // TODO: DUT instantiation (rtl/riscv_top.v + all rtl/*.v)

    // Error tracking
    integer errors = 0;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);

        // TODO: reset sequence

        // TODO: stimulus + self-checking (load program, run, check regfile)

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
