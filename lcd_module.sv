// LCD Display Module
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

/*
Based on CFAH1602B module and HD44780 controller

Has two simple state machines for now:

1. Initialization sequence
2. Send a character to shift into the LCD

*/

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps


module lcd_module #(
  // The delays in each step of our state
  parameter PREP_COUNT = 24'd3,      // 60ns at 50MHz (>= 40ns)
  parameter EN_COUNT   = 24'd12,     // 240ns at 50MHz (>= 230ns)
  parameter EN_HOLD    = 24'd2,      // 40ns at 50MHz (>= 10ns)
  parameter DELAY      = 24'd82_000  // Default delay: 1,640,000ns (1.64ms) at 50MHz (>= 40µs to 1.64ms)
) (
  // Our appropriate speed clock input (copied to output)
  input  logic clk,
  input  logic reset,

  // Interface to PHY LCD module
  output logic [7:0] data_o,
  input  logic [7:0] data_i,
  output logic       data_e, // Output when 1, input when 0
  output logic       rs, // 1 = Data, 0 = Instruction
  output logic       rw, // 1 = Read, 0 = Write
  output logic       en, // H to L signals it to read the other pins

  // Interface to this module
  output logic        busy,
  input  logic        activate, // Signal when !busy and then deactivate
  input  logic        is_data,  // Equivalent to the rw
  input  logic  [7:0] data_inst,// Character data or instruction to shift out (the only current operation)
  input  logic [23:0] delay     // If not zero, delay this many cycles before being unbusy
);

initial busy = '0;
initial data_e = '0;

localparam S_IDLE     = 4'd0,
           S_PREP     = 4'd1, // Set up the outputs, wait
           S_SET_EN   = 4'd2, // Turn on enable, wait
           S_TRANS_EN = 4'd3, // Turn off enable, wait
           S_DELAY    = 4'd4; // Wait for the command to finish
logic [3:0] state = S_IDLE;

// Our counter
logic [23:0] count = '0;

// Where we go after our delay
logic [3:0] post_delay_state;

// When we activate, save our inputs
logic        r_is_data;
logic  [7:0] r_data_inst;
logic [23:0] r_delay;

always_ff @(posedge clk) begin

  if (reset) begin

    en <= '0;
    data_e <= '0; // tri-state output
    busy <= '1; // Should we be "busy" when being reset?
    state <= S_IDLE;

  end else begin

    case (state)
    S_IDLE: begin /////////////////////////////////////////////////////////////////////
      busy <= '0;
      if (activate) begin
        state <= S_PREP;
        count <= '0;
        busy <= '1;
        // Just in case it helps to set this up a bit earlier
        data_e <= '1;
        data_o <= data_inst;
        rs <= is_data;
        rw <= '0; // We always are 0 - writing
        // Save our inputs
        r_data_inst <= data_inst;
        r_is_data <= is_data;
        if (delay == 0)
          r_delay <= DELAY;
        else
          r_delay <= delay;
        post_delay_state <= S_IDLE;
      end
    end // S_IDLE

    S_PREP: begin /////////////////////////////////////////////////////////////////////
      // Prepare the data to be shown when EN is raised
      if (count == '0) begin
        // Set the inputs to the physical LCD module
        data_e <= '1;
        data_o <= r_data_inst;
        rs <= r_is_data; // 1 if sending data, 0 if sending instruction
        rw <= '0; // Writing data, not reading
        count[0] <= 1'b1;
      end else if (count == PREP_COUNT) begin
        count <= '0;
        state <= S_SET_EN;
      end else begin
        count <= count + 1'd1;
      end
    end // S_PREP

    S_SET_EN: begin ///////////////////////////////////////////////////////////////////
      // Raise EN for "long enough"
      if (count == '0) begin
        en <= '1;
        count[0] <= 1'b1;
      end else if (count == EN_COUNT) begin
        count <= '0;
        en <= '0; 
        state <= S_TRANS_EN;
      end else begin
        count <= count + 1'd1;
      end
    end // S_SET_EN

    S_TRANS_EN: begin /////////////////////////////////////////////////////////////////
      // Hold data stable for required hold time
      if (count == '0) begin
        en <= '0;
        count[0] <= 1'b1;
      end else if (count == EN_HOLD) begin
        count <= r_delay; // How long should we delay for?
        state <= S_DELAY;
        data_e <= '0; // No longer outputting data
      end else begin
        count <= count + 1'd1;
      end
    end // S_TRANS_EN 

    S_DELAY: begin ///////////////////////////////////////////////////////////////////
      // We delay until we count down, since the delay can differ for each type
      // of operation
      if (count == '0) begin
        // We may not want to go to the main loop, but instead the initialization loop?
        state <= post_delay_state;
        // If idle, it will turn busy flag off.
      end else begin
        count <= count - 1'd1;
      end
    end // S_TRANS_EN 

    default: begin ////////////////////////////////////////////////////////////////////
      state <= S_IDLE;
      busy <= '0;
      data_e <= '0;
    end // default state

    endcase // state

  end // Not Reset

end // Main state machine


endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa