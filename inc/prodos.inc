;;; ------------------------------------------------------------
;;; ProDOS MLI
;;; ------------------------------------------------------------

;;; Entry point / Global Page
MLI             := $BF00        ; Entry point
DEVNUM          := $BF30        ; Most recent accessed device
DEVCNT          := $BF31        ; Number of on-line devices minus 1
DEVLST          := $BF32        ; Up to 14 units
BITMAP          := $BF58        ; System memory bitmap
BITMAP_SIZE     := $18          ; Bits for pages $00 to $BF
DATELO          := $BF90        ; Date lo
DATEHI          := $BF91        ; Date hi
TIMELO          := $BF92        ; Time lo
TIMEHI          := $BF93        ; Time hi
MACHID          := $BF98        ; Machine ID

;;; Patch Locations
SELECTOR        := $D100

;;; ------------------------------------------------------------
;;; MLI Calls

;;; Housekeeping Calls
CREATE          := $C0
DESTROY         := $C1
RENAME          := $C2
SET_FILE_INFO   := $C3
GET_FILE_INFO   := $C4
ON_LINE         := $C5
SET_PREFIX      := $C6
GET_PREFIX      := $C7

;;; Filing Calls
OPEN            := $C8
NEWLINE         := $C9
READ            := $CA
WRITE           := $CB
CLOSE           := $CC
FLUSH           := $CD
SET_MARK        := $CE
GET_MARK        := $CF
SET_EOF         := $D0
GET_EOF         := $D1
SET_BUF         := $D2
GET_BUF         := $D3

;;; System Calls
GET_TIME        := $82
ALLOC_INTERRUPT := $40
DEALLOC_INTERRUPT       := $41
QUIT            := $65

;;; Direct Disk Access Commands
READ_BLOCK      := $80
WRITE_BLOCK     := $81

;;; ------------------------------------------------------------
;;; Device Types (low nibble of unit number in DEVLST)

DT_DISKII       := $0
DT_PROFILE      := $4
DT_RAM          := $F

;;; See ProDOS Tech Note #21 - other than the above types, there
;;; is not an "ID nibble". The nibble is a copy of $CnFE's high
;;; nibble, with this meaning:
;;;   bit 3   = removable
;;;   bit 2   = interruptable
;;;   bit 1-0 = number of volumes (0-1)
;;; "You should ignore the low nibble in the unit number..."

;;; ------------------------------------------------------------
;;; File Types

FT_TYPELESS     := $00
FT_BAD          := $01
FT_TEXT         := $04
FT_BINARY       := $06
FT_DIRECTORY    := $0F
FT_SRC          := $B0          ; IIgs system type; re-used?
FT_S16          := $B3          ; IIgs Application Program
FT_BASIC        := $FC
FT_SYSTEM       := $FF

;;; ------------------------------------------------------------
;;; Macros

.macro  MLI_CALL    op, addr
        jsr MLI
        .byte op
        .addr addr
.endmacro

.macro PASCAL_STRING str        ; Length-prefixed string
        .local  data            ; Can include control chars by using:
        .local  end             ; PASCAL_STRING {"abc",$0D,"def"}
        .byte   end - data
data:   .byte   str
end:
.endmacro
