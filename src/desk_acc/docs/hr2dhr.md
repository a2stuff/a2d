# Hires to Double-Hires Conversion

## Background

You can ignore color and just think about mapping to the 560x192 black and white
display, since at that level HR and DHR are identical. NTSC magic translates the
560x192 pattern into color, so if you get B&W correct you'll get color correct.
(Mostly...)

Hires uses the lower 7 bits per byte directly (bit 0 on the left of the screen).
7 pixels/byte * 40 bytes per row gives 280 pixels per row. If the 8th bit is set
that set of 7 pixels is shifted right by half a pixel. This gives a resolution of
560 pixels per row, although most patterns cannot be set.

Double hires also uses the lower 7 bits. 7 pixels/byte * 80 bytes per row gives
560 pixels per row. The 8th bit in each byte is complete ignored. For added
fun, bytes alternate between aux mem and main memory. But we want to reason
about byte pairs anyway, since we're mapping one hires byte to 2 dhr bytes.

Finally, the low bit in each byte is the left-most on the screen, so
it's easiest to describe the bits backwards. That is, `$01` is written
as `10000000` instead of `00000001`.

## Conversion - Theory

If everything was simple, the conversion process would be: for every
row in the screen, convert the 40 HR bytes to 80 DHR bytes by doubling
the bits. Naming the left-most (lowest) visible bit `a` and the
right-most (highest) visible bit `g`, the doubling appears as:

`abcdefg0` → `aabbccd_` `deeffgg_`

Where `_` signals that we don't care about the high bit on the
double-hires display, as it is not used.

There are multiple complications:

### Palette Bit Shift

As noted, if the high bit in an HR byte is set then there is a
half-pixel shift to the right:

`abcdefg1` → `Xaabbcc_` `ddeeffg_`

A bit `X` needs to be shifted in from the left. This bit has the same
value as the rightmost bit in the previous byte.

* If the previous byte had high bit set then it the repetition of the
  `g` bit that didn't fit.

* If the previous byte had high bit clear then this is a repetition of
  its final `g` - it is stretched out to cover 3 bits.

* If there was no previous byte, i.e. the left-most byte on the
  screen, then it is 0.

Following the above logic reproduces the highres monochrome display
exactly on the double highres display. But if viewed on a color
display the colors will be wrong!

### 80-Column Shift

On the Apple II (except the IIgs) the 80-column hardware display
starts 7 "pixels" earlier than the 40-column display, and this affects
single-hires and double-hires as well. Emulators often skip this
detail, but it is present on real hardware. It matters here because
the way that color is derived from the monochrome bitmap depends on
how the NTSC color clock aligns with the bitmap. The color clock cycle
is 4 monochrome bits wide, so 4-bit wide patterns produce colors. But
*which* 4 bits depend on the alignment with the color, not just the
width. So while the monochrome 560 bitmap starting with 11001100...
yields purple in single-highres, it yields blue in double-hires!

This is because of the double-hires display starting 7 "pixels"
earlier; the pattern has shifted by 7 pixels relative to the color
clock. Since the color clock is 4 bits wide, it is necessary to shift
the pattern left by one bit or right by 3 bits to align correctly and
produce purple as expected.

Taking the previous exact conversion of the single-highres monochrome
screen to double-highres, then shifting everything one bit left will
yield a correct color conversion of the single-hires screen to double
hires.

This necessarily results in discarding the leftmost bit ("pixel") on
the screen; the alternative is to discard the rightmost three bits
("pixels").

### Summary

Recapping, a color conversion can be done by iterate the screen top to
bottom, and for each row:

1. Process bytes left to right, converting each single-hires bytes
   into a pair of double-hires bytes, possibly shifting in a bit on
   the left, and storing rightmost bit if needed for the next byte.

2. Process bytes right to left, shifting the visible 7 bits one to the
   left.

... while remembering that "left" and "right" refer to how bits are
presented on the display. Shifting left will require a `ROR`
instruction, and vice versa.

## Conversion - Practice

The above conversion can be done bit by bit, but as usual it can
be accelerated using lookup tables.

A key observation is that on each row we first work left to right,
possibly propagating a bit to the right. Then we work right to left,
always propagating a bit to the left. These two steps can be combined,
working from right to left and possibly propagating a bit to the left.

The previous rule for doubling each single-hires byte:

* `abcdefg0` → `aabbccd_` `deeffgg_`
* `abcdefg1` → `Xaabbcc_` `ddeeffg_`

When the addition left-shift is considered, becomes:

* `abcdefg0` → `abbccdd_` `eeffggX_`
* `abcdefg1` → `aabbccd_` `deeffgX_`

We pre-compute a table using this logic for all 256 source bytes to
two destination bytes.

There are two cases:

* If the previous byte's high bit was also clear, then `X` is `a` from
  the *previous* byte (shifted).

* If the previous byte's high bit was set, then `X` is `g` from the
  *current* byte (stretched).

Again, working from right to left, so "previous" means the byte to the
right.

