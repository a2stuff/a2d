;;; ============================================================
;;; Save/Restore Text Page
;;;
;;; Used in accessories to preserve MGTK caches when operations
;;; might trash the text page (e.g. initializing SSC)
;;; ============================================================

;;; Saves text page (except screen holes)
.proc SaveTextPage
        lda     RD80STORE
        pha
        sta     SET80STORE

        ldx     #0
loop:
        .repeat 8, i
        sta     PAGE2ON
        lda     $400 + (i*$80),x
        sta     _textpage_aux_buf + (i*$78),x
        sta     PAGE2OFF
        lda     $400 + (i*$80),x
        sta     _textpage_main_buf + (i*$78),x
        .endrepeat
        inx
        cpx     #$78
        jne     loop

        pla
        bmi     :+
        sta     CLR80STORE
:       rts
.endproc

;;; Restores text page (except screen holes)
.proc RestoreTextPage
        lda     RD80STORE
        pha
        sta     SET80STORE

        ldx     #0
loop:
        .repeat 8, i
        sta     PAGE2ON
        lda     _textpage_aux_buf + (i*$78),x
        sta     $400 + (i*$80),x
        sta     PAGE2OFF
        lda     _textpage_main_buf + (i*$78),x
        sta     $400 + (i*$80),x
        .endrepeat
        inx
        cpx     #$78
        jne     loop

        pla
        bmi     :+
        sta     CLR80STORE
:       rts
.endproc

_textpage_main_buf:      .res    40*24
_textpage_aux_buf:       .res    40*24
