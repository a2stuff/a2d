;;; ============================================================
;;; Invoker - loaded into MAIN $290-$3EF
;;;
;;; Compiled as part of DeskTop and Selector
;;; ============================================================

;;; Used to invoke other programs (system, binary, BASIC)

        BEGINSEG SegmentInvoker

.scope invoker

        MLIEntry := MLI

        ;; Reference local params, not the ones in parent scope
        PREDEFINE_SCOPE invoker::open_params
        PREDEFINE_SCOPE invoker::read_params
        PREDEFINE_SCOPE invoker::close_params

;;; ============================================================

        copy16  #PRODOS_SYS_START, jmp_addr

        ;; Interpreter?
        lda     INVOKER_INTERPRETER
        bne     use_interpreter ; Yes, load it

        ;; Set prefix
        MLI_CALL SET_PREFIX, set_prefix_params
        bcs     ret

        ;; Check file type
        MLI_CALL GET_FILE_INFO, get_info_params
        bcs     ret
        lda     get_info_params::file_type

;;; Binary file (BIN) - load and invoke at A$=AuxType
    IF_A_EQ     #FT_BINARY

        lda     get_info_params::aux_type
        sta     jmp_addr
        sta     read_params::data_buffer
        lda     get_info_params::aux_type+1
        sta     jmp_addr+1
        sta     read_params::data_buffer+1

      IF_A_LT   #$0C            ; If loading at page < $0C00
        lda     #$BB            ; ... use a high address buffer ($BB00)
        SKIP_NEXT_2_BYTE_INSTRUCTION
      END_IF
        lda     #$08            ; ... otherwise a low address buffer ($0800)
        sta     open_params::io_buffer+1
        jmp     load_target
    END_IF

;;; ProDOS 8 System file (SYS) - load at default $2000
        cmp     #FT_SYSTEM
        beq     load_target
        .assert INVOKER_FILENAME = PRODOS_SYS_PATH, error, "protocol mismatch"

;;; ProDOS 16 System file (S16) - invoke via QUIT call
        cmp     #FT_S16
        beq     quit_call

        ;; Failure
ret:    rts

;;; ============================================================
;;; Interpreter - `INVOKER_INTERPRETER` populated by caller

;;; Per "Starting System Programs" in the ProDOS 8 Technical Reference
;;; Manual:
;;; * $280 set to path of launched SYS (e.g. "/VOL/PROG.SYSTEM")
;;; * Path buffer at $2006 set to file path (e.g. "/DATA/MYFILE")
;;; * Paths may be absolute or relative (to prefix)
;;; * Prefix not guaranteed to be set to anything
;;; This is followed by the ProDOS 2.0.x selector and BASIC.SYSTEM
;;; when invoking SYS files.
;;;
;;; Note that ProDOS 2.4's Bitsy Bye has subtly different behavior:
;;; $280 is set to the path containing the invoked file, and $380 has
;;; the full path to the interpreter itself i.e. `BASIC.SYSTEM` or
;;; `BASIS.SYSTEM`.

use_interpreter:
        copy16  #INVOKER_INTERPRETER, open_params::pathname
        FALL_THROUGH_TO load_target

;;; ============================================================
;;; Load target at given address

load_target:
        MLI_CALL OPEN, open_params
        bcs     exit
        lda     open_params::ref_num
        sta     read_params::ref_num
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
      DO
        lda     INVOKER_FILENAME,y
        sta     PRODOS_INTERPRETER_BUF,y         ; ProDOS interpreter protocol
        dey
      WHILE_POS

        ;; ProDOS 2.4's Bitsy Bye populates $380 with the path to the
        ;; interpreter, so set both for good measure.
        BITSY_SYS_PATH := $380

        ;; Populate path to interpreter now that memory is free
        ldx     INVOKER_INTERPRETER
      DO
        lda    INVOKER_INTERPRETER,x
        sta     PRODOS_SYS_PATH,x
        sta     BITSY_SYS_PATH,x
        dex
      WHILE_POS

        ;; When launching BASIS.SYSTEM, ProDOS 2.4's Bitsy Bye populates
        ;; $280 with the path containing the target file.
        BITSY_DIR_PATH := $280
        bit     INVOKER_BITSY_COMPAT
      IF_NS
        ldy     INVOKER_PREFIX
       DO
        lda     INVOKER_PREFIX,y
        sta     BITSY_DIR_PATH,y
        dey
       WHILE_POS
      END_IF

    END_IF

        ;; Set return address to the QUIT call below
        ;; (mostly for invoking BIN files)
        PUSH_RETURN_ADDRESS quit_call

        jmp_addr := *+1
        jmp     PRODOS_SYS_START

quit_call:
        MLI_CALL QUIT, quit_params

exit:   rts

;;; ============================================================

        PAD_TO ::INVOKER_INTERPRETER
        .res    ::kPathBufferSize, 0
        ASSERT_ADDRESS ::INVOKER_BITSY_COMPAT
        .byte   0

;;; ============================================================

        DEFINE_SET_PREFIX_PARAMS set_prefix_params, INVOKER_PREFIX

        DEFINE_OPEN_PARAMS open_params, INVOKER_FILENAME, $800

        DEFINE_READWRITE_PARAMS read_params, PRODOS_SYS_START, MLI - PRODOS_SYS_START

        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS get_info_params, INVOKER_FILENAME

        ;; $EE = extended call signature for IIgs/GS/OS variation.
        DEFINE_QUIT_PARAMS quit_params, $EE, INVOKER_FILENAME


.endscope ; invoker

        ENDSEG SegmentInvoker
