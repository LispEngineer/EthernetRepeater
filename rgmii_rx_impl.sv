// Ethernet Repeater - RGMII Receiver Top Level
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer
//
// See rgmii_rx.md for details.
// NOTE: SINGLE CLOCK MODULE!

// Marvel 88E1111 Rev M Section 2.2.3.1:
// The MAC must hold TX_EN (TX_CTL) low until the MAC has ensured that 
// TX_EN (TX_CTL) is operating at the same speed as the PHY.

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
  // How many cycles we wait for FIFO to accept a packet
  parameter FIFO_INSERT_TRIES = 8,
  // For testing
`ifdef IS_QUARTUS
  // A packet every 2 seconds at 25MHz (100mbps) = 50_000_000
  parameter BOGUS_GENERATOR_DELAY = 50_000_000
`else
  parameter BOGUS_GENERATOR_DELAY = 25
`endif
) (
  // Our appropriate speed clock input,
  // delayed 90 degrees from raw input,
  // so that the DDR sample/hold times will be met
  input  logic clk_rx,
  input  logic reset,

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
  output logic [FIFO_WIDTH-1:0] fifo_wr_data,

  ////////////////////////////////////////////////////
  // Status outputs

  // From interframe
  output logic link_up,
  output logic full_duplex,
  output logic speed_1000,
  output logic speed_100,
  output logic speed_10,

  ////////////////////////////////////////////////////
  // Debugging outputs

  output logic in_band_differ, // Are the _h and _l different during 00 in-band?
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
  output logic [31:0] count_rcv_dropped_packets

);

// How many packets did we drop because we
// could not put them into the FIFO due to wr_full?
logic [31:0] dropped_packets = '0;



// `define BOGUS // If commented out, do our real RX receiver

`ifdef BOGUS

////////////////////////////////////////////////////////////////////////////////////////
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
logic [31:0] local_count = BOGUS_GENERATOR_DELAY;

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
        ram_wr_data <= 8'h30 + cur_buf; // 0x30 = ASCII '0'

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
      ram_wr_data <= 8'hBB + local_count[1:0];

      if (local_count == 3) begin
        // All done
        local_count <= FIFO_INSERT_TRIES;
        state <= S_FIFO;
      end else begin
        local_count <= local_count + 1'd1;
      end
      
    end // S_CRC

    S_FIFO: begin
      ram_wr_ena <= '0;
      // We insert into our FIFO if it's not full,
      // or wait another cycle, until we've waited long
      // enough and have to give up
      if (!fifo_wr_full) begin
        fifo_wr_req <= '1;
        fifo_wr_data <= {
          1'b0, // CRC error
          1'b0, // Frame error
          cur_buf,
          byte_pos
        };
      end else if (local_count == '0) begin
        // We give up
        dropped_packets <= dropped_packets + 1'd1;
      end else begin
        local_count <= local_count - 1'd1;
      end

      // We're done, let's get IDLEing
      if (!fifo_wr_full || local_count == '0) begin
        state <= S_WAIT;
        local_count <= BOGUS_GENERATOR_DELAY;
      end
    end // S_FIFO

    default: begin
      state <= S_WAIT;
      local_count <= BOGUS_GENERATOR_DELAY;
    end // default
    endcase // State machine

  end // reset or not

end // Bogus State Machine


`else // NOT BOGUS

////////////////////////////////////////////////////////////////////////////////////////
// Real RGMII Receiver

localparam S_IDLE = 4'd0,
           S_PREAMBLE = 4'd1,
           S_RECEIVING = 4'd2,
           S_FRAME_END = 4'd3;

logic [3:0] state = S_IDLE;

logic rx_nibble = '0; // Receiving low or high nibble? (low = 0, high = 1)
logic [7:0] rx_byte;  // Byte currently being received

// Retrieve the two signals from the high & low of rx_ctl
// (See RGMII Spec 3.0 and 3.4)
logic rx_dv; // High side of rx_ctl
logic rx_err; // Low side of rx_ctl as rx_dv & rx_err
logic last_rx_dv = '0, last_rx_err = '0;

// As we are receiving, we track our buffer and byte position
logic [BUFFER_NUM_ENTRY_BITS-1:0] cur_buf;
logic [BUFFER_ENTRY_SZ-1:0] byte_pos; // Position within a packet
// Our current index into our RAM
// Comprised of which buffer we are doing and
// which byte we're doing within that buffer.
logic [BUFFER_SZ-1:0] ram_pos;
assign ram_pos = {cur_buf, byte_pos};

// Current byte being received (especially if nibble-based receiving)
logic [7:0] cur_byte;
logic nibble; // and current nibble being received (0 = low, 1 = high)
// Any errors during the receive of the current packet?
logic packet_rcv_err;
logic packet_preamble_err;

// If we have to repeat things a few times
logic [3:0] local_count;
localparam TRIES_FIFO_INSERT = 3'd3;

// Our Start of Frame Delimiter - once we see this in the preamble
// we will start receiving actual data packets. The thing is, we may
// ONLY see this and no other preamble bytes. See Tables 22-3 and 22-4
// of 802.3-2022 specification.
localparam SFD = 8'b1101_0101;


// Counters how many times we enter these various RX_CTL states
`ifdef IS_QUARTUS
// QuestaSim does not like these initial conditions with always_ff:
// # ** Error (suppressible): (vlog-7061) Variable '...' driven in an always_ff block, may not be driven by any other process.
initial count_interframe = '0;
initial count_reception = '0;
initial count_receive_err = '0;
initial count_carrier = '0;
initial count_interframe_differ = '0;
`endif // IS_QUARTUS

// The last inter-frame data we got
logic [3:0] last_interframe;
logic ddr_data;

// Were we receiving?
logic in_receive = '0;

always_comb begin
  rx_dv = rx_ctl_h;
  rx_err = rx_ctl_h ^ rx_ctl_l; // Error = different rx_ctl_l and _h

  // Interpret our interframe data stream
  link_up = last_interframe[0];
  full_duplex = last_interframe[3];
  speed_1000 = last_interframe[2:1] == 2'b10;
  speed_100 = last_interframe[2:1] == 2'b01;
  speed_10 = last_interframe[2:1] == 2'b00;
  ddr_data = speed_1000;
end // Decode rx_ctl


always_ff @(posedge clk_rx) begin

  if (reset) begin

    // FIXME: CODE ME: Reset all counters, etc.
    state <= S_IDLE;

    // Should we clear the FIFO? 
    fifo_aclr <= '0;

    ram_wr_ena <= '0;
    fifo_wr_req <= '0;

  end else begin

    case (state)

    S_IDLE: begin: s_idle /////////////////////////////////////////////////////////

      last_rx_dv <= rx_dv;
      last_rx_err <= rx_err;
      byte_pos <= '0; // Prepare for next packet to be received
      in_receive <= '0; // We are not receiving a packet
      fifo_wr_req <= '0; // We just wrote to the FIFO probably
      fifo_aclr <= '0; // In case we cleared it in a reset
      ram_wr_ena <= '0; // Should already be zero, not writing to RAM usually

      // See Table 4 in section 3.4 of RGMII Spec 2.0
      // See Marvell 88E1111 Rev M section 2.2.3.2 which implies support for in-band
      // Do what needs to be done for error and rx_err (TODO: we could just
      // simplify this to rx_ctl_h and rx_ctl_l?).
      // Note that Table 4 shows RX_CTL H,L and not the decoded DV, ER (in other columns)
      case ({rx_dv, rx_err})
      2'b00: begin: normal_interframe
        // Full idle - normal inter-frame situation
        // Bit 0: link status (1 = up)
        // Bit 2-1: speed: 00 = 2.5, 01 = 25, 10 = 125 MHz, 11 = Reserved
        // Bit 3: Duplex: 1 = full
        // Nibbles are the same on high and low edge of rx_clk
        if (last_rx_dv != rx_dv || last_rx_err != rx_err)
          count_interframe <= count_interframe + 1'd1;

        if (rx_data_h != rx_data_l) begin
          in_band_differ <= '1;
          count_interframe_differ <= count_interframe_differ + 1'd1;
          in_band_h <= rx_data_h;
          in_band_l <= rx_data_l;
          // Don't save the data, it may be unreliable
        end else begin
          last_interframe <= rx_data_h;
          in_band_differ <= '0;
        end
      end: normal_interframe // 2'b00

      2'b10: begin: normal_data_start // 10 = DV and !ERR (comes on wire as 11)
        // Normal data receiption: Begin packet receiption
        if (last_rx_dv != rx_dv || last_rx_err != rx_err)
          count_reception <= count_reception + 1'd1;

        in_receive <= '1;
        packet_rcv_err <= '0;
        packet_preamble_err <= '0;
        byte_pos <= '0;
        if (ddr_data) begin
          // DDR, so we get a byte at a time:
          // 3:0 on high, 7:4 on low (RGMII 2.0 Spec, Table 1)

          if ({rx_data_l, rx_data_h} == SFD) begin
            // We got the SFD right off the bat, so go directly to receiving.
            state <= S_RECEIVING;
          end else begin
            state <= S_PREAMBLE;
            byte_pos <= 1'd1; // We have received one preamble byte already
          end

        end else begin
          // We always receive the low nibble first
          cur_byte[3:0] <= rx_data_h;
          // RGMII 2.0 spec 5.0 says data _may_ be duplicated on low edge of clock
          nibble <= '1;
          // We will write when we have a full byte
          state <= S_PREAMBLE;
        end
      end: normal_data_start // 2'b00

      2'b01: begin: carrier_information
        // Carrier information
        // 0E = False carrier indication
        // 0F = Carrier Extend
        // 1F = Carrier Extend Error
        // FF = Carrier Sense
        // (not sure how this works on RGMII at 10/100)
        // But let's just ignore it for now
        if (last_rx_dv != rx_dv || last_rx_err != rx_err)
          count_carrier <= count_carrier + 1'd1;
      end: carrier_information // 2'b00

      2'b11: begin: receive_error_interframe // 11 = DV and ERR (comes on wire as 10)
        // Transmit error propagation, not sure what to do if we get this while idle,
        // maybe just ignore it.
        // Data is ignored.
        if (last_rx_dv != rx_dv || last_rx_err != rx_err)
          count_receive_err <= count_receive_err + 1'd1;
      end: receive_error_interframe // 2'b00
      endcase // rx_dv and rx_err
        
    end: s_idle // S_IDLE


    S_PREAMBLE: begin: s_preamble //////////////////////////////////////////////////////////////////////
      // We count up to 8 preamble bytes, where the 8th must be the SFD.
      // If we don't get the SFD, we should set an error flag.
      // Our byte count is in byte_pos.
      // Before we start receiving data, we should reset byte_pos to 0.

      case ({rx_dv, rx_err})
      2'b10: begin: preamble_normal_receive // Normal receive
          // DDR, so we get a byte at a time:
          // 3:0 on high, 7:4 on low (RGMII 2.0 Spec, Table 1)

        if (ddr_data) begin: preamble_ddr_data

          if ({rx_data_l, rx_data_h} == SFD) begin
            // We got the SFD, so go directly to receiving.
            state <= S_RECEIVING;
            byte_pos <= '0;
          end else if (byte_pos < 7) begin
            // We are still reading preamble bytes
            byte_pos <= byte_pos + 1'd1;
            // TODO: Check if this is 0101_0101?
          end else begin
            // We have not found our preamble byte,
            // set an error and start receiving
            packet_preamble_err <= '1;
            byte_pos <= '0;
            state <= S_RECEIVING;
          end

        end: preamble_ddr_data else begin: preamble_non_ddr_data

          // Non-DDR data, nibble at a time
          nibble <= ~nibble;
          if (nibble == '1) begin

            // Check if we got the SFD or ran out of preamble bytes
            if ({rx_data_h, cur_byte[3:0]} == SFD) begin
              // We got the SFD, so go directly to receiving.
              state <= S_RECEIVING;
              byte_pos <= '0;
              nibble <= '0;
            end else if (byte_pos < 7) begin
              // We are still reading preamble bytes
              byte_pos <= byte_pos + 1'd1;
              // TODO: Check if this is 0101_0101?
            end else begin
              // We have not found our preamble byte,
              // set an error and start receiving
              packet_preamble_err <= '1;
              byte_pos <= '0;
              nibble <= '0;
              state <= S_RECEIVING;
            end

          end else begin
            // First half of the nibble, save it
            cur_byte[3:0] <= rx_data_h;
          end

        end: preamble_non_ddr_data
      end: preamble_normal_receive

      2'b01, // Carrier extend
      2'b00: begin: preamble_interframe // Normal inter-frame
        // We should go back to idle
        // FIXME: Increment a counter with this unexpected situation?
        state <= S_IDLE;
        in_receive <= '0;
      end: preamble_interframe

      2'b11: begin: preamble_receive_error // Receive error
        // I THINK that we ignore this byte/nibble and continue
        // receiving the rest of the packet.
        packet_rcv_err <= '1;
        count_rcv_errors <= count_rcv_errors + 1'd1;
      end: preamble_receive_error
      endcase // preamble {rx_dv, rx_err}

    end: s_preamble

    // FOR NOW, we are receiving the whole packet verbatim, not checking CRC/FCS.
    S_RECEIVING: begin /////////////////////////////////////////////////////////////////////////
      // We already got our first byte/nibble - now get more
      // TODO: Stop receiving after packet length > whatever the max is, 2000?

      case ({rx_dv, rx_err})
      2'b01, // Carrier extend
      2'b00: begin // Normal inter-frame
        // Frame is over (no matter what, DV is low)
        state <= S_FRAME_END;
        ram_wr_ena <= '0;
        // TODO: Check, if !ddr & nibble is 1, then we have half a byte received, unprocessed
        if (!rx_err)
          count_rcv_end_normal <= count_rcv_end_normal + 1'd1;
        else
          count_rcv_end_carrier <= count_rcv_end_carrier + 1'd1;
        local_count <= TRIES_FIFO_INSERT;
      end // 2'b0x

      2'b10: begin // Normal receive

        if (ddr_data) begin
          // Write our next byte to RAM (recived a byte at a time)
          byte_pos <= byte_pos + 1'd1;
          ram_wr_ena <= '1;
          ram_wr_addr <= ram_pos;
          ram_wr_data <= {rx_data_l, rx_data_h};

        end else begin
          // Non-DDR data, nibble at a time
          nibble <= ~nibble;
          if (nibble == '1) begin
            // Getting the 2nd half of a nibble, so write the byte to current position
            // and go to next position
            ram_wr_ena <= '1;
            ram_wr_data <= {rx_data_h, cur_byte[3:0]};
            ram_wr_addr <= ram_pos;
            byte_pos <= byte_pos + 1'd1;
          end else begin
            // First half of the nibble, save it
            ram_wr_ena <= '0;
            cur_byte[3:0] <= rx_data_h;
          end
        end // DDR or not

      end // 2'b10

      2'b11: begin // Receive error
        // I THINK that we ignore this byte/nibble and continue
        // receiving the rest of the packet.
        packet_rcv_err <= '1;
        ram_wr_ena <= '0;
        count_rcv_errors <= count_rcv_errors + 1'd1;
      end // 2'b11

      endcase // S_RECEIVING RX_DV/ERR case

    end // S_RECEIVING

    S_FRAME_END: begin ///////////////////////////////////////////////////////
      // Frame has ended. Finish writing our data and send the signal over
      // FIFO, then return to idle.
      // We have a few inter-packet cycles we can use up: https://en.wikipedia.org/wiki/Interpacket_gap
      // 10: 11 cycles (47 bit times @ 4 bits per cycle)
      // 100: 24 cycles (96 bit times @ 4 bits per cycle)
      // 1000: 8 cycles (64 bit times @ 8 bits per cycle)
      // We used one cycle to get here already, so we have only 7 left.

      // TODO: Finish CRC calculation and confirm it matches expected fixed value
      // Send a FIFO message about having just received something
      // Increment our buffer number before going back to idle
      ram_wr_ena <= '0;

      // We insert into our FIFO if it's not full,
      // or wait another cycle, until we've waited long
      // enough and have to give up.
      if (!fifo_wr_full) begin
        fifo_wr_req <= '1;
        fifo_wr_data <= {
          1'b0, // CRC error
          packet_rcv_err, // Frame error
          cur_buf,
          byte_pos // FIXME: Reduce this by 4 so we don't report the FCS/CRC? Only if CRC checks out?
        };
      end else if (local_count == '0) begin
        // We give up
        count_rcv_dropped_packets <= count_rcv_dropped_packets + 1'd1;
      end else begin
        local_count <= local_count - 1'd1;
      end

      // We're done, let's get IDLEing
      if (!fifo_wr_full || local_count == '0) begin
        state <= S_IDLE;
        in_receive <= '0;
        cur_buf <= cur_buf + 1'd1;
      end
    end // S_FRAME_END

    endcase // current state case

  end // reset

end // main state machine always_ff


`endif // NOT BOGUS

endmodule // rgmii_rx


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa