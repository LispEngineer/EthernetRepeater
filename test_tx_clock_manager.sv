// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module test_tx_clock_manager();

logic clk = '0; // System clock (typically 50MHz in DE2-115)
logic reset = '1;
logic clk_125 = '0;
logic clk_25 = '0;
logic clk_2p5 = '0;

///////////////////////////////////////////////////////////////////////////////////////
// generate clocks

always begin: clk_50_toggle
  // 50 MHz "system clock"
  #10 clk <= ~clk;
end: clk_50_toggle

always begin: clk_125_toggle
  #4 clk_125 <= ~clk_125;
end: clk_125_toggle

always begin: clk_25_toggle
  #20 clk_25 <= ~clk_25;
end: clk_25_toggle

always begin: clk_2p5_toggle
  #200 clk_2p5 <= ~clk_2p5;
end: clk_2p5_toggle


///////////////////////////////////////////////////////////////////////////////////////
// Device under test

// Inputs from RX
logic rx_speed_10 = '0;
logic rx_speed_100 = '0;
logic rx_speed_1000 = '1;
logic rx_link_up = '0;

// Outputs to TX
logic tx_speed_10;
logic tx_speed_100;
logic tx_speed_1000;
logic clk_tx;
logic reset_tx;
logic tx_link_up;
logic tx_changing;

tx_clock_manager dut (
  .clk, .reset,

  .clock_125(clk_125),
  .clock_25(clk_25),
  .clock_2p5(clk_2p5),

  // PHY RX inputs - unsynchronzed (uses the RX clock domain)
  .rx_speed_10,
  .rx_speed_100,
  .rx_speed_1000,
  .rx_link_up,

  // TX MAC outputs
  .tx_speed_10,
  .tx_speed_100,
  .tx_speed_1000,
  .clk_tx,
  .reset_tx,

  // Other outputs
  .link_up(tx_link_up),
  .changing(tx_changing)
);



///////////////////////////////////////////////////////////////////////////////////////
// Main test harness

// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #222; reset <= 1'b0;
  rx_link_up <= '0; {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b100; // 88E1111 PHY defaults to 1G RX when no link

  // FIXME: Move the $displays after the #delays;

  #778; 
  // Test 100
  $display("Starting 100 @ ", $time);
  rx_link_up <= '1; {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b010;
  #40000; rx_link_up <= '0; {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b100;

  #2000; 
  // Test 1000
  $display("Starting 1000 @ ", $time);
  rx_link_up <= '1; {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b100;
  #40000; rx_link_up <= '0; {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b100;

  #2000; 
  // Test 10
  $display("Starting 10 @ ", $time);
  rx_link_up <= '1; {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b001;
  #40000; rx_link_up <= '0;

  // Test invalid inputs
  // Invalid: Non-one-hot
  $display("Starting one-hot-invalid @ ", $time);
  #20000; rx_link_up <= '1;  {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b110;
  $display("Starting 100 @ ", $time);
  #20000;                    {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b010;
  $display("Starting one-hot-invalid @ ", $time);
  #20000;                    {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b000;
  $display("Starting 100 @ ", $time);
  #20000;                    {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b010;
  $display("Starting 1000 without link down @ ", $time);
  #20000; {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b100; // Shift without link down
  $display("Starting quick shifts @ ", $time);
  #1250;  {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b010; // Fast shifts
  #1250;  {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b001;
  #1250;  {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b010;
  #1250;  {rx_speed_1000, rx_speed_100, rx_speed_10} = 3'b100;

  $display("Final link down @ ", $time);
  #20000; rx_link_up <= '0;

  // Stop the simulation at appropriate point
  #40000;
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end



endmodule


`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif


