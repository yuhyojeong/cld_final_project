`timescale 1ns / 1ps

/* tb for service_3
author: Huiwone Kim
date: 2024/12/06
*/

module Service_3_revised_tb;

    reg [4:0] push;
    reg [14:0] spdt;
    reg clk_osc;
    wire sClk;
    reg clk;

    wire [6:0] eSeg;
    wire [3:0] anode;
    wire [13:0] led;
    wire clk_led;
    wire temp_led;
    
    wire RESET;

    wire [3:0] which_seg_on1;
    wire [3:0] which_seg_on2;
    wire finish1;

    wire [15:0] num1;
    wire [15:0] num3;
    wire [15:0] num4;

    wire [15:0] alarm_time;
    wire [15:0] current_time;
    wire [3:0] currentNum;
    wire alarm_on;

    // Clock generation
    initial begin
        clk_osc = 0;
        forever begin
            #10 clk_osc = ~clk_osc;
        end
    end

    reg [22:0] counter;
    reg [13:0] counter_s;
    
    wire [1:0] iter;    
    
    // everything  divided by 16
    // Spartan-3 FPGA Starter Kit Board has a 50 MHz clock oscillator
    always @(posedge clk_osc) begin
        if (RESET) counter_s <= 14'd0;
        else counter_s <= counter_s + 1;
    end
    // SCLK signal - millisecond clock period (763 Hz)
    assign SCLK = counter_s[11];
    assign iter = counter_s[13:12];
    

    // CLOCK signal
    always @(posedge clk_osc) begin
        // reset
        if (RESET) begin
            counter <= 23'd0;
            clk <= 1'b0;
        end
        else begin
            // if counter reaches desired timing: 0.5s (= 1s/2)
            // Spartan-3 FPGA Starter Kit Board has a 50 MHz clock oscillator
            if (counter == 23'd1562499) begin
                counter <= 23'd0;    // reset counter
                clk <= ~clk;    // invert CLOCK
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
    

    // RESET_OUT signal
    assign reset = RESET;

    initial begin
        // Initialize Inputs
        push = 5'b00000;
        spdt = 15'b000000000000000;

        // Wait for global reset
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

        // Finish simulation
        $finish;
    end

  Service_3_StopWatch service_3(
    .clk(sClk),
    .reset(reset),
    .SPDT3(spdt[12]),
    .push_m(push[4]),
    .segments(num3)
  );

endmodule