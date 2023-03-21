// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

// Test module to be an I2C target.
// Implemented with clock oversampling.

// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module test_i2c_target #(
  parameter I2C_ADDRESS = 7'b101_0101 // 0x55 or 0xAA read; 0xAB write
) (
  input logic clk,
  input logic reset,

  input logic scl_i,
  input logic sda_i,

  // We can send data too on a "read" request from controller
  output logic sda_o,
  output logic sda_e,

  // We don't send clock, as we don't do clock stretching

  // Debugging outputs
  output logic start_seen,
  output logic stop_seen,
  output logic in_transaction // Not yet implemented
);

// Oversample method.
// What we should really do is identify inflection points, then
// run the state machine based upon that each time.
// Maybe "clock start" inflection point, and "clock end" inflection point.
// Then have a state machine that does something for each of those
// given the other states.
// The other states are: 
// Idle - Waiting for START
// Address - Got start, waiting for 8 address bits address
//   When got all 8 bits, go to ACK or NAK as appropriate
// ACK - send the ACK, then go to Data
// NAK - if it's not our address, then go back to IDLE (ignore things until START again)
// Data write, read the data to us then continue to send an ACK
// Data read, write the data to the controller then go get an ACK

localparam S_IDLE       = 3'd0,
           S_ADDRESS    = 3'd1,
           S_ACK        = 3'd2,
           S_DATA_READ  = 3'd3,
           S_DATA_WRITE = 3'd4;

// We will need to do CDC for these samplings and
// run them through several flip flops. We will do that later.
// FIXME: Put the two-stage shift register synchronizer in,
// if we're ever going to use this code in a real device.

logic [2:0] state;

logic last_scl;
logic last_sda;
logic sda_pre_fall; // Saved whenever scl is high
logic sda_at_rise;

// Read data a bit at a time and accumulate it
logic [3:0] bit_cnt;
logic [7:0] data_accum;
// When we get a new data bit, what's our next data_accum? (combinational)
logic [7:0] next_data;

// The I2C address and read/not-write bit we've seen
logic [7:0] address;
// Did we read the address yet?
logic address_seen;
// Is the controller addressing us as the target? Is it writing to us?
logic is_us;
// (combinational) What is the next value of is_us (when appropriate)
// In other words, it's when the address is our address.
logic next_is_us; 
logic is_write;

// The situation with the clock transition right now
logic scl_change, scl_rise, scl_fall; // i2c clock changed between the last two (system) clocks
logic scl_high, scl_low; // i2c clock was stable between last system clock and now
// The situation with sda since the clock first went high
logic sda_change, sda_stop, sda_start;

logic [7:0] data_to_send;
logic [7:0] next_data_to_send;

/*
Theory of operation:

1. Always record the state of SDA at the beginning and end
   of an SCL pulse, to look for STOP and START conditions.
   (FIXME: We may need to adjust that for when we are writing
   so check sda_e, but we should never be writing those anyway.)
   
2. Always advance the state machine when the clock drops.
   First always look for START and STOP conditions, and then
   if not, deal with the state machine.

3. START always is followed by the address.
4. STOP always shifts us to IDLE.
5. Any time we would NAK, we can just jump to IDLE, since we
   won't be involved in the transaction anymore anwyway.
*/


// Figure out what we should be doing now
always_comb begin
  scl_change = last_scl != scl_i;
  scl_rise   =  scl_change &&  scl_i;
  scl_fall   =  scl_change && !scl_i;
  scl_high   = !scl_change &&  scl_i;
  scl_low    = !scl_change && !scl_i;

  // Start is HIGH to LOG; Stop is LOW to HIGH
  sda_change =  sda_at_rise !=  sda_pre_fall;
  sda_stop   = !sda_at_rise &&  sda_pre_fall;  // L -> H
  sda_start  =  sda_at_rise && !sda_pre_fall;  // H -> L

  // If we have a new bit, what is it?
  next_data = { data_accum[6:0], sda_pre_fall };
  next_is_us = data_accum[6:0] == I2C_ADDRESS;

  // Rotate data to send
  next_data_to_send = { data_to_send[6:0], data_to_send[7] };

  // Send debug outputs
  in_transaction = state != S_IDLE;
  start_seen = sda_start;
  stop_seen = sda_stop; 
end


// Save our signals from one clock to the next
always_ff @(posedge clk) begin
  // Do we care about a reset for these? I don't think so, no.

  last_scl <= scl_i;
  last_sda <= sda_i;

  if (scl_rise)
    // Note, if sda_e then this may be meaningless
    sda_at_rise <= sda_e ? sda_o : sda_i;

  if (scl_i)
    // Note, if sda_e then this may be meaningless
    sda_pre_fall <= sda_e ? sda_o : sda_i;
end // Signal saver


// Handle our resets and the new state machine.
// We always switch to a new state when scl_fall.
always_ff @(posedge clk) begin

  if (reset) begin
    state <= S_IDLE;
    sda_e <= 1'b0;
    data_to_send <= 8'b0000_0011;

    // Reset all the other things (these below shouldn't be strictly necessary)
    is_write <= 1'b0;
    is_us <= 1'b0;
    address_seen <= 1'b0;
    bit_cnt <= 4'b0;

  end else if (scl_fall) begin
    
    if (sda_start) begin
      // After a start bit we always go to address state, but the
      // only usual thing is from IDLE or after an ACK.
      // See I2C UM10204 (Rev 7.0) Section 3.1.10 Note #4
      $display("----------------------------------------");
      $display("START, from state %d @ %d", state, $time);
      state <= S_ADDRESS;
      sda_e <= 0;
      address_seen <= 1'b0;
      is_us <= 1'b0;
      bit_cnt <= 4'd0;

    end else if (sda_stop) begin
      // We should only see a STOP after an ACK/NAK, but
      // regarldess of whenever we see it, we go to IDLE
      $display("STOP, from state %d @ %d", state, $time);
      $display("=========================================");
      state <= S_IDLE;
      sda_e <= 0;
    
    end else case (state)

      S_IDLE: begin //////////////////////////////////////////////////

        // We only leave IDLE when we get a START signal, then we
        // begin to listen for our address. But that will have been
        // handled above already, so we need do nothing here.

        /*
        if (sda_start) begin
          state <= S_ADDRESS;
          bit_cnt <= 4'd0;
        end
        */
        // This shouldn't be necessary, but just in case...
        sda_e <= 1'b0;

      end // case S_IDLE

      S_ADDRESS: begin ///////////////////////////////////////////////
        // Handle the 8 bits of the address, then beginning the ACK/NAK.
        // This is always receiving data (a "write") from the controller.
        bit_cnt <= bit_cnt + 4'b1;

        if (bit_cnt <= 4'd6) begin
          // Got one of the first 7 bits.
          // $display("ADDRESS BIT: %d @ %d", next_data[0], $time);

          // Add it to our accumulator
          data_accum <= next_data;

        end else if (bit_cnt == 4'd7) begin
          // Got the 8th bit
          data_accum <= next_data;
          is_write <= ~sda_pre_fall; // 8th bit HIGH = read

          if (data_accum[6:0] == I2C_ADDRESS) begin
            $display("ADDRESS BYTE: %02h **US** %s @ %d", 
                     next_data, next_data[0] ? "read" : "write", $time);
            // We are being addressed
            is_us <= 1'b1;
            // Start our ACK
            state <= S_ACK;
            sda_o <= 1'b0;
            sda_e <= 1'b1;
          end else begin
            $display("ADDRESS BYTE: %02h (not us) %s @ %d", 
                     next_data, next_data[0] ? "read" : "write", $time);
            is_us <= 1'b0;
            // We don't have to ack, we can just go back to idle
            state <= S_IDLE;
          end
        end

      end // case S_ADDRESS

      S_ACK: begin /////////////////////////////////////////////////////
        // We just finished sending an ACK (or not)

        if (sda_e || !sda_pre_fall) begin
          // IF sda_e:
          // We just sent an ACK (from receiving data).
          // (We never send a NAK, we can just quit and go back to idle.)
          // So continue to receive more data (shut off SDA output).
          // --------------
          // IF !sda_pre_fall:
          // We saw an ACK (sda low during 9th bit).
          // This would only happen if we were writing data.
          // So prepare to write another data to the controller.
          if (sda_e)
            $display("SENT ACK (is_write: %d) @ %d", is_write, $time);
          else
            $display("GOT ACK (is_write: %d) @ %d", is_write, $time);
          bit_cnt <= 4'b0;

          if (is_write) begin
            // IS WRITE: We read data FROM the controller.
            state <= S_DATA_WRITE;
            // We don't really have to do anything special here,
            // just prepare to see the data from the controller.
            sda_e <= 1'b0;

          end else begin
            // IS READ: We write data TO the controller.
            state <= S_DATA_READ;
            // We need to start sending the first bit of our
            // data byte, MSB first (bit 7), until the next clock pulse ends.
            sda_e <= 1'b1;
            sda_o <= data_to_send[7];

          end

        end else begin
          // We did NOT see an ACK, which should only happen
          // if we are sending data to the controller (it's a read)
          // and controller is done receiving data.
          // We should get a STOP soon, but no matter what, we're done
          // with this transaction.
          $display("NO ACK *** @ %d", $time);
          state <= S_IDLE;
        end

      end // case S_ACK

      S_DATA_WRITE: begin ////////////////////////////////////////////////////////////
        // Data WRITE is being WRITTEN from Controller, and being READ by us.
        // This is basically identical to S_ADDRESS except we don't do
        // anything special with the data for now.

        // Handle the 8 bits of the address, then beginning the ACK/NAK.
        // This is always receiving data (a "write") from the controller.
        bit_cnt <= bit_cnt + 4'b1;

        if (bit_cnt <= 4'd6) begin
          // Got one of the first 7 bits.
          // $display("DATA BIT RECEIVED: %d @ %d", next_data[0], $time);

          // Add it to our accumulator
          data_accum <= next_data;

        end else if (bit_cnt == 4'd7) begin
          // Got the 8th & final bit, now send the ACK
          $display("DATA BYTE RECEIVED: %02h @ %d", next_data, $time);
          data_accum <= next_data;
          // Start our ACK
          state <= S_ACK;
          sda_o <= 1'b0;
          sda_e <= 1'b1;

          // FOR TESTING: Send a different byte the next time
          data_to_send <= next_data_to_send;
        end

      end // case S_DATA

      S_DATA_READ: begin ////////////////////////////////////////////////////////////
        // Data READ is being READ ("red") from Controller, and being WRITTEN by us.
        // We just finished writing the bit_cnt'th bit.
        /*
        $display("DATA BIT WRITTEN - just sent %d (bit %d) @ %d", 
                 data_to_send[3'd7 - bit_cnt], 3'd7 - bit_cnt, $time);
        */
        bit_cnt <= bit_cnt + 4'b1;

        if (bit_cnt <= 4'd6) begin
          // Write the next bit
          sda_e <= 1'b1;
          sda_o <= data_to_send[3'd7 - (bit_cnt + 1)];
        end else begin
          $display("DATA BYTE WRITTEN - %02h @ %d", data_to_send, $time);
          // We have written all, now get our ack
          sda_e <= 1'b0;
          state <= S_ACK;

          // After we send each byte, since we're a test harness,
          // send a different byte (via rotation of the data_to_send).
          data_to_send <= next_data_to_send;
        end

      end // case S_DATA

      default: begin ///////////////////////////////////////////////////////////
        $display("***ERROR*** got default state: %d @ %d", state, $time);
        state <= S_IDLE;
        sda_e <= 1'b0;
      end

    endcase // state case

  end // reset or scl_fall

end // new state machine

endmodule
