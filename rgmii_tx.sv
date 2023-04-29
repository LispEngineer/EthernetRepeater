// Ethernet Repeater - RGMII Transmit
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

// This module is usually in its own clock domain (clk_tx).
// This module outputs data and clock completely aligned.
// If the `gclk_tx` needs to be skewed, it has to happen outside of here.

module rgmii_tx #(
  parameter BUFFER_NUM_ENTRY_BITS = 3, // 8 entries, i.e. 16kB RAM
  parameter BUFFER_ENTRY_SZ = 11, // 2kB = 11 bits per buffer entry
  // Total RAM size
  parameter BUFFER_SZ = BUFFER_NUM_ENTRY_BITS + BUFFER_ENTRY_SZ,
  // FIFO depth is 2 ^ BUFFER_SIZE_BITS long too
  // FIFO entries are {buffer, length}
  parameter FIFO_WIDTH = BUFFER_SZ,
  parameter FIFO_RD_LATENCY = 2, // This may actually be 1
  parameter RAM_RD_LATENCY = 2
) (
  // Our appropriate speed clock input (copied to output)
  input  logic clk_tx,
  input  logic reset,

  // Should we transmit data in DDR?
  // This is only used for 1000
  input  logic ddr_tx, // SYNCHRONIZED (but should be very slow changing)

  // Are we currently sending something?
  output logic busy,

  // RGMII OUTPUTS ///////////////////////
  // Our generated appropriate speed clock output
  output logic gclk_tx,
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

  // FIFO & RAM Read Ports ////////////////
  // RAM reader - synchronous to clk_tx
  output logic                 ram_rd_ena,
  output logic [BUFFER_SZ-1:0] ram_rd_addr, // Read address
  input  logic           [7:0] ram_rd_data, // Read data output

  // FIFO reader - synchronous to clk_tx
  input  logic                  fifo_rd_empty,
  output logic                  fifo_rd_req,
  input  logic [FIFO_WIDTH-1:0] fifo_rd_data,

  ////////////////////////////////////////////////////
  // Debugging outputs
  output logic [31:0] crc_out
);

// Our sending state machine
localparam S_IDLE = 3'd0,
           S_PREAMBLE = 3'd1, // 7 bytes (Preamble)
           S_SFD = 3'd2,      // 1 byte, (Start Frame Delimiter)
           S_DATA = 3'd3,     // 14 bytes Ethernet Header header, 46+ bytes data
           S_FCS = 3'd4;      // 4 byte CRC (Frame Check Sequence)           
logic [2:0] state = S_IDLE;

localparam NIBBLE_LOW = 1'b0,
           NIBBLE_HIGH = 1'b1;
logic nibble; // 0 = low nibble, 1 = high nibble

// Which byte we are sending - max packet is about 2000 so use 11 bits
logic [10:0] count;

// Bytes sent for the Preamble and the SFD in the Ethernet frame.
// Note that we don't use these; we send the nibbles directly.
localparam BYTES_PREAMBLE = 8'b1010_1010;
localparam BYTES_SFD      = 8'b1010_1011;

logic syncd_ddr_tx;
// Registered syncd_ddr_tx when we become activated by an un-empty FIFO
logic txn_ddr;

synchronizer ddr_sync (
  .clk(clk_tx),
  .incoming(ddr_tx),
  .syncd(syncd_ddr_tx)
);


// Our actual low-level logic registered signals for transmit enable & error
logic tx_en;
logic tx_err;

logic [7:0] current_data;

// The data outputs in the internal path we're using in our state machine
logic [3:0] d_h;
logic [3:0] d_l;

// The ongoing calcuation of CRC32.
// We send this least significant byte first
logic [31:0] crc;
localparam CRC_INIT = 32'hFFFF_FFFF;
localparam CRC_XOR_OUT = 32'hFFFF_FFFF;
// If we include the CRC at the end with our CRC calculation we should get this
// fixed number
localparam CRC_CHECK = 32'hCBF4_3926;

// Combinational calculation of the next CRC given current one.
logic [31:0] next_crc;
crc32_8bit crc_byte_calc(
  .crc_in(crc),
  .crc_out(next_crc),
  .data_byte(current_data)
);

always_comb begin
  gclk_tx = clk_tx;
  tx_ctl_h = tx_en;
  tx_ctl_l = tx_en ^ tx_err;

  tx_data_h = d_h;
  tx_data_l = d_l;

  // Debugging outputs
  crc_out = crc;
end

// Data saved from the most recent FIFO read
logic [FIFO_WIDTH-1:0] saved_fifo;
// Broken out data from the above (read only)
logic [BUFFER_NUM_ENTRY_BITS-1:0] cur_buf_num;
logic [BUFFER_ENTRY_SZ-1:0] cur_buf_len;

assign {cur_buf_num, cur_buf_len} = saved_fifo;

// The last byte index we will be on when we stop sending data
// (which will be cur_buf_len - 1).
logic [BUFFER_ENTRY_SZ-1:0] last_data_byte;

// Current byte position in the RAM read for current buffer
logic [BUFFER_ENTRY_SZ-1:0] rd_pos;

assign ram_rd_addr = {cur_buf_num, rd_pos};

// We don't increment our counter on our very first read in DDR
logic first_read;

// Are we reading from the RAM for SDR sending right now or not?
// If so, we read another byte every other cycle.
logic ram_read_sdr_sending = '0;

////////////////////////////////////////////////////////////////////////////////////////////

// RAM Reader
// The puropse of this little state machine is to have the bytes ready
// to send in current_data when it needs to be read by the main
// state machine, specifically S_DATA.
// This means we need to start reading during S_PREAMBLE or
// possibly S_SFD, and read every other cycle if we're not doing
// DDR sends since we send one nibble each time.
// Use: txn_ddr, state, count, nibble
// NOTE: fifo_rd_req is handled by the main state machine;
// it's set when it leaves S_IDLE and immediately reset in the next state
// (S_PREAMBLE). We need to read the FIFO after the proper amount of latency
// and save it for later.
always_ff @(posedge clk_tx) begin: ram_reader
  if (!reset) begin: ram_reader_not_reset

    // Save our fifo data so we can start reading from RAM -
    // the FIFO read request signal is set/reset at the main state machine
    if (state == S_PREAMBLE && count == FIFO_RD_LATENCY) begin: read_fifo
      saved_fifo <= fifo_rd_data;
      rd_pos <= 0;
      first_read <= '1; // Will become 0 after we do our first RAM read, to allow pos 0 to be read
    end: read_fifo

    // First do this for non-DDR (1000)
    if (txn_ddr) begin: ddr_ram_reader

      if (state == S_PREAMBLE || state == S_SFD) begin: read_first_bytes
        // Count goes from 0 to 7. 8 would be the first byte of data.
        // If the latency was 1, we'd read on 7, if it were 2, we'd read on 6,
        // but also on 7. We have to read each cycle.
        // Add 1 to the RAM READ LATENCY because we then save it into "current data"
         if (count >= 7 - (RAM_RD_LATENCY + 1)) begin
          ram_rd_ena <= '1;
          if (first_read)
            first_read <= '0;
          else
            rd_pos <= rd_pos + 1'd1;
          current_data <= ram_rd_data;
          // Save where we will stop reading from RAM
          last_data_byte <= cur_buf_len - 1'd1;
        end

      end: read_first_bytes else if (state == S_DATA) begin: read_remaining_bytes
        // Continue reading bytes, we're now fully pipelined,
        // from the RAM. When we read too far, that's fine, we can ignore it.
        // once we're out of S_DATA, it will stop.
        ram_rd_ena <= '1;
        rd_pos <= rd_pos + 1'd1;
        // RAM read enable is always enabled
        current_data <= ram_rd_data;

      end: read_remaining_bytes else begin: done_ram_reading
        ram_rd_ena <= '0;
      end: done_ram_reading

    end: ddr_ram_reader else begin: sdr_ram_reader
      // Handle 10/100 speed, where we send one nibble every cycle,
      // so we need to change what we're reading only every other
      // cycle.
      // During Preamble/SFD, it starts at count == 0.
      // Start reading at the exact right time, then read a byte every
      // OTHER cycle, and stop reading around the right time, and all will
      // be well.

      if (ram_read_sdr_sending) begin: continue_sdr_ram_reading

        // Always save the RAM output (or do we need to do it only when we expect output?)
        current_data <= ram_rd_data;

        // Toggle our read every other cycle (and advance the read location)
        if (ram_rd_ena) begin
          // Do nothing this cycle
          ram_rd_ena <= '0;
        end else begin
          // Read the next byte
          ram_rd_ena <= '1;
          rd_pos <= rd_pos + 1'd1;
        end

        // Should we stop our SDR RAM reading efforts?
        if ((state != S_PREAMBLE && state != S_SFD && state != S_DATA) ||
            (state == S_DATA && count == last_data_byte)) begin
          // We shouldn't be reading in these other states
          // and we should stop reading by the end of sending data
          ram_rd_ena <= '0;
          ram_read_sdr_sending <= '0;
        end

      end: continue_sdr_ram_reading else begin: possibly_begin_sdr_ram_reading

        // We need to start reading from RAM, doing it every other cycle,
        // until we're done sending the packet.
        // Start at the exact time for the first byte to be in current_data
        // when it needs to be sent.
        // Add 1 to the RAM READ LATENCY because we then save it into "current data"

        // $display("In possibly_begin_sdr_ram_reading, state: ", state, " count: ", count, " time: ", $time);

        if ((state == S_PREAMBLE || state == S_SFD) &&
            (count == (15 - (RAM_RD_LATENCY + 1)))) begin
          // $display("***** VERY FIRST READ *******, time: ", $time);
          // Our very first read
          rd_pos <= '0;
          ram_rd_ena <= '1;
          ram_read_sdr_sending <= '1;
          // Save where we will stop reading from RAM
          last_data_byte <= cur_buf_len - 1'd1;
        end

      end: possibly_begin_sdr_ram_reading

    end: sdr_ram_reader
  
  end: ram_reader_not_reset else begin: ram_reader_reset

    ram_rd_ena <= '0;
    ram_read_sdr_sending <= '0;
    first_read <= '0; // Probably unnecessary

  end: ram_reader_reset
end: ram_reader

////////////////////////////////////////////////////////////////////////////////////////////

// State machine
always_ff @(posedge clk_tx) begin

  if (reset) begin /////////////////////////////////////////////////////

    tx_en <= '0;
    tx_err <= '0;
    state <= S_IDLE;
    busy <= '1; // Should we be "busy" during reset? Sure, why not. Confirm!
    fifo_rd_req <= '0;
  
  end else begin ///////////////////////////////////////////////////////

    // Remember: In the timing diagram, the transmissions will be one clock
    // cycle behind the state, because it's all registered for the next cycle.

    case (state)

      S_IDLE: begin ////////////////////////////////////////////////////
        tx_en <= '0;
        tx_err <= '0;
        busy <= '0;
        fifo_rd_req <= '0;

        // FIXME: Add an interframe delay per spec, before activation.
        // So, let's do this right when we become idle.
        if (!fifo_rd_empty) begin
          // We need to send a packet
          txn_ddr <= syncd_ddr_tx;
          busy <= '1;
          state <= S_PREAMBLE;
          nibble <= NIBBLE_LOW;
          count <= '0;
          fifo_rd_req <= '1;
        end

      end

      S_PREAMBLE: begin ////////////////////////////////////////////////////
        // Preamble is 7 bytes of 1010_1010

        tx_en <= '1;
        tx_err <= '0; // Not sure when we would ever set this
        fifo_rd_req <= '0; // Read only exactly one entry
        count <= count + 1'd1; // We will carry the count into S_SFD

        if (!txn_ddr) begin
          // Review Table 22-3 in 802.3-2022 for MII (same as RGMII with 4 tx pins)
          // Preamble is txd[0] = 1, txd[1] = 0, txd[2] = 1, txd[3] = 0
          // for 14 nibbles
          d_h <= 4'b0101;
          d_l <= 4'b0101;
          nibble <= ~nibble; // We do this for the benefit of the RAM Reader as it is not used locally
          // No matter what I use for this count (12, 13, 14, 18, 123)
          // it seems to accept the packet on the other end correctly.
          if (count == 13) begin
            // We are sending our 7th byte, second nibble, move on to SFP
            state <= S_SFD;
            nibble <= NIBBLE_LOW;
          end

        end else begin // txn_ddr
          // Send 7x 0x55

          d_h <= 4'b0101;
          d_l <= 4'b0101;
          if (count == 6) begin
            // We are sending our 7th byte, second nibble, move on to SFP
            state <= S_SFD;
          end

        end // txn_ddr or not

      end

      S_SFD: begin ////////////////////////////////////////////////////
 
        if (!txn_ddr) begin
          // Review Table 22-3 in 802.3-2022
          // SFD is txd[0] = 1, txd[1] = 0, txd[2] = 1, txd[3] = 0
          // then   txd[0] = 1, txd[1] = 0, txd[2] = 1, txd[3] = 1
          nibble <= ~nibble;
          count <= count + 1'd1; // Do this for the benefit of the RAM Reader above
          if (!nibble) begin
            // First nibble is same as preamble
            d_h <= 4'b0101;
            d_l <= 4'b0101;
          end else begin
            // Second nibble has an extra bit
            d_h <= 4'b1101;
            d_l <= 4'b1101;
            state <= S_DATA;
            count <= '0;
            crc <= CRC_INIT;
          end

        end else begin // switch to ddr
          // Send 0xD5, low nibble first
          d_h <= 4'b0101;
          d_l <= 4'b1101;
          state <= S_DATA;
          count <= '0;
          crc <= CRC_INIT;
        end

      end

      S_DATA: begin ////////////////////////////////////////////////////
        // We are going to send the data of an ARP request, "current_data"

        if (!txn_ddr) begin

          // Send our data
          if (nibble) begin
            d_h <= current_data[7:4];
            d_l <= current_data[7:4];
            crc <= next_crc; // Get the next CRC value for the full data byte
          end else begin
            d_h <= current_data[3:0];
            d_l <= current_data[3:0];
          end

          // Handle advancing state
          nibble <= ~nibble;
          if (nibble) begin
            // Second half of our byte
            count <= count + 1'd1;
            // Are we done with data?
            if (count == last_data_byte) begin
              state <= S_FCS;
              count <= 0;
            end
          end

        end else begin // txn_ddr

          // Send our data, low nibble first (high)
          d_h <= current_data[3:0];
          d_l <= current_data[7:4];
          crc <= next_crc; // Get the next CRC value for the full data byte

          // Handle advancing state
          nibble <= ~nibble;
          count <= count + 1'd1;
          // Are we done sending?
          if (count == last_data_byte) begin
            state <= S_FCS;
            count <= 0;
          end

        end

      end

      S_FCS: begin ////////////////////////////////////////////////////
        // We are going to send the calculated CRC, least significant byte
        // first, and least significant nibble of each byte first.
        // So we will send 8 nibbles from the bottom to the top in non-DDR
        // or 4 bytes with LSB in the High of the transmit clock.

        if (!txn_ddr) begin

          // Select 4 bits starting at (count + 1) * 4 - 1
          // https://stackoverflow.com/questions/18067571/indexing-vectors-and-arrays-with
          d_h <= crc[(count << 2) +:4] ^ 4'b1111; // Add final XOR
          d_l <= crc[(count << 2) +:4] ^ 4'b1111;

          count <= count + 1'd1;
          if (count == 7) begin
            // We are sending our final nibble, so we're done
            state <= S_IDLE;
          end

        end else begin // txn_ddr

          {d_l, d_h} <= crc[(count << 3) +:8] ^ 8'hFF; // Add final XOR

          count <= count + 1'd1;
          if (count == 3) begin
            // We are sending our final CRC byte, so we're done
            state <= S_IDLE;
          end

        end

        // Let's stay busy until we're IN the idle state
        // Let's keep tx_en until we're IN the idle state
      end

      default: begin
        tx_en <= '0;
        tx_err <= '1;
        state <= S_IDLE;
        busy <= '0;
      end
    endcase

  end // reset or state machine

end // Main state machine


endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa