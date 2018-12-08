;;; ============================================================
;;; Overlay for Disk Copy - $0800 - $09FF (file 1/4)
;;; ============================================================

.proc disk_copy_overlay
        .org $800

        jmp     start

        load_target := $1800

;;; ============================================================
;;; Menu - relocated up ot $D400

        menu_target := $D400

.proc menu_bar
        DEFINE_MENU_BAR 1
        DEFINE_MENU_BAR_ITEM 1, menu_target + (menu_label - menu_bar), menu_target + (menu - menu_bar)

menu:   DEFINE_MENU 1
        DEFINE_MENU_ITEM menu_target + (item_label - menu_bar)

menu_label:
        PASCAL_STRING .sprintf("       Disk copy version %d.%d   ",::VERSION_MAJOR,::VERSION_MINOR)
item_label:
        PASCAL_STRING "Rien"
.endproc

;;; ============================================================

        DEFINE_OPEN_PARAMS open_params, str_desktop2, $1C00
        DEFINE_SET_MARK_PARAMS set_mark_params, $131E0
        DEFINE_READ_PARAMS read_params, load_target, $200
        DEFINE_CLOSE_PARAMS close_params

str_desktop2:
        PASCAL_STRING "DeskTop2"

;;; ============================================================

        ptr := $6

start:  lda     #$80
        sta     ptr
        DESKTOP_RELAY_CALL DT_UNHIGHLIGHT_ALL
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

        ;; Open self (DESKTOP2)
        yax_call MLI_RELAY, OPEN, open_params

        ;; Slurp in yet another overlay...
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num

        yax_call MLI_RELAY, SET_MARK, set_mark_params
        yax_call MLI_RELAY, READ, read_params
        yax_call MLI_RELAY, CLOSE, close_params

        ;; And invoke it.
        sta     ALTZPOFF
        lda     ROMIN2
        jmp     load_target

;;; ============================================================

.proc MLI_RELAY
        sty     call
        sta     params
        stx     params+1
        php
        sei
        sta     ALTZPOFF
        lda     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
self:   bne     self            ; hang on error?
        rts
.endproc

;;; ============================================================

        PAD_TO $A00

.endproc ; disk_copy_overlay