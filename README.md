# DE2-115 Ethernet Repeater

Copyright &copy; 2023 Douglas P. Fields, Jr. All Rights Reserved.

# Overview

**Ultimate goal:**

Build a SystemVerilog system that reads Ethernet packets on one port and
reflects them directly out another port, and vice versa, allowing the
FPGA to be a bidirectional repeater.

**Initial goals:**

Do all these things without a soft processor.

* Build an MDC/MDIO interface to read all the ports.
  * Display them on the 7-segment displays
* Build an MCD/MDIO interface to write (and read) all the ports.
* Build an interface that sends a simple ARP request packet
  * Calculate CRC
  * Send at 10BASE-T
  * Send at 100BASE-TX
  * Send at 1000BASE-T
* Build an interface that reads a single packet
  * Display information on 7-seg
  * Display information on LCD
  * Display information on VGA or DVI
  * Send packet information via USB UART

  ## Hardware

  **Terasic DE2-115**

  This board has two 10/100/1000 copper Ethernet ports connected by a 
  [Marvel 88E1111 PHY](https://www.marvell.com/content/dam/marvell/en/public-collateral/transceivers/marvell-phys-transceivers-alaska-88e1111-datasheet.pdf),
  capable of MII and GRMII modes (selectable by jumper). The main FPGA is
  a Cyclone IV. It has a lot of I/O but no digital display - which can be
  added by HSMC card. Some useful features:
  
  * Lots of memory: SRAM, SDRAM, Flash, EEPROM and SD card
  * Lots of on-board user I/O: LEDs, 7-segments, buttons, switches, LCD
  * Lots of external I/O: RS-232, USB UART, VGA, Audio, PS2
  * Expansion: GPIO, EX_IO, HSMC, SMA

  ...and some not very useful stuff like a TV Decoder.