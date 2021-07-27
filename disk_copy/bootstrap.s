;;; ============================================================
;;; Overlay for Disk Copy - $0800 - $09FF (file 1/4)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc part1
        .org $800

        jmp     start

;;; ============================================================
;;; Menu - relocated up ot $D400

        menu_target := $D400

.params menu_bar
        DEFINE_MENU_BAR 1
        DEFINE_MENU_BAR_ITEM 1, menu_target + (menu_label - menu_bar), menu_target + (menu - menu_bar)

menu:   DEFINE_MENU 1
        DEFINE_MENU_ITEM menu_target + (item_label - menu_bar)

menu_label:
        PASCAL_STRING .sprintf("       Disk Copy Version %d.%d   ",::kDeskTopVersionMajor,::kDeskTopVersionMinor) ; do not localize
item_label:
        PASCAL_STRING "Rien"    ; French for "nothing" - do not localize
.endparams

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
        ITK_RELAY_CALL IconTK::RemoveAll, 0 ; volume icons
        MGTK_RELAY_CALL MGTK::CloseAll
        MGTK_RELAY_CALL MGTK::SetZP1, ptr

        ;; Copy menu bar up to language card, and use it.
        COPY_BYTES .sizeof(menu_bar)+1, menu_bar, $D400
        MGTK_RELAY_CALL MGTK::SetMenu, menu_target

        ;; Clear most of the system bitmap
        ldx     #BITMAP_SIZE - 3
        lda     #0
:       sta     BITMAP+1,x
        dex
        bpl     :-

        ;; Set up banks for ProDOS usage
        sta     ALTZPOFF
        lda     ROMIN2

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

.endproc ; part1