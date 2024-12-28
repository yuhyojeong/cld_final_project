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
    output clk_led // clock led control
    );

    // interpret spdt switches
    wire [3:0] spdt_service = spdt[14:11]; // 4 spdt switches for changing modes
    wire [9:0] spdt_mini_game = spdt[10:1]; // 10 spdt switches for mini game
    wire RESET = spdt[0]; // 1 spdt switch for reset
    wire reset;
    wire clk;

    // make sClk
    wire sClk;
    wire [1:0] iter; // wire for anode handling
    reg [17:0] counter = 18'd0;
    assign iter = counter[4:3]; ///////////////////////////////////////////////////////////////////////CHANGED
    always @(posedge clk_osc or posedge reset) begin
        if (reset) counter <= 0;
        else counter <= counter + 1;
    end

    assign sClk = counter[2]; ////////////////////////////////////////////////////////////////////////////CHANGED

    // connect with make_clk module
    make_clk make_clk_(
        .clk_osc(clk_osc),
        .RESET(RESET), 
        .clk(clk),
        .reset(reset)
    );

    // interpret leds
    reg [3:0] spdt_led = 0; // 4 leds above spdt switches
    wire [9:0] mini_game_led = 0; // 10 leds above mini game switches
    
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

    // turn off spdt_leds when it is finished
    always @(*) begin
        if (reset) begin
            spdt_led = 0;
            led = 0;
        end
        else begin
            if (finish1 || finish2 || finish3 || finish4) begin
                spdt_led = 4'b0000;
            end else begin
                case(spdt_service)
                    `SERVICERESET: spdt_led = 4'b0000;
                    `SERVICE1: spdt_led = 4'b1000;
                    `SERVICE2: spdt_led = 4'b0100;
                    `SERVICE3: spdt_led = 4'b0010;
                    `SERVICE4: spdt_led = 4'b0001;
                    default: spdt_led = 4'b0000;
                endcase
            end
            led[13:10] = spdt_led; // 4 leds above spdt switches
            led[9:0] = mini_game_led; // 10 leds above mini game switches
        end
    end
    
    reg is_count_state = 0; // 1 if we show count_state

    // store current time and alarm time
    reg [15:0] current_time; // current time
    wire [15:0] alarm_time; // alarm time

    wire [2:0] alarm_state; // state 1. alarm on, state 2. minigame, state 3. alarm off.

    wire [3:0] which_seg_on1, which_seg_on2; // one-hot style, tells which location segment is on

    wire [6:0] eSegWire; // wire that connects with eSeg

    // clock tick indicator led signal
    assign clk_led = clk;

    // wire for the output number array for the 7-segment
    wire [15:0] num1, num3, num4;
    
    // TODO: add initial state 0000, with resetn

    reg [3:0] currentNum;

    // handle alarm_state
    always @(*) begin
        if (reset) is_count_state = 0;
        else begin
            case(alarm_state)
                3'b000: begin
                    is_count_state = 0;
                end
                3'b001: begin
                    is_count_state = 0;
                end
                3'b010: begin
                    is_count_state = 0;
                    led <= 14'b11111111111111;
                    eSeg <= 7'b1111111;
                end
                3'b100: begin
                    is_count_state = 1;
                end
                default: begin
                    is_count_state = 0;
                end
            endcase
        end
    end

    always @(*) begin 
        if (reset) eSeg <= 0;
        else eSeg <= eSegWire;
    end

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
        .clk(clk_osc),
        .reset(reset),
        .SPDT3(SPDT3),
        .push_m(push_m),
        .segments(num3),
        .finish3(finish3)
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

    // update segments
    always @(posedge sClk or posedge reset) begin
        if (reset) begin
            anode <= 0;
            currentNum <= 0;
        end else begin
            case (iter)
                2'd0: begin // right-est segment
                    anode <= 4'b1110;
                    currentNum <= SPDT1 ? num1[3:0] : (SPDT3 ? num3[3:0] : (is_count_state ? num4[3:0] : 0));
                end
                2'd1: begin
                    anode <= 4'b1101;
                    currentNum <= SPDT1 ? num1[7:4] : (SPDT3 ? num3[7:4] : (is_count_state ? num4[7:4] : 0));
                end
                2'd2: begin
                    anode <= 4'b1011;
                    currentNum <= SPDT1 ? num1[11:8] : (SPDT3 ? num3[11:8] : (is_count_state ? num4[11:8] : 0));
                end
                2'd3: begin // left-est segment
                    anode <= 4'b0111;
                    currentNum <= SPDT1 ? num1[15:12] : (SPDT3 ? num3[15:12] : (is_count_state ? num4[15:12] : 0));
                end
                default: begin
                    anode <= 4'b1111;
                    currentNum <= 4'b0000; // 0 for default
                end
            endcase
            if(which_seg_on1 == anode) anode <= (!(which_seg_on1) & clk);
            if(which_seg_on2 == anode) anode <= (!(which_seg_on2) & clk);
        end
    end
    
    // use the NumTo7Segment module to convert number to 7-segment
    NumTo7Segment numTo7Seg (
        .number(currentNum),
        .reset(reset),
        .seg(eSegWire)
    );

    // update current_time
    always @(posedge clk or posedge reset) begin
        if (reset) current_time <= 16'd0;
        // if current_time is not undefined, update current_time
        else begin
            if (current_time == 16'd5959) begin
                // Reset to 0000 when current_time is 5959 (59:59)
                current_time <= 16'd0;
            end else if (current_time[7:0] == 8'd59) begin
                // If the lower 8 bits of current_time are 59, 
                // current_time[15:8] + 1 and current_time[7:0] = 0
                current_time[15:8] <= current_time[15:8] + 1;
                current_time[7:0] <= 8'd0;
            end else begin
                // Otherwise, just do + 1
                current_time <= current_time + 1;
            end
        end
    end
endmodule

module NumTo7Segment(
    input [3:0] number,
    input reset,
    output reg [6:0] seg
);
    always @(*) begin
        if (reset) seg = 0;
        else begin
            case (number)
                4'b0000: seg = 7'b0111111; // 0
                4'b0001: seg = 7'b0000110; // 1
                4'b0010: seg = 7'b1011011; // 2
                4'b0011: seg = 7'b1001111; // 3
                4'b0100: seg = 7'b1100110; // 4
                4'b0101: seg = 7'b1101101; // 5
                4'b0110: seg = 7'b1111101; // 6
                4'b0111: seg = 7'b0000111; // 7
                4'b1000: seg = 7'b1111111; // 8
                4'b1001: seg = 7'b1101111; // 9
                default: seg = 7'b0000000; // Blank for invalid input
            endcase
        end
    end
endmodule
