`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sarah Harris 
// 
// Create Date:    21:26:58 02/14/2006 
// Design Name: 
// Module Name:    alu32 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module alu(	input [31:0] A, B, input [2:0] F, 
					output reg [31:0] Y, output Zero);
	
	wire [31:0] S, Bout;
	
	assign Bout = F[2] ? ~B : B;
	assign S = A + Bout + F[2];

	always @ ( * )
		case (F[1:0])
			2'b00: Y <= A & Bout;
			2'b01: Y <= A | Bout;
			2'b10: Y <= S;
			2'b11: Y <= S[31];
		endcase
	
	assign Zero = (Y == 32'b0);
//	assign Overflow =  A[31]& Bout[31] & ~Y[31] |
//							~A[31] & ~Bout[31] & Y[31];

endmodule
