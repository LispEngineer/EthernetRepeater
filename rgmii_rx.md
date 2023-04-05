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


Testing/Debugging:

* There is a "bogus" function you can enable that generates
  packets randomly, to test RAM & FIFO functionality
  as well as top level functionality, if desired, without
  being connected to any PHY.
* There is an test_rgmii_rx testing module that tests the
  top level (bogus enabled recommended). This uses another
  module, the test_packet_receiver that reads the FIFO and
  just makes sure that the
  RAM is readable and has the expected "bogus" contents.

# TODO

* Implement the handling of RX_DV off, to determine the
  input speed, duplex and carrier status. See:
  * RGMII 2.0 Spec Table 4
  * Marvell Datasheet 2.2.3.2
  * Output the status as signals; speeds as 1-hot

# Notes on RGMII 2.0 Spec

* See Table 4 for when RX_DV and _ERR are 0:
  * Link up/down
  * Clock speed: 2.5, 25, 125
  * Duplex
  * --> We can use this to decide to read DDR nor not before
    any particular packet! So, we can remove the ddr flag input?
  * Marvell 88E1111 Datasheet (Rev. M) implies that they do the
    optional in-band signaling in section 2.2.3.2.

# Open Questions

* When RX_DV (first half of RX_CTL) goes true, does that mean
  we need to sample the data that same exact cycle, for receipt?
  If so, that makes our state machine a little interesting, as we
  are in one state but doing the next state's work.