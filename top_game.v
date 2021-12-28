module KECE210_top_Log2048(
  input clk, rst_n,
  input [(12-1):0] keypadPressed,
  output LCD_E,
  output LCD_RS, LCD_RW,
  output [(8-1):0] LCD_DATA
  );

  wire [(12-1):0] keypadScanned;
  wire validEnable;
  wire [63:0] gamingBoard;
  wire [(3-1):0] State;
  
  KECE210_Keypad_Scan KECE210KeypadScan(
    .clk(clk), .rst_n(rst_n),
    .keypadPressed(keypadPressed),
    .keypadScanned(keypadScanned),
    .validEnable(validEnable)
    );
  
  KECE210_Game_Log2048 KECE210GameLog2048(
    .clk(clk), .rst_n(rst_n),
    .commandInput(keypadScanned),
    .commandValid(validEnable),
    .gamingBoard(gamingBoard),
    .State(State)
    );
  
  
  Text_LCD TextLCD(
    .clk(clk), .rst(rst_n), .Game_State(State),
    .Board(gamingBoard),
    .LCD_E(LCD_E), .LCD_RS(LCD_RS), .LCD_RW(LCD_RW), .LCD_DATA(LCD_DATA)
    );
  
endmodule