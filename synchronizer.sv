// Synchronizer with variable width
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

// Thanks to Charles Eric LaForest for the Altera/Intel synthesis attributes
// See: http://fpgacpu.ca/fpga/CDC_Bit_Synchronizer.html

// More than one bit can be used, but there is no guarantee on if the
// signals that are input synchronously will come out at the same time,
// so only use multiple bits with that understanding.
// See: Clock Domain Crossing (CDC) Design & Verification Techniques Using SystemVerilog
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
// (and, in general, all the writing on that site is awesome)


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module synchronizer #(
  parameter DEPTH = 2, // At least 2, up to 9
  parameter WIDTH = 1
) (
  // The incoming clock
  input  logic clk,
  
  input  logic [WIDTH-1:0] incoming,
  output logic [WIDTH-1:0] syncd
);

// TODO: Validate parameters
// (This does not work in Quartus)
/*
if (DEPTH < 2 || DEPTH > 9) begin: invalid_parameters_1
  $error("DEPTH must be between 2 and 9");
end: invalid_parameters_1
if (WIDTH < 1) begin: invalid_parameters_2
  $error("WIDTH must be at least 1");
end: invalid_parameters_2
*/

// Intel/Altera synthesis attributes (see reference above for Vivado version)
// Vivado: (* IOB = "false" *) (* ASYNC_REG = "TRUE" *)
(* useioff = 0 *) // https://www.intel.com/content/www/us/en/docs/programmable/683283/18-1/use-i-o-flipflops.html
(* PRESERVE *) // https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/hdl/vlog/vlog_file_dir_preserve.htm
(* syn_preserve = 1 *) // https://www.intel.com/content/www/us/en/docs/programmable/683283/18-1/preserve-registers.html
(* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION \"FORCED IF ASYNCHRONOUS\"" *) // https://www.intel.com/content/www/us/en/docs/programmable/683296/22-4/fitterassignmentssynchronizeridentification.html
logic [DEPTH-1:0] chain [WIDTH]; // Using unpacked array is really hard!

`ifdef IS_QUARTUS
// This makes QuestaSim unhappy
initial begin
  for (int i = 0; i < WIDTH; i++) begin: zero_init
    chain[i] = '0;
  end: zero_init
end
`endif

// Synchronizer chain as a shift register
always_ff @(posedge clk) begin
  for (int i = 0; i < WIDTH; i++) begin: shift_each_chain
    chain[i] <= {chain[i][DEPTH-2:0], incoming[i]};
  end: shift_each_chain
end

always_comb begin
  for (int i = 0; i < WIDTH; i++) begin: output_end_of_each_chain
    syncd[i] = chain[i][DEPTH-1];
  end: output_end_of_each_chain
end

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif