;;; ============================================================
;;; Bootstrap
;;;
;;; Compiled as part of DeskTop and Selector
;;; ============================================================

        .org MODULE_BOOTSTRAP

;;; Install QuitRoutine to the ProDOS QUIT routine
;;; (Main, LCBANK2) and invoke it.

.proc InstallAsQuit
        MLIEntry := MLI

        ;; Patch the current prefix into `QuitRoutine`
        MLI_CALL GET_PREFIX, prefix_params

        ;; Need room for flags in $D280+ range (see common.inc)
        .assert sizeof_QuitRoutine <= kMaxQuitRoutineSize, error, "too large"

        bit     LCBANK2
        bit     LCBANK2

        src := $06
        dst := $08
        copy16  #QuitRoutine, src
        copy16  #SELECTOR, dst
        ldy     #0
    DO
        copy8   (src),y,  (dst),y
        inc16   src
        inc16   dst
        ecmp16  src, #QuitRoutine + sizeof_QuitRoutine
    WHILE NE

        bit     ROMIN2

        MLI_CALL QUIT, quit_params
        DEFINE_QUIT_PARAMS quit_params

        prefix_buffer := ::QuitRoutine + ::QuitRoutine::prefix_buffer_offset
        DEFINE_GET_PREFIX_PARAMS prefix_params, prefix_buffer
.endproc ; InstallAsQuit


;;; New QUIT routine. Gets relocated to $1000 by ProDOS before
;;; being executed.

.proc QuitRoutine
        .org ::SELECTOR_ORG

        MLIEntry := MLI

self:
        ;; ProDOS 8 Technical Reference Manual 5.1.5.2
        ;; "In addition, the $D100 byte must be a CLD ($D8) instruction,
        ;; so that programs can tell whether selector code or the ProDOS
        ;; dispatcher code is resident."
        cld

        ;; --------------------------------------------------
        ;; Show 80-column text screen

        lda     #$FF
        sta     INVFLG
        sta     FW80MODE

        sta     TXTSET
        bit     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80STORE
        jsr     SLOT3ENTRY

        ;; IIgs: Reset shadowing
        CALL    IDROUTINE, C=1
    IF CC
        .pushcpu
        .p816
        .a8
        lda     #%01111111      ; bit 7 is reserved
        trb     SHADOW          ; ensure shadowing is enabled
        lda     #%11100000      ; bits 1-4 are reserved, bit 0 unchanged
        trb     NEWVIDEO        ; color DHR, etc
        .popcpu
    END_IF

        ;; --------------------------------------------------
        ;; Display the loading string
retry:
        jsr     HOME
        CALL    VTABZ, A=#kSplashVtab
        lda     #(80 - kLoadingStringLength)/2
        sta     OURCH

        ldy     #0
    DO
        CALL    COUT, A=str_loading,y
        iny
    WHILE Y <> #kLoadingStringLength

        ;; Close all open files (just in case)
        MLI_CALL CLOSE, close_params

        ;; Initialize system bitmap
        ;; Initialize system bitmap
        ldx     #BITMAP_SIZE-1
        lda     #0
    DO
        sta     BITMAP,x
        dex
    WHILE POS
        copy8   #%00000001, BITMAP+BITMAP_SIZE-1 ; ProDOS global page
        copy8   #%11001111, BITMAP ; ZP, Stack, Text Page 1

        ;; Load the target module's loader at $2000
        MLI_CALL SET_PREFIX, prefix_params
        bcs     prompt_for_system_disk
        MLI_CALL OPEN, open_params
        bcs     _ErrorHandler
        lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params::ref_num
        MLI_CALL SET_MARK, set_mark_params
        bcs     _ErrorHandler
        MLI_CALL READ, read_params
        bcs     _ErrorHandler
        MLI_CALL CLOSE, close_params
        bcs     _ErrorHandler

        ;; Invoke it
        jmp     kSegmentLoaderAddress

;;; ============================================================
;;; Display a string, and wait for Return keypress

prompt_for_system_disk:
        jsr     HOME
        CALL    VTABZ, A=#kSplashVtab
        lda     #(80 - kDiskPromptLength)/2
        sta     OURCH

        ldy     #0
    DO
        CALL    COUT, A=str_disk_prompt,y
        iny
    WHILE Y <> #kDiskPromptLength

wait:
        sta     KBDSTRB
:       lda     KBD
        bpl     :-
        cmp     #CHAR_RETURN | $80
        bne     wait
        jmp     retry

;;; ============================================================
;;; Error Handler

.proc _ErrorHandler
        brk                     ; just crash
.endproc ; _ErrorHandler

;;; ============================================================
;;; Strings

kDiskPromptLength = .strlen(res_string_prompt_insert_system_disk)
str_disk_prompt:
        scrcode res_string_prompt_insert_system_disk

kSplashVtab = 12
kLoadingStringLength = .strlen(QR_LOADSTRING)
str_loading:
        scrcode QR_LOADSTRING

;;; ============================================================
;;; ProDOS MLI call param blocks

        io_buf := $1C00
        .assert io_buf + $400 <= kSegmentLoaderAddress, error, "memory overlap"

        DEFINE_OPEN_PARAMS open_params, filename, io_buf
        DEFINE_SET_MARK_PARAMS set_mark_params, kSegmentLoaderOffset
        DEFINE_READWRITE_PARAMS read_params, kSegmentLoaderAddress, kSegmentLoaderLength
        DEFINE_CLOSE_PARAMS close_params
        DEFINE_SET_PREFIX_PARAMS prefix_params, prefix_buffer

filename:
        PASCAL_STRING QR_FILENAME

;;; ============================================================
;;; Populated before this routine is installed
prefix_buffer:
        .res    64, 0

;;; Updated by DeskTop if parts of the path are renamed.
prefix_buffer_offset := prefix_buffer - self

.endproc ; QuitRoutine
sizeof_QuitRoutine = .sizeof(QuitRoutine)

;;; ============================================================

.assert .sizeof(QuitRoutine) + .sizeof(InstallAsQuit) <= kModuleBootstrapSize, error, "too large"
