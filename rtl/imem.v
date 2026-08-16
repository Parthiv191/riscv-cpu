// Instruction memory for RISC-V core

module imem (
    input [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [16383:0];

    initial begin
        $readmemh("program.mem", mem);
    end

    assign instr = mem[addr[15:2]];

endmodule
