;;; ============================================================
;;; DeskTop Internals
;;; ============================================================

.enum IconType
        ;; Volumes
        trash                   ; pseudo-volume
        floppy140
        ramdisk
        profile
        floppy800
        fileshare
        cdrom

        ;; Files
        generic
        text
        binary
        graphics
        animation
        music
        tracker
        audio
        speech
        font
        relocatable
        command
        folder
        system_folder
        iigs
        appleworks_db
        appleworks_wp
        appleworks_sp
        archive
        encoded
        link
        chip8
        desk_accessory
        basic
        intbasic
        variables
        system
        application

        ;; Small Icons
        small_generic
        small_folder

        COUNT                   ; last
        VOL_COUNT = generic
        SMALL_COUNT = 2
.endenum

kMaxDeskAccCount        = MGTK::max_menu_items - kAppleMenuFixedItems

;;; Maximum number of ProDOS devices (2 per slot 1-7). This is the
;;; maximum size of DEVLST not counting DEVCNT itself.
kMaxDevListSize = 14

;;; Maximum number of volumes displayed/tracked. It is possible
;;; that /RAM was previously disconnected and another drive mapped
;;; to $Bx so we need to support the maximum number of devices.
kMaxVolumes     = kMaxDevListSize

;;; ============================================================
;;; Window/Icon Metrics

;;; Offsets for created windows
kWindowXOffset = 5
kWindowYOffset = 27

;;; Min/Max window dimensions
kMinWindowWidth = 170
kMaxWindowWidth = kIconBBoxPaddingLeft + (kMaxIconTotalWidth - kMaxIconBitmapWidth) / 2 + (kIconViewIconsPerRow - 1) * kIconViewSpacingX + (kMaxIconTotalWidth + kMaxIconBitmapWidth) / 2 + kIconBBoxPaddingRight

kMinWindowHeight = 50
kMaxWindowHeight = kIconViewSpacingY * 3 + kWindowHeaderHeight - 1
;;; NOTE: `kMaxWindowHeight` is an integral number of icons so that
;;; each vertical scroll tick leaves the icons nicely aligned.

;;; Height of items/used/free header
kWindowHeaderHeight     = 15

kWindowHeaderInsetX = 5
kWindowHeaderSpacingX = 8

;;; --------------------------------------------------
;;; List views

kListViewInitialTop     = kWindowHeaderHeight - 1 + kIconBBoxPaddingTop
kListViewInitialLeft    = 4

kListViewFirstBaseline  = kListViewInitialTop - 2
kListViewWidth          = 410
kListViewRowHeight      = kListItemHeight

;;; --------------------------------------------------
;;; Icon view

kIconViewInitialLeft = kIconBBoxPaddingLeft
kIconViewInitialTop  = kWindowHeaderHeight + kIconBBoxPaddingTop + kMaxIconBitmapHeight - 1
kIconViewIconsPerRow = 5

kIconViewSpacingX    = 80
kIconViewSpacingY    = 32

;;; --------------------------------------------------
;;; Small Icon view

kSmallIconViewInitialTop     = kWindowHeaderHeight + kIconBBoxPaddingTop - 1
kSmallIconViewInitialLeft    = 4
kSmallIconViewIconsPerRow    = 3
kSmallIconViewSpacingX       = 130
kSmallIconViewSpacingY       = kListItemHeight+2

;;; --------------------------------------------------
;;; Bounding box padding (all view types)

kIconBBoxPaddingX        = 4
kIconBBoxPaddingY        = 2
kIconBBoxPaddingTop      = kIconBBoxPaddingY
kIconBBoxPaddingLeft     = kIconBBoxPaddingX
kIconBBoxPaddingBottom   = kIconBBoxPaddingY
kIconBBoxPaddingRight    = kIconBBoxPaddingX

;;; NOTE: Offsets are selected in conjunction with icon spacing
;;; and maximum window sizing so that scrolling all the way down
;;; using the pagers leaves icons aligned.

;;; --------------------------------------------------
;;; Scrolling

;;; Allow maximum fidelity
kScrollThumbMax = $FF

;;; Arbitrary - these feel good, but can be tweaked
kIconViewScrollTickH = kIconViewSpacingY * 2
kIconViewScrollTickV = kIconViewSpacingY
kListViewScrollTickH = kListViewRowHeight * 2
kListViewScrollTickV = kListViewRowHeight

;;; ============================================================
;;; Prompt Dialog

kPromptButtonsOKCancel = $00
kPromptButtonsOKOnly   = $80

;;; ============================================================
;;; Alerts

kShowAlertUseDefaultOptionsForId = $01

;;; ============================================================
;;; Operations

kOperationSucceeded     = 0
kOperationCanceled      = 1     ; no filesystem changes occurred
kOperationFailed        = $FF   ; filesystem changes possibly occurred

;;; ============================================================
;;; Memory Areas

;;; Scratch area (in Aux) used during modal operations:
;;; * Given to MGTK to save background while menus are shown
;;; * Used by DeskTop to save background while alert dialog shown
;;; * Used by IconTK to store icon outlines during DragHighlighted

SAVE_AREA_BUFFER := $E00        ; through $2000
kSaveAreaSize   = $2000 - SAVE_AREA_BUFFER

;;; Most common I/O buffer, used during initializer, loading DAs,
;;; and many other operations.

IO_BUFFER := $1C00

;;; Selector entries (shortcuts) file is temporarily loaded here
;;; by the picker dialog.

SELECTOR_FILE_BUF := $0C00

;;; Memory areas used when reading directories to populate windows.

DIR_READ_IO_BUFFER := $800
DIR_READ_DATA_BUFFER := $C00
kDirReadDataBufferSize = $200

;;; ============================================================
;;; Menu Constants

kMenuNumItems = 7

kMenuIdApple    = 1
kMenuIdFile     = 2
kMenuIdEdit     = 3
kMenuIdView     = 4
kMenuIdSpecial  = 5
kMenuIdStartup  = 6
kMenuIdSelector = 7

kAppleMenuFixedItems = 3

kSelectorMenuFixedItems = 5

kMenuSizeApple    = kMaxDeskAccCount + kAppleMenuFixedItems
kMenuSizeFile     = 13
kMenuSizeEdit     = 6
kMenuSizeView     = 6
kMenuSizeSpecial  = 10
kMenuSizeStartup  = 7
kMenuSizeSelector = kSelectorMenuFixedItems + 8

;;; These must correspond to indexes in the Selector menu.
.enum SelectorAction
        add     = 1
        edit    = 2
        delete  = 3
        run     = 4
.endenum

.enum FormatEraseAction
        format = 4
        erase  = 5
.endenum

;;; ============================================================
;;; Internals - miscellaneous structures

.struct FileRecord
        name                    .res 16
        file_type               .byte ; 16 $10
        blocks                  .word ; 17 $11
        creation_date           .word ; 19 $13 - UNUSED
        creation_time           .word ; 21 $15 - UNUSED
        modification_date       .word ; 23 $17
        modification_time       .word ; 25 $19
        access                  .byte ; 27 $1B - UNUSED
        header_pointer          .word ; 28 $1C - UNUSED
        aux_type                .word ; 30 $1E
.endstruct

;;; ============================================================
;;; DESKTOP.FILE format

;;; See `docs/Desktop_File_Format.md` for file format.

kDeskTopFileVersion  = $82  ; Increment when format changes

.struct DeskTopFileItem
        window_path     .res ::kPathBufferSize
        view_by         .byte
        viewloc         .tag MGTK::Point
        maprect         .tag MGTK::Rect
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

.macro FORMAT_MESSAGE num_args, format_str
        jsr     FormatMessage
        .byte   num_args
        .addr   format_str
.endmacro
