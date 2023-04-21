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
  parameter STABILIZATION_LENGTH = 16,
  // The clock multiplexer takes at least 3 cycles of the NEW clock
  // to start flipping again. Our slow clock is 20x the speed of clk,
  // so we need to wait at least 60 cycles. Let's give it a bit more
  // margin for error.
  parameter POST_CHANGE_DURATION = 100,
  // Figure out if there is a minimum reset period for TX
  parameter PRE_CHANGE_DURATION = 100
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
  output logic link_up,  // Is the link up?
  output logic changing  // Is the speed/link state changing?
);

// FIXME: If the speed input is not 1-hot valid, should we assert
// transmit reset?

localparam CHANGE_COUNTER_BITS = $clog2(POST_CHANGE_DURATION);
localparam initial_final_speed_10 = '0,
           initial_final_speed_100 = '0,
           initial_final_speed_1000 = '0,
           initial_final_link_up = '0;

// Input synchronizers from RX
logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_speed_10;
logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_speed_100;
logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_speed_1000;
logic [SYNCHRONIZER_LENGTH - 1:0] sync_rx_link_up;

// Final result of input synchronizers
logic cur_rx_speed_10;
logic cur_rx_speed_100;
logic cur_rx_speed_1000;
logic cur_rx_link_up;

// Input stabilizers - we want all values to be the same for this many cycles
logic [STABILIZATION_LENGTH - 1:0] stab_rx_speed_10;
logic [STABILIZATION_LENGTH - 1:0] stab_rx_speed_100;
logic [STABILIZATION_LENGTH - 1:0] stab_rx_speed_1000;
logic [STABILIZATION_LENGTH - 1:0] stab_rx_link_up;

// Final stable outputs
logic final_rx_speed_10 = initial_final_speed_10;
logic final_rx_speed_100 = initial_final_speed_100;
logic final_rx_speed_1000 = initial_final_speed_1000;
logic final_rx_link_up = initial_final_link_up;
// Signals if the stabilizer is all 1 or all 0
logic valid_rx_speed_10;
logic valid_rx_speed_100;
logic valid_rx_speed_1000;
logic valid_rx_link_up;

// True if exactly one speed is 1
logic speed_is_one_hot;
// True if all stabilizers are valid & exactly one hot
logic entirely_valid = '0;

// The inputs to the clock mux that change slowly and only
// when things are stable, and only during a TX reset.
logic current_clk_tx_10 = initial_final_speed_10;
logic current_clk_tx_100 = initial_final_speed_100;
logic current_clk_tx_1000 = initial_final_speed_1000;
logic current_link_up = initial_final_link_up;

// Outputs
assign link_up = current_link_up;
assign tx_speed_10 = current_clk_tx_10;
assign tx_speed_100 = current_clk_tx_100;
assign tx_speed_1000 = current_clk_tx_1000;


//////////////////////////////////////////////////////////////////////////////////////////
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

//////////////////////////////////////////////////////////////////////////////////////////
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

/////////////////////////////////////////////////////////////////////////////////////
// Our actual TX clock multiplexer based on the slow changing "current" clock setting.

// Note that this clock multiplexer is glitch free BUT it seems to take at
// least 3 cycles of the NEW CLOCK before it starts outputing again.
clock_mux tx_clock_mux (
  .clk       ({clock_125, clock_25, clock_2p5}), 
  .clk_select({current_clk_tx_1000, current_clk_tx_100, current_clk_tx_10}),
  .clk_out   (clk_tx)
);


/////////////////////////////////////////////////////////////////////////////////////
// Now we have to create a state machine:
// Monitor for changes in final_rx_link_up or the rx_speeds.
// When any of those change, or (global) reset is asserted:
// assert TXreset for N cycles or until link_up is restored.
// Before deasserting TXreset, change the clock speed with clock multiplexer.
// After N cycles of changing the clock speed, if link is up, deassert TXreset.

localparam S_IDLE            = 2'd0,
           S_CHANGE_DETECTED = 2'd1,
           S_CLOCK_CHANGE    = 2'd2,
           S_CHANGE_WAIT     = 2'd3;
logic [1:0] state = S_IDLE;

// Counter for delaying before & after a clock multiplexer change
logic [CHANGE_COUNTER_BITS - 1:0] counter;

// Combinationally true when the currently outputing state is not the same as input state
logic change_detected; 

always_comb begin: detect_changes
  change_detected =
    {current_clk_tx_1000, current_clk_tx_100, current_clk_tx_10} !=
      {final_rx_speed_1000, final_rx_speed_100, final_rx_speed_10} ||
    current_link_up != final_rx_link_up;
end: detect_changes

always_ff @(posedge clk) begin: main_state_machine

  if (reset) begin: external_reset

    reset_tx <= '1;
    changing <= '0;
    state <= S_CHANGE_DETECTED; // When we leave reset, set the transmit clock
    counter <= PRE_CHANGE_DURATION;

  end: external_reset else begin: state_machine_states

    case (state)

    S_IDLE: begin: s_idle /////////////////////////////////////////////////////////

      // We wait until the final_ values are different than the current_ values
      // (and we are entirely_valid). If that is the case, we assert reset for a bit,
      // change the clock, wait a bit, and then de-assert reset.

      // TODO: If the link is not up, should we keep asserting the reset_tx?

      reset_tx <= '0;
      changing <= '0;

      if (entirely_valid && change_detected) begin: found_change
        // (See above for change_detected definition)

        state <= S_CHANGE_DETECTED;
        counter <= PRE_CHANGE_DURATION;

      end: found_change else begin: no_change

        // Nothing to do

      end: no_change

    end: s_idle

    S_CHANGE_DETECTED: begin: s_change_detected ///////////////////////////////////

      // Start to reset the transmitter, wait a while, and then change the clock speed.

      reset_tx <= '1;
      changing <= '1;

      if (counter == '0) begin
        state <= S_CLOCK_CHANGE;
      end else begin
        counter <= counter - 1'd1;
      end

    end: s_change_detected

    S_CLOCK_CHANGE: begin: s_clock_change //////////////////////////////////////////

      // Change the clock speed, and wait a while before de-asserting reset
      if (entirely_valid) begin
        // Update our clock multiplexer and link state
        {current_clk_tx_1000, current_clk_tx_100, current_clk_tx_10} <=
          {final_rx_speed_1000, final_rx_speed_100, final_rx_speed_10};
        current_link_up <= final_rx_link_up;
        counter <= POST_CHANGE_DURATION;
        state <= S_CHANGE_WAIT;
      end else begin
        // Our inputs aren't stable yet (again?) so just wait for them to stabilize
        // (we could increment the counter for debug purposes...)
        counter <= counter + 1'd1;
      end 

    end: s_clock_change

    S_CHANGE_WAIT: begin: s_change_wait ////////////////////////////////////////////

      // We have changed our clock speed; now wait for two things:
      // 1. Link to come up AND
      // 2. The delay to end

      if (counter != '0) begin
        // We have to wait for the clock multiplexer to start outputing
        counter <= counter - 1'd1;

      end else if (entirely_valid) begin
        // We have stable inputs, decide what to do...
        if (change_detected) begin
          // Go back to the beginning and restart our change process
          counter <= PRE_CHANGE_DURATION;
          state <= S_CHANGE_DETECTED;
        end else begin
          // We are done!
          // TODO: Should we wait until link_up?
          state <= S_IDLE; // Will clear reset_tx and changing flags
        end

      end else begin
        // wait for inputs to stabilize then decide what to do
      end

    end: s_change_wait
    endcase // case (state) ///////////////////////////////////////////////////////

  end: state_machine_states

end: main_state_machine

endmodule // tx_clock_manager




`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa