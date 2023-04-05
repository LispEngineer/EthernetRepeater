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
`ifdef IS_QUARTUS
  parameter BOGUS_GENERATOR_DELAY = 2_000
`else
  parameter BOGUS_GENERATOR_DELAY = 25
`endif
) (
  // Our appropriate speed clock input,
  // delayed 90 degrees from raw input,
  // so that the DDR sample/hold times will be met
  input  logic clk_rx,
  input  logic reset,

  // Should we receive data in DDR?
  // This is only used for 1000
  // FIXME: Do not use this, see the in-band signalling
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
  output logic                 ram_wr_ena,  // Write enable
  output logic [BUFFER_SZ-1:0] ram_wr_addr, // Write address
  output logic           [7:0] ram_wr_data, // Write data output

  // FIFO writer - synchronous to clk_rx
  output logic                  fifo_aclr, // Asynchronous clear
  input  logic                  fifo_wr_full,
  output logic                  fifo_wr_req,
  output logic [FIFO_WIDTH-1:0] fifo_wr_data

  ////////////////////////////////////////////////////
  // Debugging outputs
);

// How many packets did we drop because we
// could not put them into the FIFO due to wr_full?
logic [31:0] dropped_packets = '0;

/////////////////////////////////////////////////////////////////
// Input synchronizer

// Synchronizer for inputs
localparam SYNC_LEN = 2;
logic [(SYNC_LEN - 1):0] syncd_ddr_rx;
logic real_ddr_rx;
// Registered real_ddr_rx when we become activated
logic txn_ddr;

always_ff @(posedge clk_rx) begin
  syncd_ddr_rx <= {syncd_ddr_rx[(SYNC_LEN - 2):0], ddr_rx};
end // synchronizer



`define BOGUS
`ifdef BOGUS

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
//    a. If the FIFO is full, increment a dropped packet
//       counter instead
//    b. ALTERNATIVE: Wait N cycles for FIFO to drain,
//       simulating a typical interpacket delay, before
//       giving up and dropping the packet.
// 7. Repeat

localparam S_WAIT = 3'd0,
           S_HEADER = 3'd1, // The 8-byte preamble with SFD
           S_DATA = 3'd2, // Our actual packet data including Eth header
           S_CRC = 3'd3, // The CRC (FCS)
           S_FIFO = 3'd4; // Put the frame into the FIFO

logic [2:0] state = S_WAIT;
logic [BUFFER_NUM_ENTRY_BITS-1:0] cur_buf;
logic [BUFFER_ENTRY_SZ-1:0] byte_pos; // Position within a packet
// A count used within any state for its own purposes
logic [BUFFER_ENTRY_SZ-1:0] local_count = BOGUS_GENERATOR_DELAY;

// Our current index into our RAM
// Comprised of which buffer we are doing and
// which byte we're doing within that buffer.
logic [BUFFER_SZ-1:0] ram_pos;

assign ram_pos = {cur_buf, byte_pos};

always_ff @(posedge clk_rx) begin

  if (reset) begin

    state <= S_WAIT;
    local_count <= BOGUS_GENERATOR_DELAY;
    cur_buf <= '0;

    // Clear the FIFO
    fifo_aclr <= '1;
    ram_wr_ena <= '0;
    fifo_wr_req <= '0;

  end else begin // !reset

    // We never want to clear the FIFO in normal operation
    fifo_aclr <= '0;

    case (state)
    S_WAIT: begin

      ram_wr_ena <= '0;
      fifo_wr_req <= '0;

      if (local_count == '0) begin
        cur_buf <= cur_buf + 1'd1;
        state <= S_HEADER;
        local_count <= 7; // 8 byte preamble 
        byte_pos <= '0;
      end else begin
        local_count <= local_count - 1'd1;
      end
    end // S_WAIT

    S_HEADER: begin // Write the 8-byte preamble with SFD

      // Write our current byte (next cycle)
      ram_wr_ena <= '1;
      // Remember wire order is 10101010..11, which is LSB first!
      ram_wr_data <= local_count != '0 ? 8'b0101_0101 : 8'b1101_0101;
      ram_wr_addr <= ram_pos;
      // And advance
      byte_pos <= byte_pos + 1'd1;
      if (local_count == 0) begin
        state <= S_DATA;
      end else begin
        local_count <= local_count - 1'd1;
      end

    end // S_HEADER

    S_DATA: begin // Write the packet data including Eth header
      // Write our byte (next cycle)
      ram_wr_ena <= '1;
      ram_wr_addr <= ram_pos;
      // Advance to the next byte
      byte_pos <= byte_pos + 1'd1;

      // Figure out the data to write
      if (local_count < 6)
        // Ethernet destination address
        ram_wr_data <= 8'hFF;
      else if (local_count < 12)
        // Ethernet source address
        ram_wr_data <= 8'hDF;
      else if (local_count < 14)
        // EtherType (or length)
        ram_wr_data <= local_count == 12 ? 8'hC5 : 8'hDF;
      else
        // The payload is the buffer # as a current digit
        ram_wr_data <= 8'h21 + cur_buf;

      // We write 64 bytes of data then move to CRC
      if (local_count == 63) begin
        state <= S_CRC;
        local_count <= '0;
      end else begin
        local_count <= local_count + 1'd1;
      end

    end // S_DATA

    S_CRC: begin
      // Write four bytes of (BOGUS) CRC / FCS
      ram_wr_ena <= '1;
      ram_wr_addr <= ram_pos;
      // Advance to the next byte
      byte_pos <= byte_pos + 1'd1;
      ram_wr_data <= 8'hBB;

      if (local_count == 3) begin
        // All done
        local_count <= '0;
        state <= S_FIFO;
      end else begin
        local_count <= local_count + 1'd1;
      end
      
    end // S_CRC

    S_FIFO: begin
      ram_wr_ena <= '0;
      // FIXME: CODE ME
      state <= S_WAIT;
      local_count <= BOGUS_GENERATOR_DELAY;
    end // S_FIFO

    default: begin
      state <= S_WAIT;
      local_count <= BOGUS_GENERATOR_DELAY;
    end // default
    endcase // State machine

  end // reset or not

end // Bogus State Machine


`else // NOT BOGUS

////////////////////////////////////////////////////////////////////////
// RGMII Receiver


`endif // NOT BOGUS

endmodule // rgmii_rx


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa