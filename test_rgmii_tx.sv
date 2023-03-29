// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps
// This makes for approximately 320ns between I2C clock pulses when
// things are running stable-state.
module test_rgmii_tx();

// Simulator generated clock & reset
logic  clk;
logic  reset;


////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
always begin
  // 2.5 MHz = 200 (one full cycle every 400 ticks at 1ns per tick per above)
  // 25 MHz = 20
  // 125 MHz = 4
  #200 clk <= ~clk;
end

logic activate = '0;
logic busy;

logic [3:0] tx_data;
logic [3:0] tx_data_h;
logic [3:0] tx_data_l;
logic tx_ctl_h, tx_ctl_l;
logic tx_ctl;
logic gtx_clk;
logic [31:0] crc;
logic [31:0] crc_final; // XOR'd with the final value

rgmii_tx dut (
  .tx_clk(clk),
  .reset('0),
  .ddr_tx('1), // Test with DDR now
  .activate(activate),
  .busy(busy),
  .gtx_clk(gtx_clk),
  .tx_data_h(tx_data_h),
  .tx_data_l(tx_data_l),
  .tx_ctl_h(tx_ctl_h),
  .tx_ctl_l(tx_ctl_l),
  .crc_out(crc)
);

// Make our DDR "actual output" signals
always_comb begin
  tx_data = gtx_clk ? tx_data_h : tx_data_l;
  tx_ctl  = (gtx_clk && tx_ctl_h)  || (!gtx_clk && tx_ctl_l);
  crc_final = crc ^ 32'hFFFF_FFFF;
end

// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #22; reset <= 1'b0;

  activate <= '1;
  #2000;
  activate <= '0;

  // Stop the simulation at appropriate point
  #64000;
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif