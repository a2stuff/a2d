;;; ============================================================
;;; DeskTop Internals
;;; ============================================================

kDAFileType     = $F1
kDAFileAuxType  = $641           ; High bit set = don't show in Apple menu

.enum IconType
        generic
        text
        binary
        graphics
        music
        font
        relocatable
        command
        folder
        iigs
        appleworks_db
        appleworks_wp
        appleworks_sp
        archive
        desk_accessory
        basic
        system
        application
        COUNT                   ; last
.endenum

kMaxDeskAccCount        = 12

;;; Maximum number of ProDOS devices (2 per slot 1-7). This is the
;;; maximum size of DEVLST not counting DEVCNT itself.
kMaxDevListSize = 14

;;; Maximum number of volumes displayed/tracked. This is two per slot,
;;; except S3,D2 is assumed to be /RAM which is disconnected.
kMaxVolumes     = kMaxDevListSize - 1

;;; ============================================================
;;; View types

;;; (low nibble must match menu order)
kViewByIcon     = $00
kViewByName     = $81
kViewByDate     = $82
kViewBySize     = $83
kViewByType     = $84
kViewByMenuMask = $0F           ; Convert kViewByXYZ to menu index

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
kIconLabelHeight        = kSystemFontHeight

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
kIconBBoxOffsetRight    = 37 + kIconWidth ; accommodate icon + label
;;; NOTE: kIconBBoxOffsetRight should probably be se to
;;; kIconBBoxOffsetLeft + kIconWidth but aesthetically that looks bad.

;;; ============================================================
;;; Common Shortcuts

kShortcutYes      = res_char_button_yes_shortcut
kShortcutNo       = res_char_button_no_shortcut
kShortcutTryAgain = res_char_button_try_again_shortcut
kShortcutAll      = res_char_button_all_shortcut

;;; ============================================================
;;; Operations

kOperationSucceeded     = 0
kOperationCanceled      = 1
kOperationFailed        = $FF

;;; ============================================================
;;; Memory Areas

;;; Scratch area (in Aux) used during modal operations:
;;; * Given to MGTK to save background while menus are shown
;;; * Used by DeskTop to save background while alert dialog shown
;;; * Used by IconTK to store icon outlines during DragHighlighted

SAVE_AREA_BUFFER := $800        ; through $1AFF
kSaveAreaSize   = $1300

;;; Most common I/O buffer, used during initializer, loading DAs,
;;; and many other operations.

IO_BUFFER := $1C00

;;; ============================================================
;;; Menu Constants

kMenuIdApple    = 1
kMenuIdFile     = 2
kMenuIdView     = 3
kMenuIdSpecial  = 4
kMenuIdStartup  = 5
kMenuIdSelector = 6

kMenuSizeApple    = 14
kMenuSizeFile     = 14
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

;;; ============================================================


;;; Mapping from file info to icon type
;;;
;;; The incoming type is compared (using a mask) against a type, and
;;; optionally auxtype and block count. First match wins.

.struct ICTRecord      ; Offset
        mask     .byte ; 0     incoming type masked before comparison
        filetype .byte ; 1     file type for the record (must match)
        flags    .byte ; 2     bit 7 = compare aux; 6 = compare blocks
        aux_suf  .word ; 3     if ICT_FLAGS_AUX: aux type; if ICT_FLAGS_SUFFIX: suffix string
        blocks   .word ; 5     optional block count
        icontype .byte ; 7     IconType
.endstruct

kICTSentinel = $01     ; not $00, because $00 as a mask is useful

.macro DEFINE_ICTRECORD mask, filetype, flags, aux_suf, blocks, icontype
        .assert mask <> kICTSentinel, error, "Can't use sentinel value as a mask"
        .byte   mask
        .byte   filetype
        .byte   flags
        .word   aux_suf
        .word   blocks
        .byte   icontype
.endmacro
        ICT_FLAGS_NONE   = %00000000
        ICT_FLAGS_AUX    = %10000000 ; exclusive with ICT_FLAGS_SUFFIX
        ICT_FLAGS_BLOCKS = %01000000
        ICT_FLAGS_SUFFIX = %00100000 ; exclusive with ICT_FLAGS_AUX

;;; ============================================================
;;; Segments & Overlays
;;;
;;; DeskTop is broken into various segments plus dynamically
;;; loaded overlays, all stored in one file. This section
;;; defines the file offsets, load addresses and lengths of each
;;; segment and offset

kLoaderOffset = $200

_segoffset .set 0
.macro DEFSEG name, addr, len
        .ident(.sprintf("k%sAddress", .string(name))) = addr
        .ident(.sprintf("k%sLength", .string(name))) = len
        .ident(.sprintf("k%sOffset", .string(name))) = _segoffset
        _segoffset .set _segoffset + len
.endmacro

;;; Segments
        _segoffset .set kLoaderOffset
        DEFSEG SegmentLoader,      $2000, $0300
        DEFSEG SegmentDeskTopAux,  $4000, $8000
        DEFSEG SegmentDeskTopLC1A, $D000, $1D00
        DEFSEG SegmentDeskTopLC1B, $FB00, $0500
        DEFSEG SegmentDeskTopMain, $4000, $7F00
        DEFSEG SegmentInitializer, $0800, $0A00
        DEFSEG SegmentInvoker,     $0290, $0160

;;; Dynamically loaded overlays
        DEFSEG OverlayFormatErase,  $0800, $1100
        DEFSEG OverlayShortcutPick, $9000, $0B00
        DEFSEG OverlayFileDialog,   $5000, $1200
        DEFSEG OverlayFileCopy,     $7000, $0200
        DEFSEG OverlayFileDelete,   $7000, $0100
        DEFSEG OverlayShortcutEdit, $7000, $0500

;;; These pseudo-overlays restore DeskTop after overlays are used

kOverlayDeskTopRestore1Length = $2800
kOverlayDeskTopRestore1Address = $5000
kOverlayDeskTopRestore1Offset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestore1Address - kSegmentDeskTopMainAddress)

kOverlayDeskTopRestore2Length = $1000
kOverlayDeskTopRestore2Address = $9000
kOverlayDeskTopRestore2Offset = kSegmentDeskTopMainOffset + (kOverlayDeskTopRestore2Address - kSegmentDeskTopMainAddress)
