`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:    Seoul National University. ECE. Logic Design
// Engineer:   Group 8
// 
// Create Date:    2024/12/05
// Design Name:    
// Module Name:    make_clk 
// Project Name:   
// Description:    
//
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
module make_clk(
    input clk_osc,
    input RESET,
    output [1:0] iter,
    output reg clk,
    output sClk,
    output s2clk,
    output s10clk,
    output reset
    );
    
    
    reg [26:0] counter;
    reg [17:0] counter_s;
    reg [1:0] counter2;
    reg [3:0] counter10 = 0;
        
    // Spartan-3 FPGA Starter Kit Board has a 50 MHz clock oscillator
    always @(posedge clk_osc) begin
        if (RESET) counter_s <= 18'd0;
        else counter_s <= counter_s + 1;
    end
    
    always @(posedge clk_osc) begin
        if (RESET) counter10 <= 4'd0;
        else if (counter10 == 4'd9) counter10 <= 4'd0;
        else counter10 <= counter10 + 1;
    end
    
    // SCLK signal - millisecond clock period (763 Hz)
    assign sClk = counter_s[15];
    assign iter = counter_s[17:16];
    assign s10clk = (counter10 == 4'b1001);
    
    
    
    // CLOCK signal
    always @(posedge clk_osc) begin
        // reset
        if (RESET) begin
            counter <= 27'd0;
            clk <= 1'b0;
        end
        else begin
            // if counter reaches desired timing: 0.5s (= 1s/2)
            // Spartan-3 FPGA Starter Kit Board has a 50 MHz clock oscillator
            if (counter == 27'd49999999) begin
                counter <= 27'd0;    // reset counter
                clk <= ~clk;    // invert CLOCK
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
    
    always @(posedge clk) begin
        if (reset) counter2 <= 0;
        else begin
            counter2 <= counter2 + 1;
        end
    end
    
    assign s2clk = counter2[1];
    
    // RESET_OUT signal
    assign reset = RESET;


endmodule
