`timescale 1ns / 1ps

/* tb for service_1
author: Huiwone Kim
date: 2024/12/04
*/

module Main_tb;

    // Inputs
    reg [4:0] push;
    reg [14:0] spdt;
    reg clk_osc;

    // Outputs
    wire [6:0] eSeg;
    wire [3:0] anode;
    wire [13:0] led;
    wire clk_led;

    // Instantiate the Unit Under Test (UUT)
    Main uut (
        .push(push),
        .spdt(spdt),
        .clk_osc(clk_osc),
        .eSeg(eSeg),
        .anode(anode),
        .led(led),
        .clk_led(clk_led)
    );

    // Clock generation
    initial begin
        clk_osc = 0;
        forever begin
            #1 clk_osc = ~clk_osc;
        end
    end

    initial begin
        // Initialize Inputs
        clk_osc = 0;
        push = 5'b00000;
        spdt = 15'b000000000000000;

        // Wait for global reset
        #100;

        // Test 1: Reset
        spdt[0] = 1; // Activate reset
        #50;
        spdt[0] = 0; // Deactivate reset
        #100;

        // Test 2: Time Setting (Service 1)
        spdt[14] = 1; // Activate SPDT switch 1
        #50;
        push[0] = 1; // Push up button to increase minute
        #50;
        push[0] = 0;
        push[2] = 1; // Push left button to select seconds
        #50;
        push[2] = 0;
        push[1] = 1; // Push down button to decrease seconds
        #50;
        push[1] = 0;
        spdt[14] = 0; // Deactivate SPDT switch 1
        #100;

        // Test 3: Alarm Setting (Service 2)
        spdt[13] = 1; // Activate SPDT switch 2
        #50;
        push[0] = 1; // Push up button to set alarm minute
        #50;
        push[0] = 0;
        spdt[13] = 0; // Deactivate SPDT switch 2
        #100;

        // Test 4: Stopwatch (Service 3)
        spdt[12] = 1; // Activate SPDT switch 3
        #50;
        push[4] = 1; // Push middle button to start stopwatch
        #50;
        push[4] = 0;
        #500; // Simulate stopwatch running
        push[4] = 1; // Push middle button to pause stopwatch
        #50;
        push[4] = 0;
        spdt[12] = 0; // Deactivate SPDT switch 3
        #100;

        // Test 5: Alarm On/Off (Service 4)
        spdt[11] = 1; // Activate SPDT switch 4
        #100;
        spdt[11] = 0; // Deactivate SPDT switch 4
        #100;

        // Test 6: Mini-game (Alarm Dismissal)
        spdt[11] = 1; // Activate SPDT switch 4
        #100;
        push[4] = 1; // Push middle button to start mini-game
        #50;
        push[4] = 0;
        spdt[10:1] = 10'b0000000001; // Activate correct SPDT switch for mini-game
        #50;
        spdt[10:1] = 10'b0000000000;
        #500;
        spdt[11] = 0; // Deactivate SPDT switch 4
        #100000000;

        // Finish simulation
        $finish;
    end
endmodule
