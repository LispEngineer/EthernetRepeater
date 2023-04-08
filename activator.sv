// Activate/deactivate module
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer
//
// Activates once, regardless how long asserted, when it goes
// from 0 to 1. Deactivates once the busy flag goes from unbusy to busy.
//
// This only activates if it goes from non-requested to requested while not busy.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps


module activator #(
  parameter NO_PARAMETERS = 0
) (
  input logic  clk,
  input logic  reset,
  input logic  busy, 
  input logic  request,
  output logic activate
)

initial activate = '0;

logic last_request = '1;
logic last_busy = '0;

always_ff @(posedge clk) begin
  last_request <= KEY;
  last_busy <= busy;

  // TODO: Handle reset

  if (!busy && last_busy) begin
    // We just became non-busy
    // Nothing really to do

  end else if (busy && activate) begin
    // Command just started
    activate <= '0;
  end else if (busy) begin
    // The thing is busy, don't accept something new to do
  end else if (activate) begin
    // Do nothing
  end else if (!busy && !activate && request && request != last_request) begin
    // We're not busy, not awaiting activation, and the request was just made,
    // so activate until we become busy.
    activate <= '1;
  end

end

endmodule

