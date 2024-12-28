`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoul National University. ECE. Logic Design
// Engineer: HyoJeong Yu
// 
// Create Date: 2024/11/30
// Design Name: Service_2_alarm_set
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

module Service_2_alarm_set (
    input clk,
    input reset,
    input spdt2,
    input push_u,
    input push_d,
    input push_l,
    input push_r,

    output reg [3:0] sel,
    output reg [15:0] alarm // 15:12 11:8 7:4 3:0 = min min sec sec, each 4bit 0-9
);

  reg [1:0] seg; // 3 2 1 0 left to right
  reg finish2;
  reg start;

  // select segment
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      seg <= 0;
      sel <= 0;
    end
    else begin
      if (spdt2) begin
        if (sel == 0) begin
          sel <= 4'b1000; // init
          seg <= 3;
        end
        else begin
          if (push_l) begin
            seg <= seg + 1;
            sel <= (sel == 4'b1000) ? 4'b0001 : sel << 1;
          end
          else if (push_r) begin
            seg <= seg - 1;
            sel <= (sel == 4'b0001) ? 4'b1000 : sel >> 1;
          end
        end
      end
      if (finish2) begin
        sel <= 4'b1000;
        seg <= 3;
      end
    end
  end

  // set time
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      alarm <= 0;
    end
    else begin
      if (spdt2) begin
        if (sel) begin
            if (push_d) begin
            if (seg[0]) alarm[4*seg+:4] <= (alarm[4*seg+:4] == 0) ? 5 : alarm[4*seg+:4] - 1;
            else alarm[4*seg+:4] <= (alarm[4*seg+:4] == 0) ? 9 : alarm[4*seg+:4] - 1;
            end else if (push_u) begin
              if (seg[0]) alarm[4*seg+:4] <= (alarm[4*seg+:4] == 5) ? 0 : alarm[4*seg+:4] + 1;
              else alarm[4*seg+:4] <= (alarm[4*seg+:4] == 9) ? 0 : alarm[4*seg+:4] + 1;
            end
        end
      end
    end
  end
  
  always @(posedge clk or posedge reset) begin
    if (reset) begin
        finish2 <= 0;
        start <= 0;
    end else begin
        if (spdt2) start <= 1;
        
        if (finish2) finish2 <= 0;
        else if (!spdt2 & start) begin
            finish2 <= 1;
            start <= 0;
        end
    end
  end
endmodule

