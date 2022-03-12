;;; ============================================================
;;; Load settings file (if present), overwriting default settings.
;;; Required:
;;; * `SETTINGS`
;;; Optional:
;;; * `BELLDATA` - if defined, that will be loaded too.
;;; Assert: ROMIN/ALTZPOFF

.macro DEFINEPROC_LOAD_SETTINGS settings_io_buf, settings_load_buf

.proc LoadSettings
        jmp     start

        .assert ::SETTINGS <> settings_load_buf, error, "Load address must not be SETTINGS"
        DEFINE_OPEN_PARAMS open_cfg_params, str_config, settings_io_buf
        DEFINE_READ_PARAMS read_cfg_params, settings_load_buf, kDeskTopSettingsFileSize

.if .defined(::BELLDATA)
        .assert ::BELLDATA <> settings_load_buf, error, "Load address must not be BELLDATA"
        DEFINE_OPEN_PARAMS open_snd_params, str_sound, settings_io_buf
        DEFINE_READ_PARAMS read_snd_params, settings_load_buf, kBellProcLength
.endif

        DEFINE_CLOSE_PARAMS close_params

str_config:
        PASCAL_STRING kFilenameDeskTopConfig
str_sound:
        PASCAL_STRING kFilenameBellProc

start:
        ;; --------------------------------------------------
        ;; Init machine-specific default settings in case load fails
        ;; (e.g. the file doesn't exist, version mismatch, etc)

        ;; See Apple II Miscellaneous #7: Apple II Family Identification

        ;; IIgs?
        sec                     ; Follow detection protocol
        jsr     IDROUTINE       ; RTS on pre-IIgs

        ldxy    #kDefaultDblClickSpeed*4
        bcc     update          ; carry clear = IIgs

        ;; IIc Plus?
        lda     ZIDBYTE         ; $00 = IIc or later
        bne     :+
        lda     ZIDBYTE2        ; IIc ROM Version
        cmp     #5
        beq     update          ; 4x speed
:

        ;; Laser 128?
        lda     IDBYTELASER128  ; $AC = Laser 128
        cmp     #$AC
        beq     update          ; 4x speed

        ;; Default:
        ldxy    #kDefaultDblClickSpeed

update: stxy    SETTINGS + DeskTopSettings::dblclick_speed

        ;; --------------------------------------------------
        ;; Now try to load the config file, skip on failure

        MLI_CALL OPEN, open_cfg_params
        bcs     close1
        lda     open_cfg_params::ref_num
        sta     read_cfg_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_cfg_params
        bcs     close1

        ;; Check version bytes; ignore on mismatch
        lda     settings_load_buf
        cmp     #kDeskTopSettingsFileVersion
        bne     close1

        ;; Successful - move settings block into place
.if ::SETTINGS >= $C000
        sta     ALTZPON         ; Bank in Aux LC Bank 1
        bit     LCBANK1
        bit     LCBANK1
.endif

        COPY_STRUCT DeskTopSettings, settings_load_buf + kDeskTopSettingsFileOffset, SETTINGS

.if ::SETTINGS >= $C000
        sta     ALTZPOFF        ; Bank in Main ZP/LC and ROM
        bit     ROMIN2
.endif

        ;; Finish up
close1: MLI_CALL CLOSE, close_params


.if .defined(::BELLDATA)
        ;; --------------------------------------------------
        ;; Now try to load the sound file, skip on failure

        MLI_CALL OPEN, open_snd_params
        bcs     close2
        lda     open_snd_params::ref_num
        sta     read_snd_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_snd_params
        bcs     close2

        ;; Successful - move settings block into place
.if ::BELLDATA >= $C000
        sta     ALTZPON         ; Bank in Aux LC Bank 1
        bit     LCBANK1
        bit     LCBANK1
.endif

        COPY_BYTES kBellProcLength, settings_load_buf, BELLDATA

.if ::BELLDATA >= $C000
        sta     ALTZPOFF        ; Bank in Main ZP/LC and ROM
        bit     ROMIN2
.endif

        ;; Finish up
close2:  MLI_CALL CLOSE, close_params

        ;; --------------------------------------------------
.endif

        rts

.endproc

.endmacro