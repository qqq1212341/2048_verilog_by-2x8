module KECE210_Game_Log2048(
  input clk, rst_n,
  input [(12-1):0] commandInput,
  input commandValid,
  output reg [(64-1):0] gamingBoard,
  output reg [(3-1):0] State
  );
  
  parameter move_up        = 12'b0000_0000_0010; // '2'
  parameter move_down      = 12'b0000_1000_0000; // '8'
  parameter move_left      = 12'b0000_0000_1000; // '4'
  parameter move_right     = 12'b0000_0010_0000; // '6'
  parameter move_upLeft    = 12'b0000_0000_0001; // '1'
  parameter move_upRight   = 12'b0000_0000_0100; // '3'
  parameter move_downLeft  = 12'b0000_0100_0000; // '7'
  parameter move_downRight = 12'b0001_0000_0000; // '9'
  
  parameter stateGameOnGoing = 3'b001;
  parameter stateGameOver = 3'b010;
  parameter stateGameClear = 3'b100;
  
  integer i, j, k, w, k_break;
  
  /*
    BoardArray: 5-bit 2-dimesional array of TextLCD gameboard.
      
      5'b [1-bit isMerged]_[4-bit BoardValue]
      
      Ex. 5'b0_0010: (0010)_2 = (2)_10, is NOT merged.
          5'b1_0101: (0101)_2 = (5)_10, is merged; that is, 4 + 4.
      
      [TextLCD]
      |------------------+------------------+-----+------------------|
      | BoardArray[0][0] | BoardArray[0][1] | ... | BoardArray[0][7] |
      |------------------+------------------+-----+------------------|
      | BoardArray[1][0] | BoardArray[1][1] | ... | BoardArray[1][7] |
      |------------------+------------------+-----+------------------|
  */
  reg [(5-1):0] BoardArray[0:(2-1)][0:(8-1)];
  reg [(8-1):0] Act;
  reg [3:0] isBoardFull;
  reg isGameOver;
  reg [(8-1):0] CountZero;

  reg [(8-1):0] tempArray[0:(16-1)]; //Reset at 'always'
  reg [(4-1):0] tempI, tempJ;
  reg [(4-1):0] randomI, randomJ;
  reg [(8-1):0] lfsrNum;
  
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      // initialize every variable
      gamingBoard = 0;
      Act = 0;
      State = stateGameOnGoing;
      isBoardFull = 0;
      isGameOver = 0;
      CountZero = 0;
      tempI = 0;
      tempJ = 0;
      randomI = 0;
      randomJ = 0;
      lfsrNum = 1;
    
      //Reset 'BoardArray'.
      for(i = 0; i < 2; i = i + 1) begin
        for(j = 0; j < 8; j = j + 1) begin
          BoardArray[i][j] = 5'b0_0000; 
          tempArray[8*i+j] = 0;
        end
      end

      // Initialize board in two num
      BoardArray[0][3] = 1;
      BoardArray[0][7] = 1;

    end
    
    else begin
      // set random Num on Clock change
      lfsrNum <= {lfsrNum[6:0], lfsrNum[7] ^ lfsrNum[5] ^ lfsrNum[4] ^ lfsrNum[3]};

      if(State == stateGameOnGoing) begin
        if(commandValid) begin
          case(commandInput)
            // Behavior on pressed "UP"
            move_up: begin
              for(i = 0; i < 8; i = i + 1) begin                
                if(BoardArray[0][i] == 0) begin
                  BoardArray[0][i] = BoardArray[1][i];
                  BoardArray[1][i] = 0;
                  Act = Act + 1'b1;
                end
                                
                else if(BoardArray[0][i] == BoardArray[1][i]) begin
                  BoardArray[0][i] = BoardArray[0][i] + 1'b1;
                  BoardArray[1][i] = 0;
                  Act = Act + 1'b1;
                end
              end
            end
            
            // Behavior on pressed "DOWN"
            move_down: begin
              for(i = 0; i < 8; i = i + 1) begin
                if(BoardArray[1][i] == 0) begin
                  BoardArray[1][i] = BoardArray[0][i];
                  BoardArray[0][i] = 0;
                  Act = Act + 1'b1;
                end
                
                else if(BoardArray[1][i] == BoardArray[0][i]) begin
                  BoardArray[1][i] = BoardArray[1][i] + 1'b1;
                  BoardArray[0][i] = 0;
                  Act = Act + 1'b1;
                end
              end
            end
            
            // Behavior on pressed "LEFT"
            move_left: begin
              for(i = 0; i < 2; i = i + 1) begin
                for(j = 1; j < 8; j = j + 1) begin
                  for(k = j; k > 0; k = k - 1) begin
                    if(BoardArray[i][k] == 0) begin
                      k_break = 1;
                    end
                    
                    if(k_break == 0) begin
                      if(BoardArray[i][k-1] == 0) begin
                        BoardArray[i][k-1] = BoardArray[i][k];
                        BoardArray[i][k] = 0;
                        Act = Act + 1'b1;
                      end
                      
                      
                      /*
                        Action; Merge left when (Left value == Current value) and (Current value != Merged value) and (Current value != 0).
                      */
                      
                      else if((BoardArray[i][k-1] == BoardArray[i][k]) && (BoardArray[i][k] < 5'b1_0000)) begin
                        BoardArray[i][k-1] = BoardArray[i][k-1] + 5'b1_0001;
                        BoardArray[i][k] = 0;
                        Act = Act + 1'b1;
                      end
                    end
                    
                    /*
                      No action; Break when
                      2) (Left value != 0) and (Left value != Current value).
                      3) (Left value == Current value) and (Current value = Merged value).
                    */
                    
                  end
                  k_break = 0;
                end
              end
            end
            
            // Behavior on pressed "RIGHT"
            move_right: begin
              for(i = 0; i < 2; i = i + 1) begin
                for(j = 6; j >= 0; j = j - 1) begin
                  for(k = j; k < 7; k = k + 1) begin
                    
                    /*
                      No action; Break when
                      1) (Current value == 0).
                    */
                    
                    if(BoardArray[i][k] == 0) begin
                      k_break = 1;
                    end
                    if (k_break == 0) begin
                      if(BoardArray[i][k+1] == 0) begin
                        BoardArray[i][k+1] = BoardArray[i][k];
                        BoardArray[i][k] = 0;
                        Act = Act + 1;
                      end
                      
                      
                      /*
                        Action; Merge right when (Right value == Current value) and (Current value != Merged value) and (Current value != 0).
                      */
                      
                      else if((BoardArray[i][k+1] == BoardArray[i][k]) && (BoardArray[i][k] < 5'b1_0000)) begin
                        BoardArray[i][k+1] = BoardArray[i][k+1] + 5'b1_0001;
                        BoardArray[i][k] = 0;
                        Act = Act + 1;
                      end
                    end
                    
                    /*
                      Action; Push right when (Right value == 0) and (Current value != 0).
                    */
                    
                    
                    
                    /*
                      No action; Break when
                      2) (Left value != 0) and (Left value != Current value).
                      3) (Left value == Current value) and (Current value = Merged value).
                    */
                    
                  end
                  k_break = 0;
                end
              end
            end
            
            // Behavior on pressed "UPLEFT"
            move_upLeft: begin
              for(i = 1; i < 8; i = i + 1) begin
                
                /*
                  Action; Push upLeft when (UpLeft value == 0).
                */
                
                if(BoardArray[0][i-1] == 0) begin
                  BoardArray[0][i-1] = BoardArray[1][i];
                  BoardArray[1][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  Action; Merge upLeft when (UpLeft value == Current value) and (Current value != 0).
                */
                
                else if(BoardArray[0][i-1] == BoardArray[1][i]) begin
                  BoardArray[0][i-1] = BoardArray[0][i-1] + 1;
                  BoardArray[1][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  No action; Do nothing when (UpLeft value != 0) and (UpLeft value != Current value).
                */
                
              end
            end
            
            // Behavior on pressed "UPRIGHT"
            move_upRight: begin
              for(i = 0; i < 7; i = i + 1) begin
                
                /*
                  Action; Push upRight when (UpRight value == 0).
                */
                
                if(BoardArray[0][i+1] == 0) begin
                  BoardArray[0][i+1] = BoardArray[1][i];
                  BoardArray[1][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  Action; Merge upRight when (UpRight value == Current value) and (Current value != 0).
                */
                
                else if(BoardArray[0][i+1] == BoardArray[1][i]) begin
                  BoardArray[0][i+1] = BoardArray[0][i+1] + 1;
                  BoardArray[1][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  No action; Do nothing when (UpRight value != 0) and (UpRight value != Current value).
                */
                
              end
            end
            
            // Behavior on pressed "DOWNLEFT"
            move_downLeft: begin
              for(i = 1; i < 8; i = i + 1) begin
                
                /*
                  Action; Push downLeft when (DownLeft value == 0).
                */
                
                if(BoardArray[1][i-1] == 0) begin
                  BoardArray[1][i-1] = BoardArray[0][i];
                  BoardArray[0][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  Action; Merge downLeft when (DownLeft value == Current value) and (Current value != 0).
                */
                
                else if(BoardArray[1][i-1] == BoardArray[0][i]) begin
                  BoardArray[1][i-1] = BoardArray[1][i-1] + 1;
                  BoardArray[0][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  No action; Do nothing when (DownLeft value != 0) and (DownLeft value != Current value).
                */
                
              end
            end
            
            // Behavior on pressed "DOWNRIGHT"
            move_downRight: begin
              for(i = 0; i < 7; i = i + 1) begin
                
                /*
                  Action; Push downRight when (DownRight value == 0).
                */
                
                if(BoardArray[1][i+1] == 0) begin
                  BoardArray[1][i+1] = BoardArray[0][i];
                  BoardArray[0][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  Action; Merge downLeft when (DownLeft value == Current value) and (Current value != 0).
                */
                
                else if(BoardArray[1][i+1] == BoardArray[0][i]) begin
                  BoardArray[1][i+1] = BoardArray[1][i+1] + 1;
                  BoardArray[0][i] = 0;
                  Act = Act + 1;
                end
                
                
                /*
                  No action; Do nothing when (DownLeft value != 0) and (DownLeft value != Current value).
                */
                
              end
            end
          endcase
        end

        // Remove 'isMerged' bit from 'BoardArray'.        
        else begin
          for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 8; j = j + 1) begin
              if(BoardArray[i][j] >= 5'b1_0000) begin
                BoardArray[i][j] = BoardArray[i][j] - 5'b1_0000;
              end
            end
          end
        

          // implement of After_act
          if(Act > 0) begin
            // reset Act to zero
            Act = 0;

            //
            // implement of newNumber
            //
            // reset CountZero to zero
            CountZero = 0;

            for(i = 0; i < 2; i = i + 1) begin
              for(j = 0; j < 8; j = j + 1) begin
                tempArray[8*i+j] = 0;
              end
            end

            for(i = 0; i < 2; i = i + 1) begin
              for(j = 0; j < 8; j = j + 1) begin
                if(BoardArray[i][j] == 0) begin
                  tempI = i; tempJ = j;
                  tempArray[CountZero] = {tempI, tempJ};
                  CountZero = CountZero + 1;
                end
              end
            end
            
            
            {randomI, randomJ} = tempArray[lfsrNum % CountZero];
            
            BoardArray[randomI][randomJ] = (lfsrNum % 100) < 75? 1: 2;

            //
            // implement of check_game_over
            //
            // check Zero in board

            // reset CountZero to zero
            CountZero = 0;

            for(i = 0; i < 2; i = i + 1) begin
              for(j = 0; j < 8; j = j + 1) begin
                if(BoardArray[i][j] == 5'b0_0000) begin
                  CountZero = CountZero + 1;
                end
              end
            end
            
            if(CountZero == 0) begin
              isBoardFull = 1;
            end
            
            if(isBoardFull == 1) begin
              for(j = 0; j < 7; j = j + 1) begin
                // right diagonal
                if(BoardArray[0][j] == BoardArray[1][j + 1]) begin
                  isGameOver = 0;
                end
                
                // left diagonal
                else if(BoardArray[0][j + 1] == BoardArray[1][j]) begin
                  isGameOver = 0;
                end
                
                // 0th right
                else if(BoardArray[0][j] == BoardArray[0][j + 1]) begin
                  isGameOver = 0;
                end
                
                // 1th right
                else if(BoardArray[1][j] == BoardArray[1][j + 1]) begin
                  isGameOver = 0;
                end

                // top-down
                else if(BoardArray[0][j] == BoardArray[1][j]) begin
                  isGameOver = 0;
                end
                
                else begin
                  isGameOver = 1;
                end

              end
              // 8th top-down
              if(BoardArray[1][7] == BoardArray[0][7]) begin
                  isGameOver = 0;
              end
            end
            
            if(isGameOver == 1) begin
              //display "GameOver"
              State = stateGameOver;
            end


            //
            // implement of gameClear
            //
            for(i = 0; i < 2; i = i + 1) begin
              for(j = 0; j < 8; j = j + 1) begin
                if(BoardArray[i][j] >= 10) begin
                  // display "GameClear"
                  State = stateGameClear;
                end
              end
            end
          end
        

        

        
        
          /*
            Assign 'BoardArray' to 'Board'.
          */
          for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 8; j = j + 1) begin
              gamingBoard[(63-32*i-4*j) -:4] = BoardArray[i][j][3:0];
            end
          end
        end
      end
    end
  end
endmodule

