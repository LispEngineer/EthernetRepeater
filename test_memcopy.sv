// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module test_memcopy();

// Simulator generated clock & reset
logic  clk;
logic  reset;


////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
localparam CLOCK_DUR = 8; // 125 MHz
localparam HALF_CLOCK_DUR = CLOCK_DUR / 2;
always begin
  // 2.5 MHz = 200 (one full cycle every 400 ticks at 1ns per tick per above)
  // 25 MHz = 20
  // 125 MHz = 4
  #(HALF_CLOCK_DUR) clk <= ~clk;
end

// Source and destination memories

localparam SRC_ADDR_SZ = 10;
localparam DST_ADDR_SZ = 9;

logic clk_src_rd;
logic clk_dst_wr;

logic [DST_ADDR_SZ-1:0] dst_wr_addr;
logic [SRC_ADDR_SZ-1:0] src_rd_addr;
logic [7:0] src_rd_data;
logic [7:0] dst_wr_data;
logic src_rd_en;
logic dst_wr_en;

test_ram_src test_ram_src_inst (
	.rdclock(clk_src_rd),
	.rden(src_rd_en),
	.rdaddress(src_rd_addr),
	.q(src_rd_data),
  // We aren't writing to the source... for now
	.wrclock(),
	.wren(),
	.wraddress(),
	.data()
);

test_ram_dst test_ram_dst_inst (
  // We aren't reading the destination... for now
	.rdclock(),
	.rden(),
	.rdaddress(),
	.q(),

	.wrclock(clk_dst_wr),
	.wren(dst_wr_en),
	.wraddress(dst_wr_addr),
	.data(dst_wr_data)
);

// Memory copier
logic busy;
logic activate = '0;

logic [DST_ADDR_SZ-1:0] dst_addr;
logic [SRC_ADDR_SZ-1:0] src_addr;
logic [SRC_ADDR_SZ-1:0] src_len;

memcopy #(
  .SRC_ADDR_SZ(SRC_ADDR_SZ),
  .DST_ADDR_SZ(DST_ADDR_SZ)
) dut (
  .clk,
  .reset,

  // Memory copier status
  .busy,

  // Memory copier API
  .activate,
  .src_addr, // Starting address of copy
  .dst_addr, // Destination address of copy
  .src_len,  // Length of copy

  // Source RAM reader interface
  .clk_ram_rd(clk_src_rd),
  .ram_rd_ena(src_rd_en),
  .ram_rd_addr(src_rd_addr),
  .ram_rd_data(src_rd_data),

  // Destination RAM writer interface
  .clk_ram_wr(clk_dst_wr),
  .ram_wr_ena(dst_wr_en),
  .ram_wr_addr(dst_wr_addr),
  .ram_wr_data(dst_wr_data)
);



// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #21; reset <= 1'b0;

  // Simple copy of 10 words
  #79;
  src_addr <= 1;
  dst_addr <= 10;
  src_len <= 20;
  #(CLOCK_DUR);
  activate <= '1;
  #(CLOCK_DUR);
  activate <= '0;

  // Single word
  #((20 + 10) * CLOCK_DUR);
  src_addr <= 40;
  dst_addr <= 40;
  src_len <= 1;
  #(CLOCK_DUR);
  activate <= '1;
  #(CLOCK_DUR);
  activate <= '0;

  // Degenerate case - 0 words
  #(10 * CLOCK_DUR);
  src_addr <= 60;
  dst_addr <= 60;
  src_len <= 0;
  #(CLOCK_DUR);
  activate <= '1;
  #(CLOCK_DUR);
  activate <= '0;

  // Longer example
  #(10 * CLOCK_DUR);
  src_addr <= 260;
  dst_addr <= 400;
  src_len <= 100;
  activate <= '1;
  #(CLOCK_DUR);
  activate <= '0;

  // Write wrap-around
  // [Did not work correctly]: gets 8 194 {wrap} 193 192 191
  // Expected: 8 13 18 23 28
  // FIXED
  #(110 * CLOCK_DUR);
  src_addr <= 827; // 3 then by 5s
  dst_addr <= 510;
  src_len <= 5;
  activate <= '1;
  #(CLOCK_DUR);
  activate <= '0;

  // Read wrap-around
  // [Did not work correctly]: gets 213 1 0 2 0 1 2 3 4 5 ...
  // should be 213 (wrong) 206 199 192 (correct) 0 1 2 3
  // FIXED
  #(15 * CLOCK_DUR);
  src_addr <= 1020; // 213 206 199 192 0 1 2 3 ...
  dst_addr <= 100;
  src_len <= 20;
  activate <= '1;
  #(CLOCK_DUR);
  activate <= '0;

  #(30 * CLOCK_DUR);
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif