// Ethernet Transceiver - Top Level
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer
//
// Handles everything for a Marvell 88E1111 Ethernet PHY
// including TX, RX and Management Interface


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module ethernet_trx_88e1111 #(
  // How big both the receive and send buffers are in packets
  // 2 ^ BUFFER_SIZE_BITS
  parameter BUFFER_NUM_ENTRY_BITS = 3, // 8 entries, i.e. 16kB RAM
  // How big each packet is
  parameter BUFFER_ENTRY_SZ = 11, // 2kB = 11 bits
  // Total RAM size
  parameter BUFFER_SZ = BUFFER_NUM_ENTRY_BITS + BUFFER_ENTRY_SZ,

  // FIFO depth is 2 ^ BUFFER_SIZE_BITS long too
  parameter RX_FIFO_WIDTH = 16,
  // TX FIFO width = buffer bits + entry size = RAM size
  parameter TX_FIFO_WIDTH = BUFFER_SZ,

  // Pass to mii_management_interface - see that for description
  parameter MII_CLK_DIV = 32,
  parameter MII_PHY_ADDRESS = 5'b0_0000,
  // 50MHz = 50,000 cycles per ms
`ifdef IS_QUARTUS
  parameter CLOCKS_FOR_5ms = 250_000
`else
  // Set a faster number for simulation
  parameter CLOCKS_FOR_5ms = 50
`endif

) (
  // All of our various clocks
  input  logic clk, // System clock
  input  logic clk_125, // 125 MHz clock for Ethernet TX 1000
  input  logic clk_25, // 25 MHz clock for Ethernet TX 100
  input  logic clk_2p5, // 2.5 MHz clock for Ethernet TX 10
  input  logic reset,

  ///////////////////////////////////////////////////////
  // RGMII PHY RX INTERFACE

  // Marvell 88E1111 Data Sheet, Section 2.2.3
  // RGMII RX_CTL is on the RX_DV pin:
  // RX_DV is encoded on the rising edge of RX_CLK, 
  // RX_ER XORed with RX_DV is encoded on the falling edge.

  // Our receive clock from PHY
  input  logic clk_rx,

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
  // PHY Status outputs (From RX in-band data)
  // These should be synchronized in the receiver?

  // From interframe in-band data
  output logic link_up,
  output logic full_duplex,
  output logic speed_1000,
  output logic speed_100,
  output logic speed_10,

  ////////////////////////////////////////////////////
  // RX Debugging outputs
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
  // RX RAM & FIFO Outputs

  // RAM read - in its own clock domain
  input  logic                 clk_rx_ram_rd,
  input  logic                 rx_ram_rd_ena, // Read enable
  input  logic [BUFFER_SZ-1:0] rx_ram_rd_addr, // Read address
  output logic           [7:0] rx_ram_rd_data, // Read data output

  // FIFO read - in its own clock domain
  input  logic                     clk_rx_fifo_rd, // Usually same as clk_ram_rd
  output logic                     rx_fifo_rd_empty,
  input  logic                     rx_fifo_rd_req,
  output logic [RX_FIFO_WIDTH-1:0] rx_fifo_rd_data,

  ////////////////////////////////////////////////////
  // TX (simplified, fixed packet)

  // RGMII TX PHY OUTPUTS ///////////////////////
  // Our generated appropriate speed clock output
  output logic clk_gtx,
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

  ///////////////////////////////////////////////////
  // TX API 

  // FIXME: Remove the tx_activate with the new rgmii tx top level
  // Should we send something?
  input  logic tx_activate, // SYNCHRONIZED
  // Are we currently sending something?
  output logic tx_busy,

  // Export the tx RAM & FIFO out of this module
  // RAM writer inputs
  input  logic                 clk_tx_ram_wr,
  input  logic                 tx_ram_wr_ena,
  input  logic [BUFFER_SZ-1:0] tx_ram_wr_addr,
  input  logic           [7:0] tx_ram_wr_data,

  // FIFO writer inputs
  input  logic                  clk_tx_fifo_wr,
  input  logic                  tx_fifo_aclr,
  input  logic                  tx_fifo_wr_full,
  input  logic                  tx_fifo_wr_req,
  input  logic [TX_FIFO_WIDTH-1:0] tx_fifo_wr_data,

  ////////////////////////////////////////////////////
  // TX Debugging outputs

  output logic [31:0] tx_crc_out,

  ////////////////////////////////////////////////////
  // PHY Management Interface

  // MDIO Bus - pass through to MII management interface
  // These need to be connected to a tristate buffered output pin
  input  logic mdio_i,    // MDIO input
  output logic mdio_o,    // MDIO output
  output logic mdio_e,    // MDIO output enabled
  output logic mdc,       // MDC clock (generated from 1/4 of 1/CLK_DIV of system clk)
  output logic phy_reset, // Positive ETH PHY reset signal
  
  // Outputs about what's going on
  output logic mii_busy,    // This controller is busy
  output logic mii_success, // When busy -> !busy, did we complete the last request successfully?
  
  // Passthrough to MII management interface
  // (when the controller & the underlying is not busy)
  // This adds 1 cycle latency on all requests to MII
  input  logic        mii_activate,    // True to begin when !busy
  input  logic        mii_read,        // True to do a read operation, false for write
  input  logic  [4:0] mii_register,    // Register to read/write
  input  logic [15:0] mii_data_out,    // Data to send when !read
  output logic [15:0] mii_data_in,     // Data read when read

  // Assert this anytime we failed to get expected response in configuration
  output logic phy_configured,  // When RX and TX are ready to be used
  output logic phy_config_error,

  // MII Debugging outputs
  output logic  [5:0] d_state,
  output logic [15:0] d_reg0,
  output logic [15:0] d_reg20,
  output logic [15:0] d_seen_states,
  output logic [15:0] d_soft_reset_checks
);

// TODO: Reset sequencing:
// Incoming reset to everything
// RX gets reset if MII not configured
// TX gets reset if MII not configured or link not up 
//    (should be TX_DV false when in reset)
// TX gets reset if the speed is changing for a while before
//    clock changeover
// PHY outgoing reset signal handled by MII controller

// TODO: TX clock multiplexer based on RX speed

//////////////////////////////////////////////////////////////////////////////////////////
// Management interface

// Marvell 88E1111 section 4.10.2 (Rev. M) says the MII setup time
// for 10 Mbps is 10ns, and hold time is zero. Same for 100.
// For 1000, section 4.12.2.1 says setup time is 1ns and hold is 0.8ns.
//
// At startup, Register 20.1 is 0 (no delay for TXD outputs)
// and Register 20.7 is 0 (no added delay for RX_CLK).
// Our Controller resets those to 1, to allow us to receive data
// and send data synchronously with the received and transmitted clocks.

eth_phy_88e1111_controller #(
  .CLK_DIV(MII_CLK_DIV),
  .PHY_MII_ADDRESS(MII_PHY_ADDRESS)
) eth_phy_88e1111_controller (
  // Controller clock & reset
  .clk(clk),
  .reset(reset),

  // External management bus connections
  .mdc(mdc),
  .mdio_e(mdio_e), .mdio_i(mdio_i), .mdio_o(mdio_o),
  .phy_reset(phy_reset),

  // Status
  .busy(mii_busy),
  .success(mii_success),

  // Management interface passthrough:
  // This adds 1 cycle latency on all requests to MII
  .mii_activate(mii_activate),
  .mii_read    (mii_read),
  .mii_register(mii_register),
  .mii_data_out(mii_data_out), // Data being written
  .mii_data_in (mii_data_in),  // Data being read

  // Status outputs
  .configured  (phy_configured),
  .config_error(phy_config_error),

  // Debugging outputs
  .d_state            (d_state),
  .d_reg0             (d_reg0),
  .d_reg20            (d_reg20),
  .d_seen_states      (d_seen_states),
  .d_soft_reset_checks(d_soft_reset_checks)
);





////////////////////////////////////////////////////////////////////////////
// RX Interface

rgmii_rx ethernet_rx (
  .clk_rx(clk_rx), // Use CLOCK_50 if using BOGUS Ethernet Receiver
  .reset (reset), // FIXME: Implement reset sequencer
  .ddr_rx('0), // SYNCHRONIZED (but should be very slow changing) - UNUSED

  // Inputs from PHY (after DDR conversion)
  .rx_ctl_h (rx_ctl_h), // RX_DV
  .rx_ctl_l (rx_ctl_l), // RX_ER XOR RX_DV
  .rx_data_h(rx_data_h),
  .rx_data_l(rx_data_l),

  // Status & Debugging outputs
  .link_up    (link_up),
  .full_duplex(full_duplex),
  .speed_1000 (speed_1000),
  .speed_100  (speed_100),
  .speed_10   (speed_10),

  .in_band_differ(in_band_differ),
  .in_band_h     (in_band_h),
  .in_band_l     (in_band_l),

  // Debugging counters
  .count_interframe       (count_interframe),
  .count_reception        (count_reception),
  .count_receive_err      (count_receive_err),
  .count_carrier          (count_carrier),
  .count_interframe_differ(count_interframe_differ),

  .count_rcv_end_normal     (count_rcv_end_normal),
  .count_rcv_end_carrier    (count_rcv_end_carrier),
  .count_rcv_errors         (count_rcv_errors),
  .count_rcv_dropped_packets(count_rcv_dropped_packets),

  // RAM read interface
  .clk_ram_rd (clk_rx_ram_rd),
  .ram_rd_ena (rx_ram_rd_ena), // Read enable
  .ram_rd_addr(rx_ram_rd_addr), // Read address
  .ram_rd_data(rx_ram_rd_data), // Read data output

  // FIFO read interface
  .clk_fifo_rd  (clk_rx_fifo_rd), // Usually same as clk_ram_rd
  .fifo_rd_empty(rx_fifo_rd_empty),
  .fifo_rd_req  (rx_fifo_rd_req),
  .fifo_rd_data (rx_fifo_rd_data)
);




////////////////////////////////////////////////////////////////////////////
// TX Interface with Clock Manager (multiplexer following RX speed output)

// The clock we should use for transmit
logic clock_eth_tx;
// Whether the transmitter should be in reset (usually during clock changes)
logic reset_tx;

logic tx_speed_1000, tx_speed_100, tx_speed_10;
logic tx_link_up, tx_changing;


tx_clock_manager tx_clock_manager_inst (
  .clk, .reset,

  .clock_125(clk_125),
  .clock_25(clk_25),
  .clock_2p5(clk_2p5),

  // PHY RX inputs - unsynchronzed (uses the RX clock domain)
  .rx_speed_10(speed_10),
  .rx_speed_100(speed_100),
  .rx_speed_1000(speed_1000),
  .rx_link_up(link_up),

  // TX MAC outputs
  .tx_speed_10,
  .tx_speed_100,
  .tx_speed_1000,
  .clk_tx(clock_eth_tx),
  .reset_tx,

  // Other outputs
  .link_up(tx_link_up),
  .changing(tx_changing)
);

rgmii_tx_top ethernet_tx (
  .clk_tx(clock_eth_tx),
  .reset(reset_tx), // This reset_tx will be one cycle later than reset if we don't do || reset, which is probably okay
  .ddr_tx(tx_speed_1000), // 0 for 10/100, 1 for 1000

  .busy(tx_busy),

  // Ethernet PHY interface
  .gtx_clk(clk_gtx), // Should be the same as tx_clk input above
  .tx_data_h(tx_data_h),
  .tx_data_l(tx_data_l),
  .tx_ctl_h(tx_ctl_h),
  .tx_ctl_l(tx_ctl_l),

  // Transmit RAM and FIFO that we can (only) write to
  .clk_ram_wr(clk_tx_ram_wr),
  .ram_wr_ena(tx_ram_wr_ena),
  .ram_wr_addr(tx_ram_wr_addr),
  .ram_wr_data(tx_ram_wr_data),
  .clk_fifo_wr(clk_tx_fifo_wr),
  .fifo_aclr(tx_fifo_aclr),
  .fifo_wr_full(tx_fifo_wr_full),
  .fifo_wr_req(tx_fifo_wr_req),
  .fifo_wr_data(tx_fifo_wr_data),

  // Debug ports
  .crc_out(tx_crc_out)
);




endmodule



`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa