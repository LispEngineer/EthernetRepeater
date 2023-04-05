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

  // Input from the Ethernet 25MHz crystal clock
  // Mapped as a Global Signal: Global Clock
  input  logic        ENETCLK_25,

  //////////// Ethernet 1 //////////
  output logic        ENET1_GTX_CLK,
  input  logic        ENET1_INT_N,
  input  logic        ENET1_LINK100,
  output logic        ENET1_MDC,
  inout  wire         ENET1_MDIO,
  output logic        ENET1_RST_N,
  // Mapped as a Global Signal: Global Clock
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
  // output logic        DVI_EDID_WP,
  // input  logic        DVI_RX_CLK,
  // input  logic  [3:1] DVI_RX_CTL,
  // input  logic [23:0] DVI_RX_D,
  // inout  wire         DVI_RX_DDCSCL,
  // inout  wire         DVI_RX_DDCSDA,
  // input  logic        DVI_RX_DE,
  // input  logic        DVI_RX_HS,
  // input  logic        DVI_RX_SCDT,
  // input  logic        DVI_RX_VS,
  // output logic        DVI_TX_CLK,
  // output logic  [3:1] DVI_TX_CTL,
  // output logic [23:0] DVI_TX_D,
  // inout  wire         DVI_TX_DDCSCL,
  // inout  wire         DVI_TX_DDCSDA,
  // output logic        DVI_TX_DE,
  // output logic        DVI_TX_DKEN,
  // output logic        DVI_TX_HS,
  // output logic        DVI_TX_HTPLG,
  // output logic        DVI_TX_ISEL,
  // output logic        DVI_TX_MSEN,
  // output logic        DVI_TX_PD_N,
  // output logic        DVI_TX_SCL,
  // inout  wire         DVI_TX_SDA,
  // output logic        DVI_TX_VS

	//////////// HSMC, HSMC connect to NET - Dual 10/100/1000 Ethernet //////////
  // FIXME: Set the default outputs on these
	output logic       NET2_GTX_CLK,
	input  logic       NET2_INTN,
	input  logic       NET2_LINK1000,
	output logic       NET2_MDC,
	inout  wire        NET2_MDIO,
	output logic       NET2_RESETN,
	input  logic       NET2_RX_CLK,
	input  logic       NET2_RX_COL,
	input  logic       NET2_RX_CRS,
	input  logic       NET2_RX_DV,
	input  logic       NET2_RX_ER,
	input  logic [7:0] NET2_RX_D,
	output logic [7:0] NET2_TX_D,
	input  logic       NET2_S_CLKN,
	input  logic       NET2_S_CLKP,
	input  logic       NET2_S_RX_N,
	input  logic       NET2_S_RX_P,
	output logic       NET2_S_TX_N,
	output logic       NET2_S_TX_P,
	input  logic       NET2_TX_CLK,
	output logic       NET2_TX_EN,
	output logic       NET2_TX_ER,
	output logic       NET3_GTX_CLK,
	input  logic       NET3_INTN,
	input  logic       NET3_LINK1000,
	output logic       NET3_MDC,
	inout  wire        NET3_MDIO,
	output logic       NET3_RESETN,
	input  logic       NET3_RX_CLK,
	input  logic       NET3_RX_COL,
	input  logic       NET3_RX_CRS,
	input  logic       NET3_RX_DV,
	input  logic       NET3_RX_ER,
	input  logic [7:0] NET3_RX_D,
	output logic [7:0] NET3_TX_D,
	input  logic       NET3_S_CLKN,
	input  logic       NET3_S_CLKP,
	input  logic       NET3_S_RX_N,
	input  logic       NET3_S_RX_P,
	output logic       NET3_S_TX_N,
	output logic       NET3_S_TX_P,
	input  logic       NET3_TX_CLK,
	output logic       NET3_TX_EN,
	output logic       NET3_TX_ER
);

// Zero out unused outputs
always_comb begin
  LEDG[6:5] = '0;
  LEDR[16] = '0;
  HEX0 = '1; // These LED segments are OFF when logic 1
  HEX1 = '1;
  HEX2 = '1;
  HEX3 = '1;
  HEX4 = '1;
  HEX5 = '1;
  HEX6 = '1;
  HEX7 = '1;
  // DVI_TX_CTL = '0;
  // DVI_TX_D = '0;
  // DVI_TX_CLK = '0;
  // DVI_TX_DE = '0;
  // DVI_TX_DKEN = '0;
  // DVI_TX_HS = '0;
  // DVI_TX_HTPLG = '0;
  // DVI_TX_ISEL = '0;
  // DVI_TX_MSEN = '0;
  // DVI_TX_PD_N = '0;
  // DVI_TX_SCL = '0;
  // DVI_TX_VS = '0;
  // DVI_EDID_WP = '0;
  LCD_BLON = '0; // Turn Backlight on? Shouldn't do anything
  // LCD_EN = '0;
  // LCD_RS = '0;
  // LCD_RW = '0;
  LCD_ON = '1; // Turn LCD on
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

	NET2_GTX_CLK = '0;
	NET2_MDC = '0;
	NET2_RESETN = '1; // Take it out of reset
	NET2_TX_D = '0;
	NET2_S_TX_N = '0;
	NET2_S_TX_P = '0;
	NET2_TX_EN = '0;
	NET2_TX_ER = '0;
	NET3_GTX_CLK = '0;
	NET3_MDC = '0;
	NET3_RESETN = '1; // Take it out of reset
	NET3_TX_D = '0;
	NET3_S_TX_N = '0;
	NET3_S_TX_P = '0;
	NET3_TX_EN = '0;
	NET3_TX_ER = '0;

end

// Tristate unused inouts
always_comb begin
`ifdef IS_QUARTUS
  // For some reason, this makes Questa unhappy
  EX_IO = 'z;
  // LCD_DATA = 'z;
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
  // DVI_RX_DDCSCL = 'z;
  // DVI_RX_DDCSDA = 'z;
  // DVI_TX_DDCSCL = 'z;
  // DVI_TX_DDCSDA = 'z;
  // DVI_TX_SDA = 'z;
  NET2_MDIO = 'z;
	NET3_MDIO = 'z;

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

// Let's generate our own 2.5MHz 10BASE-T clock
// with two outputs: one 12ns shifted and one 90⁰ phase shifted.
// Marvell 88E1111 section 4.10.2 (Rev. M) says the MII setup time
// for 10 Mbps is 10ns, and hold time is zero. Same for 100.
// For 1000, section 4.12.2.1 says setup time is 1ns and hold is 0.8ns.
//
// At startup, Register 20.1 is 0 (no delay for TXD outputs)
// and Register 20.7 is 0 (no added delay for RX_CLK)

logic clock_eth_tx, clock_eth_tx_shifted, clock_eth_tx_shifted2, clock_eth_tx_lock;

`define SPEED_1000

`ifdef SPEED_10
`define USE_DDR 1'b0
pll_50_to_2p5_with_shift	pll_50_to_2p5_with_shift_inst (
	.areset('0),
	.inclk0(CLOCK_50),
	.c0(clock_eth_tx),
	.c1(clock_eth_tx_shifted), // 12ns shift
	.c2(clock_eth_tx_shifted2), // 90 degree shift
	.locked(clock_eth_tx_lock)
);

`elsif SPEED_100

`define USE_DDR 1'b0
// FIXME: Make this a 10ns shift
pll_50_to_25_with_shift	pll_50_to_25_with_shift_inst (
	.areset('0),
	.inclk0(CLOCK_50),
	.c0(clock_eth_tx),
	.c1(clock_eth_tx_shifted), // 12ns shift
	.c2(clock_eth_tx_shifted2), // 90 degree shift
	.locked(clock_eth_tx_lock)
);

`elsif SPEED_1000

`define USE_DDR 1'b1
pll_50_to_125_with_shift	pll_50_to_125_with_shift_inst (
	.areset('0),
	.inclk0(CLOCK_50),
	.c0(clock_eth_tx),
	.c1(clock_eth_tx_shifted2), // 2ns shift
	.c2(clock_eth_tx_shifted), // 90 degree shift - should ALSO be 2ns
	.locked(clock_eth_tx_lock)
);

`endif

// Use a PLL to get a 90⁰ delayed version of the RX clock
// which in practice works at 2.5 MHz input even though the
// minimum input to the PLL is 5 MHz
/*
logic pll_locked, gtx_clk_90;

pll_5mhz_90	pll_5mhz_90_inst (
  .areset('0),
	.inclk0(ENET1_RX_CLK),
	.c0(gtx_clk_90),
	.locked(pll_locked)
);
*/

logic [3:0] tx_data_h, tx_data_l;
logic tx_ctl_h, tx_ctl_l;
logic gtx_clk;
logic send_activate = '0;
logic send_busy;

// This will only work with 10BASE-T now, since the
// clock speed doesn't change to adjust with the ENET1_RX_CLK.
rgmii_tx rgmii_tx1 (
  .tx_clk(clock_eth_tx),
  .reset('0),
  .ddr_tx(`USE_DDR), // 0 for 10/100, 1 for 1000

  .activate(send_activate),
  .busy(send_busy),

  .gtx_clk(gtx_clk), // Should be the same as tx_clk input above
  .tx_data_h(tx_data_h),
  .tx_data_l(tx_data_l),
  .tx_ctl_h(tx_ctl_h),
  .tx_ctl_l(tx_ctl_l),

  // Debug ports
  .crc_out()
);

assign ENET1_TX_ER = '0;
// For 10/100 use a 12ns shifted clock. (10 would be better for 100)
// For 1000, use 1 2ns shifted clock (90⁰ shift for 125 MHz)
assign ENET1_GTX_CLK = clock_eth_tx_shifted;
assign LEDG[7] = clock_eth_tx_lock; // pll_locked;

// Set up our DDR output pins for RGMII transmit
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


// LCD DRIVER TOP LEVEL ///////////////////////////////////////////////////////

// Wait at least 20ms before using the LCD
logic [31:0] lcd_power_on = '0;
logic lcd_available = '0;

logic [7:0] lcd_data_o, lcd_data_i;
logic lcd_data_e;
logic lcd_busy;

// Wait 20ms before we enable our LCD
always_ff @(posedge CLOCK_50) begin
  if (!lcd_available) begin
    if (lcd_power_on == 32'd100_000_000) begin // FIXME: Make localparam
      lcd_available <= '1;
    end else begin
      lcd_power_on <= lcd_power_on + 1'd1;
    end
  end // lcd_available
end

// FIXME: We probably have to do a full manual initialization of
// the LCD module before we can write characters.
// We will have to write a driver that does the initialization,
// then passes through the rest of the commands.

logic lcd_activate = '0;
logic char_activate = '0;
logic [4:0] char_loc = '1; // Top bit = row 1 or 2, bottom = col

lcd_module lcd_module (
  .clk(CLOCK_50),
  .reset('0),

  // Interface to physical LCD module
  .data_o(lcd_data_o),
  .data_i(lcd_data_i),
  .data_e(lcd_data_e),
  .rs(LCD_RS),
  .rw(LCD_RW),
  .en(LCD_EN),

  // Low level interface to this module
  .busy(lcd_busy),
  .activate(lcd_activate),
  .is_data('1), // Send an H in
  .data_inst(SW[17:10]), // Change the letter being sent
  .delay('0), // Default delay

  // Character interface
  .char_activate(char_activate),
  .move_row(char_loc[4]),
  .move_col(char_loc[3:0])
);

assign LEDR[17] = lcd_busy;

genvar i;
generate
  for (i = 0; i < 8; i = i + 1) begin: lcd_output_generator
    ALTIOBUF_LCD ALTIOBUF_lcd_i (
      .dataio  (LCD_DATA[i]),
      .oe      (lcd_data_e),
      .datain  (lcd_data_o[i]),
      .dataout (lcd_data_i[i])
    );
  end
endgenerate

logic last_lcd_busy = '0;
logic [3:0] last_key_lcd = '0;

// Prove we can send data to the module one letter at a time.
always_ff @(posedge CLOCK_50) begin
  last_key_lcd <= KEY;
  last_lcd_busy <= lcd_busy;

  // TODO: Handle reset

  if (!lcd_busy && last_lcd_busy) begin
    // We need to handle the completion of an activation.
    // Nothing really to do

  end else if (lcd_busy && (lcd_activate || char_activate)) begin
    // Command just started
    lcd_activate <= '0;
    char_activate <= '0;
  end else if (lcd_busy) begin
    // The LCD module is busy, nothing to do
  end else if (lcd_activate) begin
    // Do nothing
  end else if (!lcd_busy && !char_activate && !KEY[2] && KEY[2] != last_key_lcd[2]) begin
    // We're not busy, not awaiting activation, and the key was just pressed
    // (remember key down reports logic 0)
    char_activate <= '1;
    char_loc <= char_loc + 1'd1;
  end
end // Activate LCD module
// TODO: Make the above a module with inputs:
//   activate request (the key) - only activated from 0 to 1 edge
//   busy status
// Outputs:
//   actual activate
//   and its deactivation
// Parameters:
//   activate only if not busy currently
//     or activate when not busy



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