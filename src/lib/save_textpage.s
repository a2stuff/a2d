;;; ============================================================
;;; Save/Restore Text Page
;;;
;;; Used in accessories to preserve MGTK caches when operations
;;; might trash the text page (e.g. initializing SSC)
;;; ============================================================

.scope save_textpage_impl

        ptr_screen := $06
        ptr_aux_buf := $08
        ptr_main_buf := $10

        kNumSegments = 8
        kSegmentWidth   = $78
        kSegmentStride  = $80

;;; Saves text page (except screen holes)
.proc SaveTextPage
        lda     RD80STORE
        pha
        sta     SET80STORE

        jsr     InitPointers
        ldx     #kNumSegments-1
    DO
        ldy     #kSegmentWidth-1
      DO
        sta     PAGE2ON
        lda     (ptr_screen),y
        sta     (ptr_aux_buf),y
        sta     PAGE2OFF
        lda     (ptr_screen),y
        sta     (ptr_main_buf),y
      WHILE dey : POS
        jsr     IncPointers
    WHILE dex : POS

        pla
    IF NC
        sta     CLR80STORE
    END_IF
        rts
.endproc ; SaveTextPage

;;; Restores text page (except screen holes)
.proc RestoreTextPage
        lda     RD80STORE
        pha
        sta     SET80STORE

        jsr     InitPointers
        ldx     #kNumSegments-1
    DO
        ldy     #kSegmentWidth-1
      DO
        sta     PAGE2ON
        lda     (ptr_aux_buf),y
        sta     (ptr_screen),y
        sta     PAGE2OFF
        lda     (ptr_main_buf),y
        sta     (ptr_screen),y
      WHILE dey : POS
        jsr     IncPointers
    WHILE dex : POS

        pla
    IF NC
        sta     CLR80STORE
    END_IF
        rts
.endproc ; RestoreTextPage

.proc InitPointers
        copy16  #$400, ptr_screen
        copy16  #textpage_aux_buf, ptr_aux_buf
        copy16  #textpage_main_buf, ptr_main_buf
        rts
.endproc ; InitPointers

.proc IncPointers
        add16_8 ptr_screen, #kSegmentStride
        add16_8 ptr_aux_buf, #kSegmentWidth
        add16_8 ptr_main_buf, #kSegmentWidth
        rts
.endproc ; IncPointers

textpage_main_buf:      .res    24*40
textpage_aux_buf:       .res    24*40

.endscope ; save_textpage_impl

;;; Exports
SaveTextPage := save_textpage_impl::SaveTextPage
RestoreTextPage := save_textpage_impl::RestoreTextPage
