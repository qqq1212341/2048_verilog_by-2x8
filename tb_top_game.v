`timescale 1ns/10ps

module tb_top_game;
  wire LCD_E;
  wire LCD_RS, LCD_RW;
  wire [(8-1):0] LCD_DATA;
  reg clk, rst_n;
  reg [(12-1):0] keypadPressed;

 KECE210_top_Log2048 test(
  clk, rst_n, keypadPressed, LCD_E, LCD_RS, LCD_RW, LCD_DATA
  );

  always begin
    #10 clk <= ~clk;
  end
 
  initial begin
    clk <= 0;
    rst_n <= 0;
    #20 rst_n <= 1;
    #5000 keypadPressed = 12'b0000_0000_1000;
    #100 keypadPressed <= 12'dx;
    #5000 keypadPressed = 12'b0000_1000_0000;
    #100 keypadPressed <= 12'dx;
    #5000 keypadPressed = 12'b0000_0000_1000;
    #100 keypadPressed <= 12'dx;
    #5000 keypadPressed = 12'b0000_0010_0000;
    #100 keypadPressed <= 12'dx;
    #5000 keypadPressed = 12'b0000_0010_0000;
    #100 keypadPressed <= 12'dx;
  end

endmodule

