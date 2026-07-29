// 32-bit ALU for RISC-V core

// ----- Operations -----
// 	ADD, SUB, AND, OR, XOR
// 	SLL, SRL, SRA
// 	SLT, SLTU



module alu(
	input [31:0] a,
	input [31:0] b,
	input [3:0] alu_op,
	output reg [31:0] result,
	output zero
);

	always @(*) begin
	  case (alu_op)
		4'b0000: result = a + b;
		4'b1000: result = a - b;
		4'b0001: result = a << b[4:0];
		4'b0010: result = $signed(a) < $signed(b) ? 1 : 0;
		4'b0011: result = $unsigned(a) < $unsigned(b) ? 1 : 0;
		4'b0100: result = a ^ b;
		4'b0101: result = a >> b[4:0];
		4'b1101: result = $signed(a) >>> b[4:0];
		4'b0110: result = a | b;
		4'b0111: result = a & b;
		default: result = 32'b0;
	  endcase
	end

	assign zero = (result == 0) ? 1 : 0;

endmodule
