`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoul National University. ECE. Logic Design
// Engineer: Huiwone Kim
// 
// Create Date: 2024/11/26 16:25:00
// Design Name: 
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
//////////////////////////////////////////////////////////////////////////////////

// define constants
`define SERVICERESET 4'b0000 // reset
`define SERVICE1 4'b1000 // spdt switch1 on - service 1
`define SERVICE2 4'b0100 // spdt switch2 on - service 2
`define SERVICE3 4'b0010 // spdt switch3 on - service 3
`define SERVICE4 4'b0001 // spdt switch4 on - service 4

// Main module
module Main(
    input [4:0] push, // 5 push buttons
    input [14:0] spdt, 
    // 4 spdt switches for changing modes + 
    // 10 spdt switches for mini game +
    // 1 spdt switch for reset
    input clk_osc, 
    
    output reg [6:0] eSeg, // 7-segment control
    output reg [3:0] anode, // 7-segment control
    output reg [13:0] led, // 4 spdt leds + 10 mini game leds control
    output reg temp_led, // led for minigame only
    output clk_led // clock led control
    );

    wire RESET = spdt[0]; // 1 spdt switch for reset
    wire reset;
    wire clk;

    // make sClk
    wire sClk;
    wire [1:0] iter; // wire for anode handling
    reg [17:0] counter = 18'd0;

    always @(posedge clk_osc or posedge reset) begin
        if (reset) counter <= 0;
        else counter <= counter + 1;
    end
    
    assign sClk = counter[15]; //counter[1];
    assign iter = counter[17:16]; // counter[3:2]
    // assign sClk = counter[1];
    // assign iter = counter[3:2];
    
    // connect with make_clk module
    make_clk make_clk_(
        .clk_osc(clk_osc),//in
        .RESET(RESET), 
        .clk(clk),//for 1s clock
        .reset(reset)
    );

    // assign push buttons
    wire push_u = push[0]; // is push up button pressed
    wire push_d = push[1]; // is push down button pressed
    wire push_l = push[2]; // is push left button pressed
    wire push_r = push[3]; // is push right button pressed
    wire push_m = push[4]; // is push middle button pressed

    // finish wires
    
    wire [6:0] eSegWire; // wire that connects with eSeg
    reg [15:0] current_time = 0;
    reg [3:0] currentNum;


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 0;
            temp_led <= 0;
        end else begin
            led = spdt[14:1];
        end
    end
    assign clk_led = sClk;



    // update segments
    always @(posedge sClk or posedge reset) begin
        if (reset) begin
            currentNum <= 0;
            anode <= 4'b1111;
        end else begin
            case (iter)
                2'd0: begin // right-est segment
                    anode <= 4'b1011;
                    currentNum <= current_time[3:0];
                end
                2'd1: begin
                    anode <= 4'b0111;
                    currentNum <= current_time[7:4];
                end
                2'd2: begin
                    anode <= 4'b1110;
                    currentNum <= current_time[11:8];
                end
                2'd3: begin // left-est segment
                    anode <= 4'b1101;
                    currentNum <= current_time[15:12];
                end
                default: begin
                    anode <= 4'b1111;
                    currentNum <= 4'b0000; // 0 for default
                end
            endcase
        end
    end
    
    // use the NumTo7Segment module to convert number to 7-segment
    NumTo7Segment numTo7Seg (
        .number(currentNum),
        .reset(reset),
        .clk_osc(sClk),
        .alarm_on(alarm_on),
        .seg(eSegWire)
    );
    
    always @(posedge sClk or posedge reset) begin 
        if (reset) eSeg <= 0;
        else eSeg <= eSegWire;
    end
    
    // update current_time
    always @(posedge clk or posedge reset) begin
        if (reset) current_time <= 16'd0;
        // if current_time is not undefined, update current_time
        else begin
            if (current_time == 16'b0101_1001_0101_1001) begin
                // Reset to 0000 when current_time is 5959 (59:59)
                current_time <= 16'd0;
            end else begin
                if (current_time == 16'b0101_1001_0101_1001) begin 
                    // Reset to 0000 when current_time is 5959 (59:59)
                    current_time <= 0;
                end else if(current_time[11:0] == 12'b1001_0101_1001) begin
                    // x900
                    current_time[15:12] <= current_time[15:12] + 1;
                    current_time[11:8] <= 0;
                end else if (current_time[7:0] == 8'b0101_1001) begin
                    // If the lower 8 bits of current_time are 59, 
                    // current_time[15:8] + 1 and current_time[7:0] = 0
                    current_time[15:8] <= current_time[15:8] + 1;
                    current_time[7:0] <= 0;
                end else if(current_time[3:0] == 4'b1001) begin
                    // xxx9
                    current_time[3:0] <= 0;
                    current_time[7:4] <= current_time[7:4] + 1;
                end else begin
                    // Otherwise, just do + 1
                    current_time <= current_time + 1;
                end
            end
        end
    end
endmodule

module NumTo7Segment(
    input [3:0] number,
    input reset,
    input clk_osc,
    input alarm_on,
    output reg [6:0] seg
);
    always @(posedge clk_osc or posedge reset) begin
        if (reset) seg <= 7'b1111111;
        else if (alarm_on) seg <= ~7'b1111111;
        else begin
            case (number)
                4'b0000: seg <= ~7'b0111111; // 0
                4'b0001: seg <= ~7'b0000110; // 1
                4'b0010: seg <= ~7'b1011011; // 2
                4'b0011: seg <= ~7'b1001111; // 3
                4'b0100: seg <= ~7'b1100110; // 4
                4'b0101: seg <= ~7'b1101101; // 5
                4'b0110: seg <= ~7'b1111101; // 6
                4'b0111: seg <= ~7'b0000111; // 7
                4'b1000: seg <= ~7'b1111111; // 8
                4'b1001: seg <= ~7'b1101111; // 9
                default: seg <= ~7'b0000000; // Blank for invalid input
            endcase
        end
    end
endmodule