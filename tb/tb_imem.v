`timescale 1ns/1ps

module tb_imem #(
    parameter [8*32-1:0] MEMFILE = "program.mem"
) ();

    reg [31:0] addr;
    wire [31:0] instr;

    imem #(.MEMFILE(MEMFILE)) dut(
        .addr(addr),
        .instr(instr)
    );

    // Error tracking
    integer errors = 0;

    task check_read;
        input [8*48-1:0] name;
        input [31:0] addr_in;
        input [31:0] expected;
        begin
            addr = addr_in;
            #1;

            if (instr !== expected) begin
                errors = errors + 1;
                $display("FAIL [%0s] instr: 0x%08h, expected 0x%08h", name, instr, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_imem);

        // Preload a known pattern directly through the DUT's internal array
        // -- $readmemh loading program.mem is an integration-level concern,
        // not something this unit test needs
        dut.mem[0] = 32'h00000013;
        dut.mem[1] = 32'hDEADBEEF;
        dut.mem[2] = 32'h12345678;
        dut.mem[16383] = 32'hFFFFFFFF;

        check_read("word 0", 32'h00000000, 32'h00000013);
        check_read("word 1", 32'h00000004, 32'hDEADBEEF);
        check_read("word 2", 32'h00000008, 32'h12345678);
        check_read("last word (64KB - 4)", 32'h0000FFFC, 32'hFFFFFFFF);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
