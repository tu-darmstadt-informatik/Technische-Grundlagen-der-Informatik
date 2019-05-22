`timescale 1ns / 1ps
//Praktikum TGDI WS 09/10
//Toplevel Modul 
//100108 TW: Initial Version

module top(input clk, reset, 
           output [7:0] led);
    
    
  wire [31:0] aluout, writedata, readdata;
  wire memwrite;
  wire [31:0] pc, instr;
  
  //LEDs belegen und Signale zusammen-ORen, damit sie nicht wegopimiert werden
  assign led[0] = (|aluout | |writedata | |readdata | |memwrite);
  assign led[1] = 0;
  
  //PC auf LEDs legen zur Kontrolle
  assign led[7:2] =  pc[7:2];
  
  //50 MHZ-Takt teilen
  wire clkout;
  divider taktteiler (
    .clkin(clk), 
    .clkout(clkout)
    );
   
  //MIPS-CPU instanziieren           
  mips myMIPS (
    .clk(clkout), 
    .reset(reset), 
    .pc(pc), 
    .instr(instr), 
    .memwrite(memwrite), 
    .aluout(aluout), 
    .writedata(writedata), 
    .readdata(readdata)
    );
           
  //Instruction-Speicher
  imem imem (
    .a(pc[7:2]), 
    .rd(instr)
    );
    
  //Datenspeicher
  dmem dmem(
    .clk(clkout), 
    .we(memwrite), 
    .a(aluout), 
    .wd(writedata), 
    .rd(readdata)
    );

endmodule
