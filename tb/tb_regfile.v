`timescale 1ns/1ps

module tb_regfile;

    // Clock
    reg clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // TODO: DUT signals

    // TODO: DUT instantiation (rtl/regfile.v)

    // Error tracking
    integer errors = 0;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_regfile);

        // TODO: stimulus + self-checking

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
