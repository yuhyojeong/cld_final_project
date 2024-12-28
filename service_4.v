`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoul National University. ECE. Logic Design
// Engineer: Hyewoo Jeong
//
// Create Date: 2024/11/10 17:49:08
// Design Name: Service_4_alarm_check
// Module Name:
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
//////////////////////////////////////a////////////////////////////////////////////

// define state assignment - binary
`define SWIDTH 3 // State width
//`define S0 3'b000
//`define S1 3'b001
//`define S2 3'b010
//`define S3 3'b100

`define CWIDTH 16
`define C0 16'b0000000000000000
`define C1 16'b0000000000000001
`define C2 16'b0000000000000010
`define C3 16'b0000000000000011

`define RWIDTH 10
`define RN0

module Service_4(
    input clk,
    input s2clk,
    input reset,
    input SPDT4, // Buttons
    input [9:0] SPDTs,
    input push_m,
    
    input [15:0] current, // current_time
    input [15:0] alarm, // alarm_time
    
    output [2:0] alarm_state, // state 1. alarm on, state 2. minigame, state 3. alarm off.
    output [15:0] count_state,
    output [9:0] SPDT_LED
);
    wire finish4;
    
    Service_4_alarm_check uut_alarm_check (
        .s2clk(clk),
        .reset(reset),
        .SPDT4(SPDT4),
        .current(current),
        .alarm(alarm),
        .push_m(push_m),
        .mini_game(finish4),
        .alarm_state(alarm_state)//output
    );

    // Service_4_minigame
    Service_4_minigame uut_minigame (
        .s2clk(s2clk),
        .reset(reset),
        .alarm_state(alarm_state),
        .random_led(SPDT_LED),//input
        .SPDTs(SPDTs),//input
        .count_state(count_state),//output
        .mini_game(finish4)//done
    );
    
    Service_4_random uut_random (
        .s2clk(s2clk),
        .reset(reset),
        .hot(SPDT_LED)
    );
    
endmodule
    

module Service_4_alarm_check(
    input s2clk,
    input reset, // reset
    input SPDT4, // input string (1bit)
    input [15:0] current, // current_time
    input [15:0] alarm, // alarm_time
    input push_m,
    input mini_game,

    output reg [2:0] alarm_state // state 1. alarm on, state 2. minigame, state 3. alarm off.
    
    );
    //000 => basic state , 001 => SPDT4 on, 010 => comparator = 1(alarm_on), 100 => minigame

    always @(posedge s2clk or posedge reset) begin
        if (reset|!SPDT4) alarm_state <= `S0;    
        else begin
            if (SPDT4) begin// when time = alarm.
               case(alarm_state)
                   `S0: alarm_state <= `S1;
                   `S1: alarm_state <= ((current == alarm) ? `S2 : `S1);
                   `S2: alarm_state <= (push_m ? `S3 : `S2);
                   `S3: alarm_state <= (mini_game ? `S1 : `S3);
                   default: alarm_state <= `S1;
               endcase
            end
            else alarm_state <= `S0;
        end
    end
endmodule

    
module Service_4_minigame(
    input s2clk,
    input reset,
    input [2:0] alarm_state,
    input [9:0] random_led,
    input [9:0] SPDTs,

    output reg [15:0] count_state,
    output reg mini_game
);
    //
//    wire cmp_game;
    
    // random_led?? SPDTs ??
//    assign cmp_game = (random_led == SPDTs);
    
    // Combinational logic for next_count and next_mini_game
    always @(posedge s2clk or posedge reset) begin
        if (reset) begin
            count_state <= `C0;
            mini_game <= 1'b0;
        end
        else begin
           case (alarm_state)
               `S3: begin
                   case (count_state)
                       `C0: begin
                           count_state <= (random_led == SPDTs) ? `C1 : `C0;
                           mini_game <= 1'b0;
                       end
                       `C1: begin
                           count_state <= (random_led == SPDTs) ? `C2 : `C0;
                           mini_game <= 1'b0;
                       end
                       `C2: begin
                           count_state <= (random_led == SPDTs) ? `C3 : `C0;
                           mini_game <= 1'b0;
                       end
                       `C3: begin
                           count_state <= `C0;
                           mini_game <= 1'b1;
                       end
                       
                       default: begin
                           count_state <= `C0;
                           mini_game <= 1'b0;
                       end
                    endcase
               end
           default: begin
                count_state <= `C0;
                mini_game <= 1'b0;
                end
           endcase
        end
    end    
    
endmodule


module Service_4_random
    (
    input s2clk,
    input reset,
    output reg [9:0] hot // Declare hot as reg
    );

    wire feedback_value;
    reg [3:0] q;    
    reg [3:0] r_reg = 4'b0011; // LFSR initial value
    reg [3:0] increment;

    assign feedback_value = r_reg[3] ^ r_reg[1]; // Feedback value
    
    always @(posedge s2clk or posedge reset) begin
        if (reset) begin
            r_reg <=  4'b0011; // Use non-blocking assignment
            increment <= 4'b0001;
        end else begin
            r_reg <= {r_reg[2:0], feedback_value} + increment; // Shift & feedback
            increment <= (increment == 4'b0001) ? 4'b0011 : 4'b0001;
            q <= (r_reg >= 4'b1001) ? (r_reg - 4'b1001) : r_reg;
        end
    end

//    assign q <= (r_reg >= 4'b1001) ? (r_reg - 4'b1001) : r_reg; //(r_reg >= 4'b1001) ? r_reg - 4'b1001 : r_reg; // Adjust q calculation

    always @(posedge s2clk or posedge reset) begin
        if (reset) hot <= 0;
        else hot <= 10'b0000000001 << q;
    end
endmodule
