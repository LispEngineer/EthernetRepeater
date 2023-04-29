// Memory Copier
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

/*
TODO: Future enhancement possibilities:
1. Copy different widths for source and destination
2. Copy from the beginning or the end, in case we want to use this
   for copying from/to the same memory.
3. Don't read beyond where we strictly need to read.

FIXME: Figure out how to use src_addr_t, dst_addr_t and data_t in the
module's parameter list.
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

// FIXME: Should we synchronize the "activate" signal?

typedef logic [SRC_ADDR_SZ-1:0] src_addr_t;
typedef logic [DST_ADDR_SZ-1:0] dst_addr_t;
typedef logic   [MEM_WIDTH-1:0] data_t;

assign clk_ram_wr = clk;
assign clk_ram_rd = clk;
assign ram_wr_data = ram_rd_data;

`ifdef IS_QUARTUS
// QuestaSim complaints about these:
// ** Error (suppressible): memcopy.sv: (vlog-7061) Variable 'busy' driven in an always_ff block, may not be driven by any other process.
initial ram_wr_ena = '0;
initial ram_rd_ena = '0;
initial busy = '0;
`endif // IS_QUARTUS

// Algorithm:
// Three blocks, a reader, a writer and a main state machine.
//
// Reader:
// 1. Starts reading into ram_rd_data once main state machine leaves idle
// 2. Has a read latency countdown so the writer can start using
//    the read data once it hits zero
// 3. Keeps reading sequentially until main state machine goes idle
//    (it's mostly harmless to read past the end and not use it)
//
// Writer:
// 1. Waits for read data to be ready
// 2. Writes each byte into the proper destination address
//    (the destination write data is permanently set to the ram_rd_data)
// 3. Stops when we have written the requested number of words
// 4. Sets a signal when we're done writing
//
// State machine:
// 1. Waits until activate asserted, then asserts busy
// 2. If the length is degenerate, does nothing but a single-cycle busy assertion
// 3. Waits until the writer is done writing
// 4. Then returns to wait/idle state (which deasserts busy)


// Quartus Prime Design Recommendations for SystemVerilog State Machines
// Section 1.6.4.2.2
typedef enum int unsigned { S_IDLE = 0, S_COPYING = 1 } state_t;
state_t state = S_IDLE;

// Saved source/destination addresses
src_addr_t s_src_addr; // Starting address of copy
dst_addr_t s_dst_addr; // Destination address of copy
src_addr_t s_src_len;  // Length of copy

// We wait a few cycles for copying to begin before we start checking if copying is over.
// It takes three cycles from when we activate to we start writing, when SRC_LATENCY is 2.
// So add an extra cycle just for good measure.
localparam COPYING_DELAY_START = 3'd2 + 3'(SRC_LATENCY);
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
        if (src_len == 0) begin: degenerate_length
          // We should flash the busy but actually do nothing, as a zero length
          // will break the rest of our code.
          busy <= '1;

        end: degenerate_length else begin: reasonable_length
          busy <= '1;
          s_src_addr <= src_addr;
          s_dst_addr <= dst_addr;
          s_src_len <= src_len;
          state <= S_COPYING;
          copying_delay <= COPYING_DELAY_START;
        end: reasonable_length
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

// Track when we first go non-idle
logic reader_was_idle = '1;

src_addr_t cur_src_addr;  // Current source address of copy
localparam READ_DELAY_SZ = $clog2(SRC_LATENCY + 1);
logic [READ_DELAY_SZ-1:0] read_delay;

always_ff @(posedge clk) begin: reader_state_machine

  if (reset) begin: reader_reset
    ram_rd_ena <= '0;
    reader_was_idle <= '1;
    read_delay <= (READ_DELAY_SZ)'(SRC_LATENCY);

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

      if (read_delay != 0) begin: write_not_yet_ready
        read_delay <= read_delay - 1'd1;
      end: write_not_yet_ready

    end: reader_active

  end: reader_state

end: reader_state_machine

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Writer State Machine

logic writer_was_idle = '1;

dst_addr_t cur_dst_addr;  // Current destination address of copy
dst_addr_t last_dst_addr; // Last destination address we will write

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
        last_dst_addr <= s_dst_addr + (DST_ADDR_SZ)'(s_src_len) - 1'd1;
        // Figure out our write start and end addresses
      end: prepare_writing

      // TODO: Should there be an "else" here?

      if (copying_done) begin: stop_writing
        // In case the main state machine doesn't get us back to S_IDLE fast enough
        ram_wr_ena <= '0;
      end: stop_writing else if (read_delay == 0) begin: do_write
        // We got the signal from reader that we can write the data
        ram_wr_ena <= '1;
        // remember, ram_wr_data is assigned to ram_rd_data above
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