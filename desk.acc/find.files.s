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

        MGTKEntry := MGTKAuxEntry

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

        .org DA_LOAD_ADDRESS

        MLIEntry := MLI

        block_buffer := $1A00


entry:

;;; Copy the DA to AUX for easy bank switching
.scope
        bit     ROMIN2
        copy16  #entry, STARTLO
        copy16  #da_end, ENDLO
        copy16  #entry, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
        bit     LCBANK1
        bit     LCBANK1
.endscope

.scope
        ptr := $06

        ;; Get top DeskTop window (if any) and find its path
        JUMP_TABLE_MGTK_CALL MGTK::FrontWindow, ptr
        lda     ptr             ; any window open?
        beq     no_windows
        cmp     #kMaxDeskTopWindows+1
        bcs     no_windows
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

        jsr     Init

        ;; Back to main for exit
        sta     RAMRDOFF
        sta     RAMWRTOFF
exit:   rts

no_windows:
        lda     #kErrNoWindowsOpen
        jmp     JUMP_TABLE_SHOW_ALERT ; NOTE: Trashes AUX $800-$1AFF
.endscope

;;; ============================================================

.proc GetEntryAddr
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

.proc JTRelay
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

.proc UpcasePathChar
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
        jsr     UpcasePathChar
        sta     pattern-1,y
        dey
        bne     loop
endloop:

        ;; Run from Main, with normal ZP and ROM
        sta     RAMRDOFF
        sta     RAMWRTOFF
        sta     ALTZPOFF
        bit     ROMIN2

        bit     KBDSTRB         ; clear strobe

        ldy     searchPath      ; prime the search path
:       copy    searchPath,y, nameBuffer,y
        dey
        bpl     :-

        lda     #0              ; reset recursion/results state
        sta     Depth
        sta     num_entries

        jsr     Relay           ; for stack restore
        ldy     num_entries

        ;; DA runs out of Aux with aux ZP and LC
        sta     RAMRDON
        sta     RAMWRTON
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        sty     num_entries

        rts

.proc Relay
        tsx
        stx     saved_stack

        ldax    #nameBuffer
        jmp     ReadDir
.endproc
.endproc

.proc Terminate
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
        beq     Terminate
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
        jsr     IsMatch
        bcc     exit            ; No match
:

        ptr := $0A
        lda     num_entries
        jsr     GetEntryAddr
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
        jeq     Terminate

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

.proc IsMatch

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
        jsr     UpcasePathChar

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
penmode:        .byte   MGTK::pencopy
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
penmode:        .byte   MGTK::pencopy
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
penmode:        .byte   MGTK::pencopy
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

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

        kControlsTop = 10
        kFindLeft = 20
        DEFINE_LABEL find, res_string_label_find, kFindLeft, 20

        ;; Left edges are adjusted dynamically based on label width
        DEFINE_RECT input_rect, kFindLeft + kLabelHOffset, kControlsTop, kDAWidth-250, kControlsTop + kTextBoxHeight
        DEFINE_RECT input_clear_rect, kFindLeft + kLabelHOffset+1, kControlsTop+1, kDAWidth-250-1, kControlsTop + kTextBoxHeight-1
        DEFINE_POINT input_textpos, kTextBoxTextHOffset, kControlsTop + kTextBoxTextVOffset

        DEFINE_BUTTON search, res_string_button_search, kDAWidth-235, kControlsTop
        DEFINE_BUTTON cancel, res_string_button_cancel, kDAWidth-120, kControlsTop

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy
pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

cursor_ip_flag: .byte   0

kBufSize = 16                       ; max length = 15, length
buf_search:     .res    kBufSize, 0 ; search term

        .include "../lib/line_edit_res.s"

top_row:        .byte   0

;;; ============================================================

.proc Init
        ;; Prep input string
        copy    #0, buf_search

        jsr     line_edit__Init

        param_call MeasureString, find_label_str
        addax   input_rect::x1
        add16   input_rect::x1, input_textpos::xcoord, input_textpos::xcoord
        add16_8 input_rect::x1, #1, input_clear_rect::x1

        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::OpenWindow, winfo_results
        MGTK_CALL MGTK::HideCursor
        jsr     DrawWindow
        jsr     line_edit__Update
        jsr     DrawResults
        MGTK_CALL MGTK::ShowCursor
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        ;; Since ZP preservation is on for DAs, MGTK calls are much
        ;; slower. Approximate normal IP blink speed by making multiple
        ;; idle calls.
        copy    #24, count
:       jsr     line_edit__Idle
        dec     count
        count := *+1
        lda     #SELF_MODIFIED_BYTE
        bne     :-

        param_call JTRelay, JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown
        cmp     #MGTK::EventKind::key_down
        jeq     HandleKey
        cmp     #MGTK::EventKind::no_event
        jeq     HandleNoEvent
        jmp     InputLoop
.endproc

.proc Exit
        param_call JTRelay, JUMP_TABLE_CUR_POINTER

        MGTK_CALL MGTK::CloseWindow, winfo_results
        MGTK_CALL MGTK::CloseWindow, winfo
        param_call JTRelay, JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc

;;; ============================================================
;;; Line Edit

.scope line_edit
        buf_text := buf_search
        textpos := input_textpos
        clear_rect := input_clear_rect
        frame_rect := input_rect
        kLineEditMaxLength := kMaxFilenameLength
        NotifyTextChanged := NoOp
        click_coords := screentowindow_params::window

.proc SetPort
        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc

.proc IsAllowedChar
        ;; Valid characters are . 0-9 A-Z a-z ? *
        cmp     #'*'            ; Wildcard
        beq     insert
        cmp     #'?'            ; Wildcard
        beq     insert
        cmp     #'.'            ; Filename char (here and below)
        beq     insert
        cmp     #'0'
        bcc     ignore
        cmp     #'9'+1
        bcc     insert
        cmp     #'A'
        bcc     ignore
        cmp     #'Z'+1
        bcc     insert
        cmp     #'a'
        bcc     ignore
        cmp     #'z'+1
        bcs     ignore

insert: clc
        rts

ignore: sec
        rts
.endproc

.proc NoOp
        rts
.endproc

        .include "../lib/line_edit.s"

.endscope ; line_edit
line_edit__Init := line_edit::Init
line_edit__Idle := line_edit::Idle
line_edit__Update := line_edit::Update

;;; ============================================================

.proc HandleKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF_NOT_ZERO
        ;; Modified
        cmp     #CHAR_UP
      IF_EQ
        copy    #MGTK::Part::page_up, findcontrol_params::which_part
        jmp     HandleScroll
     END_IF

        cmp     #CHAR_DOWN
      IF_EQ
        copy    #MGTK::Part::page_down, findcontrol_params::which_part
        jmp     HandleScroll
      END_IF

        jsr     line_edit::Key
    ELSE
        ;; Not modified
        cmp     #CHAR_ESCAPE
      IF_EQ
        param_call FlashButton, cancel_button_rect
        jmp     Exit
      END_IF

        cmp     #CHAR_RETURN
      IF_EQ
        param_call FlashButton, search_button_rect
        jmp     DoSearch
      END_IF

        cmp     #CHAR_UP
      IF_EQ
        copy    #MGTK::Part::up_arrow, findcontrol_params::which_part
        jmp     HandleScroll
      END_IF

        cmp     #CHAR_DOWN
      IF_EQ
        copy    #MGTK::Part::down_arrow, findcontrol_params::which_part
        jmp     HandleScroll
      END_IF

        jsr     line_edit::Key
    END_IF

        jmp     InputLoop
.endproc

;;; ============================================================

.proc DoSearch
        param_call JTRelay, JUMP_TABLE_CUR_WATCH

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
        jsr     UpdateViewport
        jsr     DrawResults

        bit     cursor_ip_flag
    IF_PLUS
        param_call JTRelay, JUMP_TABLE_CUR_POINTER
    ELSE
        param_call JTRelay, JUMP_TABLE_CUR_IBEAM
    END_IF

finish: jmp     InputLoop
.endproc


;;; ============================================================

.proc HandleDown
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
        param_call ButtonPress, search_button_rect
        beq     :+
        bmi     done
        jmp     DoSearch
:
        param_call ButtonPress, cancel_button_rect
        beq     :+
        bmi     done
        jmp     Exit
:
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, input_rect
        cmp     #MGTK::inrect_inside
        bne     done
        jsr     line_edit::Click

done:   jmp     InputLoop

        ;; Click in Results content area
results:
        copy16  event_params::xcoord, findcontrol_params::mousex
        copy16  event_params::ycoord, findcontrol_params::mousey
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     done

        jmp     HandleScroll
.endproc


;;; ============================================================
;;; Handle scroll bar


.proc HandleScroll
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

        jsr     UpdateViewport
        jsr     DrawResults

done:   jmp     InputLoop

max_top:        .byte   0
.endproc

;;; Assumes `top_row` is set.
.proc UpdateViewport
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

.proc ButtonPress
        kOutside         = 0
        kCanceled        = $FF
        kClicked         = 1

        stax    inrect_addr
        stax    fillrect_addr
        jsr     TestRect
        beq     :+
        return  #kOutside

:       jsr     InvertRect

        copy    #0, down_flag

loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     exit

        jsr     TestRect
        beq     inside

        lda     down_flag       ; outside but was inside?
        beq     invert
        jmp     loop

inside: lda     down_flag       ; already depressed?
        bne     invert
        jmp     loop

invert: jsr     InvertRect
        lda     down_flag
        clc
        adc     #$80
        sta     down_flag
        jmp     loop

exit:   lda     down_flag       ; was depressed?
        beq     :+
        return  #kCanceled
:       jsr     InvertRect     ; invert one last time
        return  #kClicked

down_flag:
        .byte   0

TestRect:
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, 0, inrect_addr
        cmp     #MGTK::inrect_inside
        rts

InvertRect:
        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, 0, fillrect_addr
        rts
.endproc

;;; ============================================================
;;; Call with rect addr in A,X

.proc FlashButton
        stax    fillrect_addr

        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penXOR
        jsr     sub
        FALL_THROUGH_TO sub

sub:    MGTK_CALL MGTK::PaintRect, 0, fillrect_addr
        rts
.endproc

;;; ============================================================


;;; ============================================================


.proc HandleNoEvent
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
        param_call JTRelay, JUMP_TABLE_CUR_POINTER
        jmp     done

inside:
        bit     cursor_ip_flag
        bmi     done
        copy    #$80, cursor_ip_flag
        param_call JTRelay, JUMP_TABLE_CUR_IBEAM

done:   jmp     InputLoop
.endproc

;;; ============================================================

.proc DrawWindow
        copy    #kDAWindowID, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        ;; No need to check results, since window is always visible.
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, input_rect

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, find_label_pos
        param_call DrawString, find_label_str

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, search_button_rect
        MGTK_CALL MGTK::MoveTo, search_button_pos
        param_call DrawString, search_button_label

        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call DrawString, cancel_button_label

        MGTK_CALL MGTK::ShowCursor
done:   rts
.endproc

;;; ============================================================

.proc DrawResults
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
        jsr     GetEntry

        param_call DrawString, entry_buf
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
;;; Populate entry_buf with entry in A

.proc GetEntry
        jsr     GetEntryAddr
        stax    STARTLO

        add16   STARTLO, #64, ENDLO
        copy16  #entry_buf, DESTINATIONLO

        sec                     ; main>aux
        jsr     AUXMOVE

        rts
.endproc

;;; ============================================================

        .include "../lib/drawstring.s"
        .include "../lib/measurestring.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00
