;;; ============================================================
;;;
;;; ProDOS MLI
;;;
;;; ============================================================

.ifndef PRODOS_INC
PRODOS_INC = 1

;;; Entry point / Global Page
MLI             := $BF00        ; Entry point
DATETIME        := $BF06        ; JMP to clock routine
DEVADR          := $BF10        ; Device driver addresses ($BF10-$BF2F)
NODEV           := $BF10        ; "No Device Connected" entry (slot 0)
RAMSLOT         := $BF26        ; Slot 3, Drive 2 is /RAM's driver vector
DEVNUM          := $BF30        ; Most recent accessed device
DEVCNT          := $BF31        ; Number of on-line devices minus 1
DEVLST          := $BF32        ; Up to 14 units ($BF32-$BF3F)
BITMAP          := $BF58        ; System memory bitmap
BITMAP_SIZE     = $18           ; Bits for pages $00 to $BF
DATELO          := $BF90        ; Date lo
DATEHI          := $BF91        ; Date hi
TIMELO          := $BF92        ; Time lo
TIMEHI          := $BF93        ; Time hi
LEVEL           := $BF94        ; File level
MACHID          := $BF98        ; Machine ID

  kMachIDSysType  = %11000000   ; bits 6,7 = system type (see bit 3)
  kMachIDHas128k  = %00110000   ; bits 4,5 = 128k if both set (else < 128k)
  kMachIDSysMod   = %00001000   ; bit 3 = modifies bit 6/7 decoding
  kMachIDReserved = %00000100   ; bit 2 = RESERVED
  kMachIDHas80Col = %00000010   ; bit 1 = has 80 col card
  kMachIDHasClock = %00000001   ; bit 0 = has clock card

SLTBYT          := $BF99        ; '1' bits indicate rom in slot (bit#)
IVERSION        := $BFFD        ; Interpreter Version
KVERSION        := $BFFF        ; ProDOS Kernel Version

;;; Patch Locations
SELECTOR        := $D100        ; QUIT handler address in LCBANK2
SELECTOR_ORG    := $1000        ; QUIT handler execution load address


BLOCK_SIZE      = $200

kVolumeDirKeyBlock = 2
kVolumeBitmapBlock = 6          ; first block of volume bitmap

;;; ============================================================
;;; Unit Numbers
;;; ============================================================

;;; Mask needed when preparing a `DEVLST` entry for:
;;; * Filling `DRIVER_UNIT_NUMBER` before a driver call
;;; * Preparing params for an `ON_LINE` call
;;; * Comparing against `DEVNUM`
;;; * Looking up a driver address in `DEVADR` (mask then LSR 3x)
;;; * Extracting the slot and drive (high bits are DSSS)
.ifndef PRODOS_2_5
UNIT_NUM_MASK   = $F0           ; DSSS0000
.else
;;; Per https://prodos8.com/releases/prodos-25/
UNIT_NUM_MASK   = $FF           ; DSSS00XY (but preserve all bits)
.endif ; PRODOS_2_5

;;; Mask off just the slot bits from a unit number. Used when
;;; constructing $Cn00 pointer to probe firmware.
UNIT_NUM_SLOT_MASK      = %01110000 ; 0SSS0000

;;; ============================================================
;;; MLI Calls
;;; ============================================================

;;; Housekeeping Calls
CREATE          = $C0
DESTROY         = $C1
RENAME          = $C2
SET_FILE_INFO   = $C3
GET_FILE_INFO   = $C4
ON_LINE         = $C5
SET_PREFIX      = $C6
GET_PREFIX      = $C7

;;; Filing Calls
OPEN            = $C8
NEWLINE         = $C9
READ            = $CA
WRITE           = $CB
CLOSE           = $CC
FLUSH           = $CD
SET_MARK        = $CE
GET_MARK        = $CF
SET_EOF         = $D0
GET_EOF         = $D1
SET_BUF         = $D2
GET_BUF         = $D3

;;; System Calls
GET_TIME        = $82
ALLOC_INTERRUPT = $40
DEALLOC_INTERRUPT       = $41
QUIT            = $65

;;; Direct Disk Access Commands
READ_BLOCK      = $80
WRITE_BLOCK     = $81


;;; ============================================================
;;; File Types
;;; ============================================================

FT_TYPELESS     = $00
FT_BAD          = $01
FT_TEXT         = $04           ; ASCII Text File *
FT_BINARY       = $06           ; Generic Binary File *
FT_FONT         = $07           ; Font File
FT_GRAPHICS     = $08           ; Graphics File
FT_DIRECTORY    = $0F           ; Directory *
FT_ADB          = $19           ; AppleWorks Database *
FT_AWP          = $1A           ; AppleWorks Word Processing *
FT_ASP          = $1B           ; AppleWorks Spreadsheet *
FT_ANIMATION    = $5B           ; Animation/Video file
FT_ENTERTAINMENT= $5D           ; Entertainment
FT_SRC          = $B0           ; IIgs system type; re-used?
FT_S16          = $B3           ; IIgs Application Program
FT_PNT          = $C0           ; IIgs Packed Super Hi-Res picture
FT_PIC          = $C1           ; IIgs Super Hi-Res picture
FT_MUSIC        = $D5           ; Music File
FT_SOUND        = $D8           ; Sampled Sound File
FT_SPEECH       = $D9           ; Speech (e.g. Text-to-Speech)
FT_ARCHIVE      = $E0           ; Archival library
FT_LINK         = $E1           ; Link
FT_PAS          = $EF           ; Pascal Area *
FT_CMD          = $F0           ; ProDOS Command File *
FT_INT          = $FA           ; Integer BASIC Program *
FT_IVR          = $FB           ; Integer BASIC Variable File *
FT_BASIC        = $FC           ; Applesoft BASIC Program *
FT_VAR          = $FD           ; Applesoft BASIC Variable File *
FT_REL          = $FE           ; EDASM/Contiki Relocatable File *
FT_SYSTEM       = $FF           ; ProDOS System File *

;;; Types marked with * are known to BASIC.SYSTEM and have an
;;; associated three-letter abbreviation.

;;; ============================================================
;;; System Files
;;; ============================================================

;;; ProDOS 8 TRM 5.1.5.1 - Starting System Programs
;;; http://www.easy68k.com/paulrsm/6502/PDOS8TRM.HTM#5.1.5.1

PRODOS_SYS_START        := $2000
PRODOS_INTERPRETER_BUF  := $2006
PRODOS_SYS_PATH         := $280

;;; ============================================================
;;; Access
;;; ============================================================

ACCESS_D  = %10000000           ; Access: Destroy-Enable
ACCESS_RN = %01000000           ; Access: Rename-Enable
ACCESS_B  = %00100000           ; Access: Backup
ACCESS_I  = %00000100           ; Access: Invisible
ACCESS_W  = %00000010           ; Access: Write-Enable
ACCESS_R  = %00000001           ; Access: Read-Enable

ACCESS_DEFAULT  = ACCESS_D | ACCESS_RN | ACCESS_W | ACCESS_R
LOCKED_MASK     = %11000010     ; all 0 = locked, all 1 = unlocked

;;; ============================================================
;;; Storage Types
;;; ============================================================

ST_SEEDLING_FILE        = $01
ST_SAPLING_FILE         = $02
ST_TREE_FILE            = $03
ST_PASCAL_AREA          = $04   ; not supported by DeskTop
ST_FORKED_FILE          = $05   ; not supported by DeskTop
ST_LINKED_DIRECTORY     = $0D
ST_VOLUME_DIRECTORY     = $0F

;;; ============================================================
;;; Errors
;;; ============================================================

ERR_IO_ERROR          = $27
ERR_DEVICE_NOT_CONNECTED = $28
ERR_WRITE_PROTECTED   = $2B
ERR_DEVICE_OFFLINE    = $2F     ; Technical Note: ProDOS #21: Identifying ProDOS Devices
ERR_INVALID_PATHNAME  = $40
ERR_INVALID_REFERENCE = $43
ERR_PATH_NOT_FOUND    = $44
ERR_VOL_NOT_FOUND     = $45
ERR_FILE_NOT_FOUND    = $46
ERR_DUPLICATE_FILENAME= $47
ERR_OVERRUN_ERROR     = $48
ERR_VOLUME_DIR_FULL   = $49
ERR_END_OF_FILE       = $4C
ERR_ACCESS_ERROR      = $4E
ERR_NOT_PRODOS_VOLUME = $52
ERR_DUPLICATE_VOLUME  = $57
ERR_NETWORK_ERROR     = $88

;;; ============================================================
;;; Misc Structures
;;; ============================================================

;;; DateTime:
;;;
;;;       byte 1            byte 0
;;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
;;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;;; |    Year     |  Month  |   Day   |
;;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;;;
;;;       byte 3            byte 2
;;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
;;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;;; |0 0 0|  Hour   | |0 0|  Minute   |
;;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+

.struct DateTime
        datelo  .byte
        datehi  .byte
        timelo  .byte
        timehi  .byte
.endstruct

;;; ============================================================
;;; Directory Structures
;;; ============================================================

STORAGE_TYPE_MASK       = $F0
NAME_LENGTH_MASK        = $0F

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
        ASSERT_EQUALS .sizeof(VolumeDirectoryHeader), $2B
        VolumeDirectoryHeader::case_bits = $1A

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
        ASSERT_EQUALS .sizeof(SubdirectoryHeader), $2B

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
        ASSERT_EQUALS .sizeof(FileEntry), $27
        FileEntry::case_bits = FileEntry::version

;;; ============================================================
;;; ProDOS Driver Protocol
;;; ============================================================

;;; While described in the ProDOS 8 Technical Reference Manual, that
;;; document targets device implementers. For more complete
;;; documentation about calling into drivers, see "Beneath Apple
;;; ProDOS", section "Calling a Storage Device Driver") pp. 6-6
;;; through 6-11, Don Worth and Pieter Lechner, 1985.

;;; Addresses for command parameters
DRIVER_COMMAND          := $42
DRIVER_UNIT_NUMBER      := $43
DRIVER_BUFFER           := $44
DRIVER_BLOCK_NUMBER     := $46

;;; Commands
DRIVER_COMMAND_STATUS  = 0
DRIVER_COMMAND_READ    = 1
DRIVER_COMMAND_WRITE   = 2
DRIVER_COMMAND_FORMAT  = 3


;;; ============================================================
;;; Macros
;;; ============================================================

;;; Scopes define their own MLIEntry identifiers (e.g. MLIEntry := MLI)
;;; This allows for helpers that e.g. bank switch before calling.
.macro MLI_CALL call, addr
        jsr     MLIEntry
        .byte   call
    .if .paramcount > 1
        .addr   addr
    .else
        .addr   0
    .endif
.endmacro


.macro DEFINE_OPEN_PARAMS name, pn, io
        WARN_IF_SHADOWING name
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .if .xmatch(.string(io), "io_buffer")
        .error "Can't pass 'io_buffer' label to DEFINE_*_PARAMS"
    .endif
    .assert pn < $C000, error, "MLI params can't be in LC RAM"
.params name
param_count:    .byte   3
pathname:       .addr   pn
io_buffer:      .addr   io
ref_num:        .byte   0
        .refto param_count
        .refto pathname
        .refto io_buffer
        .refto ref_num
.endparams
.endmacro

.macro DEFINE_READWRITE_PARAMS name, db, rc
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   4
ref_num:        .byte   0
data_buffer:    .addr   db
request_count:  .word   rc
trans_count:    .word   0
        .refto param_count
        .refto ref_num
        .refto data_buffer
        .refto request_count
        .refto trans_count
.endparams
.endmacro

.macro DEFINE_CLOSE_PARAMS name
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   1
ref_num:        .byte   0
        .refto param_count
        .refto ref_num
.endparams
.endmacro

.macro DEFINE_FLUSH_PARAMS name
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   1
ref_num:        .byte   0
        .refto param_count
        .refto ref_num
.endparams
.endmacro

.macro DEFINE_GET_FILE_INFO_PARAMS name, pn
        WARN_IF_SHADOWING name
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .assert pn < $C000, error, "MLI params can't be in LC RAM"
.params name
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
        .refto param_count
        .refto pathname
        .refto access
        .refto file_type
        .refto aux_type
        .refto storage_type
        .refto blocks_used
        .refto mod_date
        .refto mod_time
        .refto create_date
        .refto create_time
.endparams
.endmacro

.macro DEFINE_SET_MARK_PARAMS name, pos
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   2
ref_num:        .byte   0
position:       .faraddr pos
        .refto param_count
        .refto ref_num
        .refto position
.endparams
.endmacro

.macro DEFINE_ON_LINE_PARAMS name, un, db
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   2

    .ifnblank un
unit_num:       .byte   un
    .else
unit_num:       .byte   0
    .endif

data_buffer:    .addr   db
        .refto param_count
        .refto unit_num
        .refto data_buffer
.endparams
.endmacro

.macro DEFINE_READWRITE_BLOCK_PARAMS name, db, bn
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   3
unit_num:       .byte   0
data_buffer:    .addr   db
block_num:      .word   bn
        .refto param_count
        .refto unit_num
        .refto data_buffer
        .refto block_num
.endparams
.endmacro

.macro DEFINE_ALLOC_INTERRUPT_PARAMS name, ic
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   2
int_num:        .byte   0
int_code:       .addr   ic
        .refto param_count
        .refto int_num
        .refto int_code
.endparams
.endmacro

.macro DEFINE_DEALLOC_INTERRUPT_PARAMS name
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   1
int_num:        .byte   0
        .refto param_count
        .refto int_num
.endparams
.endmacro

.macro DEFINE_QUIT_PARAMS name, type, pathname
        WARN_IF_SHADOWING name
    .ifnblank pathname
        .assert pathname < $C000, error, "MLI params can't be in LC RAM"
    .endif
.params name
param_count:    .byte   4
quit_type:
    .ifnblank type
        .byte   type
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
        .refto param_count
        .refto quit_type
.endparams
.endmacro

.macro DEFINE_SET_PREFIX_PARAMS name, pn
        WARN_IF_SHADOWING name
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .assert pn < $C000, error, "MLI params can't be in LC RAM"
.params name
param_count:    .byte   1
pathname:       .addr   pn
        .refto param_count
        .refto pathname
.endparams
.endmacro

.macro DEFINE_GET_PREFIX_PARAMS name, pn
        WARN_IF_SHADOWING name
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .assert pn < $C000, error, "MLI params can't be in LC RAM"
.params name
param_count:    .byte   1
pathname:       .addr   pn
        .refto param_count
        .refto pathname
.endparams
.endmacro

.macro DEFINE_DESTROY_PARAMS name, pn
        WARN_IF_SHADOWING name
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .assert pn < $C000, error, "MLI params can't be in LC RAM"
.params name
param_count:    .byte   1
pathname:       .addr   pn
        .refto param_count
        .refto pathname
.endparams
.endmacro

.macro DEFINE_CREATE_PARAMS name, pn, ac, ft, at, st
        WARN_IF_SHADOWING name
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .assert pn < $C000, error, "MLI params can't be in LC RAM"
.params name
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
        .refto param_count
        .refto pathname
        .refto access
        .refto file_type
        .refto aux_type
        .refto storage_type
        .refto create_date
        .refto create_time
.endparams
.endmacro

.macro DEFINE_SET_EOF_PARAMS name, eo
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   2
ref_num:        .byte   0
eof:            .faraddr eo
        .refto param_count
        .refto ref_num
        .refto eof
.endparams
.endmacro

.macro DEFINE_GET_EOF_PARAMS name
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   2
ref_num:        .byte   0
eof:            .faraddr 0
        .refto param_count
        .refto ref_num
        .refto eof
.endparams
.endmacro

.macro DEFINE_RENAME_PARAMS name, pn, np
        WARN_IF_SHADOWING name
    .if .xmatch(.string(pn), "pathname")
        ;; If 'pathname' is passed then expansion yields a circular reference.
        .error "Can't pass 'pathname' label to DEFINE_*_PARAMS"
    .endif
    .assert pn < $C000, error, "MLI params can't be in LC RAM"
.params name
param_count:    .byte   2
pathname:       .addr   pn
new_pathname:   .addr   np
        .refto param_count
        .refto pathname
        .refto new_pathname
.endparams
.endmacro

.endif ; PRODOS_INC
