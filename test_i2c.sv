// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps
// This makes for approximately 320ns between I2C clock pulses when
// things are running stable-state.
module test_i2c();

// Simulator generated clock & reset
logic  clk;
logic  reset;

// The internal wires for I2C bus for Controller
logic scl_i, scl_o, scl_e;
logic sda_i_c, sda_o_c, sda_e_c;
// Wires for the I2C bus for Target
logic sda_i_t, sda_o_t, sda_e_t;

// Status of I2C controller
logic i2c_busy, i2c_abort, i2c_success;

// Debugging of i2c
logic i2c_start, i2c_stop, i2c_ack;

// Output of the test target
logic start_seen, stop_seen, in_transaction;

// Should we do the activate thing
logic i2c_activate;

// What should we activate?
logic [6:0] i2c_address;
logic       i2c_readnotwrite;
logic [7:0] i2c_location; // Data 1
logic [7:0] i2c_data;     // Data 2
logic       i2c_read_two; // Read two bytes (if true) or one (if false)

// What data did we read back from I2C read operation
logic [7:0] i2c_read_data1;
logic [7:0] i2c_read_data2;

////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
always begin
  // 50 Mhz (one full cycle every 20 ticks at 1ns per tick per above)
  #10 clk <= ~clk;
end


// instantiate device to be tested (Device Under Test)
I2C_CONTROLLER #(
  .CLK_DIV(4)
) dut (
  // Controller clock & reset
	.clk(clk),
	.reset(reset),
	
  // External I2C Bus connections
	.scl_i(scl_i),   .scl_o(scl_o),   .scl_e(scl_e),
	.sda_i(sda_i_c), .sda_o(sda_o_c), .sda_e(sda_e_c),
	
  // I2C controller status
	.busy(i2c_busy),
	.abort(i2c_abort), 
  .success(i2c_success),

  // I2C request inputs
	.activate(i2c_activate),
	.address (i2c_address),   // Initially: 7'b011_1100 -> 0111_1000 = 0x78 with read/not-write bit
	.read    (i2c_readnotwrite),
	.location(i2c_location),
	.data    (i2c_data),
  .data_repeat(3'd0),
  .read_two(i2c_read_two),

  // I2C Outputs
  .data1(i2c_read_data1),
  .data2(i2c_read_data2),

  // I2C Controller debugging outputs
	.start_pulse(i2c_start),
	.stop_pulse (i2c_stop),
  .got_ack    (i2c_ack)
);

// Our test target; address is 0x55 by default (plus a r/w-bar -> 0xAA, 0xAB)
test_i2c_target test_target (
  .clk(clk),
  .reset(reset),
  // FIXME: Make it 1 when Controller scl_e is not asserted
  .scl_i(scl_o),    // Input only; no clock stretching implemented

  .sda_i(sda_i_t),
  .sda_o(sda_o_t),
  .sda_e(sda_e_t),

  .start_seen(start_seen),
  .stop_seen(stop_seen),
  .in_transaction(in_transaction)
);

// Connect the SDA's together in I2C Controller & Target
always_comb begin
  if (sda_e_c && sda_e_t) begin
    // They are both driving output to SDA, so neither should be
    // looking at their input.
    // Should these be X's or Z's? 
    // Or should they be 0 if either out is 0? Probably this one.
    // But if they are x it will be easier to see simulation problems.
    sda_i_c = 1'bx;
    sda_i_t = 1'bx;
  end else if (sda_e_c) begin
    // Only controller is driving SDA
    sda_i_c = 1'bx; // Controller shouldn't be looking
    sda_i_t = sda_o_c;
  end else if (sda_e_t) begin
    // Only target is driving SDA
    sda_i_c = sda_o_t;
    sda_i_t = 1'bx; // Target shouldn't be looking
  end else begin
    // Neither is driving SDA, so I2C will be high due to pull-ups
    sda_i_c = 1'b1;
    sda_i_t = 1'b1; // Pull-up
  end
end // Connection of SDAs together


// Test commands to send from controller to target
// Instantiate our state machine to program the ADV7513,
// which does it via I2C
test_script test_script (
  .clk(clk),
  .rst(reset),
  
  .i2c_activate(i2c_activate),
  .i2c_busy(i2c_busy),
  .i2c_success(i2c_success),
  .i2c_abort(i2c_abort),

  .i2c_address(i2c_address),
  .i2c_readnotwrite(i2c_readnotwrite),
  .i2c_byte1(i2c_location),
  .i2c_byte2(i2c_data),
  .i2c_read_two(i2c_read_two),

  .i2c_read_byte1(i2c_read_data1),
  .i2c_read_byte2(i2c_read_data2),
  
  // Unconnected status signals
  .active(),
  .done  ()
);


// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #22; reset <= 1'b0;
  // Stop the simulation at appropriate point
  // FIXME: Make it stop when test_script is done
  #48000;
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule















`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif