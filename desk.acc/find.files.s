;;; ============================================================
;;; FIND.FILES - Desk Accessory
;;;
;;; Presents a dialog with a text field to enter a search
;;; string, then searches for files (in the current directory
;;; and child directories) for matching filenames. Wildcards
;;; are ? and *.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "find.files.res"

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
;;;          | IO Buffer   | |Win Tables   |
;;;  $1C00   +-------------+ |             |
;;;  $1B00   | Dir Block   | +-------------+
;;;  $1A00   +-------------+ |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | File Names  | |             |
;;;          + - - - - - - + |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | DA          | | DA (copy)   |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;

;;; ============================================================

        .org $800

        block_buffer := $1A00


entry:

;;; Copy the DA to AUX for easy bank switching
.scope
        lda     ROMIN2
        copy16  #entry, STARTLO
        copy16  #da_end, ENDLO
        copy16  #entry, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
        lda     LCBANK1
        lda     LCBANK1
.endscope

.scope
        ptr := $06

        ;; Get top DeskTop window (if any) and find its path
        param_call JUMP_TABLE_MGTK_RELAY, MGTK::FrontWindow, ptr
        lda     ptr             ; any window open?
        beq     exit
        cmp     #kMaxDeskTopWindows+1
        bcs     exit
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

        ;; Run the DA
        sta     RAMRDON
        sta     RAMWRTON

        jsr     init

        ;; Back to main for exit
        sta     RAMRDOFF
        sta     RAMWRTOFF
exit:   rts
.endscope

;;; ============================================================

.proc get_entry_addr
        sta     num
        sta     offset
        lda     #0
        sta     offset+1

        ;; Compute num * 65
        ldx     #6              ; offset = num * 64
:       asl16   offset
        dex
        bne     :-
        add16_8 offset, num, offset ; offset += num, so * 65
        add16   offset, #entries_buffer, offset

        ldax    offset
        rts

num:    .byte   0
offset: .addr   0
.endproc

;;; ============================================================
;;; Make call into Main from Aux (for JUMP_TABLE calls)
;;; Inputs: A,X = address

.proc jt_relay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        stax    @addr
        @addr := *+1
        jsr     SELF_MODIFIED
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================

;;; Make a path character uppercase; assumes no char >'z' is
;;; a valid path character.

.proc upcase_path_char
        cmp     #'a'
        bcc     :+
        and     #CASE_MASK
:       rts
.endproc

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
;;; From http://www.1000bit.it/support/manuali/apple/technotes/pdos/tn.pdos.17.html
;;;
;;; * Converted to ca65 syntax
;;; * Using A2D headers/macros
;;; * Use procs
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
;;; Call with A,X pointing at dir name
saved_stack:
        .byte   0

.proc Start
        ;; Copy pattern in Aux > Main (source is length-prefixed, dest is null terminated)
        sta     RAMWRTOFF       ; read aux, write main

        ldy     buf_search
        copy    #0, pattern,y   ; null-terminate
        cpy     #0
        beq     endloop
loop:   lda     buf_search,y    ; copy characters
        jsr     upcase_path_char
        sta     pattern-1,y
        dey
        bne     loop
endloop:

        ;; Run from Main, with normal ZP and ROM
        sta     RAMRDOFF
        sta     RAMWRTOFF
        sta     ALTZPOFF
        lda     ROMIN2

        bit     KBDSTRB         ; clear strobe

        ldy     searchPath      ; prime the search path
:       copy    searchPath,y, nameBuffer,y
        dey
        bpl     :-

        lda     #0              ; reset recursion/results state
        sta     Depth
        sta     num_entries

        jsr     relay           ; for stack restore
        ldy     num_entries

        ;; DA runs out of Aux with aux ZP and LC
        sta     RAMRDON
        sta     RAMWRTON
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        sty     num_entries

        rts

.proc relay
        tsx
        stx     saved_stack

        ldax    #nameBuffer
        jmp     ReadDir
.endproc
.endproc

.proc terminate
        MLI_CALL CLOSE, CloseParms ; close the directory

        ldx     saved_stack
        txs

        rts
.endproc

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
        beq     terminate
:

        jsr     GetNext         ; get pointer to next entry
        bcc     loop            ; Carry set means we're done
done:                           ; moved before PHA (11/89 DAL)
        pha                     ; save error code

        MLI_CALL CLOSE, CloseParms ; close the directory

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
        MLI_CALL OPEN, OpenParms ; open dir as a file
        bcs     OpenDone

        lda     OpenParms::ref_num  ; copy the refnum return-
        sta     ReadParms::ref_num  ; ed by Open into the
        sta     CloseParms::ref_num ; other param blocks.
        sta     SetMParms::ref_num

        MLI_CALL READ, ReadParms ; read the first block
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
.endproc

;;;
;;;******************************************************
;;;
.proc VisitFile

        ;; Does the file match the search pattern?
        lda     pattern         ; Skip if pattern is empty
        beq     :+
        jsr     is_match
        bcc     exit            ; No match
:

        ptr := $0A
        lda     num_entries
        jsr     get_entry_addr
        stax    ptr

        ;; Copy name to buffer

        jsr     ExtendName      ; Appends entry name to dirName plus '/'

        ldy     #0
        lda     (dirName),y
        tay
:       lda     (dirName),y
        sta     (ptr),y
        dey
        bne     :-
        lda     (dirName),y     ; Y is 0...
        tax
        dex                     ; Chop off the trailing '/'
        txa
        sta     (ptr),y

        jsr     ChopName        ; Restores the name
        inc     num_entries

        ;; If we've hit max number of entries, terminate operation.
        lda     num_entries
        cmp     #kMaxFilePaths
        jeq     terminate

exit:   rts
.endproc

;;;
;;;******************************************************
;;;
.proc VisitDir

        ;; Treat directories like files
        jsr     VisitFile

        jsr     RecursDir       ; enumerate all entries in sub-dir.

        rts
.endproc
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
        MLI_CALL CLOSE, CloseParms

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

        jmp     terminate

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

        MLI_CALL SET_MARK, SetMParms ; reset the file marker

        MLI_CALL READ, ReadParms ; now read in the block we were on last.

        dec     Depth
        rts
.endproc

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
.endproc

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
.endproc

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
        MLI_CALL READ, ReadParms ; get the next block
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
.endproc


.endproc

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

;;; ============================================================

pattern:        .res    16      ; 15 + null terminator
string:         .res    16      ; 15 + null terminator

.proc is_match

.scope
        ;; Copy filename to null terminated string buffer
        .assert FileEntry::storage_type_name_length = 0, error, "Can't treat as Pascal string"
        .assert FileEntry::file_name = 1, error, "Can't treat as Pascal string"
        ldy     #FileEntry::storage_type_name_length
        lda     (entPtr),y
        and     #NAME_LENGTH_MASK
        tay
        copy    #0, string,y    ; null-terminate
        cpy     #0
        beq     endloop
loop:   lda     (entPtr),y      ; copy characters
        jsr     upcase_path_char

        sta     string-1,y
        dey
        bne     loop
endloop:
.endscope

        str := $0A
        ldax    #string
        stax    str

;;; Based on Pattern Matcher
;;; String pattern matcher in 6502 assembly.
;;; By Paul Guertin (pg@sff.net), 30 August 2000
;;; http://6502.org/source/strings/patmatch.htm

;;; Input:  A NUL-terminated, <255-length pattern at address `pattern`.
;;;         A NUL-terminated, <255-length string pointed to by `str`.
;;;
;;; Output: Carry bit = 1 if the string matches the pattern, = 0 if not.
;;;
;;; Notes:  Clobbers A, X, Y. Each * in the pattern uses 4 bytes of stack.
;;;

        ldx #$00                ; X is an index in the pattern
        ldy #$FF                ; Y is an index in the string
next:   lda pattern,X           ; Look at next pattern character
        cmp #'*'                ; Is it a star?
        beq star                ; Yes, do the complicated stuff
        iny                     ; No, let's look at the string
        cmp #'?'                ; Is the pattern caracter a ques?
        bne reg                 ; No, it's a regular character
        lda (str),Y             ; Yes, so it will match anything
        beq fail                ; except the end of string
reg:    cmp (str),Y             ; Are both characters the same?
        bne fail                ; No, so no match
        inx                     ; Yes, keep checking
        cmp #0                  ; Are we at end of string?
        bne next                ; Not yet, loop
found:  rts                     ; Success, return with C=1

star:   inx                     ; Skip star in pattern
        cmp pattern,X           ; String of stars equals one star
        beq star                ; so skip them also
stloop: txa                     ; We first try to match with * = ""
        pha                     ; and grow it by 1 character every
        tya                     ; time we loop
        pha                     ; Save X and Y on stack
        jsr next                ; Recursive call
        pla                     ; Restore X and Y
        tay
        pla
        tax
        bcs found               ; We found a match, return with C=1
        iny                     ; No match yet, try to grow * string
        lda (str),Y             ; Are we at the end of string?
        bne stloop              ; Not yet, add a character

fail:   clc                     ; Yes, no match found, return with C=0
        rts
.endproc

.endscope


;;; ============================================================



;;; ============================================================
;;; Used in both Main and Aux

kMaxFilePaths       = (block_buffer - entries_buffer) / kPathBufferSize

entry_buf:
        .res    kPathBufferSize

num_entries:
        .byte   0

entries_buffer := *


        .assert * < $1000, error, "Try to keep Main code size down"

;;; ============================================================

;;; From this point on gets overwritten in main

;;; ============================================================


kDAWindowID     = 63
kDAWidth        = 465
kDAHeight       = 151
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

kResultsWindowID        = kDAWindowID+1
kResultsWidth           = kDAWidth - 60
kResultsWidthSB         = kResultsWidth + 20
kResultsHeight          = kDAHeight - 40
kResultsLeft            = kDALeft + (kDAWidth - kResultsWidthSB) / 2
kResultsTop             = kDATop + 30

kResultsRows    = 11                ; line height is 10

.params winfo
window_id:      .byte   kDAWindowID
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontlength:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

.params winfo_results
window_id:      .byte   kResultsWindowID
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_present | MGTK::Scroll::option_thumb
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   kMaxFilePaths - kResultsRows
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kResultsWidth
mincontlength:  .word   kResultsHeight
maxcontwidth:   .word   kResultsWidth
maxcontlength:  .word   kResultsHeight
port:
        DEFINE_POINT viewloc, kResultsLeft, kResultsTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
        DEFINE_RECT maprect, 0, 0, kResultsWidth, kResultsHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams


;;; ============================================================

.params event_params
kind:  .byte   0
;;; EventKind::key_down
key             := *
modifiers       := * + 1
;;; EventKind::update
window_id       := *
;;; otherwise
xcoord          := *
ycoord          := * + 2
        .res    4
.endparams

.params findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

.params findcontrol_params
mousex:         .word   0
mousey:         .word   0
which_ctl:      .byte   0
which_part:     .byte   0
.endparams

.params trackthumb_params
which_ctl:      .byte   MGTK::Ctl::vertical_scroll_bar
mousex:         .word   0
mousey:         .word   0
thumbpos:       .byte   0
thumbmoved:     .byte   0
.endparams

.params updatethumb_params
which_ctl:      .byte   MGTK::Ctl::vertical_scroll_bar
thumbpos:       .byte   0
.endparams

.params winport_params
window_id:      .byte   0
port:           .addr   grafport
.endparams

.params screentowindow_params
window_id:      .byte   kDAWindowID
        DEFINE_POINT screen, 0, 0
        DEFINE_POINT window, 0, 0
.endparams
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

.params grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .word   0
mapwidth:       .word   0
        DEFINE_RECT maprect, 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endparams

.params activatectl_params
which_ctl:      .byte   MGTK::Ctl::vertical_scroll_bar
activate:       .byte   0
.endparams

.params setctlmax_params
which_ctl:      .byte   MGTK::Ctl::vertical_scroll_bar
ctlmax:         .byte   0
.endparams

;;; ============================================================

        DEFINE_RECT_INSET frame_rect1, 4, 2, kDAWidth, kDAHeight
        DEFINE_RECT_INSET frame_rect2, 5, 3, kDAWidth, kDAHeight

        DEFINE_LABEL find, res_string_label_find, 20, 20

        DEFINE_RECT input_rect, 90, 10, kDAWidth-250, 21
        DEFINE_POINT input_textpos, 95, 20

        ;; figure out coords here
.params input_mapinfo
        DEFINE_POINT viewloc, 75, 35
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   0
        DEFINE_RECT maprect, 0, 0, 358, 100
.endparams

        DEFINE_BUTTON search, res_string_button_search, kDAWidth-235, 10
        DEFINE_BUTTON cancel, res_string_button_cancel,   kDAWidth-120, 10

penxor: .byte   MGTK::penXOR

cursor_ip_flag: .byte   0

kBufSize = 18                   ; max length = 15, plus IP + length + extra
buf_left:       .res    kBufSize, 0 ; input text before IP
buf_right:      .res    kBufSize, 0 ; input text at/after IP
buf_search:     .res    kBufSize, 0 ; search term

suffix: PASCAL_STRING "  "      ; do not localize

ip_blink_counter:       .byte   0
ip_blink_flag:          .byte   0

top_row:        .byte   0

;;; ============================================================

.proc init
        ;; Prep input string
        copy    #0, buf_left

        copy    #1, buf_right
        copy    #kGlyphInsertionPoint, buf_right+1

        copy    #0, ip_blink_flag
        copy    #prompt_insertion_point_blink_count, ip_blink_counter

        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::OpenWindow, winfo_results
        MGTK_CALL MGTK::HideCursor
        jsr     draw_window
        jsr     draw_input_text
        jsr     draw_results
        MGTK_CALL MGTK::ShowCursor
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        jsr     blink_ip
        param_call jt_relay, JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        jeq     handle_down
        cmp     #MGTK::EventKind::key_down
        jeq     handle_key
        cmp     #MGTK::EventKind::no_event
        jeq     handle_no_event
        jmp     input_loop
.endproc

.proc exit
        param_call jt_relay, JUMP_TABLE_CUR_POINTER

        MGTK_CALL MGTK::CloseWindow, winfo_results
        MGTK_CALL MGTK::CloseWindow, winfo
        rts
.endproc

;;; ============================================================

        prompt_insertion_point_blink_count = $14

.proc blink_ip
        dec     ip_blink_counter
        bne     done
        copy    #prompt_insertion_point_blink_count, ip_blink_counter

        bit     ip_blink_flag
        bmi     clear

set:    copy    #$80, ip_blink_flag
        copy    #kGlyphSpacer, buf_right+1
        jsr     draw_input_text
        rts


clear:  copy    #0, ip_blink_flag
        copy    #kGlyphInsertionPoint, buf_right+1
        jsr     draw_input_text

done:   rts
.endproc

;;; ============================================================

.proc handle_key
        lda     event_params::modifiers
        beq     not_meta

        ;; Button down
        lda     event_params::key
        cmp     #CHAR_LEFT
        jeq     do_meta_left
        cmp     #CHAR_RIGHT
        jeq     do_meta_right
        cmp     #CHAR_UP
    IF_EQ
        copy    #MGTK::Part::page_up, findcontrol_params::which_part
        jmp     handle_scroll
    END_IF
        cmp     #CHAR_DOWN
    IF_EQ
        copy    #MGTK::Part::page_down, findcontrol_params::which_part
        jmp     handle_scroll
    END_IF
        jmp     ignore_char

not_meta:
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        bne     :+
        param_call flash_button, cancel_button_rect
        jmp     exit

:       cmp     #CHAR_RETURN
        bne     :+
        param_call flash_button, search_button_rect
        jmp     do_search

:       cmp     #CHAR_LEFT
        jeq     do_left

        cmp     #CHAR_RIGHT
        jeq     do_right

        cmp     #CHAR_DELETE
        jeq     do_delete

        cmp     #CHAR_UP
    IF_EQ
        copy    #MGTK::Part::up_arrow, findcontrol_params::which_part
        jmp     handle_scroll
    END_IF
        cmp     #CHAR_DOWN
    IF_EQ
        copy    #MGTK::Part::down_arrow, findcontrol_params::which_part
        jmp     handle_scroll
    END_IF

        ;; Valid characters are . 0-9 A-Z a-z ? *
        cmp     #'*'            ; Wildcard
        beq     do_char
        cmp     #'?'            ; Wildcard
        beq     do_char
        cmp     #'.'            ; Filename char (here and below)
        beq     do_char
        cmp     #'0'
        bcc     ignore_char
        cmp     #'9'+1
        bcc     do_char
        cmp     #'A'
        bcc     ignore_char
        cmp     #'Z'+1
        bcc     do_char
        cmp     #'a'
        bcc     ignore_char
        cmp     #'z'+1
        bcc     do_char
        ;; fall through
.endproc

ignore_char:
        jmp     input_loop

;;; ------------------------------------------------------------

.proc do_char
        ;; check length
        tax
        clc
        lda     buf_left
        adc     buf_right
        cmp     #16             ; max length is 15, plus ip
        bcs     ignore_char

        ;; append char
        txa
        ldx     buf_left
        inx
        sta     buf_left,x
        stx     buf_left
        jsr     draw_input_text
        jmp     input_loop
.endproc

;;; ------------------------------------------------------------

.proc do_meta_left
        jsr     move_ip_to_end
        jmp     input_loop
.endproc

.proc move_ip_to_start
        lda     buf_left            ; length of string to left of IP
        beq     done

        ;; shift right string up N (apart from IP)
        clc
        adc     buf_right
        tay
        ldx     buf_right
:       cpx     #1
        beq     move
        copy    buf_right,x, buf_right,y
        dex
        dey
        bne     :-              ; always

        ;; move chars from left string to just after IP in right string
move:   ldx     buf_left
:       copy    buf_left,x, buf_right+1,x
        dex
        bne     :-

        ;; adjust lengths
        lda     buf_left
        clc
        adc     buf_right
        sta     buf_right

        copy    #0, buf_left

        jsr     draw_input_text

done:   rts
.endproc

;;; ------------------------------------------------------------

.proc do_left
        lda     buf_left            ; length of string to left of IP
        beq     done

        ;; shift right string up one (apart from IP)
        ldx     buf_right
        ldy     buf_right
        iny
:       cpx     #1
        beq     :+
        copy    buf_right,x, buf_right,y
        dex
        dey
        bne     :-              ; always

        ;; move char from end of left string to just after IP in right string
:       ldx     buf_left
        copy    buf_left,x, buf_right+2

        ;; adjust lengths
        dec     buf_left
        inc     buf_right

        jsr     draw_input_text

done:   jmp     input_loop
.endproc

;;; ------------------------------------------------------------

.proc do_meta_right
        jsr     move_ip_to_end
        jmp     input_loop
.endproc

.proc move_ip_to_end
        lda     buf_right       ; length of string from IP rightwards
        cmp     #2              ; must be at least one char (plus IP)
        bcc     done

        ;; append right string to left
        ldx     #2
        ldy     buf_left
        iny
:       copy    buf_right,x, buf_left,y
        cpx     buf_right
        beq     :+
        inx
        iny
        bne     :-              ; always

        ;; adjust lengths
:       lda     buf_left
        clc
        adc     buf_right
        sec
        sbc     #1
        sta     buf_left

        copy    #1, buf_right

        jsr     draw_input_text

done:   rts
.endproc

;;; ------------------------------------------------------------

.proc do_right
        lda     buf_right       ; length of string from IP rightwards
        cmp     #2              ; must be at least one char (plus IP)
        bcc     done

        ;; copy char from start of right to end of left
        lda     buf_right+2
        ldx     buf_left
        inx
        sta     buf_left,x

        ;; shift right string down one (apart from IP)
        ldx     #3
        ldy     #2
:       copy    buf_right,x, buf_right,y
        inx
        iny
        cpy     buf_right
        bcc     :-

        ;; adjust lengths
        inc     buf_left
        dec     buf_right

        jsr     draw_input_text

done:   jmp     input_loop
.endproc

;;; ------------------------------------------------------------

.proc do_delete
        lda     buf_left            ; length of string to left of IP
        beq     done

        dec     buf_left
        jsr     draw_input_text

done:   jmp     input_loop
.endproc

;;; ============================================================

.proc do_search
        ;; Concatenate left/right strings
        ldx     buf_left
        beq     right

        ;; Copy left
:       copy    buf_left,x, buf_search,x
        dex
        bpl     :-
        ldx     buf_left

        ;; Append right
right:
        ldy     #1
:       cpy     buf_right
        beq     done_concat
        iny
        inx
        copy    buf_right,y, buf_search,x
        bne     :-              ; always

done_concat:
        stx     buf_search

        param_call jt_relay, JUMP_TABLE_CUR_WATCH

        ;; Do the search
        jsr     RecursiveCatalog::Start

        ;; Update the scrollbar
        lda     num_entries
        cmp     #kResultsRows+1
    IF_LT
        copy    #MGTK::activatectl_deactivate, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
    ELSE
        copy    #0, updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        lda     num_entries
        clc
        sbc     #kResultsRows
        sta     setctlmax_params::ctlmax
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params
        copy    #MGTK::activatectl_activate, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
    END_IF

        ;; Update the results display
        copy    #0, top_row
        jsr     update_viewport
        jsr     draw_results

        bit     cursor_ip_flag
    IF_PLUS
        param_call jt_relay, JUMP_TABLE_CUR_POINTER
    ELSE
        param_call jt_relay, JUMP_TABLE_CUR_IBEAM
    END_IF

finish: jmp     input_loop
.endproc


;;; ============================================================

.proc handle_down
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bne     done
        lda     findwindow_params::window_id
        cmp     #kResultsWindowID
        beq     results
        cmp     #kDAWindowID
        bne     done

        ;; Click in DA content area
        param_call button_press, search_button_rect
        beq     :+
        bmi     done
        jmp     do_search

:       param_call button_press, cancel_button_rect
        beq     :+
        bmi     done
        jmp     exit

:       jsr     handle_click_in_textbox

done:   jmp     input_loop

        ;; Click in Results content area
results:
        copy16  event_params::xcoord, findcontrol_params::mousex
        copy16  event_params::ycoord, findcontrol_params::mousey
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     done

        jmp     handle_scroll
.endproc


;;; ============================================================
;;; Handle scroll bar


.proc handle_scroll
        lda     num_entries
        sec
        sbc     #kResultsRows
        sta     max_top

        lda     findcontrol_params::which_part

        ;; scroll up by one line
        cmp     #MGTK::Part::up_arrow
        bne     try_down
        lda     top_row
        cmp     #0
        jeq     done

        dec     top_row
        bpl     update

        ;; scroll down by one line
try_down:
        cmp     #MGTK::Part::down_arrow
        bne     try_pgup
        lda     top_row
        cmp     max_top
        jcs     done

        inc     top_row
        bpl     update

        ;; scroll up by one page
try_pgup:
        cmp     #MGTK::Part::page_up
        bne     try_pgdn
        lda     top_row
        cmp     #kResultsRows
        bcs     :+
        lda     #0
        beq     store
:       sec
        sbc     #kResultsRows
        jmp     store

        ;; scroll down by one page
try_pgdn:
        cmp     #MGTK::Part::page_down
        bne     try_thumb
        lda     top_row
        clc
        adc     #kResultsRows
        cmp     max_top
        bcc     store
        lda     max_top
        jmp     store

try_thumb:
        cmp     #MGTK::Part::thumb
        jne     done

        copy16  event_params::xcoord, trackthumb_params::mousex
        copy16  event_params::ycoord, trackthumb_params::mousey
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        beq     done
        lda     trackthumb_params::thumbpos

store:  sta     top_row

update: copy    top_row, updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        jsr     update_viewport
        jsr     draw_results

done:   jmp     input_loop

max_top:        .byte   0
.endproc

;;; Assumes `top_row` is set.
.proc update_viewport
        ;; Compute height of line (font height + 1)
        copy16  #1, line_height
        add16_8 line_height, DEFAULT_FONT+MGTK::Font::height, line_height

        ;; Update top of maprect: 1 + top_row * line_height
        copy16  #0, winfo_results::maprect::y1
        ldx     top_row
        beq     bottom
:       add16   line_height, winfo_results::maprect::y1, winfo_results::maprect::y1
        dex
        bne     :-

        ;; Update bottom of maprect
bottom: add16   winfo_results::maprect::y1, #kResultsHeight, winfo_results::maprect::y2

        rts

line_height:    .word   0
.endproc

;;; ============================================================
;;; Call with rect addr in A,X
;;; Returns: 0 (beq) if outside, $FF (bmi) if canceled, 1 if clicked

.proc button_press
        kOutside         = 0
        kCanceled        = $FF
        kClicked         = 1

        stax    inrect_addr
        stax    fillrect_addr
        jsr     test_rect
        beq     :+
        return  #kOutside

:       jsr     invert_rect

        copy    #0, down_flag

loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     exit

        jsr     test_rect
        beq     inside

        lda     down_flag       ; outside but was inside?
        beq     invert
        jmp     loop

inside: lda     down_flag       ; already depressed?
        bne     invert
        jmp     loop

invert: jsr     invert_rect
        lda     down_flag
        clc
        adc     #$80
        sta     down_flag
        jmp     loop

exit:   lda     down_flag       ; was depressed?
        beq     :+
        return  #kCanceled
:       jsr     invert_rect     ; invert one last time
        return  #kClicked

down_flag:
        .byte   0

test_rect:
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, 0, inrect_addr
        cmp     #MGTK::inrect_inside
        rts

invert_rect:
        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::PaintRect, 0, fillrect_addr
        rts
.endproc

;;; ============================================================
;;; Call with rect addr in A,X

.proc flash_button
        stax    fillrect_addr

        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penxor
        jsr     sub
        ;; fall through...

sub:    MGTK_CALL MGTK::PaintRect, 0, fillrect_addr
        rts
.endproc


;;; ============================================================

.proc handle_click_in_textbox

        PARAM_BLOCK tw_params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        click_coords := screentowindow_params::window::xcoord

        ;; Mouse coords to window coords; is click inside name field?
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, click_coords
        MGTK_CALL MGTK::InRect, input_rect
        cmp     #MGTK::inrect_inside
        beq     :+
        rts

        ;; Is click to left or right of insertion point?
:       jsr     calc_ip_pos

        width := $6

        stax    width
        cmp16   click_coords, width
        bcs     to_right
        jmp     to_left

;;; --------------------------------------------------

        ;; Click is to the right of IP

.proc to_right
        jsr     calc_ip_pos
        stax    ip_pos

        ldx     buf_right
        inx
        copy    #' ', buf_right,x ; append space at end
        inc     buf_right

        ;; Iterate to find the position
        copy16  #buf_right, tw_params::data
        copy    buf_right, tw_params::length
@loop:  MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, ip_pos, tw_params::width
        cmp16   tw_params::width, click_coords
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bne     @loop

        dec     buf_right
        jmp     finish

        ;; Was it to the right of the string?
:       lda     tw_params::length
        cmp     buf_right
        bcc     :+
        dec     buf_right          ; remove appended space
        jmp     move_ip_to_end     ; use this shortcut

        ;; Append from `buf_right` into `buf_left`
:       ldx     #2
        ldy     buf_left
        iny
:       lda     buf_right,x
        sta     buf_left,y
        cpx     tw_params::length
        beq     :+
        iny
        inx
        jmp     :-
:       sty     buf_left

        ;; Shift contents of `buf_right` down,
        ;; preserving IP at the start.
        ldy     #2
        ldx     tw_params::length
        inx
:       lda     buf_right,x
        sta     buf_right,y
        cpx     buf_right
        beq     :+
        iny
        inx
        jmp     :-

:       dey
        sty     buf_right
        jmp     finish
.endproc

;;; --------------------------------------------------

        ;; Click to left of IP

.proc to_left
        ;; Iterate to find the position
        copy16  #buf_left, tw_params::data
        copy    buf_left, tw_params::length
:       MGTK_CALL MGTK::TextWidth, tw_params
        add16   tw_params::width, input_textpos::xcoord, tw_params::width
        cmp16   tw_params::width, click_coords
        bcc     :+
        dec     tw_params::length
        lda     tw_params::length
        cmp     #1
        bcs     :-
        jmp     move_ip_to_start ; use this shortcut

        ;; Found position; copy everything to the right of
        ;; the new position from `buf_left` to `buf_search`
:       inc     tw_params::length
        ldy     #0
        ldx     tw_params::length
:       cpx     buf_left
        beq     :+
        inx
        iny
        lda     buf_left,x
        sta     buf_search+1,y
        jmp     :-
:       iny
        sty     buf_search

        ;; Append `buf_right` to `buf_search`
        ldx     #1
        ldy     buf_search
:       cpx     buf_right
        beq     :+
        inx
        iny
        lda     buf_right,x
        sta     buf_search,y
        jmp     :-
:       sty     buf_search

        ;; Copy IP and `buf_search` into `buf_right`
        copy    #kGlyphInsertionPoint, buf_search+1
:       lda     buf_search,y
        sta     buf_right,y
        dey
        bpl     :-

        ;; Adjust length
        lda     tw_params::length
        sta     buf_left
        ;; fall through
.endproc

finish:
        jsr     draw_input_text
        rts

ip_pos: .word   0
.endproc


;;; ============================================================

.proc calc_ip_pos
        PARAM_BLOCK params, $06
data    .addr
length  .byte
width   .word
        END_PARAM_BLOCK

        lda     #0
        sta     params::width
        sta     params::width+1
        lda     buf_left
        beq     :+
        sta     params::length
        copy16  #buf_left+1, params::data
        MGTK_CALL MGTK::TextWidth, params
:       lda     params::width
        clc
        adc     input_rect::x1
        tay
        lda     params::width+1
        adc     input_rect::x1+1
        tax
        tya
        rts
.endproc

;;; ============================================================

.proc handle_no_event
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, input_rect
        cmp     #MGTK::inrect_inside
        beq     inside

outside:
        bit     cursor_ip_flag
        bpl     done
        copy    #0, cursor_ip_flag
        param_call jt_relay, JUMP_TABLE_CUR_POINTER
        jmp     done

inside:
        bit     cursor_ip_flag
        bmi     done
        copy    #$80, cursor_ip_flag
        param_call jt_relay, JUMP_TABLE_CUR_IBEAM

done:   jmp     input_loop
.endproc

;;; ============================================================

.proc draw_window
        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        ;; No need to check results, since window is always visible.
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::FrameRect, frame_rect1
        MGTK_CALL MGTK::FrameRect, frame_rect2

        MGTK_CALL MGTK::MoveTo, find_label_pos
        param_call draw_string, find_label_str
        MGTK_CALL MGTK::FrameRect, input_rect

        MGTK_CALL MGTK::FrameRect, search_button_rect
        MGTK_CALL MGTK::MoveTo, search_button_pos
        param_call draw_string, search_button_label

        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call draw_string, cancel_button_label

        MGTK_CALL MGTK::ShowCursor
done:   rts
.endproc

;;; ============================================================

.proc draw_input_text
        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::MoveTo, input_textpos
        MGTK_CALL MGTK::HideCursor
        param_call draw_string, buf_left
        param_call draw_string, buf_right
        param_call draw_string, suffix
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

.proc draw_results
        copy    DEFAULT_FONT+MGTK::Font::height, line_height
        inc     line_height

        copy    #kResultsWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        ;; No need to check results, since window is always visible.
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; TODO: Optimize erasing
        MGTK_CALL MGTK::PaintRect, winfo_results::maprect

        lda     num_entries
        beq     done

        copy    #0, line
        copy16  #0, pos_ycoord
loop:   add16_8   pos_ycoord, line_height, pos_ycoord
        MGTK_CALL MGTK::MoveTo, pos

        lda     line
        jsr     get_entry

        param_call draw_string, entry_buf
        inc     line
        lda     line
        cmp     num_entries
        bcc     loop

done:   MGTK_CALL MGTK::ShowCursor
        rts

line_height:
        .byte   0

line:   .byte   0
        DEFINE_POINT pos, 5, 0
        pos_ycoord := pos::ycoord

.endproc


;;; ============================================================
;;; Helper to draw a PASCAL_STRING; call with addr in A,X

.proc draw_string
        PARAM_BLOCK params, $06
addr    .addr
length  .byte
        END_PARAM_BLOCK

        stax    params::addr
        ldy     #0
        lda     (params::addr),y
        beq     done
        sta     params::length
        inc16   params::addr
        MGTK_CALL MGTK::DrawText, params
done:   rts
.endproc

;;; ============================================================
;;; Populate entry_buf with entry in A

.proc get_entry
        jsr     get_entry_addr
        stax    STARTLO

        add16   STARTLO, #64, ENDLO
        copy16  #entry_buf, DESTINATIONLO

        sec                     ; main>aux
        jsr     AUXMOVE

        rts
.endproc

;;; ============================================================

;;; ============================================================

da_end  := *

.assert * < WINDOW_ICON_TABLES, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00
