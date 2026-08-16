`timescale 1ns/1ps

module tb_dmem;

    // Clock
    reg clk = 0;
    always #5 clk = ~clk;

    reg we;
    reg [31:0] addr;
    reg [31:0] wdata;
    wire [31:0] rdata;

    dmem dut(
        .clk(clk),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Error tracking
    integer errors = 0;

    // Same same-edge race as regfile's write task -- the #1 lets the DUT's
    // own posedge-triggered block go first before we drop we back to 0
    task write_word;
        input [31:0] addr_in;
        input [31:0] data_in;
        begin
            addr = addr_in;
            wdata = data_in;
            we = 1'b1;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

    task check_read;
        input [8*48-1:0] name;
        input [31:0] addr_in;
        input [31:0] expected;
        begin
            addr = addr_in;
            #1;

            if (rdata !== expected) begin
                errors = errors + 1;
                $display("FAIL [%0s] rdata: 0x%08h, expected 0x%08h", name, rdata, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_dmem);

        we = 1'b0;
        addr = 32'd0;
        wdata = 32'd0;

        // Zero-initialized before any write
        check_read("word 0 reads 0 before any write", 32'h00000000, 32'd0);

        // Write then read back, a couple different addresses
        write_word(32'h00000000, 32'hAAAAAAAA);
        write_word(32'h00000004, 32'h11111111);
        check_read("word 0 after write", 32'h00000000, 32'hAAAAAAAA);
        check_read("word 1 after write", 32'h00000004, 32'h11111111);

        // we=0 -- attempted write must not change anything
        addr = 32'h00000000;
        wdata = 32'hFFFFFFFF;
        we = 1'b0;
        @(posedge clk);
        #1;
        check_read("we=0 blocks write to word 0", 32'h00000000, 32'hAAAAAAAA);

        // Read-during-write to the same address -- async read must show the
        // OLD value right up until the write's clock edge actually lands
        addr = 32'h00000008;
        wdata = 32'h66666666;
        we = 1'b1;
        #1;
        if (rdata !== 32'd0) begin
            errors = errors + 1;
            $display("FAIL [read-during-write, before edge] rdata: 0x%08h, expected old 0x%08h", rdata, 32'd0);
        end
        @(posedge clk);
        #1;
        we = 1'b0;
        if (rdata !== 32'h66666666) begin
            errors = errors + 1;
            $display("FAIL [read-during-write, after edge] rdata: 0x%08h, expected new 0x%08h", rdata, 32'h66666666);
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
