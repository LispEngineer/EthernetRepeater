// Enhanced by Douglas P. Fields, Jr. in 2023 to SystemVerilog.

// THIS IS GENERATED VERILOG CODE.
// https://bues.ch/h/crcgen
// 
// This code is Public Domain.
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted.
// 
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
// RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
// NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE
// USE OR PERFORMANCE OF THIS SOFTWARE.

`ifndef CRC32_8BIT_V_
`define CRC32_8BIT_V_

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// CRC polynomial coefficients: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
//                              0xEDB88320 (hex)
// CRC width:                   32 bits
// CRC shift direction:         right (little endian)
// Input word width:            8 bits

module crc32_8bit(
    input  [31:0] crc_in,
    input   [7:0] data_byte,
    output [31:0] crc_out
);

always_comb begin
  crc_out[0] = (crc_in[2] ^ crc_in[8] ^ data_byte[2]);
  crc_out[1] = (crc_in[0] ^ crc_in[3] ^ crc_in[9] ^ data_byte[0] ^ data_byte[3]);
  crc_out[2] = (crc_in[0] ^ crc_in[1] ^ crc_in[4] ^ crc_in[10] ^ data_byte[0] ^ data_byte[1] ^ data_byte[4]);
  crc_out[3] = (crc_in[1] ^ crc_in[2] ^ crc_in[5] ^ crc_in[11] ^ data_byte[1] ^ data_byte[2] ^ data_byte[5]);
  crc_out[4] = (crc_in[0] ^ crc_in[2] ^ crc_in[3] ^ crc_in[6] ^ crc_in[12] ^ data_byte[0] ^ data_byte[2] ^ data_byte[3] ^ data_byte[6]);
  crc_out[5] = (crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[7] ^ crc_in[13] ^ data_byte[1] ^ data_byte[3] ^ data_byte[4] ^ data_byte[7]);
  crc_out[6] = (crc_in[4] ^ crc_in[5] ^ crc_in[14] ^ data_byte[4] ^ data_byte[5]);
  crc_out[7] = (crc_in[0] ^ crc_in[5] ^ crc_in[6] ^ crc_in[15] ^ data_byte[0] ^ data_byte[5] ^ data_byte[6]);
  crc_out[8] = (crc_in[1] ^ crc_in[6] ^ crc_in[7] ^ crc_in[16] ^ data_byte[1] ^ data_byte[6] ^ data_byte[7]);
  crc_out[9] = (crc_in[7] ^ crc_in[17] ^ data_byte[7]);
  crc_out[10] = (crc_in[2] ^ crc_in[18] ^ data_byte[2]);
  crc_out[11] = (crc_in[3] ^ crc_in[19] ^ data_byte[3]);
  crc_out[12] = (crc_in[0] ^ crc_in[4] ^ crc_in[20] ^ data_byte[0] ^ data_byte[4]);
  crc_out[13] = (crc_in[0] ^ crc_in[1] ^ crc_in[5] ^ crc_in[21] ^ data_byte[0] ^ data_byte[1] ^ data_byte[5]);
  crc_out[14] = (crc_in[1] ^ crc_in[2] ^ crc_in[6] ^ crc_in[22] ^ data_byte[1] ^ data_byte[2] ^ data_byte[6]);
  crc_out[15] = (crc_in[2] ^ crc_in[3] ^ crc_in[7] ^ crc_in[23] ^ data_byte[2] ^ data_byte[3] ^ data_byte[7]);
  crc_out[16] = (crc_in[0] ^ crc_in[2] ^ crc_in[3] ^ crc_in[4] ^ crc_in[24] ^ data_byte[0] ^ data_byte[2] ^ data_byte[3] ^ data_byte[4]);
  crc_out[17] = (crc_in[0] ^ crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[5] ^ crc_in[25] ^ data_byte[0] ^ data_byte[1] ^ data_byte[3] ^ data_byte[4] ^ data_byte[5]);
  crc_out[18] = (crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[6] ^ crc_in[26] ^ data_byte[0] ^ data_byte[1] ^ data_byte[2] ^ data_byte[4] ^ data_byte[5] ^ data_byte[6]);
  crc_out[19] = (crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ crc_in[7] ^ crc_in[27] ^ data_byte[1] ^ data_byte[2] ^ data_byte[3] ^ data_byte[5] ^ data_byte[6] ^ data_byte[7]);
  crc_out[20] = (crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[7] ^ crc_in[28] ^ data_byte[3] ^ data_byte[4] ^ data_byte[6] ^ data_byte[7]);
  crc_out[21] = (crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ crc_in[29] ^ data_byte[2] ^ data_byte[4] ^ data_byte[5] ^ data_byte[7]);
  crc_out[22] = (crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ crc_in[30] ^ data_byte[2] ^ data_byte[3] ^ data_byte[5] ^ data_byte[6]);
  crc_out[23] = (crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[7] ^ crc_in[31] ^ data_byte[3] ^ data_byte[4] ^ data_byte[6] ^ data_byte[7]);
  crc_out[24] = (crc_in[0] ^ crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ data_byte[0] ^ data_byte[2] ^ data_byte[4] ^ data_byte[5] ^ data_byte[7]);
  crc_out[25] = (crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ data_byte[0] ^ data_byte[1] ^ data_byte[2] ^ data_byte[3] ^ data_byte[5] ^ data_byte[6]);
  crc_out[26] = (crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[7] ^ data_byte[0] ^ data_byte[1] ^ data_byte[2] ^ data_byte[3] ^ data_byte[4] ^ data_byte[6] ^ data_byte[7]);
  crc_out[27] = (crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ data_byte[1] ^ data_byte[3] ^ data_byte[4] ^ data_byte[5] ^ data_byte[7]);
  crc_out[28] = (crc_in[0] ^ crc_in[4] ^ crc_in[5] ^ crc_in[6] ^ data_byte[0] ^ data_byte[4] ^ data_byte[5] ^ data_byte[6]);
  crc_out[29] = (crc_in[0] ^ crc_in[1] ^ crc_in[5] ^ crc_in[6] ^ crc_in[7] ^ data_byte[0] ^ data_byte[1] ^ data_byte[5] ^ data_byte[6] ^ data_byte[7]);
  crc_out[30] = (crc_in[0] ^ crc_in[1] ^ crc_in[6] ^ crc_in[7] ^ data_byte[0] ^ data_byte[1] ^ data_byte[6] ^ data_byte[7]);
  crc_out[31] = (crc_in[1] ^ crc_in[7] ^ data_byte[1] ^ data_byte[7]);
end

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif


`endif // CRC32_8BIT_V_
