;;; ============================================================
;;; Definitions that apply to DeskTop and Selector
;;; ============================================================

        .include .concat("common/res/common.res.", kBuildLang)

;;; ============================================================
;;; Filenames

.define kFilenameLauncher      "DeskTop.system"
.define kFilenameDeskTop       "DeskTop2"
.define kFilenameSelector      "Selector"
.define kFilenameSelectorList  "Selector.List"
.define kFilenameDeskTopConfig "DeskTop.config"
.define kFilenameDeskTopState  "DeskTop.file"
.define kFilenameDADir         "Desk.Acc"
.define kFilenamePreviewDir    "Preview"
.define kFilenameQuitSave      "Quit.tmp"
.define kFilenameRAMCardDir    "DeskTop"

;;; ============================================================

;;; For addresses that will be filled in at runtime.

SELF_MODIFIED   = $1234            ; To avoid ZP addressing mode

;;; ============================================================

kMaxPathLength  = 64
kPathBufferSize = 65
kDirStackBufferSize = 170

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

kSelectorListNumRunListEntries  = 8
kSelectorListNumEntries         = 24
kSelectorListNameLength         = 16
kSelectorListPathLength         = 64

kSelectorListNumRunListOffset   = 0
kSelectorListNumOtherListOffset = 1
kSelectorListEntriesOffset      = 2
kSelectorListPathsOffset        = kSelectorListEntriesOffset + kSelectorListNumEntries * kSelectorListNameLength

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
        clock_24hours   .byte   ; $00 = 12 hour, $80 = 24 hour
        rgb_color       .byte   ; $00 = B&W, $80 = Color
        mouse_tracking  .byte   ; 0 = normal, 1 = 2x speed

        startup_ramcard .byte   ; $00 = copy to RAMCard on startup, $80 = skip
        startup_selector .byte  ; $00 = start Selector if present, $80 = skip

        reserved        .res 110
.endstruct
        .assert .sizeof(DeskTopSettings) = $80, error, .sprintf("Expected $80, was $%0X", .sizeof(DeskTopSettings))

;;; ============================================================
;;; Alert library options

;;; Button options
;;; $C0 (%11xxxxxx) = Cancel + Ok
;;; $81 (%10xxxxx1) = Cancel + Yes + No
;;; $80 (%10xx0000) = Cancel + Try Again
;;; $00 (%0xxxxxxx) = Ok
;;; Note: Wrapper APIs that take A=id, X=options use X=0 to mean
;;; "use default options for that id", otherwise X & %00000001.
.enum AlertButtonOptions
        OkCancel       = $C0
        YesNoCancel    = $81
        TryAgainCancel = $80
        Ok             = $00
.endenum

.enum AlertOptions
        Beep       = %10000000  ; N = play beep sound
        SaveBack   = %01000000  ; V = save/restore background
.endenum

;;; ============================================================
;;; Offsets into launcher

kLauncherDateOffset     = 3

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

;;; 24 bytes - flags for each entry, set to $FF when copied to RAM disk.
ENTRY_COPIED_FLAGS      := $D395

;;; 65 bytes - original prefix DeskTop was loaded with (e.g. "/HD/A2D")
DESKTOP_ORIG_PREFIX     := $D3AD

;;; 17 bytes - prefix for RAMCard (e.g. "/RAM")
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
kGlyphCheckmark         = $1D

;;; Menu (by default) uses:
;;;   Solid Mod   $1E
;;;   Open Mod    $1F
;;;   Check       $1D
;;;   Control     $01
;;;   Inactive    $7F

;;; ============================================================
;;; Macros (specific to this project)

.macro DEFINE_BUTTON_COORDS ident, xpos, ypos, width, height
.if .paramcount > 3
        DEFINE_RECT_SZ .ident(.sprintf("%s_button_rect", .string(ident))), (xpos), (ypos), width, height
.else
        DEFINE_RECT_SZ .ident(.sprintf("%s_button_rect", .string(ident))), (xpos), (ypos), kButtonWidth, kButtonHeight
.endif
        DEFINE_POINT .ident(.sprintf("%s_button_pos", .string(ident))), ((xpos) + 5), ((ypos) + 10)
.endmacro
.macro DEFINE_BUTTON ident, label, xpos, ypos, width, height
.if .paramcount > 4
        DEFINE_BUTTON_COORDS ident, xpos, ypos, width, height
.else
        DEFINE_BUTTON_COORDS ident, xpos, ypos
.endif
        .ident(.sprintf("%s_button_label", .string(ident))) := *
        PASCAL_STRING {label}
.endmacro

.macro DEFINE_LABEL ident, label, xpos, ypos

        DEFINE_POINT .ident(.sprintf("%s_label_pos", .string(ident))), (xpos), (ypos)
        .ident(.sprintf("%s_label_str", .string(ident))) := *
        PASCAL_STRING {label}
.endmacro
