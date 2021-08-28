;;; ============================================================
;;; Settings

;;; Keep in sync w/ DeskTopSettings definition/offsets

.scope settings
        settings_start := *

        ASSERT_ADDRESS settings_start + DeskTopSettings::version_major
        .byte   kDeskTopVersionMajor
        ASSERT_ADDRESS settings_start + DeskTopSettings::version_minor
        .byte   kDeskTopVersionMinor

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
        .word   kDefaultDblClickSpeed ; $12C * 1, * 4, or * 16

        ASSERT_ADDRESS settings_start + DeskTopSettings::ip_blink_speed
        .byte   kDefaultIPBlinkSpeed ; 120, 60 or 30; lower is faster

        ASSERT_ADDRESS settings_start + DeskTopSettings::clock_24hours
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::rgb_color
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::mouse_tracking
        .byte   0

        ASSERT_ADDRESS settings_start + DeskTopSettings::startup
        .byte   0

        ;; Reserved for future use...

        PAD_TO settings_start + .sizeof(DeskTopSettings)
.endscope
