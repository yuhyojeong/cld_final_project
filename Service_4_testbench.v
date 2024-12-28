`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/26 14:28:26
// Design Name: 
// Module Name: Service_4_testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define SWIDTH 3 // State width
`define S0 3'b000
`define S1 3'b001
`define S2 3'b010
`define S3 3'b100

`define CWIDTH 16
`define C0 16'b0000000000000000
`define C1 16'b0000000000000001
`define C2 16'b0000000000000010
`define C3 16'b0000000000000011

`define RWIDTH 10
module Service_4_testbench(

    );
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg resetn;
    reg SPDT4;
    reg [15:0] current_time;
    reg [15:0] alarm_time;
    reg push_m;
    
    wire [2:0] alarm_state;
    wire mini_game;
    reg[9:0] SPDTs;
    reg[9:0] random_led;
    wire [15:0] count_state;

    wire [9:0] hot;
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        SPDT4 = 0;
        resetn = 1;
        current_time = 16'd0;
        alarm_time = 16'd10;
        push_m = 0;
        SPDTs = 10'b0;
        random_led = 10'b1;
        
        #200
        SPDT4 = 1;
        
        repeat (20) begin
            #CLK_PERIOD;
            current_time = current_time + 1;
        end
        
        #20
        push_m = 1;
        #CLK_PERIOD; // 한 클럭 주기 동안 유지
        push_m = 0;
    
        //minigame
        #100; // X
        SPDTs = 10'b0;
        random_led = 10'b1; 
        
        #100; // OX
        SPDTs = 10'b0;
        random_led = 10'b0;
        
        #100;
        SPDTs = 10'b0;
        random_led = 10'b1;
        
        #100; //OOX
        SPDTs = 10'b0001;
        random_led = 10'b0001;
        
        #100;
        SPDTs = 10'b100000;
        random_led = 10'b100000;
        
        #100;
        SPDTs = 10'b010000;
        random_led = 10'b100000;
        
    
        #100; //OOX
        SPDTs = 10'b100;
        random_led = 10'b100;
        
        #100;
        SPDTs = 10'b100000;
        random_led = 10'b100000;
        
        #100;
        SPDTs = 10'b10000000;
        random_led = 10'b10000000;
        
        #100;
        SPDTs = 10'b10000000;
        random_led = 10'b10000000;
        
        repeat (4) begin
            #(CLK_PERIOD);
            current_time = current_time + 1;
            SPDTs = random_led;
        end
    
        #1000;
        $finish;
    
    end

    // Service_4_alarm_check 모듈 인스턴스화
    Service_4_alarm_check uut_alarm_check (
        .clk(clk),
        .resetn(resetn),
        .SPDT4(SPDT4),
        .current(current_time),
        .alarm(alarm_time),
        .push_m(push_m),
        .mini_game(mini_game),
        .alarm_state(alarm_state)
    );

    // Service_4_minigame 모듈 인스턴스화
    Service_4_minigame uut_minigame (
        .clk(clk),
        .resetn(resetn),
        .alarm_state(alarm_state),
        .random_led(random_led),
        .SPDTs(SPDTs),
        .count_state(count_state),
        .mini_game(mini_game)
    );
    
    Service_4_random uut_random (
        .clk(clk),
        .resetn(resetn),
        .hot(hot)
    );
    // 출력 신호 모니터링
    initial begin
        $monitor("Time=%0t | alarm_state=%b | mini_game=%b | random_led=%b | SPDTs=%b | count_state=%d| random_num=%d",
                 $time, alarm_state, mini_game, random_led, SPDTs, count_state, hot);
    end

endmodule


