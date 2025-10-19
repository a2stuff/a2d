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
;;;          | IO Buffer | |           |
;;;  $1C00   +-----------+ |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | | (unused)  |
;;;          | DA        | |           |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

;;; ============================================================

        DA_HEADER
        DA_START_MAIN_SEGMENT

;;; ============================================================

        jmp     start

;;; ============================================================

bs_path:        .res    kPathBufferSize, 0
prefix_path:    .res    kPathBufferSize, 0

        MLIEntry := MLI

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, bs_path
        DEFINE_OPEN_PARAMS open_params, bs_path, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, PRODOS_SYS_START, MLI-PRODOS_SYS_START
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_PREFIX_PARAMS set_prefix_params, prefix_path
        DEFINE_QUIT_PARAMS quit_params

;;; ============================================================

        ;; Early errors - show alert and return to DeskTop
fail:   jmp     JUMP_TABLE_SHOW_ALERT

start:
        ;; Get active window's path
        jsr     GetWinPath
    IF NOT_ZERO
        lda     #kErrNoWindowsOpen
        bne     fail            ; always
    END_IF

        ;; Find BASIC.SYSTEM
        jsr     CheckBasicSystem
    IF NOT_ZERO
        lda     #kErrBasicSysNotFound
        bne     fail
    END_IF

         ;; Restore system state: devices, /RAM, ROM/ZP banks.
        jsr     JUMP_TABLE_RESTORE_SYS

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


.proc CheckBasicSystem
        ;; Check well known location first
        JUMP_TABLE_MLI_CALL GET_PREFIX, get_prefix_params
        bcs     no_bs

        ldy     #0
        ldx     bs_path
    DO
        iny
        inx
        copy8   str_extras_basic,y, bs_path,x
    WHILE Y <> str_extras_basic
        stx     bs_path

        JUMP_TABLE_MLI_CALL GET_FILE_INFO, get_file_info_params
        RTS_IF CC

        ;; Not there - search from `prefix_path` upwards
        ldx     prefix_path
        stx     path_length
    DO
        copy8   prefix_path,x, bs_path,x
        dex
    WHILE POS

        inc     bs_path
        ldx     bs_path
        copy8   #'/', bs_path,x
loop:
        ;; Append BASIC.SYSTEM to path and check for file.
        ldx     bs_path
        ldy     #0
    DO
        inx
        iny
        copy8   str_basic_system,y, bs_path,x
    WHILE Y <> str_basic_system
        stx     bs_path
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, get_file_info_params
        bcs     not_found
        rts                     ; zero is success

        ;; Pop off a path segment and try again.
not_found:
        ldx     path_length
    DO
        lda     bs_path,x
        cmp     #'/'
        beq     found_slash
        dex
    WHILE NOT_ZERO

no_bs:  return8 #$FF            ; non-zero is failure

found_slash:
        cpx     #1
        beq     no_bs
        stx     bs_path
        dex
        stx     path_length
        jmp     loop

        ;; length of directory path e.g. "/VOL/DIR/"
path_length:
        .byte   0

str_extras_basic:
        PASCAL_STRING .concat(kFilenameExtrasDir, "/BASIC.SYSTEM")
str_basic_system:
        PASCAL_STRING "BASIC.SYSTEM"
.endproc ; CheckBasicSystem

;;; ============================================================

.proc GetWinPath
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
    DO
        copy8   (ptr),y, prefix_path,y
        dey
    WHILE POS
        return8 #0

fail:   return8 #1

.endproc ; GetWinPath

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
