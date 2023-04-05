// Ethernet Repeater - RGMII Receiver Top Level
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer
//
// See rgmii_rx.md for details.
// NOTE: SINGLE CLOCK MODULE!

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module rgmii_rx_impl #(
  // 2 ^ BUFFER_SIZE_BITS
  parameter BUFFER_NUM_ENTRY_BITS = 3, // 8 entries, i.e. 16kB RAM
  parameter BUFFER_ENTRY_SZ = 11, // 2kB = 11 bits
  // Total RAM size
  parameter BUFFER_SZ = BUFFER_NUM_ENTRY_BITS + BUFFER_ENTRY_SZ,
  // FIFO depth is 2 ^ BUFFER_SIZE_BITS long too
  parameter FIFO_WIDTH = 16,
  // For testing
  parameter BOGUS_GENERATOR_DELAY = 2_000
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

  // RAM & FIFO Interface ///////////////////////////////////

  // RAM writer - synchronous to clk_rx
  input  logic                 ram_wr_ena,  // Write enable
  input  logic [BUFFER_SZ-1:0] ram_wr_addr, // Write address
  output logic           [8:0] ram_wr_data, // Write data output

  // FIFO writer - synchronous to clk_rx
  output logic                  fifo_aclr, // Asynchronous clear
  input  logic                  fifo_wr_full,
  input  logic                  fifo_wr_req,
  output logic [FIFO_WIDTH-1:0] fifo_wr_data

  ////////////////////////////////////////////////////
  // Debugging outputs
);

///////////////////////////////////////////////////////////////////
// Bogus RGMII Receiver to test the RAM and FIFO

// Simple state machine:
// 1. Wait a bit (make it a parameter)
// 2. Start a new packet
// 3. Write a bogus frame header: PREAMBLE, SFD
// 4. Write a bunch of RAM of length packet number * 16 + 64
//    with the same byte as the packet number + 0x21 (ASCII 0)
// 5. Write a real CRC 4 bytes
// 6. Pass the packet to the FIFO
// 7. Repeat


// RGMII Receiver /////////////////////////////////////////////////

endmodule // rgmii_rx


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa