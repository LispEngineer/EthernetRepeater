# Debugging Notes 1

First packet transmitted!

This packet was received with a CRC error and a length error, per the counters
in my Ubuntu 22 LTS.

![First Packet](FirstPacket.png)

`f5ffffffffff6f0037f2fbfb1b600080000060200080600037f2fbfb0b08f4fb0b0000000000f0ffffff0f000000000000000000000000000000a0ded0c2`

Here is what was received:
```
f5 ff ff ff ff ff
6f 00 37 f2 fb fb
1b 60 
00 80
00 00 
60
20
00 80
60 00 37 f2 fb fb
0b 08 f4 fb
0b 00 00 00 00 00
f0 ff ff ff 
0f 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00
a0 de d0 c2
```

Here's what we were trying to send:
```
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
75 0B 4B 43 (or maybe it's the other way around)
```

Some conclusions:
* It got the correct number of bytes
* It looks like both the nibbles AND the bit order may be wrong
  * FB = 1111_1011
  * DF = 1101_1111
  * 20 = 0010_0000
  * 04 = 0000_0100
* Looks like some of the bits aren't transmitted/received correctly