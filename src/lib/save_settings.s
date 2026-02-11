;;; ============================================================
;;; Save Settings
;;;
;;; Used in control panel DAs
;;; ============================================================

        .include "../inc/prodos.inc"
        .include "../lib/alert_dialog.inc"

filename:
        PASCAL_STRING kPathnameDeskTopConfig

filename_buffer:
        .res kPathBufferSize

        write_buffer := DA_IO_BUFFER - kDeskTopSettingsFileSize

        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS write_params, write_buffer, kDeskTopSettingsFileSize
        DEFINE_CLOSE_PARAMS close_params

;;; Run from Main, but with Aux LCBANK1 in
.proc SaveSettings

        ;; Copy from Main LCBANK2 to somewhere ProDOS can read.

        sta     ALTZPOFF
        bit     LCBANK2
        bit     LCBANK2

        COPY_STRUCT DeskTopSettings, SETTINGS, write_buffer + kDeskTopSettingsFileOffset
        copy8   #kDeskTopSettingsFileVersion, write_buffer

        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        ;; Write to desktop current prefix
        ldax    #filename
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     _DoWrite
        bcs     done            ; failed and canceled

        ;; Write to the original file location, if necessary
        jsr     JUMP_TABLE_GET_RAMCARD_FLAG
        beq     done
        ldax    #filename_buffer
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     JUMP_TABLE_GET_ORIG_PREFIX
        jsr     _AppendFilename
        jsr     _DoWrite

done:   rts

.proc _AppendFilename
        ;; Append filename to buffer
        inc     filename_buffer ; Add '/' separator
        ldx     filename_buffer
        lda     #'/'
        sta     filename_buffer,x

        ldx     #0              ; Append filename
        ldy     filename_buffer
    DO
        inx
        iny
        lda     filename,x
        sta     filename_buffer,y
    WHILE X <> filename
        sty     filename_buffer
        rts
.endproc ; _AppendFilename

.proc _DoWrite
        ;; First time - ask if we should even try.
        copy8   #kErrSaveChanges, message

retry:
        ;; Create if necessary
        copy16  DATELO, create_params::create_date
        copy16  TIMELO, create_params::create_time
        JUMP_TABLE_MLI_CALL CREATE, create_params

        JUMP_TABLE_MLI_CALL OPEN, open_params
        bcs     error
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL WRITE, write_params
        php                     ; preserve result
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
        bcc     ret             ; succeeded

error:
        message := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     JUMP_TABLE_SHOW_ALERT ; `kErrSaveChanges` or `kErrInsertSystemDisk`

        ;; Second time - prompt to insert.
        ldx     #kErrInsertSystemDisk
        stx     message

        ;; Responses are either OK/Cancel or Try Again/Cancel
        cmp     #kAlertResultCancel
        bne     retry

        sec                     ; failed
ret:    rts

second_try_flag:
        .byte   0
.endproc ; _DoWrite

.endproc ; SaveSettings
