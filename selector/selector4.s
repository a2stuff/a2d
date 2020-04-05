;;; ============================================================
;;; Invoker
;;; ============================================================

        .org $290

;;; Used to invoke the selected program (BIN, BAS, SYS, S16).

.scope
        jmp     start

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
        DEFINE_QUIT_PARAMS quit_params, $EE, $280

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

start:  lda     ROMIN2

        copy16  #PRODOS_SYS_START, invoke_addr

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
        sta     invoke_addr
        sta     read_params::data_buffer
        lda     get_info_params::aux_type+1
        sta     invoke_addr+1
        sta     read_params::data_buffer+1

        cmp     #$0C            ; If loading at page < $0C
        bcs     :+
        lda     #$BB            ; ... use a high address buffer ($BB)
        sta     open_params::io_buffer+1
        bne     load_target
:       lda     #$08            ; otherwise a low address buffer ($08)
        sta     open_params::io_buffer+1
        bne     load_target
not_binary:

;;; BASIC file (BAS) - invoke interpreter as path instead.
;;; (If not found, ProDOS QUIT will be invoked.)
        cmp     #FT_BASIC
        bne     load_target
        copy16  #str_basic_system, open_params::pathname

        ;;  Try opening interpreter with current prefix.
check_for_intepreter:
        jsr     open
        beq     found_interpreter
        ldy     INVOKER_PREFIX
:       lda     INVOKER_PREFIX,y
        cmp     #'/'
        beq     update_prefix
        dey
        cpy     #1
        bne     :-
        jmp     exit

update_prefix:
        dey
        sty     INVOKER_PREFIX
        jsr     set_prefix
        jmp     check_for_intepreter

found_interpreter:
        lda     prefix_length
        sta     INVOKER_PREFIX
        jmp     do_read

not_basic:

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

        invoke_addr := *+1
        jmp     PRODOS_SYS_START

update_bitmap:
        rts                     ; no-op?

quit_call:
        jsr     update_bitmap
        MLI_CALL QUIT, quit_params
exit:   rts

.endscope

        .incbin "inc/junk2.dat"

        ASSERT_ADDRESS $3F0
