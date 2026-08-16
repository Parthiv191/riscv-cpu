// Instruction memory for RISC-V core

module imem #( parameter [8*32-1:0] MEMFILE = "program.mem") (
    /* verilator lint_off UNUSEDSIGNAL */
    input [31:0] addr, // only addr[15:2] is used -- 64KB region, word-only access
    /* verilator lint_on UNUSEDSIGNAL */
    output [31:0] instr
);
    reg [31:0] mem [16383:0];

    initial begin
        $readmemh(MEMFILE, mem);
    end

    assign instr = mem[addr[15:2]];

endmodule
