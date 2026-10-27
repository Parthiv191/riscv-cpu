`timescale 1ns/1ps

module tb_regfile;

    // Clock
    logic clk = 0;
    always #5 clk = ~clk;

    logic we;
    logic [4:0] rs1_addr; 
    logic [4:0] rs2_addr; 
    logic [4:0] rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    regfile dut(
        .*
    );

    // Error tracking
    int errors = 0;

    // This needs the delay after the clk posedge. Before, we was going back to 0 before the always block wrote data 
    task automatic write_reg(
        input [4:0] addr,
        input [31:0] data
    );
        rd_addr = addr;
        rd_data = data;
        we = 1'b1;

        @(posedge clk);
        #1;
        
        we = 1'b0;
    endtask

    task automatic test_read(
        input string name,
        input [4:0] addr1,
        input [4:0] addr2,
        input [31:0] exp1,
        input [31:0] exp2
    );
        rs1_addr = addr1;
        rs2_addr = addr2;
        #1;

        assert(rs1_data === exp1) else begin
            errors += 1;
            $error("FAIL [%0s] rs1_data: 0x%08h, expected 0x%08h", name, rs1_data, exp1);
        end

        assert(rs2_data === exp2) else begin
            errors += 1;
            $error("FAIL [%0s] rs2_data: 0x%08h, expected 0x%08h", name, rs2_data, exp2);
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_regfile);

        we = 1'b0;
        rs1_addr = 5'd0;
        rs2_addr = 5'd0;
        rd_addr = 5'd0;
        rd_data = 32'd0;

        // General read and write
        write_reg(5'd1, 32'hAAAAAAAA);
        write_reg(5'd2, 32'h11111111);
        write_reg(5'd3, 32'h22222222);
        test_read("x1/x2 after writes", 5'd1, 5'd2, 32'hAAAAAAAA, 32'h11111111);
        test_read("x3/x1 after writes", 5'd3, 5'd1, 32'h22222222, 32'hAAAAAAAA);

        // Write w/ we=0
        rd_addr = 5'd1;
        rd_data = 32'hFFFFFFFF;
        we = 1'b0;

        @(posedge clk);
        #1;

        test_read("we=0 blocks write to x1", 5'd1, 5'd1, 32'hAAAAAAAA, 32'hAAAAAAAA);

        // Testing x0
        test_read("x0 reads 0 before any write", 5'd0, 5'd0, 32'd0, 32'd0);
        write_reg(5'd0, 32'hDEADBEEF);
        test_read("x0 still reads 0 after a write attempt", 5'd0, 5'd0, 32'd0, 32'd0);

        // Read during write
        write_reg(5'd5, 32'h55555555);
        rd_addr = 5'd5;
        rd_data = 32'h66666666;
        we = 1'b1;
        rs1_addr = 5'd5;

        #1;

        assert(rs1_data === 32'h55555555) else begin
            errors += 1;
            $error("FAIL [read-during-write, before edge] rs1_data: 0x%08h, expected old 0x%08h", rs1_data, 32'h55555555);
        end

        @(posedge clk);
        #1;

        we = 1'b0;

        assert(rs1_data === 32'h66666666) else begin
            errors += 1;
            $error("FAIL [read-during-write, after edge] rs1_data: 0x%08h, expected new 0x%08h", rs1_data, 32'h66666666);
        end

        if (errors == 0) 
            $display("PASS");
        else             
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
