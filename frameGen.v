`timescale 1ns / 1ps

module frame_generator(
    input            CLK,
    input            RST,
    input            START,

    input [10:0]     W,
    input [10:0]     H,
    input [2:0]      W_pause,
    input [6:0]      H_pause,
    input [31:0]     FRAME_pause,
    input            EN_I,
    
    output reg       H_SYNC = 1,
    output reg       V_SYNC = 1,
    output reg       EN_O = 0,    
    output reg [9:0] DATA = 0    
    );
    //=================== Внутренние регистры ===================//
    reg [10:0] x  = 0;
    reg [10:0] y  = 0;
    reg [2:0]  wp = 0;
    reg [6:0]  hp = 0;
    reg [31:0] f  = 0;
    reg [31:0] numOfFrames = 0;
   
    reg [4:0] STATE = 0;
    reg       RST_f = 0;
    //===========================================================//
    always @(posedge CLK)
    begin                
        if (EN_I)
        begin    
            if (START) 
            begin
                STATE <= 1;                 
            end    
              
            if (RST)
            begin   
                RST_f <= 1;
            end
            
            if (RST_f)
            begin
                STATE <= 6;
                RST_f <= 0;
            end
               
            //++++++++++++++++++++++ Автомат ++++++++++++++++++++++//
            case (STATE)
                0:  //Простой
                begin
                     
                end
                //--------------------------------------------------
                1: // Первый кадр
                begin                    
                    EN_O <= 0; 
                    x = 0;
                    y = 0;
                    
                    if (wp >= W_pause)
                    begin
                        wp <= 0;
                        STATE <= 2;
                    end
                    
                    if (wp == 0)
                    begin
                        DATA <= DATA + 1;
                        EN_O <= 1;
                        H_SYNC <= 0;
                        V_SYNC = 0;
                    end
                    if (W_pause > 0) wp <= wp + 1;
                    
                end
                //--------------------------------------------------
                2: //Выдача данных
                begin   
                    if (W_pause > 0) wp <= wp + 1;
                    if (wp >= W_pause)
                    begin
                        wp <= 0;
                    end   
                
                    EN_O <= 0;  
                    if (wp == 0)
                    begin
                        DATA <= DATA + 1;
                        EN_O <= 1;                    
                                           
                        //========== Счетчик пикселей ==========//
                        x = x + 1;
                        if (x == W)
                        begin
                            x <= 0;
                            y <= y + 1;  
                            if (H_pause != 0)   
                            begin
                                STATE <= 3;
                                EN_O <= 0; 
                                H_SYNC <= 1;
                            end
                        end

                        //======================================//
                    end
                 
                end
                //--------------------------------------------------
                3:  //Пауза после строки
                begin          
                    hp = hp + 1;
                    if (hp == H_pause)
                    begin
                        hp <= 0;
                        H_SYNC <= 0;
                        EN_O <= 1;
                        STATE <= 2;
                    end                   
                                            
                    if (y == H)                
                    begin
                        V_SYNC  <= 1;
                        EN_O <= 0;
                        H_SYNC <= 1;
                        wp <= 0;
                        STATE <= 4;
                    end
                end
                //--------------------------------------------------
                4: //Пауза после кадров
                begin
                    f = f + 1;
                    if (f == FRAME_pause)
                    begin
                        f <= 0;
                        STATE <= 5;
                    end
                end
                //--------------------------------------------------
                5: //Подсчет кадров
                begin
                    numOfFrames <= numOfFrames + 1;
                    STATE <= 1;
                end
                //--------------------------------------------------
                6: //RESET
                begin
                    H_SYNC = 1;
                    EN_O = 0;
                    V_SYNC = 1;
                    DATA = 0;
                    x  = 0;
                    y  = 0;
                    wp = 0;
                    hp = 0;
                    f  = 0;
                    numOfFrames = 0;
                    
                    STATE = 1;
                end
            endcase
            //+++++++++++++++++++++++++++++++++++++++++++++++++++++//
            
        end
        else
        begin
            //не работает
        end
    end
    
//    ila_1 ilaFG(
//        .clk(CLK), // input wire clk
//        .probe0(DATA), // input wire [31:0]  probe0  
//        .probe1(STATE), // input wire [31:0]  probe1 
//        .probe2(y) // input wire [31:0]  probe2 
//    );
    
endmodule
