// Ethernet Repeater - RGMII Receiver Top Level
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer
//
// See rgmii_rx.md for details.
// NOTE: Multi-clock module!
// Instantiates the RAM & FIFO and passes them to the
// external world and the actual RGMII Receiver implementation.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module rgmii_rx #(
  // 2 ^ BUFFER_SIZE_BITS
  parameter BUFFER_NUM_ENTRY_BITS = 3, // 8 entries, i.e. 16kB RAM
  parameter BUFFER_ENTRY_SZ = 11, // 2kB = 11 bits
  // Total RAM size
  parameter BUFFER_SZ = BUFFER_NUM_ENTRY_BITS + BUFFER_ENTRY_SZ,
  // FIFO depth is 2 ^ BUFFER_SIZE_BITS long too
  parameter FIFO_WIDTH = 16
) (
  // Our appropriate speed clock input,
  // delayed 90 degrees from raw input,
  // so that the DDR sample/hold times will be met
  input  logic clk_rx,
  input  logic reset,

  // Should we receive data in DDR?
  // This is only used for 1000
  input  logic ddr_rx, // SYNCHRONIZED (but should be very slow changing)

  // RGMII PHY INTERFACE ///////////////////////

  // Marvell 88E1111 Data Sheet, Section 2.2.3
  // RGMII RX_CTL is on the RX_DV pin:
  // RX_DV is encoded on the rising edge of RX_CLK, 
  // RX_ER XORed with RX_DV is encoded on the falling edge.

  // DDR RX_CTL signal (on RX_DV Marvell pin)
  input  logic        rx_ctl_h, // RX_DV
  input  logic        rx_ctl_l, // RX_ER XOR RX_DV
  // Possibly DDR data input
  input  logic [3:0]  rx_data_h,
  input  logic [3:0]  rx_data_l,
  // The data in DDR mode:
  // Send H bits while the clock is high [3:0]
  // Send L bits while the clock is low [7:4]
  // See RGMII 2.0 spec section 3.0

  ////////////////////////////////////////////////////
  // Status outputs

  // From interframe in-band data
  output logic link_up,
  output logic full_duplex,
  output logic speed_1000,
  output logic speed_100,
  output logic speed_10,

  ////////////////////////////////////////////////////
  // Debugging outputs
  output logic in_band_differ,
  // When they differ, we share the differences
  output logic [3:0] in_band_h,
  output logic [3:0] in_band_l,

  // Debugging counters
  // How many times we began normal interframe
  output logic [31:0] count_interframe,
  // How many times we began reception
  output logic [31:0] count_reception,
  // How many times we began receive error
  output logic [31:0] count_receive_err,
  // How many times we got the Carrier Extend/Error/Sense interframe
  output logic [31:0] count_carrier,
  // How many times the H & L nibbles differed in normal interframe
  output logic [31:0] count_interframe_differ,

  // How many frames we got which ended normally
  output logic [31:0] count_rcv_end_normal,
  // How many frames we got which ended with a carrier extend
  output logic [31:0] count_rcv_end_carrier,
  // How many frames we received with at least one error in them
  output logic [31:0] count_rcv_errors,
  // How many packets we received we had to drop due to full recieve FIFO
  output logic [31:0] count_rcv_dropped_packets,

  ////////////////////////////////////////////////////
  // RAM & FIFO Outputs

  // RAM read - in its own clock domain
  input  logic                 clk_ram_rd,
  input  logic                 ram_rd_ena, // Read enable
  input  logic [BUFFER_SZ-1:0] ram_rd_addr, // Read address
  output logic           [7:0] ram_rd_data, // Read data output

  // FIFO read - in its own clock domain
  input  logic                  clk_fifo_rd, // Usually same as clk_ram_rd
  output logic                  fifo_rd_empty,
  input  logic                  fifo_rd_req,
  output logic [FIFO_WIDTH-1:0] fifo_rd_data
);

// RAM & FIFO /////////////////////////////////////////////////////

// Signals to the RX implementation for RAM & FIFO
logic ram_wr_ena;
logic [BUFFER_SZ-1:0] ram_wr_addr;
logic [7:0] ram_wr_data;
logic fifo_aclr;
logic fifo_wr_full;
logic fifo_wr_req;
logic [FIFO_WIDTH-1:0] fifo_wr_data;

// Instantiate our read & write port RAM
// `define USE_REGISTERED_OUTPUT_RAM
`ifdef USE_REGISTERED_OUTPUT_RAM
// This will have two cycle latency
rx_ram_buffer
`else
// This will have one cycle latency as the outputs are unregistered
rx_ram_buffer_fast
`endif
rx_ram_buffer_inst (
	.rdclock   ( clk_ram_rd ),
	.wrclock   ( clk_rx ),

  .rden      ( ram_rd_ena ),
	.rdaddress ( ram_rd_addr ),
	.q         ( ram_rd_data ),

  .wren      ( ram_wr_ena ),
	.wraddress ( ram_wr_addr ),
	.data      ( ram_wr_data )
);

// And here is our FIFO
rx_fifo	rx_fifo_inst (
	.rdclk   ( clk_fifo_rd ),
	.wrclk   ( clk_rx ),

  .rdempty ( fifo_rd_empty ),
	.rdreq   ( fifo_rd_req ),
	.q       ( fifo_rd_data ),

  .aclr    ( fifo_aclr ),
	.wrfull  ( fifo_wr_full ),
	.wrreq   ( fifo_wr_req ),
	.data    ( fifo_wr_data )
);

// RGMII Receiver /////////////////////////////////////////////////

rgmii_rx_impl #(
  .BUFFER_NUM_ENTRY_BITS(BUFFER_NUM_ENTRY_BITS),
  .BUFFER_ENTRY_SZ(BUFFER_ENTRY_SZ),
  .BUFFER_SZ(BUFFER_SZ),
  .FIFO_WIDTH(FIFO_WIDTH)
  // BOGUS_GENERATOR_DELAY
) rgmii_rx_impl_inst (
  .clk_rx(clk_rx),
  .reset(reset),
  .ddr_rx(ddr_rx),

  // Status & Debugging outputs
  .link_up(link_up),
  .full_duplex(full_duplex),
  .speed_1000(speed_1000),
  .speed_100(speed_100),
  .speed_10(speed_10),

  .in_band_differ(in_band_differ),
  .in_band_h(in_band_h),
  .in_band_l(in_band_l),

  .count_interframe(count_interframe),
  .count_reception(count_reception),
  .count_receive_err(count_receive_err),
  .count_carrier(count_carrier),
  .count_interframe_differ(count_interframe_differ),

  .count_rcv_end_normal(count_rcv_end_normal),
  .count_rcv_end_carrier(count_rcv_end_carrier),
  .count_rcv_errors(count_rcv_errors),
  .count_rcv_dropped_packets(count_rcv_dropped_packets),

  // PHY interface
  .rx_ctl_h(rx_ctl_h),
  .rx_ctl_l(rx_ctl_l),
  .rx_data_h(rx_data_h),
  .rx_data_l(rx_data_l),

  // RAM interface - clocked with clk_rx
  .ram_wr_ena(ram_wr_ena),
  .ram_wr_addr(ram_wr_addr),
  .ram_wr_data(ram_wr_data),

  // FIFO interface - clocked with clk_rx
  .fifo_aclr, // Asynchronous clear
  .fifo_wr_full,
  .fifo_wr_req,
  .fifo_wr_data
);


endmodule // rgmii_rx


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa