;;; ============================================================
;;; DeskTop Internals
;;; ============================================================

        dummy0000 := $0000         ; overwritten by self-modified code
        dummy1234 := $1234         ; overwritten by self-modified code

;;; ============================================================

;;; ============================================================

kMaxDeskAccCount        = 12

;;; icon #1 is always Trash (BUG: should use trash_icon_num)
kTrashIconNum   = 1

;;; Internally, FT_SYS files with ".SYSTEM" are represented as this type.
;;; (FT_BAD files are remapped to FT_TYPELESS)
kAppFileType    = $01

;;; Standard button sizes; sometimes narrower
kButtonWidth  = 100
kButtonHeight = 11


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

MGTK_RELAY      := $D000
ITK_RELAY       := $D040

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


;;; ============================================================
;;; Internals - miscellaneous structures

.struct IconDefinition
        ;; First part is MGTK::MapInfo without leading viewloc
        mapbits         .addr   ; address of bitmap bits
        mapwidth        .byte   ; stride of bitmap bits
        reserved        .byte   ; 0
        maprect         .res 8  ; x1,y1 must be 0,0

        ;; Next part is address of mask bits; must be same
        ;; dimensions as rect of icon.
        maskbits        .addr
.endstruct

.macro  DEFICON mapbits, mapwidth, dx, dy, maskbits
        ;; First part is MGTK::MapInfo without leading viewloc
        .addr   mapbits
        .byte   mapwidth
        .byte   0             ; reserved
        .word   0, 0, dx, dy  ; maprect
        ;; Next part is link to mask
        .addr   maskbits
.endmacro

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
