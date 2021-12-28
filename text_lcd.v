module Text_LCD(
    input clk, rst,
    input [63:0] Board,
    input [2:0] Game_State,
    output LCD_E,
    // E is enable port
    output reg LCD_RS, LCD_RW,
    /*
        RS is to classify 'DATA' or 'Instruction'.
        RW is to classify 'Read data' or 'Write data'.
    */
    output reg [8-1:0] LCD_DATA
);

    parameter delay_100ms   = 3'b000;
    parameter function_set  = 3'b001;
    parameter entry_mode    = 3'b010;
    parameter disp_onoff    = 3'b011;
    parameter disp_line1    = 3'b100;
    parameter disp_line2    = 3'b101;
    parameter delay_2sec    = 3'b110;
    parameter clear_disp    = 3'b111;

    parameter stateGameOnGoing = 3'b001;
    parameter stateGameOver = 3'b010;
    parameter stateGameClear = 3'b100;
    
    integer counter;
    integer i, j;
    reg [3-1:0] state;
    reg [(8-1):0] BoardArray[0:(2-1)][0:(8-1)];

    always @(negedge rst or posedge clk) begin
        /*
            Control and change LCD states.
        */
        if (~rst) 
        begin
            state = delay_100ms;
        end
        else begin
            case (state)
                delay_100ms     : if (counter == 70)    state = function_set;
                function_set    : if (counter == 30)    state = disp_onoff;
                disp_onoff      : if (counter == 30)    state = entry_mode;
                entry_mode      : if (counter == 30)    state = disp_line1;
                disp_line1      : if (counter == 20)    state = disp_line2;
                disp_line2      : if (counter == 20)    state = delay_2sec;
                delay_2sec      : if (counter == 400)   state = disp_line1;
                clear_disp      : if (counter == 200)   state = disp_line1;
                default         :                       state = delay_100ms;
            endcase
        end
    end

    always @(negedge rst or posedge clk) begin
        /*
            Count local counter for determining LCD state.
        */
        if (~rst) counter = 0;
        else begin
            case (state)
                delay_100ms     : begin
                                    if (counter >= 70) counter = 0; 
                                    else counter = counter + 1;
                                end
                function_set    : begin
                                    if (counter >= 30) counter = 0; 
                                    else counter = counter + 1;
                                end
                disp_onoff      : begin
                                    if (counter >= 30) counter = 0; 
                                    else counter = counter + 1;
                                end
                entry_mode      : begin
                                    if (counter >= 30) counter = 0; 
                                    else counter = counter + 1;
                                end
                disp_line1      : begin
                                    if (counter >= 20) counter = 0; 
                                    else counter = counter + 1;
                                end
                disp_line2      : begin
                                    if (counter >= 20) counter = 0; 
                                    else counter = counter + 1;
                                end
                delay_2sec      : begin
                                    if (counter >= 400) counter = 0; 
                                    else counter = counter + 1;
                                end
                clear_disp      : begin
                                    if (counter >= 200) counter = 0; 
                                    else counter = counter + 1;
                                end
                default: counter = 0;
            endcase
        end
    end

    // set Number for lcd
    always @(negedge rst or posedge clk) begin
        if (~rst) begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 8; j = j + 1) begin
                    BoardArray[i][j] = 0; //Reset 'BoardArray'.
                end
            end
        end
        else begin
            for(i = 0; i < 2; i = i + 1) begin
                for(j = 0; j < 8; j = j + 1) begin
                    case (Board[(63-32*i-4*j) -:4])
                        0 : BoardArray[i][j] <= 8'b0011_0000;
                        1 : BoardArray[i][j] <= 8'b0011_0001;
                        2 : BoardArray[i][j] <= 8'b0011_0010;
                        3 : BoardArray[i][j] <= 8'b0011_0011;
                        4 : BoardArray[i][j] <= 8'b0011_0100;
                        5 : BoardArray[i][j] <= 8'b0011_0101;
                        6 : BoardArray[i][j] <= 8'b0011_0110;
                        7 : BoardArray[i][j] <= 8'b0011_0111;
                        8 : BoardArray[i][j] <= 8'b0011_1000;
                        9 : BoardArray[i][j] <= 8'b0011_1001;
                        // default = NULL
                        default: BoardArray[i][j] <= 8'b0010_0000;
                    endcase
                end
            end
        end
    end

    always @(negedge rst or posedge clk) begin
        /*
            To print TEXT in LCD.
        */
        if (~rst) begin
            LCD_RS = 1'b1;
            LCD_RW = 1'b1;
            LCD_DATA = 8'd0;
        end
        else begin
            case (Game_State)
                stateGameOnGoing : begin
                    case (state)
                        function_set :  begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0011_1000;
                                        end
                        disp_onoff :    begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0000_1100;
                                        end
                        entry_mode :    begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0000_0110;
                                        end
                        disp_line1 :    begin
                                            LCD_RW = 1'b0;
                                            case (counter)
                                                0:  begin LCD_RS=1'b0; LCD_DATA=8'b1000_0000; end // address
                                                1:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                2:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                3:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                4:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 

                                                5:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][0]; end 
                                                6:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][1]; end 
                                                7:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][2]; end 
                                                8:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][3]; end // 
                                                9:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][4]; end 
                                                10: begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][5]; end 
                                                11: begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][6]; end 
                                                12: begin LCD_RS=1'b1; LCD_DATA=BoardArray[0][7]; end 

                                                13: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                14: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                15: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                16: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                default: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                            endcase
                                        end
                        disp_line2 :    begin
                                            LCD_RW = 1'b0;
                                            case (counter)
                                                0:  begin LCD_RS=1'b0; LCD_DATA=8'b1100_0000; end // address
                                                1:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                2:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                3:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                4:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 

                                                5:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][0]; end 
                                                6:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][1]; end 
                                                7:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][2]; end 
                                                8:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][3]; end 
                                                9:  begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][4]; end 
                                                10: begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][5]; end 
                                                11: begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][6]; end 
                                                12: begin LCD_RS=1'b1; LCD_DATA=BoardArray[1][7]; end 

                                                13: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                14: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                15: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                16: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                default: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                            endcase
                                        end
                        delay_2sec :    begin
                                            LCD_RS=1'b0;
                                            LCD_RW=1'b0;
                                            LCD_DATA=8'b0000_0010;
                                        end
                        clear_disp :    begin
                                            LCD_RS=1'b0;
                                            LCD_RW=1'b0;
                                            LCD_DATA=8'b0000_0001;
                                        end
                        default :       begin
                                            LCD_RS=1'b1;
                                            LCD_RW=1'b1;
                                            LCD_DATA=8'b0000_0000;
                                        end
                    endcase
                end
                stateGameClear : begin
                    case (state)
                        function_set :  begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0011_1000;
                                        end
                        disp_onoff :    begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0000_1100;
                                        end
                        entry_mode :    begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0000_0110;
                                        end
                        disp_line1 :    begin
                                            LCD_RW = 1'b0;
                                            case (counter)
                                                0:  begin LCD_RS=1'b0; LCD_DATA=8'b1000_0000; end // address
                                                1:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                2:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0011; end // C
                                                3:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_1111; end // O
                                                4:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_1110; end // N
                                                5:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0111; end // G
                                                6:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0010; end // R
                                                7:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0001; end // A
                                                8:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0100; end // T
                                                9:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0101; end // U
                                                10: begin LCD_RS=1'b1; LCD_DATA=8'b0100_1100; end // L
                                                11: begin LCD_RS=1'b1; LCD_DATA=8'b0100_0001; end // A
                                                12: begin LCD_RS=1'b1; LCD_DATA=8'b0101_0100; end // T
                                                13: begin LCD_RS=1'b1; LCD_DATA=8'b0100_1001; end // I
                                                14: begin LCD_RS=1'b1; LCD_DATA=8'b0100_1111; end // O
                                                15: begin LCD_RS=1'b1; LCD_DATA=8'b0100_1110; end // N 
                                                16: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end //
                                                default: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                            endcase
                                        end
                        disp_line2 :    begin
                                            LCD_RW = 1'b0;
                                            case (counter)
                                                0:  begin LCD_RS=1'b0; LCD_DATA=8'b1100_0000; end // address
                                                1:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                2:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                3:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0111; end 
                                                4:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0001; end 
                                                5:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_1101; end 
                                                6:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0101; end 
                                                7:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end 
                                                8:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0011; end 
                                                9:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_1100; end 
                                                10: begin LCD_RS=1'b1; LCD_DATA=8'b0100_0101; end 
                                                11: begin LCD_RS=1'b1; LCD_DATA=8'b0100_0001; end 
                                                12: begin LCD_RS=1'b1; LCD_DATA=8'b0101_0010; end 
                                                13: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0001; end // 
                                                14: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0001; end // 
                                                15: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                16: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                default: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                            endcase
                                        end
                        delay_2sec :    begin
                                            LCD_RS=1'b0;
                                            LCD_RW=1'b0;
                                            LCD_DATA=8'b0000_0010;
                                        end
                        clear_disp :    begin
                                            LCD_RS=1'b0;
                                            LCD_RW=1'b0;
                                            LCD_DATA=8'b0000_0001;
                                        end
                        default :       begin
                                            LCD_RS=1'b1;
                                            LCD_RW=1'b1;
                                            LCD_DATA=8'b0000_0000;
                                        end
                    endcase
                end
                stateGameOver : begin
                    case (state)
                        function_set :  begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0011_1000;
                                        end
                        disp_onoff :    begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0000_1100;
                                        end
                        entry_mode :    begin
                                            LCD_RS = 1'b0;
                                            LCD_RW = 1'b0;
                                            LCD_DATA = 8'b0000_0110;
                                        end
                        disp_line1 :    begin
                                            LCD_RW = 1'b0;
                                            case (counter)
                                                0:  begin LCD_RS=1'b0; LCD_DATA=8'b1000_0000; end // address
                                                1:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                2:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0111; end // G
                                                3:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0001; end // A
                                                4:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_1101; end // M
                                                5:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0101; end // E
                                                6:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                7:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_1111; end // O
                                                8:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0110; end // V
                                                9:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0101; end // E
                                                10: begin LCD_RS=1'b1; LCD_DATA=8'b0101_0010; end // R
                                                11: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0001; end // !
                                                12: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                13: begin LCD_RS=1'b1; LCD_DATA=8'b0111_1000; end // x
                                                14: begin LCD_RS=1'b1; LCD_DATA=8'b0101_1111; end // _
                                                15: begin LCD_RS=1'b1; LCD_DATA=8'b0111_1000; end // x 
                                                16: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                                default: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end //
                                            endcase
                                        end
                        disp_line2 :    begin
                                            LCD_RW = 1'b0;
                                            case (counter)
                                                0:  begin LCD_RS=1'b0; LCD_DATA=8'b1100_0000; end // address
                                                1:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // blank
                                                2:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0010; end // R
                                                3:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0101; end // E
                                                4:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0011; end // S
                                                5:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_0101; end // E
                                                6:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0100; end // T
                                                7:  begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // blank
                                                8:  begin LCD_RS=1'b1; LCD_DATA=8'b0101_0100; end // T
                                                9:  begin LCD_RS=1'b1; LCD_DATA=8'b0100_1111; end // O
                                                10: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // blank
                                                11: begin LCD_RS=1'b1; LCD_DATA=8'b0101_0010; end // R
                                                12: begin LCD_RS=1'b1; LCD_DATA=8'b0100_0101; end // E
                                                13: begin LCD_RS=1'b1; LCD_DATA=8'b0101_0100; end // T
                                                14: begin LCD_RS=1'b1; LCD_DATA=8'b0101_0010; end // R
                                                15: begin LCD_RS=1'b1; LCD_DATA=8'b0101_1001; end // Y
                                                16: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // blank
                                                default: begin LCD_RS=1'b1; LCD_DATA=8'b0010_0000; end // 
                                            endcase
                                        end
                        delay_2sec :    begin
                                            LCD_RS=1'b0;
                                            LCD_RW=1'b0;
                                            LCD_DATA=8'b0000_0010;
                                        end
                        clear_disp :    begin
                                            LCD_RS=1'b0;
                                            LCD_RW=1'b0;
                                            LCD_DATA=8'b0000_0001;
                                        end
                        default :       begin
                                            LCD_RS=1'b1;
                                            LCD_RW=1'b1;
                                            LCD_DATA=8'b0000_0000;
                                        end
                    endcase
                end
            endcase
        end
    end

    assign LCD_E = clk;
endmodule