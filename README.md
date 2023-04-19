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

* Ethernet MII Management Interface (MDC/MDIO)
  * Simulation tested in Questa
  * Tested on real PHY for reading & writing manually
  * Initializes PHY at startup and upon reset per 88E1111 timing guidlines
    * (Does not check for 10 cycles of PHY 25 MHz clock)
  * Turns on PHY-side TX & RX clock adjustments including soft reset
  * Outputs `configured` signal once fully initialized
  * See below for UI interactions

* RGMII Transmit Capability
  * Works at 10/100/1000 using PLL generated clock at 2.5, 25, 125 MHz
    * And sends data on TXD with DDR encoding at 1000
    * Sends TX_DV and TX_ER via DDR
  * Sends a fixed packet (a silly ARP request)
    * Calculates the CRC on the fly and sends it, using [generated HDL](https://bues.ch/cms/hacking/crcgen)

* RGMII Receive Capability
  * FIFO for putting notifications of fully received packets into
  * RAM buffer for putting full packet data into (including preamble/SFD for now)
  * (Disabled) "Bogus" test implementation of receiver to exercise RAM, FIFO
  * In-Band metadata connected
    * Tested at 10/100 Full/Half and 1000 Full
      * (PHY will not autonegotiate a 1000 Half link with default settings)
    * Shows 1000 speed when no connection (Reg20, bits 6:4)
  * Receives 10/100 data - totally raw (one nibble at a time)
    * Does not track preamble, SFD, FCS/CRC - just stores all data received while RX_DV
    * BUG: Reports length off by one
  * BUG: Receiving 1000 data does not work (one byte at a time with DDR)
    * BUG: Looks like the DDR data receiver is ... off - see below

* Built-in LCD driver
  * Can put a character anywhere with single activation request
  * (Cannot initialize screen yet! Works only if screen initialized by previous programming.)

* Miscellaneous
  * 7-segment driver


## Next Steps

* LCD Manager
  * Power-up sequence required

* Management state machine
  * Query MDIO for state periodically and exports state flags based on the state read
    * Link up & ready
    * Speed
    * Duplex
    * (Unnecessary for RGMII optional in-band state signaling?)
  * Enable and handle interrupts
  * Handle changing transmit speed as receive speed changes
    (Use a clock multiplexer)

* Simple RGMII TX interface
  * Write ALTDDIO_IN module that aligns `_h` and `_l`
  * Handle changing speeds dynamically & reconfiguring delay PLLs
    * Or use a clock multiplexer and choose the right clock
    * Ensure to hold TX_DV low while switching clock
  * Handle [Interpacket Gap](https://en.wikipedia.org/wiki/Interpacket_gap)
    * See 802.3-2022 4.4.2 `interPacketGap` of 96 bits for up to 100Mb/s & 1 Gb/s
  * Use a RAM with 2048 byte-long packet slots (enough for the usual maximum frame size)
  * Use a FIFO for queuing sends
    * Length
    * RAM slot to send
    * CRC included (or not)
    * (Figure out how to parcel out RAM slots)
      * Maybe start with a FIFO of all N slots filled up
      * Then as a slot is asked to be sent, re-add it to the FIFO
      * This can fail badly if someone doesn't send a slot, so maybe not a good idea...
  * Add some bus (e.g. AXI4-Lite) for
    * Putting packet data into the transmit RAM slots
    * Adding an entry to the transmit FIFO

* Simple RGMII RX interface
  * Handle all 3 speeds: 1000 does not currently work
  * Check frame CRC
  * Handle non-nibble/byte aligned receives (if necessary? and see below)
    * Once we see the SFD (`0xD5`) we should jump to the payload, even if it
      is less than the 8th byte. This way received data is always at 8.
    * "Clause 22.2.3.2.2 shows all that is required is that the SFD is received fully and it 
      is correctly aligned at the MII pins. No preamble preceding SFD needs to be conveyed 
      through the MII."
      [Source](https://ez.analog.com/industrial-ethernet/physical-layer-devices/f/q-a/558604/adin1300-10base-t-runt-preamble?ReplySortBy=CreatedDate&ReplySortOrder=Ascending)
      and of course see the 802.3-2022 spec itself.
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
  * Handle missing preamble nibbles: [Wikipedia](https://en.wikipedia.org/wiki/Media-independent_interface) says:
    "The receive data valid signal (RX_DV) is not required to go high immediately 
    when the frame starts, but must do so in time to ensure the "start of frame 
    delimiter" byte is included in the received data. Some of the preamble nibbles 
    may be lost."

* Improved CRC generator specifically for Cyclone IV
  * Build a 3 & 4 entry XOR LUT mechanism to target the Cyclone IV's 4-LUT
  * Rewrite the CRC to use these 3/4-LUTs to reduce the combinatorial depth
  * Reference: Cyclone IV Device Handbook, Volume 1, Section I, Part 2,
    LE Operating Modes -> Normal Mode, Figure 2-2

* Enable reduced preamble mode for Management Interface?

* Simulate the PHY side of the Management Interface (for reads)
* Simulate the MAC/PHY side of TX/RX
* Put a decimal counter into the Bogus packet generator
  * [Here](https://www.realdigital.org/doc/6dae6583570fd816d1d675b93578203d) is one BCD converter
  * [Here](https://johnloomis.org/ece314/notes/devices/binary_to_BCD/bin_to_bcd.html) is a better description


## User Interface

* Red LEDs 15-0: Data read from registers
* Red LEDs 17-16: LCD:
  * 17 = lcd_busy
  * 16 = lcd_available
* Green LEDs 5-0: PHY RX in-band status
  * 0 = Link Up
  * 1 = Full Duplex
  * 2 = 10
  * 3 = 100
  * 4 = 1000
  * 5 = RX in-band data differs on H and L edges - happens sometimes
* Green LED 6: Eth PHY configuration complete
* Green LED 7: PLL Lock status for 125, 25, 2.5 MHz from 50
* Green LED 8: Heartbeat
* SW 4-0: Register address for below (Register decimal 17 is interesting.)
* KEY 0: Set register address for KEY 1/2
* KEY 1: Read from stored register to Red LEDs & HEX
* KEY 2: Transmit fixed Ethernet packet (at SV-defined fixed speed)
* KEY 3: Reset Ethernet Management & PHY (only, for now)
* HEX 7-6: Stored MDIO Management Interface register (from key 0)
* HEX 5-0: Receiver counts
  * 5-4: Count of received frames ended by a "carrier" message (i.e., RXDV 0, RXERR 1)
  * 3-0: The 16 bits read from the most recent receive FIFO:
    crc error, frame error, 3 bits of buffer number, 11 bits of length
* LCD: Displays 32 characters of received packet data as ASCII starting 
  after Ethernet frame header (i.e., after 2x MAC & EtherType, preamble and SFD)
  * (This can be off if the PHY omits some preamble nibbles/bytes)


## Open Questions

* During Management Interface idle periods - should I continue to run MDC?
  * Seems unnecessary and a waste of energy
  
* Can we get non-aligned packets?
  * Can we get extra bits before the SFD such that the 1011 comes non-nibble
    or non-byte aligned?

* Quartus is ignoring my GLOBAL_CLOCK settings for a few of the clocks.
  [This](https://www.intel.com/content/www/us/en/programmable/quartushelp/14.1/mergedProjects/msgs/msgs/wfygr_fygr_user_global_ignored.htm) talks about it
  but doesn't really explain why.

* (This may be out of date)
  At 10/Full, the PHY gets an in-band data mismatch every time there is a packet received.
  * This is repeatable, just send ARP requests while it is in 10/Half.
  * Also 10/Full, 100/Half and 100/Full
  * Harder to say, but also seems to happen at 1000/Full (blink is so faint)
  * TODO: Show the H & L sides when there is a packet mismatch?
  * Test results (with this commit):
    * The count of received packets is exactly the same as the count of interframe_differ
      packets. I wonder if this means the receiver starts getting stuff in the middle of
      an interframe in-band signaling packet and directly outputs that to the MAC?
    * The data_h and data_l seem to be a consistent 0xFD or 8'b1111_1101 based on the
      output of this commit receiving at 1000. For 10, it seems to be 0xF9 / 8'b1111_1001.
      For 100, it seems to be 0xFB / 8'b1111_1011. For Half Duplex 100 it shows 0xF3,
      8'b1111_0011 indicating half duplex 100 and an F. Predictably, for 100/half it shows 0xF1.
      * This seems to imply that the mismatch / F indicates that data is about to be received?
    * When the link is down it shows a mismatch 0x4C or 8'b0010_1100, 0x42 or 8'b0010_0010,
      or 0x49 or 8'b0010_1001. It seems the old (or new?) speed is shown during this misatch.
    * I guess we just ignore the mismatches.
    * WHAT ABOUT receive errors?

* The packets we start to receive get ended with 0,1 - carrier something - according to
  our counters. They don't have errors (receive error counter is 0) and don't have
  normal ends.
  * Register 20.15 is used to block carrier extension in GMII (Sec 2.2.3.2)
  * Says to refer to the White Paper "TRR Byte Stuffing and MACs"

* If we get RX_ERR (RX_ER, RXERR) with RX_DV, what do we do with the data in that byte/nibble?
  * For now, I am just ignoring it (not adding it to receive buffer)

* Is there a standard, fault tolerant "in use" system so we can allocate buffers, use them,
  and release them in a safe fashion?

## Known Bugs

* Have an off by one error on receive packet length because it
  uses the final byte write position and not the actual length.

* Packets received at 1000 are one byte short - probably missing a
  preamble byte.
  * 88E1111 datasheet mentions `dribble bits` and says `nibbles on MII are aligned to start
    of frame delimiter and dribble bits are truncated`.
    * "Dribble bits are extra bits of data that were received after the Ethernet CRC."
      [Discussion](https://groups.google.com/g/comp.dcom.lans.ethernet/c/ywqOT9aUnJY).
  * 88E1111 datasheet sections 4.14.12-14 show RGMII Receive Latency Timing
  * [Intel's Triple-Speed Ethernet](https://www.intel.com/content/www/us/en/docs/programmable/683402/22-4-21-1-0/preamble-processing.html)
    preamble processing looks for SFD within 7 bytes. (It also allows IPG of 8/6 bytes in 1000 or 100/10,
    below the 96 bit times in the spec.)

* Timing analyzer does not like the CRC generator running at 125MHz; compiling gives a Critical Warning
  * Open Timing Analyzer -> Tasks -> Reports -> Custom Reports -> Report Timing Closure Recommendations and use 20,000 paths
  * Suggested setting the Synthesis Optimization to "Speed" - this did not help
  * Suggested turning on Physical Synthesis - which I did in the Fitter Advanced Settings - this also did not help
  * I don't really understand how the paths from `count` to `crc` are misbehaving
  * We could try Alex's [CRC Generator Here](https://github.com/alexforencich/verilog-lfsr/blob/master/rtl/lfsr.v) which he says synthesizes well in Quartus

* Sometimes I have to send the MDIO request a few times to get it to respond
  differently. I haven't looked much into it. It could be a switch/button problem
  or an actual internal bug or a PHY limitation?
  * This hasn't happened in a while so maybe it's not a problem anymore.

### Recently Fixed Bugs

* **Does NOT receive packets at 1000.** Gets the correct length (same off by one error as
  above), but the data is all messed up. Expected then Received:

        Hi Doug! !"#$%&'   48 69 20 44 6F 75 67 21 20 21 22 23 24 25 26 27
        Bye    ()*+,-./0   42 79 65 20 20 20 20 28 29 2A 2B 2C 2D 2E 2F 30 .. 22 24 26 28 2A

        I`$Oewa !"#$%&'"   xx 49 60 24 4F 65 77 61 20 21 22 23 24 25 26 27 .. 22
        Iu`   ()*+,-./ 2   22 49 75 60 20 20 20 28 29 2A 2B 2C 2D 2E 2F 20 32

        69 20 44 6F 75 67 21 20 21 22 23 24 25 26 27
        49 60 24 4F 65 77 61 20 21 22 23 24 25 26 27
        ... Shift the top nibble over one ...
        69 20 44 6F 75 67 21 20 21 22 23 24 25

  * If we do `always_ff @(posedge clk)` then the DDR receive negative side will be from the previous
    byte, because the new corresponding `negedge` hasn't yet come in and gotten latched/flopped
    into the input buffer.
  * FIXED: Delay the `_h` side by a cycle to align it with the `_l` and these two things are fixed:
    1. The data bytes for 1000 speed are properly aligned
    2. The RX_CTL no longer shows unexpected frame extension

### Hardware Bugs

* ETH0 is dead: On my DE2-115, enabling the Ethernet (RST_N to 1) on both ports
  causes ETH0 to be unreponsive when plugged in, but ETH1 reponds
  just fine and lights up 1000, DUP, RX lights.
  * I have since purchased a second DE2-115 that seems to have two working ETH ports.

# Notes on FPGA Resources / Megafunctions / Hard IP

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

## ALTDDIO_IN

See Cyclone IV Handbook, Volume 1, Chapter 7, Figure 7-7 on the DDR Input Register.

This DDR input buffer has the property that, on posedge `inclock`, it shows the current value
of the high bit and the previous value of the low bit, because the new low bit has not
yet come in. So, you need to add a single cycle synchronizer on the `dataout_h` to align
the `_h` and `_l` data to the same clock cycle (high then low) if you want to handle those
two specifically as a pair.

This is necessary for RGMII, as those specific two bits go together to form the RX_CTL
signal. At 1000 speed, the two go together to make a single byte of data transfer as well.

## ALTSYNCRAM

The readout on this seems to take 2 cycles, not one.
* [Post](https://community.intel.com/t5/Intel-Quartus-Prime-Software/Altsyncram-read-data/m-p/165214) about it
* The Megafunction asks "Which ports should be registered"
  * If you choose `Read Output Ports: q` then it adds a register to the output
  * This seems to require two cycles to read the data:
  * Cycle 1: Set the inputs for reading (read enable, read address)
  * Cycle 2: It sents the output register
  * Cycle 3: You can see the data on the register's outputs

I made two RAMs:
* rx_ram_buffer - registered q output
* rx_ram_buffer_fast - unregistered q output

## CRC Generator Modules

Used the generated code from [this site](https://bues.ch/cms/hacking/crcgen)
and made it into SystemVerilog. Source is [on Github](https://github.com/mbuesch/crcgen).

* [Another one](https://leventozturk.com/engineering/crc/)
* [A nice another one](http://crctool.easics.be/)


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

* `nmcli` (Really no idea about this one)
  * `nmcli connection show` 

* `ping`
  * Send exactly one ping on a specified interface to broadcast address
    * `ping -c 1 -I enp175s0 -r -b 192.168.3.255`

* `packeth`
  * GUI (and CLI?) program to send random Ethernet packets, very useful

* Ubuntu network settings
  * For the wired ethernet, make it quiet like this:
  * Details: Do not connect automatically
  * Identity: Whatever
  * IPv4: Manual at 192.168.0.133/255.255.252.0, no gateway, no DNS
  * IPv6: Disable (just easier for now)
  * Security: None (802.1x disable)
  * (Adding a gateway leads to tons of ARPs for 192.168.1.1)
  * Upon enabling the connection we get a bunch of packets:
    * IGMPv3 join for 224.0.0.251
    * ARP announcement for 192.168.0.133
    * A bunch of MDNS

* Disable MDNS on wired ethernet (Avahi)
  * `/etc/avahi/avahi-daemon.conf` and add the interface to `deny-interfaces`

* With the network configuration above, and removing MDNS (Avahi), you now get a very
  quiet interface: Just a few ARP announcements. Then you can just use `arping` to generate
  random packets.

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
* [Ethernet Carrier Extension](https://www.cse.wustl.edu/~jain/cis788-97/ftp/gigabit_ethernet/index.html#CAR)

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

* Ethernet Errors
  * [TX_ER Question](https://electronics.stackexchange.com/questions/261123/gmii-rgmii-tx-er-signal-guaranteed-functionality)

* Packet Generator - section 2.21 (uses 12 bytes of IPG, 8 bytes of preamble)


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

Section 1.5 shows the Reset Modes (specifically Hardware & Software reset)
* Reg 16.3 defaults to active for RX_CLK
* Hardware reset stops MDIO but software reset keeps it active (!)

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

## Learnings

* Hardware reset will set all register values to default
  * So if you do hardware reset, after setting Register 20 bits 7 & 1, you
    need to reset them
* The link down MAC RX interface speed seems to depend on Register 20 bits 6-4,
  which defaults to 110 on my DE2-115


## Questions


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


## 88E1111 Controller

Notes on resets:

* 2.10 says: "The 88E1111 device will be available for read/write operations 5 ms after hardware reset."
  * Unclear if that means for TWSI only or all operations.
* Table 59, bit 15, says when the software reset is complete, the bit will be cleared
  * So we can monitor for reset complete by polling this
* 4.8.1 shows Reset Timings
  * Do a reset for 10ms after valid power
  * Do at least 10 cycles of the (Ethernet) clock before deasserting reset
  * Assert reset for at least 10ms during normal operation
  * 5ms after reset ends you can use MDIO

Controller operation:

* Reset
  * Implement this as hard reset of PHY
* Initial startup:
  * Start & hold reset 10ms (call it 15 for good measure)
  * Deassert PHY reset
  * Wait 5ms to get to MDIO capability (call it 7.5ms for good measure)
* Configuration:
  * Set PHY-side TX_CLK/RX_CLK delays (so we can just read/write "synchronously" on the FPGA)
    * Read Register 20 (0x14)
    * Set bits 7 & 1 and write it
    * Confirm those bits are set
    * Read Register 0
    * Set bit 15 & write it
    * Wait n MS for soft reset
    * Read Register 0 every so often until bit 0 is off
  * Indicate "Ethernet Ready"
* Normal operation:
  * Offer MDIO Mangement Interface so it can handle read/write requests
  * Occasionally read the status and export them as output signals
    * Link connected
    * Speed
    * Duplex
    * (Note: The ETH RX will get this using in-band signaling)
* FUTURE: Handle interrupts
  

# Misc Quartus Notes

* VS Code as external editor: `"C:\Users\Doug\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd" --goto %f:%l`
  * You cannot insert HDL template without using the internal editor, so sometimes this needs to change
* Questa directory: `C:/bin/fpga/intelFPGA_lite/21.1/questa_fse/win64`



# 16x2 LCD

This is now working - see `lcd_module` - but doesn't do initialization yet.

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