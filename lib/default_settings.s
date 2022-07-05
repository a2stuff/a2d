;;; ============================================================
;;; Settings

;;; Keep in sync w/ DeskTopSettings definition/offsets

.scope settings
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
        .word   kDefaultDblClickSpeed ; * 1, * 4, or * 16

        ASSERT_ADDRESS settings_start + DeskTopSettings::ip_blink_speed
        .word   kDefaultIPBlinkSpeed ; * 0.5, * 1, or * 2

        ASSERT_ADDRESS settings_start + DeskTopSettings::clock_24hours
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::rgb_color
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::mouse_tracking
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::startup
        .byte   DeskTopSettings::kStartupSkipSelector

        ;; Reserved for future use...

        PAD_TO settings_start + .sizeof(DeskTopSettings)
.endscope
