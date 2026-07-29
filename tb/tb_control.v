`timescale 1ns/1ps

module tb_control;

    // TODO: DUT signals

    // TODO: DUT instantiation (rtl/control.v)

    // Error tracking
    integer errors = 0;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_control);

        // TODO: stimulus + self-checking

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
