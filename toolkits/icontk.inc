;;; ============================================================
;;; Icon ToolKit - Public Definitions
;;; ============================================================

;;; Icon ToolKit Calls

.scope IconTK

InitToolKit     = $00   ; { .byte headersize, .addr a_polybuf, .word bufsize }
AddIcon         = $01   ; param is address of IconEntry
HighlightIcon   = $02   ; { .byte icon }
DrawIconRaw     = $03   ; { .byte icon }
RemoveIcon      = $04   ; { .byte icon }
RemoveAll       = $05   ; { .byte window_id }
FindIcon        = $06   ; { .word mousex, .word mousey, .byte result, .byte window_id }
DragHighlighted = $07   ; { .byte param, .word mousex, .word mousey }
                        ; Input: specific icon being dragged, mouse coords
                        ; Output: 0 = onto desktop or same window (no-op)
                        ;  hi bit clear: low bits are target icon
                        ;  hi bit set:   low bits are target window
                        ;  if 0, X = 2 means "file icon dragged to desktop" (???)
UnhighlightIcon = $08   ; { .byte icon }
DrawAll         = $09   ; { .byte window_id }
IconInRect      = $0A   ; { .byte icon, rect bounds }
EraseIcon       = $0B   ; { .byte icon }
GetIconBounds   = $0C   ; { .byte icon, rect bounds out }
DrawIcon        = $0D   ; { .byte icon }

;;; `icon` is the icon number, i.e. first field in icon entry

.endscope ; IconTK

;;; ============================================================

;;; Call a IconTK entry point:
;;;     ITK_CALL n                      - params is $0000
;;;     ITK_CALL n, params_addr
;;;     ITK_CALL m, params_addr, label  - params_addr is labeled for modifying
;;; Scopes define their own ITKEntry identifiers (e.g. ITKEntry := IconTK::MLI)
;;; This allows for helpers that e.g. bank switch before calling.
.macro ITK_CALL    op, addr, label
        jsr     ITKEntry
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
;;;      .byte state     bit 0   = allocated
;;;                      bit 1-5 = (unused)
;;;                      bit 6   = highlighted
;;;                      bit 7   = dimmed
;;;                      $00 if not allocated
;;;      .byte flags/window_id
;;;                      bits 0-3 = window_id
;;;                      bit 4 = small icon
;;;                      bit 5 = not valid drop source flag (i.e. trash)
;;;                      bit 6 = drop target flag (trash, folder, dir)
;;;                      bit 7 = fixed location
;;;      .word iconx     (pixels)
;;;      .word icony     (pixels)
;;;      .addr iconbits  (addr of IconResource)
;;;      .byte len       (name length)
;;;      .res  15  name  (name)
;;;      .byte record_num (index of icon in window)

.struct IconEntry
        id              .byte   ; 0
        state           .byte   ; 1
        win_flags       .byte   ; 2
        iconx           .word   ; 3
        icony           .word   ; 5
        iconbits        .addr   ; 7
        name            .res 16 ; 9 (length + 15 chars)
        record_num      .byte   ; 25
.endstruct                      ; 26

;;; Icon numbers 1...127 are supported
;;; (Tables keyed by icon number must hold `kMaxIconCount` + 1 entries)
kMaxIconCount   = 127

;;; Masks for IconEntry::state
kIconEntryStateDimmed      = %10000000
kIconEntryStateHighlighted = %01000000
kIconEntryStateAllocated   = %00000001

;;; Masks for IconEntry::win_flags
kIconEntryFlagsFixed            = %10000000
kIconEntryFlagsDropTarget       = %01000000
kIconEntryFlagsNotDropSource    = %00100000
kIconEntryFlagsSmall            = %00010000
kIconEntryWinIdMask             = %00001111

.struct IconResource
        ;; First part is MGTK::MapInfo without leading viewloc
        mapbits         .addr   ; address of bitmap bits
        mapwidth        .byte   ; stride of bitmap bits
        reserved        .byte   ; 0
        maprect         .res 8  ; x1,y1 must be 0,0

        ;; Next part is address of mask bits; must be same
        ;; dimensions as rect of icon.
        maskbits        .addr
.endstruct

.macro  DEFINE_ICON_RESOURCE name, mapbits, mapwidth, dx, dy, maskbits
.params name
        ;; First part is MGTK::MapInfo without leading viewloc
        .addr   mapbits
        .byte   mapwidth
        .byte   0             ; reserved
        .word   0, 0, dx, dy  ; maprect
        ;; Next part is link to mask
        .addr   maskbits
.endparams
.endmacro
