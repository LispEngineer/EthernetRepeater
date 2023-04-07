// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved. 

// Combinational logic to decode a nibble to a 7-segment
// display. Output is LSB = segment A.
// (A = top; counts around clockwise, then the last seg is the middle dash.)

module seven_segment (
  input  logic [3:0] num,
  output logic [6:0] hex
);
  
// Purpose: Creates a case statement for all possible input binary numbers.
// Drives hex appropriately for each input combination.
always_comb
  case (num)
    4'b0000 : hex = 7'b011_1111; // 7E;
    4'b0001 : hex = 7'b000_0110; // 30;
    4'b0010 : hex = 7'b101_1011; // 6D;
    4'b0011 : hex = 7'b100_1111; // 79;
    4'b0100 : hex = 7'b110_0110; // 33;          
    4'b0101 : hex = 7'b110_1101; // 5B;
    4'b0110 : hex = 7'b111_1101; // 5F;
    4'b0111 : hex = 7'b000_0111; // 70;
    4'b1000 : hex = 7'b111_1111; // 7F;
    4'b1001 : hex = 7'b110_1111; // 7B;
    4'b1010 : hex = 7'b111_0111; // 77;
    4'b1011 : hex = 7'b111_1100; // 1F;
    4'b1100 : hex = 7'b011_1001; // 4E;
    4'b1101 : hex = 7'b101_1110; // 3D;
    4'b1110 : hex = 7'b111_1001; // 4F;
    4'b1111 : hex = 7'b111_0001; // 47;
  endcase
  
endmodule
