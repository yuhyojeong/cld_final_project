`timescale 1ns / 1ps

/* tb for service_1
author: HyoJeong Yu
date: 2024/11/30
*/

module tb;

  `define expected 16'b0000_1001_0011_1000
  reg clk;
  reg resetn;
  reg spdt1;
  reg u, d, l, r;
  wire [3:0] sel;
  wire finish1;
  reg finish;
  wire [15:0] num;

  initial begin
    clk = 0;
    forever #(5) clk = ~clk;
  end

  initial begin
    resetn = 0;
    spdt1 = 0;
    u = 0;
    d = 0;
    r = 0;
    l = 0;
  end
  
  initial begin
    #10;
    resetn = 1;

    #20;
    spdt1 = 1;

    $display("setting time to 09:38\n");

    // Sequence for setting 09:38

    //9
    repeat (2) @(posedge clk);
    r = 1;
    @(posedge clk);
    r = 0;

    @(posedge clk);
    d = 1;
    @(posedge clk);
    d = 0;
    
    //3
    repeat (3) @(posedge clk);
    r = 1;
    @(posedge clk);
    r = 0;

    repeat (2) @(posedge clk);
    repeat (3) begin
      u = 1;
      @(posedge clk);
      u = 0;
    end

    //8
    repeat (5) @(posedge clk);
    r = 1;
    @(posedge clk);
    r = 0;

    repeat (2) @(posedge clk);
    repeat (2) begin
      d = 1;
      @(posedge clk);
      d = 0;
    end

    repeat (5) @(posedge clk);
    spdt1 = 0;
  end

  always @(posedge clk) begin
    finish <= finish1;
    if (finish) begin
      if (num == `expected) $display("result is correct!");
      else begin
        $display("result is different.\n");
        $display("your result: %b", num);
      end
      $display("test done\n");
      $finish;
    end
  end

  Service_1_time_set u_time_set (
    .clk(clk),
    .resetn(resetn),
    .spdt1(spdt1),
    .push_u(u),
    .push_d(d),
    .push_l(l),
    .push_r(r),

    .sel(sel),
    .finish1(finish1),
    .num(num)
  );
endmodule
