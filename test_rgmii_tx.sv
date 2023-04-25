// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

// FIXME: Update for new rgmii_tx and its top

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module test_rgmii_tx();

// Simulator generated clock & reset
logic  clk;
logic  reset;


////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
localparam CLOCK_DUR = 20;
localparam HALF_CLOCK_DUR = CLOCK_DUR / 2;
localparam USE_DDR = CLOCK_DUR == 4;
always begin
  // 2.5 MHz = 200 (one full cycle every 400 ticks at 1ns per tick per above)
  // 25 MHz = 20
  // 125 MHz = 4
  #(HALF_CLOCK_DUR) clk <= ~clk;
end

logic busy;

logic [3:0] tx_data;
logic [3:0] tx_data_h;
logic [3:0] tx_data_l;
logic tx_ctl_h, tx_ctl_l;
logic tx_ctl;
logic gtx_clk;
logic [31:0] crc;
logic [31:0] crc_final; // XOR'd with the final value

logic        ram_wr_ena;
logic [13:0] ram_wr_addr;
logic [7:0]  ram_wr_data;
logic        fifo_wr_full;
logic        fifo_wr_req;
logic [13:0] fifo_wr_data;

rgmii_tx_top dut (
  .clk_tx(clk),
  .reset('0),
  .ddr_tx(USE_DDR),
  .busy(busy),

  .gtx_clk(gtx_clk),
  .tx_data_h(tx_data_h),
  .tx_data_l(tx_data_l),
  .tx_ctl_h(tx_ctl_h),
  .tx_ctl_l(tx_ctl_l),

  .clk_ram_wr(clk),
  .ram_wr_ena,
  .ram_wr_addr,
  .ram_wr_data,

  .clk_fifo_wr(clk),
  .fifo_aclr('0), // Not using the asynchronous clear
  .fifo_wr_full,
  .fifo_wr_req,
  .fifo_wr_data,

  .crc_out(crc) // The sent CRC is this XOR '1
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

  #78;

  // Pulse FIFO for one cycle
  fifo_wr_req <= '1;
  fifo_wr_data <= {3'b0, 11'd60}; // Buffer # then buffer length - Buffer 1 is a test pattern
  #(CLOCK_DUR); 
  fifo_wr_req <= '0;

  // Stop the simulation at appropriate point
  #5000;
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif