;;; ============================================================
;;;
;;; ProDOS MLI
;;;
;;; ============================================================

;;; Entry point / Global Page
MLI             := $BF00        ; Entry point
DATETIME        := $BF06        ; JMP to clock routine
DEVADR          := $BF10        ; Device driver addresses ($BF10-$BF2F)
NODEV           := $BF10        ; "No Device Connected" entry (slot 0)
DEVNUM          := $BF30        ; Most recent accessed device
DEVCNT          := $BF31        ; Number of on-line devices minus 1
DEVLST          := $BF32        ; Up to 14 units ($BF32-$BF3F)
BITMAP          := $BF58        ; System memory bitmap
BITMAP_SIZE     := $18          ; Bits for pages $00 to $BF
DATELO          := $BF90        ; Date lo
DATEHI          := $BF91        ; Date hi
TIMELO          := $BF92        ; Time lo
TIMEHI          := $BF93        ; Time hi
LEVEL           := $BF94        ; File level
MACHID          := $BF98        ; Machine ID
SLTBYT          := $BF99        ; '1' bits indicate rom in slot (bit#)
IVERSION        := $BFFD        ; Interpreter Version
KVERSION        := $BFFF        ; ProDOS Kernel Version

;;; Patch Locations
SELECTOR        := $D100

BLOCK_SIZE      := $200

;;; ============================================================
;;; MLI Calls
;;; ============================================================

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

;;; ============================================================
;;; Device Types (low nibble of unit number in DEVLST)
;;; ============================================================

;;; As used by DeskTop; these are not actually correct...

DT_DISKII       := $0
DT_PROFILE      := $4
DT_REMOVABLE    := $B
DT_RAM          := $F

;;; See ProDOS Tech Note #21 - other than the above types, there
;;; is not an "ID nibble". The nibble is a copy of $CnFE's high
;;; nibble, with this meaning:
;;;   bit 3   = removable
;;;   bit 2   = interruptable
;;;   bit 1-0 = number of volumes (0-1)
;;; "You should ignore the low nibble in the unit number..."

;;; ============================================================
;;; File Types
;;; ============================================================

FT_TYPELESS     := $00
FT_BAD          := $01
FT_TEXT         := $04
FT_BINARY       := $06
FT_DIRECTORY    := $0F
FT_SRC          := $B0          ; IIgs system type; re-used?
FT_S16          := $B3          ; IIgs Application Program
FT_BASIC        := $FC
FT_SYSTEM       := $FF

;;; ============================================================
;;; Access
;;; ============================================================

ACCESS_DEFAULT  := %11000011

;;; ============================================================
;;; Storage Types
;;; ============================================================

ST_STANDARD_FILE        := $01
ST_LINKED_DIRECTORY     := $0D
ST_VOLUME_DIRECTORY     := $0F

;;; ============================================================
;;; Errors
;;; ============================================================

ERR_DEVICE_NOT_CONNECTED := $28
ERR_WRITE_PROTECTED   := $2B
ERR_INVALID_REFERENCE := $43
ERR_PATH_NOT_FOUND    := $44
ERR_VOL_NOT_FOUND     := $45
ERR_FILE_NOT_FOUND    := $46
ERR_DUPLICATE_FILENAME:= $47
ERR_OVERRUN_ERROR     := $48
ERR_VOLUME_DIR_FULL   := $49
ERR_END_OF_FILE       := $4C
ERR_ACCESS_ERROR      := $4E
ERR_DUPLICATE_VOLUME  := $57

;;; ============================================================
;;; Misc Structures
;;; ============================================================

.struct DateTime
        datelo  .byte
        datehi  .byte
        timelo  .byte
        timehi  .byte
.endstruct

;;; ============================================================
;;; Directory Structures
;;; ============================================================

STORAGE_TYPE_MASK       := $F0
NAME_LENGTH_MASK        := $0F

;;; Volume Directory Header structure
.struct VolumeDirectoryHeader
        prev_block      .word
        next_block      .word
        storage_type_name_length        .byte
        file_name       .byte 15
        reserved        .byte 8
        creation_date   .word
        creation_time   .word
        version         .byte
        min_version     .byte
        access          .byte
        entry_length    .byte
        entries_per_block       .byte
        file_count      .word
        ;; same through here ---------
        bit_map_pointer .word
        total_blocks    .word
.endstruct
        .assert .sizeof(VolumeDirectoryHeader) = $2B, error, "incorrect struct size"

;;; Subdirectory Header structure
.struct SubdirectoryHeader
        prev_block      .word
        next_block      .word
        storage_type_name_length        .byte
        file_name       .byte 15
        reserved        .byte 8
        creation_date   .word
        creation_time   .word
        version         .byte
        min_version     .byte
        access          .byte
        entry_length    .byte
        entries_per_block       .byte
        file_count      .word
        ;; same through here ---------
        parent_pointer .word
        parent_entry_number .byte
        parent_entry_length .byte
.endstruct
        .assert .sizeof(SubdirectoryHeader) = $2B, error, "incorrect struct size"

;; File Entry structure
.struct FileEntry
        storage_type_name_length        .byte
        file_name       .byte 15
        file_type       .byte
        key_pointer     .word
        blocks_used     .word
        eof             .faraddr
        creation_date   .word
        creation_time   .word
        version         .byte
        min_version     .byte
        access          .byte
        aux_type        .word
        mod_date        .word
        mod_time        .word
        header_pointer  .word
.endstruct
        .assert .sizeof(FileEntry) = $27, error, "incorrect struct size"

;;; ============================================================
;;; ProDOS Driver Protocol
;;; ============================================================

;;; Addresses for command parameters
DRIVER_COMMAND          := $42
DRIVER_UNIT_NUMBER      := $43
DRIVER_BUFFER           := $44
DRIVER_BLOCK_NUMBER     := $46

;;; Commands
DRIVER_COMMAND_STATUS  := 0
DRIVER_COMMAND_READ    := 1
DRIVER_COMMAND_WRITE   := 2
DRIVER_COMMAND_FORMAT  := 3


;;; ============================================================
;;; Macros
;;; ============================================================

.macro  MLI_CALL    op, addr
        jsr MLI
        .byte op
        .addr addr
.endmacro

.macro DEFINE_OPEN_PARAMS name, pn, io, rn
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .if .xmatch(.string(io), "io_buffer")
        .error "Can't pass 'io_buffer' label to DEFINE_*_PARAMS"
    .endif
.proc name
param_count:    .byte   3
pathname:       .addr   pn
io_buffer:      .addr   io
    .ifnblank rn
ref_num:        .byte   rn
    .else
ref_num:        .byte   0
    .endif
.endproc
.endmacro

.macro DEFINE_READ_PARAMS name, db, rc
.proc name
param_count:    .byte   4
ref_num:        .byte   0
data_buffer:    .addr   db
request_count:  .word   rc
trans_count:    .word   0
.endproc
.endmacro

.macro DEFINE_WRITE_PARAMS name, db, rc
.proc name
param_count:    .byte   4
ref_num:        .byte   0
data_buffer:    .addr   db
request_count:  .word   rc
trans_count:    .word   0
.endproc
.endmacro

.macro DEFINE_CLOSE_PARAMS name
.proc name
param_count:    .byte   1
ref_num:        .byte   0
.endproc
.endmacro

.macro DEFINE_FLUSH_PARAMS name
.proc name
param_count:    .byte   1
ref_num:        .byte   0
.endproc
.endmacro

.macro DEFINE_GET_FILE_INFO_PARAMS name, pn
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
.proc name
param_count:    .byte  $A
pathname:       .addr   pn
access:         .byte   0
file_type:      .byte   0
aux_type:       .word   0
storage_type:   .byte   0
blocks_used:    .word   0
mod_date:       .word   0
mod_time:       .word   0
create_date:    .word   0
create_time:    .word   0
.endproc
.endmacro

.macro DEFINE_SET_MARK_PARAMS name, pos
.proc name
param_count:    .byte   2
ref_num:        .byte   0
position:       .faraddr pos
.endproc
.endmacro

.macro DEFINE_ON_LINE_PARAMS name, un, db
.proc name
param_count:    .byte   2

    .ifnblank un
unit_num:       .byte   un
    .else
unit_num:       .byte   0
    .endif

data_buffer:    .addr   db
.endproc
.endmacro

.macro DEFINE_READ_BLOCK_PARAMS name, db, bn
.proc name
param_count:    .byte   3
unit_num:       .byte   0
data_buffer:    .addr   db
block_num:      .word   bn
.endproc
.endmacro


.macro DEFINE_WRITE_BLOCK_PARAMS name, db, bn
.proc name
param_count:    .byte   3
unit_num:       .byte   0
data_buffer:    .addr   db
block_num:      .word   bn
.endproc
.endmacro

.macro DEFINE_ALLOC_INTERRUPT_PARAMS name, ic
.proc alloc_interrupt_params
param_count:    .byte   2
int_num:        .byte   0
int_code:       .addr   ic
.endproc
.endmacro

.macro DEFINE_DEALLOC_INTERRUPT_PARAMS name
.proc dealloc_interrupt_params
param_count:    .byte   1
int_num:        .byte   0
.endproc
.endmacro

.macro DEFINE_QUIT_PARAMS name, ext, pathname
.proc name
param_count:    .byte   4
    .ifnblank ext
        .byte   ext
    .else
        .byte   0
    .endif
    .ifnblank pathname
        .word   pathname
    .else
        .word   0
    .endif
        .byte   0
        .word   0
.endproc
.endmacro

.macro DEFINE_SET_PREFIX_PARAMS name, pn
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
.proc name
param_count:    .byte   1
pathname:       .addr   pn
.endproc
.endmacro

.macro DEFINE_GET_PREFIX_PARAMS name, pn
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
.proc name
param_count:    .byte   1
pathname:       .addr   pn
.endproc
.endmacro

.macro DEFINE_DESTROY_PARAMS name, pn
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
.proc name
param_count:    .byte   1
pathname:       .addr   pn
.endproc
.endmacro

.macro DEFINE_CREATE_PARAMS name, pn, ac, ft, at, st
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
.proc name
param_count:    .byte   7
pathname:       .addr   pn

    .ifnblank ac
access: .byte   ac
    .else
access: .byte   0
    .endif

    .ifnblank ft
file_type:      .byte   ft
    .else
file_type:      .byte   0
    .endif

    .ifnblank at
aux_type:       .word   at
    .else
aux_type:       .word   0
    .endif

    .ifnblank st
storage_type:   .byte   st
    .else
storage_type:   .byte   0
    .endif

create_date:    .word   0
create_time:    .word   0
.endproc
.endmacro

.macro DEFINE_SET_EOF_PARAMS name, eo
.proc name
param_count:    .byte   2
ref_num:        .byte   0
eof:            .faraddr eo
.endproc
.endmacro

.macro DEFINE_GET_EOF_PARAMS name
.proc name
param_count:    .byte   2
ref_num:        .byte   0
eof:            .faraddr 0
.endproc
.endmacro

.macro DEFINE_RENAME_PARAMS name, pn, np
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
.proc name
param_count:    .byte   2
pathname:       .addr   pn
new_pathname:   .addr   np
.endproc
.endmacro
