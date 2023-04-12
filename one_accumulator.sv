// One Accumulator
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

// This accumulates any number of true values from the inputs
// as true until it's told to reset to the current value.
// This allows signals that are very fast to be held for a
// while until they are actioned and reset.


// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps


module one_accumulator #(
  parameter WIDTH = 1
) (
  input logic clk,
  input logic reset,
  input logic [WIDTH-1:0] i,
  output logic [WIDTH-1:0] o
);

always_ff @(posedge clk) begin
  if (reset)
    o <= i;
  else
    o <= o | i;
end

endmodule