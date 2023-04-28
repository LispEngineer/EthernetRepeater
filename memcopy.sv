// Memory Copier
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

/*
TODO: Future enhancement possibilities:
1. Copy different widths for source and destination
2. Copy from the beginning or the end, in case we want to use this
   for copying from/to the same memory.
*/

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// Simulation: Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module memcopy #(
  parameter MEM_WIDTH = 8,
  parameter SRC_ADDR_SZ = 14,
  parameter DST_ADDR_SZ = 14,
  parameter SRC_LATENCY = 2
) (
  // Our appropriate speed clock input (copied to output)
  input  logic clk,
  input  logic reset,

  // Are we currently copying something?
  output logic busy,

  // Activation
  input  logic activate, // Assert until busy
  input  logic [SRC_ADDR_SZ-1:0] src_addr, // Starting address of copy
  input  logic [DST_ADDR_SZ-1:0] dst_addr, // Destination address of copy
  input  logic [SRC_ADDR_SZ-1:0] src_len,  // Length of copy

  // Source RAM reader interface
  output logic                   clk_ram_rd,
  output logic                   ram_rd_ena,
  output logic [SRC_ADDR_SZ-1:0] ram_rd_addr,
  input  logic   [MEM_WIDTH-1:0] ram_rd_data,

  // Destination RAM writer interface
  output logic                   clk_ram_wr,
  output logic                   ram_wr_ena,
  output logic [DST_ADDR_SZ-1:0] ram_wr_addr,
  output logic   [MEM_WIDTH-1:0] ram_wr_data
);

assign clk_ram_wr = clk;
assign clk_ram_rd = clk;
initial ram_wr_ena = '0;
initial ram_rd_ena = '0;
initial busy = '0;

// Algorithm:
// Three blocks, a reader, a writer and a main state machine.
//
// Reader:
// 1. Starts reading into ram_rd_data
// 2. At the appropriate latency asserts a "write ready" flag
// 3. Keeps reading sequentially until all read
// 4. Deasserts write ready flag once all done
//
// Writer:
// 1. Waits for write ready
// 2. Writes each byte into the destination when write ready
// 3. Stops when write not ready
//
// State machine:
// 1. Waits until activate asserted, then asserts busy
// 2. Sets a signal to tell reader/writer to initialize themselves?
//    Or should it set them itself? That would need to have two drivers
//    of a single net in different always_ff blocks, so... Will have to think
//    about that.
// 3. Waits until the writer is done writing.
// 4. Clears busy and returns to wait/idle state.


localparam S_IDLE = 0,
           S_COPYING = 1;

logic [2:0] state = S_IDLE;

// Saved source/destination addresses
logic [SRC_ADDR_SZ-1:0] s_src_addr; // Starting address of copy
logic [DST_ADDR_SZ-1:0] s_dst_addr; // Destination address of copy
logic [SRC_ADDR_SZ-1:0] s_src_len;  // Length of copy

// We wait a few cycles for copying to begin before we start checking if copying is over
logic [2:0] copying_delay;

// Has copying completed?
logic copying_done; // Written only in the writer block

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Main State Machine

always_ff @(posedge clk) begin: main_state_machine

  if (reset) begin: main_reset

    state <= S_IDLE;
    busy <= '1; // We are busy when we're being reset

  end: main_reset else begin: state_machine_case

    case (state)
    S_IDLE: begin: s_idle
      busy <= '0;
      if (activate) begin: activation
        busy <= '1;
        s_src_addr <= src_addr;
        s_dst_addr <= dst_addr;
        s_src_len <= src_len;
        state <= S_COPYING;
        copying_delay <= '1;
      end: activation
    end: s_idle

    S_COPYING: begin: s_copying


      if (copying_delay == 0) begin: check_done
        if (copying_done) begin: am_done
          busy <= '0;
          state <= S_IDLE;
        end: am_done
      end: check_done else begin: continue_waiting
        copying_delay <= copying_delay - 1'd1;
      end: continue_waiting


    end: s_copying
    endcase // state

  end: state_machine_case

end: main_state_machine


/////////////////////////////////////////////////////////////////////////////////////////////////////
// Reader State Machine

// This becomes true once our reading pipeline has data to write
logic write_ready = '0;
logic reader_was_idle = '1;

logic [DST_ADDR_SZ-1:0] cur_src_addr;  // Current source address of copy
localparam READ_DELAY_SZ = $clog2(SRC_LATENCY);
logic [READ_DELAY_SZ:0] read_delay;

always_ff @(posedge clk) begin: reader_state_machine

  if (reset) begin: reader_reset
    ram_rd_ena <= '0;
    reader_was_idle <= '1;

  end: reader_reset else begin: reader_state

    if (state == S_IDLE) begin: reader_idle
      ram_rd_ena <= '0;
      reader_was_idle <= '1;
      read_delay <= (READ_DELAY_SZ)'(SRC_LATENCY);

    end: reader_idle else begin: reader_active

      if (reader_was_idle) begin: begin_reading
        reader_was_idle <= '0;
        ram_rd_ena <= '1;
        ram_rd_addr <= s_src_addr;
        cur_src_addr <= s_src_addr + 1'd1;
      end: begin_reading else begin: continue_reading
        // We will read past the end, but that shouldn't hurt anything (I hope)
        // ram_rd_ena <= '1; // Already true
        ram_rd_addr <= cur_src_addr;
        cur_src_addr <= cur_src_addr + 1'd1;
      end: continue_reading

      if (read_delay == 0) begin: write_is_ready
        write_ready <= '1;
      end: write_is_ready else begin: write_not_yet_ready
        read_delay <= read_delay - 1'd1;
      end: write_not_yet_ready

    end: reader_active

  end: reader_state

end: reader_state_machine

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Writer State Machine

logic writer_was_idle = '1;

logic [DST_ADDR_SZ-1:0] cur_dst_addr;  // Current destination address of copy
logic [DST_ADDR_SZ-1:0] last_dst_addr; // Last destination address we will write

always_ff @(posedge clk) begin: writer_state_machine

  if (reset) begin: writer_reset
    copying_done <= '0;
    ram_wr_ena <= '0;
    writer_was_idle <= '1;

  end: writer_reset else begin: writer_state_case

    if (state == S_IDLE) begin: writer_idle
      writer_was_idle <= '1;
      ram_wr_ena <= '0;
      copying_done <= '0;

    end: writer_idle else begin: writer_active

      if (writer_was_idle) begin: prepare_writing
        writer_was_idle <= '0;
        cur_dst_addr <= s_dst_addr;
        last_dst_addr <= s_dst_addr + (DST_ADDR_SZ)'(s_src_len);
        // Figure out our write start and end addresses
      end: prepare_writing

      // TODO: Should there be an "else" here?

      if (copying_done) begin: stop_writing
        // In case the main state machine doesn't get us back to S_IDLE fast enough
        ram_wr_ena <= '0;
      end: stop_writing else if (write_ready) begin: do_write
        // We got the signal from reader that we can write the data
        ram_wr_ena <= '1;
        ram_wr_data <= ram_rd_data;
        ram_wr_addr <= cur_dst_addr;
        cur_dst_addr <= cur_dst_addr + 1'd1;

        // Are we done?
        if (cur_dst_addr == last_dst_addr) begin: copying_last
          copying_done <= '1;
          // Will eventually transition to S_IDLE - we are writing our
          // last byte right now
        end: copying_last

      end: do_write

    end: writer_active

  end: writer_state_case

end: writer_state_machine


endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif