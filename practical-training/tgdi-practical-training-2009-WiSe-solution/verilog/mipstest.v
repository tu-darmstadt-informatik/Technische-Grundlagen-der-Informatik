`timescale 1ns / 1ps
//Praktikum TGDI WS 09/10
//Testbench
//100108 TW: Initial Version

module testbench();

  reg         clk;
  reg         reset;

  wire [7:0] leds;

  // insstantiate device to be tested
  top dut(clk, reset, leds);
  
  // Reset
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // Takt
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

endmodule

