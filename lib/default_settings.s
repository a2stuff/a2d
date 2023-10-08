;;; ============================================================
;;; Default Settings
;;;
;;; Keep in sync w/ DeskTopSettings definition/offsets
;;; ============================================================

.proc DefaultSettings
        settings_start := *

        ASSERT_ADDRESS settings_start + DeskTopSettings::pattern
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

        ASSERT_ADDRESS settings_start + DeskTopSettings::dblclick_speed
        .word   kDefaultDblClickSpeed * 4 ; * 1, * 4, or * 16

        ASSERT_ADDRESS settings_start + DeskTopSettings::caret_blink_speed
        .word   kDefaultCaretBlinkSpeed ; * 0.5, * 1, or * 2

        ASSERT_ADDRESS settings_start + DeskTopSettings::clock_24hours
        .byte   res_const_clock_format ; $80 = 24-hour

        ASSERT_ADDRESS settings_start + DeskTopSettings::rgb_color
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::mouse_tracking
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::options
        .byte   DeskTopSettings::kOptionsSkipSelector

        ASSERT_ADDRESS settings_start + DeskTopSettings::intl_date_sep
        .byte   res_char_date_separator

        ASSERT_ADDRESS settings_start + DeskTopSettings::intl_time_sep
        .byte   res_char_time_separator

        ASSERT_ADDRESS settings_start + DeskTopSettings::intl_thou_sep
        .byte   res_char_thousands_separator

        ASSERT_ADDRESS settings_start + DeskTopSettings::intl_deci_sep
        .byte   res_char_decimal_separator

        ASSERT_ADDRESS settings_start + DeskTopSettings::intl_date_order
        .byte   res_const_date_order

        ;; Reserved for future use...

        PAD_TO settings_start + .sizeof(DeskTopSettings)
.endproc ; DefaultSettings
