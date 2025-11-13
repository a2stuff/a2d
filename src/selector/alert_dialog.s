;;; ============================================================
;;; Resources
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG SegmentAlert

.proc AlertById
        jmp     start

;;; --------------------------------------------------
;;; Messages

str_selector_unable_to_run:
        PASCAL_STRING res_string_alert_selector_unable_to_run
str_io_error:
        PASCAL_STRING res_string_err27_io_error
str_no_device:
        PASCAL_STRING res_string_err28_device_not_connected
str_pathname_does_not_exist:
        PASCAL_STRING res_string_err44_path_not_found
str_insert_source_disk:
        PASCAL_STRING res_string_alert_insert_source_disk
str_file_not_found:
        PASCAL_STRING res_string_err46_file_not_found
str_copy_incomplete:
        PASCAL_STRING res_string_error_copy_incomplete
str_not_enough_room:
        PASCAL_STRING res_string_error_not_enough_room
str_insert_system_disk:
        PASCAL_STRING res_string_alert_insert_system_disk
str_basic_system_not_found:
        PASCAL_STRING res_string_alert_basic_system_not_found

kNumAlerts = 10

alert_table:
        .byte   AlertID::selector_unable_to_run
        .byte   AlertID::io_error
        .byte   AlertID::no_device
        .byte   AlertID::pathname_does_not_exist
        .byte   AlertID::insert_source_disk
        .byte   AlertID::file_not_found
        .byte   AlertID::copy_incomplete
        .byte   AlertID::not_enough_room
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
        .addr   str_copy_incomplete
        .addr   str_not_enough_room
        .addr   str_insert_system_disk
        .addr   str_basic_system_not_found
        ASSERT_ADDRESS_TABLE_SIZE message_table, kNumAlerts

alert_options_table:
        .byte   AlertButtonOptions::OK
        .byte   AlertButtonOptions::OK
        .byte   AlertButtonOptions::OK
        .byte   AlertButtonOptions::OK
        .byte   AlertButtonOptions::TryAgainCancel
        .byte   AlertButtonOptions::OK
        .byte   AlertButtonOptions::OK
        .byte   AlertButtonOptions::OK
        .byte   AlertButtonOptions::TryAgainCancel
        .byte   AlertButtonOptions::OK
        ASSERT_TABLE_SIZE alert_options_table, kNumAlerts

.params alert_params
text:           .addr   0
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams

start:  bit     app::invoked_during_boot_flag ; if no UI, just return cancel
    IF NS
        RETURN  A=#kAlertResultCancel
    END_IF

        ;; --------------------------------------------------
        ;; Process Options, populate `alert_params`

        ;; A = alert

        ;; Search for alert in table, set Y to index
        ldy     #kNumAlerts-1
    DO
        cmp     alert_table,y
        beq     :+
        dey
    WHILE POS
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
        copy8   alert_options_table,y, alert_params::buttons

        ldax    #alert_params
        FALL_THROUGH_TO Alert
.endproc ; AlertById

;;; ============================================================
;;; Display alert
;;; Inputs: A,X=alert_params structure
;;;    { .addr text, .byte AlertButtonOptions, .byte AlertOptions }

        Bell = app::Bell
        SystemTask = app::SystemTaskFromLC
        alert_grafport = app::grafport2
        BTKEntry := app::BTKEntry

        AD_SAVEBG = 1
        .include "../lib/alert_dialog.s"

;;; ============================================================

        ENDSEG SegmentAlert
