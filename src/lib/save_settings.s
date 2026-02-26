;;; ============================================================
;;; Save Settings
;;;
;;; Used in control panel DAs
;;; ============================================================

        .include "../inc/prodos.inc"
        .include "../lib/alert_dialog.inc"

.scope save_settings

filename:
        PASCAL_STRING kPathnameDeskTopConfig

        write_buffer := DA_IO_BUFFER - kDeskTopSettingsFileSize

        ;; If running from RAMCard, we temporarily swap the ProDOS
        ;; prefix for writing back to the startup disk.
        current_prefix := write_buffer - kPathBufferSize
        orig_prefix := current_prefix - kPathBufferSize
        data_buffer := orig_prefix

        DEFINE_DESTROY_PARAMS destroy_params, filename
        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS write_params, write_buffer, kDeskTopSettingsFileSize
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_PREFIX_PARAMS current_prefix_params, current_prefix
        DEFINE_GET_PREFIX_PARAMS orig_prefix_params, orig_prefix

local_dir:      PASCAL_STRING kFilenameLocalDir
        DEFINE_CREATE_PARAMS create_localdir_params, local_dir, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

;;; ============================================================

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

        ;; First time - ask if we should even try.
        CLEAR_BIT7_FLAG retry_flag

        ;; Write to desktop current prefix
        jsr     _DoWrite
        bcs     done            ; failed and canceled

        ;; Write to the original file location, if necessary
        jsr     JUMP_TABLE_GET_RAMCARD_FLAG
    IF ZC
        CALL    JUMP_TABLE_GET_ORIG_PREFIX, AX=#orig_prefix
        JUMP_TABLE_MLI_CALL GET_PREFIX, current_prefix_params
retry:
        JUMP_TABLE_MLI_CALL SET_PREFIX, orig_prefix_params
      IF CS
        jsr     _CheckRetry
        beq     retry
        sec                     ; failed
        rts
      END_IF
        jsr     _DoWrite
        JUMP_TABLE_MLI_CALL SET_PREFIX, current_prefix_params
        ;; Assert: Succeeded (otherwise RAMCard was deleted out from under us)
    END_IF

done:   rts
.endproc ; SaveSettings

.proc _DoWrite
        ldax    DATELO
        stax    create_params::create_date
        stax    create_localdir_params::create_date
        ldax    TIMELO
        stax    create_params::create_time
        stax    create_localdir_params::create_time

        ;; Create local dir if necessary
retry1:
        JUMP_TABLE_MLI_CALL CREATE, create_localdir_params
    IF CS AND A <> #ERR_DUPLICATE_FILENAME
        jsr     _CheckRetry
        beq     retry1
        bne     failed          ; always
    END_IF

        ;; Destroy existing settings file if necessary
        ;; This is to catch write failures before the file `OPEN`, as
        ;; failure to `WRITE`/`FLUSH` will make the `CLOSE` fail,
        ;; leaving the `io_buffer` in use.
retry2:
        JUMP_TABLE_MLI_CALL DESTROY, destroy_params
    IF CS AND A <> #ERR_FILE_NOT_FOUND
        jsr     _CheckRetry
        beq     retry2
        bne     failed          ; always
    END_IF

        ;; Create/write settings file if necessary
retry3:
        JUMP_TABLE_MLI_CALL CREATE, create_params
        JUMP_TABLE_MLI_CALL OPEN, open_params
    IF CC
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL WRITE, write_params
        JUMP_TABLE_MLI_CALL CLOSE, close_params
    END_IF
    IF CS
        jsr     _CheckRetry
        beq     retry3
        bne     failed          ; always
    END_IF
        rts                     ; C=0

failed:
        sec
        rts                     ; C=1
.endproc ; _DoWrite

;;; Before calling: ensure `retry_flag` was cleared at some point.
;;; Input: A = ProDOS error code
;;; Output: Z = 1 if retry was selected
.proc _CheckRetry
    IF bit retry_flag : NC
        ;; First time - prompt see if we want to try saving.
        SET_BIT7_FLAG retry_flag
        CALL    JUMP_TABLE_SHOW_ALERT, A=#kErrSaveChanges ; OK/Cancel
        cmp     #kAlertResultOK
        rts                     ; Z=1 if OK selected (i.e. retry)
    END_IF

        ;; Special case
    IF A = #ERR_VOL_NOT_FOUND
        lda     #kErrInsertSystemDisk ; Try Again/Cancel
    END_IF
        jsr     JUMP_TABLE_SHOW_ALERT ; arbitrary ProDOS error
        ;; Responses are either OK or Try Again/Cancel
        cmp     #kAlertResultTryAgain
        rts
.endproc

retry_flag:        .byte   0 ; bit7

.endscope ; save_settings
SaveSettings := save_settings::SaveSettings
write_buffer := save_settings::data_buffer
