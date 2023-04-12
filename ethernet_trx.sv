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

  ///////////////////////////////////////////////////
  // TX API 

  // Should we send something?
  input  logic tx_activate, // SYNCHRONIZED
  // Are we currently sending something?
  output logic tx_busy,

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






endmodule



`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa