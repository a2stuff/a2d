;;; ============================================================
;;; RUN.BASIC.HERE - Desk Accessory
;;;
;;; Launches BASIC.SYSTEM with PREFIX set to the path of the
;;; current window. BYE will return to DeskTop. Looks for
;;; BASIC.SYSTEM up the directory tree from DeskTop itself.
;;; ============================================================

        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ============================================================

        .org $800

;;; ============================================================

        jmp     start

;;; ============================================================

bs_path:        .res    65, 0
prefix_path:    .res    65, 0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, bs_path
        DEFINE_OPEN_PARAMS open_params, bs_path, $C00
        DEFINE_READ_PARAMS read_params, $2000, $BF00-$2000
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, prefix_path
        DEFINE_QUIT_PARAMS quit_params

;;; ============================================================

        ;; Early errors - show alert and return to DeskTop
fail:   jsr JUMP_TABLE_ALERT_X
        rts

start:
        ;; Get active window's path
        jsr     get_win_path
        beq     :+
        lda     #ERR_FILE_NOT_OPENABLE
        bne     fail

        ;; Find BASIC.SYSTEM
:       jsr     check_basic_system
        beq     :+
        lda     #ERR_BASIC_SYS_NOT_FOUND
        bne     fail

         ;; Restore system state: devices, /RAM, ROM/ZP banks.
:       jsr     JUMP_TABLE_RESTORE_SYS

        ;; Load BS
        MLI_CALL OPEN, open_params
        bcs     quit
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num

        MLI_CALL READ, read_params
        bcs     quit

        MLI_CALL CLOSE, close_params
        bcs     quit

        ;; Set PREFIX. Do this last; see:
        ;; https://github.com/inexorabletash/a2d/issues/95
        MLI_CALL SET_PREFIX, set_prefix_params
        bcs     quit

        ;; Launch
        jmp     $2000

        ;; Late errors - QUIT, which should relaunch DeskTop
quit:   MLI_CALL QUIT, quit_params


;;; ============================================================

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, bs_path

.proc check_basic_system
        ;; Was DeskTop copied to a RAM Card?
        jsr     get_copied_to_ramcard_flag
        bpl     get_current_prefix ; nope

        ;; Use original location, since BASIC.SYSTEM was unlikely
        ;; to be copied.
        addr_call copy_desktop_orig_prefix, bs_path
        jmp     got_prefix

get_current_prefix:
        yax_call JUMP_TABLE_MLI, GET_PREFIX, get_prefix_params
        bne     no_bs

got_prefix:
        lda     bs_path
        sta     path_length

        ;; Append BASIC.SYSTEM to path and check for file.
loop:   ldx     path_length
        ldy     #0
:       inx
        iny
        copy    str_basic_system,y, bs_path,x
        cpy     str_basic_system
        bne     :-
        stx     bs_path

        yax_call JUMP_TABLE_MLI, GET_FILE_INFO, get_file_info_params
        bne     not_found
        rts

        ;; Pop off a path segment and try again.
not_found:
        ldx     path_length
        dex
:       lda     bs_path,x
        cmp     #'/'
        beq     found_slash
        dex
        bne     :-

found_slash:
        cpx     #1
        beq     no_bs
        stx     path_length
        jmp     loop

no_bs:  return  #1

        ;; length of directory path e.g. "/VOL/DIR/"
path_length:
        .byte   0

str_basic_system:
        PASCAL_STRING "BASIC.SYSTEM"
.endproc

;;; ============================================================

.proc get_win_path
        ptr := $06

        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::FrontWindow, ptr
        lda     ptr             ; any window open?
        beq     fail
        cmp     #9              ; windows are 1-8
        bcs     fail

        asl     a               ; window index * 2
        tay
        copy16  path_table,y, ptr

        ldy     #0
        lda     (ptr),y
        tay
:       copy    (ptr),y, prefix_path,y
        dey
        bpl     :-
        return  #0

fail:   return  #1

.endproc

;;; ============================================================

.proc get_copied_to_ramcard_flag
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        lda     copied_to_ramcard_flag
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

.proc copy_desktop_orig_prefix
        stax    @destptr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     desktop_orig_prefix
:       lda     desktop_orig_prefix,x
        @destptr := *+1
        sta     $1234,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc
