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
  // These are logic 0 when pressed
  input  logic  [3:0] KEY,

  //////////// EX_IO //////////
  inout  wire   [6:0] EX_IO,

  //////////// SW //////////
  input  logic [17:0] SW,

  //////////// SEG7 //////////
  // All of these use logic 0 to light up the segment
  // These are off with logic 1
  output logic  [6:0] HEX0,
  output logic  [6:0] HEX1,
  output logic  [6:0] HEX2,
  output logic  [6:0] HEX3,
  output logic  [6:0] HEX4,
  output logic  [6:0] HEX5,
  output logic  [6:0] HEX6,
  output logic  [6:0] HEX7,

  //////////// LCD //////////
  // See data sheet for initialization sequence
  output logic        LCD_BLON, // Backlight - NOT CONNECTED
  inout  wire   [7:0] LCD_DATA,
  output logic        LCD_EN, // Enable
  output logic        LCD_ON, // LCD Power On/Off
  output logic        LCD_RS, // 1 = Data, 0 = Instruction
  output logic        LCD_RW, // 1 = Read, 0 = Write

  //////////// RS232 //////////
  input  logic        UART_CTS,
  output logic        UART_RTS,
  input  logic        UART_RXD,
  output logic        UART_TXD,

  //////////// PS2 for Keyboard and Mouse //////////
  inout  wire         PS2_CLK,
  inout  wire         PS2_CLK2,
  inout  wire         PS2_DAT,
  inout  wire         PS2_DAT2,

  //////////// SDCARD //////////
  output logic        SD_CLK,
  inout  wire         SD_CMD,
  inout  wire   [3:0] SD_DAT,
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
  inout  wire         AUD_ADCLRCK,
  inout  wire         AUD_BCLK,
  output logic        AUD_DACDAT,
  inout  wire         AUD_DACLRCK,
  output logic        AUD_XCK,

  //////////// I2C for EEPROM //////////
  output logic        EEP_I2C_SCLK,
  inout  wire         EEP_I2C_SDAT,

  //////////// I2C for Audio HSMC  //////////
  output logic        I2C_SCLK,
  inout  wire         I2C_SDAT,

  //////////// Ethernet 0 //////////
  output logic        ENET0_GTX_CLK,
  input  logic        ENET0_INT_N,
  input  logic        ENET0_LINK100,
  output logic        ENET0_MDC,
  inout  wire         ENET0_MDIO,
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
  inout  wire         ENET1_MDIO,
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
  inout  wire  [15:0] OTG_DATA,
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
  inout  wire  [31:0] DRAM_DQ,
  output logic  [3:0] DRAM_DQM,
  output logic        DRAM_RAS_N,
  output logic        DRAM_WE_N,

  //////////// SRAM //////////
  output logic [19:0] SRAM_ADDR,
  output logic        SRAM_CE_N,
  inout  wire  [15:0] SRAM_DQ,
  output logic        SRAM_LB_N,
  output logic        SRAM_OE_N,
  output logic        SRAM_UB_N,
  output logic        SRAM_WE_N,

  //////////// Flash //////////
  output logic [22:0] FL_ADDR,
  output logic        FL_CE_N,
  inout  wire   [7:0] FL_DQ,
  output logic        FL_OE_N,
  output logic        FL_RST_N,
  input  logic        FL_RY,
  output logic        FL_WE_N,
  output logic        FL_WP_N,

  //////////// GPIO, GPIO connect to GPIO Default //////////
  inout  wire  [35:0] GPIO,

  //////////// HSMC, HSMC connect to DVI - FullHD TX/RX //////////
  output logic        DVI_EDID_WP,
  input  logic        DVI_RX_CLK,
  input  logic  [3:1] DVI_RX_CTL,
  input  logic [23:0] DVI_RX_D,
  inout  wire         DVI_RX_DDCSCL,
  inout  wire         DVI_RX_DDCSDA,
  input  logic        DVI_RX_DE,
  input  logic        DVI_RX_HS,
  input  logic        DVI_RX_SCDT,
  input  logic        DVI_RX_VS,
  output logic        DVI_TX_CLK,
  output logic  [3:1] DVI_TX_CTL,
  output logic [23:0] DVI_TX_D,
  inout  wire         DVI_TX_DDCSCL,
  inout  wire         DVI_TX_DDCSDA,
  output logic        DVI_TX_DE,
  output logic        DVI_TX_DKEN,
  output logic        DVI_TX_HS,
  output logic        DVI_TX_HTPLG,
  output logic        DVI_TX_ISEL,
  output logic        DVI_TX_MSEN,
  output logic        DVI_TX_PD_N,
  output logic        DVI_TX_SCL,
  inout  wire         DVI_TX_SDA,
  output logic        DVI_TX_VS
);

// Zero out unused outputs
always_comb begin
  LEDG[6:5] = '0;
  LEDR[17:16] = '0;
  HEX0 = '1; // These LED segments are OFF when logic 1
  HEX1 = '1;
  HEX2 = '1;
  HEX3 = '1;
  HEX4 = '1;
  HEX5 = '1;
  HEX6 = '1;
  HEX7 = '1;
  DVI_TX_CTL = '0;
  DVI_TX_D = '0;
  DVI_TX_CLK = '0;
  DVI_TX_DE = '0;
  DVI_TX_DKEN = '0;
  DVI_TX_HS = '0;
  DVI_TX_HTPLG = '0;
  DVI_TX_ISEL = '0;
  DVI_TX_MSEN = '0;
  DVI_TX_PD_N = '0;
  DVI_TX_SCL = '0;
  DVI_TX_VS = '0;
  DVI_EDID_WP = '0;
  LCD_BLON = '0; // Turn Backlight on? Shouldn't do anything
  LCD_EN = '0;
  LCD_RS = '0;
  LCD_RW = '0;
  LCD_ON = '0; // Turn LCD on
  UART_RTS = '0;
  UART_TXD = '1; // Marking means we're transmitting nothing
  SD_CLK = '0;
  VGA_R = '0;
  VGA_G = '0;
  VGA_B = '0;
  VGA_BLANK_N = '0;
  VGA_CLK = '0;
  VGA_HS = '0;
  VGA_SYNC_N = '0;
  VGA_VS = '0;
  AUD_DACDAT = '0;
  AUD_XCK = '0;
  EEP_I2C_SCLK = '0;
  I2C_SCLK = '0;
  ENET0_GTX_CLK = '0;
  ENET0_MDC = '0;
  ENET0_RST_N = '1; // DISABLE Ethernet Reset, see if it comes up on its own
  ENET0_TX_EN = '0;
  ENET0_TX_ER = '0;
  ENET0_TX_DATA = '0;
  // ENET1_TX_DATA = '0;
  // ENET1_GTX_CLK = '0;
  // ENET1_MDC = '0;
  // ENET1_RST_N = '0;
  // ENET1_TX_EN = '0;
  // ENET1_TX_ER = '0;
  OTG_ADDR = '0;
  OTG_CS_N = '0;
  OTG_RD_N = '0;
  OTG_RST_N = '0;
  OTG_WE_N = '0;
  DRAM_ADDR = '0;
  DRAM_BA = '0;
  DRAM_DQM = '0;
  DRAM_CAS_N = '0;
  DRAM_CKE = '0;
  DRAM_CLK = '0;
  DRAM_CS_N = '0;
  DRAM_RAS_N = '0;
  DRAM_WE_N = '0;
  SRAM_ADDR = '0;
  SRAM_CE_N = '0;
  SRAM_LB_N = '0;
  SRAM_OE_N = '0;
  SRAM_UB_N = '0;
  SRAM_WE_N = '0;
  FL_ADDR = '0;
  FL_CE_N = '0;
  FL_OE_N = '0;
  FL_RST_N = '0;
  FL_WE_N = '0;
  FL_WP_N = '0;
end

// Tristate unused inouts
always_comb begin
`ifdef IS_QUARTUS
  // For some reason, this makes Questa unhappy
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
  // ENET1_MDIO = 'z;
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
`endif
end

///////////////////////////////////////////////////////////////////////////////
// Use Ethernet Management Interface
// Read the output of register 0 after 3 seconds

// The internal wires for Management Interface
logic mdc, mdio_i, mdio_o, mdio_e;

// Status of I2C controller
logic mi_busy, mi_success;

// Should we do the activate thing
logic mi_activate = '0;

// Register IDs
localparam R_CONTROL = 5'd0,
           R_STATUS = 5'd1,
           R_PHY_ID_1 = 5'd2,
           R_PHY_ID_2 = 5'd3;

// What should we activate?
logic        mi_read = '1;
logic  [4:0] mi_phy_address = 5'b1_0001; // 10000 for ENET0, 10001 for ENET1
logic  [4:0] mi_register = R_STATUS;
logic [15:0] mi_data_in = '0;
logic [15:0] mi_data_out = '0;

// Set true if we ever saw busy from MI
logic ever_busy_mi = '0;

////////////////////////////////////////////////////////////////////////////////////

// Use an ALTIOBUF with open-drain set for MDIO.
// Datain means IN TO THE BUFFER, which would be OUT FROM THIS MODULE
// and hence OUT TO THE EXTERNAL PIN
ALTIOBUF ALTIOBUF_mdio ( // OPEN DRAIN!!!
	.dataio  (ENET1_MDIO),
	.oe      (mdio_e),
	.datain  (mdio_o),
	.dataout (mdio_i)
);

// Tie everything to ETH1 and our display
always_comb begin
  ENET1_MDC = mdc;
  ENET1_RST_N = KEY[3]; // Take chip out of reset (with logical 1)
  // ENET1_MDIO = mdio;

  // Show the results
  LEDR[15:0] = mi_data_in;
  LEDG[0] = mi_busy;
  LEDG[1] = mi_success;
  LEDG[2] = mi_activate;
  LEDG[3] = mdc;
  LEDG[4] = ever_busy_mi;
end

////////////////////////////////////////////////////////////////////////////////////


// Instantiate one MII Management Interface
mii_management_interface #(
  // Leave all parameters at default, usually
  .CLK_DIV(60)
) mii_management_interface1 (
  // Controller clock & reset
  .clk(CLOCK_50),
  .reset('0),

  // External management bus connections
  .mdc(mdc),
  .mdio_e(mdio_e), .mdio_i(mdio_i), .mdio_o(mdio_o),

  // Status
  .busy(mi_busy),
  .success(mi_success),

  // Management interface inputs
  .activate   (mi_activate),
  .read       (mi_read),
  .phy_address(mi_phy_address),
  .register   (mi_register),
  .data_out   (mi_data_out),
  .data_in    (mi_data_in)
);



// Read and display status when a button is pushed, for the specified
// register from switches 4:0.
// Note: "Each push-button switch provides a high logic level when it is not pressed,
//        and provides a low logic level when depressed."
logic [3:0] last_key = '1;
logic last_mi_busy = '0;

always_ff @(posedge CLOCK_50) begin
  last_key <= KEY;
  last_mi_busy <= mi_busy;

  // TODO: Handle reset

  if (!mi_busy && last_mi_busy) begin
    // We need to handle the completion of a command
    // Nothing really to do

  end else if (mi_busy && mi_activate) begin
    // Command just started
    mi_activate <= '0;
    ever_busy_mi <= '1;
  end else if (mi_busy) begin
    // The MI is busy, so track that it became busy
    ever_busy_mi <= '1;
  end else if (mi_activate) begin
    // Do nothing
  end else if (!mi_busy && !mi_activate && !KEY[0] && KEY[0] != last_key[0]) begin
    // We're not busy, not awaiting activation, and the key was just pressed
    // (remember key down reports logic 0)
    mi_activate <= '1;
    mi_register <= SW[4:0];
    ever_busy_mi <= '0;
  end

end



// ETHERNET TRANSMITTER TOP LEVEL /////////////////////////////////////////////

logic [3:0] tx_data_h, tx_data_l;
logic tx_ctl_h, tx_ctl_l;
logic gtx_clk, gtx_clk_90;
logic send_activate = '0;
logic send_busy;
logic pll_locked;

rgmii_tx rgmii_tx1 (
  .tx_clk(ENET1_RX_CLK),
  .reset('0),
  .ddr_tx('0),

  .activate(send_activate),
  .busy(send_busy),

  .gtx_clk(gtx_clk),
  .tx_data_h(tx_data_h),
  .tx_data_l(tx_data_l),
  .tx_ctl_h(tx_ctl_h),
  .tx_ctl_l(tx_ctl_l)
);

// Use a PLL to get a 90⁰ delayed version of the clock
pll_5mhz_90	pll_5mhz_90_inst (
  .areset('0),
	.inclk0(ENET1_RX_CLK),
	.c0(gtx_clk_90),
	.locked(pll_locked)
);

assign ENET1_TX_ER = '0;
assign ENET1_GTX_CLK = gtx_clk_90;
assign LEDG[7] = pll_locked;

// TODO: SET UP DDR OUTPUT PINS
ddr_output_4 ddr_output4_rgmii1_tx_data (
	.datain_h(tx_data_h),
	.datain_l(tx_data_l),
	.outclock(gtx_clk),
	.dataout (ENET1_TX_DATA)
);

ddr_output_1 ddr_output1_rgmii1_tx_ctl (
	.datain_h(tx_ctl_h),
	.datain_l(tx_ctl_l),
	.outclock(gtx_clk),
	.dataout(ENET1_TX_EN)
);

// Transmit when KEY[1] is pushed.
// Note: "Each push-button switch provides a high logic level when it is not pressed,
//        and provides a low logic level when depressed."
logic [3:0] last_key_tx = '1;
logic last_send_busy = '0;

always_ff @(posedge CLOCK_50) begin
  last_key_tx <= KEY;
  last_send_busy <= send_busy;

  // TODO: Handle reset

  if (!send_busy && last_send_busy) begin
    // We need to handle the completion of a send.
    // Nothing really to do

  end else if (send_busy && send_activate) begin
    // Transmit just started
    send_activate <= '0;
  end else if (send_busy) begin
    // The transmitter is busy, nothing to do
  end else if (send_activate) begin
    // Do nothing
  end else if (!send_busy && !send_activate && !KEY[1] && KEY[1] != last_key_tx[1]) begin
    // We're not busy, not awaiting activation, and the key was just pressed
    // (remember key down reports logic 0)
    send_activate <= '1;
  end

end




// LED BLINKER TOP LEVEL //////////////////////////////////////////////////////

logic [31:0] counter = '0;

always_ff @(posedge CLOCK_50) begin
  counter <= counter + 1'd1;
end

// Give a heartbeat
assign LEDG[8] = counter[26];

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
// `default_nettype none // This causes problems in Questa