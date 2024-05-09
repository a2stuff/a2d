Apple File Type Notes:

* https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/ftyp/ft.about.html

Modern registry:

* https://github.com/a2infinitum/apple2-filetypes
* https://docs.google.com/spreadsheets/d/1HIg5f1gispUvO0r8t6SEww8XM41eUAtn7wkNNDrNPtQ/edit

Other listings:

* https://www.kreativekorp.com/miscpages/a2info/filetypes.shtml
* https://macgui.com/kb/article/116

DeskTop-internal types:

* $F1 / $0000 - Desktop Module (not really used though)
* $F1 / $0642 - Desk Accessory

Proposed types:

* $08 FOT / $8066 - LZ4FH image - https://github.com/fadden/fhpack
* $5B ANM / $10xx - Animation / Video stream - https://github.com/frankmilliron/play.vids.system
  * $1001 - GR - sequence of $400-byte frames
  * $1002 - DGR - sequence of $800-byte frames (aux first)
  * $1003 - HGR - sequence of $2000-byte frames
  * $1004 - DHGR - sequence of $4000-byte frames (aux first)
* $D5 MUS / $D0E7 - Music Sequence / Electric Duet - https://github.com/a2infinitum/apple2-filetypes/issues
* $D8 SND / $10xx - Sampled Sound - Zero-Crossing (ZC) - https://github.com/frankmilliron/play.zc.system
* $D8 SND / $330x - Sampled Sound - Binary Time constant (BTC) - https://github.com/frankmilliron/play.zc.system
  * $3300 - includes cover art
  * $3301 - no cover art
* $D9 TTS / ????? - Text-to-Speech
* $E1 LNK / $0001 - Link - [definition](../../docs/Link_File_Format.md)
