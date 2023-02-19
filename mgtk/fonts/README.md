# MouseGraphics Fonts

This is a collection of fonts that work with MGTK.

The `bin/convert_font.pl` tool can be used to convert a 768-byte HiRes
Character Generator (HRCG) font to MTGK format. Several are included
below, from the Applesoft Toolkit 1.0 by Apple, 1980.

The `bin/dump_font.pl` tool can be used to preview a font, displaying
an ASCII rendition of the pixels on the console.

The `bin/make_font.pl` tool can be used to reverse the process, and
take a textual representation of a font and convert it back to a
binary representation.

If these are transferred to an Apple disk and changed to file type $07
(FNT) then the `SHOW.FONT.FILE` preview accessory can show them in
DeskTop.

Font Name    | Origin           | Width  | Height
------------ | ---------------- | ------ | ------
System.en    | Apple II DeskTop | Single | 9
System.fr    | MouseDesk 2.0 fr | Single | 9
System.de    | MouseDesk 1.0 de | Single | 9
System.it    | MouseDesk 1.0 it | Single | 9
System.pt    | custom           | Single | 9
System.es    | custom           | Single | 9
System.sv    | custom           | Single | 9
System.da    | custom           | Single | 9
Monaco.*     | custom           | Single | 9
MP.FONT      | MousePaint       | Single | 9
ATHENS       | MousePaint       | Double | 12
NEW.YORK     | MousePaint       | Double | 11
TORONTO      | MousePaint       | Double | 11
VENICE       | MousePaint       | Double | 10
ASCII        | HRCG             | Single | 8
BLIPPO.BLACK | HRCG             | Single | 8
BYTE         | HRCG             | Single | 8
COLOSSAL     | HRCG             | Single | 8
COUNT        | HRCG             | Single | 8
FLOW         | HRCG             | Single | 8
GOTHIC       | HRCG             | Single | 8
MIRROR       | HRCG             | Single | 8
OUTLINE      | HRCG             | Single | 8
PINOCCHIO    | HRCG             | Single | 8
PUDGY        | HRCG             | Single | 8
ROMAN        | HRCG             | Single | 8
SLANT        | HRCG             | Single | 8
STOP         | HRCG             | Single | 8
UPSIDE.DOWN  | HRCG             | Single | 8
mini         | custom           | Single | 8
PIG.FONT     | "The Pig Sty"    | Single | 8

Single width fonts can be 1-7 pixels wide. Double width fonts can be
1-14 pixels wide. Glyphs must include inter-character spacing
(kerning); MGTK does not add this. This allows special glyphs to be
used to produce small graphics, similar to MouseText's folder glyphs.
