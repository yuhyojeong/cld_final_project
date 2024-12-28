`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoul National University. ECE. Logic Design
// Engineer: Potato / Huiwone Kim
// 
// Create Date: 2024/12/06 03:00:00
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

module top_module (
  input [4:0] push, // 5 push buttons
  input [14:0] spdt, 
  // 4 spdt switches for changing modes + 
  // 10 spdt switches for mini game +
  // 1 spdt switch for reset
  input clk_osc, 
  
  output [6:0] eSeg, // 7-segment control
  output [3:0] anode, // 7-segment control
  output [13:0] led, // 4 spdt leds + 10 mini game leds control
  output temp_led, // led for minigame only
  output clk_led // clock led control
);

  wire clk;
  wire sClk;
  wire s2clk;
  wire s10clk;
  wire reset;

  wire [3:0] which_seg_on1;
  wire [3:0] which_seg_on2;
  wire finish1;

  wire [15:0] num1;
  wire [15:0] num3;
  wire [15:0] num4;

  wire [15:0] alarm_time;
  wire [2:0] alarm_state;
  wire [15:0] current_time;
  wire [3:0] currentNum;
  wire alarm_on;
  wire [1:0] iter;
  
  wire [9:0] mini_game_led;

  make_clk make_clk_(
    .clk_osc(clk_osc),
    .RESET(spdt[0]),
    
    .iter(iter),
    .clk(clk), // once in 1 second
    .sClk(sClk), // once in 1 milli-second
    .s2clk(s2clk), // once in 2 seconds
    .s10clk(s10clk), // once in 1/100 seconds
    .reset(reset)
  );

  Service_1_time_set service_1(
    .clk(clk),
    .reset(reset),
    .spdt1(spdt[14]),
    .push_u(push[0]),
    .push_d(push[1]),
    .push_l(push[2]),
    .push_r(push[3]),
    .sel(which_seg_on1),
    .finish1(finish1),
    .num(num1)
  );

  Service_2_alarm_set service_2(
    .clk(clk),
    .reset(reset),
    .spdt2(spdt[13]),
    .push_u(push[0]),
    .push_d(push[1]),
    .push_l(push[2]),
    .push_r(push[3]),
    .sel(which_seg_on2),
    .alarm(alarm_time)
  );

  Service_3_StopWatch service_3(
    .clk(s10clk),
    .reset(reset),
    .SPDT3(spdt[12]),
    .push_m(push[4]),
    .clk_count(num3)
  );

  Service_4 service_4(
    .s2clk(s2clk),
    .reset(reset), 
    .SPDT4(spdt[11]), 
    .SPDTs(spdt[10:1]),
    .push_m(push[4]),
    .current(current_time),
    .alarm(alarm_time),
    .alarm_state(alarm_state),
    .count_state(num4),
    .SPDT_LED(mini_game_led)
  );

  set_led set_led(
    .clk(clk),
    .reset(reset),
    .service(spdt[14:11]),
    .alarm_state(alarm_state),
    .mini_game_led(mini_game_led),

    .led(led),
    .alarm_on(alarm_on),
    .temp_led(temp_led),
    .clk_led(clk_led)
  );

  set_anode set_anode(
    .clk(clk),
    .sClk(sClk),
    .reset(reset),
    .iter(iter),
    .num1(num1),
    .num3(num3),
    .num4(num4),
    .SPDT1(spdt[14]),
    .SPDT2(spdt[13]),
    .SPDT3(spdt[12]),
    .alarm_time(alarm_time),
    .which_seg_on1(which_seg_on1),
    .which_seg_on2(which_seg_on2),
    .alarm_state(alarm_state),
    .current_time(current_time),

    .anode(anode),
    .currentNum(currentNum)
  );

  store_time store_time(
    .clk(clk),
    .reset(reset),
    .finish1(finish1),
    .num1(num1),
    
    .current_time(current_time)
  );

  NumTo7Segment numTo7Seg (
    .number(currentNum),
    .reset(reset),
    .sClk(sClk),
    .alarm_on(alarm_on),
    .seg(eSeg)
  );

endmodule