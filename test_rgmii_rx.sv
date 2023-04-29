// Copyright 2023 ⓒ Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps


module test_rgmii_rx();

// Simulator generated clock & reset
logic  clk;
logic  reset;


////////////////////////////////////////////////////////////////////////////////////

// generate clock to sequence tests
localparam period = 20;
localparam reset_period = period * 4.2;
always begin
  // 2.5 MHz = 200 (one full cycle every 400 ticks at 1ns per tick per above)
  // 25 MHz = 20
  // 125 MHz = 4
  #(period) clk <= ~clk;
end

logic fifo_rd_empty;
logic fifo_rd_req = '0;
logic [15:0] fifo_rd_data;
logic [15:0] stored_fifo_data;
logic crc_error, frame_error;
logic [2:0] buf_num;
logic [10:0] pkt_len;

logic ram_rd_ena;
logic [13:0] ram_rd_addr;
logic [7:0] ram_rd_data;
logic [2:0] read_buf;
logic [10:0] read_pos; // We're requesting the byte at this address this cycle
logic [10:0] read_end; // Last pos we want to see/process before quitting

// Use '1 as a sentinel saying "invalid seeing"
logic [10:0] read_see; // We're seeing this byte this time - the req from last cycle

// Handle RAM with two cycle read latency
`define TWO_CYCLE_LATENCY_RAM
`ifdef TWO_CYCLE_LATENCY_RAM
logic [10:0] read_hold;
`endif

// We want to skip the preamble
localparam READ_START = 8;
// We probably want to skip the CRC
localparam FCS_LEN = 0; // FIXME: Let's not skip it for now while debugging

// Break out the FIFO contents
assign {crc_error, frame_error, buf_num, pkt_len} = stored_fifo_data;
assign ram_rd_addr = {read_buf, read_pos};

rgmii_rx dut (
  .clk_rx(clk),
  .reset(reset),

  // Inputs from PHY (after DDR conversion)
  .rx_ctl_h('0), // RX_DV
  .rx_ctl_l('0), // RX_ER XOR RX_DV
  .rx_data_h('0),
  .rx_data_l('0),

  // RAM read interface
  .clk_ram_rd(clk),
  .ram_rd_ena(ram_rd_ena), // Read enable
  .ram_rd_addr(ram_rd_addr), // Read address
  .ram_rd_data(ram_rd_data), // Read data output

  // FIFO read interface
  .clk_fifo_rd(clk), // Usually same as clk_ram_rd
  .fifo_rd_empty(fifo_rd_empty),
  .fifo_rd_req(fifo_rd_req),
  .fifo_rd_data(fifo_rd_data)
);

// Build test bed that prints 32 characters received when we get a fifo.
logic [2:0] state = '0;
localparam FIFO_LATENCY = 2;
logic [3:0] latency_count;

always_ff @(posedge clk) begin
  case (state)
  0: begin
    // Wait for the fifo to be non-empty
    if (!fifo_rd_empty) begin
      fifo_rd_req <= '1;
      state <= 1;
      latency_count <= FIFO_LATENCY - 1;
      $display("Requesting read from FIFO @ %0t", $time);
      // Takes a cycle to read the data from FIFO
    end
  end

  1: begin
    // Save the data from the FIFO once our latency is over
    fifo_rd_req <= '0;
    if (latency_count == 0) begin
      stored_fifo_data <= fifo_rd_data;
      state <= 2;
      $display("Reading FIFO data now, %0h @ %0t", fifo_rd_data, $time);
    end else begin
      latency_count <= latency_count - 1'd1;
      $display("Waiting FIFO latency @ %0t", $time);
    end
  end

  2: begin
    // DO something with the saved data:
    // Set up to read through all the RAM
    $display("Doing something with FIFO data: %0h @ %0t", stored_fifo_data, $time);
    $display("Buffer %0h, Length %0h", buf_num, pkt_len);
    ram_rd_ena <= '1; // Do we need to read enable sooner? The answer seems NO
    // ram_read_addr is made up of the two things below - maybe it's too slow?
    read_buf <= buf_num;
    read_pos <= READ_START; // Skip Preamble & SFD
    // The address of the last byte we want to SEE before quitting
    read_end <= pkt_len - FCS_LEN - 1'd1; // Skip FCS/CRC
    state <= 3;
    // NOT next cycle, but the cycle after that we can read the data.
    // NEXT cycle, the RAM will see the read enable and address,
    // THEN it will output the data.
    // BUT we have to pipeline if we want to read a byte each time.
    // So, how do I know I'm reading a byte from 2 cycles ago?
    $write("Reading bytes: ");
    read_see <= '1; // Sentinel meaning "nothing"
`ifdef TWO_CYCLE_LATENCY_RAM
    read_hold <= '1; // Our intermediate between read_pos and read_see
`endif    
  end

  3: begin
    // Print the whole packet, one byte at a time, minus FCS (or with it, depending on settings above)
    if (read_see == '1)
      // We are not seeing any data yet
      $write("<latency> ");
    else
      $write("%2h:%2h ", read_see, ram_rd_data);
`ifdef TWO_CYCLE_LATENCY_RAM
    // We will see things in two cycles from when requested
    read_see <= read_hold;
    read_hold <= read_pos;
`else
    // Next cycle we will see the request from the previous cycle (for a single cycle latency RAM)
    read_see <= read_pos;
`endif
    // Quit when we see the final byte we want to process
    if (read_see == read_end) begin
      $display(" END (%0h) @ %0t", read_pos, $time);
      state <= 0;
      ram_rd_ena <= '0;
      // NOTE: If we want to do anything with read_see, we should
      // definitely register it and save it elsewhere because otherwise
      // it is going to be overwritten!
    end else begin
      read_pos <= read_pos + 1'd1;
      // FIXME: If the read_pos > read_end then disable read enable!
      // (Maybe add a "disable at" value, and once read_pos reaches
      // that, disable rd_ena - which is read_end + 1.)
    end
  end
  endcase
end


// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ %0t", $time);
  clk <= 1'b0;
  reset <= 1'b1; 
  #(reset_period) reset <= 1'b0;

  // Stop the simulation at appropriate point
  // #(period * 2 * 10000);
  #50000; // 40µs is enough to fill the FIFO and drop a few packets
  $display("Ending simulation @ %0t", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif