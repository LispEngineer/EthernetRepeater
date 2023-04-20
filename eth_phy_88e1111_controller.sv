// Marvel 88E1111 Controller
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

/* See README.md, section "88E1111 Controller," for instructions on what
 * this is supposed to be doing.
 */

module eth_phy_88e1111_controller #(
  // Pass to mii_management_interface - see that for description
  parameter CLK_DIV = 32,
  parameter PHY_MII_ADDRESS = 5'b0_0000,
  // 50MHz = 50,000 cycles per ms
`ifdef IS_QUARTUS
  parameter CLOCKS_FOR_5ms = 250_000
`else
  // Set a faster number for simulation
  parameter CLOCKS_FOR_5ms = 50
`endif
) (
  input  logic clk,
  input  logic reset, // This is the global system reset

  // MDIO Bus - pass through to MII management interface
  // These need to be connected to a tristate buffered output pin
  input  logic mdio_i,    // MDIO input
  output logic mdio_o,    // MDIO output
  output logic mdio_e,    // MDIO output enabled
  output logic mdc,       // MDC clock (generated from 1/4 of 1/CLK_DIV of system clk)
  output logic phy_reset, // Positive ETH PHY reset signal
  
  // Outputs about what's going on
  output logic busy,    // This controller is busy
  output logic success, // When busy -> !busy, did we complete the last request successfully?
  
  // Passthrough to MII management interface
  // (when the controller & the underlying is not busy)
  // This adds 1 cycle latency on all requests to MII
  input  logic        mii_activate,    // True to begin when !busy
  input  logic        mii_read,        // True to do a read operation, false for write
  input  logic  [4:0] mii_register,    // Register to read/write
  input  logic [15:0] mii_data_out,    // Data to send when !read
  output logic [15:0] mii_data_in,     // Data read when read

  // Outputs from our PHY
  // FIXME: Code these and output from the controller
  output logic speed_10,
  output logic speed_100,
  output logic speed_1000,
  output logic full_duplex,
  output logic connected,

  // Assert this anytime we failed to get expected response in configuration
  output logic configured,  // When RX and TX are ready to be used
  output logic config_error,

  // Debugging outputs
  output logic  [5:0] d_state,
  output logic [15:0] d_reg0,
  output logic [15:0] d_reg20,
  output logic [15:0] d_seen_states,
  output logic [15:0] d_soft_reset_checks
);

`ifdef IS_QUARTUS
// QuestaSim does not like these initial conditions with always_ff:
// # ** Error (suppressible): eth_phy_88e1111_controller.sv(171): (vlog-7061) Variable 'phy_reset' driven in an always_ff block, may not be driven by any other process. See eth_phy_88e1111_controller.sv(73).
initial phy_reset = '1;
initial config_error = '0;
initial connected = '0;
initial d_seen_states = '0;
initial d_soft_reset_checks = '0;
initial configured = '0;
`endif

logic reset_into_mii = '0;
logic c_mii_busy;
logic c_mii_success;

// Controller internal versions of these signals,
// which can also be sent in by end-user using non-c_ just-mii_ versions
logic        c_mii_activate;    // True to begin when !busy
logic        c_mii_read;        // True to do a read operation, false for write
logic  [4:0] c_mii_register;    // Register to read/write
logic [15:0] c_mii_data_out;    // Data to send when !read
logic [15:0] c_mii_data_in;     // Data read when read

// Instantiate one MII Management Interface
mii_management_interface #(
  // Leave all parameters at default, usually
  .CLK_DIV(CLK_DIV)
) mii_management_interface1 (
  // Controller clock & reset
  .clk(clk),
  .reset(reset || reset_into_mii),

  // External management bus connections
  .mdc(mdc),
  .mdio_e(mdio_e), .mdio_i(mdio_i), .mdio_o(mdio_o),

  // Status
  .busy(c_mii_busy),
  .success(c_mii_success),

  // Management interface inputs
  .activate   (c_mii_activate),
  .read       (c_mii_read),
  .phy_address(PHY_MII_ADDRESS),
  .register   (c_mii_register),
  .data_out   (c_mii_data_out),
  .data_in    (c_mii_data_in)
);



// Main controller state machine states
localparam S_POWER_ON             = 6'd0,
           S_POST_RESET_WAIT      = 6'd1,
           S_STARTUP_READ_20      = 6'd2,
           S_STARTUP_WRITE_20     = 6'd3,
           S_STARTUP_REREAD_20    = 6'd4,
           S_STARTUP_VERIFY_20    = 6'd5,
           S_REGISTER_READ_START  = 6'd6,
           S_REGISTER_WRITE_START = 6'd7,
           S_REGISTER_READ_AWAIT  = 6'd8,
           S_REGISTER_WRITE_AWAIT = 6'd9,
           S_SOFT_RESET_BEGIN     = 6'd10,
           S_SOFT_RESET_WRITE_0   = 6'd11,
           S_SOFT_RESET_WAIT      = 6'd12,
           S_SOFT_RESET_VERIFY    = 6'd13,
           S_CUSTOMER_IDLE        = 6'd14;

// Register IDs
localparam R_CONTROL  = 5'd0,
           R_STATUS   = 5'd1,
           R_PHY_ID_1 = 5'd2,
           R_PHY_ID_2 = 5'd3,
           R_PHY_EXT_SPEC_CTRL = 5'd20; // Extended PHY Specific Control Register (Table 95)

// Register bits
localparam REG20_ADJ_CLKs = 16'b0000_0000__1000_0010,
           REG0_SOFT_RESET = 16'b1000_0000__0000_0000;

// Delays
localparam DELAY_AFTER_POWER_ON = CLOCKS_FOR_5ms * 3, // Also for minimum reset
           DELAY_AFTER_DEASSERT_RESET = CLOCKS_FOR_5ms * 3 / 2,
           DELAY_AFTER_RUN_MDC = CLK_DIV * 8, // Let the MDC "spin up"
           DELAY_AFTER_SOFT_RESET = CLK_DIV * 32;

logic [31:0] delay_counter = DELAY_AFTER_POWER_ON;

logic [5:0] state = S_POWER_ON;
assign d_state = state;
logic [5:0] state_after_rw; // What state after a read/write to MII?
logic [5:0] state_after_soft_reset; // What state after we do soft reset?
logic success_after_rw; // Did a read/write to MII return success?
logic [4:0] reg_to_rw; // Which register to read/write in MII
logic [15:0] saved_read; // What we just read from MII
logic [15:0] val_to_write; // What we should write to MII
logic was_busy; // Track when MII newly becomes busy


always_ff @(posedge clk) begin

  if (reset) begin
    // Must give a minimum PHY reset of 10ms (4.8.1)
    phy_reset <= '1;
    // So handle that by doing the full power on cycle after reset
    state <= S_POWER_ON;
    delay_counter <= DELAY_AFTER_POWER_ON;

    reset_into_mii <= '1;
    busy <= '1;
    success <= '0;

    configured <= '0;
    config_error <= '0;

    d_seen_states <= '0;
    d_reg0 <= '0;
    d_reg20 <= '0;

  end else begin

    d_seen_states <= d_seen_states | (16'b1 << state);

    case (state)

    ////////////////////////////////////////////////////////////////////
    // Power on routine

    S_POWER_ON: begin ///////////////////////////////////////////////////
      // We need to wait 10ms before we deassert reset after power on
      // (Technically also must ensure 10 clocks of ETH clock but we don't see that.)
      busy <= '1;
      success <= '0;
      config_error <= '0;
      configured <= '0;
      if (delay_counter == '0) begin
        phy_reset <= '0;
        reset_into_mii <= '1; // We don't start MDIO/MDC until after PHY reset is down a while
        state <= S_POST_RESET_WAIT;
        delay_counter <= DELAY_AFTER_DEASSERT_RESET;
      end else begin
        delay_counter <= delay_counter - 1'd1;
        phy_reset <= '1;
        reset_into_mii <= '1;
      end
    end // S_POWER_ON

    S_POST_RESET_WAIT: begin ////////////////////////////////////////////
      // We need to wait 5ms before we enable MDIO,
      // then wait a few moments for MDC to get reestablished (I guess,
      // probably not strictly necessary)
      if (delay_counter == '0) begin
        if (reset_into_mii) begin
          // We can start running our MII MDC now (remove the MII reset)
          reset_into_mii <= '0;
          delay_counter <= DELAY_AFTER_RUN_MDC;
        end else begin
          // We can begin our startup sequence
          state <= S_STARTUP_READ_20;
        end
      end else begin
        delay_counter <= delay_counter - 1'd1;
      end
    end // S_POST_RESET_WAIT

    ////////////////////////////////////////////////////////////////////
    // Startup configuration routine

    S_STARTUP_REREAD_20,
    S_STARTUP_READ_20: begin //////////////////////////////////////////////
      // We need to read (or re-read) register 20
      config_error <= '0;
      reg_to_rw <= R_PHY_EXT_SPEC_CTRL;
      state <= S_REGISTER_READ_START;
      state_after_rw <= (state == S_STARTUP_READ_20) ? S_STARTUP_WRITE_20 : S_STARTUP_VERIFY_20;
    end // S_STARTUP_READ_20

    S_STARTUP_WRITE_20: begin ///////////////////////////////////////////
      // Set Reg 20 bits 7 and 1 to adjust RX and TX clocks in PHY
      d_reg20 <= saved_read;
      reg_to_rw <= R_PHY_EXT_SPEC_CTRL; // Should already be set
      val_to_write <= saved_read | REG20_ADJ_CLKs;
      state <= S_REGISTER_WRITE_START;
      state_after_rw <= S_STARTUP_REREAD_20;
    end // S_STARTUP_WRITE_20

    S_STARTUP_VERIFY_20: begin //////////////////////////////////////////
      // Verify that bits 7 & 1 are set in register 20
      d_reg20 <= saved_read;
      if ((saved_read & REG20_ADJ_CLKs) != REG20_ADJ_CLKs) begin
        config_error <= '1;
        $warning("Could not configure register 20");
        // FIXME: Should we try a few more times?
      end
      state <= S_SOFT_RESET_BEGIN;
      state_after_soft_reset <= S_CUSTOMER_IDLE;
    end // S_STARTUP_VERIFY_20

    ////////////////////////////////////////////////////////////////////
    // End user interactions

    S_CUSTOMER_IDLE: begin ///////////////////////////////////////////
      // Pass through everything we get from outside, but just one
      // cycle delayed
      configured <= '1; // Clearly we're done by now since we're in pass-thru mode
      busy <= c_mii_busy;
      success <= c_mii_success;
      mii_data_in <= c_mii_data_in; // data IN is read IN from the PHY

      c_mii_activate <= mii_activate;
      c_mii_read <= mii_read;
      c_mii_register <= mii_register;
      c_mii_data_out <= mii_data_out; // data OUT is data written OUT to the PHY
    end

    ////////////////////////////////////////////////////////////////////
    // Register read/write subroutines

    S_REGISTER_WRITE_START,
    S_REGISTER_READ_START: begin ///////////////////////////////////////
      // (TODO: Refactor to use a r/w flag instead of two states?)
      // Send a read request to MII once it's not busy
      if (c_mii_busy) begin
        // Do nothing
      end else begin
        c_mii_activate <= '1;
        c_mii_read <= (state == S_REGISTER_READ_START);
        c_mii_register <= reg_to_rw;
        if (state == S_REGISTER_WRITE_START)
          c_mii_data_out <= val_to_write; // data OUT is data written OUT to the PHY
        state <= (state == S_REGISTER_READ_START) ? S_REGISTER_READ_AWAIT : S_REGISTER_WRITE_AWAIT;
        was_busy <= '0;
      end
    end // S_REGISTER_READ_START

    S_REGISTER_WRITE_AWAIT,
    S_REGISTER_READ_AWAIT: begin ///////////////////////////////////////
      // Wait for it to be busy, then wait for it to be not busy.
      was_busy <= c_mii_busy;
      if (!was_busy && c_mii_busy) begin
        // Just became busy
        c_mii_activate <= '0; // We no longer need an activation, it's working
      end else if (was_busy && c_mii_busy) begin
        // It's processing, nothing to do
      end else if (was_busy && !c_mii_busy) begin
        // Just finished being busy
        if (state == S_REGISTER_READ_AWAIT)
          saved_read <= c_mii_data_in;
        state <= state_after_rw;
        success_after_rw <= c_mii_success;
      end else if (!c_mii_busy) begin
        // Should only happen if MII takes a short time to respond to activate request
        if (c_mii_activate)
          $warning("Slow MII response");
        else
          $error("Impossible state");
      end
    end // S_REGISTER_READ_AWAIT

    ////////////////////////////////////////////////////////////////////
    // Soft reset subroutine: read 0, write 0, wait N ms, read until not in reset

    S_SOFT_RESET_BEGIN: begin ////////////////////////////////////////
      reg_to_rw <= R_CONTROL;
      state <= S_REGISTER_READ_START;
      state_after_rw <= S_SOFT_RESET_WRITE_0;
      d_soft_reset_checks <= '0;
    end // S_SOFT_RESET_BEGIN

    S_SOFT_RESET_WRITE_0: begin ///////////////////////////////////////////
      d_reg0 <= saved_read;
      // Set Reg 0 bit 15 to do a soft reset
      reg_to_rw <= R_CONTROL; // Should already be set
      val_to_write <= saved_read | REG0_SOFT_RESET;
      state <= S_REGISTER_WRITE_START;
      state_after_rw <= S_SOFT_RESET_WAIT;
      delay_counter <= DELAY_AFTER_SOFT_RESET;
    end // S_STARTUP_WRITE_20

    S_SOFT_RESET_WAIT: begin ////////////////////////////////////////////
      // We read every now and then and then check if software 
      if (delay_counter == '0) begin
        state <= S_REGISTER_READ_START;
        reg_to_rw <= R_CONTROL;
        state_after_rw <= S_SOFT_RESET_VERIFY;
      end else begin
        delay_counter <= delay_counter - 1'd1;
      end
    end // S_SOFT_RESET_WAIT

    S_SOFT_RESET_VERIFY: begin //////////////////////////////////////////
      // Ensure that reset is done
      d_reg0 <= saved_read;
      if ((saved_read & REG0_SOFT_RESET) == '0) begin
        state <= state_after_soft_reset;
      end else begin
        // Need to try again
        delay_counter <= DELAY_AFTER_SOFT_RESET;
        state <= S_SOFT_RESET_WAIT;
        d_soft_reset_checks <= d_soft_reset_checks + 1'd1;
      end
    end // S_SOFT_RESET_VERIFY

    endcase

  end // reset or not?

end // Main state machine

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa
