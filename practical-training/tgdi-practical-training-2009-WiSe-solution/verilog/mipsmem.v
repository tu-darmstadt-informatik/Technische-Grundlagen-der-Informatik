//------------------------------------------------
// mipsmem.v
// David_Harris@hmc.edu 23 October 2005
// External memories used by MIPS processors
//------------------------------------------------


module dmem(input         clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg  [31:0] RAM[63:0];

  initial
    begin
      $readmemh("memfiledata.dat",RAM);
    end

  always @(posedge clk)
    if (we)
      RAM[a[6:2]] <= wd;
      
  assign rd = RAM[a[6:2]]; // word aligned      
      
endmodule

//Instruction-Memory
//ROM
module imem(input  [5:0] a,
            output [31:0] rd);

  reg  [31:0] RAM[63:0];

  initial
    begin
      $readmemh("memfile1.dat",RAM);
    end

  assign rd = RAM[a]; // word aligned
endmodule


