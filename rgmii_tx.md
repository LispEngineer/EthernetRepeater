# RGMII Transmitter

Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved.

# Current Capabilities

First version: Just send a fixed packet.

* [Interpacket Gaps](https://en.wikipedia.org/wiki/Interpacket_gap)
* [SystemVerilog Streaming Operators](https://www.amiq.com/consulting/2017/05/29/how-to-pack-data-using-systemverilog-streaming-operators/#reverse_bits)
  * Unfortunately [Quartus](https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/mapIdTopics/jka1465580570693.htm) does not support these

Convert a file of hex bytes (with possible leading spaces) into a ROM:

    sed 's/^ *//' <x | tr ' ' '\n' | nl -v 0 | sed "s/\t/: val = 8'h/" | sed 's/$/;/' | sed s"/^ */6'd/"

# TX Data sending order

## 10BASE-T (2.5MHz) RGMII mode

* Send one nibble each cycle (not two) - same on H and L of clock
* For Preamble & SFD:
  * Send the exact data as shown in 802.3-2022 Table 22-3on TXD[0:3]
  * This is erversed from the bit sequence
* For data, send the lower nibble first, with the txd bits in same order as data bits
* Overall, this is not documented clearly or perfectly anywhere.
  * Specifically, it seems the order of TXD bits is opposite in preamble/SFD
    vs. the rest of the data packet.
  * The 802.3-2022 has section 22.2.3 with Figure 22-13, but that
    is confusing. Table 22-3 tries to help. Why not just say it clearly
    in plain English?
* Reduced Gigabit Media Independent Interface (RGMII) Version 2.0 4/1/2022
  is not helpful either. (Broadcom, HP, Marvell)

# Code Notes

* `FLIP_BITS` macro, if defined, will send the bits in each nibble out in backwards order
  from how they are in tx_data.
  * Not yet sure which one is correct