;;; ============================================================
;;; PRINT.CATALOG - Desk Accessory
;;;
;;; Prints a recursive catalog for the current window (or all
;;; volumes) to a printer in Slot 1.
;;; ============================================================

        ;; TODO: Print modification date

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
        param_call CheckSlot1Signature, sigtable_printer
        beq     :+
        param_call CheckSlot1Signature, sigtable_ssc
        beq     :+
        param_call CheckSlot1Signature, sigtable_parallel
        beq     :+

        lda     #ERR_DEVICE_NOT_CONNECTED
        jmp     JUMP_TABLE_SHOW_ALERT
:
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
:       lda     (ptr),y
        sta     searchPath,y
        dey
        bpl     :-

        ;; Append '/' needed by algorithm
        ldy     searchPath
        iny
        lda     #'/'
        sta     searchPath,y
        sty     searchPath

        clc
        ror     vol_flag

        jmp     continue

        ;; --------------------------------------------------
        ;; Search all volumes

no_windows:
        ;; Signal this mode with a path of just "/"
        copy    #1, searchPath
        copy    #'/', searchPath+1

        sec
        ror     vol_flag

        ;; --------------------------------------------------

continue:
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        ;; SSC operations trash the text page (if 80 col firmware active?)
        jsr     SaveTextPage

        ldy     #SSC::PInit
        jsr     GoCard

        ;; Init IW2 settings
        ldx     #0
:       lda     iw2_init,x
        jsr     COut
        inx
        cpx     #kLenIW2Init
        bne     :-

        ;; Recurse and print
        jsr     PrintCatalog

        jsr     RestoreTextPage
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts

PrintCatalog:
        ;; Header
        ldx     #0
:       lda     str_header+1,x
        jsr     COut
        inx
        cpx     str_header
        bne     :-
        jsr     CROut

        ;; If we're doing multiple volumes, get started
        bit     vol_flag
    IF_NS
        jsr     InitVolumes
        jsr     NextVolume
        bcs     finish
    END_IF

        ;; Show the current path
next:
        ldx     #0
:       lda     searchPath+1,x
        jsr     COut
        inx
        cpx     searchPath
        bcc     :-
        jsr     CROut
        copy    #1, indent

        ;; And invoke it!
        jsr     RecursiveCatalog__Start

        ;; If we're doing multiple volumes, do the next one
        bit     vol_flag
    IF_NS
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
        PASCAL_STRING .sprintf("%29s%6s%6s", res_string_col_name, res_string_col_type, res_string_col_blocks)
        kColType   = 30         ; Left aligned
        kTypeWidth = 3
        kColBlocks = 41         ; Right aligned

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
        lda     (ptr),y         ; first byte in table is number of tuples
        sta     count

:       iny
        lda     (ptr),y
        tax
        lda     SLOT1,x
        iny
        and     (ptr),y
        iny
        cmp     (ptr),y
        bne     ret

        dec     count
        bne     :-

ret:    rts

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
        DEFINE_READ_PARAMS ReadParms, block_buffer, 512
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
:       copy    searchPath,y, nameBuffer,y
        dey
        bpl     :-

        lda     #0              ; reset recursion/results state
        sta     Depth

        jsr     Relay           ; for stack restore

        rts

.proc Relay
        tsx
        stx     saved_stack

        ldax    #nameBuffer
        jmp     ReadDir
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
        ldax    entPtr
        jsr     JUMP_TABLE_ADJUST_FILEENTRY

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
        bpl     :+
        sta     KBDSTRB
        cmp     #$80|CHAR_ESCAPE
        beq     Terminate
:

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

        copy    block_buffer+SubdirectoryHeader::entry_length, entryLen ; init 'entryLen'

        copy16  #(block_buffer+4), entPtr ; init ptr to first entry

        lda     block_buffer+SubdirectoryHeader::entries_per_block ; init these values based on
        sta     ThisBEntry      ; values in the dir header
        sta     entPerBlk

        copy    #0, ThisBlock   ; init block offset into dir.

        clc                     ; say that open was OK

OpenDone:
        rts
.endproc ; OpenDir

;;;
;;;******************************************************
;;;
.proc VisitFile
        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        and     #DeskTopSettings::kOptionsShowInvisible
    IF_ZERO
        ;; Is the file visible?
        ldy     #FileEntry::access
        lda     (entPtr),y
        and     #ACCESS_I
        RTS_IF_NOT_ZERO
    END_IF

        jsr     PrintName

        ldx     #kColType
        lda     #' '
:       jsr     COut
        cpx     ch
        bcs     :-

        jsr     PrintType
        jsr     PrintSize

        jmp     CROut
.endproc ; VisitFile

;;; --------------------------------------------------

.proc PrintName
        ;; Print indentation
        ldx     indent
    IF_NOT_ZERO
        lda     #' '
:       jsr     COut
        jsr     COut
        dex
        bne     :-
    END_IF

        ;; Print name
        ldy     #FileEntry::storage_type_name_length
        lda     (entPtr),y
        and     #NAME_LENGTH_MASK
        tax
        ldy     #1
:       lda     (entPtr),y
        jsr     COut
        iny
        dex
        bne     :-

        rts
.endproc ; PrintName

;;; --------------------------------------------------

.proc PrintType
        ldy     #FileEntry::file_type
        lda     (entPtr),y

        jsr     ComposeFileTypeString
        ldx     #0
:       lda     str_file_type+1,x
        jsr     COut
        inx
        cpx     str_file_type
        bne     :-

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
:       jsr     COut
        dex
        cpx     str_from_int
        bne     :-

        ;; Print it
        ldx     #0
:       lda     str_from_int+1,x
        jsr     COut
        inx
        cpx     str_from_int
        bne     :-

        rts
.endproc ; PrintSize

;;;
;;;******************************************************
;;;
.proc VisitDir

        jsr     PrintName
        lda     #'/'
        jsr     COut
        jsr     CROut

        ;; 6 bytes + 3 return addresses = 12 bytes are pushed to stack on
        ;; in RecursDir; 12 * 16 = 192 bytes, which leaves enough room
        ;; on the stack above and below for safety.
        kMaxRecursionDepth = 16

        lda     Depth
        cmp     #kMaxRecursionDepth
        bcs     :+

        jmp     RecursDir       ; enumerate all entries in sub-dir.

:       rts
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
        lda     entPtr+1
        pha
        lda     entPtr
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
        sta     entPtr
        pla
        sta     entPtr+1

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
        lda     entPtr
        adc     entryLen
        sta     entPtr
        lda     entPtr+1
        adc     #0
        sta     entPtr+1
        clc                     ; say that the buffer's good
        rts

ReadNext:
        JUMP_TABLE_MLI_CALL READ, ReadParms ; get the next block
        bcs     DirDone

        inc     ThisBlock

        copy16  #(block_buffer+4),entPtr ; set entry pointer to beginning
                                   ; of first entry in block

        copy    entPerBlk, ThisBEntry ; re-init 'entries in this block'
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
        RecursiveCatalog__Start := RecursiveCatalog::Start

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer

on_line_buffer:
        .res    16, 0

devidx: .byte   0

;;; Call before calling `NextVolume` to begin enumeration.
.proc InitVolumes
        copy    DEVCNT, devidx
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

        param_call JUMP_TABLE_ADJUST_ONLINEENTRY, on_line_buffer

        ldx     #0
:       copy    on_line_buffer+1,x, searchPath+2,x
        inx
        cpx     on_line_buffer
        bne     :-
        copy    #'/', searchPath+2,x ; add trailing '/'
        inx
        inx
        stx     searchPath

        ;; Success!
        clc
        rts

fail:
        sec
        rts
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
        lda     #0
        sta     ch

        lda     #CHAR_RETURN
        jsr     COut
        lda     #CHAR_DOWN
        FALL_THROUGH_TO COut
.endproc ; CROut

.proc COut
        inc     ch

        sta     asave
        stx     xsave
        sty     ysave

        ldy     #SSC::PWrite
        jsr     GoCard

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

hex_digits:     .byte   "0123456789ABCDEF" ; Needed by ComposeFileTypeString
str_from_int:   PASCAL_STRING "000,000"    ; Filled in by IntToString

        .include "../lib/filetypestring.s"
        .include "../lib/inttostring.s"
        .include "../lib/save_textpage.s"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
