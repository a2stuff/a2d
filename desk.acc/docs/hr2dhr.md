# Hires to Double-Hires Conversion

## Background

You can ignore color and just think about mapping to the 560x192 black and white
display, since at that level HR and DHR are identical. NTSC magic translates the
560x192 pattern into color, so if you get B&W correct you'll get color correct.
(Mostly...)

Hires uses the lower 7 bits per byte directly (bit 0 on the left of the screen).
7 pixels/byte * 40 bytes per row gives 280 pixels per row. If the 8th bit is set
that set of 7 pixels is shifted by half a pixel. This gives a resolution of 560
pixels per row, although most patterns cannot be set.

Double Hires also uses the lower 7 bits. 7 pixels/byte * 80 bytes per row gives
560 pixels per row. The 8th bit in each byte is complete ignored. For added
fun, bytes alternate between aux mem and main memory. But we want to reason
about byte pairs anyway, since we're mapping one hires byte to 2 dhr bytes.

## Conversion

### Easy Case

Hires bytes with the high bit set turn out to be the easy case. The source
7 bits are basically just doubled up and then split with 7 going into each
destination byte. We'll visualize that with the byte patterns for blue/orange:
```
source byte:     0xD5                    |    0xAA
source bits:     0b11010101              |    0b10101010
hr pixels:       1  0  1  0:  1  0  1    |    0  1  0  1:  0  1  0
dhr pixels:      11 00 11 0:0 11 00 11   |    00 11 00 1:1 00 11 00
dest bits:       0b_1100110 0b_1100110   |    0b_1001100 0b_0011001
dest bytes:      0x66       0x66         |    0x4C       0x19
```
To read that table, remember that bits/pixels are in reverse order.
Also, the high destination bit doesn't matter; this wil prove useful later.

### Hard Case

When the high bit is _not_ set, the source pixels are shifted a
half-pixel *right*, here shown by shifting the dhr pixels *left*.
We'll visualize this using the byte patterns for violet/green:

```
source byte:     0x55                    |    0x2A
source bits:     0b01010101              |    0b00101010
hr pixels:       1  0  1  0:  1  0  1    |    0  1  0  1:  0  1  0
dhr pixels:   (1)1 00 11 00: 11 00 11(?) | (0)0 11 00 11: 00 11 00(?)
dest bits:       0b_0011001 0b_?110011   |    0b_1100110 0b_?001100
dest bytes:      0x19       0x33 | ?<<7  |    0x66       0x06 | ?<<7
```

This means we're dropping a bit on the left - shown in parentheses -
and have an unknown bit on the right - shown as ?. Visualizing it this
way solves the mystery: when the high bit is clear in the hires bytes,
a bit "spills" from each dhr pixel pair into the pixel pair to the left.
Doing this will preserve the original 560 B&W pixel pattern.

### Conversion Algorithm

We pre-compute a table using this logic for all 256 source bytes to
two destination bytes.

This "spilling" means we cannot simply convert all 8192 bytes in order;
we need to process each row 40 bytes at a time. (Bonus - we preserve
screen holes!) Instead, we start at the right edge of the screen, get
the source byte, and look up the two destination bytes - one table for
the left (aux) byte, one for the right (main) byte.

If the high bit of the source byte is _set_ we're in the easy case and
so we're done - we have the two destination bytes.

If the high bit of the source byte is _clear_ we're in the harder case.
We need to spill a bit _in_ and a bit _out_. We saved the bit we're spilling
_in_ from the previous iteration, so we `ORA` that into place. (Aside: that
means we reset the spill bit both at the start of each row _and_ if the
previous source byte had the high bit set.)

To know what bit to spill _out_ we sneakily look at the otherwise unused
high bit of the _destination byte_ from the table. The code which constructs
the mapping table slips it into place there. (I said it would be useful.)

## Edge Cases

Astute readers will note that if high bits are clear in the source (i.e. the
green/violet palette is used) we have some apparent problems.

* For the right-most pixel we don't have anything to spill in; it will be left as 0.
* The left-most pixel spills out and is ignored.

So far as I can tell, this doesn't cause an actual problem in most cases. This
effect is below the effective resolution of the hires display, should at most
alter the NTSC color fringes that occur on the screen edges. Samples demonstrating
actual problems are welcome.

I also haven't experimented in detail, e.g. with things like the infamous
"orange squeeze out" where vertical orange lines on byte boundaries disappear.
In theory the same effect should be present here since we started from
first-principles but practice may differ.
