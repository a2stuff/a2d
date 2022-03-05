;;; ============================================================
;;; Overlay for Disk Copy - $0800 - $09FF (file 1/4)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.scope part1
        .org $800

        MLIEntry  := MLI
        MGTKEntry := MGTKRelayImpl ; in LC, temporarily left over from DeskTop
        ITKEntry  := ITKRelayImpl ; in LC, temporarily left over from DeskTop

        jmp     start

;;; ============================================================

        DEFINE_OPEN_PARAMS open_params, str_desktop2, $1C00
        DEFINE_SET_MARK_PARAMS set_mark_params, kOverlayDiskCopy2Offset
        DEFINE_READ_PARAMS read_params, kOverlayDiskCopy2Address, kOverlayDiskCopy2Length
        DEFINE_CLOSE_PARAMS close_params

str_desktop2:
        PASCAL_STRING kFilenameDeskTop

;;; ============================================================

        ptr := $6

start:  lda     #$80
        sta     ptr
        ITK_CALL IconTK::RemoveAll, 0 ; volume icons
        MGTK_CALL MGTK::CloseAll
        MGTK_CALL MGTK::SetZP1, ptr

        ;; Clear most of the system bitmap
        ldx     #BITMAP_SIZE - 3
        lda     #0
:       sta     BITMAP+1,x
        dex
        bpl     :-

        ;; Set up banks for ProDOS usage
        sta     ALTZPOFF
        bit     ROMIN2

        ;; Open self (DESKTOP2)
        MLI_CALL OPEN, open_params

        ;; Slurp in yet another overlay...
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num

        MLI_CALL SET_MARK, set_mark_params
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params

        jmp     kOverlayDiskCopy2Address

;;; ============================================================

        PAD_TO $A00

.endscope ; part1