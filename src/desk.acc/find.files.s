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
        .include "../toolkits/letk.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/lbtk.inc"
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
;;;          | File Names  | |             |
;;;          + - - - - - - + |             |
;;;          |             | |             |
;;;          |             | | GUI code &  |
;;;          | search code | | resources   |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc RunDA
        sty     path_length
        jsr     Init
        RETURN  A=show_index
.endproc ; RunDA

;;; ============================================================

kDAWindowId     = $80
kDAWidth        = 465
kDAHeight       = kResultsHeight + 40
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

kResultsWindowId        = kDAWindowId+1
kResultsWidth           = kDAWidth - 60
kResultsWidthSB         = kResultsWidth + 20
kResultsHeight          = kResultsRows * kListItemHeight - 1
kResultsLeft            = kDALeft + (kDAWidth - kResultsWidthSB) / 2
kResultsTop             = kDATop + 30

kResultsRows    = 11                ; line height is 10

.params winfo
window_id:      .byte   kDAWindowId
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
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

cur_line:       .byte   0

entry_buf:
        .res    ::kPathBufferSize

;;; ============================================================

        .include "../lib/event_params.s"

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport_win
.endparams

grafport_win:   .tag    MGTK::GrafPort

;;; ============================================================

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

        kControlsTop = 10
        kFindLeft = 20
        DEFINE_LABEL find, res_string_label_find, kFindLeft, 20

        ;; Left edges are adjusted dynamically based on label width
        DEFINE_RECT input_rect, kFindLeft + kLabelHOffset, kControlsTop, kDAWidth-250, kControlsTop + kTextBoxHeight

        DEFINE_BUTTON search_button, kDAWindowId, res_string_button_search, kGlyphReturn, kDAWidth-235, kControlsTop

        DEFINE_BUTTON cancel_button, kDAWindowId, res_string_button_cancel, res_string_button_cancel_shortcut, kDAWidth-120, kControlsTop

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

kBufSize = ::kMaxFilenameLength+1     ; max length = 15, length
buf_search:     .res    kBufSize, 0 ; search term

pattern:        .res    16      ; null-terminated/upcased version

;;; ============================================================
;;; Search field

        DEFINE_LINE_EDIT line_edit_rec, kDAWindowId, buf_search, kFindLeft + kLabelHOffset, kControlsTop, kDAWidth-250-(kFindLeft+kLabelHOffset), kMaxFilenameLength
        DEFINE_LINE_EDIT_PARAMS le_params, line_edit_rec

;;; ============================================================
;;; List Box

        DEFINE_LIST_BOX_WINFO winfo_results, \
                kResultsWindowId, \
                kResultsLeft, \
                kResultsTop, \
                kResultsWidth, \
                kResultsHeight, \
                DEFAULT_FONT
        DEFINE_LIST_BOX listbox_rec, winfo_results, \
                kResultsRows, SELF_MODIFIED_BYTE, \
                DrawListEntryProc, NoOp, NoOp
        DEFINE_LIST_BOX_PARAMS lb_params, listbox_rec

selected_index := listbox_rec::selected_index
num_entries := listbox_rec::num_items

;;; ============================================================

.proc Init
        ;; Prep input string
        copy8   #0, buf_search


        CALL    MeasureString, AX=#find_label_str
        addax   input_rect::x1
        add16_8 input_rect::x1, #1, line_edit_rec::rect::x1

        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::OpenWindow, winfo_results
        MGTK_CALL MGTK::HideCursor
        jsr     DrawWindow
        LETK_CALL LETK::Init, le_params
        LETK_CALL LETK::Activate, le_params
        MGTK_CALL MGTK::ShowCursor

        copy8   #0, num_entries
        LBTK_CALL LBTK::Init, lb_params

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        LETK_CALL LETK::Idle, le_params
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        jsr     GetNextEvent

        cmp     #kEventKindMouseMoved
        jeq     HandleMouseMove

        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown

        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        bne     InputLoop       ; always
.endproc ; InputLoop

.proc Exit
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer

        MGTK_CALL MGTK::CloseWindow, winfo_results
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        ldx     event_params::modifiers
        sta     le_params::key
        stx     le_params::modifiers
        sta     lb_params::key
        stx     lb_params::modifiers

    IF A IN #CHAR_UP, #CHAR_DOWN
        LBTK_CALL LBTK::Key, lb_params
        jmp     InputLoop
    END_IF

    IF X <> #0
        ;; Modified
        lda     event_params::key
        jsr     ToUpperCase

        cmp     #kShortcutCloseWindow
        jeq     Exit

      IF A = #'O'
        lda     selected_index
        bmi     InputLoop
        sta     show_index
        jmp     Exit
      END_IF

        LETK_CALL LETK::Key, le_params
        jmp     InputLoop
    END_IF

        ;; Not modified
    IF A = #CHAR_ESCAPE
        BTK_CALL BTK::Flash, cancel_button
        jmp     Exit
    END_IF

    IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, search_button
        jmp     DoSearch
    END_IF

        jsr     IsControlChar
        bcc     allow
        jsr     IsSearchChar
        bcs     ignore
allow:  LETK_CALL LETK::Key, le_params
ignore:
        jmp     InputLoop
.endproc ; HandleKey

;;; ============================================================

;;; Input: A=character
;;; Output: C=0 if control, C=1 if not
.proc IsControlChar
        cmp     #CHAR_DELETE
        bcs     yes

        cmp     #' '
        rts                     ; C=0 (if less) or 1

yes:    RETURN  C=0
.endproc ; IsControlChar

;;; ============================================================

;;; Input: A=character
;;; Output: C=0 if valid, C=1 otherwise
.proc IsSearchChar
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

.if kBuildSupportsLowercase
        cmp     #'a'
        bcc     ignore
        cmp     #'z'+1
        bcs     ignore
.else
        bcs     ignore          ; always
.endif

insert: RETURN  C=0

ignore: RETURN  C=1
.endproc ; IsSearchChar

;;; ============================================================

;;; Called during iteration; this ensures the mouse cursor remains
;;; responsive.
;;; Output: A=CHAR_ESCAPE if Esc key was pressed, A=0 otherwise

.proc CheckEvents
        MGTK_CALL MGTK::CheckEvents
        MGTK_CALL MGTK::PeekEvent, event_params
        MGTK_CALL MGTK::FlushEvents

        lda     event_params::kind
        cmp     #MGTK::EventKind::key_down
        bne     nope
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        bne     nope
        rts

nope:   RETURN  A=#0
.endproc ; CheckEvents

;;; ============================================================

path_length:
        .byte   0

.proc DoSearch
        MGTK_CALL MGTK::GetCursorAdr, cursor_addr
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch

        copy8   #0, num_entries
        copy8   #$ff, selected_index
        LBTK_CALL LBTK::Init, lb_params
        jsr     PrepDrawIncrementalResults

        lda     path_length
    IF A = #1
        JSR_TO_MAIN ::main::InitVolumes
        JSR_TO_MAIN ::main::NextVolume
        bcs     finish
    END_IF

        ;; Do the search
search:
        ;; Convert `buf_search` to a null-terminated uppercase string
        ;; and copy to main
        ldy     buf_search
        copy8   #0, pattern,y   ; null-terminate
        cpy     #0
    IF NE
      DO
        lda     buf_search,y    ; copy characters
        jsr     ToUpperCase
        sta     pattern-1,y
        dey
      WHILE NOT_ZERO
    END_IF

        copy16  #pattern, STARTLO
        copy16  #pattern+kMaxFilenameLength, ENDLO
        copy16  #::main::RecursiveCatalog::pattern, DESTINATIONLO
        CALL    AUXMOVE, C=0    ; aux>main

        ;; And invoke it!
        ldy     num_entries     ; A,X are trashed by macro
        JSR_TO_MAIN  ::main::RecursiveCatalog::Start
        sty     num_entries
        sty     lb_params::new_size
        LBTK_CALL LBTK::SetSize, lb_params ; update scrollbar

        lda     path_length
    IF A = #1
        lda     num_entries
        cmp     #kMaxFilePaths
        beq     finish
        JSR_TO_MAIN ::main::NextVolume
        bcc     search
    END_IF

finish:
        MGTK_CALL MGTK::SetCursor, SELF_MODIFIED, cursor_addr
        jmp     InputLoop

.endproc ; DoSearch

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        jne     done

        lda     findwindow_params::window_id
    IF A = #kResultsWindowId
        COPY_STRUCT event_params::coords, lb_params::coords
        LBTK_CALL LBTK::Click, lb_params
      IF NC
        jsr     DetectDoubleClick
       IF NC
        copy8   selected_index, show_index
        jmp     Exit
       END_IF
      END_IF

        jmp     InputLoop
    END_IF

        cmp     #kDAWindowId
        bne     done

        ;; Click in DA content area
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, search_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, search_button
        bmi     done
        jmp     DoSearch
    END_IF

        MGTK_CALL MGTK::InRect, cancel_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
        bmi     done
        jmp     Exit
    END_IF

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, input_rect
        beq     done

        COPY_STRUCT screentowindow_params::window, le_params::coords
        LETK_CALL LETK::Click, le_params

done:   jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleMouseMove
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, input_rect
    IF ZERO
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
    ELSE
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
    END_IF
        jmp     InputLoop
.endproc ; HandleMouseMove

;;; ============================================================

.proc SetPortForDialog
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc ; SetPortForDialog

;;; ============================================================

.proc DrawWindow
        jsr     SetPortForDialog
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::FrameRect, input_rect

        MGTK_CALL MGTK::MoveTo, find_label_pos
        CALL    DrawString, AX=#find_label_str

        BTK_CALL BTK::Draw, search_button
        BTK_CALL BTK::Draw, cancel_button

        MGTK_CALL MGTK::ShowCursor
done:   rts
.endproc ; DrawWindow

;;; ============================================================
;;; Populate `entry_buf` with entry in A

.proc GetEntry
        jsr     GetEntryAddr
        stax    STARTLO

        add16   STARTLO, #kPathBufferSize-1, ENDLO
        copy16  #entry_buf, DESTINATIONLO

        TAIL_CALL AUXMOVE, C=1  ; main>aux
.endproc ; GetEntry

;;; ============================================================
;;; List Box
;;; ============================================================

;;; Set to the selected index to show on exit.
show_index:     .byte   $FF

NoOp:   rts

;;; ============================================================

;;; Called with A = index
.proc DrawListEntryProc
        jsr     GetEntry
        TAIL_CALL DrawString, AX=#entry_buf
.endproc ; DrawListEntryProc

;;; ============================================================

        DEFINE_POINT cur_pos, 0, 0

.proc PrepDrawIncrementalResults
        MGTK_CALL MGTK::SetPort, winfo_results::port
        copy8   #0, cur_line
        copy16  #kListItemTextOffsetX, cur_pos+MGTK::Point::xcoord
        copy16  #kListItemTextOffsetY, cur_pos+MGTK::Point::ycoord
        rts
.endproc ; PrepDrawIncrementalResults

.proc DrawNextResult
        MGTK_CALL MGTK::MoveTo, cur_pos

        CALL    DrawListEntryProc, A=cur_line

        add16_8 cur_pos+MGTK::Point::ycoord, #kListItemHeight
        inc     cur_line
        rts
.endproc ; DrawNextResult

;;; ============================================================

;;; Keep in sync with the copy of this in main!
.proc GetEntryAddr
        sta     num
        sta     offset
        lda     #0
        sta     offset+1

        ;; Compute num * 65
        ldx     #6              ; offset = num * 64
    DO
        asl16   offset
        dex
    WHILE NOT_ZERO

        add16_8 offset, num ; offset += num, so * 65
        add16   offset, #::main::entries_buffer, offset

        RETURN  AX=offset

num:    .byte   0
offset: .addr   0
.endproc ; GetEntryAddr

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/drawstring.s"
        .include "../lib/measurestring.s"
        .include "../lib/doubleclick.s"
        .include "../lib/get_next_event.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
.scope main

;;; ============================================================

        MLIEntry := MLI
        block_buffer := $1A00

entry:

.scope
        ptr := $06

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

        jmp     continue

        ;; --------------------------------------------------
        ;; Search all volumes

no_windows:
        ;; Signal this mode with a path of just "/"
        copy8   #1, searchPath
        copy8   #'/', searchPath+1

        ;; --------------------------------------------------

continue:

        ;; Run the DA
        ldy     searchPath      ; A,X are trashed by macro
        JSR_TO_AUX aux::RunDA

        ;; Show an entry?
    IF POS
        ;; Copy entry path to `INVOKER_PREFIX`
        jsr     GetEntryAddr
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
      DO
        copy8   ($06),y, INVOKER_PREFIX,y
        dey
      WHILE POS

        ;; Inject JT call to stack
        pla
        tax
        pla
        tay

        PUSH_RETURN_ADDRESS JUMP_TABLE_SHOW_FILE

        tya
        pha
        txa
        pha
    END_IF

        rts
.endscope

;;; ============================================================

;;; Keep in sync with the copy of this in main!
.proc GetEntryAddr
        sta     num
        sta     offset
        lda     #0
        sta     offset+1

        ;; Compute num * 65
        ldx     #6              ; offset = num * 64
    DO
        asl16   offset
        dex
    WHILE NOT_ZERO
        add16_8 offset, num ; offset += num, so * 65
        add16   offset, #entries_buffer, offset

        RETURN  AX=offset

num:    .byte   0
offset: .addr   0
.endproc ; GetEntryAddr

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

num_entries:
        .byte   0

.proc Start
        sty     num_entries     ; copy in main

        ;; Run with normal ZP and ROM
        sta     ALTZPOFF
        bit     ROMIN2

        bit     KBDSTRB         ; clear strobe

        ldy     searchPath      ; prime the search path
    DO
        copy8   searchPath,y, nameBuffer,y
        dey
    WHILE POS

        lda     #0              ; reset recursion/results state
        sta     Depth

        jsr     Relay           ; for stack restore
        ldy     num_entries

        ;; DA runs with aux ZP and LC
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts

.proc Relay
        tsx
        stx     saved_stack

        TAIL_CALL ReadDir, AX=#nameBuffer
.endproc ; Relay
.endproc ; Start

.proc Terminate
        MLI_CALL CLOSE, CloseParms ; close the directory

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

        ;; Check length
        pha                     ; A = storage type
        ASSERT_EQUALS FileEntry::storage_type_name_length, 0
        clc
        lda     (entPtr),y
        and     #NAME_LENGTH_MASK
        adc     (dirName),y
    IF A >= #kMaxPathLength
        pla                     ; A = storage type (ignored)
        bne     nextEntry       ; always
    END_IF
        pla                     ; A = storage type

        cmp     #(ST_LINKED_DIRECTORY<<4) ; is it a directory?
        beq     ItsADir         ; yes, so call VisitDir
        jsr     VisitFile       ; no, it's a file
        jmp     nextEntry

ItsADir:
        jsr     VisitDir

nextEntry:
        jsr     CheckEventsFromMain
        cmp     #CHAR_ESCAPE
        beq     Terminate

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
        bne     exit
    END_IF

        ;; Does the file match the search pattern?
        lda     pattern         ; Skip if pattern is empty
    IF NOT_ZERO
        jsr     IsMatch
        bcc     exit            ; No match
    END_IF

        ptr := $0A
        CALL    GetEntryAddr, A=num_entries
        stax    ptr

        ;; Copy name to buffer

        jsr     ExtendName      ; Appends entry name to dirName plus '/'

        ldy     #0
        lda     (dirName),y
        tay
    DO
        copy8   (dirName),y, (ptr),y
        dey
    WHILE NOT_ZERO

        lda     (dirName),y     ; Y is 0...
        tax
        dex                     ; Chop off the trailing '/'
        txa
        sta     (ptr),y

        jsr     ChopName        ; Restores the name
        inc     num_entries

        ;; Render it
        jsr     DrawNextResultFromMain

        ;; If we've hit max number of entries, terminate operation.
        lda     num_entries
        cmp     #kMaxFilePaths
        jeq     Terminate

exit:   rts
.endproc ; VisitFile

;;;
;;;******************************************************
;;;
.proc VisitDir

        ;; Treat directories like files
        jsr     VisitFile

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

        MLI_CALL SET_MARK, SetMParms ; reset the file marker

        MLI_CALL READ, ReadParms ; now read in the block we were on last.

        dec     Depth
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
        MLI_CALL READ, ReadParms ; get the next block
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

;;; ============================================================

pattern:        .res    16      ; 15 + null terminator
string:         .res    16      ; 15 + null terminator

.proc IsMatch

.scope
        ;; Copy filename to null terminated string buffer
        ASSERT_EQUALS FileEntry::storage_type_name_length, 0, "Can't treat as Pascal string"
        ASSERT_EQUALS FileEntry::file_name, 1, "Can't treat as Pascal string"
        ldy     #FileEntry::storage_type_name_length
        lda     (entPtr),y
        and     #NAME_LENGTH_MASK
        tay
        copy8   #0, string,y    ; null-terminate
        cpy     #0
    IF NE
      DO
        lda     (entPtr),y      ; copy characters
        jsr     ToUpperCase

        sta     string-1,y
        dey
      WHILE NOT_ZERO
    END_IF
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
.endproc ; IsMatch

.endscope ; RecursiveCatalog


;;; ============================================================

;;; Called from Main with normal ZP/ROM. Bank in everything
;;; needed for MGTK, draw the latest result, and restore banks.

.proc DrawNextResultFromMain
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        JSR_TO_AUX aux::DrawNextResult

        sta     ALTZPOFF
        bit     ROMIN2

        rts
.endproc ; DrawNextResultFromMain

;;; ============================================================

;;; Called from Main with normal ZP/ROM. Bank in everything
;;; needed for MGTK, check events, and restore banks.

.proc CheckEventsFromMain
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        JSR_TO_AUX aux::CheckEvents

        sta     ALTZPOFF
        bit     ROMIN2

        rts
.endproc ; CheckEventsFromMain

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

ReadSetting = JUMP_TABLE_READ_SETTING

        .include "../lib/uppercase.s"

;;; ============================================================

entries_buffer := *

;;; ============================================================
.endscope ; main

        DA_END_MAIN_SEGMENT


kMaxFilePaths = (::main::block_buffer - ::main::entries_buffer) / kPathBufferSize

;;; ============================================================
