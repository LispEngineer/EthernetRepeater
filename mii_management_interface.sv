// Ethernet Repeater - MII Management Interface
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

/*
  MII management interface per 802.3-2022 Spec Clause 22, section 22.2.4.
  Based on my I2C_CONTROLLER. 
  
  Target: Marvell 88E1111 PHY. Using Rev M of datasheet.

  This can run up to 8.3 MHz per section 2.9 of data sheet, and as slow as DC.
*/


module mii_management_interface #(
  // Every this many clocks we should do something, at 4x MDC clock speed
  // 4  gives 12.50 MHz from 50 MHz system, MDC of 3.125 MHz
  // 8  gives  6.25 MHz from 50 MHz system, MDC of ~1.56 MHz
  // 32 gives ~1.56 MHz from 50 MHz system, MDC of ~391 kHz
  parameter CLK_DIV = 32,
  // Number of bits to count as high as the above
  parameter CLK_CNT_SZ = $clog2(CLK_DIV)
) (
  // Our input system clock which will be internally
  // divided by CLOCK_DIV
  input  logic clk,
  input  logic reset,

  // MDIO Bus
  // These need to be connected to a tristate buffered output pin
  input  logic mdio_i, // MDIO input
  output logic mdio_o, // MDIO output
  output logic mdio_e, // MDIO output enabled
  output logic mdc,    // MDC clock (generated from 1/4 of 1/CLK_DIV of system clk)
  
  // Outputs about what's going on
  output logic busy,    // We're busy communicating
  output logic success, // When !busy, did we complete the last request successfully?
  
  // Inputs asking for something to do:
  // We only support a 3 byte transaction for now.
  input  logic        activate,    // True to begin when !busy
  input  logic        read,        // True to do a read operation, false for write
  input  logic  [4:0] phy_address, // Destination PHY (or 00000)
  input  logic  [4:0] register,    // Register to read/write
  input  logic [15:0] data_out,    // Data to send when !read
  output logic [15:0] data_in      // Data read when read
);

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa
