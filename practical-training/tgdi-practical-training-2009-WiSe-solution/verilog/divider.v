`timescale 1ns / 1ps
//Praktikum TGDI WS 09/10
//Taktteiler
//100108 TW: Initial Version
//100114 TW: SIM-Switch eingebaut

module divider(input clkin, 
               output clkout);

//zur Synthese auskommentieren
`define SIM 1


//Zaehler
reg [25:0] count;

`ifdef SIM
assign clkout = count[2];
`else
assign clkout = count[25];
`endif

initial count = 0;

always @(posedge clkin) begin
	count <= count + 1;
end
endmodule
