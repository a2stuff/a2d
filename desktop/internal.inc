;;; ============================================================
;;; DeskTop Internals
;;; ============================================================

        RESOURCE_FILE "internal.res"

kDAFileType     = $F1
kDAFileAuxType  = $641           ; High bit set = don't show in Apple menu

.enum IconType
        generic
        text
        binary
        graphics
        font
        relocatable
        command
        folder
        iigs
        appleworks_db
        appleworks_wp
        appleworks_sp
        desk_accessory
        basic
        system
        application
        COUNT                   ; last
.endenum

kMaxDeskAccCount        = 12

;;; Maximum number of volumes displayed/tracked. This is two per slot,
;;; except S3,D2 is assumed to be /RAM which is disconnected.
kMaxVolumes     = 13

;;; ============================================================
;;; Window/Icon Metrics

;;; Offsets for created windows
kWindowXOffset = 5
kWindowYOffset = 27

;;; Min/Max window dimensions
kMinWindowWidth = 170
kMaxWindowWidth = 430

kMinWindowHeight = 50
kMaxWindowHeight = 115

;;; Height of items/used/free header
kWindowHeaderHeight     = 14

;;; --------------------------------------------------
;;; List views

kFirstRowBaseline       = 16
kListViewWidth          = 410

;;; --------------------------------------------------
;;; Icon views

kMaxIconHeight          = 17
kIconWidth              = 28
kIconLabelHeight        = 9     ; default font height

kIconsPerRow    = 5
kIconSpacingX   = 80
kIconSpacingY   = 32

;;; Bounding box padding, which defines icon placing, window sizing and
;;; scrollbars. This does not take into account the icon's actual width
;;; (bitmap or label size). The header is included to simplify
;;; calculations.

kIconBBoxOffsetTop      = kWindowHeaderHeight + 4
kIconBBoxOffsetLeft     = 45
kIconBBoxOffsetBottom   = kIconLabelHeight + 4
kIconBBoxOffsetRight    = 37 + kIconWidth ; accomodate icon + label
;;; NOTE: kIconBBoxOffsetRight should probably be se to
;;; kIconBBoxOffsetLeft + kIconWidth but aesthetically that looks bad.

;;; ============================================================
;;; Common Shortcuts

kShortcutYes      = res_char_button_yes_shortcut
kShortcutNo       = res_char_button_no_shortcut
kShortcutTryAgain = res_char_button_try_again_shortcut
kShortcutAll      = res_char_button_all_shortcut


;;; ============================================================
;;; Memory Areas

;;; Scratch area (in Aux) used during modal operations:
;;; * Given to MGTK to save background while menus are shown
;;; * Used by DeskTop to save background while alert dialog shown
;;; * Used by IconTK to store icon outlines during DragHighlighted
;;; * Used by IconTK for a temp buffer during HighlightAll

SAVE_AREA_BUFFER := $800        ; through $1AFF
kSaveAreaSize   = $1300

;;; Most common I/O buffer, used during initializer, loading DAs,
;;; and many other operations.

IO_BUFFER := $1C00

;;; ============================================================
;;; Menu Constants

kMenuIdApple    = 1
kMenuIdFile     = 2
kMenuIdView     = 4
kMenuIdSpecial  = 5
kMenuIdStartup  = 8
kMenuIdSelector = 3

kMenuSizeApple    = 14
kMenuSizeFile     = 13
kMenuSizeView     = 5
kMenuSizeSpecial  = 11
kMenuSizeStartup  = 7
kMenuSizeSelector = 13

;;; These must correspond to indexes in the Selector menu.
.enum SelectorAction
        add     = 1
        edit    = 2
        delete  = 3
        run     = 4
.endenum

;;; ============================================================
;;; Device types

kNumDeviceTypes = 5

kDeviceTypeDiskII       = 0
kDeviceTypeRAMDisk      = 1
kDeviceTypeFixed        = 2
kDeviceTypeRemovable    = 3
kDeviceTypeFileShare    = 4

;;; ============================================================
;;; Warning messages

kNumWarningTypes = 7

kWarningMsgInsertSystemDisk     = 0
kWarningMsgSelectorListFull     = 1
kWarningMsgSelectorListFull2    = 2
kWarningMsgWindowMustBeClosed   = 3
kWarningMsgWindowMustBeClosed2  = 4
kWarningMsgTooManyWindows       = 5
kWarningMsgSaveSelectorList     = 6

;;; ============================================================
;;; Invoker routine locations

INVOKER_PREFIX          := $220 ; Prefix to set
INVOKER                 := $290 ; Invoke other programs
INVOKER_FILENAME        := $280 ; File to invoke (PREFIX must be set)

;;; ============================================================
;;; Relays from Main to Aux (params must be in ZP or LC)

MGTK_RELAY      := MGTKRelayImpl
ITK_RELAY       := ITKRelayImpl

.macro MGTK_RELAY_CALL call, addr
    .if .paramcount > 1
        param_call        MGTK_RELAY, (call), (addr)
    .else
        param_call        MGTK_RELAY, (call), 0
    .endif
.endmacro

.macro ITK_RELAY_CALL call, addr
    .if .paramcount > 1
        param_call        ITK_RELAY, (call), (addr)
    .else
        param_call        ITK_RELAY, (call), 0
    .endif
.endmacro

;;; Scopes define their own MLI_RELAY procs.

.macro MLI_RELAY_CALL call, addr
    .if .paramcount > 1
        param_call        MLI_RELAY, (call), (addr)
    .else
        param_call        MLI_RELAY, (call), 0
    .endif
.endmacro

;;; ============================================================
;;; Internals - miscellaneous structures

.struct FileRecord
        name                    .res 16
        file_type               .byte ; 16 $10
        blocks                  .word ; 17 $11
        creation_date           .word ; 19 $13
        creation_time           .word ; 21 $15
        modification_date       .word ; 23 $17
        modification_time       .word ; 25 $19
        access                  .byte ; 27 $1B
        header_pointer          .word ; 28 $1C
        aux_type                .word ; 30 $1E
.endstruct

kDeskTopFileVersion  = $80  ; Increment when format changes

.struct DeskTopFileItem
        window_path     .res ::kPathBufferSize
        rect            .tag MGTK::Rect
.endstruct

.struct ParsedDateTime
        year    .word
        month   .byte
        day     .byte
        hour    .byte
        minute  .byte
.endstruct

;;; ============================================================
;;; Segments & Overlays
;;;
;;; DeskTop is broken into various segments plus dynamically
;;; loaded overlays, all stored in one file. This section
;;; defines the file offsets, load addresses and lengths of each
;;; segment and offset

_segoffset .set 0
.macro DEFSEG name, addr, len
        .ident(.sprintf("k%sAddress", .string(name))) = addr
        .ident(.sprintf("k%sLength", .string(name))) = len
        .ident(.sprintf("k%sOffset", .string(name))) = _segoffset
        _segoffset .set _segoffset + len
.endmacro

;;; Segments
        DEFSEG SegmentLoader,      $2000, $0580
        DEFSEG SegmentDeskTopAux,  $4000, $8000
        DEFSEG SegmentDeskTopLC1A, $D000, $1D00
        DEFSEG SegmentDeskTopLC1B, $FB00, $0500
        DEFSEG SegmentDeskTopMain, $4000, $7F00
        DEFSEG SegmentInitializer, $0800, $0A00
        DEFSEG SegmentInvoker,     $0290, $0160

;;; Dynamically loaded overlays
        DEFSEG OverlayDiskCopy1,   $0800, $0200
        DEFSEG OverlayDiskCopy2,   $1800, $0200
        DEFSEG OverlayDiskCopy3,   $D000, $2200
        DEFSEG OverlayDiskCopy4,   $0800, $0B00
        DEFSEG OverlayFormatErase, $0800, $1400
        DEFSEG OverlaySelector1,   $9000, $1000
        DEFSEG OverlayFileDialog,  $5000, $2000
        DEFSEG OverlayFileCopy,    $7000, $0800
        DEFSEG OverlayFileDelete,  $7000, $0800
        DEFSEG OverlaySelector2,   $7000, $0800

;;; These pseudo-overlays restore DeskTop after overlays are used

kOverlayDeskTopRestore1Length = $2800
kOverlayDeskTopRestore1Address = $5000
kOverlayDeskTopRestore1Offset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestore1Address - kSegmentDeskTopMainAddress)

kOverlayDeskTopRestore2Length = $1000
kOverlayDeskTopRestore2Address = $9000
kOverlayDeskTopRestore2Offset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestore2Address - kSegmentDeskTopMainAddress)
