// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps
// This makes for approximately 320ns between I2C clock pulses when
// things are running stable-state.
module test_lcd_module();

// Simulator generated clock & reset
logic  clk;
logic  reset;


////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
always begin
  // 2.5 MHz = 200 (one full cycle every 400 ticks at 1ns per tick per above)
  // 25 MHz = 20
  // 50 MHz = 10
  // 125 MHz = 4
  // 
  #10 clk <= ~clk;
end

// Signals to LCD PHY
logic [7:0] lcd_data_o;
logic [7:0] lcd_data_i;
logic lcd_data_e, lcd_rs, lcd_rw, lcd_en;

// Signals to LCD Module (DUT)
logic activate = '0;
logic busy;
logic is_data = '0;
logic [7:0] data_inst = 8'hDF;
logic [23:0] delay = 23'h00_0020;

lcd_module dut (
  .clk(clk),
  .reset(reset),

  .data_o(lcd_data_o),
  .data_i(lcd_data_i),
  .data_e(lcd_data_e),
  .rs(lcd_rs),
  .rw(lcd_rw),
  .en(lcd_en),

  .busy(busy),
  .activate(activate),
  .is_data(is_data),
  .data_inst(data_inst),
  .delay(delay)
);


// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #22; reset <= 1'b0;

  activate <= '1;
  #3000;
  activate <= '0;

  // Stop the simulation at appropriate point
  #5000;
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif