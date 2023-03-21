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
 * MII management interface per 802.3-2022 Spec Clause 22, section 22.2.4.
 * Based on my I2C_CONTROLLER.
 *
 * Target: Marvell 88E1111 PHY. Using Rev M of datasheet.
 *
 * Note: the FPGA is sometimes "STA" and sometimes "MAC". The Marvell chip is
 * always "PHY".
 * 
 * This can run up to 8.3 MHz per section 2.9 of data sheet, and as slow as DC.
 *
 * "The 88E1111 device is permanently programmed for preamble suppression.
 * A minimum of one idle bit is required between operations." (2.9.2)
 * We will always send the full preamble, just for good measure.
 *
 * There is no documentation on what to do when we're in a reset,
 * or how the Management Interface will handle things. Should I keep the
 * clock running? If the PHY is also in reset, does it read the Management Interface?
 * No idea.
 *
 * What should we do while idling? Turn off the MDC? Leave MDIO at low?
 *
 * Caller: Assert activate while !busy until the busy signal activates.
 * If activate is asserted while busy, wait until it goes !busy then busy.
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
  output logic success, // When busy -> !busy, did we complete the last request successfully?
  
  // Inputs asking for something to do:
  // We only support a 3 byte transaction for now.
  input  logic        activate,    // True to begin when !busy
  input  logic        read,        // True to do a read operation, false for write
  input  logic  [4:0] phy_address, // Destination PHY (or 00000)
  input  logic  [4:0] register,    // Register to read/write
  input  logic [15:0] data_out,    // Data to send when !read
  output logic [15:0] data_in      // Data read when read
);

// FIXME: Ensure that CLK_DIV is at least 2

// Our main states in our I2C state machine
localparam S_RESET    = 4'd0,
           S_IDLE     = 4'd1, // MDIO = z (pulled high by external pull-up)
           S_PREAMBLE = 4'd2, // 32 1 bits
           S_SOF      = 4'd3, // Start of frame (01)
           S_OPCODE   = 4'd4, // Read 10, Write 01
           S_PHYADDR  = 4'd5, // 5 bits
           S_REGADDR  = 4'd6, // 5 bits
           S_TA       = 4'd7, // Turnaround: Read = Z0 (by PHY), Write = 10 (by STA)
           S_DATA     = 4'd8; // and back to IDLE



// Clock divider counter
localparam CLK_DIV_CNT_ONE = { {(CLK_CNT_SZ-1){1'b0}}, 1'b1 }; // 1 in the proper bit width
localparam CLK_CNT_MAX = CLK_DIV - 1;
logic [CLK_CNT_SZ:0] clk_div_cnt;

// Our state machine       
logic [3:0] state = S_RESET;

// Our steps to make the MDC
// 0 1 2 3
// _/---\_
// 0: clock starts low
// 1: clock transitions high
// 2: clock remains high
// 3: clock returns/transitions low
logic [1:0] step;



always_ff @(posedge clk) begin

  // If we are being reset
  if (reset) begin
    state <= S_RESET;
    // Since this can be asserted for a bunch of clock cycles,
    // update our important external signals
    busy <= 1;
    success <= 0;
    // Turn off our outputs
    mdio_e <= 0;
    mdc <= 0; // Turn clock off
    step <= 0; // Reset the clock step when we do begin
    // Reset our clock divider counter
    clk_div_cnt <= 0;

    // TODO: If we get a reset when not idle, now what?

  end else if (clk_div_cnt != 0) begin ////////////////////////////////////
  
    // Do nothing until we get to our divider
    if (clk_div_cnt == CLK_CNT_MAX)
      clk_div_cnt <= 0;
    else
      clk_div_cnt <= clk_div_cnt + CLK_DIV_CNT_ONE;
    
  end else begin //////////////////////////////////////////////////////////
  
    // Count is 0 on our clock divider now, so move it to 1.
    clk_div_cnt <= CLK_DIV_CNT_ONE;

    // Not resetting, not waiting for system clock to hit our divider, so:
    // do our proper 4x speed I2C state machine, finally.

    case (state)

      S_RESET: begin /////////////////////////////////////////////////
        busy <= 1; // We're powering up
        // We have no previous status
        success <= 0;
        // Turn off our outputs
        mdio_e <= 0;
        // Move to our idle state
        state <= S_IDLE;
        step <= 0; // Clock step
      end // S_RESET case

      S_IDLE: begin ///////////////////////////////////////////////////

        mdio_e <= 0;

        // Do we run our clock with no output? Sounds good to me.
        case (step)
          0: begin mdc <= 0; step <= 2'd1; end
          1: begin mdc <= 1; step <= 2'd2; end
          2: begin mdc <= 1; step <= 2'd3; end
          3: begin mdc <= 0; step <= 2'd0;
            if (activate) begin
              // TODO: CODE ME
            end
          end
        endcase // S_IDLE step

      end // S_IDLE

      // TODO: CODE ME (all other states)

    endcase // state

  end // not reset

end // always_ff main state machine

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa
