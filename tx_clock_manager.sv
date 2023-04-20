// Ethernet Repeater - Transmit Clock Manager
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

/*
This module handles the reset and clock speed for the RGMII transmit
module.

If the RX speed changes:
1. Assert reset for TX for a while
2. Wait for the RX speed to stabilize and the link to come up
3. Change the output clock (with clock multiplexer) for TX to match RX speed
4. Wait at least N clocks and remove TX reset

Synchronize the inputs from RX, then let them stabilze through a bunch of
shift registers until they're all 1s and 0s. If the 1-hot speed is ever
out of agreement, then ignore the inputs until just one speed is asserted.

Output what we think the most stable speed/link status is as well.

Clock Multiplexer code: https://www.intel.com/content/www/us/en/docs/programmable/683082/22-1/clock-multiplexing.html

Clock Multiplexer timing: https://www.intel.com/content/www/us/en/docs/programmable/683243/21-3/clock-multiplexer-example.html
*/

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module tx_clock_manager #(
  parameter SYNCHRONIZER_LENGTH = 3,
  parameter STABILIZATION_LENGTH = 16
) (
  // System clock that operates this module
  input  logic clk,
  // Overall system reset
  input  logic reset,

  // Clock speeds that can be fed to TX clock
  input  logic clock_125, // For 1000
  input  logic clock_25,  // For 100
  input  logic clock_2p5, // For 10

  // PHY RX inputs - unsynchronzed (uses the RX clock domain)
  input  logic rx_speed_10,
  input  logic rx_speed_100,
  input  logic rx_speed_1000,
  input  logic rx_link_up,

  // TX MAC outputs
  output logic tx_speed_10,
  output logic tx_speed_100,
  output logic tx_speed_1000,
  output logic clk_tx,
  output logic reset_tx,

  // Other outputs
  output logic link_up
);

logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_speed_10;
logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_speed_100;
logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_speed_1000;
logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_link_up;

logic cur_rx_speed_10;
logic cur_rx_speed_100;
logic cur_rx_speed_1000;
logic cur_rx_link_up;

logic [STABILIZATION_LENGTH - 1:0] stab_rx_speed_10;
logic [STABILIZATION_LENGTH - 1:0] stab_rx_speed_100;
logic [STABILIZATION_LENGTH - 1:0] stab_rx_speed_1000;
logic [STABILIZATION_LENGTH - 1:0] stab_rx_link_up;

logic final_rx_speed_10;
logic final_rx_speed_100;
logic final_rx_speed_1000;
logic final_rx_link_up;
logic valid_rx_speed_10;
logic valid_rx_speed_100;
logic valid_rx_speed_1000;
logic valid_rx_link_up;

logic speed_is_one_hot;
logic entirely_valid = '0;

// Synchronizers
always_ff @(posedge clk) begin: synchronizers
  // sync_rx_speed_10   <= {sync_rx_speed_10  [SYNCHRONIZER_LENGTH - 2:0], rx_speed_10};
  sync_rx_speed_100  <= {sync_rx_speed_100 [SYNCHRONIZER_LENGTH - 2:0], rx_speed_100};
  sync_rx_speed_1000 <= {sync_rx_speed_1000[SYNCHRONIZER_LENGTH - 2:0], rx_speed_1000};
  sync_rx_link_up    <= {sync_rx_link_up   [SYNCHRONIZER_LENGTH - 2:0], rx_link_up};

  // cur_rx_speed_10   <= sync_rx_speed_10  [SYNCHRONIZER_LENGTH - 1];
  cur_rx_speed_100  <= sync_rx_speed_100 [SYNCHRONIZER_LENGTH - 1];
  cur_rx_speed_1000 <= sync_rx_speed_1000[SYNCHRONIZER_LENGTH - 1];
  cur_rx_link_up    <= sync_rx_link_up   [SYNCHRONIZER_LENGTH - 1];

  {cur_rx_speed_10, sync_rx_speed_10}   <= {sync_rx_speed_10, rx_speed_10};
end: synchronizers

// Stabilizers
always_comb begin: stabilizer_comb
  // It's valid if it's all 1s or 0s
  valid_rx_speed_10   = (&stab_rx_speed_10)   == '1 || (|stab_rx_speed_10) == '0;
  valid_rx_speed_100  = (&stab_rx_speed_100)  == '1 || (|stab_rx_speed_100) == '0;
  valid_rx_speed_1000 = (&stab_rx_speed_1000) == '1 || (|stab_rx_speed_1000) == '0;
  valid_rx_link_up    = (&stab_rx_link_up)    == '1 || (|stab_rx_link_up) == '0;

  // Check if 1-hot is true
  case ({stab_rx_speed_10[0], stab_rx_speed_100[0], stab_rx_speed_1000[0]})
    3'b100,
    3'b010,
    3'b001: speed_is_one_hot = '1;
    default: speed_is_one_hot = '0;
  endcase

  entirely_valid = valid_rx_link_up && 
                   valid_rx_speed_10 && valid_rx_speed_100 && valid_rx_speed_1000 && 
                   speed_is_one_hot;
end: stabilizer_comb

always_ff @(posedge clk) begin: stabilizers
  stab_rx_speed_10   <= {stab_rx_speed_10  [STABILIZATION_LENGTH - 2:0], cur_rx_speed_10};
  stab_rx_speed_100  <= {stab_rx_speed_100 [STABILIZATION_LENGTH - 2:0], cur_rx_speed_100};
  stab_rx_speed_1000 <= {stab_rx_speed_1000[STABILIZATION_LENGTH - 2:0], cur_rx_speed_1000};
  stab_rx_link_up    <= {stab_rx_link_up   [STABILIZATION_LENGTH - 2:0], cur_rx_link_up};

  // Save the final decision on what our speed is
  final_rx_speed_10   <= entirely_valid ? stab_rx_speed_10[0]   : final_rx_speed_10;
  final_rx_speed_100  <= entirely_valid ? stab_rx_speed_100[0]  : final_rx_speed_100;
  final_rx_speed_1000 <= entirely_valid ? stab_rx_speed_1000[0] : final_rx_speed_1000;
  final_rx_link_up    <= entirely_valid ? stab_rx_link_up[0]    : final_rx_link_up;
end: stabilizers

// Now we have to create a state machine:
// Monitor for changes in final_rx_link_up or the rx_speeds.
// When any of those change, or (global) reset is asserted:
// assert TXreset for N cycles or until link_up is restored.
// Before deasserting TXreset, change the clock speed with clock multiplexer.
// After N cycles of changing the clock speed, if link is up, deassert TXreset.



endmodule // tx_clock_manager

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa