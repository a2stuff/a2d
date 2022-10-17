;;; ============================================================
;;; Definitions that apply to DeskTop and Selector
;;; ============================================================

.define DEBUG 0

        .include .concat("common/res/common.res.", kBuildLang)

;;; ============================================================
;;; Filenames

.define kFilenameLauncher      "DeskTop.system"
.define kFilenameModulesDir    "Modules"
.define kFilenameDeskTop       .concat(kFilenameModulesDir, "/DeskTop2")
.define kFilenameDiskCopy      .concat(kFilenameModulesDir, "/Disk.Copy")
.define kFilenameSelector      .concat(kFilenameModulesDir, "/Selector")
.define kFilenameLocalDir      "Local"
.define kFilenameSelectorList  .concat(kFilenameLocalDir, "/Selector.List")
.define kFilenameDeskTopConfig .concat(kFilenameLocalDir, "/DeskTop.config")
.define kFilenameDeskTopState  .concat(kFilenameLocalDir, "/DeskTop.file")
.define kFilenameBellProc     .concat(kFilenameLocalDir, "/Bell.proc")
.define kFilenameQuitSave      .concat(kFilenameLocalDir, "/Quit.tmp")
.define kFilenameDADir         "Desk.Acc"
.define kFilenamePreviewDir    "Preview"
.define kFilenameExtrasDir     "Extras"
.define kFilenameRAMCardDir    "DeskTop"

;;; ============================================================

;;; For addresses/values that will be filled in at runtime.

SELF_MODIFIED   = $1234          ; To avoid ZP addressing mode
SELF_MODIFIED_BYTE = $12

;;; ============================================================

kMaxPathLength  = 64
kPathBufferSize = 65
kDirStackBufferSize = 64        ; max of 32 levels
kMaxFilenameLength = 15

;;; ============================================================
;;; Metrics

kScreenWidth    = 560
kScreenHeight   = 192

;;; Prefer DEFAULT_FONT+MGTK::Font::height, but that's not always convenient.
kSystemFontHeight = 9

kMenuBarHeight  = kSystemFontHeight+4

;;; Standard button sizes; sometimes narrower
kButtonWidth  = 100
kButtonHeight = kSystemFontHeight+2
kButtonTextHOffset = 5                   ; from left edge of rect to text pos
kButtonTextVOffset = kSystemFontHeight+1 ; from top edge of rect to text pos

;;; Horizontal distance for label/control pairs
kLabelHOffset = 3

;;; Standard line edit (text input) control metrics
kTextBoxHeight = kSystemFontHeight+2
kTextBoxTextHOffset = 5                   ; from left edge of rect to text pos
kTextBoxTextVOffset = kSystemFontHeight+1 ; from top edge of rect to text pos

;;; Standard list box control metrics
kListItemHeight = kSystemFontHeight+1
kListItemTextOffsetX = kTextBoxTextHOffset
kListItemTextOffsetY = kListItemHeight - 1

;;; File lists
kListViewIconWidth = 14
kListViewIconGap = 4
kListViewIconX = 4
kListViewNameX = kListViewIconX + kListViewIconWidth + kListViewIconGap


;;; Mouse threshold for double click detection.
kDoubleClickDeltaX      = 5
kDoubleClickDeltaY      = 4

;;; ============================================================
;;; Selector List file

;;; See docs/Selector_List_Format.md for file format.

kSelectorListNumPrimaryRunListEntries   = 8
kSelectorListNumSecondaryRunListEntries = 16
kSelectorListNumEntries                 = kSelectorListNumPrimaryRunListEntries + kSelectorListNumSecondaryRunListEntries
kSelectorListNameLength                 = 16 ; includes leading size byte and trailing flags byte
kSelectorListPathLength                 = 64
kSelectorMaxNameLength                  = 14

kSelectorListNumPrimaryRunListOffset    = 0
kSelectorListNumSecondaryRunListOffset  = 1
kSelectorListEntriesOffset              = 2
kSelectorListPathsOffset                = kSelectorListEntriesOffset + kSelectorListNumEntries * kSelectorListNameLength

kSelectorEntryFlagsOffset       = $F
kSelectorEntryCopyOnBoot        = $00
kSelectorEntryCopyOnUse         = $80
kSelectorEntryCopyNever         = $C0

;;; This much is consistently reserved/written.
kSelectorListBufSize = $800

;;; ============================================================
;;; Settings Config File

kDefaultDblClickSpeed   = 1200
kDefaultIPBlinkSpeed    =  500

.struct DeskTopSettings
        pattern         .res 8
        dblclick_speed  .word
        ip_blink_speed  .word
        clock_24hours   .byte   ; $00 = 12 hour, $80 = 24 hour
        rgb_color       .byte   ; $00 = B&W, $80 = Color
        mouse_tracking  .byte   ; 0 = normal, 1 = 2x speed

        startup         .byte   ; kStartupXYZ options

        reserved        .res 112
.endstruct
        .assert .sizeof(DeskTopSettings) = $80, error, .sprintf("Expected $80, was $%0X", .sizeof(DeskTopSettings))

DeskTopSettings::kStartupSkipRAMCard  = %00000001 ; skip copy to RAMCard, if set
DeskTopSettings::kStartupSkipSelector = %00000010 ; skip starting Selector, if set

kDeskTopSettingsFileVersion = 2
kDeskTopSettingsFileSize = 1 + .sizeof(DeskTopSettings)
kDeskTopSettingsFileOffset = 1  ; offset into file of settings (first byte is version)

;;; ============================================================
;;; Alert Sounds. See lib/bell.s

kBellProcLength = 128
BELLPROC   := $300

;;; ============================================================
;;; Alert library options. See lib/alert_dialog.s

;;; Button options
;;; $C0 (%11xxxxxx) = Cancel + Ok
;;; $80 (%10xx0000) = Cancel + Try Again
;;; $00 (%0xxxxxxx) = Ok
;;; Note: Wrapper APIs that take A=id, X=options use X=0 to mean
;;; "use default options for that id", otherwise X & %00000001.
.enum AlertButtonOptions
        OkCancel       = $C0
        TryAgainCancel = $80
        Ok             = $00
.endenum

.enum AlertOptions
        Beep       = %10000000  ; N = play beep sound
        SaveBack   = %01000000  ; V = save/restore background
.endenum

;;; ============================================================
;;; Date/Time. See lib/datetime.s

.struct ParsedDateTime
        year    .word
        month   .byte
        day     .byte
        hour    .byte
        minute  .byte
.endstruct

;;; ============================================================
;;; Offsets into launcher

kLauncherDateOffset     = 3

;;; ============================================================
;;; Drive Special Cases

;;; Unit number used by Glen E. Bredon's RAM.DRV.SYSTEM
;;; RAM disk driver for RamWorks, appears in `DEVLST`.
kRamDrvSystemUnitNum = $3E

;;; Unit number used by John Brooks' RAMAUX.SYSTEM
;;; RAM disk driver for RamWorks, appears in `DEVLST`.
kRamAuxSystemUnitNum = $3F

;;; ADTPro's VDRIVE: https://adtpro.com/vdrive.html
;;; Driver address used by ADTPro's VEDRIVE in `DEVADR`.
kVEDRIVEDriverAddress = $D004
;;; Driver address used by ADTPro's VSDRIVE in `DEVADR`.
kVSDRIVEDriverAddress = $D000
;;; Driver signature byte/value for ADTPro's VSDRIVE
VSDRIVE_SIGNATURE_BYTE := $D003 ; in Main/LCBANK1
kVSDRIVESignatureValue = $63

;;; ============================================================
;;; RAM Disk

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
;;; Invoker routine locations

;;; DeskTop and Selector both use a routine at $290 to launch
;;; other apps. See: lib/invoker.s

INVOKER_PREFIX          := $220 ; Prefix to set
INVOKER                 := $290 ; Invoke other programs
INVOKER_FILENAME        := $280 ; File to invoke (PREFIX must be set)

;;; ============================================================
;;; Default Font

;;; Control Character Glyphs
;;;
;;; Glyphs $00-$1F are useful symbols; some overlap with MouseText
;;; (called out as MT:X in the table below)
;;;
;;; $00 = spacer       !           $10 = TM left      *
;;; $01 = folder left  ! (MT:X)    $11 = TM right     *
;;; $02 = folder right ! (MT:Y)    $12 = pound        *
;;; $03 = file left    !           $13 = pi           *
;;; $04 = file right   !           $14 = divide       *
;;; $05 = pointer        (MT:B)    $15 = rarrow       ! (MT:U)
;;; $06 = vbar           (MT:_)    $16 = degree       !
;;; $07 = hbar           (MT:S)    $17 = open circ
;;; $08 = larrow       ! (MT:H)    $18 = close          (MT:])
;;; $09 = left box                 $19 = gray odd       (MT:W)
;;; $0A = darrow       ! (MT:J)    $1A = gray even      (MT:V)
;;; $0B = uarrow       ! (MT:K)    $1B = solid circ
;;; $0C = right box                $1C = inv check      (MT:E)
;;; $0D = return       ! (MT:M)    $1D = check        ! (MT:D)
;;; $0E = (C)                      $1E = solid apple  ! (MT:@)
;;; $0F = (R)                      $1F = open apple   ! (MT:A)
;;;
;;; ! = Used in this application; glyphs must be present in font.
;;; Any other code points can be repurposed.
;;; * = Used to provide additional characters in some languages
;;; (notably Spanish) where Apple's character sets are lacking.

kGlyphSpacer            = $00
kGlyphFolderLeft        = $01
kGlyphFolderRight       = $02
kGlyphFileLeft          = $03
kGlyphFileRight         = $04

kGlyphLeftArrow         = $08
kGlyphRightArrow        = $15
kGlyphUpArrow           = $0B
kGlyphDownArrow         = $0A
kGlyphReturn            = $0D
kGlyphDegreeSign        = $16
kGlyphOpenApple         = $1F
kGlyphSolidApple        = $1E
kGlyphCheckmark         = $1D

;;; Menu (by default) uses:
;;;   Solid Mod   $1E
;;;   Open Mod    $1F
;;;   Check       $1D
;;;   Control     $01

;;; ============================================================
;;; Macros (specific to this project)

.macro DEFINE_LABEL ident, label, xpos, ypos

        DEFINE_POINT .ident(.sprintf("%s_label_pos", .string(ident))), (xpos), (ypos)
        .ident(.sprintf("%s_label_str", .string(ident))) := *
        PASCAL_STRING {label}
.endmacro

;;; Define an rect for an inset frame drawn with a 4x2 pen, with a 4x2
;;; gap between the passed window bounds and the border. This is the
;;; standard style for modal dialog boxes and alerts.
kBorderDX = 4
kBorderDY = 2
.macro DEFINE_RECT_FRAME ident, width, height
        ident := *
.scope ident
x1:     .word   kBorderDX
y1:     .word   kBorderDY
x2:     .word   ((width) - kBorderDX*2 + 1)
y2:     .word   ((height) - kBorderDY*2 + 1)
.endscope
.endmacro
