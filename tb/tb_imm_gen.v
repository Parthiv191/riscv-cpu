`timescale 1ns/1ps

module tb_imm_gen;

    // TODO: DUT signals

    // TODO: DUT instantiation (rtl/imm_gen.v)

    // Error tracking
    integer errors = 0;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_imm_gen);

        // TODO: stimulus + self-checking

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
