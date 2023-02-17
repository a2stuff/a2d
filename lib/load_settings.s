;;; ============================================================
;;; Load settings and alert sound (if present; otherwise default)
;;; and install in the ProDOS QUIT code area in Main/LCBank2.
;;;
;;; Required:
;;; * `SETTINGS_IO_BUF` - 1k ProDOS I/O buffer for the load
;;; Assert: Called with ROMIN/ALTZPOFF
;;; ============================================================

.proc LoadSettings
        jmp     start

        DEFINE_OPEN_PARAMS open_cfg_params, str_config, SETTINGS_IO_BUF
        DEFINE_READ_PARAMS read_cfg_params, SETTINGS_LOAD_ADDR, kDeskTopSettingsFileSize

        DEFINE_OPEN_PARAMS open_snd_params, str_sound, SETTINGS_IO_BUF
        DEFINE_READ_PARAMS read_snd_params, DefaultBell, kBellProcLength

        DEFINE_CLOSE_PARAMS close_params

str_config:
        PASCAL_STRING kPathnameDeskTopConfig

str_sound:
        PASCAL_STRING kPathnameBellProc

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

update: stxy    DefaultSettings + DeskTopSettings::dblclick_speed

        ;; --------------------------------------------------
        ;; Now try to load the config file, skip on failure

        MLI_CALL OPEN, open_cfg_params
        bcs     close1
        lda     open_cfg_params::ref_num
        sta     read_cfg_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_cfg_params
        bcs     close1

        ;; Check version byte; ignore on mismatch
        lda     version_byte
        cmp     #kDeskTopSettingsFileVersion
        bne     close1

        ;; Successful - move settings block into place
        bit     LCBANK2
        bit     LCBANK2

        COPY_STRUCT DeskTopSettings, DefaultSettings, SETTINGS

        bit     ROMIN2

        ;; Finish up
close1: MLI_CALL CLOSE, close_params

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
        bit     LCBANK2
        bit     LCBANK2

        COPY_BYTES kBellProcLength, DefaultBell, BELLDATA

        bit     ROMIN2

        ;; Finish up
close2:  MLI_CALL CLOSE, close_params

        ;; --------------------------------------------------

        rts

;;; ============================================================

        .include "../lib/default_sound.s"

        SETTINGS_LOAD_ADDR := *
version_byte:   .byte   0
        .include "../lib/default_settings.s"
        .assert * - SETTINGS_LOAD_ADDR = kDeskTopSettingsFileSize, error, "size mismatch"

.endproc ; LoadSettings
