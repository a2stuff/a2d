;;; ============================================================
;;; Load settings file (if present), overwriting default settings.
;;;
;;; Assert: ROMIN/ALTZPOFF

.macro DEFINEPROC_LOAD_SETTINGS settings_io_buf, settings_load_buf

.proc LoadSettings
        .assert SETTINGS <> settings_load_buf, error, "Load address must not be SETTINGS"

        jmp     start

        DEFINE_OPEN_PARAMS open_params, str_config, settings_io_buf
        DEFINE_READ_PARAMS read_params, settings_load_buf, .sizeof(DeskTopSettings)
        DEFINE_CLOSE_PARAMS close_params

str_config:
        PASCAL_STRING kFilenameDeskTopConfig

start:
        ;; --------------------------------------------------
        ;; Init machine-specific default settings in case load fails
        ;; (e.g. the file doesn't exist, version mismatch, etc)

        ;; See Apple II Miscellaneous #7: Apple II Family Identification

        ;; IIgs?
        sec                     ; Follow detection protocol
        jsr     IDROUTINE       ; RTS on pre-IIgs
        bcs     :+              ; carry clear = IIgs
        ldxy    #kDefaultDblClickSpeed*4
        jmp     update
:

        ;; IIc Plus?
        lda     ZIDBYTE         ; $00 = IIc or later
        bne     :+
        lda     ZIDBYTE2        ; IIc ROM Version
        cmp     #5
        bne     :+
        ldxy    #kDefaultDblClickSpeed*4
        jmp     update
:

        ;; Laser 128?
        lda     IDBYTELASER128  ; $AC = Laser 128
        cmp     #$AC
        bne     :+
        ldxy    #kDefaultDblClickSpeed*4
:

        ;; Default:
        ldxy    #kDefaultDblClickSpeed

update: stxy    SETTINGS + DeskTopSettings::dblclick_speed

        ;; --------------------------------------------------
        ;; Now try to load the config file, skip on failure

        MLI_CALL OPEN, open_params
        bcs     close
        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        bcs     close

        ;; Check version bytes; ignore on mismatch
        lda     settings_load_buf + DeskTopSettings::version_major
        cmp     #kDeskTopVersionMajor
        bne     close
        lda     settings_load_buf + DeskTopSettings::version_minor
        cmp     #kDeskTopVersionMinor
        bne     close

        ;; Successful - move settings block into place
.if ::SETTINGS >= $C000
        sta     ALTZPON         ; Bank in Aux LC Bank 1
        bit     LCBANK1
        bit     LCBANK1
.endif

        COPY_STRUCT DeskTopSettings, settings_load_buf, SETTINGS

.if ::SETTINGS >= $C000
        sta     ALTZPOFF        ; Bank in Main ZP/LC and ROM
        bit     ROMIN2
.endif

        ;; Finish up
close:  MLI_CALL CLOSE, close_params
        rts

.endproc

.endmacro