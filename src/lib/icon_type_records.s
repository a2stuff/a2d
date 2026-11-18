        ;; Types where suffix shouldn't override other metadata
        DEFINE_ICTRECORD $FF, FT_DIRECTORY, ICT_FLAGS_AUX, $8000, 0, IconType::system_folder ; $0F
        DEFINE_ICTRECORD $FF, FT_DIRECTORY, ICT_FLAGS_NONE, 0, 0, IconType::folder        ; $0F

        ;; Types entirely defined by file suffix
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_shk_suffix, 0, IconType::archive ; NuFX
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bny_suffix, 0, IconType::archive ; Binary II
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bxy_suffix, 0, IconType::archive ; NuFX in Binary II
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2fc_suffix, 0, IconType::graphics ; Apple II Full Color
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2fm_suffix, 0, IconType::graphics ; Apple II Full Monochrome
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2lc_suffix, 0, IconType::graphics ; Apple II Low Color
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_a2hr_suffix, 0, IconType::graphics ; Apple II High Resolution
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bsc_suffix, 0, IconType::encoded ; BinSCII
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_bsq_suffix, 0, IconType::encoded ; BinSCII - ShrinkIt
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_btc_suffix, 0, IconType::audio ; Binary Time Constant Audio
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_zc_suffix, 0, IconType::audio ; Zero-Crossing Audio
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_pt3_suffix, 0, IconType::tracker ; Vortex Tracker PT3
        DEFINE_ICTRECORD 0, 0, ICT_FLAGS_SUFFIX, str_ch8_suffix, 0, IconType::chip8 ; CHIP-8

        ;; Binary files ($06) identified as graphics (hi-res, double hi-res, minipix)
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $2000, 17, IconType::graphics ; HR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $4000, 17, IconType::graphics ; HR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $2000, 33, IconType::graphics ; DHR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $4000, 33, IconType::graphics ; DHR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $4800, 3,  IconType::graphics ; Print Shop 88x52 Mono as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $5800, 3,  IconType::graphics ; Print Shop 88x52 Mono as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $6800, 3,  IconType::graphics ; Print Shop 88x52 Mono as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $7800, 3,  IconType::graphics ; Print Shop 88x52 Mono as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $400, 3,  IconType::graphics ; LR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX|ICT_FLAGS_BLOCKS, $400, 5,  IconType::graphics ; DLR image as FOT
        DEFINE_ICTRECORD $FF, FT_BINARY, ICT_FLAGS_AUX, $60FF, 0, IconType::graphics ; AXE PACKER image as FOT

        ;; Simple Mappings
        DEFINE_ICTRECORD $FF, FT_TEXT,      ICT_FLAGS_NONE, 0, 0, IconType::text          ; $04
        DEFINE_ICTRECORD $FF, FT_BINARY,    ICT_FLAGS_NONE, 0, 0, IconType::binary        ; $06
        DEFINE_ICTRECORD $FF, FT_FONT,      ICT_FLAGS_NONE, 0, 0, IconType::font          ; $07
        DEFINE_ICTRECORD $FF, FT_GRAPHICS,  ICT_FLAGS_NONE, 0, 0, IconType::graphics      ; $08

        DEFINE_ICTRECORD $FF, FT_ADB,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_db ; $19
        DEFINE_ICTRECORD $FF, FT_AWP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_wp ; $1A
        DEFINE_ICTRECORD $FF, FT_ASP,       ICT_FLAGS_NONE, 0, 0, IconType::appleworks_sp ; $1B

        DEFINE_ICTRECORD $FF, FT_CMD,       ICT_FLAGS_NONE, 0, 0, IconType::command       ; $F0
        DEFINE_ICTRECORD $FF, FT_INT,       ICT_FLAGS_NONE, 0, 0, IconType::intbasic      ; $FA
        DEFINE_ICTRECORD $FF, FT_IVR,       ICT_FLAGS_NONE, 0, 0, IconType::variables     ; $FB
        DEFINE_ICTRECORD $FF, FT_BASIC,     ICT_FLAGS_NONE, 0, 0, IconType::basic         ; $FC
        DEFINE_ICTRECORD $FF, FT_VAR,       ICT_FLAGS_NONE, 0, 0, IconType::variables     ; $FD
        DEFINE_ICTRECORD $FF, FT_REL,       ICT_FLAGS_NONE, 0, 0, IconType::relocatable   ; $FE
        DEFINE_ICTRECORD $FF, FT_SYSTEM,    ICT_FLAGS_SUFFIX, str_sys_suffix, 0, IconType::application ; $FF
        DEFINE_ICTRECORD $FF, FT_SYSTEM,    ICT_FLAGS_NONE, 0, 0, IconType::system        ; $FF

        DEFINE_ICTRECORD $FF, FT_ANIMATION, ICT_FLAGS_NONE, 0, 0, IconType::animation     ; $5B ANM
        DEFINE_ICTRECORD $FF, FT_SOUND,     ICT_FLAGS_NONE, 0, 0, IconType::audio         ; $D8 SND
        DEFINE_ICTRECORD $FF, FT_MUSIC,     ICT_FLAGS_NONE, 0, 0, IconType::music         ; $D5 MUS
        DEFINE_ICTRECORD $FF, FT_ARCHIVE,   ICT_FLAGS_AUX, $8002, 0, IconType::archive    ; NuFX
        DEFINE_ICTRECORD $FF, FT_LINK,      ICT_FLAGS_AUX, kLinkFileAuxType, 0, IconType::link ; $E1 LNK
        DEFINE_ICTRECORD $FF, FT_SPEECH,    ICT_FLAGS_AUX, $0001, 0, IconType::speech     ; $D9 Speech
        DEFINE_ICTRECORD $FF, FT_ENTERTAINMENT, ICT_FLAGS_AUXMASK, $C800, $FF00, IconType::chip8 ; CHIP-8

        ;; IIgs-Specific Files (ranges)
        DEFINE_ICTRECORD $F0, $50,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs General  $5x
        DEFINE_ICTRECORD $F0, $A0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs BASIC    $Ax
        DEFINE_ICTRECORD $FF, FT_S16, ICT_FLAGS_NONE, 0, 0, IconType::application ; IIgs System   $B3
        DEFINE_ICTRECORD $F0, $B0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs System   $Bx
        DEFINE_ICTRECORD $FF, FT_PNT, ICT_FLAGS_AUX, $0001, 0, IconType::graphics ; IIgs Pkd SHR  $C0
        DEFINE_ICTRECORD $FF, FT_PIC, ICT_FLAGS_AUX, $0000, 0, IconType::graphics ; IIgs SHR      $C1
        DEFINE_ICTRECORD $F0, $C0,    ICT_FLAGS_NONE, 0, 0, IconType::iigs        ; IIgs Graphics $Cx

        ;; Desk Accessories/Applets $F1/$0642 and $F1/$8642
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType, 0, IconType::desk_accessory
        DEFINE_ICTRECORD $FF, kDAFileType,  ICT_FLAGS_AUX, kDAFileAuxType|$8000, 0, IconType::desk_accessory
        .byte   kICTSentinel
