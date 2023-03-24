// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps
// This makes for approximately 320ns between I2C clock pulses when
// things are running stable-state.
module test_mii_management_interface();

// Simulator generated clock & reset
logic  clk;
logic  reset;

// The internal wires for Management Interface
logic mdc, mdio_i, mdio_o, mdio_e;

// Status of I2C controller
logic mii_busy, mii_success;

// Should we do the activate thing
logic mii_activate;

// What should we activate?
logic        mii_read;
logic  [4:0] mii_phy_address;
logic  [4:0] mii_register;
logic [15:0] mii_data_in;
logic [15:0] mii_data_out;

////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
always begin
  // 50 Mhz (one full cycle every 20 ticks at 1ns per tick per above)
  #10 clk <= ~clk;
end

// instantiate device to be tested (Device Under Test)
mii_management_interface #(
  .CLK_DIV(4)
) dut (
  // Controller clock & reset
  .clk(clk),
  .reset(reset),

  // External management bus connections
  .mdc(mdc),
  .mdio_e(mdio_e), .mdio_i(mdio_i), .mdio_o(mdio_o),

  // Status
  .busy(mii_busy),
  .success(mii_success),

  // Management interface inputs
  .activate(mii_activate),
  .read(mii_read),
  .phy_address(mii_phy_address),
  .register(mii_register),
  .data_out(mii_data_out),
  .data_in(mii_data_in)
);

always_comb begin
  mii_activate = '1;
  mii_read = '0;
  mii_phy_address = 5'b1_0101;
  mii_register = 5'b0_1100;
  mii_data_out = 16'hDEAD;
end

// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #22; reset <= 1'b0;
  // Stop the simulation at appropriate point
  #48000;
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule






`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif