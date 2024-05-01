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

Font Name     | Origin            | Width  | Height
------------- | ----------------- | ------ | ------
System.en     | Apple II DeskTop  | Single | 9
System.fr     | MouseDesk 2.0 fr  | Single | 9
System.de     | MouseDesk 1.0 de  | Single | 9
System.it     | MouseDesk 1.0 it  | Single | 9
System.*      | custom            | Single | 9
Monaco.*      | custom            | Single | 9
MousePaint    | MousePaint        | Single | 9
Athens        | MousePaint        | Double | 12
New.York      | MousePaint        | Double | 11
Toronto       | MousePaint        | Double | 11
Venice        | MousePaint        | Double | 10
hrcg/*        | Applesoft Toolkit | Single | 8
mini          | custom            | Single | 8
Pig.Font      | "The Pig Sty"     | Single | 8
Fairfax.*     | Kreative Software | Single | 12
FairfaxBd.*   | Kreative Software | Single | 12
FairfaxIt.*   | Kreative Software | Single | 12
FairfaxSf.*   | Kreative Software | Single | 12
Magdalena.*   | Kreative Software | Double | 16
MagdalenaBd.* | Kreative Software | Double | 16
McMillen.*    | Kreative Software | Double | 16
McMillenBd.*  | Kreative Software | Double | 16
Mischke.*     | Kreative Software | Double | 16
MischkeBd.*   | Kreative Software | Double | 16
Monterey.*    | Kreative Software | Double | 16
MontereyBd.*  | Kreative Software | Double | 16
Catalyst      | Quark Software    | Double | 8

Single width fonts can be 1-7 pixels wide. Double width fonts can be
1-14 pixels wide. Glyphs must include inter-character spacing
(kerning); MGTK does not add this. This allows special glyphs to be
used to produce small graphics, similar to MouseText's folder glyphs.

The `System.latin1` and `Monaco.latin1` files are fonts with 256
glyphs representing the ISO-8859-1 (Latin-1) code page. These are used
with the `bin/build_fonts_from_latin1.pl` script which generates the
per-language fonts. This eases maintenance of the fonts.
