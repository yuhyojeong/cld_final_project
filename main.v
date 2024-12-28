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
// Description: NOT USED ANYMORE
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
// ################################ USE TOP_MODULE.V & FUNCTIONS.V INSTEAD ################################
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

    // interpret spdt switches
    wire [3:0] spdt_service = spdt[14:11]; // 4 spdt switches for changing modes
    wire [9:0] spdt_mini_game = spdt[10:1]; // 10 spdt switches for mini game
    wire RESET = spdt[0]; // 1 spdt switch for reset
    wire reset;
    wire clk;

    // make sClk -> period = 1s
    wire sClk;
    // make s2Clk -> 2 times sClk, period = 2s
    wire s2Clk;
    wire [1:0] iter; // wire for anode handling
    reg [17:0] counter = 18'd0;

    always @(posedge clk_osc or posedge reset) begin
        if (reset) counter <= 0;
        else counter <= counter + 1;
    end
    
    assign sClk = counter[15]; //counter[1];
    assign iter = counter[17:16]; // counter[3:2]
    
    // connect with make_clk module
    make_clk make_clk_(
        .clk_osc(clk_osc),
        .RESET(RESET), 
        .clk(clk),
        .s2Clk(s2Clk),
        .reset(reset)
    );

    // interpret leds
    reg [3:0] spdt_led = 0; // 4 leds above spdt switches
    wire [9:0] mini_game_led; // 10 leds above mini game switches
    
    // assign service buttons 
    wire SPDT1, SPDT2, SPDT3, SPDT4;
    assign SPDT1 = reset ? 0 : spdt_service[3];
    assign SPDT2 = reset ? 0 : spdt_service[2];
    assign SPDT3 = reset ? 0 : spdt_service[1];
    assign SPDT4 = reset ? 0 : spdt_service[0];

    // assign push buttons
    wire push_u = push[0]; // is push up button pressed
    wire push_d = push[1]; // is push down button pressed
    wire push_l = push[2]; // is push left button pressed
    wire push_r = push[3]; // is push right button pressed
    wire push_m = push[4]; // is push middle button pressed

    // finish wires
    wire finish1;
    wire finish2;
    wire finish3;
    wire finish4;
    
    reg alarm_on;
    reg is_count_state = 0; // 1 if we show count_state
    wire [2:0] alarm_state; // state 1. alarm on, state 2. minigame, state 3. alarm off.
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 0;
            is_count_state <= 0;
            alarm_on <= 0;
            temp_led <= 0;
        end else if (spdt_service == `SERVICE4) begin
            case(alarm_state)
                3'b000: begin
                    is_count_state <= 0;
                    alarm_on <= 0;
                    temp_led <= 0;
                    led[9:0] <= 0;
                end
                3'b001: begin
                    is_count_state <= 0;
                    alarm_on <= 0;
                    temp_led <= 0;
                    led <= 0;
                end
                3'b010: begin
                    is_count_state <= 0;
                    led <= 14'b11111111111111;
                    alarm_on <= 1;
                    temp_led <= 1;
                end
                3'b100: begin
                    is_count_state <= 1;
                    led[13:10] <= 0;
                    led[9:0] <= mini_game_led;
                    alarm_on <= 0;
                    temp_led <= 0;
                end
                default: begin
                    is_count_state <= 0;
                    alarm_on <= 0;
                    temp_led <= 0;
                    led <= 0;
                end
            endcase
        end else begin
            case(spdt_service)
                `SERVICERESET: spdt_led <= 4'b0000;
                `SERVICE1: spdt_led <= 4'b1000;
                `SERVICE2: spdt_led <= 4'b0100;
                `SERVICE3: spdt_led <= 4'b0010;
                default: spdt_led <= 4'b0000;
            endcase
            led[13:10] <= spdt_led; // 4 leds above spdt switches
            led[9:0] <= 0; // 10 leds above mini game switches
        end
    end

    // store current time and alarm time
    reg [15:0] current_time = 0; // current time
    wire [15:0] alarm_time; // alarm time

    wire [3:0] which_seg_on1, which_seg_on2; // one-hot style, tells which location segment is on

    wire [6:0] eSegWire; // wire that connects with eSeg

    // clock tick indicator led signal
    assign clk_led = clk;

    // wire for the output number array for the 7-segment
    wire [15:0] num3, num4;
    
    // TODO: add initial state 0000, with resetn

    reg [3:0] currentNum;
    wire [15:0] num1;

    // instantiate modules
    Service_1_time_set service_1(
        .clk(clk),
        .reset(reset),
        .spdt1(SPDT1),
        .push_u(push_u),
        .push_d(push_d),
        .push_l(push_l),
        .push_r(push_r),
        .sel(which_seg_on1),
        .finish1(finish1),
        .num(num1)
    );
    Service_2_alarm_set service_2(
        .clk(clk),
        .reset(reset),
        .spdt2(SPDT2),
        .push_u(push_u),
        .push_d(push_d),
        .push_l(push_l),
        .push_r(push_r),
        .sel(which_seg_on2),
        .finish2(finish2),
        .alarm(alarm_time)
    );
    Service_3_StopWatch service_3(
        .clk(sClk),
        .reset(reset),
        .SPDT3(SPDT3),
        .push_m(push_m),
        .clk_count(num3)
    );
    Service_4 service_4(
        .clk(clk), 
        .reset(reset), 
        .SPDT4(SPDT4), 
        .SPDTs(spdt_mini_game),
        .push_m(push_m),
        .current(current_time),
        .alarm(alarm_time),
        .alarm_state(alarm_state),
        .count_state(num4),
        .SPDT_LED(mini_game_led),
        .finish4(finish4)
    );
    
//    always @(num1) begin 
//        current_time = num1;
//    end
    
    
    reg [3:0] anode_temp;
    // update segments
    always @(posedge sClk or posedge reset) begin
        if (reset) begin
            anode_temp <= 0;
            currentNum <= 0;
            anode <= 4'b1111;
        end else begin
            case (iter)
                2'd0: begin // right-est segment
                    anode_temp <= 4'b0111;
                    currentNum <= SPDT1 ? num1[3:0] : ( SPDT2 ? alarm_time[3:0] : (SPDT3 ? num3[3:0] : (is_count_state ? num4[3:0] : current_time[3:0])));
                end
                2'd1: begin
                    anode_temp <= 4'b1110;
                    currentNum <= SPDT1 ? num1[7:4] : ( SPDT2 ? alarm_time[7:4] : (SPDT3 ? num3[7:4] : (is_count_state ? num4[7:4] : current_time[7:4])));
                end
                2'd2: begin
                    anode_temp <= 4'b1101;
                    currentNum <= SPDT1 ? num1[11:8] : ( SPDT2 ? alarm_time[11:8] : (SPDT3 ? num3[11:8] : (is_count_state ? num4[11:8] : current_time[11:8])));
                end
                2'd3: begin // left-est segment
                    anode_temp <= 4'b1011;
                    currentNum <= SPDT1 ? num1[15:12] : ( SPDT2 ? alarm_time[15:12] : (SPDT3 ? num3[15:12] : (is_count_state ? num4[15:12] : current_time[15:12])));
                end
                default: begin
                    anode_temp <= 4'b1111;
                    currentNum <= 4'b0000; // 0 for default
                end
            endcase
            // on/off
           if (SPDT1) anode <= (which_seg_on1 == ~anode) ? ~(which_seg_on1 & clk) : anode_temp;
           else if (SPDT2) anode <= (which_seg_on2 == ~anode) ? ~(which_seg_on2 & clk) : anode_temp;
            // spdt4
            anode <= anode_temp;
//            anode <= 4'b1110; // test
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
    always @(posedge clk or posedge reset or posedge finish1) begin
        if (reset) current_time <= 16'd0;
        // if current_time is not undefined, update current_time
        else begin
            if (finish1) current_time <= num1;
            else begin
                if (current_time == 16'b0101_1001_0101_1001) begin 
                    // Reset to 0000 when current_time is 5959 (59:59)
                    current_time <= 0;
                end else if(current_time[11:0] == 12'b1001_0101_1001) begin
                    // x900
                    current_time[15:12] <= current_time[15:12] + 1;
                    current_time[11:0] <= 0;
                end else if (current_time[7:0] == 8'b0101_1001) begin
                    // If the lower 8 bits of current_time are 59, 
                    // current_time[15:8] + 1 and current_time[7:0] = 0
                    current_time[15:8] <= current_time[15:8] + 1;
                    current_time[7:0] <= 0;
                end else if(current_time[3:0] == 4'b1001) begin
                    // xxx9
                    current_time[7:4] <= current_time[7:4] + 1;
                    current_time[3:0] <= 0;
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