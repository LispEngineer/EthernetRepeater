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

// This module is usually in its own clock domain (tx_clk).
// This module outputs data and clock completely aligned.
// If the `gtx_clk` needs to be skewed, it has to happen outside of here.
// In non-DDR mode, we transmit the low nibble first!

// Our fixed send data, for now
module data_packet (
  input  logic [5:0] addr,
  output logic [7:0] val
);

always_comb
  case (addr)
  6'd0: val = 8'hff;
  6'd1: val = 8'hff;
  6'd2: val = 8'hff;
  6'd3: val = 8'hff;
  6'd4: val = 8'hff;
  6'd5: val = 8'hff;
  6'd6: val = 8'h06;
  6'd7: val = 8'he0;
  6'd8: val = 8'h4c;
  6'd9: val = 8'hDF;
  6'd10: val = 8'hDF;
  6'd11: val = 8'hDF;
  6'd12: val = 8'h08;
  6'd13: val = 8'h06;
  6'd14: val = 8'h00;
  6'd15: val = 8'h01;
  6'd16: val = 8'h00;
  6'd17: val = 8'h00;
  6'd18: val = 8'h06;
  6'd19: val = 8'h04;
  6'd20: val = 8'h00;
  6'd21: val = 8'h01;
  6'd22: val = 8'h06;
  6'd23: val = 8'he0;
  6'd24: val = 8'h4c;
  6'd25: val = 8'hDF;
  6'd26: val = 8'hDF;
  6'd27: val = 8'hDF;
  6'd28: val = 8'h10;
  6'd29: val = 8'h20;
  6'd30: val = 8'hDF;
  6'd31: val = 8'hDF;
  6'd32: val = 8'h00;
  6'd33: val = 8'h00;
  6'd34: val = 8'h00;
  6'd35: val = 8'h00;
  6'd36: val = 8'h00;
  6'd37: val = 8'h00;
  6'd38: val = 8'hff;
  6'd39: val = 8'hff;
  6'd40: val = 8'hff;
  6'd41: val = 8'hff;
  6'd42: val = 8'h00;
  6'd43: val = 8'h00;
  6'd44: val = 8'h00;
  6'd45: val = 8'h00;
  6'd46: val = 8'h00;
  6'd47: val = 8'h00;
  6'd48: val = 8'h00;
  6'd49: val = 8'h00;
  6'd50: val = 8'h00;
  6'd51: val = 8'h00;
  6'd52: val = 8'h00;
  6'd53: val = 8'h00;
  6'd54: val = 8'h00;
  6'd55: val = 8'h00;
  6'd56: val = 8'h00;
  6'd57: val = 8'h00;
  6'd58: val = 8'h75; // CRC
  6'd59: val = 8'h0B;
  6'd60: val = 8'h4B;
  6'd61: val = 8'h43;
  default: val = 8'hff;
  endcase

endmodule // data_packet
localparam LAST_DATA_BYTE = 6'd57; // plus 4 for CRC
localparam LAST_CRC_BYTE = 6'd61;

module rgmii_tx /* #(
  // No parameters, yet
) */ (
  // Our appropriate speed clock input (copied to output)
  input  logic tx_clk,
  input  logic reset,

  // Should we transmit data in DDR?
  // This is only used for 1000
  input  logic ddr_tx, // SYNCHRONIZED (but should be very slow changing)
  // Should we send something?
  input  logic activate, // SYNCHRONIZED
  // Are we currently sending something?
  output logic busy,

  // RGMII OUTPUTS ///////////////////////
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
  output logic tx_ctl_l  // TX_ERR XOR TX_EN
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

localparam BYTES_PREAMBLE = 8'b1010_1010;
localparam BYTES_SFD      = 8'b1010_1011;


localparam SYNC_LEN = 2;
logic [(SYNC_LEN - 1):0] syncd_activate;
logic [(SYNC_LEN - 1):0] syncd_ddr_tx;
logic real_activate;
logic real_ddr_tx;
// Registered real_ddr_tx when we become activated
logic txn_ddr;

// Our actual low-level logic registered signals for transmit enable & error
logic tx_en;
logic tx_err;

logic [7:0] current_data;

data_packet data_packet (
  .addr(count),
  .val(current_data)
);

always_comb begin
  gtx_clk = tx_clk;
  tx_ctl_h = tx_en;
  tx_ctl_l = tx_en ^ tx_err;
  real_activate = syncd_activate[SYNC_LEN - 1];
  real_ddr_tx = syncd_ddr_tx[SYNC_LEN - 1];
end

// Synchronizer
always_ff @(posedge tx_clk) begin
  syncd_activate <= {syncd_activate[(SYNC_LEN - 2):0], activate};
  syncd_ddr_tx   <= {syncd_ddr_tx  [(SYNC_LEN - 2):0], ddr_tx};
end // synchronizer

// State machine
always_ff @(posedge tx_clk) begin

  if (reset) begin /////////////////////////////////////////////////////

    tx_en <= '0;
    tx_err <= '0;
    state <= S_IDLE;
  
  end else begin ///////////////////////////////////////////////////////

    // Remember: In the timing diagram, the transmissions will be one clock
    // cycle behind the state, because it's all registered for the next cycle.

    case (state)

      S_IDLE: begin ////////////////////////////////////////////////////
        tx_en <= '0;
        tx_err <= '0;
        busy <= '0;

        // FIXME: Add an interframe delay per spec, before activation.
        // So, let's do this right when we become idle.
        if (real_activate) begin
          // We need to send a packet
          txn_ddr <= real_ddr_tx;
          busy <= '1;
          state <= S_PREAMBLE;
          nibble <= NIBBLE_LOW;
          count <= '0;
        end

      end

      S_PREAMBLE: begin ////////////////////////////////////////////////////
        // Preamble is 7 bytes of 1010_1010

        tx_en <= '1;
        tx_err <= '0; // Not sure when we would ever set this

        if (!txn_ddr) begin

          // Non-DDR (regular MII) mode:
          // FIXME: Review Table 22-3 in 802.3-2022
          // It seems that the txd[0] is MSB of nibble
          // and txd[3] is LSB of the nibble.
          // Example:
          // Preamble: txd0=1, txd1=0, txd2=0, txd3=1 x15
          //     then: txd0=1, txd1=0, txd2=1, txd3=1 x1
          // Then first data byte:
          // txd0=d0, txd1=d1, txd2=d2, txd3=d3
          // txd0=d4, txd1=d5, txd2=d6, txd3=d7
          // Serially, we would transmit LSB first, and then
          // stick the lsb into txd0, txd1, txd2, txd3

          nibble <= ~nibble;
          if (nibble) begin
            count <= count + 1'd1;
            if (count == 6) begin
              // We are sending our 7th byte, second nibble, move on to SFP
              state <= S_SFD;
            end
            tx_data_h <= {BYTES_PREAMBLE[4], BYTES_PREAMBLE[5], BYTES_PREAMBLE[6], BYTES_PREAMBLE[7]};
            tx_data_l <= {BYTES_PREAMBLE[4], BYTES_PREAMBLE[5], BYTES_PREAMBLE[6], BYTES_PREAMBLE[7]};
          end else begin 
            // Bottom nibble sent first, LSB first
            tx_data_h <= {BYTES_PREAMBLE[0], BYTES_PREAMBLE[1], BYTES_PREAMBLE[2], BYTES_PREAMBLE[3]};
            tx_data_l <= {BYTES_PREAMBLE[0], BYTES_PREAMBLE[1], BYTES_PREAMBLE[2], BYTES_PREAMBLE[3]};
            // Same on both sides, not DDR
          end
        end // !ddr
        // FIXME: CODE txn_ddr

      end

      S_SFD: begin ////////////////////////////////////////////////////
        // SFD is 1010_1011

        if (!txn_ddr) begin
          nibble <= ~nibble;
          if (nibble) begin
            // Send our second half and move to sending data
            state <= S_DATA;
            count <= '0;
            tx_data_h <= {BYTES_SFD[4], BYTES_SFD[5], BYTES_SFD[6], BYTES_SFD[7]};
            tx_data_l <= {BYTES_SFD[4], BYTES_SFD[5], BYTES_SFD[6], BYTES_SFD[7]};
          end else begin
            tx_data_h <= {BYTES_SFD[0], BYTES_SFD[1], BYTES_SFD[2], BYTES_SFD[3]};
            tx_data_l <= {BYTES_SFD[0], BYTES_SFD[1], BYTES_SFD[2], BYTES_SFD[3]};
          end
        end // !ddr

        // FIXME: CODE txn_ddr
      end

      S_DATA: begin ////////////////////////////////////////////////////
        // We are going to send the data of an ARP request

        if (!txn_ddr) begin
          nibble <= ~nibble;
          if (!nibble) begin
            // First half of our byte - lower part
            tx_data_h <= {current_data[0], current_data[1], current_data[2], current_data[3]};
            tx_data_l <= {current_data[0], current_data[1], current_data[2], current_data[3]};
          end else begin
            // Second half of our byte - higher part
            tx_data_h <= {current_data[4], current_data[5], current_data[6], current_data[7]};
            tx_data_l <= {current_data[4], current_data[5], current_data[6], current_data[7]};
            count <= count + 1'd1;
            // FIXME: For now we send CRC as part of data
            if (count == LAST_CRC_BYTE) begin
              state <= S_IDLE;
              // Let's stay busy until we're IN the idle state
            end
          end
        end

        // FIXME: CODE txn_ddr
      end

      S_FCS: begin ////////////////////////////////////////////////////
        // We are going to send a fixed CRC value for FCS
        state <= S_IDLE;
        busy <= '0;
        // FIXME: CODE ME
        // FOR NOW: Is part of S_DATA
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