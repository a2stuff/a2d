;;; ============================================================
;;; Icon ToolKit - Public Definitions
;;; ============================================================
;;; Used by:
;;;  * DeskTop itself
;;;  * Desk Accessories & Preview Accessories
;;; ============================================================

;;; Icon ToolKit Calls (from aux memory)

.scope IconTK

;;; * = Used by Desk Accessories

MLI := $8E00
        ;; MLI-style call (jsr IconTK::MLI ; .byte call ; .addr params)
        ;; Call from Aux (RAMRDON/RAMWRTON)

AddIcon         = $01   ; param is address of IconEntry
HighlightIcon   = $02   ; { .byte icon }
RedrawIcon      = $03   ; { .byte icon }
RemoveIcon      = $04   ; { .byte icon }
RemoveAll       = $05   ; { .byte window_id }
CloseWindow     = $06   ; { .byte window_id }
FindIcon        = $07   ; { .word mousex, .word mousey, .byte result, .byte window_id }
DragHighlighted = $08   ; { .byte param, .word mousex, .word mousey }
                        ; Input: specific icon being dragged, mouse coords
                        ; Output: 0 = onto desktop or same window (no-op)
                        ;  hi bit clear: low bits are target icon
                        ;  hi bit set:   low bits are target window
                        ;  if 0, X = 2 means "file icon dragged to desktop" (???)
UnhighlightIcon = $09   ; { .byte icon }
RedrawDesktopIcons = $0A ; Repaints desktop icons *
IconInRect      = $0B   ; { .byte icon, rect bounds }
EraseIcon       = $0C   ; { .byte icon }

;;; `icon` is the icon number, i.e. first field in icon entry
;;; `icon_index` is the index in the icon table

.endscope ; IconTK

;;; Call a IconTK entry point:
;;;     ITK_CALL n                      - params is $0000
;;;     ITK_CALL n, params_addr
;;;     ITK_CALL m, params_addr, label  - params_addr is labeled for modifying

.macro ITK_CALL    op, addr, label
        jsr     IconTK::MLI
        .byte   op

    .if .paramcount > 2
label   := *
    .endif

    .if .paramcount > 1
        .addr   addr
    .else
        .addr   0
    .endif
.endmacro


;;; ============================================================

;;; Icon (file/volume) entries - length 27 bytes, maximum of 127
;;;      .byte icon      icon index
;;;      .byte state     1 = allocated, $80 = dragging, 0 = otherwise
;;;      .byte type/window_id
;;;                      (bits 0-3 window_id)
;;;                      (bits 4,5,6)
;;;                             000 = directory
;;;                             001 = system
;;;                             010 = binary (maybe runnable)
;;;                             011 = basic
;;;                             100 = (unused)
;;;                             101 = data (text/generic/...)
;;;                             110 = (unused)
;;;                             111 = trash
;;;                      (bit 7 = open flag)
;;;      .word iconx     (pixels)
;;;      .word icony     (pixels)
;;;      .addr iconbits  (addr of IconDefinition)
;;;      .byte len       (name length)
;;;      .res  15  name  (name)
;;;      .byte record_num (index of icon in window)

.struct IconEntry
        id              .byte   ; 0
        state           .byte   ; 1
        win_type        .byte   ; 2
        iconx           .word   ; 3
        icony           .word   ; 5
        iconbits        .addr   ; 7
        name            .res 16 ; 9 (length + 15 chars)
        record_num      .byte   ; 25
.endstruct                      ; 26

;;; Icon numbers 1...127 are supported
;;; (Tables keyed by icon number must hold `kMaxIconCount` + 1 entries)
kMaxIconCount   = 127

kIconEntryOpenMask    = %10000000
kIconEntryTypeMask    = %01110000
kIconEntryWinIdMask   = %00001111

;;; Only kIconEntryTypeDir and kIconEntryTypeTrash define unique behavior.
kIconEntryTypeDir     = %00000000
kIconEntryTypeSystem  = %00010000
kIconEntryTypeBinary  = %00100000
kIconEntryTypeBasic   = %00110000
kIconEntryTypeGeneric = %01010000
kIconEntryTypeTrash   = %01110000

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
