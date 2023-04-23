// Ethernet Repeater - RGMII Transmit top-level
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer
//
// See rgmii_tx.md for details

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

// This module is usually in its own clock domain (tx_clk).
// This module outputs data and clock completely aligned.
// If the `gtx_clk` needs to be skewed, it has to happen outside of here.


// This top-level instantiates FIFO & RAM and passes them to rgmii_tx
// (the implementation module) and up to the instantanting module.


module rgmii_tx_top #(
  parameter BUFFER_NUM_ENTRY_BITS = 3, // 8 entries, i.e. 16kB RAM
  parameter BUFFER_ENTRY_SZ = 11, // 2kB = 11 bits per buffer entry
  // Total RAM size
  parameter BUFFER_SZ = BUFFER_NUM_ENTRY_BITS + BUFFER_ENTRY_SZ,
  // FIFO depth is 2 ^ BUFFER_SIZE_BITS long too
  // FIFO entries are {buffer, length}
  parameter FIFO_WIDTH = BUFFER_SZ,
  parameter FIFO_RD_LATENCY = 2,
  parameter RAM_RD_LATENCY = 2
) (
  // Our appropriate speed clock input (copied to output)
  input  logic clk_tx,
  input  logic reset,

  // Should we send in DDR for data?
  input  logic ddr_tx,

  // Are we currently sending something?
  output logic busy,

  // RGMII OUTPUTS ///////////////////////
  // Our generated appropriate speed clock output
  output logic gtx_clk,
  // The data outputs in DDR mode:
  // Send H while the clock is high [3:0]
  // Send L while the clock is low [7:4]
  // See: https://docs.xilinx.com/r/en-US/pg160-gmii-to-rgmii/RGMII-Interface-Protocols
  // or see RGMII spec section 3.0
  output logic [3:0] tx_data_h,
  output logic [3:0] tx_data_l,
  // The transmit control output in DDR mode:
  // This means the output stays high during transmission
  // and low during non-transmission, in the absence of errors.
  output logic tx_ctl_h, // TX_EN
  output logic tx_ctl_l,  // TX_ERR XOR TX_EN

  // RAM writer inputs
  input  logic                 clk_ram_wr,
  input  logic                 ram_wr_ena,
  input  logic [BUFFER_SZ-1:0] ram_wr_addr,
  input  logic           [7:0] ram_wr_data,

  // FIFO writer inputs
  input  logic                  clk_fifo_wr,
  input  logic                  fifo_aclr,
  input  logic                  fifo_wr_full,
  input  logic                  fifo_wr_req,
  input  logic [FIFO_WIDTH-1:0] fifo_wr_data,

  ////////////////////////////////////////////////////
  // Debugging outputs
  output logic [31:0] crc_out
);



// Instantiate FIFO
logic fifo_rd_empty;
logic fifo_rd_req;
logic [BUFFER_SZ-1:0] fifo_rd_data;

tx_fifo	tx_fifo_inst (
	.rdclk  (clk_tx),
	.rdempty(fifo_rd_empty),
	.rdreq  (fifo_rd_req),
	.q      (fifo_rd_data),

	.wrclk (clk_fifo_wr),
	.aclr  (fifo_aclr),
	.wrfull(fifo_wr_full),
	.wrreq (fifo_wr_req),
	.data  (fifo_wr_data)
);


// Instantiate RAM
logic                 ram_rd_ena;
logic [BUFFER_SZ-1:0] ram_rd_addr; // Read address
logic           [7:0] ram_rd_data; // Read data output


`define USE_REGISTERED_INPUT_RAM
`ifdef USE_REGISTERED_INPUT_RAM
// This will have two cycle latency
tx_ram_buffer_registered
`else
// FIXME: Make a tx_ram_buffer_fast with properly initialized memory
// This will have one cycle latency as the outputs are unregistered
rx_ram_buffer_fast
`endif
tx_ram_buffer_inst (
	.rdclock   ( clk_tx ),
  .rden      ( ram_rd_ena ),
	.rdaddress ( ram_rd_addr ),
	.q         ( ram_rd_data ),

	.wrclock   ( clk_ram_wr ),
  .wren      ( ram_wr_ena ),
	.wraddress ( ram_wr_addr ),
	.data      ( ram_wr_data )
);



// Instantiate rgmii_tx

rgmii_tx #(
  .BUFFER_NUM_ENTRY_BITS(BUFFER_NUM_ENTRY_BITS),
  .BUFFER_ENTRY_SZ(BUFFER_ENTRY_SZ),
  .BUFFER_SZ(BUFFER_SZ),
  .FIFO_WIDTH(FIFO_WIDTH),
  .FIFO_RD_LATENCY(FIFO_RD_LATENCY),
  .RAM_RD_LATENCY(RAM_RD_LATENCY)
) rgmii_tx_inst (
  // Our appropriate speed clock input (copied to output)
  .clk_tx,
  .reset,
  .ddr_tx, // SYNCHRONIZED (but should be very slow changing)
  .busy,
  .gclk_tx(gtx_clk),
  .tx_data_h,
  .tx_data_l,
  .tx_ctl_h, // TX_EN
  .tx_ctl_l,  // TX_ERR XOR TX_EN
  .ram_rd_ena,
  .ram_rd_addr, // Read address
  .ram_rd_data, // Read data output
  .fifo_rd_empty,
  .fifo_rd_req,
  .fifo_rd_data,
  .crc_out
);



endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa