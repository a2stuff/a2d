;;; ============================================================
;;; Resources
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        RESOURCE_FILE "alert_dialog.res"

        .org kAlertSegmentAddress

kShortcutTryAgain = res_char_button_try_again_shortcut

.proc AlertById
        jmp     start

;;; --------------------------------------------------
;;; Messages

str_selector_unable_to_run:
        PASCAL_STRING res_string_alert_selector_unable_to_run
str_io_error:
        PASCAL_STRING res_string_alert_io_error
str_no_device:
        PASCAL_STRING res_string_alert_no_device
str_pathname_does_not_exist:
        PASCAL_STRING res_string_alert_pathname_does_not_exist
str_insert_source_disk:
        PASCAL_STRING res_string_alert_insert_source_disk
str_file_not_found:
        PASCAL_STRING res_string_alert_file_not_found
str_insert_system_disk:
        PASCAL_STRING res_string_alert_insert_system_disk
str_basic_system_not_found:
        PASCAL_STRING res_string_alert_basic_system_not_found

kNumAlerts = 8

alert_table:
        .byte   AlertID::selector_unable_to_run
        .byte   AlertID::io_error
        .byte   AlertID::no_device
        .byte   AlertID::pathname_does_not_exist
        .byte   AlertID::insert_source_disk
        .byte   AlertID::file_not_found
        .byte   AlertID::insert_system_disk
        .byte   AlertID::basic_system_not_found
        ASSERT_TABLE_SIZE alert_table, kNumAlerts

message_table:
        .addr   str_selector_unable_to_run
        .addr   str_io_error
        .addr   str_no_device
        .addr   str_pathname_does_not_exist
        .addr   str_insert_source_disk
        .addr   str_file_not_found
        .addr   str_insert_system_disk
        .addr   str_basic_system_not_found
        ASSERT_ADDRESS_TABLE_SIZE message_table, kNumAlerts

alert_options_table:
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::TryAgainCancel
        .byte   AlertButtonOptions::Ok
        .byte   AlertButtonOptions::TryAgainCancel
        .byte   AlertButtonOptions::Ok
        ASSERT_TABLE_SIZE alert_options_table, kNumAlerts

.params alert_params
text:           .addr   0
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams

start:  pha                     ; alert number
        lda     app::L9129      ; if non-zero, just return cancel
        beq     :+
        pla
        return  #kAlertResultCancel
:       pla                     ; alert number

        ;; --------------------------------------------------
        ;; Process Options, populate `alert_params`

        ;; A = alert

        ;; Search for alert in table, set Y to index
        ldy     #kNumAlerts-1
:       cmp     alert_table,y
        beq     :+
        dey
        bpl     :-
        ldy     #0              ; default
:

        ;; Look up message
        tya                     ; Y = index
        asl     a
        tay                     ; Y = index * 2
        copy16  message_table,y, alert_params::text

        ;; Look up button options
        tya                     ; Y = index * 2
        lsr     a
        tay                     ; Y = index
        copy    alert_options_table,y, alert_params::buttons

        ldax    #alert_params
        jmp     Alert
.endproc

;;; ============================================================
;;; Display alert
;;; Inputs: A,X=alert_params structure
;;;    { .addr text, .byte AlertButtonOptions, .byte AlertOptions }

        pointer_cursor = app::pointer_cursor
        Bell = app::Bell
        DrawString = app::DrawString
        AlertYieldLoop = app::AlertYieldLoopRelay
        alert_grafport = app::grafport2

        .include "../lib/alert_dialog.s"

;;; ============================================================

        PAD_TO kAlertSegmentAddress + kAlertSegmentSize
