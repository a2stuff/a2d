;;; ============================================================
;;; Invoker - loaded into MAIN $290-$3EF
;;;
;;; Compiled as part of DeskTop and Selector
;;; ============================================================

;;; Used to invoke other programs (system, binary, BASIC)

.scope invoker
        .org ::INVOKER

        MLIEntry := MLI

start:
        jmp     begin

;;; ============================================================

        DEFINE_SET_PREFIX_PARAMS set_prefix_params, INVOKER_PREFIX

prefix_length:
        .byte   0

;;; High bit set if an interpreter is being invoked, and
;;; the start protocol must be followed.
interpreter_flag:
        .byte   0

        DEFINE_OPEN_PARAMS open_params, INVOKER_FILENAME, $800, 1
        DEFINE_READ_PARAMS read_params, PRODOS_SYS_START, MLI - PRODOS_SYS_START
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_GET_FILE_INFO_PARAMS get_info_params, INVOKER_FILENAME

kBSOffset       = 5             ; Offset of 'C' in BASIC.SYSTEM
str_basic_system:
        PASCAL_STRING "BASIC.SYSTEM" ; do not localize

        ;; $EE = extended call signature for IIgs/GS/OS variation.
        DEFINE_QUIT_PARAMS quit_params, $EE, INVOKER_FILENAME

;;; ============================================================

.proc SetPrefix
        MLI_CALL SET_PREFIX, set_prefix_params
        beq     :+
        pla
        pla
        jmp     exit
:       rts
.endproc

;;; ============================================================

.proc Open
        MLI_CALL OPEN, open_params
        rts
.endproc

;;; ============================================================

begin:  bit     ROMIN2

        copy16  #PRODOS_SYS_START, jmp_addr

        ;; Clear system memory bitmap
        ldx     #BITMAP_SIZE-2
        lda     #0
:       sta     BITMAP,x
        dex
        bne     :-

        jsr     SetPrefix
        lda     INVOKER_PREFIX
        sta     prefix_length
        MLI_CALL GET_FILE_INFO, get_info_params
        beq     :+
        jmp     exit
:       lda     get_info_params::file_type


;;; ProDOS 16 System file (S16) - invoke via QUIT call
        cmp     #FT_S16
        bne     not_s16

        jsr     update_bitmap
        jmp     quit_call
not_s16:

;;; Binary file (BIN) - load and invoke at A$=AuxType
        cmp     #FT_BINARY
        bne     not_binary

        lda     get_info_params::aux_type
        sta     jmp_addr
        sta     read_params::data_buffer
        lda     get_info_params::aux_type+1
        sta     jmp_addr+1
        sta     read_params::data_buffer+1

        cmp     #$0C            ; If loading at page < $0C
        bcs     :+
        lda     #$BB            ; ... use a high address buffer ($BB)
        sta     open_params::io_buffer+1
        bne     load_target     ; always
:       lda     #$08            ; ... otherwise a low address buffer ($08)
        sta     open_params::io_buffer+1
        bne     load_target     ; always
not_binary:

;;; BASIC file (BAS) - invoke interpreter as path instead.
;;; (If not found, ProDOS QUIT will be invoked.)
        cmp     #FT_BASIC       ; BASIC?
        bne     not_basic

        copy16  #str_basic_system, open_params::pathname

        ;; Try opening interpreter with current prefix.
check_for_interpreter:
        jsr     Open
        beq     found_interpreter
        ldy     INVOKER_PREFIX   ; Pop a path segment to try
:       lda     INVOKER_PREFIX,y ; parent directory.
        cmp     #'/'
        beq     update_prefix
        dey
        cpy     #1
        bne     :-
        jmp     exit

update_prefix:                  ; Update prefix and try again.
        dey
        sty     INVOKER_PREFIX
        jsr     SetPrefix
        jmp     check_for_interpreter

found_interpreter:
        copy    #$80, interpreter_flag
        lda     prefix_length
        sta     INVOKER_PREFIX
        jmp     do_read

not_basic:

;;; ProDOS 8 System file (SYS) - load at default $2000
        cmp     #FT_SYSTEM
        beq     load_target

;;; Use BASIS.SYSTEM as fallback if present.
;;; (If not found, ProDOS QUIT will be invoked.)
        copy    #'S', str_basic_system + kBSOffset ; "BASIC" -> "BASIS"
        copy16  #str_basic_system, open_params::pathname
        jmp     check_for_interpreter

;;; TODO: ProDOS 2.4's Bitsy Bye invokes BASIS.SYSTEM with:
;;; * [x] ProDOS prefix set to directory containing file.
;;; * [x] Path buffer in BASIS.SYSTEM set to filename.
;;; * [ ] $280 set to name of root volume
;;; * [ ] $380 set to path of launched SYS (i.e. path to BASIS.SYSTEM)
;;; Not all should be necessary, but not doing so may lead to future
;;; compatibility issues. Those addresses conflict with this code.

;;; ============================================================
;;; Load target at given address

load_target:
        jsr     Open
        bne     exit
do_read:
        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        bne     exit
        MLI_CALL CLOSE, close_params
        bne     exit

        ;; If interpreter, set prefix and copy filename to interpreter buffer.
        lda     get_info_params::file_type
        bit     interpreter_flag
        bpl     update_stack

        jsr     SetPrefix
        ldy     INVOKER_FILENAME
:       lda     INVOKER_FILENAME,y
        sta     PRODOS_INTERPRETER_BUF,y         ; ProDOS interpreter protocol
        dey
        bpl     :-

        ;; Set return address to the QUIT call below
update_stack:
        lda     #>(quit_call-1)
        pha
        lda     #<(quit_call-1)
        pha
        jsr     update_bitmap

        jmp_addr := *+1
        jmp     PRODOS_SYS_START

quit_call:
        MLI_CALL QUIT, quit_params

        ;; Update system bitmap
update_bitmap:
        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP
        FALL_THROUGH_TO exit

exit:   rts

.endscope ; invoker

        ;; Pad to $160 bytes
        PAD_TO $3F0
