;;; ============================================================
;;; Settings

.scope settings
        ASSERT_ADDRESS ::SETTINGS

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::version_major
        .byte   kDeskTopVersionMajor
        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::version_minor
        .byte   kDeskTopVersionMinor

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::pattern
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::dblclick_speed
        .word   kDefaultDblClickSpeedInit ; $12C * 1, * 4, or * 32, 0 if not set

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::ip_blink_speed
        .byte   kDefaultIPBlinkSpeed ; 120, 60 or 30; lower is faster

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::clock_24hours
        .byte   0

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::rgb_color
        .byte   0

        ASSERT_ADDRESS ::SETTINGS + DeskTopSettings::mouse_tracking
        .byte   0

        ;; Reserved for future use...

        PAD_TO ::SETTINGS + .sizeof(DeskTopSettings)
.endscope
