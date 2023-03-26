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
* First nibble (of each byte) sent should be the high nibble, bits 7:4
  * Followed by the low nibble, bits 3:0
* The `tx_data_h`/`_l` signals have their bits reversed compared to
  the original data nibbles.
  * I cannot find this documented clearly or perfectly anywhere.
    The 802.3-2022 has section 22.2.3 with Figure 22-13, but that
    is confusing. Table 22-3 tries to help. Why not just say it clearly
    in plain English?

# Code Notes

* `FLIP_BITS` macro, if defined, will send the bits in each nibble out in backwards order
  from how they are in tx_data.
  * Not yet sure which one is correct