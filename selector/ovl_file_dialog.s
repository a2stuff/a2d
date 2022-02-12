;;; ============================================================
;;; Run a Program File Picker Dialog - Overlay #1
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "ovl_file_dialog.res"

.scope file_dialog
        .org ::OVERLAY_ADDR

;;; ============================================================

ep_init:
        jmp     Start

ep_loop:
        jmp     EventLoop

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

        .include "../lib/event_params.s"

.params getwinport_params
window_id:     .byte   0
a_grafport:    .addr   window_grafport
.endparams

window_grafport:
        .tag    MGTK::GrafPort
main_grafport:
        .tag    MGTK::GrafPort

double_click_counter_init:
        .byte   $FF

pointer_cursor:
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000)
        .byte   PX(%0110000),PX(%0000000)
        .byte   PX(%0111000),PX(%0000000)
        .byte   PX(%0111100),PX(%0000000)
        .byte   PX(%0111110),PX(%0000000)
        .byte   PX(%0111111),PX(%0000000)
        .byte   PX(%0101100),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000)
        .byte   PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%1100000),PX(%0000000)
        .byte   PX(%1110000),PX(%0000000)
        .byte   PX(%1111000),PX(%0000000)
        .byte   PX(%1111100),PX(%0000000)
        .byte   PX(%1111110),PX(%0000000)
        .byte   PX(%1111111),PX(%0000000)
        .byte   PX(%1111111),PX(%1000000)
        .byte   PX(%1111111),PX(%0000000)
        .byte   PX(%0001111),PX(%0000000)
        .byte   PX(%0001111),PX(%0000000)
        .byte   PX(%0000111),PX(%1000000)
        .byte   PX(%0000111),PX(%1000000)
        .byte   1,1

ibeam_cursor:
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%0001010),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0000100),PX(%0000000)
        .byte   PX(%0001010),PX(%0000000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%1111011),PX(%1100000)
        .byte   PX(%0111111),PX(%1000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0001110),PX(%0000000)
        .byte   PX(%0111111),PX(%1000000)
        .byte   PX(%1111011),PX(%1100000)
        .byte   PX(%0110001),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000)
        .byte   4, 5

;;; Text Input Field
buf_text:       .res    68, 0

;;; String being edited:
buf_input_left:         .res    68, 0 ; left of IP
buf_input_right:        .res    68, 0 ; IP and right

;;; ============================================================
;;; File Picker Dialog


;;; ============================================================

        .byte   $00
        .byte   $00

prompt_ip_counter:
        .word   1             ; immediately decremented to 0 and reset

        .byte   $00

prompt_ip_flag:
        .byte   $00
blink_ip_flag:
        .byte   $00
        .byte   $00

str_insertion_point:
        PASCAL_STRING {kGlyphInsertionPoint} ; do not localize

;;; Flags that control the behavior of the file picker dialog.

input_dirty_flag:
        .byte   $00

        .byte   $00             ; TODO: Unused
        .byte   $00             ; TODO: Unused
        .byte   $00             ; TODO: Unused

        ;; Used to draw/clear insertion point; overwritten with char
        ;; to right of insertion point as needed.
str_1_char:
        PASCAL_STRING {0}       ; do not localize

        ;; Used as suffix for text being edited to account for insertion
        ;; point adding extra width.
str_2_spaces:
        PASCAL_STRING "  "      ; do not localize

;;; ============================================================

        .include "../lib/file_dialog_res.s"

str_file_to_run:
        PASCAL_STRING res_string_label_file_to_run

;;; ============================================================

start:  jsr     OpenWindow
        jsr     DrawWindow
        jsr     DeviceOnLine
        jsr     ReadDir
        jsr     UpdateScrollbar
        jsr     UpdateDiskName
        jsr     DrawListEntries
        jsr     InitInput
        jsr     PrepPathInput1
        jsr     RedrawInput
        lda     #$FF
        sta     blink_ip_flag
        jmp     EventLoop

;;; ============================================================

.proc InitInput
        lda     #$00
        sta     buf_input1_left
        sta     focus_in_input2_flag
        copy    #1, buf_input_right
        copy    #kGlyphInsertionPoint, buf_input_right+1
        rts
.endproc

;;; ============================================================

.proc DrawWindow
        lda     file_dialog_res::winfo::window_id
        jsr     SetPortForWindow
        param_call DrawTitleCentered, app::str_run_a_program
        param_call DrawInput1Label, str_file_to_run
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, file_dialog_res::input1_rect
        MGTK_CALL MGTK::InitPort, main_grafport
        MGTK_CALL MGTK::SetPort, main_grafport
        rts
.endproc

;;; ============================================================

.proc HandleOk
        param_call VerifyValidNonVolumePath, buf_input1_left
        beq     :+
        rts

:       ldx     saved_stack
        txs
        ldy     #<buf_input1_left
        ldx     #>buf_input1_left
        sta     $07
        return  #$00
.endproc

;;; ============================================================

.proc HandleCancel
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
        lda     #$00
        sta     blink_ip_flag
        jsr     UnsetCursorIBeam
        ldx     saved_stack
        txs
        return  #$FF
.endproc

;;; ============================================================

;;; Required proc definitions:
YieldLoop               := app::YieldLoop
DetectDoubleClick       := app::DetectDoubleClick
ButtonEventLoop         := app::ButtonEventLoop
ModifierDown            := app::ModifierDown
ShiftDown               := app::ShiftDown

;;; Required data definitions:
buf_input1_left := buf_input_left

;;; Required macro definitions:
.define LIB_MGTK_CALL MGTK_CALL
.define LIB_MLI_CALL MLI_CALL

        .define FD_EXTENDED 0
        .include "../lib/file_dialog.s"

;;; ============================================================
;;; Determine if mouse moved
;;; Output: C=1 if mouse moved

.proc CheckMouseMoved
        ldx     #.sizeof(MGTK::Point)-1
:       lda     event_coords,x
        cmp     coords,x
        bne     diff
        dex
        bpl     :-
        clc
        rts

diff:   COPY_STRUCT MGTK::Point, event_coords, coords
        sec
        rts

        DEFINE_POINT coords, 0, 0
.endproc

;;; ============================================================

         ADJUSTCASE_VOLPATH := $810
         ADJUSTCASE_VOLBUF  := $820
         ADJUSTCASE_IO_BUFFER := $1C00
        .include "../lib/adjustfilecase.s"
        .include "../lib/muldiv.s"

;;; ============================================================

.endscope

file_dialog_init   := file_dialog::ep_init
file_dialog_loop   := file_dialog::ep_loop

        PAD_TO OVERLAY_ADDR + kOverlay1Size
        .assert * <= $BF00, error, "Overwrites ProDOS Global Page"

.undefine LIB_MGTK_CALL
.undefine LIB_MLI_CALL
