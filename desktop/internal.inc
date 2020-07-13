;;; ============================================================
;;; DeskTop Internals
;;; ============================================================

kDAFileType     = $F1
kDAFileAuxType  = $640           ; High bit set = don't show in Apple menu

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

;;; icon #1 is always Trash (BUG: should use trash_icon_num)
kTrashIconNum   = 1

;;; Maximum number of volumes displayed/tracked. This is two per slot,
;;; except S3,D2 is assumed to be /RAM which is disconnected.
kMaxVolumes     = 13


;;; ============================================================
;;; Memory Areas

;;; Scratch area (in Aux) used during modal operations:
;;; * Given to MGTK to save background while menus are shown
;;; * Used by DeskTop to save background while alert dialog shown
;;; * Used by IconTK to store icon outlines during DragHighlighted
;;; * Used by IconTK for a temp buffer during HighlightAll

SAVE_AREA_BUFFER := $800        ; through $1AFF
kSaveAreaSize   = $1300

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
        yax_call        MGTK_RELAY, (call), (addr)
    .else
        yax_call        MGTK_RELAY, (call), 0
    .endif
.endmacro

.macro ITK_RELAY_CALL call, addr
    .if .paramcount > 1
        yax_call        ITK_RELAY, (call), (addr)
    .else
        yax_call        ITK_RELAY, (call), 0
    .endif
.endmacro

;;; Scopes define their own MLI_RELAY procs.

.macro MLI_RELAY_CALL call, addr
    .if .paramcount > 1
        yax_call        MLI_RELAY, (call), (addr)
    .else
        yax_call        MLI_RELAY, (call), 0
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
