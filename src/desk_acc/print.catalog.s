;;; ============================================================
;;; PRINT.CATALOG - Desk Accessory
;;;
;;; Prints a recursive catalog for the current window (or all
;;; volumes) to a printer in Slot 1.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "print.catalog.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          | IO Buffer   | |             |
;;;  $1C00   +-------------+ |             |
;;;          | Dir Block   | |             |
;;;  $1A00   +-------------+ |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | code        | |             |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;

;;; ============================================================

        DA_HEADER
        DA_START_MAIN_SEGMENT

;;; ============================================================

        block_buffer := $1A00

        SLOT1   := $C100

.scope
        ptr := $06

        ;; Try to verify a printer card in slot 1
        CALL    CheckSlot1Signature, AX=#sigtable_printer
    IF ZC
        CALL    CheckSlot1Signature, AX=#sigtable_ssc
      IF ZC
        CALL    CheckSlot1Signature, AX=#sigtable_parallel
       IF ZC
        TAIL_CALL JUMP_TABLE_SHOW_ALERT, A=#ERR_DEVICE_NOT_CONNECTED
       END_IF
      END_IF
    END_IF

        ;; Get top DeskTop window (if any) and find its path
        JUMP_TABLE_MGTK_CALL MGTK::FrontWindow, ptr
        lda     ptr             ; any window open?
        beq     no_windows
        cmp     #kMaxDeskTopWindows+1
        bcs     no_windows

        ;; --------------------------------------------------
        ;; Get path for window

        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    ptr

        ;; Copy path to our path buffer
        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, searchPath,y
        dey
    WHILE POS

        ;; Append '/' needed by algorithm
        ldy     searchPath
        iny
        copy8   #'/', searchPath,y
        sty     searchPath

        CLEAR_BIT7_FLAG vol_flag

        jmp     continue

        ;; --------------------------------------------------
        ;; Search all volumes

no_windows:
        ;; Signal this mode with a path of just "/"
        copy8   #1, searchPath
        copy8   #'/', searchPath+1

        SET_BIT7_FLAG vol_flag

        ;; --------------------------------------------------

continue:
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        ;; SSC operations trash the text page (if 80 col firmware active?)
        jsr     SaveTextPage

        CALL    GoCard, Y=#SSC::PInit

        ;; Init IW2 settings
        ldx     #0
    DO
        CALL    COut, A=iw2_init,x
        inx
    WHILE X <> #kLenIW2Init

        ;; Recurse and print
        jsr     PrintCatalog

        jsr     RestoreTextPage
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts

PrintCatalog:
        ;; Header
        ldx     #0
    DO
        CALL    COut, A=str_header+1,x
        inx
    WHILE X <> str_header
        jsr     CROut

        ;; If we're doing multiple volumes, get started
        bit     vol_flag
    IF NS
        jsr     InitVolumes
        jsr     NextVolume
        bcs     finish
    END_IF

        ;; Show the current path
next:
        ldx     #0
    DO
        CALL    COut, A=searchPath+1,x
        inx
    WHILE X < searchPath
        jsr     CROut
        copy8   #1, indent

        ;; And invoke it!
        jsr     ::RecursiveCatalog::Start

        ;; If we're doing multiple volumes, do the next one
        bit     vol_flag
    IF NS
        jsr     NextVolume
        bcc     next
    END_IF

finish: jmp     CROut
.endscope

ch:     .byte   0               ; cursor horizontal position

vol_flag:
        .byte   0               ; high bit set if we're iterating volumes
indent:
        .byte   0

str_header:
        PASCAL_STRING .sprintf("%28s%6s%6s  %s", res_string_col_name, res_string_col_type, res_string_col_blocks, res_string_col_modified)
        kColType   = 30         ; Left aligned
        kTypeWidth = 3
        kColBlocks = 41         ; Right aligned
        kBlocksWidth = 6
        kColMod    = 49

iw2_init:
        .byte   CHAR_ESCAPE, 'Z', $80, $00 ; disable automatic LF after CR
        kLenIW2Init = * - iw2_init

;;; ============================================================

;;; Input: A,X = pointer to table (num, offset, mask, value, offset, mask, value, ...)
;;; Output: Z=1 on match, Z=0 on no match
.proc CheckSlot1Signature
        ptr := $06

        stax    ptr

        ldy     #0
        copy8   (ptr),y, count ; first byte in table is number of tuples
    DO
        iny
        lda     (ptr),y
        tax
        lda     SLOT1,x
        iny
        and     (ptr),y
        iny
        BREAK_IF A <> (ptr),y

        dec     count
    WHILE NOT_ZERO

        rts

count:  .byte   0
.endproc ; CheckSlot1Signature

;;; Format: count, offset1, mask1, value1, offset2, mask2, value2, ...
sigtable_ssc:           .byte   4, $05, $FF, $38, $07, $FF, $18, $0B, $FF, $01, $0C, $FF, $31
sigtable_printer:       .byte   4, $05, $FF, $38, $07, $FF, $18, $0B, $FF, $01, $0C, $F0, $10
sigtable_parallel:      .byte   2, $05, $FF, $48, $07, $FF, $48

;;; ============================================================
;;;
;;;******************************************************
;;;
;;; ProDOS command parameter blocks
;;;
        DEFINE_OPEN_PARAMS OpenParms, 0, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS ReadParms, block_buffer, 512
        DEFINE_CLOSE_PARAMS CloseParms
        DEFINE_SET_MARK_PARAMS SetMParms, 0

searchPath:     .res    ::kPathBufferSize
nameBuffer:     .res    ::kPathBufferSize ; space for directory name

;;;******************************************************

.scope RecursiveCatalog


;;;******************************************************
;;; ProDOS #17
;;; Recursive ProDOS Catalog Routine
;;;
;;; Revised by Dave Lyons, Keith Rollin, & Matt Deatherage (November 1989)
;;; Written by Greg Seitz (December 1983)
;;;
;;; From https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.17.html
;;;
;;; * Converted to ca65 syntax
;;; * Using A2D headers/macros
;;; * Use procs
;;; * Prevent excessive recursion
;;;******************************************************


;;;******************************************************
;;;
;;; Recursive ProDOS Catalog Routine
;;;
;;; by: Greg Seitz 12/83
;;; Pete McDonald 1/86
;;; Keith Rollin 7/88
;;; Dave Lyons 11/89
;;;
;;; This program shows the latest "Apple Approved"
;;; method for reading a directory under ProDOS 8.
;;; READ_BLOCK is not used, since it is incompatible
;;; with AppleShare file servers.
;;;
;;; November 1989: The file_count field is no longer
;;; used (all references to ThisEntry were removed).
;;; This is because the file count can change on the fly
;;; on AppleShare volumes.  (Note that the old code was
;;; accidentally decrementing the file count when it
;;; found an entry for a deleted file, so some files
;;; could be left off the end of the list.)
;;;
;;; Also, ThisBlock now gets incremented when a chunk
;;; of data is read from a directory.  Previously, this
;;; routine could get stuck in an endless loop when
;;; a subdirectory was found outside the first block of
;;; its parent directory.
;;;
;;; Limitations:  This routine cannot reach any
;;; subdirectory whose pathname is longer than 64
;;; characters, and it will not operate correctly if
;;; any subdirectory is more than 255 blocks long
;;; (because ThisBlock is only one byte).
;;;
;;;******************************************************
;;;
;;; Equates
;;;
;;; Zero page locations
;;;
dirName := $06                  ; pointer to directory name
entPtr  := $08                  ; ptr to current entry

;;;******************************************************
saved_stack:
        .byte   0

.proc Start
        bit     KBDSTRB         ; clear strobe

        ldy     searchPath      ; prime the search path
    DO
        copy8   searchPath,y, nameBuffer,y
        dey
    WHILE POS

        lda     #0              ; reset recursion/results state
        sta     Depth

        jsr     Relay           ; for stack restore

        rts

.proc Relay
        tsx
        stx     saved_stack

        TAIL_CALL ReadDir, AX=#nameBuffer
.endproc ; Relay
.endproc ; Start

.proc Terminate
        JUMP_TABLE_MLI_CALL CLOSE, CloseParms ; close the directory

        ldx     saved_stack
        txs

        rts
.endproc ; Terminate

;;;
;;;******************************************************
;;;******************************************************
;;;
.proc ReadDir
;;;
;;; This is the actual recursive routine. It takes as
;;; input a pointer to the directory name to read in
;;; A,X (lo,hi), opens it, and starts to read the
;;; entries. When it encounters a filename, it calls
;;; the routine "VisitFile". When it encounters a
;;; directory name, it calls "VisitDir".
;;;
;;; The directory pathname string must end with a "/"
;;; character.
;;;
;;;******************************************************
;;;
        stax    dirName         ; save a pointer to name

        stax    OpenParms::pathname ; set up OpenFile params

ReadDir1:                       ; recursive entry point
        jsr     OpenDir         ; open the directory as a file
        bcs     done

        jmp     nextEntry       ; jump to the end of the loop

loop:
        CALL    JUMP_TABLE_ADJUST_FILEENTRY, AX=entPtr

        ldy     #FileEntry::storage_type_name_length ; get type of current entry
        lda     (entPtr),y
        and     #STORAGE_TYPE_MASK ; look at 4 high bits
        cmp     #0              ; inactive entry?
        beq     nextEntry       ; yes - bump to next one
        cmp     #(ST_LINKED_DIRECTORY<<4) ; is it a directory?
        beq     ItsADir         ; yes, so call VisitDir
        jsr     VisitFile       ; no, it's a file
        jmp     nextEntry

ItsADir:
        jsr     VisitDir

nextEntry:
        lda     KBD
    IF NS
        sta     KBDSTRB
        cmp     #$80|CHAR_ESCAPE
        beq     Terminate
    END_IF

        jsr     GetNext         ; get pointer to next entry
        bcc     loop            ; Carry set means we're done
done:                           ; moved before PHA (11/89 DAL)
        pha                     ; save error code

        JUMP_TABLE_MLI_CALL CLOSE, CloseParms ; close the directory

        pla                     ;we're expecting EndOfFile error
        cmp     #ERR_END_OF_FILE
        beq     hitDirEnd

hitDirEnd:
        rts
;;;
;;;******************************************************
;;;
.proc OpenDir
;;;
;;; Opens the directory pointed to by OpenParms
;;; parameter block. This pointer should be init-
;;; ialized BEFORE this routine is called. If the
;;; file is successfully opened, the following
;;; variables are set:
;;;
;;; xRefNum     ; all the refnums
;;; entryLen    ; size of directory entries
;;; entPtr      ; pointer to current entry
;;; ThisBEntry  ; entry number within this block
;;; ThisBlock   ; offset (in blocks) into dir.
;;;
        JUMP_TABLE_MLI_CALL OPEN, OpenParms ; open dir as a file
        bcs     OpenDone

        lda     OpenParms::ref_num  ; copy the refnum return-
        sta     ReadParms::ref_num  ; ed by Open into the
        sta     CloseParms::ref_num ; other param blocks.
        sta     SetMParms::ref_num

        JUMP_TABLE_MLI_CALL READ, ReadParms ; read the first block
        bcs     OpenDone

        copy8   block_buffer+SubdirectoryHeader::entry_length, entryLen ; init 'entryLen'

        copy16  #(block_buffer+4), z:entPtr ; init ptr to first entry

        lda     block_buffer+SubdirectoryHeader::entries_per_block ; init these values based on
        sta     ThisBEntry      ; values in the dir header
        sta     entPerBlk

        copy8   #0, ThisBlock   ; init block offset into dir.

        clc                     ; say that open was OK

OpenDone:
        rts
.endproc ; OpenDir

;;;
;;;******************************************************
;;;
.proc VisitFile
        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsShowInvisible
    IF ZERO
        ;; Is the file visible?
        ldy     #FileEntry::access
        lda     (entPtr),y
        and     #ACCESS_I
        RTS_IF NOT_ZERO
    END_IF

        jsr     PrintName

        ldx     #kColType
        lda     #' '
    DO
        jsr     COut
    WHILE X >= ch

        jsr     PrintType
        jsr     PrintSize
        jsr     PrintDate

        jmp     CROut
.endproc ; VisitFile

;;; --------------------------------------------------

.proc PrintName
        ;; Print indentation
        ldx     indent
    IF NOT_ZERO
        lda     #' '
      DO
        jsr     COut
        jsr     COut
        dex
      WHILE NOT_ZERO
    END_IF

        ;; Print name
        ldy     #FileEntry::storage_type_name_length
        lda     (entPtr),y
        and     #NAME_LENGTH_MASK
        tax
        ldy     #1
    DO
        CALL    COut, A=(entPtr),y
        iny
        dex
    WHILE NOT_ZERO

        rts
.endproc ; PrintName

;;; --------------------------------------------------

.proc PrintType
        ldy     #FileEntry::file_type
        lda     (entPtr),y

        jsr     ComposeFileTypeString
        ldx     #0
    DO
        CALL    COut, A=str_file_type+1,x
        inx
    WHILE X <> str_file_type

        rts
.endproc ; PrintType

;;; --------------------------------------------------

.proc PrintSize
        ;; Load block count into A,X
        ldy     #FileEntry::blocks_used+1
        lda     (entPtr),y
        tax
        dey
        lda     (entPtr),y

        ;; Compose string
        jsr     IntToString

        ;; Left-pad it
        ldx     #kColBlocks - kColType - kTypeWidth
        lda     #' '
    DO
        jsr     COut
        dex
    WHILE X <> str_from_int

        ;; Print it
        ldx     #0
    DO
        CALL    COut, A=str_from_int+1,x
        inx
    WHILE X <> str_from_int

        rts
.endproc ; PrintSize

;;; --------------------------------------------------

.proc PrintDate
        ;;       byte 1            byte 0
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |    Year     |  Month  |   Day   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+

        ;; Day
        ldy     #FileEntry::mod_date
        lda     (entPtr),y
        and     #%00011111      ; lo
        ldx     #0              ; hi
        jsr     IntToString
        lda     str_from_int
    IF A = #1
        lda     #' '
        ldx     str_from_int+1
    ELSE
        lda     str_from_int+1
        ldx     str_from_int+2
    END_IF
        sta     str_date+1
        stx     str_date+2

        ;; Month
        ldy     #FileEntry::mod_date+1
        lda     (entPtr),y
        lsr
        dey
        lda     (entPtr),y
        and     #%11100000
        ror                     ; A = MMMM0000
        lsr                     ; A = 0MMMM000
        lsr                     ; A = 00MMMM00
        lsr                     ; A = 000MMMM0
        lsr                     ; A = 0000MMMM
        sta     tmp
        ;; Assert: C=0
        adc     tmp             ; A *= 2
        ;; Assert: C=0
        adc     tmp             ; A *= 3

        tax
        lda     month_names_table-3+0,x
        sta     str_date+4
        lda     month_names_table-3+1,x
        sta     str_date+5
        lda     month_names_table-3+2,x
        sta     str_date+6

        ;; Year
        ldy     #FileEntry::mod_date+1
        lda     (entPtr),y
        lsr                     ; A = 0YYYYYYY
    IF A >= #100
        sec
        sbc     #100
    END_IF
        ldx     #0              ; hi
        jsr     IntToString
        lda     str_from_int
    IF A = #1
        lda     #'0'
        ldx     str_from_int+1
    ELSE
        lda     str_from_int+1
        ldx     str_from_int+2
    END_IF
        sta     str_date+8
        stx     str_date+9

        ;; Pad it
        ldx     #kColMod - (kColBlocks + kBlocksWidth)
        lda     #' '
    DO
        jsr     COut
        dex
    WHILE NOT_ZERO

        ;; Print it
        ldx     #0
    DO
        CALL    COut, A=str_date+1,x
        inx
    WHILE X <> str_date

        rts

tmp:    .byte   0
.endproc ; PrintDate

;;;
;;;******************************************************
;;;
.proc VisitDir

        jsr     PrintName
        CALL    COut, A=#'/'
        jsr     CROut

        ;; 6 bytes + 3 return addresses = 12 bytes are pushed to stack on
        ;; in RecursDir; 12 * 16 = 192 bytes, which leaves enough room
        ;; on the stack above and below for safety.
        kMaxRecursionDepth = 16

        lda     Depth
    IF A < #kMaxRecursionDepth
        jmp     RecursDir       ; enumerate all entries in sub-dir.
    END_IF

        rts
.endproc ; VisitDir
;;;
;;;******************************************************
;;;
.proc RecursDir
;;;
;;; This routine calls ReadDir recursively. It
;;;
;;; - increments the recursion depth counter,
;;; - saves certain variables onto the stack
;;; - closes the current directory
;;; - creates the name of the new directory
;;; - calls ReadDir (recursively)
;;; - restores the variables from the stack
;;; - restores directory name to original value
;;; - re-opens the old directory
;;; - moves to our last position within it
;;; - decrements the recursion depth counter
;;;
        inc     Depth           ; bump this for recursive call
        inc     indent
;;;
;;; Save everything we can think of (the women,
;;; the children, the beer, etc.).
;;;
        lda     z:entPtr+1
        pha
        lda     z:entPtr
        pha
        lda     ThisBEntry
        pha
        lda     ThisBlock
        pha
        lda     entryLen
        pha
        lda     entPerBlk
        pha
;;;
;;; Close the current directory, as ReadDir will
;;; open files of its own, and we don't want to
;;; have a bunch of open files lying around.
;;;
        JUMP_TABLE_MLI_CALL CLOSE, CloseParms

        jsr     ExtendName      ; make new dir name

        jsr     ReadDir1        ; enumerate the subdirectory

        jsr     ChopName        ; restore old directory name

        jsr     OpenDir         ; re-open it back up
        bcc     reOpened
;;;
;;; Can't continue from this point -- exit in
;;; whatever way is appropriate for your
;;; program.
;;;

        jmp     Terminate

reOpened:
;;;
;;; Restore everything that we saved before
;;;
        pla
        sta     entPerBlk
        pla
        sta     entryLen
        pla
        sta     ThisBlock
        pla
        sta     ThisBEntry
        pla
        sta     z:entPtr
        pla
        sta     z:entPtr+1

        lda     #0
        sta     SetMParms::position
        sta     SetMParms::position+2
        lda     ThisBlock       ; reset last position in dir
        asl     a               ; = to block # times 512
        sta     SetMParms::position+1
        rol     SetMParms::position+2

        JUMP_TABLE_MLI_CALL SET_MARK, SetMParms ; reset the file marker

        JUMP_TABLE_MLI_CALL READ, ReadParms ; now read in the block we were on last.

        dec     Depth
        dec     indent
        rts
.endproc ; RecursDir

;;;
;;;******************************************************
;;;
.proc ExtendName
;;;
;;; Append the name in the current directory entry
;;; to the name in the directory name buffer. This
;;; will allow us to descend another level into the
;;; disk hierarchy when we call ReadDir.
;;;
        ldy     #FileEntry::storage_type_name_length ; get length of string to copy
        lda     (entPtr),y
        and     #NAME_LENGTH_MASK
        sta     extCnt          ; save the length here
        sty     srcPtr          ; init src ptr to zero

        ldy     #0              ; init dest ptr to end of
        lda     (dirName),y     ; the current directory name
        sta     destPtr

extloop:
        inc     srcPtr          ; bump to next char to read
        inc     destPtr         ; bump to next empty location
        ldy     srcPtr          ; get char of sub-dir name
        lda     (entPtr),y
        ldy     destPtr         ; tack on to end of cur. dir.
        sta     (dirName),y
        dec     extCnt          ; done all chars?
        bne     extloop         ; no - so do more

        iny
        lda     #'/'            ; tack "/" on to the end
        sta     (dirName),y

        tya                     ; fix length of filename to open
        ldy     #0
        sta     (dirName),y

        rts

extCnt:         .res    1
srcPtr:         .res    1
destPtr:        .res    1
.endproc ; ExtendName

;;;
;;;
;;;******************************************************
;;;
.proc ChopName
;;;
;;; Scans the current directory name, and chops
;;; off characters until it gets to a /.
;;;
        ldy     #0              ; get len of current dir.
        lda     (dirName),y
        tay
ChopLoop:
        dey                     ; bump to previous char
        lda     (dirName),y
        cmp     #'/'
        bne     ChopLoop
        tya
        ldy     #0
        sta     (dirName),y
        rts
.endproc ; ChopName

;;;
;;;******************************************************
;;;
.proc GetNext
;;;
;;; This routine is responsible for making a pointer
;;; to the next entry in the directory. If there are
;;; still entries to be processed in this block, then
;;; we simply bump the pointer by the size of the
;;; directory entry. If we have finished with this
;;; block, then we read in the next block, point to
;;; the first entry, and increment our block counter.
;;;
        dec     ThisBEntry      ; dec count for this block
        beq     ReadNext        ; done w/this block, get next one

        clc                     ; else bump up index
        lda     z:entPtr
        adc     entryLen
        sta     z:entPtr
        lda     z:entPtr+1
        adc     #0
        sta     z:entPtr+1
        clc                     ; say that the buffer's good
        rts

ReadNext:
        JUMP_TABLE_MLI_CALL READ, ReadParms ; get the next block
        bcs     DirDone

        inc     ThisBlock

        copy16  #(block_buffer+4),z:entPtr ; set entry pointer to beginning
                                   ; of first entry in block

        copy8   entPerBlk, ThisBEntry ; re-init 'entries in this block'
        dec     ThisBEntry
        clc                     ; return 'No error'
        rts

DirDone:
        sec                     ; return 'an error occurred' (error in A)
        rts
.endproc ; GetNext


.endproc ; ReadDir

;;;
;;;******************************************************
;;;
;;; Some global variables
;;;
Depth:          .res    1       ; amount of recursion
ThisBEntry:     .res    1       ; entry in this block
ThisBlock:      .res    1       ; block with dir
entryLen:       .res    1       ; length of each directory entry
entPerBlk:      .res    1       ; entries per block

.endscope ; RecursiveCatalog

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer

on_line_buffer:
        .res    16, 0

devidx: .byte   0

;;; Call before calling `NextVolume` to begin enumeration.
.proc InitVolumes
        copy8   DEVCNT, devidx
        rts
.endproc ; InitVolumes

;;; Appends next volume name to `searchPath`. Call `InitVolumes` first.
;;; Output: C=0 on success, C=1 on failure
.proc NextVolume
repeat: ldx     devidx
        bmi     fail
        dec     devidx

        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        JUMP_TABLE_MLI_CALL ON_LINE, on_line_params
        bcs     repeat
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        beq     repeat          ; error - try next one

        CALL    JUMP_TABLE_ADJUST_ONLINEENTRY, AX=#on_line_buffer

        ldx     #0
    DO
        copy8   on_line_buffer+1,x, searchPath+2,x
        inx
    WHILE X <> on_line_buffer

        copy8   #'/', searchPath+2,x ; add trailing '/'
        inx
        inx
        stx     searchPath

        ;; Success!
        RETURN  C=0

fail:
        RETURN  C=1
.endproc ; NextVolume

;;; ============================================================

;;; Inputs: Y = entry point, A = char to output (for `SSC::PWrite`)
.proc GoCard
        ;; Normal banking
        sta     ALTZPOFF
        bit     ROMIN2

        ldx     SLOT1,Y
        stx     vector+1
        ldx     #>SLOT1                  ; X = $Cn
        ldy     #((>SLOT1)<<4)&%11110000 ; Y = $n0
        ;; A2MISC TechNote #3 SSC C800 space
        stx     MSLOT
        stx     $CFFF
vector: jsr     SLOT1                    ; self-modified

        ;; Back to what DeskTop expects
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts
.endproc ; GoCard

.proc CROut
        copy8   #0, ch

        CALL    COut, A=#CHAR_RETURN
        lda     #CHAR_DOWN
        FALL_THROUGH_TO COut
.endproc ; CROut

.proc COut
        inc     ch

        sta     asave
        stx     xsave
        sty     ysave

        CALL    GoCard, Y=#SSC::PWrite

        lda     asave
        ldx     xsave
        ldy     ysave

        rts

asave:  .byte   0
xsave:  .byte   0
ysave:  .byte   0
.endproc ; COut

;;; ============================================================

ReadSetting = JUMP_TABLE_READ_SETTING

str_from_int:   PASCAL_STRING "000,000"    ; Filled in by IntToString

str_date:       PASCAL_STRING "DD-MMM-YY"

month_names_table:
        .byte   .sprintf("%3s", res_string_month_abbrev_1)
        .byte   .sprintf("%3s", res_string_month_abbrev_2)
        .byte   .sprintf("%3s", res_string_month_abbrev_3)
        .byte   .sprintf("%3s", res_string_month_abbrev_4)
        .byte   .sprintf("%3s", res_string_month_abbrev_5)
        .byte   .sprintf("%3s", res_string_month_abbrev_6)
        .byte   .sprintf("%3s", res_string_month_abbrev_7)
        .byte   .sprintf("%3s", res_string_month_abbrev_8)
        .byte   .sprintf("%3s", res_string_month_abbrev_9)
        .byte   .sprintf("%3s", res_string_month_abbrev_10)
        .byte   .sprintf("%3s", res_string_month_abbrev_11)
        .byte   .sprintf("%3s", res_string_month_abbrev_12)
        ASSERT_RECORD_TABLE_SIZE month_names_table, 12, 3

        .include "../lib/filetypestring.s"
        .include "../lib/inttostring.s"
        .include "../lib/save_textpage.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
