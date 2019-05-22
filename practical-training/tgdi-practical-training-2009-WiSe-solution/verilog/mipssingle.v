`timescale 1ns / 1ps
//Praktikum TGDI WS 09/10
//Taktteiler
//100108 TW: Initial Version, Codevorlage aus Lehrbuch erweitert

//------------------------------------------------
// mipssingle.v
// David_Harris@hmc.edu 23 October 2005
// Single-cycle MIPS processor
//------------------------------------------------

// single-cycle MIPS processor
module mips(input         clk, reset,
            output [31:0] pc,
            input  [31:0] instr,
            output        memwrite,
            output [31:0] aluout, writedata,
            input  [31:0] readdata);

  wire        memtoreg, branch,
              alusrc, regdst, regwrite, jump;
  wire [2:0]  alucontrol;
  wire datamemorywritemux_s;
  wire fpu_regwrite_ctrl,fpuregisterwritemux;

  controller c(instr[31:26], instr[5:0],
               memtoreg, memwrite, branch,
               alusrc, regdst, regwrite, jump,
               alucontrol,datamemorywritemux_s,fpu_regwrite_ctrl,fpuregisterwritemux);
  datapath dp(clk, reset, memtoreg, branch,
              alusrc, regdst, regwrite, jump,
              alucontrol,
              pc, instr,
              aluout, writedata, readdata,datamemorywritemux_s,fpu_regwrite_ctrl,fpuregisterwritemux);
endmodule

module controller(input  [5:0] op, funct,
                  output       memtoreg, memwrite,
                  output       branch, alusrc,
                  output       regdst, regwrite,
                  output       jump,
                  output [2:0] alucontrol,
                  output datamemorywritemux_s,fpu_regwrite_ctrl,fpuregisterwritemux);

  wire [1:0] aluop;

  maindec md(op, memtoreg, memwrite, branch,
             alusrc, regdst, regwrite, jump,
             aluop,datamemorywritemux_s,fpu_regwrite_ctrl,fpuregisterwritemux);
  aludec  ad(funct, aluop, alucontrol);
endmodule

module maindec(input  [5:0] op,
               output       memtoreg, memwrite,
               output       branch, alusrc,
               output       regdst, regwrite,
               output       jump,
               output [1:0] aluop,
               output datamemorywritemux_s,fpu_regwrite_ctrl,fpuregisterwritemux);

  reg [11:0] controls;

  assign {regwrite, regdst, alusrc,
          branch, memwrite,
          memtoreg, jump, aluop,datamemorywritemux_s,fpu_regwrite_ctrl,fpuregisterwritemux} = controls;

  always @( * )
    case(op)
      6'b000000: controls <= 12'b110000010000; //Rtyp
      6'b100011: controls <= 12'b101001000000; //LW
      6'b101011: controls <= 12'b001010000000; //SW
      6'b000100: controls <= 12'b000100001000; //BEQ
      6'b001000: controls <= 12'b101000000000; //ADDI
      6'b000010: controls <= 12'b000000100000; //J
      6'b110001: controls <= 12'b011001000011; //lwc1
      6'b111001: controls <= 12'b011010000100; //swc1
      6'b010001: controls <= 12'b000000000010; //Floating-Point
      default:   controls <= 12'bxxxxxxxxx; //???
    endcase
endmodule

module aludec(input      [5:0] funct,
              input      [1:0] aluop,
              output reg [2:0] alucontrol);

  always @( * )
    case(aluop)
      2'b00: alucontrol <= 3'b010;  // add
      2'b01: alucontrol <= 3'b110;  // sub
      default: case(funct)          // RTYPE
          6'b100000: alucontrol <= 3'b010; // ADD
          6'b100010: alucontrol <= 3'b110; // SUB
          6'b100100: alucontrol <= 3'b000; // AND
          6'b100101: alucontrol <= 3'b001; // OR
          6'b101010: alucontrol <= 3'b111; // SLT
          default:   alucontrol <= 3'bxxx; // ???
        endcase
    endcase
endmodule

module datapath(input         clk, reset,
                input         memtoreg, branch,
                input         alusrc, regdst,
                input         regwrite, jump,
                input  [2:0]  alucontrol,
                output [31:0] pc,
                input  [31:0] instr,
                output [31:0] aluout, writedata,
                input  [31:0] readdata,
                
                input datamemorywritemux_s,
                input fpu_regwrite_ctrl,
                input fpuregisterwritemux_s);

  wire [4:0]  writereg;
  wire        zero, pcsrc;
  wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
  wire [31:0] pcjump;
  wire [31:0] immext, immextsh;
  wire [31:0] srca, srcb;
  wire [31:0] result;
  
  //TW
  wire [31:0] writedata_rf;
  //

  // next PC logic
  assign pcsrc = branch & zero;
  assign pcjump = {pcplus4[31:28], instr[25:0], 2'b00};

  flopr #(32) pcreg(clk, reset, pcnext, pc);
  adder       pcadd1(pc, 32'b100, pcplus4);
  sl2         immsh(immext, immextsh);
  adder       pcadd2(pcplus4, immextsh, pcbranch);
  mux2 #(32)  pcbrmux(pcplus4, pcbranch, pcsrc,
                      pcnextbr);
  mux2 #(32)  pcmux(pcnextbr, pcjump, jump,
                    pcnext);
                    

  // register file logic
  regfile     rf(clk, regwrite, instr[25:21],
                 instr[20:16], writereg,
                 result, srca, writedata_rf);
  mux2 #(5)   wrmux(instr[20:16], instr[15:11],
                    regdst, writereg);
  mux2 #(32)  resmux(aluout, readdata,
                     memtoreg, result);
  signext     se(instr[15:0], immext);

  // ALU logic
  mux2 #(32)  srcbmux(writedata, immext, alusrc,
                      srcb);
  alu       alu32(srca, srcb, alucontrol,
                  aluout, zero);
  
  //Begin TW
  //----------------------------------------------------------------------------
  wire [31:0] fpu_result;
  
    //Mux vor DataMem, Ergebnis aus Reg oder FPU_Reg?
    mux2 #(32) datamemorywritemux (
    .d0(writedata_rf), 
    .d1(fpu_result), 
    .s(datamemorywritemux_s), 
    .y(writedata)
    );
  
    //Instanziierung der FPU
    /////////////////////////////////////
    fpu myFPU (
    .clk(clk), 
    .reset(reset), 
    .instruction(instr), 
    .mem_readdata(readdata), 
    .regdst(regdst), 
    .fpuregwritemux(fpuregisterwritemux_s), 
    .fpu_regwrite(fpu_regwrite_ctrl), 
    .mem_writedata(fpu_result)
    );
    ///////////////////////////////////////
    
endmodule
