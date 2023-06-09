// Ethernet Repeater
// Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved
// symbolics@lisp.engineer

// Empty top-level originally built by Terasic System Builder

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL input  logic 
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


module EthernetRepeater (

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
  // inout  wire  [35:0] GPIO,
  input  logic [35:0] GPIO,

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
  // LEDG[5] = '0;
  // LEDR[16] = '0;
  /*
  HEX0 = '1; // These LED segments are OFF when logic 1
  HEX1 = '1;
  HEX2 = '1;
  HEX3 = '1;
  HEX4 = '1;
  HEX5 = '1;
  HEX6 = '1;
  HEX7 = '1;
  */
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
  // GPIO = 'z;
  // DVI_RX_DDCSCL = 'z;
  // DVI_RX_DDCSDA = 'z;
  // DVI_TX_DDCSCL = 'z;
  // DVI_TX_DDCSDA = 'z;
  // DVI_TX_SDA = 'z;
  NET2_MDIO = 'z;
	NET3_MDIO = 'z;

`endif
end

////////////////////////////////////////////////////////////////////////////////
// Adafruit 1332 4-button keypad
// These are dumb, non-debounced buttons
// Plug these into the left side of GPIO, starting at 6th pin from bottom for power,
// and then going up it uses GPIO24, 22, 20, 18 for buttons 2, 1, 4, 3
//
// https://learn.adafruit.com/matrix-keypad/pinouts
// Did not get this working

/*
logic [3:0] BTN_RAW;
assign BTN_RAW[0] = GPIO[22];
assign BTN_RAW[1] = GPIO[24];
assign BTN_RAW[2] = GPIO[18];
assign BTN_RAW[3] = GPIO[20];

assign LEDG[5] = BTN_RAW[0];
*/

////////////////////////////////////////////////////////////////////////////////
// 7 Segment logic

logic [6:0] ihex0 = '0;
logic [6:0] ihex1 = '0;
logic [6:0] ihex2 = '0;
logic [6:0] ihex3 = '0;
logic [6:0] ihex4 = '0;
logic [6:0] ihex5 = '0;
logic [6:0] ihex6 = '0;
logic [6:0] ihex7 = '0;

logic [31:0] hex_display;

assign HEX0 = ~ihex0;
assign HEX1 = ~ihex1;
assign HEX2 = ~ihex2;
assign HEX3 = ~ihex3;
assign HEX4 = ~ihex4;
assign HEX5 = ~ihex5;
assign HEX6 = ~ihex6;
assign HEX7 = ~ihex7;

// Show the saved data on hex 0-3
seven_segment sshex0 (.num(hex_display[3:0]),   .hex(ihex0));
seven_segment sshex1 (.num(hex_display[7:4]),   .hex(ihex1));
seven_segment sshex2 (.num(hex_display[11:8]),  .hex(ihex2));
seven_segment sshex3 (.num(hex_display[15:12]), .hex(ihex3));
seven_segment sshex4 (.num(hex_display[19:16]), .hex(ihex4));
seven_segment sshex5 (.num(hex_display[23:20]), .hex(ihex5));
seven_segment sshex6 (.num(hex_display[27:24]), .hex(ihex6));
seven_segment sshex7 (.num(hex_display[31:28]), .hex(ihex7));

///////////////////////////////////////////////////////////////////////////////
// Ethernet Management Interface
// Read the output of register 0 after 3 seconds

localparam ENET1_PHY_ADDRESS = 5'b1_0001; // 10000 for ENET0, 10001 for ENET1

// The internal wires for Management Interface
logic mdc, mdio_i, mdio_o, mdio_e;

// Status of I2C controller
logic mi_busy, mi_success;

// Should we do the activate thing
logic mi_activate = '0;

// What should we activate?
logic        mi_read = '1;
logic  [4:0] mi_register = '0;
logic [15:0] mi_data_in = '0;
logic [15:0] mi_data_out = '0;
logic enet1_reset;

//////////////

// Use an ALTIOBUF with open-drain set for MDIO.
// Datain means IN TO THE BUFFER, which would be OUT FROM THIS MODULE
// and hence OUT TO THE EXTERNAL PIN
ALTIOBUF ALTIOBUF_mdio ( // OPEN DRAIN!!!
	.dataio  (ENET1_MDIO),
	.oe      (mdio_e),
	.datain  (mdio_o),
	.dataout (mdio_i)
);

// What's the difference between always and assign?

assign ENET1_MDC = mdc;
assign ENET1_RST_N = ~enet1_reset;

logic ep1_config_error;
logic ep1_configured; // Has the PHY been configured? If so, we can enable TX and RX
logic [5:0] ep1_state;
logic [15:0] ep1_seen_states;
logic [15:0] ep1_reg0;
logic [15:0] ep1_reg20;
logic [15:0] ep1_soft_reset_checks;

// Output some internals
// assign LEDG[5] = ep1_config_error;
assign LEDG[6] = ep1_configured;
// assign hex_display[23:16] = ep1_soft_reset_checks; // ep1_reg20[7:0]; // Expect E2 in reg20
// assign LEDR[15:0] = ep1_seen_states;
// Show the results from an MII read
always LEDR[15:0] = mi_data_in;


// BUTTON 0 ////////////////////////////////////////

// Show the stored register ID in Hex 7-6
assign hex_display[31:24] = mi_register;
// assign hex_display[15:0] = mi_data_in; // Data read in from ETH PHY

// Note: "Each push-button switch provides a HIGH logic level when it is not pressed,
//        and provides a low logic level when depressed."
logic [3:0] last_key = '1;
logic last_mi_busy = '0;


// Read stored register on button 1
always_ff @(posedge CLOCK_50) begin
  last_key <= KEY;

  // TODO: Handle reset

  if (!mi_busy && last_mi_busy) begin
    // We need to handle the completion of a command
    // Nothing really to do

  end else if (mi_busy && mi_activate) begin
    // Command just started
    mi_activate <= '0;
  end else if (mi_busy) begin
    // The MI is busy
  end else if (mi_activate) begin
    // Do nothing
  end else if (!mi_busy && !mi_activate && !KEY[0] && KEY[0] != last_key[0]) begin
    // We're not busy, not awaiting activation, and the key was just pressed
    // (remember key down reports logic 0)
    // Save the switches into our saved register
    mi_register <= SW[4:0];
  end else if (!mi_busy && !mi_activate && !KEY[1] && KEY[1] != last_key[1]) begin
    // Activate a read
    mi_activate <= '1;
    mi_read <= '1;
    // mi_register is already set
  end 
/*  
  // This uses KEY[2] too to write data from the switches
  else if (!mi_busy && !mi_activate && !KEY[2] && KEY[2] != last_key[2]) begin
    // Activate a write
    mi_activate <= '1;
    mi_read <= '0;
    mi_data_out <= SW[15:0];
    // mi_register is already set
  end
*/

end // MDIO Button Handler



// ETHERNET TRANSMITTER TOP LEVEL /////////////////////////////////////////////

logic clock_eth_tx, clock_eth_tx_lock;
logic clk_eth_125, clk_eth_25, clk_eth_2p5;

logic [3:0] tx_data_h, tx_data_l;
logic tx_ctl_h, tx_ctl_l;
logic gtx_clk;
logic send_busy;

assign ENET1_TX_ER = '0; // Not used in RGMII
assign ENET1_GTX_CLK = gtx_clk;
assign LEDG[7] = clock_eth_tx_lock; // pll_locked;

// If you mess up the transmit clock multiplexer or selector, then this error:
// Critical Warning (15090): Changed operation mode of PLL (this one) to No Compensation
// could pop up, giving you a clue that it's broken. :)
pll_50_to_all_eth_single_input	pll_50_to_all_eth_single_input_inst (
	.inclk0 ( CLOCK_50 ),
	.c0 ( clk_eth_125 ), // 125 MHz
	.c1 ( clk_eth_25 ), // 25 MHz
	.c2 ( clk_eth_2p5 ), // 2.5 MHz
	.locked (clock_eth_tx_lock),
	.areset ( '0 ) // FIXME: Add PLL reset
);

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

// Transmit when KEY[2] is pushed.
// Note: "Each push-button switch provides a high logic level when it is not pressed,
//        and provides a low logic level when depressed."
logic [3:0] last_key_tx = '1;
logic last_send_busy = '0;

// TX RAM
logic        tx_ram_wr_ena;
logic [13:0] tx_ram_wr_addr;
logic  [7:0] tx_ram_wr_data;

// TX FIFO
logic        tx_fifo_wr_full;
logic        tx_fifo_wr_req = '0;
logic [13:0] tx_fifo_wr_data;

`ifdef TRANSMIT_ON_KEY_2
always_ff @(posedge CLOCK_50) begin: request_packet_send
  last_key_tx <= KEY;
  last_send_busy <= send_busy;

  // TODO: Handle reset

  // Our FIFO needs exactly one cycle to take a value in,
  // so set the _wr_req only for one cycle exactly.
  // send_busy will be asserted a few cycles later (probably),
  // and it's asynchronous to this clock anyway so should be
  // synchronized... (FIXME)

  tx_fifo_wr_req <= '0; // We are not activating, UNLESS...
  if (!send_busy && last_send_busy) begin
    // We need to handle the completion of a send.
    // Nothing really to do
  end else if (send_busy && tx_fifo_wr_req) begin
    // Transmit just started
  end else if (send_busy) begin
    // The transmitter is busy, nothing to do
  end else if (tx_fifo_wr_req) begin
    // Do nothing
  end else if (!send_busy && !tx_fifo_wr_req && !KEY[2] && KEY[2] != last_key_tx[2]) begin
    // We're not busy, not awaiting activation, and the key was just pressed
    // (remember key down reports logic 0)
    if (!tx_fifo_wr_full) begin: push_into_tx_fifo
      tx_fifo_wr_req <= '1;
      tx_fifo_wr_data <= {send_buf, 11'd60}; // Buffer (3 bits) length (11 bits)
      send_buf[0] <= ~send_buf[0]; // Next time send the other buffer
    end: push_into_tx_fifo

  end

end: request_packet_send
`endif // TRANSMIT_ON_KEY_2


// ETHERNET RECEIVER TOP LEVEL ////////////////////////////////////////////////

// Wait at least 2s before using the LCD for it to power up
localparam LCD_POWER_ON_WAIT = 32'd100_000_000;
logic [31:0] lcd_power_on = '0;
logic lcd_available = '0;

// Wait 20ms before we enable our LCD
always_ff @(posedge CLOCK_50) begin
  // FIXME: Add a reset
  if (!lcd_available) begin
    if (lcd_power_on == LCD_POWER_ON_WAIT) begin
      lcd_available <= '1;
    end else begin
      lcd_power_on <= lcd_power_on + 1'd1;
    end
  end // lcd_available
end

// 1. Listen for RX FIFO not empty
// 2. When it gets a FIFO entry, output the Ethernet packet payload to LCD
//    (everything after the Ethernet header - 2x MAC & EtherType)

// FIFO
logic fifo_rd_empty;
logic fifo_rd_req = '0;
logic [15:0] fifo_rd_data; // Output from FIFO
logic [15:0] stored_fifo_data; // Safely stored data from FIFO for reuse
// Break out the FIFO data
logic fifo_crc_error, fifo_frame_error; // READ ONLY
logic [2:0] fifo_buf_num; // READ ONLY
logic [10:0] fifo_pkt_len; // READ ONLY
assign {fifo_crc_error, fifo_frame_error, fifo_buf_num, fifo_pkt_len} = stored_fifo_data;

localparam FIFO_LATENCY = 4'd2; // FIFO read latency
logic [3:0] fifo_latency_count;


// Receiver RAM buffer
logic ram_rd_ena;
logic [13:0] ram_rd_addr;
logic [7:0] ram_rd_data; // READ ONLY

`ifdef WRITE_PACKETS_TO_LCD
// Break out the RAM address into a buffer # and byte position
logic [2:0] ram_read_buf;
logic [10:0] ram_read_pos; // 2k max packet size - 11 bits
assign ram_rd_addr = {ram_read_buf, ram_read_pos};
`endif // WRITE_PACKETS_TO_LCD

// We will skip reading the preamble, SFD, and Ethernet header.
// NOTE: Revised operation does not save preamble/SFD in RAM.
localparam RAM_READ_START = 11'd6 + 11'd6 + 11'd2; // 2x MAC, EtherType/Length
logic [10:0] ram_read_last; // Last ram_read_pos to process before ending

// Match this to the setting in rgmii_rx.sv: USE_REGISTERED_OUTPUT_RAM
// USE_REGISTERED_OUTPUT_RAM = 4'd2
// Otherwise = 4'd1
localparam RAM_READ_LATENCY = 4'd2;
logic [3:0] ram_read_latency_count;

// Which byte should we display? (Retrieved from Eth RX RAM earlier)
logic [7:0] byte_to_display; 

// PHY Status
logic link_up, full_duplex, speed_10, speed_100, speed_1000;
// PHY Debugging
logic in_band_differ;
logic [3:0] in_band_h;
logic [3:0] in_band_l;
// PHY RX counters
logic [31:0] count_interframe;
logic [31:0] count_reception;
logic [31:0] count_receive_err;
logic [31:0] count_carrier;
logic [31:0] count_interframe_differ;
logic [31:0] count_rcv_end_normal;
logic [31:0] count_rcv_end_carrier;
logic [31:0] count_rcv_errors;
logic [31:0] count_rcv_dropped_packets;

assign LEDG[5:0] = {in_band_differ, speed_1000, speed_100, speed_10, full_duplex, link_up};
// 31-24 is the register, so display counts on the other 3 pairs
// assign hex_display[23:16] = count_reception[7:0];
// assign hex_display [15:8] = count_interframe[7:0]; // count_reception[7:0];
// assign hex_display  [7:0] = count_interframe_differ[7:0];
// assign hex_display  [7:0] = {in_band_h, in_band_l};
// assign hex_display[23:16] = count_rcv_end_carrier[7:0]; // Getting a lot of these
// assign hex_display [15:8] = count_rcv_errors[7:0]; // And none of these
// assign hex_display  [7:0] = count_rcv_end_normal[7:0]; // And none of these
assign hex_display[15:0] = stored_fifo_data;

// DDR inputs
logic rx_ctl_l, rx_ctl_h;
logic [3:0] rx_data_l;
logic [3:0] rx_data_h;


`ifdef USE_DDR_WITH_RESYNCHRONIZING

// Each cycle, on the `inclock`, we get the
// CURRENT value of the _h
// PREVIOUS value of the _l
// So if we want to get a full high/low cycle,
// we need to use the previous value of _h, which
// adds a single cycle of latency.
logic rx_ctl_h_next;
logic [3:0] rx_data_h_next;

ddr_input_1	ddr_input_1_inst (
	.inclock   (ENET1_RX_CLK),
	.datain    (ENET1_RX_DV),
	.dataout_h (rx_ctl_h_next),
	.dataout_l (rx_ctl_l)
);
ddr_input_4	ddr_input_4_inst (
	.inclock   (ENET1_RX_CLK),
	.datain    (ENET1_RX_DATA),
	.dataout_h (rx_data_h_next),
	.dataout_l (rx_data_l)
);

// Align the _l with its original _h
// See Cyclone IV Handbook, Volume 1, Chapter 7, Figure 7-7
// on the DDR Input Register.
// FIXME: Put this into its own ddr_input_aligned module with
// the ALTDDIO_IN
always_ff @(posedge ENET1_RX_CLK) begin: ddr_input_resynchronize
  rx_data_h <= rx_data_h_next;
  rx_ctl_h <= rx_ctl_h_next;
end: ddr_input_resynchronize

`else // Don't use DDR with resynchronizing - use clock inversion

// If we invert the clock, we can get the old high and new low
// at the next high, and not have to do the trick with the
// cycle delay, saving a cycle. Let's try that.
ddr_input_5_inverted	ddr_input_5_inverted_inst (
	.inclock   (ENET1_RX_CLK),
	.datain    ({ENET1_RX_DV, ENET1_RX_DATA}),
	.dataout_h ({rx_ctl_l, rx_data_l}),
	.dataout_l ({rx_ctl_h, rx_data_h})
);

`endif // USE_DDR_WITH_RESYNCHRONIZING


/////////////////////////////////////////////////////////////
// Ethernet RGMII PHY Interface - RX, TX, MII

// Transmit FIFO
logic [2:0] tx_fifo_buf_num;
logic [10:0] tx_fifo_len;
// Break out the tx_fifo_wr_data
assign tx_fifo_wr_data = {tx_fifo_buf_num, tx_fifo_len};

ethernet_trx_88e1111 #(
  // Leave most parameters at default
  .MII_PHY_ADDRESS(ENET1_PHY_ADDRESS)
) enet1_mac (
  // Clocks //
  .clk    (CLOCK_50),
  .clk_125(clk_eth_125),
  .clk_25 (clk_eth_25),
  .clk_2p5(clk_eth_2p5),
  .reset  (~KEY[3]),

  // Receiver //

  // PHY signals
  .clk_rx(ENET1_RX_CLK),
  .rx_ctl_h,
  .rx_ctl_l,
  .rx_data_h,
  .rx_data_l,

  // link status
  .link_up,
  .full_duplex,
  .speed_1000,
  .speed_100,
  .speed_10,

  // Debugging
  .in_band_differ,
  .in_band_h,
  .in_band_l,

  // RX counters
  .count_interframe,
  .count_reception,
  .count_receive_err,
  .count_carrier,
  .count_interframe_differ,
  .count_rcv_end_normal,
  .count_rcv_end_carrier,
  .count_rcv_errors,
  .count_rcv_dropped_packets,

  // RX packet buffer
  .clk_rx_ram_rd(CLOCK_50),
  .rx_ram_rd_ena(ram_rd_ena),
  .rx_ram_rd_addr(ram_rd_addr),
  .rx_ram_rd_data(ram_rd_data),

  // RX FIFO
  .clk_rx_fifo_rd(CLOCK_50),
  .rx_fifo_rd_empty(fifo_rd_empty),
  .rx_fifo_rd_req(fifo_rd_req),
  .rx_fifo_rd_data(fifo_rd_data),

  // Transmitter

  // TX PHY signals (DDR)
  .clk_gtx(gtx_clk), // Will be one of the 3 clocks above
  .tx_data_h,
  .tx_data_l,
  .tx_ctl_h,
  .tx_ctl_l,

  // TX status
  .tx_busy(send_busy),

  // TX RAM & FIFO
  .clk_tx_ram_wr(CLOCK_50),
  .tx_ram_wr_ena,
  .tx_ram_wr_addr,
  .tx_ram_wr_data,
  .clk_tx_fifo_wr(CLOCK_50),
  .tx_fifo_aclr('0), // We never clear
  .tx_fifo_wr_full,
  .tx_fifo_wr_req,
  .tx_fifo_wr_data,


  // TX debug signals
  .tx_crc_out(), // NOT connected

  // Management interface

  // PHY control signals
  .mdio_i,
  .mdio_o,
  .mdio_e,
  .mdc,
  .phy_reset(enet1_reset),

  // Controller status
  .mii_busy   (mi_busy),
  .mii_success(mi_success),
  .phy_configured  (ep1_configured),
  .phy_config_error(ep1_config_error),

  // Controller signals
  .mii_activate(mi_activate),
  .mii_read    (mi_read),
  .mii_register(mi_register),
  .mii_data_out(mi_data_out),
  .mii_data_in (mi_data_in),

  // MII Debug
  .d_state(ep1_state),
  .d_reg0(ep1_reg0),
  .d_reg20(ep1_reg20),
  .d_seen_states(ep1_seen_states),
  .d_soft_reset_checks(ep1_soft_reset_checks)
);


// Instantiate our LCD and necessary signals
logic char_activate = '0;
logic lcd_busy;

// LCD PHY signals
logic [7:0] lcd_data_o, lcd_data_i;
logic lcd_data_e;

// Where we want to draw a character
logic [4:0] lcd_pos;


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

  .busy(lcd_busy),

  // Low level interface to this module - unused
  .activate('0), // Never use the low-level input
  .is_data('1),
  .delay('0), // Default delay

  // Character interface (which we use)
  .char_activate(char_activate),
  .move_row(lcd_pos[4]),
  .move_col(lcd_pos[3:0]),
  .data_inst(byte_to_display)
);

// Show a sign when our LCD is busy
assign LEDR[17] = lcd_busy;
assign LEDR[16] = lcd_available;

// Create our bidi I/O buffers for the LCD data lines
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


// Memory Copier signals
logic rxtx_copy_busy;
logic rxtx_copy_activate = '0;
logic [13:0] rxtx_copy_src_addr;
logic [13:0] rxtx_copy_dst_addr;
logic [13:0] rxtx_copy_len;

// Memory copier instance from receive buffer to transmit buffer
memcopy /* #(
  parameter MEM_WIDTH = 8,
  parameter SRC_ADDR_SZ = 14,
  parameter DST_ADDR_SZ = 14,
  parameter SRC_LATENCY = 2
) */ receive_to_transmit_copier (
  .clk(CLOCK_50),
  .reset(~KEY[3]),

  .busy(rxtx_copy_busy),

  .activate(rxtx_copy_activate),
  .src_addr(rxtx_copy_src_addr),
  .dst_addr(rxtx_copy_dst_addr),
  .src_len(rxtx_copy_len),

  // Source RAM reader interface
  .clk_ram_rd(), // Already connected to CLOCK_50 elsewhere
  .ram_rd_ena(ram_rd_ena), // Eth RX RAM
  .ram_rd_addr(ram_rd_addr),
  .ram_rd_data(ram_rd_data),

  // Destination RAM writer interface
  .clk_ram_wr(), // Already connected to CLOCK_50 elsewhere
  .ram_wr_ena(tx_ram_wr_ena),
  .ram_wr_addr(tx_ram_wr_addr),
  .ram_wr_data(tx_ram_wr_data)
);




// State machine for reading FIFO and going to display memory
typedef enum int unsigned { 
  S_ERX_AWAIT_FIFO = 0,
  S_ERX_GET_FIFO = 1,
  S_ERX_START_READING = 2,
  S_ERX_READ_BYTE = 3,
  S_ERX_READ_LATENCY = 4,
  S_ERX_SAVE_BYTE = 5,
  S_ERX_WRITE_SCREEN = 6,
  S_ERX_AWAIT_SCREEN = 7,
  S_ERX_START_RAM_COPY = 8,
  S_ERX_AWAIT_RAM_COPY = 9,
  S_ERX_QUEUE_SEND = 10
} erx_state_t;
erx_state_t erx_state = S_ERX_AWAIT_FIFO;

logic [7:0] packets_received = '0;

// Display internal info on our hex display
/*
assign hex_display[3:0] = {1'b0, erx_state};
assign hex_display[7:4] = fifo_rd_empty ? '0 : 4'd1;
assign hex_display[31:24] = packets_received;
assign hex_display[23:16] = byte_to_display;
assign hex_display[15:8] = fifo_buf_num;
*/

logic [2:0] send_buf = '0;
logic copy_was_busy;

assign hex_display[23:16] = send_buf;


`ifdef WRITE_PACKETS_TO_LCD

always_ff @(posedge CLOCK_50) begin: lcd_writer_state_machine
  
  if (!lcd_available) begin

    // FIXME: CODE A RESET

  end else begin

    case (erx_state)

    S_ERX_AWAIT_FIFO: begin //////////////////////////////////////////
      // Wait for the fifo to be non-empty
      if (!fifo_rd_empty) begin
        fifo_rd_req <= '1;
        erx_state <= S_ERX_GET_FIFO;
        // Takes a while to read the data from FIFO - some latency
        fifo_latency_count <= FIFO_LATENCY - 1'd1;

        packets_received <= packets_received + 1'd1;
      end
  
    end

    S_ERX_GET_FIFO: begin //////////////////////////////////////////
      // Save the data from the FIFO once our read latency is over
      fifo_rd_req <= '0;
      if (fifo_latency_count == 0) begin
        stored_fifo_data <= fifo_rd_data;
        erx_state <= S_ERX_START_READING;
      end else begin
        fifo_latency_count <= fifo_latency_count - 1'd1;
      end
    end

    S_ERX_START_READING: begin /////////////////////////////////////////
      // Prepare the RAM reading, and then start the read next cycle
      ram_read_pos <= RAM_READ_START; // Skip reading header stuff, direct to Eth payload

      // Calculate the last byte we want to read. For now, just ignore
      // the packet length and just always pick 32 bytes (the size of
      // the LCD). Since Eth data must always be > 32, this is fine.
      ram_read_last <= RAM_READ_START + 11'd31; // Really, + 32 - 1
      // Test: Just do 5 bytes
      // ram_read_last <= RAM_READ_START + 11'd4;
      // Test: Just do the one byte!
      // ram_read_last <= RAM_READ_START;

      // Read the proper location (this and ram_read_pos make the final RAM address)
      // THis does not change for the whole packet read.
      ram_read_buf <= fifo_buf_num; // broken out from stored_fifo_data

      // Which position in the LCD are we writing to?
      lcd_pos <= '0;

      erx_state <= S_ERX_READ_BYTE;
    end

    S_ERX_READ_BYTE: begin //////////////////////////////////////////
      // Okay, now we have to set up reading all the data from
      // the appropriate RAM buffer specified in the FIFO saved data
      // and dump it to the LCD, one character at a time.

      // Enable reads from RAM
      ram_rd_ena <= '1;

      // If latency is 0, then we need to do skip the latency step.
      // (Latency zero means we can get the byte next cycle, which
      // COULD be possible if we had asynchronous SRAM.)
      if (RAM_READ_LATENCY == '0) begin
        erx_state <= S_ERX_SAVE_BYTE;
      end else begin
        erx_state <= S_ERX_READ_LATENCY;
        ram_read_latency_count <= RAM_READ_LATENCY - 1'd1;
      end
    end

    S_ERX_READ_LATENCY: begin //////////////////////////////////////////
      // Add necessary latency before reading the output of the RAM
      ram_rd_ena <= '0;
      if (ram_read_latency_count == '0) begin
        erx_state <= S_ERX_SAVE_BYTE;
      end else begin
        ram_read_latency_count <= ram_read_latency_count - 1'd1;
      end
    end

    S_ERX_SAVE_BYTE: begin ////////////////////////////////////////////
      // Read latency is over, we should have the byte ready now.
      // Save it and begin processing next state. (Okay, we could
      // technically combine those states, but whatever.)
      ram_rd_ena <= '0; // In case we are in 1-cycle latency RAM

      // Just display the lower nibble
      /*
      if (ram_rd_data[3:0] < 4'd10)
        byte_to_display <= {4'h3, ram_rd_data[3:0]}; // 0-9
      else
        byte_to_display <= 8'h41 - 4'd10 + ram_rd_data[3:0]; // A-F
      */

      // Display the whole byte as ASCII
      byte_to_display <= ram_rd_data;

      // Testing if our nibbles are saved backwards
      // {ram_rd_data[3:0],ram_rd_data[7:4]};
      erx_state <= S_ERX_AWAIT_SCREEN;
    end

    S_ERX_AWAIT_SCREEN: begin //////////////////////////////////////////
      // We got our byte to write. Wait for screen to be ready, then
      // submit our request to write the byte.
      if (!lcd_busy) begin
        erx_state <= S_ERX_WRITE_SCREEN;
        char_activate <= '1;
        // byte_to_display and lcd_pos should already be ready
      end
    end

    S_ERX_WRITE_SCREEN: begin //////////////////////////////////////////
      // Disable our write once the screen takes up the
      // activation flag.
      if (lcd_busy) begin
        char_activate <= '0;
        
        // Check if we're done
        if (ram_read_pos == ram_read_last) begin
          // We displayed the whole packet (well, 32 bytes of it)
          erx_state <= S_ERX_AWAIT_FIFO;
        end else begin
          // We have to read our next character
          erx_state <= S_ERX_READ_BYTE;
          lcd_pos <= lcd_pos + 1'd1;
          ram_read_pos <= ram_read_pos + 1'd1;
        end
      end
    end

    default: erx_state <= S_ERX_AWAIT_FIFO;
    endcase

  end

end: lcd_writer_state_machine


`else // copy packets, don't write to LCD //////////////////////////////////////////////////////////////////////



always_ff @(posedge CLOCK_50) begin: retransmit_received_packets
  
  if (!lcd_available) begin

    // FIXME: CODE A RESET

  end else begin

    case (erx_state)

    S_ERX_AWAIT_FIFO: begin //////////////////////////////////////////

      tx_fifo_wr_req <= '0;

      // Wait for the fifo to be non-empty
      if (!fifo_rd_empty) begin
        fifo_rd_req <= '1;
        erx_state <= S_ERX_GET_FIFO;
        // Takes a while to read the data from FIFO - some latency
        fifo_latency_count <= FIFO_LATENCY - 1'd1;

        packets_received <= packets_received + 1'd1;
      end
  
    end

    S_ERX_GET_FIFO: begin //////////////////////////////////////////
      // Save the data from the FIFO once our read latency is over
      fifo_rd_req <= '0;
      if (fifo_latency_count == 0) begin
        stored_fifo_data <= fifo_rd_data;
        erx_state <= S_ERX_START_RAM_COPY;
      end else begin
        fifo_latency_count <= fifo_latency_count - 1'd1;
      end
    end

    S_ERX_START_RAM_COPY: begin: start_ram_copy ////////////////////////////////////////
      // We need to copy our packet from the receive buffer to the transmit buffer.
      // If we used a different speed clock for our memory copier, we would need to:
      // 1. Set our input address and make sure they are stable for enough cycles
      // 2. Set our activate signal
      // 3. Wait for the busy signal to become active
      // 4. Wait for the busy signal to become inactive
      // But since we're running the RAM copier synchronous to this always_ff, we can
      // be a bit more cavalier
      rxtx_copy_src_addr <= { fifo_buf_num, 11'b0 };
      rxtx_copy_dst_addr <= { send_buf, 11'b0 };
      // The received length includes the CRC currently
      // FIXME: Verify the CRC in the receiver and don't store it in the RAM buffer?
      rxtx_copy_len <= fifo_pkt_len - 4; // Don't copy the FCS/CRC

      // Prepare our FIFO assertion too
      tx_fifo_buf_num <= send_buf;
      tx_fifo_len <= fifo_pkt_len - 4; // Don't send the FCS/CRC

      if (!rxtx_copy_busy) begin
        rxtx_copy_activate <= '1;
        erx_state <= S_ERX_AWAIT_RAM_COPY;
        copy_was_busy <= '0;
        send_buf <= send_buf + 1'd1; // Use the next send buffer, next time
      end
      // FIXME: give up if it's permanently busy?
    end: start_ram_copy

    S_ERX_AWAIT_RAM_COPY: begin: await_ram_copy ////////////////////////////////////////
      // Wait for the busy flag to be asserted then de-asserted
      case ({copy_was_busy, rxtx_copy_busy})
      // FIXME: Maybe have a counter so it cannot loop infinitely in these two states?
      2'b00: begin /* wasn't busy, still not busy: do nothing */ end
      2'b11: begin /* was busy, still busy: do nothing */ end
      2'b01: begin
        // Wasn't busy, became busy
        copy_was_busy <= '1;
      end
      2'b10: begin
        // Was busy, now not busy - copy is done!
        erx_state <= S_ERX_QUEUE_SEND;
      end
      endcase
    end: await_ram_copy

    S_ERX_QUEUE_SEND: begin: queue_send ////////////////////////////////////////////////
      // Assert our transmit FIFO send request when the send buffer is not full
      if (tx_fifo_wr_full) begin
        // DO NOTHING
        // FIXME: Time out after a while and give up so we don't loop indefinitely
      end else begin
        tx_fifo_wr_req <= '1;
        // tx_fifo_buf_num and tx_fifo_len already set above
        erx_state <= S_ERX_AWAIT_FIFO;
      end
    end: queue_send

    default: erx_state <= S_ERX_AWAIT_FIFO;
    endcase

  end

end: retransmit_received_packets

`endif // WRITE_PACKETS_TO_LCD






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