;;; ============================================================
;;; RUN.BASIC.HERE - Desk Accessory
;;;
;;; Launches BASIC.SYSTEM with PREFIX set to the path of the
;;; current window. BYE will return to DeskTop. Looks for
;;; BASIC.SYSTEM up the directory tree from DeskTop itself.
;;; ============================================================

        .include "../config.inc"

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
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |Win Tables |
;;;  $1C00   +-----------+ |           |
;;;  $1B00   |           | +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | | (unused)  |
;;;          | DA        | |           |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

        .org DA_LOAD_ADDRESS

;;; ============================================================

        jmp     start

;;; ============================================================

bs_path:        .res    kPathBufferSize, 0
prefix_path:    .res    kPathBufferSize, 0

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, bs_path
        DEFINE_OPEN_PARAMS open_params, bs_path, DA_IO_BUFFER
        DEFINE_READ_PARAMS read_params, PRODOS_SYS_START, MLI-PRODOS_SYS_START
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, prefix_path
        DEFINE_QUIT_PARAMS quit_params

;;; ============================================================

        ;; Early errors - show alert and return to DeskTop
fail:   jmp     JUMP_TABLE_SHOW_ALERT

start:
        ;; Get active window's path
        jsr     get_win_path
        beq     :+
        lda     #kErrNoWindowsOpen
        bne     fail            ; always

        ;; Find BASIC.SYSTEM
:       jsr     check_basic_system
        beq     :+
        lda     #kErrBasicSysNotFound
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
        ;; https://github.com/a2stuff/a2d/issues/95
        MLI_CALL SET_PREFIX, set_prefix_params
        bcs     quit

        ;; Launch
        jmp     PRODOS_SYS_START

        ;; Late errors - QUIT, which should relaunch DeskTop
quit:   MLI_CALL QUIT, quit_params


;;; ============================================================

        DEFINE_GET_PREFIX_PARAMS get_prefix_params, bs_path

.proc check_basic_system
        ;; Was DeskTop copied to a RAM Card?
        jsr     GetCopiedToRAMCardFlag
        bpl     get_current_prefix ; nope

        ;; Use original location, since BASIC.SYSTEM was unlikely
        ;; to be copied.
        param_call CopyDeskTopOriginalPrefix, bs_path
        jmp     got_prefix

get_current_prefix:
        JUMP_TABLE_MLI_CALL GET_PREFIX, get_prefix_params
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

        JUMP_TABLE_MLI_CALL GET_FILE_INFO, get_file_info_params
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
        PASCAL_STRING "BASIC.SYSTEM" ; do not localize
.endproc

;;; ============================================================

.proc get_win_path
        ptr := $06

        JUMP_TABLE_MGTK_CALL MGTK::FrontWindow, ptr
        lda     ptr             ; any window open?
        beq     fail
        cmp     #kMaxDeskTopWindows+1
        bcs     fail

        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    ptr

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

        .include "../lib/ramcard.s"
