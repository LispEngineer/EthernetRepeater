# DE2-115 Ethernet Repeater

Copyright &copy; 2023 Douglas P. Fields, Jr. All Rights Reserved.

# Overview

My SystemVerilog code is heavily commented for ease of readability.

**Ultimate goal:**

Build a SystemVerilog system that reads Ethernet packets on one port and
reflects them directly out another port, and vice versa, allowing the
FPGA to be a bidirectional repeater.

Do all these things without a soft processor.

**Initial goals:**

* Build an MDC/MDIO interface to read all the ports.
  * Display them on the 7-segment displays
* Build an MDC/MDIO interface to write (and read) all the ports.
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

**[Terasic DE2-115](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=139&No=502&PartNo=4)**

This board has two 10/100/1000 copper Ethernet ports connected by a 
[Marvel 88E1111 PHY](https://www.marvell.com/content/dam/marvell/en/public-collateral/transceivers/marvell-phys-transceivers-alaska-88e1111-datasheet.pdf),
capable of MII and RGMII modes (selectable by jumper). The main FPGA is
a Cyclone IV. It has a lot of I/O but no digital display - which can be
added by HSMC card. Some useful features:

* Lots of memory: SRAM, SDRAM, Flash, EEPROM and SD card
* Lots of on-board user I/O: LEDs, 7-segments, buttons, switches, LCD
* Lots of external I/O: RS-232, USB UART, VGA, Audio, PS2
* Expansion: GPIO, EX_IO, HSMC, SMA

...and some not very useful stuff like a TV Decoder.

## Development Software

* Quartus Lite 21.1.0 Build 842
* Questa Intel Starter FPGA Edition-64 2021.2 (previously known as ModelSim)




# Current Functionality

* Management Interface - read & write enabled
  * Visually simulated in Questa
  * Tested on real PHY for reading
  * Useful actions:
    * Position cursor to Row, Col
    * Clear display (and position cursor to first spot)

* RGMII Transmit Capability
  * Works at 10BASE-T: Uses PLL generated 2.5MHz clock & 12ns delay on transmitted GTX clock
  * Works at 100BASE-T: Uses PLL generated 25MHz clock & 12ns delay on transmitted GTX clock
  * Works at 1000BASE-T: Uses PLL generated 125MHz clock & 2ns delay on transmitted GTX clock
    * And sends data on TXD with DDR encoding
  * Sends a fixed packet
    * Calculates the CRC on the fly and sends it, using [generated HDL](https://bues.ch/cms/hacking/crcgen)

* Built-in LCD
  * Can send a full screen of characters from switches
  * (Untested) Can put a character anywhere

* RGMII Receive Capability
  * FIFO for putting notifications fully received packets into
  * RAM buffer for putting full packet data into (including preamble/SFD for now)
  * "Bogus" test implementation of receiver to exercise RAM, FIFO
    

## Next Steps

* LCD Manager
  * TEST: Send a letter with a specific screen location
  * Power-up sequence required
  * Prepare to use it to display packet contents (!!!)

* Manual management interface
  * Store the register # from the switches SW4-0 (Key 0)
    * Show it on the HEX5-4
  * Read the stored register (Key 1)
    * Show it on LEDR15-0
  * Write switches SW15-0 to the stored register (Key 2)
    * Show current switch 15-0 settings always on HEX3-0
    * (Show SW4-0 on HEX7-6) (Huh? Why?)
  * Hardware reset (Key 3)

* Management state machine
  * Set up PHY side tx/rx clock shift handling
    * Read reg, write reg, read reg, write reg, wait for soft reset
  * Queries MDIO for state periodically
  * Exports state flags based on the state read
    * Link up & ready
    * Speed
    * Duplex
    * (Unnecessary for RGMII optional in-band state signaling?)
  * Could handle interrupts
  * Handle changing transmit speed as receive speed changes

* Simple RGMII TX interface
  * Handle changing speeds dynamically & reconfiguring delay PLLs
  * Handle [Interpacket Gap](https://en.wikipedia.org/wiki/Interpacket_gap)
    * See 802.3-2022 4.4.2 `interPacketGap` of 96 bits for up to 100Mb/s & 1 Gb/s
  * Use a RAM with 2048 byte-long packet slots (enough for the usual maximum frame size)
  * Use a FIFO for queuing sends
    * Length
    * RAM slot to send
    * CRC included (or not)
    * (Figure out how to parcel out RAM slots)
  * Add some bus for:
    * Putting packet data into the transmit RAM slots
    * Adding an entry to the transmit FIFO

* Simple RGMII RX interface
  * Handle RGMII configuration frames; use to determine DDR RX
  * Handle all 3 speeds
  * Receive frame bytes into a RAM buffer
    * Rotate receives through multiple buffers
    * Check frame CRC
    * Include flags on the received frames
  * Handle non-nibble/byte aligned receives (?)
  * Expand RAM size:
    * Allow reads 32 or 64 bits at a time, but still write 1 byte at a time with byte selects
    * Same, but write a word at a time
    * Expand RAM size by 1 bit, when that Nth bit is set it signals
      end of packet, and the other bits signify things like:
      * CRC error
      * Frame error
      * Then we could send a "Receive begin" message on the FIFO and
        the receiver could read from RAM the data as it is coming in.
      * Or we could send a "Receive complete" message on the FIFO with
        the final length and error information
  * Build a streaming output (AXI-Stream?) when we are getting a packet
    * Have an end of packet flag, which shows CRC and framing errors

* Enable reduced preamble mode for Management Interface?

* Simulate the PHY side of the Management Interface (for reads)
* Simulate the MAC/PHY side of TX/RX


## User Interface

* Red LEDs 15-0: Data read from registers
* Green LED 8: Heartbeat
* Green LEDs 5-0: Status (see code)
* Green LED 7: PLL Lock status
* KEY 3: Reset Ethernet PHY (only)
* SW 4-0: Register address
* KEY 0: Read from register in SW 4-0
* KEY 1: Send fixed ARP packet


## Open Questions

* During Management Interface idle periods - should I continue to run MDC?
  * Seems unnecessary and a waste of energy
  
* Can we get non-aligned packets?
  * Can we get extra bits before the SFD such that the 1011 comes non-nibble
    or non-byte aligned?

* Quartus is ignoring my GLOBAL_CLOCK settings for a few of the clocks.
  [This](https://www.intel.com/content/www/us/en/programmable/quartushelp/14.1/mergedProjects/msgs/msgs/wfygr_fygr_user_global_ignored.htm) talks about it
  but doesn't really explain why.

## Known Bugs

* Sometimes I have to send the MDIO request a few times to get it to respond
  differently. I haven't looked much into it. It could be a switch/button problem
  or an actual internal bug or a PHY limitation?

### Recently Fixed Bugs

### Hardware Bugs

* ETH0 is dead: On my DE2-115, enabling the Ethernet (RST_N to 1) on both ports
  causes ETH0 to be unreponsive when plugged in, but ETH1 reponds
  just fine and lights up 1000, DUP, RX lights.


# Notes on FPGA Resources

## ALTIOBUF

[Intel ALTIOBUF docs](https://www.intel.com/content/www/us/en/docs/programmable/683471/19-1/ip-core-user-guide.html)

* Add `ALTIOBUF`
* Bidirectional buffer
* Use open drain output (like I2C bus, MDC is pulled high)
  * From docs: "can be asserted by multiple devices in your system"
* Do not generate a netlist (we don't use a 3P EDA synthesis tool)
* Generate the Instantiation Template File (not really needed, it's easy, but whatever)
* Generate the Symbol File (although we won't use it)

Remember - the `inout` must be a SystemVerilog `wire` and not `logic` or else it
won't work.

## ALTSYNCRAM

The readout on this seems to take 2 cycles, not one.
* [Post](https://community.intel.com/t5/Intel-Quartus-Prime-Software/Altsyncram-read-data/m-p/165214) about it
* The Megafunction asks "Which ports should be registered"
  * If you choose `Read Output Ports: q` then it adds a register to the output
  * This seems to require two cycles to read the data:
  * Cycle 1: Set the inputs for reading (read enable, read address)
  * Cycle 2: It sents the output register
  * Cycle 3: You can see the data on the register's outputs

## CRC Generator Modules

Used the generated code from [this site](https://bues.ch/cms/hacking/crcgen)
and made it into SystemVerilog. Source is [on Github](https://github.com/mbuesch/crcgen).




# Notes on Ubuntu & Wireshark

* `ethtool`
  * `ethtool enp175s0` - shows the status of that link
  * `ethtool -K _device_ rx-fcs on` - accept frames with bad FCS (checksum)
  * `ethtool -K _device_ rx-all on` - accept all other invalid frames (like runts)
    * [source](https://isc.sans.edu/diary/Not+all+Ethernet+NICs+are+Created+Equal+Trying+to+Capture+Invalid+Ethernet+Frames/25896)
  * `ethtool -k _device_` shows all device capabilities
  * `ethtool -s enp175s0 autoneg on speed 10 duplex full` forces 10BASE-T full duplex
  * `ethtool -S enp175s0` shows some statistics
  * `ethtool --register-dump _device_` shows a bunch of hex values

* `ip`
  * `ip link show enp175s0` - shows status of that link
  * `ip link set _device_ promisc on` - turn on promiscuous mode
  * `ip -s link` to see summary statistics
  * `ip -stats link show enp175s0` shows them for that specific device

* `ifconfig`
  * `ifconfig _device_ promisc` - turn on promiscuous mode

* `arping`
  * `arping -t enp175s0 -S 10.10.10.10 -B` - force an ARP packet out that interface with this made up IP address

* `nstat`
* `ss`
* `netstat`
  * `netstat -s`

* `sysfs`
  * `ls /sys/class/net/enp175s0/statistics/` shows all available statistics

* Little monitor I cooked up:

    clear ; while /bin/true ; do echo -e -n '\E[25A' ; for i in `ls /sys/class/net/enp175s0/statistics/ | fgrep -v txxxx_` ; do echo $i `cat /sys/class/net/enp175s0/statistics/$i` ; done ; sleep 1 ; done`

* Docs
  * [Kernel Network Statistics](https://docs.kernel.org/networking/statistics.html)


## Wireshark

* Documents/Tutorials
  * [Tutorial](https://www.varonis.com/blog/how-to-use-wireshark)

* [Capture Privileges](https://wiki.wireshark.org/CaptureSetup/CapturePrivileges#most-unixes)
  * Or just run as `root`

* Seeing FCS?
  * [Stack Overflow](https://ask.wireshark.org/question/2876/how-to-see-the-fcs-in-ethernet-frames/)
    says it's probably impossible
  * [Another Stack Overflow](https://stackoverflow.com/questions/22101650/how-can-i-receive-the-wrong-ethernet-frames-and-disable-the-crc-fcs-calcul) tells about how to use
    the `ethtool` above
  * [Wireshark FAQ on FCS](https://www.wireshark.org/faq.html#_how_can_i_capture_entire_frames_including_the_fcs)


* [Network Tap](https://en.wikipedia.org/wiki/Network_tap)
  * [LANProbe](https://qlinxtech.com/lanprobe)
  * [DualComm](https://www.dualcomm.com/collections/featured-products/products/usb-powered-10-100-1000base-t-network-tap)
  * [ProfiShark 1G](https://blog.packet-foo.com/2014/12/a-look-at-a-portable-usb3-network-tap/)


* Filters
  * `eth.type != 0x86dd && eth.type != 0x0800` - remove all IPv6 and IPv4 packets
    * (Generally leaves just ARP and invalid stuff)

* Wireshark Ethernet options
  * Assume packets have FCS: Always
  * Validate the Ethernet checksum if possible
  * NOTE: receive packets include the FCS, but sent packets do NOT, so doing this will
    find FCS/checksum errors in all SENT packets




# Notes on Test Harness

Ensure Quartus Settings -> Simulation shows `Questa Intel FPGA`

Do not use `$finish;` in your simulation - it will quit Questa
and you will have to do everything below all over again!

* Run Questa: `Tools -> Run Simulation Tool -> RTL Simulation...`
* To restart simulation: `Simulate -> Restart...`
* You can save your waves
* You can load saved waves with File -> Load -> Macro File... and then
  choose `test1-wave.do`

Setting up Quartus to load the Test Harness in Questa
* See [Quick Start](https://www.intel.com/content/www/us/en/docs/programmable/703090/21-1/simulation-quick-start.html)
  documentation section 1.2, figures 3-4
* Quartus: Assignments -> Settings -> EDA Tool Settings -> Simulation
* NativeLink Settings -> Compile test bench
* Click `Test Benches...` then `New`
* Add a name (e.g., `testbench_1`) and specify the `test_whatever` as top-level module
* Add all the file `test_whatever.sv` and `other.sv` and mark it as SystemVerilog
* NOW, when you run the `RTL Simulation` it will open this by default.
* You will still need to save the waves as you like them and reload them (per above).
* When you change things, you still have to right-click & `Recompile` in the `Library`
  * This is a long command in `VSIM ##>` prompt
* Then you can type at the `VSIM ##>` prompt `restart -f ; run -all`

## SignalTap

* To disable SignalTap again, go to Assignments -> Settings -> SignalTap and unclick Enable

## Ubuntu Ethernet Monitoring

* Monitor counts with:
        clear ; while /bin/true ; do echo -e -n '\E[45A' ; for i in `ls /sys/class/net/enp175s0/statistics/ | fgrep -v txxxx_` ; do echo $i `cat /sys/class/net/enp175s0/statistics/$i` ; done ; echo ; ifconfig enp175s0 ; sleep 1 ; done



# Example Ethernet Frame

This is an ARP ethernet Frame

    ff ff ff ff ff ff - to everyone
    06 e0 4c DF DF DF - from whoever we are
    08 06 - ARP (type/len)
    FROM HERE IS ARP
    00 01 - Ethernet
    00 00 - IPv4 ARP (not 00 00, this is wrong, fixed in the code)
    06 - hardware size
    04 - protocol size
    00 01 - opcode - request
    06 e0 4c DF DF DF - sender MAC address (same as above)
    10 20 DF DF - our IPv4 Address
    00 00 00 00 00 00 - target MAC address (anyone)
    ff ff ff ff - target IP address (anyone)
    00 .. 00 - trailer (16x 00's)
    xx xx xx xx - checksum

    ff ff ff ff ff ff
    06 e0 4c DF DF DF
    08 06
    00 01
    00 00
    06
    04
    00 01
    06 e0 4c DF DF DF
    10 20 DF DF
    00 00 00 00 00 00
    ff ff ff ff
    00 00 00 00 00 00 00 00
    00 00 00 00 00 00 00 00
    43 4B 0B 75 (checksum is sent least significant byte first)

* CRC = `0x750B4B43`
* [Online CRC Calculator](https://crccalc.com/?crc=ff+ff+ff+ff+ff+ff++06+e0+4c+DF+DF+DF++08+06++00+01++00+00++06++04++00+01++06+e0+4c+DF+DF+DF++10+20+DF+DF++00+00+00+00+00+00++ff+ff+ff+ff++00+00+00+00+00+00+00+00+00+00+00+00+00+00+00+00&method=crc32&datatype=hex&outtype=0)

## CRC Calculators

* [SO Question](https://stackoverflow.com/questions/40017293/check-fcs-ethernet-frame-crc-32-online-tools)
* [CRC calculator](https://www.scadacore.com/tools/programming-calculators/online-checksum-calculator/)
* [CRC Algorithms](https://reveng.sourceforge.io/crc-catalogue/17plus.htm#crc.cat-bits.32/) - see CRC-32/ISO-HDLC
* [CRC Verilog Language Generator](https://bues.ch/cms/hacking/crcgen)
* [Another one](http://www.sunshine2k.de/coding/javascript/crc/crc_js.html)






# DE2-115 and Marvel 88E1111

Docs:
* https://ftp.intel.com/Public/Pub/fpgaup/pub/Teaching_Materials/current/Tutorials/DE2-115/Using_Triple_Speed_Ethernet.pdf
* https://people.ece.cornell.edu/land/courses/ece5760/FinalProjects/f2011/mis47_ayg6/mis47_ayg6/
* [Great intro to Ethernet on the Wire](https://www.analog.com/media/en/technical-documentation/application-notes/ee-269.pdf)
* https://www.allaboutcircuits.com/ip-cores/communication-controller/sgmii/
* https://lantian.pub/en/article/modify-computer/cyclone-iv-fpga-development-bugs-resolve.lantian/
* https://github.com/alexforencich/verilog-ethernet
* https://github.com/xddxdd/zjui-ece385-final
* https://core.ac.uk/download/pdf/224741175.pdf
* https://www.fpga-cores.com/cores/fc1001_mii/
* https://fraserinnovations.com/fpga-board-based/how-ethernet-work-and-familiar-with-mii-gmii-rgmii-interface-types-fii-prx100-risc-v-board-experiment-15/
* https://prodigytechno.com/mdio-management-data-input-output/
* https://medium.com/@Frank_pan/how-to-use-ethernet-components-in-fpga-altera-de2-115-26659da06362
* https://en.wikipedia.org/wiki/Media-independent_interface#cite_note-802.3-2
* [U-boot Initialization](https://github.com/RobertCNelson/u-boot/blob/master/drivers/net/phy/marvell.c)

* MDIO
  * [Wikipedia on MDIO](https://en.wikipedia.org/wiki/Management_Data_Input/Output)

* RGMII:
  * https://www.renesas.com/us/en/document/apn/guide-using-rgmii-making-ethernet-if-connection
  * [AN 477: Designing RGMII Interfaces with FPGAs and HardCopy 
     ASICs](https://cdrdv2-public.intel.com/654563/an477.pdf)
  * [Intel Triple-Speed Ethernet](https://www.intel.com/content/www/us/en/docs/programmable/683402/22-4-21-1-0/about-this-ip.html)
  * [RGMII Timing for EthernetFMC](https://ethernetfmc.com/docs/user-guide/rgmii-timing/)
  * [RGMII experiment](https://fraserinnovations.com/fpga-board-based/how-does-ethernet-work-mii-gmii-rgmii-interface-advantages-and-disadvantages-fii-pra004-altera-risc-v-tutorial-experiment-14/)
  * [Stack Overflow](https://stackoverflow.com/questions/15777399/clarification-on-ethernet-mii-sgmii-rgmii-and-phy)
  * [Xilinx notes](https://docs.xilinx.com/r/en-US/pg160-gmii-to-rgmii/RGMII-Interface-Protocols)
  * [RGMII v2.0 Spec](https://web.archive.org/web/20160303171328/http://www.hp.com/rnd/pdfs/RGMIIv2_0_final_hp.pdf)

* Marvell 88E1111
  * [U-Boot 88E1xxx Initialization](https://github.com/RobertCNelson/u-boot/blob/master/drivers/net/phy/marvell.c)
  * [88E1111 PHY Configuration Steps](https://community.intel.com/t5/FPGA-Wiki/Marvell-88E1111-PHY-Configuration-Steps/ta-p/735410)

* Quartus
  * [Inferring RAM](https://www.intel.com/content/www/us/en/docs/programmable/683082/22-3/simple-dual-port-dual-clock-synchronous-ram.html)
  * [Constraining RGMII Clocks](https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-examples/horizontal/exm-tse-rgmii-phy.html)
  * [Quartus II Clocks](https://www.eevblog.com/forum/microcontrollers/quartus-ii-clocks/)
  * [Use Global Clock Resources](https://www.intel.com/content/www/us/en/docs/programmable/683082/21-3/use-global-clock-network-resources.html)
  * [Some RGMII timing constraint examples](https://github.com/genrnd/ethond/blob/master/fpga/rgmii.sdc)
  * [Altera AN 433: Constraining and Analyzing Source-Synchronous Interfaces](https://cdrdv2-public.intel.com/653688/an433.pdf)
  * [Quartus Help top level v22.1](https://www.intel.com/content/www/us/en/programmable/quartushelp/22.1/index.htm#quartus/gl_quartus_welcome.htm)
  * [Quartus Recommended HDL Coding and Design Practices](https://www.intel.com/content/www/us/en/docs/programmable/683082/22-3/recommended-hdl-coding-styles.html)
  * [Programmable Delays](https://www.intel.com/content/www/us/en/docs/programmable/683641/21-4/programmable-delays.html)
    * `Delay Chain Summary` report is in Fitter -> Resource Section -> Delay Chain Summary
    * Not sure what the `Resource Property Editor` is
  * [Clock Multiplexing](https://www.intel.com/content/www/us/en/docs/programmable/683082/22-3/clock-multiplexing.html)
  * [Reconfigurable PLLs - example](https://www.reddit.com/r/FPGA/comments/mubxlb/altera_cyclone_iv_altpll_reconfig/)
  * [PLL reconfiguration AN-661](https://www.intel.com/content/www/us/en/docs/programmable/683640/current/implementing-fractional-pll-reconfiguration-33682.html)

* [ETHERNET-HSMC](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=71&No=355&PartNo=2#contents)


Linux to keep FCS & bad CRCs
* https://stackoverflow.com/questions/22101650/how-can-i-receive-the-wrong-ethernet-frames-and-disable-the-crc-fcs-calcul


Per schematic, only 4 RXD/TXD lines are connected to FPGA from Marvell Alaska 88E1111.

CONFIG wiring pins on DE2-115:

                      Table 32      Table 12
    0 - ground        000 (VSS)     PHY_ADR[2:0]
    1 - LED_LINK10    110           PHY_ADR[4:3] and ENA_PAUSE; PHY_ADR[6:5] fixed 10
    2 - VCC           111 (VDDO)    ANEG[3:1]
    3 - LED_TX        001           ANEG[0], ENA_XC, DIS_125
    4 - (see below)   011 or 111    HWCFG_MODE[2:0]
    5 - VCC           111 (VDDO)    DIS_FC, DIS_SLEEP, HWCFG_MODE[3]
    6 - LED_RX        010           SEL_TWSI, INT_POL, 75/50 Ohm
    (ENET_VCC2P5 is fed to VDDOX, VDDOH, VDDO. VSSC is fed to ground)

See Table 34 for exact bit details, and Table 35 for meanings:

    PHY_ADR[6:0] = 10 10 000
    ANEG[3:0]    = 1110 = Auto-Neg, advertise all capabilities, prefer Master
    ENA_XC       = 0 = Disable (MDI Crossover)
    DIS_125      = 1 = Disable 125CLK
    HWCFG_MODE[3:0] = 1011 or 1111 - RGMII or GMII
    DIS_FC       = 1 = Disable fiber/copper auto select
    DIS_SLEEP    = 1 = Disable energy detect
    SEL_TWSI     = 0 = Select MDC/MDIO interface
    INT_POL      = 1 = INTn signal is active LOW
    75_50_OHM    = 0 = 50 ohm termination for fiber


Looks like `RST_N`, `MDC`, `MDIO`, and `INT_N` are all pulled high by 4.7k.
`RSET` and `TRST_N` are pulled low.
JTAG is not configured.
`XTAL1` gets 25MHZ.

`JP1/2` on Pins 2-3 will set `MII` mode; on 1-2 will set `RGMII` mode (4 bit)
This goes to CONFIG4 pin, which can be either:
* 011 - LED_DUPLEX
* 111 - VDDO (which is ENET_VCC2P5 in the docs)a

MII Mode: (p.54)
* 100BASE-TX - TX_CLK, RX_CLK source 25 MHz
* 10BASE-T - they source 2.5 MHz

Revision M of Marvell spec:
* 2.2.1 is GMII/MII
* 2.2.3 is RGMII

#### 2.8 Power management
COMA pin is tied low per schematic

#### 2.9 Management Interface
IEEE 802.3u clause 22
https://en.wikipedia.org/wiki/Management_Data_Input/Output

Per schematics:
* Eth0 PHY: 101 0000
* Eth1 PHY: 101 0001

`MDIO`: Pull-up by 1.5 - 10 kohm

`MDC` - maximum 8.3 MHz (120 ns period, per 4.15.1)

Preamble = 32 bits of 1; Suppression allows this to become just one 1

It seems a lot like a I2C/IIC interface but with fixed function and
fixed read/write size (16 bits).

The picture makes it look like the value is sampled on the rising edge
of the clock.

#### 3. Register Description

This contains all the registers details

#### 4. This section contains the timing diagrams

#### IEEE 802.3-2022

SEE IEEE 802.3-2022 section 22.2.2.13-14 (page 714)
and 22.2.4 page 717

(Note: It is not clear to me if the Ethernet CRC has to be sent as part of the data
or if the PHY will do that., per Standard 22.2.3. I am guessing the PHY does NOT do that.)

Std Table 22-6 lists the registers.
22.2.4.1.1 says reset cannot take more than 0.5 sec.

22.2.4.5 has the management frame structure

22.2.4.5.5 Transmit PHY MSB first (5 bits)
  You can always use an address of 00000 if there is only one device connected!
22.2.4.5.6 Also transmit register address MSB first
22.2.4.5.7 TA Turnaround
  Read: Z then PHY 0
  Write: 10
22.2.4.5.8 DATA is transmitted MSB first

22.3.4 MDIO/MDC timing 
* "When the STA sources the MDIO signal, the STA shall provide a minimum of 10 ns of setup time and a 
minimum of 10 ns of hold time referenced to the rising edge of MDC"
* "When the MDIO signal is sourced by the PHY, it is sampled by the STA synchronously with respect to the
rising edge of MDC."

## ETHERNET-HSMC Card

Schematic says "RGMII Mode"
* CONFIG 0 - RX      010   PHY_ADR[2:0]
* CONFIG 1 - LINK10  110   PHY_ADR[4:3] and ENA_PAUSE; PHY_ADR[6:5] fixed 10
* CONFIG 2 - VCC     111   ANEG[3:1]
* CONFIG 3 - TX      001   ANEG[0], ENA_XC, DIS_125
* CONFIG 4 - DUPLEX  011   HWCFG_MODE[2:0]
* CONFIG 5 - VCC     111   DIS_FC, DIS_SLEEP, HWCFG_MODE[3]
* CONFIG 6 - GND     000   SEL_TWSI, INT_POL, 75/50 Ohm
* PHYADR     = 10010 - PHY Address
* ENA_PAUSE  = 1     - Enable Pause
* ANEG       = 1110  - (Copper) Auto-neg, advertise all capabilities, prefer Master
* ENA_XC     = 0     - Disable Crossover
* DIS_125    = 1     - Disable 125MHz clock
* HWCFG_MODE = 1011  - RGMII/Modified MII to copper (Table 28)
* DIS_FC     = 1     - Disable fiber/copper auto-select
* DIS_SLEEP  = 1     - Disable energy detect
* SEL_TWSI   = 0     - Select MDC/MDIO interface
* INT_POL    = 0     - Interrupt poliarity - INTn is active HIGH
* 75_50_OHM  = 0     - 50 ohm termination for fiber

The `HWCFG_MODE` could be changed
* Register 27 Bits 3:0 (Table 28)
  * 0000 = SGMII with Clock with SGMII Auto-Neg to copper
  * 0100 = SGMII without Clock with SGMII Auto-Neg to copper
  * 1011 = RGMII/Modified MII to Copper (Hard reset default)
  * 1111 = GMII/MII to copper
  * After changing, needs a soft reset

* Set the delays in the PHY - see Page 213 / 4.12.2
  * Register 20.7 = Delay to RX_CLK
  * Register 20.1 = Delay to TX_CLK



## Experimental learnings with 88E1111

* During RST_N (reset) it will not respond to Management Interface.

## 88E1111 Register Notes

* Register 0x11 (17) Page 0 - PHY Specific Status Register - Copper
  * Bits 15-14: Speed
  * Bit 13: Duplex
  * In 10/Full it shows:
    * 0010_1101_0000_1100
    * Speed: 10
    * Duplex: Full
    * Page not reeived
    * Speed & duplex resolved
    * Link up
    * Cable length 80-110m (which is funny since it has a 3' cable)
    * MDI
    * No Downshift
    * PHY ACtive
    * Transmit pause enabled
    * Receive pause enabled
    * Normal polarity
    * No jabber
* Register 0x01 (1) Page 0 - Status Register
  * In 10/Full it shows:
  * 0111_1001_0110_1101
  * 100BASE-T4 incapable
  * 100BASE-T FD & HD capable
  * 10BASE-T FD & HD capable
  * 100BASE-T2 FD/HD incapable
  * Extended status available in Register 15
  * Preamble suppression allowed (management frames)
  * Auto-negotiation complete (bit 5, copper)
  * No copper remote fault detected
  * Able to auto-negotiate
  * Link up (bit 2)
  * No Jabber
  * Extended register capability - yes



# Misc Quartus Notes

* VS Code as external editor: `"C:\Users\Doug\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd" --goto %f:%l`
  * You cannot insert HDL template without using the internal editor, so sometimes this needs to change
* Questa directory: `C:/bin/fpga/intelFPGA_lite/21.1/questa_fse/win64`



# 16x2 LCD

[Crystalfontz CFAH1602B-TMC-JP](https://www.crystalfontz.com/product/cfah1602btmcjp)
* [Hitachi HD44780 Display Controller](https://www.sparkfun.com/datasheets/LCD/HD44780.pdf)
* [KS0066U]()
* [Lab Exercise to use this with all datasheets](http://web02.gonzaga.edu/faculty/talarico/CP430/LABS/Lab4.pdf)
* DE2-115 pin `LCD_BLON` is not connected - no backlight
* [Example Verilog](https://github.com/amanmibra/lcd-de2-115) - incomprehensible
* [Another example](https://gist.github.com/jjcarrier/1529101)
* [ANother lab](http://media.ee.ntu.edu.tw/personal/pcwu/dclab/dclab_08.pdf)
* [Example Verilog for HD44780](https://circuit4us.medium.com/play-with-16x2-lcd-display-ca70a047af36)
* [Another example](http://robotics.hobbizine.com/fpgalcd.html) - good one
* [Xilinx Example](https://docs.xilinx.com/v/u/en-US/ug330)