`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoul National University. ECE. Logic Design
// Engineer: Junho Park
// 
// Create Date: 2024/11/26 17:04:35
// Design Name: 
// Module Name: function3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Stopwatch implementation with 16-bit register for segment display
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Define state assignments
`define SWIDTH 3 // State width
`define S0  3'b000 // default
`define S1  3'b001 // SPDT ON, waiting push_m
`define S15 3'b011 // Stopwatch running
`define S2  3'b010 // Stopwatch running
`define S25 3'b101 // Stopwatch running
`define S3  3'b100 // Stopwatch paused

// Stopwatch module
module Service_3_StopWatch(
    input clk,        // Main clock
    input reset,     // Reset signal (active low)
    input SPDT3,      // SPDT switch 3
    input push_m,     // Push button
    output reg [15:0] clk_count // Combined segments for seg1, seg2, seg3, seg4
);
    reg [2:0] stopwatch_state; // State registers
    
    // State transitions and control logic
    always @(posedge clk or posedge reset) begin
        if (reset || ~SPDT3) begin
            // Reset all state-related signals 
            clk_count <= 0;
        end else begin  
            // Stopwatch functionality
            if (SPDT3) begin
                case (stopwatch_state)
                    `S0: begin
                        // Idle: Reset stopwatch values
                        clk_count <= 0;
                    end
                    `S1: begin
                        // Initialized: Wait for push_m to start
                    end
                    `S2: begin
                        // Running: Increment counters
                        if (clk_count == 16'b1001_1001_1001_1001) begin 
                            // Reset to 0000 when current_time is 5959 (59:59)
                            clk_count <= 0;
                        end else if(clk_count[11:0] == 12'b1001_1001_1001) begin
                            // x900
                            clk_count[15:12] <= clk_count[15:12] + 1;
                            clk_count[11:0] <= 0;
                        end else if (clk_count[7:0] == 8'b1001_1001) begin
                            // If the lower 8 bits of current_time are 59, 
                            // current_time[15:8] + 1 and current_time[7:0] = 0
                            clk_count[15:8] <= clk_count[15:8] + 1;
                            clk_count[7:0] <= 0;
                        end else if(clk_count[3:0] == 4'b1001) begin
                            // xxx9
                            clk_count[3:0] <= 0;
                            clk_count[7:4] <= clk_count[7:4] + 1;
                        end else begin
                            // Otherwise, just do + 1
                            clk_count <= clk_count + 1;
                        end
                    end
                    `S3: begin
                        // Paused: Hold current time
                    end
                endcase
            end
        end
    end

    // Next state logic
    always @(posedge clk or posedge reset) begin
        if (reset || !SPDT3) begin
            stopwatch_state <= `S0;
        end else begin
            case (stopwatch_state)
                `S0: begin
                    stopwatch_state <= (SPDT3 ? `S1 : `S0); // Idle -> Initialized if SPDT3 ON
                    end
                `S1: begin
                    stopwatch_state <= (push_m ? `S15 : `S1); // Initialized -> Running if push_m
                    end
                `S15: begin
                    stopwatch_state <= (!push_m ? `S2 : `S15); // Initialized -> Running if push_m
                    end
                `S2: begin
                    stopwatch_state <= (push_m ? `S25 : `S2);
                    end
                `S25: begin
                    stopwatch_state <= (!push_m ? `S3 : `S25); // Initialized -> Running if push_m
                    end
                `S3: begin
                    stopwatch_state <= (push_m ? `S15 : `S3); // Initialized -> Running if push_m
                end
                default: begin
                    stopwatch_state <= `S0;
                end
            endcase
        end
    end

    // Convert time to 7-segment display values (using a 16-bit register)

endmodule
