;;; ============================================================
;;; Definitions that apply to DeskTop and Selector
;;; ============================================================

kDeskTopVersionMajor = 1
kDeskTopVersionMinor = 2
.define kDeskTopVersionSuffix "-alpha11"
.define kDeskTopReleaseDate "March 12, 2020"

;;; ============================================================

kScreenWidth    = 560
kScreenHeight   = 192

kMenuBarHeight  = 13
kTitleBarHeight = 12

;;; Standard button sizes; sometimes narrower
kButtonWidth  = 100
kButtonHeight = 11

;;; Mouse threshold for double click detection.
kDoubleClickDeltaX      = 5
kDoubleClickDeltaY      = 4

;;; ============================================================
;;; Selector List file

;;; See docs/Selector_List_Format.md for file format.

kSelectorListNumRunListOffset   = 0
kSelectorListNumOtherListOffset = 1
kSelectorListEntriesOffset      = 2
kSelectorListPathsOffset        = 2 + 24 * 16

kSelectorEntryFlagsOffset       = $F
kSelectorEntryCopyOnBoot        = $00
kSelectorEntryCopyOnUse         = $80
kSelectorEntryCopyNever         = $C0

;;; This much is consistently reserved/written.
kSelectorListBufSize = $800

;;; ============================================================
;;; Settings Config File

kDefaultDblClickSpeed   = $12C
kDefaultIPBlinkSpeed    = 60

.struct DeskTopSettings
        version_major   .byte
        version_minor   .byte
        pattern         .res 8
        dblclick_speed  .word
        ip_blink_speed  .byte

        reserved        .res 115
.endstruct
        .assert .sizeof(DeskTopSettings) = $80, error, .sprintf("Expected $80, was $%0X", .sizeof(DeskTopSettings))

;;; ============================================================
;;; RAM Disk

;;; UnitNum used by Glen E. Bredon's RAM.DRV.SYSTEM
;;; RAM disk driver for RamWorks.
kRamDrvSystemUnitNum = $3E

;;; On startup, DeskTop will copy itself (including resources) and
;;; (optionally) selector entries to a RAM disk if available. Flags
;;; are set and the original/new prefixes to DeskTop are maintained.
;;; These are stored in the custom ProDOS QUIT routine area in Main
;;; LCBANK2.

;;; 16 bytes $D395-$D3A4 - set to $FF when entry is copied to RAM disk.
ENTRY_COPIED_FLAGS      := $D395

DESKTOP_ORIG_PREFIX     := $D3AD
RAMCARD_PREFIX          := $D3EE

;;; $00 = no ramcard found
;;; $C0 = ramcard found, but not copied (internal state)
;;; $80 = ramcard found, DeskTop copied
COPIED_TO_RAMCARD_FLAG  := $D3FF

;;; ============================================================
;;; Default Font

;;; Control Character Glyphs
;;;
;;; Glyphs $00-$1F are useful symbols; some overlap with MouseText
;;; (called out as MT:X in the table below)
;;;
;;; $00 = space                $10 = TM left
;;; $01 = folder left  (MT:X)  $11 = TM right
;;; $02 = folder right (MT:Y)  $12 = pound
;;; $03 = hourglass    (MT:C)  $13 = pi
;;; $04 = insertion pt         $14 = divide
;;; $05 = pointer      (MT:B)  $15 = rarrow       (MT:U)
;;; $06 = vbar         (MT:_)  $16 = tri
;;; $07 = hbar         (MT:S)  $17 = open circ
;;; $08 = larrow       (MT:H)  $18 = close        (MT:])
;;; $09 = left box             $19 = gray odd     (MT:W)
;;; $0A = darrow       (MT:J)  $1A = gray even    (MT:V)
;;; $0B = uarrow       (MT:K)  $1B = solid circ
;;; $0C = right box            $1C = inv check    (MT:E)
;;; $0D = return       (MT:M)  $1D = check        (MT:D)
;;; $0E = (C)                  $1E = solid apple  (MT:@)
;;; $0F = (R)                  $1F = open apple   (MT:A)

kGlyphFolderLeft        = $01
kGlyphFolderRight       = $02

kGlyphSpacer            = $00
kGlyphInsertionPoint    = $06

kGlyphLeftArrow         = $08
kGlyphRightArrow        = $15
kGlyphUpArrow           = $0B
kGlyphDdownArrow        = $0A
kGlyphReturn            = $0D
kGlyphOpenApple         = $1F
kGlyphSolidApple        = $1E

;;; Menu (by default) uses:
;;;   Solid Mod   $1E
;;;   Open Mod    $1F
;;;   Check       $1D
;;;   Control     $01
;;;   Inactive    $7F
