;;; ============================================================
;;; MAKE.LINK - Desk Accessory
;;;
;;; Create a link file for the selected icon in the LINKS/ directory
;;; under the desktop folder.
;;;
;;; Note that this is likely a temporary tool; after some additional
;;; noodling it's likely that this functionality will be pulled into
;;; DeskTop itself.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"
        .include "../toolkits/icontk.inc"

;;; ============================================================

.define kFilenameLinksDir      "Links"

;;; ============================================================

        DA_HEADER
        DA_START_MAIN_SEGMENT

;;; ============================================================

        jmp     Start

;;; ============================================================
;;; ProDOS call parameter blocks

;;; Param block written out as new link file
.params link_struct
        .byte   kLinkFileSig1Value
        .byte   kLinkFileSig2Value
        .byte   kLinkFileCurrentVersion
length: .byte   0
path:   .res    64,0
.endparams

        INVOKE_PATH := $220

dir_path:
        PASCAL_STRING kFilenameLinksDir

path_buf:
        .res    kPathBufferSize, 0

        DEFINE_GET_FILE_INFO_PARAMS gfi_params, INVOKE_PATH
        DEFINE_GET_PREFIX_PARAMS prefix_params, INVOKE_PATH

        DEFINE_CREATE_PARAMS create_dir_params, dir_path, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY
        DEFINE_CREATE_PARAMS create_params, path_buf, ACCESS_DEFAULT, FT_LINK, kLinkFileAuxType

        DEFINE_OPEN_PARAMS open_params, path_buf, DA_IO_BUFFER
        DEFINE_WRITE_PARAMS write_params, link_struct, .sizeof(link_struct)
        DEFINE_CLOSE_PARAMS close_params

;;; ============================================================
;;; Main DA logic

.proc Start
        ;; TODO: Show better error if no selection (shows invalid path)

        ;; Verify target exists
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, gfi_params
        bcs     err

        ;; Compose names
        COPY_STRING INVOKE_PATH, link_struct::length
        jsr     PrepareName

        ;; Create dir (ok if it already exists)
        JUMP_TABLE_MLI_CALL CREATE, create_dir_params
        bcc     :+
        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
:
        ;; Create link file (ok if it already exists)
        JUMP_TABLE_MLI_CALL CREATE, create_params
        bcc     :+
        cmp     #ERR_DUPLICATE_FILENAME
        bne     err
:
        ;; Write out link file
        JUMP_TABLE_MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL WRITE, write_params
        php
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
        bcs     err

        ;; --------------------------------------------------
        ;; Show new link file

        JUMP_TABLE_MLI_CALL GET_PREFIX, prefix_params

        ;; Append relative path to PREFIX
        ldy     INVOKE_PATH
        ldx     #0
:       iny
        inx
        lda     path_buf,x
        sta     INVOKE_PATH,y
        cpx     path_buf
        bne     :-
        sty     INVOKE_PATH

        ;; Inject JT call to stack
        pla
        tax
        pla
        tay

        lda     #>(JUMP_TABLE_SHOW_FILE-1)
        pha
        lda     #<(JUMP_TABLE_SHOW_FILE-1)
        pha

        tya
        pha
        txa
        pha

        rts

        ;; --------------------------------------------------
        ;; Error - A = ProDOS error code

err:    jmp     JUMP_TABLE_SHOW_ALERT
.endproc ; Start

;;; ============================================================

.proc PrepareName
        ;; Stick in dir name
        ldx     #1
        ldy     #1
:       lda     dir_path,x
        sta     path_buf,y
        cpx     dir_path
        beq     :+
        inx
        iny
        bne     :-              ; always
:
        ;; Append slash
        lda     #'/'
        iny
        sta     path_buf,y

        ;; Find / in target
        ldx     INVOKE_PATH
:       lda     INVOKE_PATH,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-              ; always
:
        ;; Copy last segment
:       inx
        iny
        lda     INVOKE_PATH,x
        sta     path_buf,y
        cpx     INVOKE_PATH
        bne     :-

        ;; Assign length and done
        sty     path_buf
        rts
.endproc ; PrepareName

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
