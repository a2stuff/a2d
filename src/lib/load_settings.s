;;; ============================================================
;;; Load settings and alert sound (if present; otherwise default)
;;; and install in the ProDOS QUIT code area in Main/LCBank2.
;;;
;;; Required:
;;; * `SETTINGS_IO_BUF` - 1k ProDOS I/O buffer for the load
;;; Assert: Called with ROMIN/ALTZPOFF
;;; ============================================================

.scope load_settings_impl
        DEFINE_OPEN_PARAMS open_cfg_params, str_config, SETTINGS_IO_BUF
        DEFINE_READWRITE_PARAMS read_cfgver_params, version_byte, 1
        DEFINE_READWRITE_PARAMS read_cfg_params, DefaultSettings, .sizeof(DeskTopSettings)

        DEFINE_OPEN_PARAMS open_snd_params, str_sound, SETTINGS_IO_BUF
        DEFINE_READWRITE_PARAMS read_snd_params, DefaultBell, kBellProcLength

        DEFINE_CLOSE_PARAMS close_params

str_config:
        PASCAL_STRING kPathnameDeskTopConfig

str_sound:
        PASCAL_STRING kPathnameBellProc

version_byte:
        .byte   0

LoadSettings:
        ;; --------------------------------------------------
        ;; Init machine-specific default settings in case load fails
        ;; (e.g. the file doesn't exist, version mismatch, etc)

        ;; See Apple II Miscellaneous #7: Apple II Family Identification

        ;; IIgs?
        CALL    IDROUTINE, C=1  ; Follow detection protocol

        ldxy    #kDefaultDblClickSpeed*4
        bcc     update          ; carry clear = IIgs

        ;; IIc Plus?
        lda     ZIDBYTE         ; $00 = IIc or later
    IF ZERO
        lda     ZIDBYTE2        ; IIc ROM Version
        cmp     #5
        beq     update          ; 4x speed
    END_IF

        ;; Laser 128?
        lda     IDBYTELASER128  ; $AC = Laser 128
        cmp     #$AC
        beq     update          ; 4x speed

        ;; Default:
        ldxy    #kDefaultDblClickSpeed

update: stxy    DefaultSettings + DeskTopSettings::dblclick_speed

        ;; --------------------------------------------------
        ;; Now try to load the config file
.scope
        MLI_CALL OPEN, open_cfg_params
        bcs     skip            ; failed - use defaults
        lda     open_cfg_params::ref_num
        sta     read_cfgver_params::ref_num
        sta     read_cfg_params::ref_num
        sta     close_params::ref_num

        MLI_CALL READ, read_cfgver_params
        bcs     close           ; failed - use defaults

        ;; Check version byte; ignore on mismatch
        lda     version_byte
        cmp     #kDeskTopSettingsFileVersion
        bne     close           ; mismatch - use defaults

        ;; Version byte is fine - read the rest of the file
        MLI_CALL READ, read_cfg_params

close:  MLI_CALL CLOSE, close_params
skip:
.endscope

        ;; --------------------------------------------------
        ;; Move settings block into place
        bit     LCBANK2
        bit     LCBANK2

        COPY_STRUCT DeskTopSettings, DefaultSettings, SETTINGS

        bit     ROMIN2

        ;; --------------------------------------------------
        ;; Now try to load the sound file
.scope
        MLI_CALL OPEN, open_snd_params
        bcs     close           ; failed - use defaults
        lda     open_snd_params::ref_num
        sta     read_snd_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_snd_params

close:  MLI_CALL CLOSE, close_params
.endscope

        ;; --------------------------------------------------
        ;; Move bell data block into place

        bit     LCBANK2
        bit     LCBANK2
        COPY_BYTES kBellProcLength, DefaultBell, BELLDATA
        bit     ROMIN2

        rts

;;; ============================================================

        .include "../lib/default_sound.s"
        .include "../lib/default_settings.s"

.endscope ; load_settings_impl

;;; Exports
LoadSettings    := load_settings_impl::LoadSettings
