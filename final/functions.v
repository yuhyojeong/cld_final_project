`timescale 1ns / 1ps

module store_time(
  input clk,
  input reset,
  input finish1,
  input [15:0] num1,

  output reg [15:0] current_time
);

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



module set_led(
  input clk,
  input reset,
  input [3:0] service,
  input [2:0] alarm_state,
  input [9:0] mini_game_led,

  output [13:0] led,
  output temp_led,
  output reg alarm_on,
  output clk_led 
);

  assign clk_led = ~clk;

  reg is_count_state;
  reg [13:0] led_clk;
  reg temp_led_clk;

  always @(posedge clk or posedge reset) begin
      if (reset) begin
          led_clk <= 0;
          is_count_state <= 0;
          alarm_on <= 0;
          temp_led_clk <= 0;
      end else begin
          if (service[0]) begin //service4
              case(alarm_state)
              3'b000: begin
                led_clk[9:0] <= 0;
                is_count_state <= 0;
                alarm_on <= 0;
                temp_led_clk <= 0;
              end
              3'b001: begin
                led_clk <= 0;
                is_count_state <= 0;
                alarm_on <= 0;
                temp_led_clk <= 0;
              end
              3'b010: begin
                is_count_state <= 0;
                led_clk <= 14'b1111_1111_1111_11;
                alarm_on <= 1;
                temp_led_clk <= 1;
              end
              3'b100: begin
                led_clk[9:0] <= mini_game_led;
                led_clk[13:10] <= 0;
                is_count_state <= 1;
                alarm_on <= 0;
                temp_led_clk <= 0;
              end
              default: begin
                led_clk <= 0;
                is_count_state <= 0;
                alarm_on <= 0;
                temp_led_clk <= 0;
              end
          endcase
          end else begin
            temp_led_clk <= 0;
            led_clk[9:0] <= 0; // 10 leds above mini game switches
            led_clk[13:10] <= service; // 4 leds above spdt switches
          end
      end
  end
  
  assign led = (alarm_on & !clk) ? 14'd0 : led_clk;
  assign temp_led = (alarm_on & !clk) ? 1'b0 : temp_led_clk;

endmodule



module set_anode(
  input clk,
  input sClk,
  input reset,
  input [1:0] iter,
  input [15:0] num1,
  input [15:0] num3,
  input [15:0] num4,
  input SPDT1,
  input SPDT2,
  input SPDT3,
  input SPDT4,
  input [15:0] alarm_time,
  input [2:0] alarm_state,
  input [3:0] which_seg_on1,
  input [3:0] which_seg_on2,
  input [15:0] current_time,

  output reg [3:0] anode,
  output reg [3:0] currentNum
);

    // update segments
  always @(posedge sClk or posedge reset) begin
    if (reset) begin
        currentNum <= 0;
        anode <= 4'b1111;
    end else begin
      case (iter)
        2'd0: begin // right-est segment
            if (SPDT1 & which_seg_on1 == 4'b0001) anode <= ~(which_seg_on1 & {4{clk}});
            else if (SPDT2 & which_seg_on2 == 4'b0001) anode <= ~(which_seg_on2 & {4{clk}});
            else if (SPDT4 & alarm_state == 3'b010) anode <= ~(4'b0001 & {4{clk}});
            else anode <= 4'b1110;
            currentNum <= SPDT1 ? num1[7:4] : ( SPDT2 ? alarm_time[7:4] : (SPDT3 ? num3[7:4] : (alarm_state == 3'b100 ? num4[7:4] : current_time[7:4])));
        end
        2'd1: begin
            if (SPDT1 & which_seg_on1 == 4'b0010) anode <= ~(which_seg_on1 & {4{clk}});
            else if (SPDT2 & which_seg_on2 == 4'b0010) anode <= ~(which_seg_on2 & {4{clk}});
            else if (SPDT4 & alarm_state == 3'b010) anode <= ~(4'b0010 & {4{clk}});
            else anode <= 4'b1101;
            currentNum <= SPDT1 ? num1[11:8] : ( SPDT2 ? alarm_time[11:8] : (SPDT3 ? num3[11:8] : (alarm_state == 3'b100 ? num4[11:8] : current_time[11:8])));
        end
        2'd2: begin
            if (SPDT1 & which_seg_on1 == 4'b0100) anode <= ~(which_seg_on1 & {4{clk}});
            else if (SPDT2 & which_seg_on2 == 4'b0100) anode <= ~(which_seg_on2 & {4{clk}});
            else if (SPDT4 & alarm_state == 3'b010) anode <= ~(4'b0100 & {4{clk}});
            else anode <= 4'b1011;
            currentNum <= SPDT1 ? num1[15:12] : ( SPDT2 ? alarm_time[15:12] : (SPDT3 ? num3[15:12] : (alarm_state == 3'b100 ? num4[15:12] : current_time[15:12])));
        end
        2'd3: begin // left-est segment
            if (SPDT1 & which_seg_on1 == 4'b1000) anode <= ~(which_seg_on1 & {4{clk}});
            else if (SPDT2 & which_seg_on2 == 4'b1000) anode <= ~(which_seg_on2 & {4{clk}});
            else if (SPDT4 & alarm_state == 3'b010) anode <= ~(4'b1000 & {4{clk}});
            else anode <= 4'b0111;
            currentNum <= SPDT1 ? num1[3:0] : ( SPDT2 ? alarm_time[3:0] : (SPDT3 ? num3[3:0] : (alarm_state == 3'b100 ? num4[3:0] : current_time[3:0])));
        end
        default: begin
            anode <= 4'b1111;
            currentNum <= 4'b0000; // 0 for default
        end
      endcase
      // on/off
      // spdt4
    end
  end


endmodule

module NumTo7Segment(
    input [3:0] number,
    input reset,
    input sClk,
    input alarm_on,
    output reg [6:0] seg
);
    always @(posedge sClk or posedge reset) begin
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