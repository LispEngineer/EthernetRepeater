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

// CRC polynomial coefficients: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
//                              0xEDB88320 (hex)
// CRC width:                   32 bits
// CRC shift direction:         right (little endian)
// Input word width:            8 bits

module crc32_8bit (
    input [31:0] crc_in,
    input [7:0] data_nibble,
    output [31:0] crc_out
);
    assign crc_out[0] = (crc_in[2] ^ crc_in[8] ^ data_nibble[2]);
    assign crc_out[1] = (crc_in[0] ^ crc_in[3] ^ crc_in[9] ^ data_nibble[0] ^ data_nibble[3]);
    assign crc_out[2] = (crc_in[0] ^ crc_in[1] ^ crc_in[4] ^ crc_in[10] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[4]);
    assign crc_out[3] = (crc_in[1] ^ crc_in[2] ^ crc_in[5] ^ crc_in[11] ^ data_nibble[1] ^ data_nibble[2] ^ data_nibble[5]);
    assign crc_out[4] = (crc_in[0] ^ crc_in[2] ^ crc_in[3] ^ crc_in[6] ^ crc_in[12] ^ data_nibble[0] ^ data_nibble[2] ^ data_nibble[3] ^ data_nibble[6]);
    assign crc_out[5] = (crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[7] ^ crc_in[13] ^ data_nibble[1] ^ data_nibble[3] ^ data_nibble[4] ^ data_nibble[7]);
    assign crc_out[6] = (crc_in[4] ^ crc_in[5] ^ crc_in[14] ^ data_nibble[4] ^ data_nibble[5]);
    assign crc_out[7] = (crc_in[0] ^ crc_in[5] ^ crc_in[6] ^ crc_in[15] ^ data_nibble[0] ^ data_nibble[5] ^ data_nibble[6]);
    assign crc_out[8] = (crc_in[1] ^ crc_in[6] ^ crc_in[7] ^ crc_in[16] ^ data_nibble[1] ^ data_nibble[6] ^ data_nibble[7]);
    assign crc_out[9] = (crc_in[7] ^ crc_in[17] ^ data_nibble[7]);
    assign crc_out[10] = (crc_in[2] ^ crc_in[18] ^ data_nibble[2]);
    assign crc_out[11] = (crc_in[3] ^ crc_in[19] ^ data_nibble[3]);
    assign crc_out[12] = (crc_in[0] ^ crc_in[4] ^ crc_in[20] ^ data_nibble[0] ^ data_nibble[4]);
    assign crc_out[13] = (crc_in[0] ^ crc_in[1] ^ crc_in[5] ^ crc_in[21] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[5]);
    assign crc_out[14] = (crc_in[1] ^ crc_in[2] ^ crc_in[6] ^ crc_in[22] ^ data_nibble[1] ^ data_nibble[2] ^ data_nibble[6]);
    assign crc_out[15] = (crc_in[2] ^ crc_in[3] ^ crc_in[7] ^ crc_in[23] ^ data_nibble[2] ^ data_nibble[3] ^ data_nibble[7]);
    assign crc_out[16] = (crc_in[0] ^ crc_in[2] ^ crc_in[3] ^ crc_in[4] ^ crc_in[24] ^ data_nibble[0] ^ data_nibble[2] ^ data_nibble[3] ^ data_nibble[4]);
    assign crc_out[17] = (crc_in[0] ^ crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[5] ^ crc_in[25] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[3] ^ data_nibble[4] ^ data_nibble[5]);
    assign crc_out[18] = (crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[6] ^ crc_in[26] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[2] ^ data_nibble[4] ^ data_nibble[5] ^ data_nibble[6]);
    assign crc_out[19] = (crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ crc_in[7] ^ crc_in[27] ^ data_nibble[1] ^ data_nibble[2] ^ data_nibble[3] ^ data_nibble[5] ^ data_nibble[6] ^ data_nibble[7]);
    assign crc_out[20] = (crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[7] ^ crc_in[28] ^ data_nibble[3] ^ data_nibble[4] ^ data_nibble[6] ^ data_nibble[7]);
    assign crc_out[21] = (crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ crc_in[29] ^ data_nibble[2] ^ data_nibble[4] ^ data_nibble[5] ^ data_nibble[7]);
    assign crc_out[22] = (crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ crc_in[30] ^ data_nibble[2] ^ data_nibble[3] ^ data_nibble[5] ^ data_nibble[6]);
    assign crc_out[23] = (crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[7] ^ crc_in[31] ^ data_nibble[3] ^ data_nibble[4] ^ data_nibble[6] ^ data_nibble[7]);
    assign crc_out[24] = (crc_in[0] ^ crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ data_nibble[0] ^ data_nibble[2] ^ data_nibble[4] ^ data_nibble[5] ^ data_nibble[7]);
    assign crc_out[25] = (crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[2] ^ data_nibble[3] ^ data_nibble[5] ^ data_nibble[6]);
    assign crc_out[26] = (crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[7] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[2] ^ data_nibble[3] ^ data_nibble[4] ^ data_nibble[6] ^ data_nibble[7]);
    assign crc_out[27] = (crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ data_nibble[1] ^ data_nibble[3] ^ data_nibble[4] ^ data_nibble[5] ^ data_nibble[7]);
    assign crc_out[28] = (crc_in[0] ^ crc_in[4] ^ crc_in[5] ^ crc_in[6] ^ data_nibble[0] ^ data_nibble[4] ^ data_nibble[5] ^ data_nibble[6]);
    assign crc_out[29] = (crc_in[0] ^ crc_in[1] ^ crc_in[5] ^ crc_in[6] ^ crc_in[7] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[5] ^ data_nibble[6] ^ data_nibble[7]);
    assign crc_out[30] = (crc_in[0] ^ crc_in[1] ^ crc_in[6] ^ crc_in[7] ^ data_nibble[0] ^ data_nibble[1] ^ data_nibble[6] ^ data_nibble[7]);
    assign crc_out[31] = (crc_in[1] ^ crc_in[7] ^ data_nibble[1] ^ data_nibble[7]);
endmodule

`endif // CRC32_8BIT_V_