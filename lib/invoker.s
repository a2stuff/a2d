;;; ============================================================
;;; Invoker - loaded into MAIN $290-$3EF
;;;
;;; Compiled as part of DeskTop and Selector
;;; ============================================================

;;; Used to invoke other programs (system, binary, BASIC)

.scope invoker
        .org ::INVOKER

        MLIEntry := MLI

;;; ============================================================

start:
        copy16  #PRODOS_SYS_START, jmp_addr

        ;; Clear system memory bitmap
        ldx     #BITMAP_SIZE-2
        lda     #0
:       sta     BITMAP,x
        dex
        bne     :-
        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP

        ;; Interpreter?
        lda     INVOKER_INTERPRETER
        bne     use_interpreter ; Yes, load it

        ;; Set prefix
        MLI_CALL SET_PREFIX, set_prefix_params
        bcs     ret

        ;; Check file type
        MLI_CALL GET_FILE_INFO, get_info_params
        bcs     ret
        lda     get_info_params__file_type

;;; Binary file (BIN) - load and invoke at A$=AuxType
        cmp     #FT_BINARY
    IF_EQ

        lda     get_info_params__aux_type
        sta     jmp_addr
        sta     read_params__data_buffer
        lda     get_info_params__aux_type+1
        sta     jmp_addr+1
        sta     read_params__data_buffer+1

        cmp     #$0C            ; If loading at page < $0C00
        bcs     :+
        lda     #$BB            ; ... use a high address buffer ($BB00)
        .byte   OPC_BIT_abs     ; skip next 2-byte instruction
:       lda     #$08            ; ... otherwise a low address buffer ($0800)
        sta     open_params__io_buffer+1
        jmp     load_target
    END_IF

;;; ProDOS 8 System file (SYS) - load at default $2000
        cmp     #FT_SYSTEM
        beq     load_target

;;; ProDOS 16 System file (S16) - invoke via QUIT call
        cmp     #FT_S16
        beq     quit_call

        ;; Failure
ret:    rts

;;; ============================================================
;;; Interpreter - `INVOKER_INTERPRETER` populated by caller

;;; ProDOS 2.4's Bitsy Bye invokes BASIS.SYSTEM with:
;;; * ProDOS prefix set to directory containing file.
;;; * Path buffer in BASIS.SYSTEM ($2006) set to filename.
;;; * $280 set to name of root volume (e.g. "/VOL")
;;; * $380 set to path of launched SYS (e.g. "/VOL/BASIS.SYSTEM")
;;; Not all should be necessary, but not doing so may lead to future
;;; compatibility issues.

BITSY_ROOT = $280
BITSY_PATH = $380
.assert INVOKER_INTERPRETER = BITSY_PATH, error, "location mismatch"

use_interpreter:
        copy16  #INVOKER_INTERPRETER, open_params__pathname
        FALL_THROUGH_TO load_target

;;; ============================================================
;;; Load target at given address

load_target:
        MLI_CALL OPEN, open_params
        bcs     exit
do_read:
        lda     open_params__ref_num
        sta     read_params__ref_num
        MLI_CALL READ, read_params
        bcs     exit
        MLI_CALL CLOSE, close_params
        bcs     exit

        ;; If interpreter, copy filename to interpreter buffer.
        lda     INVOKER_INTERPRETER
    IF_NE
        MLI_CALL SET_PREFIX, set_prefix_params
        bcs     exit
        ldy     INVOKER_FILENAME
:       lda     INVOKER_FILENAME,y
        sta     PRODOS_INTERPRETER_BUF,y         ; ProDOS interpreter protocol
        dey
        bpl     :-

        ;; Also populate vol name (like Bitsy) now that memory is free.
        .assert INVOKER_FILENAME = BITSY_VOL, error, "location mismatch"
        ldx     #1              ; start at leading '/'
        lda     INVOKER_PREFIX,x
:       sta     BITSY_VOL,x
        cpx     INVOKER_PREFIX  ; hit the end?
        beq     :+
        inx
        lda     INVOKER_PREFIX,x ; found another '/'?
        cmp     #'/'
        bne     :-
        dex
:       stx     BITSY_VOL
    END_IF

        ;; Set return address to the QUIT call below
        ;; (mostly for invoking BIN files)
        lda     #>(quit_call-1)
        pha
        lda     #<(quit_call-1)
        pha

        jmp_addr := *+1
        jmp     PRODOS_SYS_START

quit_call:
        MLI_CALL QUIT, quit_params

exit:   rts

;;; ============================================================

        PAD_TO ::INVOKER_INTERPRETER
        .res    ::kPathBufferSize, 0

;;; ============================================================

        DEFINE_SET_PREFIX_PARAMS set_prefix_params, INVOKER_PREFIX

        DEFINE_OPEN_PARAMS open_params, INVOKER_FILENAME, $800, 1
        open_params__ref_num := open_params::ref_num
        open_params__io_buffer := open_params::io_buffer
        open_params__pathname := open_params::pathname

        DEFINE_READ_PARAMS read_params, PRODOS_SYS_START, MLI - PRODOS_SYS_START
        read_params__ref_num := read_params::ref_num
        read_params__data_buffer := read_params::data_buffer

        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS get_info_params, INVOKER_FILENAME
        get_info_params__file_type := get_info_params::file_type
        get_info_params__aux_type := get_info_params::aux_type

        ;; $EE = extended call signature for IIgs/GS/OS variation.
        DEFINE_QUIT_PARAMS quit_params, $EE, INVOKER_FILENAME


.endscope ; invoker

        ;; Pad to $160 bytes
        PAD_TO $3F0
