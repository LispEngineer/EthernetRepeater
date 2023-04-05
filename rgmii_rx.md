# RGMII Receiver Documentation

Modules:

* `rgmii_rx` is the top level, which also handles instantiating
  the necessary RAM and FIFO. This is a multi-clock module since
  the RAM & FIFO & RGMII receiver all can be in different clock
  domains (and the RAM/FIFO are dual domain).
* `rgmii_rx_impl` is the meat of the RGMII receiver implementation,
  but takes as input RAM and FIFOs to use, clocked with the same
  clock as the rest of the module

Misc notes:

* Receive clock should be 90 degrees delayed from the
  actual RX_CLK from the PHY.
* Inputs from PHY that are DDR should be pre-decoded
  before sending to this module.
* This module has a N-port frame buffer, where N is a
  power of two. It receives into this buffer in a
  circular queue. It receives the whole Ethernet
  frame, including Preamble, SFD, data and CRC.
  Each entry in the buffer is 2kB (11 bits) so it's easy to
  address the proper buffer entry.
* When it's done receiving a packet, it puts into
  a (dual clock) FIFO:
  * Buffer entry number - 3 bits
  * Packet length       - 11 bits (maximum 2047)
  * TODO: CRC Check OK  - 1 bit
  * TODO: Frame Error   - 1 bit
  * TOTAL: 16 bits
  * Format: {crc_error, frame_error, buffer_num, packet_len}
  * FIFO length is the same as the # of buffer entries.
* The receiver can take stuff out of the FIFO whenever
  it wants. :)