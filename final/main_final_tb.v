`timescale 1ns / 1ps

/* tb for service_1
author: Huiwone Kim
date: 2024/12/04
*/

module Main_tb;

    reg [4:0] push;
    reg [14:0] spdt;
    reg clk_osc;
    wire sClk;
    reg clk;
    wire s2clk;
    wire s10clk;

    wire [6:0] eSeg;
    wire [3:0] anode;
    wire [13:0] led;
    wire clk_led;
    wire temp_led;
    

    reg RESET;

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

    // Clock generation
    initial begin
        clk_osc = 0;
        forever begin
            #1 clk_osc = ~clk_osc;
        end
    end

    reg [21:0] counter;
    reg [12:0] counter_s;
    reg [3:0] counter10 = 0;
    
    wire [1:0] iter;    
    
    // everything  divided by 32
    // Spartan-3 FPGA Starter Kit Board has a 50 MHz clock oscillator
    always @(posedge clk_osc) begin
        if (RESET) counter_s <= 13'd0;
        else counter_s <= counter_s + 1;
    end
    
    always @(posedge sClk) begin
        if (RESET) counter10 <= 4'd0;
        else if (counter10 == 4'd9) counter10 <= 4'd0;
        else counter10 <= counter10 + 1;
    end
    
    // SCLK signal - millisecond clock period (763 Hz)
    assign sClk = counter_s[10];
    assign s2clk = counter_s[11];
    assign iter = counter_s[12:11];
    assign s10clk = (counter10 == 4'b1001);

    // CLOCK signal
    always @(posedge clk_osc) begin
        // reset
        if (RESET) begin
            counter <= 22'd0;
            clk <= 1'b0;
        end
        else begin
            // if counter reaches desired timing: 0.5s (= 1s/2)
            // Spartan-3 FPGA Starter Kit Board has a 50 MHz clock oscillator
            if (counter == 22'd781249) begin
                counter <= 22'd0;    // reset counter
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

        // Test 1: Reset
        RESET = 1; // Activate reset
        #50;
        RESET = 0; // Deactivate reset
        
        repeat (2) @(posedge clk);
        // Test 2: Time Setting (Service 1)
//        spdt[14] = 1; // Activate SPDT switch 1
//        @(posedge clk);
//        push[0] = 1; // Push up button to increase minute
//        @(posedge clk);
//        push[0] = 0;
//        @(posedge clk);
//        push[2] = 1; // Push left button to select seconds
//        @(posedge clk);
//        push[2] = 0;
//        @(posedge clk);
//        push[1] = 1; // Push down button to decrease seconds
//        @(posedge clk);
//        push[1] = 0;
//        #50;
//        spdt[14] = 0; // Deactivate SPDT switch 1
        
//        repeat (2) @(posedge clk);
//        spdt[14] = 1;
//        @(posedge clk);
//        push[0] = 1; // Push up button to increase minute
//        @(posedge clk);
//        push[0] = 0;
//        @(posedge clk);
//        spdt[14] = 0;
//        // Test 3: Alarm Setting (Service 2)
//        #50;
//        @(posedge clk);
//        spdt[13] = 1; // Activate SPDT switch 2
//        @(posedge clk);
//        push[0] = 1; // Push up button to set alarm minute
//        @(posedge clk);
//        push[0] = 0;
//        #50;
//        spdt[13] = 0; // Deactivate SPDT switch 2

//        // Test 4: Stopwatch (Service 3)
//        #50;
//        spdt[12] = 1; // Activate SPDT switch 3
//        @(posedge clk);
//        push[4] = 1; // Push middle button to start stopwatch
//        @(posedge clk);
//        push[4] = 0;
//        @(posedge clk); // Simulate stopwatch running
//        push[4] = 1; // Push middle button to pause stopwatch
//        @(posedge clk);
//        push[4] = 0;
//        #30;
//        spdt[12] = 0; // Deactivate SPDT switch 3
        #50;

//        // Test 5: Alarm On/Off (Service 4)
//        spdt[11] = 1; // Activate SPDT switch 4
//        #50;
//        spdt[11] = 0; // Deactivate SPDT switch 4
//        #50;

        // Test 6: Mini-game (Alarm Dismissal)
        spdt[11] = 1; // Activate SPDT switch 4
        @(posedge clk);
        push[4] = 1; // Push middle button to start mini-game
        @(posedge clk);
        push[4] = 0;
        #30;
        spdt[10:1] = 10'b0000000001; // Activate correct SPDT switch for mini-game
        #50;
        spdt[10:1] = 10'b0000000000;
        #50;
        spdt[11] = 0; // Deactivate SPDT switch 4
        #100;

        // Finish simulation
        $finish;
    end

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
    .clk(sClk),
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