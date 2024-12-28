`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/04 20:00:34
// Design Name: 
// Module Name: tb_service_4_unified
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

module tb_service_4_unified(

    );
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg resetn;
    reg SPDT4;
    reg [9:0] SPDTs;
    reg push_m;
    
    reg [15:0] current_time;
    reg [15:0] alarm_time;
    
    reg [2:0] alarm_state;
    reg [15:0] count_state;
    reg [9:0] SPDT_LED;
    reg finish4;
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        resetn = 1;
        SPDT4 = 0;
        SPDTs = 0;
        push_m = 0;
        
        current_time = 16'd0;
        alarm_time = 16'd10;
        
        #100;
        SPDT4 = 1;
        
        repeat(20) begin
            #CLK_PERIOD;
            current_time = current_time +1;
        end
        
        #CLK_PERIOD;
        push_m = 1;
                
        #CLK_PERIOD;
        push_m = 0;
        
        #200;
        
        repeat(4) begin
            #CLK_PERIOD;
            current_time = current_time + 1;
            SPDTs = SPDT_LED;
        end
        #1000;
        $finish;
    end
            
    Service_4 uut_service_4(
        .clk(clk),
        .resetn(resetn),
        .SPDT4(SPDT4),
        .SPDTs(SPDTs),
        .push_m(push_m),
        
        .current(current_time),
        .alarm(alarm_time),
        
        .alarm_state(alarm_state),
        .count_state(count_state),
        .SPDT_LED(SPDT_LED),
        .finish4(finish4)
    );
    
    initial begin
        $monitor("Time=%0t | alarm_state=%b | finish4=%b | SPDT_LED=%b | SPDTs=%b | count_state=%d",
                 $time, alarm_state, finish4, SPDT_LED, SPDTs, count_state);
    end

    
endmodule
