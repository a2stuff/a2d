;;; ============================================================
;;; Invoker - loaded into MAIN $290-$3EF
;;; ============================================================

;;; Used to invoke other programs (system, binary, BASIC)

.proc invoker
        .org $290

start:
        jmp     begin

;;; ============================================================

        PRODOS_SYS_START := $2000 ; for SYS files
        PRODOS_INTERPRETER_BUF := $2006

        DEFINE_SET_PREFIX_PARAMS set_prefix_params, INVOKER_PREFIX

prefix_length:
        .byte   0

        DEFINE_OPEN_PARAMS open_params, INVOKER_FILENAME, $800, 1
        DEFINE_READ_PARAMS read_params, PRODOS_SYS_START, MLI - PRODOS_SYS_START
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_GET_FILE_INFO_PARAMS get_info_params, INVOKER_FILENAME

        .byte   0,0,0           ; Unused

str_basic_system:
        PASCAL_STRING "BASIC.SYSTEM"

        ;; $EE = extended call signature for IIgs/GS/OS variation.
        DEFINE_QUIT_PARAMS quit_params, $EE, INVOKER_FILENAME

;;; ============================================================

.proc set_prefix
        MLI_CALL SET_PREFIX, set_prefix_params
        beq     :+
        pla
        pla
        jmp     exit
:       rts
.endproc

;;; ============================================================

.proc open
        MLI_CALL OPEN, open_params
        rts
.endproc

;;; ============================================================

begin:  lda     ROMIN2

        copy16  #PRODOS_SYS_START, jmp_addr

        ;; Clear system memory bitmap
        ldx     #BITMAP_SIZE-2
        lda     #0
:       sta     BITMAP,x
        dex
        bne     :-

        jsr     set_prefix
        lda     INVOKER_PREFIX
        sta     prefix_length
        MLI_CALL GET_FILE_INFO, get_info_params
        beq     :+
        jmp     exit
:       lda     get_info_params::file_type

;;; ProDOS 16 System file (S16) - invoke via QUIT call
        cmp     #FT_S16
        bne     not_s16
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
        bne     load_target
        copy16  #str_basic_system, open_params::pathname

        ;; Try opening interpreter with current prefix.
check_for_interpreter:
        jsr     open
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
        jsr     set_prefix
        jmp     check_for_interpreter

found_interpreter:
        lda     prefix_length
        sta     INVOKER_PREFIX
        jmp     do_read

not_basic:

;;; TODO: Use BASIS.SYSTEM as fallback if present.

;;; ============================================================
;;; Load target at given address

load_target:
        jsr     open
        bne     exit
do_read:
        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        bne     exit
        MLI_CALL CLOSE, close_params
        bne     exit
        lda     get_info_params::file_type
        cmp     #FT_BASIC
        bne     update_stack

        jsr     set_prefix
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
        jsr     update_bitmap   ; WTF?

        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP

        jmp_addr := *+1
        jmp     PRODOS_SYS_START

update_bitmap:
        rts                     ; no-op?

quit_call:
        jsr     update_bitmap
        MLI_CALL QUIT, quit_params
exit:   rts

.endproc ; invoker

        ;; Pad to $160 bytes
        PAD_TO $3F0
