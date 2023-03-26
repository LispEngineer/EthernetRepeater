# RGMII Transmitter

Copyright ⓒ 2023 Douglas P. Fields, Jr. All Rights Reserved.

# Current Capabilities

First version: Just send a fixed packet.

* [Interpacket Gaps](https://en.wikipedia.org/wiki/Interpacket_gap)
* [SystemVerilog Streaming Operators](https://www.amiq.com/consulting/2017/05/29/how-to-pack-data-using-systemverilog-streaming-operators/#reverse_bits)
  * Unfortunately [Quartus](https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/mapIdTopics/jka1465580570693.htm) does not support these

Convert a file of hex bytes (with possible leading spaces) into a ROM:

    sed 's/^ *//' <x | tr ' ' '\n' | nl -v 0 | sed "s/\t/: val = 8'h/" | sed 's/$/;/' | sed s"/^ */6'd/"

# Code Notes

* `FLIP_BITS` macro, if defined, will send the bits in each nibble out in backwards order
  from how they are in tx_data.
  * Not yet sure which one is correct