module KECE210_Keypad_Scan(
  input clk, rst_n,
  input [(12-1):0] keypadPressed,
  output reg [(12-1):0] keypadScanned,
  output reg validEnable
  );
  
  reg temp;
  
  
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      keypadScanned <= 12'b0000_0000_0000;
      validEnable <= 1'b0;
      temp <= 1'b0;
    end
    
    else begin
      if(keypadPressed) begin
        if(~temp) begin
          keypadScanned <= keypadPressed;
          validEnable <= 1'b1;
          temp <= 1'b1;
        end
        
        else begin
          keypadScanned <= 12'b0000_0000_0000;
          validEnable <= 1'b0;
        end
      end
      
      else begin
        keypadScanned <= 12'b0000_0000_0000;
        validEnable <= 1'b0;
        temp <= 1'b0;
      end
    end
  end
endmodule