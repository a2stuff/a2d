;;; ============================================================
;;; DeskTop Internals
;;; ============================================================

        dummy0000 := $0000         ; overwritten by self-modified code
        dummy1234 := $1234         ; overwritten by self-modified code

;;; ============================================================

VERSION_MAJOR = 1
VERSION_MINOR = 2
.define VERSION_SUFFIX "-alpha9"
.define RELEASE_DATE "January 5, 2020"

;;; ============================================================

kMaxDeskAccCount        = 12

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
