// Ethernet Repeater
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

// Empty top-level originally built by Terasic System Builder

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


module EthernetRepeater(

  //////////// CLOCK //////////
  input  logic        CLOCK_50,
  input  logic        CLOCK2_50,
  input  logic        CLOCK3_50,

  //////////// LED //////////
  output logic  [8:0] LEDG,
  output logic [17:0] LEDR,

  //////////// KEY //////////
  input  logic  [3:0] KEY,

  //////////// EX_IO //////////
  inout  logic  [6:0] EX_IO,

  //////////// SW //////////
  input  logic [17:0] SW,

  //////////// SEG7 //////////
  output logic  [6:0] HEX0,
  output logic  [6:0] HEX1,
  output logic  [6:0] HEX2,
  output logic  [6:0] HEX3,
  output logic  [6:0] HEX4,
  output logic  [6:0] HEX5,
  output logic  [6:0] HEX6,
  output logic  [6:0] HEX7,

  //////////// LCD //////////
  output logic        LCD_BLON,
  inout  logic  [7:0] LCD_DATA,
  output logic        LCD_EN,
  output logic        LCD_ON,
  output logic        LCD_RS,
  output logic        LCD_RW,

  //////////// RS232 //////////
  input  logic        UART_CTS,
  output logic        UART_RTS,
  input  logic        UART_RXD,
  output logic        UART_TXD,

  //////////// PS2 for Keyboard and Mouse //////////
  inout  logic        PS2_CLK,
  inout  logic        PS2_CLK2,
  inout  logic        PS2_DAT,
  inout  logic        PS2_DAT2,

  //////////// SDCARD //////////
  output logic        SD_CLK,
  inout  logic        SD_CMD,
  inout  logic  [3:0] SD_DAT,
  input  logic        SD_WP_N,

  //////////// VGA //////////
  output logic  [7:0] VGA_B,
  output logic        VGA_BLANK_N,
  output logic        VGA_CLK,
  output logic  [7:0] VGA_G,
  output logic        VGA_HS,
  output logic  [7:0] VGA_R,
  output logic        VGA_SYNC_N,
  output logic        VGA_VS,

  //////////// Audio //////////
  input  logic        AUD_ADCDAT,
  inout  logic        AUD_ADCLRCK,
  inout  logic        AUD_BCLK,
  output logic        AUD_DACDAT,
  inout  logic        AUD_DACLRCK,
  output logic        AUD_XCK,

  //////////// I2C for EEPROM //////////
  output logic        EEP_I2C_SCLK,
  inout  logic        EEP_I2C_SDAT,

  //////////// I2C for Audio HSMC  //////////
  output logic        I2C_SCLK,
  inout  logic        I2C_SDAT,

  //////////// Ethernet 0 //////////
  output logic        ENET0_GTX_CLK,
  input  logic        ENET0_INT_N,
  input  logic        ENET0_LINK100,
  output logic        ENET0_MDC,
  inout  logic        ENET0_MDIO,
  output logic        ENET0_RST_N,
  input  logic        ENET0_RX_CLK,
  input  logic        ENET0_RX_COL,
  input  logic        ENET0_RX_CRS,
  input  logic  [3:0] ENET0_RX_DATA,
  input  logic        ENET0_RX_DV,
  input  logic        ENET0_RX_ER,
  input  logic        ENET0_TX_CLK,
  output logic  [3:0] ENET0_TX_DATA,
  output logic        ENET0_TX_EN,
  output logic        ENET0_TX_ER,
  input  logic        ENETCLK_25,

  //////////// Ethernet 1 //////////
  output logic        ENET1_GTX_CLK,
  input  logic        ENET1_INT_N,
  input  logic        ENET1_LINK100,
  output logic        ENET1_MDC,
  inout  logic        ENET1_MDIO,
  output logic        ENET1_RST_N,
  input  logic        ENET1_RX_CLK,
  input  logic        ENET1_RX_COL,
  input  logic        ENET1_RX_CRS,
  input  logic  [3:0] ENET1_RX_DATA,
  input  logic        ENET1_RX_DV,
  input  logic        ENET1_RX_ER,
  input  logic        ENET1_TX_CLK,
  output logic  [3:0] ENET1_TX_DATA,
  output logic        ENET1_TX_EN,
  output logic        ENET1_TX_ER,

  //////////// USB 2.0 OTG (Cypress CY7C67200) //////////
  output logic  [1:0] OTG_ADDR,
  output logic        OTG_CS_N,
  inout  logic [15:0] OTG_DATA,
  input  logic        OTG_INT,
  output logic        OTG_RD_N,
  output logic        OTG_RST_N,
  output logic        OTG_WE_N,

  //////////// SDRAM //////////
  output logic [12:0] DRAM_ADDR,
  output logic  [1:0] DRAM_BA,
  output logic        DRAM_CAS_N,
  output logic        DRAM_CKE,
  output logic        DRAM_CLK,
  output logic        DRAM_CS_N,
  inout  logic [31:0] DRAM_DQ,
  output logic  [3:0] DRAM_DQM,
  output logic        DRAM_RAS_N,
  output logic        DRAM_WE_N,

  //////////// SRAM //////////
  output logic [19:0] SRAM_ADDR,
  output logic        SRAM_CE_N,
  inout  logic [15:0] SRAM_DQ,
  output logic        SRAM_LB_N,
  output logic        SRAM_OE_N,
  output logic        SRAM_UB_N,
  output logic        SRAM_WE_N,

  //////////// Flash //////////
  output logic [22:0] FL_ADDR,
  output logic        FL_CE_N,
  inout  logic  [7:0] FL_DQ,
  output logic        FL_OE_N,
  output logic        FL_RST_N,
  input  logic        FL_RY,
  output logic        FL_WE_N,
  output logic        FL_WP_N,

  //////////// GPIO, GPIO connect to GPIO Default //////////
  inout  logic [35:0] GPIO,

  //////////// HSMC, HSMC connect to DVI - FullHD TX/RX //////////
  output logic        DVI_EDID_WP,
  input  logic        DVI_RX_CLK,
  input  logic  [3:1] DVI_RX_CTL,
  input  logic [23:0] DVI_RX_D,
  inout  logic        DVI_RX_DDCSCL,
  inout  logic        DVI_RX_DDCSDA,
  input  logic        DVI_RX_DE,
  input  logic        DVI_RX_HS,
  input  logic        DVI_RX_SCDT,
  input  logic        DVI_RX_VS,
  output logic        DVI_TX_CLK,
  output logic  [3:1] DVI_TX_CTL,
  output logic [23:0] DVI_TX_D,
  inout  logic        DVI_TX_DDCSCL,
  inout  logic        DVI_TX_DDCSDA,
  output logic        DVI_TX_DE,
  output logic        DVI_TX_DKEN,
  output logic        DVI_TX_HS,
  output logic        DVI_TX_HTPLG,
  output logic        DVI_TX_ISEL,
  output logic        DVI_TX_MSEN,
  output logic        DVI_TX_PD_N,
  output logic        DVI_TX_SCL,
  inout  logic        DVI_TX_SDA,
  output logic        DVI_TX_VS
);

// Zero out unused outputs
always_comb begin
  LEDG[8:4] = 'b0;
  LEDR = 'b0;
  HEX0 = 'b0;
  HEX1 = 'b0;
  HEX2 = 'b0;
  HEX3 = 'b0;
  HEX4 = 'b0;
  HEX5 = 'b0;
  HEX6 = 'b0;
  HEX7 = 'b0;
  DVI_TX_CTL = 'b0;
  DVI_TX_D = 'b0;
  DVI_TX_CLK = 'b0;
  DVI_TX_DE = 'b0;
  DVI_TX_DKEN = 'b0;
  DVI_TX_HS = 'b0;
  DVI_TX_HTPLG = 'b0;
  DVI_TX_ISEL = 'b0;
  DVI_TX_MSEN = 'b0;
  DVI_TX_PD_N = 'b0;
  DVI_TX_SCL = 'b0;
  DVI_TX_VS = 'b0;
  DVI_EDID_WP = 'b0;
  LCD_BLON = 'b0;
  LCD_EN = 'b0;
  LCD_RS = 'b0;
  LCD_RW = 'b0;
  LCD_ON = 'b0;
  UART_RTS = 'b0;
  UART_TXD = 'b0;
  SD_CLK = 'b0;
  VGA_R = 'b0;
  VGA_G = 'b0;
  VGA_B = 'b0;
  VGA_BLANK_N = 'b0;
  VGA_CLK = 'b0;
  VGA_HS = 'b0;
  VGA_SYNC_N = 'b0;
  VGA_VS = 'b0;
  AUD_DACDAT = 'b0;
  AUD_XCK = 'b0;
  EEP_I2C_SCLK = 'b0;
  I2C_SCLK = 'b0;
  ENET0_GTX_CLK = 'b0;
  ENET0_MDC = 'b0;
  ENET0_RST_N = 'b0;
  ENET0_TX_EN = 'b0;
  ENET0_TX_ER = 'b0;
  ENET0_TX_DATA = 'b0;
  ENET1_TX_DATA = 'b0;
  ENET1_GTX_CLK = 'b0;
  ENET1_MDC = 'b0;
  ENET1_RST_N = 'b0;
  ENET1_TX_EN = 'b0;
  ENET1_TX_ER = 'b0;
  OTG_ADDR = 'b0;
  OTG_CS_N = 'b0;
  OTG_RD_N = 'b0;
  OTG_RST_N = 'b0;
  OTG_WE_N = 'b0;
  DRAM_ADDR = 'b0;
  DRAM_BA = 'b0;
  DRAM_DQM = 'b0;
  DRAM_CAS_N = 'b0;
  DRAM_CKE = 'b0;
  DRAM_CLK = 'b0;
  DRAM_CS_N = 'b0;
  DRAM_RAS_N = 'b0;
  DRAM_WE_N = 'b0;
  SRAM_ADDR = 'b0;
  SRAM_CE_N = 'b0;
  SRAM_LB_N = 'b0;
  SRAM_OE_N = 'b0;
  SRAM_UB_N = 'b0;
  SRAM_WE_N = 'b0;
  FL_ADDR = 'b0;
  FL_CE_N = 'b0;
  FL_OE_N = 'b0;
  FL_RST_N = 'b0;
  FL_WE_N = 'b0;
  FL_WP_N = 'b0;
end

// Tristate unused inouts
always_comb begin
  EX_IO = 'z;
  LCD_DATA = 'z;
  PS2_CLK = 'z;
  PS2_CLK2 = 'z;
  PS2_DAT = 'z;
  PS2_DAT2 = 'z;
  SD_CMD = 'z;
  SD_DAT = 'z;
  AUD_ADCLRCK = 'z;
  AUD_BCLK = 'z;
  AUD_DACLRCK = 'z;
  EEP_I2C_SDAT = 'z;
  I2C_SDAT = 'z;
  ENET0_MDIO = 'z;
  ENET1_MDIO = 'z;
  OTG_DATA = 'z;
  DRAM_DQ = 'z;
  SRAM_DQ = 'z;
  FL_DQ = 'z;
  GPIO = 'z;
  DVI_RX_DDCSCL = 'z;
  DVI_RX_DDCSDA = 'z;
  DVI_TX_DDCSCL = 'z;
  DVI_TX_DDCSDA = 'z;
  DVI_TX_SDA = 'z;
end

logic [31:0] counter = 0;

always_ff @(posedge CLOCK_50) begin
  counter <= counter + 1;
end

assign LEDG[3:0] = counter[28:25];

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa