# RGMII Transmitter

Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved.

# Current Capabilities

* Send a fixed MII packet with calculated CRC

## TODO

* [Interpacket Gaps](https://en.wikipedia.org/wiki/Interpacket_gap)
* DDR (RGMII) data sending

## Notes

Convert a file of hex bytes (with possible leading spaces) into a ROM:

    sed 's/^ *//' <x | tr ' ' '\n' | nl -v 0 | sed "s/\t/: val = 8'h/" | sed 's/$/;/' | sed s"/^ */6'd/"

# TX Data sending order

## 10BASE-T (2.5MHz) RGMII mode

* Send one nibble each cycle (not two) - same on H and L of clock
* For Preamble & SFD:
  * Send the exact data as shown in 802.3-2022 Table 22-3on TXD[0:3]
  * This is reversed from the bit sequence
  * See [Ethernet frame](https://en.wikipedia.org/wiki/Ethernet_frame) section
    Preamble and start frame delimiter, which shows that the bits (1010 ... 1010 1011)
    are actually hex values 0x55 .. 0x55 0xD5. I wish the other specs had shared this
    tidbit earlier, would have saved a lot of sadness.
* For data, send the lower nibble first, with the txd bits in same order as data bits
* Overall, this is not documented clearly or perfectly anywhere.
  * Specifically, it seems the order of TXD bits is opposite in preamble/SFD
    vs. the rest of the data packet.
  * The 802.3-2022 has section 22.2.3 with Figure 22-13, but that
    is confusing. Table 22-3 tries to help. Why not just say it clearly
    in plain English?
* Reduced Gigabit Media Independent Interface (RGMII) Version 2.0 4/1/2022
  is not helpful either. (Broadcom, HP, Marvell)
* The Ethernet Frame minimum size of 64 bytes does NOT include the preamble
  or SFD, but it DOES include the FCS (checksum). So short packets like ARP
  need to have plenty of extra padding.

# Code Notes
