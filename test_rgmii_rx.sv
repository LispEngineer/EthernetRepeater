// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps


module test_rgmii_rx();

// Simulator generated clock & reset
logic  clk;
logic  reset;


////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
localparam period = 20;
localparam reset_period = period * 2.2;
always begin
  // 2.5 MHz = 200 (one full cycle every 400 ticks at 1ns per tick per above)
  // 25 MHz = 20
  // 125 MHz = 4
  #period clk <= ~clk;
end


rgmii_rx dut (

  .clk_rx(clk),
  .reset(reset),
  .ddr_rx('0), // SYNCHRONIZED (but should be very slow changing)

  // Inputs from PHY (after DDR conversion)
  .rx_ctl_h('0), // RX_DV
  .rx_ctl_l('0), // RX_ER XOR RX_DV
  .rx_data_h('0),
  .rx_data_l('0),

  // RAM read interface
  .clk_ram_rd(clk),
  .ram_rd_ena(), // Read enable
  .ram_rd_addr(), // Read address
  .ram_rd_data(), // Read data output

  // FIFO read interface
  .clk_fifo_rd(clk), // Usually same as clk_ram_rd
  .fifo_rd_empty(),
  .fifo_rd_req(),
  .fifo_rd_data()
);


// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #reset_period; reset <= 1'b0;

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