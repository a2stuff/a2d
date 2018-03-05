        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../macros.inc"

;;; ============================================================
;;; Segment loaded into MAIN $290-$3EF
;;; ============================================================

;;; Used to invoke other programs (system, binary, BASIC)

.proc invoker
        .org $290

PREFIX          := $220
FILENAME        := $280                 ; File to invoke, set by caller

start:
        jmp     begin

;;; ============================================================

        default_start_address := $2000

        DEFINE_SET_PREFIX_PARAMS set_prefix_params, PREFIX

prefix_length:
        .byte   0

        DEFINE_OPEN_PARAMS open_params, FILENAME, $800, 1
        DEFINE_READ_PARAMS read_params, default_start_address, $9F00
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_GET_FILE_INFO_PARAMS get_info_params, FILENAME

        .res    3

bs_path:
        PASCAL_STRING "BASIC.SYSTEM"

        DEFINE_QUIT_PARAMS quit_params, $EE, FILENAME

;;; ============================================================

set_prefix:
        MLI_CALL SET_PREFIX, set_prefix_params
        beq     :+
        pla
        pla
        jmp     exit
:       rts

;;; ============================================================

open:   MLI_CALL OPEN, open_params
        rts

;;; ============================================================

begin:  lda     ROMIN2

        copy16  #default_start_address, jmp_addr

        ;; clear system memory bitmap
        ldx     #BITMAP_SIZE-2
        lda     #0
:       sta     BITMAP,x
        dex
        bne     :-

        jsr     set_prefix
        lda     PREFIX
        sta     prefix_length
        MLI_CALL GET_FILE_INFO, get_info_params
        beq     :+
        jmp     exit
:       lda     get_info_params::file_type
        cmp     #FT_S16
        bne     not_s16
        jsr     update_bitmap
        jmp     quit_call
not_s16:

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

        cmp     #FT_BASIC       ; BASIC?
        bne     load_target

        ;; Invoke BASIC.SYSTEM as path instead.
        copy16  #bs_path, open_params::pathname

        ;; Try opening BASIC.SYSTEM with current prefix.
check_for_bs:
        jsr     open
        beq     found_bs
        ldy     PREFIX          ; Pop a path segment to try
:       lda     PREFIX,y        ; parent directory.
        cmp     #'/'
        beq     update_prefix
        dey
        cpy     #1
        bne     :-
        jmp     exit

update_prefix:                  ; Update prefix and try again.
        dey
        sty     PREFIX
        jsr     set_prefix
        jmp     check_for_bs

found_bs:
        lda     prefix_length
        sta     PREFIX
        jmp     do_read

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

        ;; If it's BASIC, set prefix and copy filename to interpreter buffer.
        lda     get_info_params::file_type
        cmp     #FT_BASIC
        bne     update_stack
        jsr     set_prefix
        ldy     FILENAME
:       lda     FILENAME,y
        sta     $2006,y
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
        jmp     default_start_address

quit_call:
        MLI_CALL QUIT, quit_params

        ;; Update system bitmap
update_bitmap:
        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP
        rts

exit:   rts

        ;; Pad to $160 bytes
        .res    $160 - (* - start), 0
.endproc ; invoker
