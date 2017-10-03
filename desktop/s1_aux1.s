        .org $4000
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../desk.acc/a2d.inc"


L0000           := $0000
L0082           := $0082
L0083           := $0083
L0088           := $0088
L00C7           := $00C7
LD05E           := $D05E
LD2D0           := $D2D0

;; A2D
        lda     $C054
        sta     $C001
        bit     L5F1B
        bpl     L4022
        ldx     #$7F
L400D:  lda     $80,x
        sta     L5F72,x
        dex
        bpl     L400D
        ldx     #$0B
L4017:  lda     L5F66,x
        sta     $F4,x
        dex
        bpl     L4017
        jsr     L40BD
L4022:  pla
        sta     $80
        clc
        adc     #$03
        tax
        pla
        sta     $81
        adc     #$00
        pha
        txa
        pha
        tsx
        stx     L5F1D
        ldy     #$01
        lda     ($80),y
        asl     a
        tax
        lda     a2d_jump_table,x
        sta     jump+1
        lda     a2d_jump_table+1,x
        sta     jump+2
        iny
        lda     ($80),y
        pha
        iny
        lda     ($80),y
        sta     $81
        pla
        sta     $80
        ldy     param_lengths+1,x
        bpl     L4076
        txa
        pha
        tya
        pha
        lda     $80
        pha
        lda     $81
        pha
        bit     L633F
        bpl     L406A
        jsr     L40D4
L406A:  pla
        sta     $81
        pla
        sta     $80
        pla
        and     #$7F
        tay
        pla
        tax
L4076:  lda     param_lengths,x
        beq     jump
        sta     L4082
        dey
L407F:  lda     ($80),y
L4082           := * + 1
        sta     $FF,y
        dey
        bpl     L407F
jump:   jsr     $FFFF
L408A:  bit     L633F
        bpl     L4092
        jsr     L40DA
L4092:  bit     L5F1B
        bpl     L40AE
        jsr     L40C8
        ldx     #$0B
L409C:  lda     $F4,x
        sta     L5F66,x
        dex
        bpl     L409C
        ldx     #$7F
L40A6:  lda     L5F72,x
        sta     $80,x
        dex
        bpl     L40A6
L40AE:  lda     #$00
jt_rts: rts

L40B1:  pha
        jsr     L408A
        pla
        ldx     L5F1D
        txs
        ldy     #$FF
L40BC:  rts

L40BD:  ldy     #$23
L40BF:  lda     ($F4),y
        sta     $D0,y
        dey
        bpl     L40BF
        rts

L40C8:  ldy     #$23
L40CA:  lda     $D0,y
        sta     ($F4),y
        dey
        bpl     L40CA
        rts

L40D3:  .byte   0
L40D4:  dec     L40D3
        jmp     HIDE_CURSOR_IMPL

L40DA:  bit     L40D3
        bpl     L40BC
        inc     L40D3
        jmp     SHOW_CURSOR_IMPL

        ;; Jump table for A2D entry point calls
a2d_jump_table:
        .addr   jt_rts              ; $00
        .addr   L5E51               ; $01
        .addr   L5E7B               ; $02
        .addr   QUERY_SCREEN_IMPL   ; $03 QUERY_SCREEN
        .addr   SET_STATE_IMPL      ; $04 SET_STATE
        .addr   L5EB4               ; $05
        .addr   SET_BOX_IMPL        ; $06 SET_BOX
        .addr   SET_FILL_MODE_IMPL  ; $07 SET_FILL_MODE
        .addr   SET_PATTERN_IMPL    ; $08 SET_PATTERN
        .addr   jt_rts              ; $09
        .addr   jt_rts              ; $0A SET_THICKNESS  ???
        .addr   L586A               ; $0B
        .addr   jt_rts              ; $0C SET_TEXT_MASK  ???
        .addr   L5742               ; $0D
        .addr   jt_rts              ; $0E SET_POS        ???
        .addr   DRAW_LINE_IMPL      ; $0F DRAW_LINE
        .addr   L5776               ; $10
        .addr   FILL_RECT_IMPL      ; $11 FILL_RECT
        .addr   DRAW_RECT_IMPL      ; $12 DRAW_RECT
        .addr   TEST_BOX_IMPL       ; $13 TEST_BOX
        .addr   DRAW_BITMAP_IMPL    ; $14 DRAW_BITMAP
        .addr   L537E               ; $15
        .addr   L56D6               ; $16
        .addr   L537A               ; $17
        .addr   MEASURE_TEXT_IMPL   ; $18 MEASURE_TEXT
        .addr   DRAW_TEXT_IMPL      ; $19 DRAW_TEXT
        .addr   CONFIGURE_ZP_IMPL   ; $1A CONFIGURE_ZP_USE
        .addr   L5EDE               ; $1B
        .addr   L5F0A               ; $1C
        .addr   L6341               ; $1D
        .addr   L64A5               ; $1E
        .addr   L64D2               ; $1F
        .addr   L65B3               ; $20
        .addr   L8427               ; $21
        .addr   L7D61               ; $22
        .addr   L6747               ; $23
        .addr   SET_CURSOR_IMPL     ; $24 SET_CURSOR
        .addr   SHOW_CURSOR_IMPL    ; $25 SHOW_CURSOR
        .addr   HIDE_CURSOR_IMPL    ; $26 HIDE_CURSOR
        .addr   L624E               ; $27
        .addr   L630A               ; $28
        .addr   L6663               ; $29
        .addr   GET_INPUT_IMPL      ; $2A GET_INPUT
        .addr   L67D8               ; $2B
        .addr   L65D4               ; $2C
        .addr   SET_INPUT_IMPL      ; $2D SET_INPUT
        .addr   L6814               ; $2E
        .addr   L6ECD               ; $2F
        .addr   L6926               ; $30
        .addr   L6BDB               ; $31
        .addr   L6B60               ; $32
        .addr   L6B1D               ; $33
        .addr   L6BCB               ; $34
        .addr   L6BA9               ; $35
        .addr   L6BB5               ; $36
        .addr   L6F1C               ; $37
        .addr   CREATE_WINDOW_IMPL  ; $38 CREATE_WINDOW
        .addr   DESTROY_WINDOW_IMPL ; $39 DESTROY_WINDOW
        .addr   L7836               ; $3A
        .addr   L7500               ; $3B
        .addr   QUERY_STATE_IMPL    ; $3C QUERY_STATE
        .addr   L761F               ; $3D
        .addr   L7532               ; $3E
        .addr   L758C               ; $3F
        .addr   QUERY_TARGET_IMPL   ; $40 QUERY_TARGET
        .addr   L7639               ; $41
        .addr   L74AC               ; $42
        .addr   CLOSE_CLICK_IMPL    ; $43 CLOSE_CLICK
        .addr   DRAG_WINDOW_IMPL    ; $44 DRAG_WINDOW
        .addr   DRAG_RESIZE_IMPL    ; $45 DRAG_RESIZE
        .addr   MAP_COORDS_IMPL     ; $46 MAP_COORDS
        .addr   L78E1               ; $47
        .addr   QUERY_CLIENT_IMPL   ; $48 QUERY_CLIENT
        .addr   RESIZE_WINDOW_IMPL  ; $49 RESIZE_WINDOW
        .addr   DRAG_SCROLL_IMPL    ; $4A DRAG_SCROLL
        .addr   UPDATE_SCROLL_IMPL  ; $4B UPDATE_SCROLL
        .addr   L7965               ; $4C
        .addr   L51B3               ; $4D
        .addr   L7D69               ; $4E

        ;; Entry point param lengths
param_lengths:
        .byte   $00
        .byte   $00,$00,$00,$82,$01,$00,$00,$D0
        .byte   $24,$00,$00,$D0,$10,$F0,$01,$E0
        .byte   $08,$E8,$02,$EE,$02,$00,$00,$F1
        .byte   $01,$A1,$04,$EA,$04,$A1,$84,$92
        .byte   $84,$92,$88,$9F,$88,$92,$08,$8A
        .byte   $10,$00,$80,$00,$80,$00,$00,$A1
        .byte   $03,$A1,$83,$82,$01,$82,$01,$00
        .byte   $00,$82,$0C,$00,$00,$82,$03,$82
        .byte   $02,$82,$02,$82,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$82,$05,$82,$01,$82,$04,$00
        .byte   $00,$00,$00,$C7,$04,$C7,$01,$C7
        .byte   $02,$C7,$03,$C7,$03,$C7,$04,$00
        .byte   $00,$82,$01,$00,$00,$82,$01,$82
        .byte   $03,$82,$02,$82,$01,$82,$01,$EA
        .byte   $04,$00,$00,$82,$01,$00,$00,$82
        .byte   $05,$82,$05,$82,$05,$82,$05,$EA
        .byte   $04,$82,$03,$82,$05,$8C,$03,$8C
        .byte   $02,$8A,$10,$82,$02

L4221:  .byte   $00,$02,$04,$06,$08,$0A,$0C,$0E
        .byte   $10,$12,$14,$16,$18,$1A,$1C,$1E
        .byte   $20,$22,$24,$26,$28,$2A,$2C,$2E
        .byte   $30,$32,$34,$36,$38,$3A,$3C,$3E
        .byte   $40,$42,$44,$46,$48,$4A,$4C,$4E
        .byte   $50,$52,$54,$56,$58,$5A,$5C,$5E
        .byte   $60,$62,$64,$66,$68,$6A,$6C,$6E
        .byte   $70,$72,$74,$76,$78,$7A,$7C,$7E
        .byte   $00,$02,$04,$06,$08,$0A,$0C,$0E
        .byte   $10,$12,$14,$16,$18,$1A,$1C,$1E
        .byte   $20,$22,$24,$26,$28,$2A,$2C,$2E
        .byte   $30,$32,$34,$36,$38,$3A,$3C,$3E
        .byte   $40,$42,$44,$46,$48,$4A,$4C,$4E
        .byte   $50,$52,$54,$56,$58,$5A,$5C,$5E
        .byte   $60,$62,$64,$66,$68,$6A,$6C,$6E
        .byte   $70,$72,$74,$76,$78,$7A,$7C,$7E
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $20,$24,$28,$2C,$30,$34,$38,$3C
        .byte   $40,$44,$48,$4C,$50,$54,$58,$5C
        .byte   $60,$64,$68,$6C,$70,$74,$78,$7C
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $20,$24,$28,$2C,$30,$34,$38,$3C
        .byte   $40,$44,$48,$4C,$50,$54,$58,$5C
        .byte   $60,$64,$68,$6C,$70,$74,$78,$7C
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $20,$24,$28,$2C,$30,$34,$38,$3C
        .byte   $40,$44,$48,$4C,$50,$54,$58,$5C
        .byte   $60,$64,$68,$6C,$70,$74,$78,$7C
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $20,$24,$28,$2C,$30,$34,$38,$3C
        .byte   $40,$44,$48,$4C,$50,$54,$58,$5C
        .byte   $60,$64,$68,$6C,$70,$74,$78,$7C
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$08,$10,$18,$20,$28,$30,$38
        .byte   $40,$48,$50,$58,$60,$68,$70,$78
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $04,$04,$04,$04,$04,$04,$04,$04
        .byte   $04,$04,$04,$04,$04,$04,$04,$04
        .byte   $05,$05,$05,$05,$05,$05,$05,$05
        .byte   $05,$05,$05,$05,$05,$05,$05,$05
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$10,$20,$30,$40,$50,$60,$70
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $04,$04,$04,$04,$04,$04,$04,$04
        .byte   $05,$05,$05,$05,$05,$05,$05,$05
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $08,$08,$08,$08,$08,$08,$08,$08
        .byte   $09,$09,$09,$09,$09,$09,$09,$09
        .byte   $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
        .byte   $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
        .byte   $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$20,$40,$60,$00,$20,$40,$60
        .byte   $00,$00,$00,$00,$01,$01,$01,$01
        .byte   $02,$02,$02,$02,$03,$03,$03,$03
        .byte   $04,$04,$04,$04,$05,$05,$05,$05
        .byte   $06,$06,$06,$06,$07,$07,$07,$07
        .byte   $08,$08,$08,$08,$09,$09,$09,$09
        .byte   $0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B
        .byte   $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D
        .byte   $0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F
        .byte   $10,$10,$10,$10,$11,$11,$11,$11
        .byte   $12,$12,$12,$12,$13,$13,$13,$13
        .byte   $14,$14,$14,$14,$15,$15,$15,$15
        .byte   $16,$16,$16,$16,$17,$17,$17,$17
        .byte   $18,$18,$18,$18,$19,$19,$19,$19
        .byte   $1A,$1A,$1A,$1A,$1B,$1B,$1B,$1B
        .byte   $1C,$1C,$1C,$1C,$1D,$1D,$1D,$1D
        .byte   $1E,$1E,$1E,$1E,$1F,$1F,$1F,$1F
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$40,$00,$40,$00,$40,$00,$40
        .byte   $00,$00,$01,$01,$02,$02,$03,$03
        .byte   $04,$04,$05,$05,$06,$06,$07,$07
        .byte   $08,$08,$09,$09,$0A,$0A,$0B,$0B
        .byte   $0C,$0C,$0D,$0D,$0E,$0E,$0F,$0F
        .byte   $10,$10,$11,$11,$12,$12,$13,$13
        .byte   $14,$14,$15,$15,$16,$16,$17,$17
        .byte   $18,$18,$19,$19,$1A,$1A,$1B,$1B
        .byte   $1C,$1C,$1D,$1D,$1E,$1E,$1F,$1F
        .byte   $20,$20,$21,$21,$22,$22,$23,$23
        .byte   $24,$24,$25,$25,$26,$26,$27,$27
        .byte   $28,$28,$29,$29,$2A,$2A,$2B,$2B
        .byte   $2C,$2C,$2D,$2D,$2E,$2E,$2F,$2F
        .byte   $30,$30,$31,$31,$32,$32,$33,$33
        .byte   $34,$34,$35,$35,$36,$36,$37,$37
        .byte   $38,$38,$39,$39,$3A,$3A,$3B,$3B
        .byte   $3C,$3C,$3D,$3D,$3E,$3E,$3F,$3F
L4821:  .byte   $00,$00,$00,$00
L4825:  .byte   $00,$00,$00
L4828:  .byte   $01,$01,$01,$01,$01,$01,$01,$02
        .byte   $02,$02,$02,$02,$02,$02,$03,$03
        .byte   $03,$03,$03,$03,$03,$04,$04,$04
        .byte   $04,$04,$04,$04,$05,$05,$05,$05
        .byte   $05,$05,$05,$06,$06,$06,$06,$06
        .byte   $06,$06,$07,$07,$07,$07,$07,$07
        .byte   $07,$08,$08,$08,$08,$08,$08,$08
        .byte   $09,$09,$09,$09,$09,$09,$09,$0A
        .byte   $0A,$0A,$0A,$0A,$0A,$0A,$0B,$0B
        .byte   $0B,$0B,$0B,$0B,$0B,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D
        .byte   $0D,$0D,$0D,$0E,$0E,$0E,$0E,$0E
        .byte   $0E,$0E,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$10,$10,$10,$10,$10,$10,$10
        .byte   $11,$11,$11,$11,$11,$11,$11,$12
        .byte   $12,$12,$12,$12,$12,$12,$13,$13
        .byte   $13,$13,$13,$13,$13,$14,$14,$14
        .byte   $14,$14,$14,$14,$15,$15,$15,$15
        .byte   $15,$15,$15,$16,$16,$16,$16,$16
        .byte   $16,$16,$17,$17,$17,$17,$17,$17
        .byte   $17,$18,$18,$18,$18,$18,$18,$18
        .byte   $19,$19,$19,$19,$19,$19,$19,$1A
        .byte   $1A,$1A,$1A,$1A,$1A,$1A,$1B,$1B
        .byte   $1B,$1B,$1B,$1B,$1B,$1C,$1C,$1C
        .byte   $1C,$1C,$1C,$1C,$1D,$1D,$1D,$1D
        .byte   $1D,$1D,$1D,$1E,$1E,$1E,$1E,$1E
        .byte   $1E,$1E,$1F,$1F,$1F,$1F,$1F,$1F
        .byte   $1F,$20,$20,$20,$20,$20,$20,$20
        .byte   $21,$21,$21,$21,$21,$21,$21,$22
        .byte   $22,$22,$22,$22,$22,$22,$23,$23
        .byte   $23,$23,$23,$23,$23,$24,$24,$24
        .byte   $24
L4921:  .byte   $00,$01,$02,$03
L4925:  .byte   $04,$05,$06,$00,$01,$02,$03,$04
        .byte   $05,$06,$00,$01,$02,$03,$04,$05
        .byte   $06,$00,$01,$02,$03,$04,$05,$06
        .byte   $00,$01,$02,$03,$04,$05,$06,$00
        .byte   $01,$02,$03,$04,$05,$06,$00,$01
        .byte   $02,$03,$04,$05,$06,$00,$01,$02
        .byte   $03,$04,$05,$06,$00,$01,$02,$03
        .byte   $04,$05,$06,$00,$01,$02,$03,$04
        .byte   $05,$06,$00,$01,$02,$03,$04,$05
        .byte   $06,$00,$01,$02,$03,$04,$05,$06
        .byte   $00,$01,$02,$03,$04,$05,$06,$00
        .byte   $01,$02,$03,$04,$05,$06,$00,$01
        .byte   $02,$03,$04,$05,$06,$00,$01,$02
        .byte   $03,$04,$05,$06,$00,$01,$02,$03
        .byte   $04,$05,$06,$00,$01,$02,$03,$04
L499D:  .byte   $05,$06,$00,$01,$02,$03,$04,$05
        .byte   $06,$00,$01,$02,$03,$04,$05,$06
        .byte   $00,$01,$02,$03,$04,$05,$06,$00
        .byte   $01,$02,$03,$04,$05,$06,$00,$01
        .byte   $02,$03,$04,$05,$06,$00,$01,$02
        .byte   $03,$04,$05,$06,$00,$01,$02,$03
        .byte   $04,$05,$06,$00,$01,$02,$03,$04
        .byte   $05,$06,$00,$01,$02,$03,$04,$05
        .byte   $06,$00,$01,$02,$03,$04,$05,$06
        .byte   $00,$01,$02,$03,$04,$05,$06,$00
        .byte   $01,$02,$03,$04,$05,$06,$00,$01
        .byte   $02,$03,$04,$05,$06,$00,$01,$02
        .byte   $03,$04,$05,$06,$00,$01,$02,$03
        .byte   $04,$05,$06,$00,$01,$02,$03,$04
        .byte   $05,$06,$00,$01,$02,$03,$04,$05
        .byte   $06,$00,$01,$02,$03,$04,$05,$06
        .byte   $00,$01,$02,$03

hires_table_lo:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $80,$80,$80,$80,$80,$80,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $80,$80,$80,$80,$80,$80,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $80,$80,$80,$80,$80,$80,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $80,$80,$80,$80,$80,$80,$80,$80
        .byte   $28,$28,$28,$28,$28,$28,$28,$28
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $28,$28,$28,$28,$28,$28,$28,$28
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $28,$28,$28,$28,$28,$28,$28,$28
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $28,$28,$28,$28,$28,$28,$28,$28
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0

hires_table_hi:
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $01,$05,$09,$0D,$11,$15,$19,$1D
        .byte   $01,$05,$09,$0D,$11,$15,$19,$1D
        .byte   $02,$06,$0A,$0E,$12,$16,$1A,$1E
        .byte   $02,$06,$0A,$0E,$12,$16,$1A,$1E
        .byte   $03,$07,$0B,$0F,$13,$17,$1B,$1F
        .byte   $03,$07,$0B,$0F,$13,$17,$1B,$1F
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $01,$05,$09,$0D,$11,$15,$19,$1D
        .byte   $01,$05,$09,$0D,$11,$15,$19,$1D
        .byte   $02,$06,$0A,$0E,$12,$16,$1A,$1E
        .byte   $02,$06,$0A,$0E,$12,$16,$1A,$1E
        .byte   $03,$07,$0B,$0F,$13,$17,$1B,$1F
        .byte   $03,$07,$0B,$0F,$13,$17,$1B,$1F
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $00,$04,$08,$0C,$10,$14,$18,$1C
        .byte   $01,$05,$09,$0D,$11,$15,$19,$1D
        .byte   $01,$05,$09,$0D,$11,$15,$19,$1D
        .byte   $02,$06,$0A,$0E,$12,$16,$1A,$1E
        .byte   $02,$06,$0A,$0E,$12,$16,$1A,$1E
        .byte   $03,$07,$0B,$0F,$13,$17,$1B,$1F
        .byte   $03,$07,$0B,$0F,$13,$17,$1B,$1F

L4BA1:  lda     ($84),y
        eor     ($8E),y
        eor     $F6
        and     $89
        eor     ($84),y
        bcc     L4BB1
L4BAD:  lda     ($8E),y
        eor     $F6
L4BB1:  and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4BAD
        lda     ($84),y
        eor     ($8E),y
        eor     $F6
        and     L0088
        eor     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        rts


        lda     ($8E),y
        eor     $F6
        and     $89
        bcc     L4BD7
L4BD3:  lda     ($8E),y
        eor     $F6
L4BD7:  ora     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4BD3
        lda     ($8E),y
        eor     $F6
        and     L0088
        ora     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        rts

        lda     ($8E),y
        eor     $F6
        and     $89
        bcc     L4BFD
L4BF9:  lda     ($8E),y
        eor     $F6
L4BFD:  eor     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4BF9
        lda     ($8E),y
        eor     $F6
        and     L0088
        eor     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        rts

        lda     ($8E),y
        eor     $F6
        and     $89
        bcc     L4C23
L4C1F:  lda     ($8E),y
        eor     $F6
L4C23:  eor     #$FF
        and     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4C1F
L4C30:  lda     ($8E),y
        eor     $F6
        and     L0088
        eor     #$FF
        and     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        rts

L4C41:  cpx     $98
        beq     L4C49
        inx
L4C46:
L4C47           := * + 1
L4C48           := * + 2
        jmp     L4CFB

L4C49:  rts

        lda     L4C5B
        adc     $90
        sta     L4C5B
        bcc     L4C57
        inc     L4C5C
L4C57:  ldy     L5168
L4C5A:
L4C5B           := * + 1
L4C5C           := * + 2
        lda     $FFFF,y
        and     #$7F
        sta     $0601,y
        dey
        bpl     L4C5A
        bmi     L4C9F
L4C67:  ldy     $8C
        inc     $8C
        lda     hires_table_hi,y
        ora     $80
        sta     L0083
        lda     hires_table_lo,y
        adc     $8A
        sta     L0082
L4C79:  stx     $81
        ldy     #$00
        ldx     #$00
L4C7F:  sta     $C055
        lda     (L0082),y
        and     #$7F
        sta     $C054
L4C8A           := * + 1
        sta     $0601,x
        lda     (L0082),y
        and     #$7F
L4C91           := * + 1
        sta     $0602,x
        iny
        inx
        inx
        cpx     L5168
        bcc     L4C7F
        beq     L4C7F
        ldx     $81
L4C9F:  clc
L4CA1           := * + 1
L4CA2           := * + 2
        jmp     L4CBE

        stx     L0082
        ldy     L5168
        lda     #$00
L4CAA:  ldx     $0601,y
L4CAE           := * + 1
L4CAF           := * + 2
        ora     $42A1,x
L4CB1           := * + 1
        sta     $0602,y
L4CB4           := * + 1
L4CB5           := * + 2
        lda     L4221,x
        dey
        bpl     L4CAA
L4CBA           := * + 1
        sta     $0601
        ldx     L0082
L4CBE:
L4CBF           := * + 1
L4CC0           := * + 2
        jmp     L4D38

L4CC1:  stx     L0082
        ldx     #$00
        ldy     #$00
L4CC7:
L4CC8           := * + 1
        lda     $0601,x
        sta     $C055
        sta     $0601,y
        sta     $C054
L4CD4           := * + 1
        lda     $0602,x
        sta     $0601,y
        inx
        inx
        iny
        cpy     $91
        bcc     L4CC7
        beq     L4CC7
        ldx     L0082
        jmp     L4D38

L4CE7:  ldx     $94
        clc
        jmp     L4C46

L4CED:  ldx     L4D6A
        stx     L4C47
        ldx     L4D6B
        stx     L4C48
        ldx     $94
L4CFB:
L4CFC           := * + 1
L4CFD           := * + 2
        jmp     L4D11

L4CFE:
        txa
        ror     a
        ror     a
        ror     a
        and     #$C0
        ora     $86
        sta     L0082
        lda     #$04
        adc     #$00
        sta     L0083
        jmp     L4C79

L4D11:  txa
        ror     a
        ror     a
        ror     a
        and     #$C0
        ora     $86
        sta     $8E
        lda     #$04
        adc     #$00
        sta     $8F
L4D22           := * + 1
L4D23           := * + 2
        jmp     L4D38

L4D24:  lda     $84
        clc
        adc     $D6
        sta     $84
        bcc     L4D30
        inc     $85
        clc
L4D30:  ldy     $91
        jsr     L4D67
        jmp     L4C41

L4D38:  lda     hires_table_hi,x
        ora     $D5
        sta     $85
        lda     hires_table_lo,x
        clc
        adc     $86
        sta     $84
        ldy     #$01
        jsr     L4D54
        ldy     #$00
        jsr     L4D54
        jmp     L4C41

L4D54:  sta     $C054,y
        lda     $92,y
        ora     #$80
        sta     L0088
        lda     $96,y
        ora     #$80
        sta     $89
        ldy     $91
L4D67:
L4D68           := * + 1
L4D69           := * + 2
        jmp     L4BA1

L4D6A:  .byte   $FB
L4D6B:
L4D6C           := * + 1
        jmp     L0000

        .byte   $00,$00,$00,$00,$00
L4D73:  .byte   $01,$03,$07,$0F,$1F,$3F,$7F
L4D7A:  .byte   $7F,$7F,$7F,$7F,$7F,$7F,$7F
L4D81:  .byte   $7F,$7E,$7C,$78,$70,$60,$40,$00
        .byte   $00,$00,$00,$00,$00,$00
L4D8F:  .byte   $A1
L4D90:  .byte   $4B,$CB,$4B,$F1,$4B,$17,$4C,$A1
        .byte   $4B,$CB,$4B,$F1,$4B,$17,$4C
L4D9F:  .byte   $BA
L4DA0:  .byte   $4B,$E2,$4B,$08,$4C,$30,$4C,$BA
        .byte   $4B,$E2,$4B,$08,$4C,$30,$4C

;;; ==================================================

SET_FILL_MODE_IMPL:
        lda     $F0
        ldx     #$00
        cmp     #$04
        bcc     L4DB9
        ldx     #$7F
L4DB9:  stx     $F6
        rts

L4DBC:  lda     $F7
        clc
        adc     $96
        sta     $96
        lda     $F8
        adc     $97
        sta     $97
        lda     $F9
        clc
        adc     $98
        sta     $98
        lda     $FA
        adc     $99
        sta     $99
        lda     $F7
        clc
        adc     $92
        sta     $92
        lda     $F8
        adc     $93
        sta     $93
        lda     $F9
        clc
        adc     $94
        sta     $94
        lda     $FA
        adc     $95
        sta     $95
        lsr     $97
        beq     L4DF7
        jmp     L4E79

L4DF7:  lda     $96
        ror     a
        tax
        lda     L4821,x
        ldy     L4921,x
L4E01:  sta     L0082
        tya
        rol     a
        tay
        lda     L4D73,y
        sta     $97
        lda     L4D6C,y
        sta     $96
        lsr     $93
        bne     L4E68
        lda     $92
        ror     a
        tax
        lda     L4821,x
        ldy     L4921,x
L4E1E:  sta     $86
        tya
        rol     a
        tay
        sty     $87
        lda     L4D81,y
        sta     $93
        lda     L4D7A,y
        sta     $92
        lda     L0082
        sec
        sbc     $86
L4E34:  sta     $91
        pha
        lda     $F0
        asl     a
        tax
        pla
        bne     L4E5B
        lda     $93
        and     $97
        sta     $93
        sta     $97
        lda     $92
        and     $96
        sta     $92
        sta     $96
        lda     L4D9F,x
        sta     L4D68
        lda     L4DA0,x
        sta     L4D69
        rts

L4E5B:  lda     L4D8F,x
        sta     L4D68
        lda     L4D90,x
        sta     L4D69
        rts

L4E68:  lda     $92
        ror     a
        tax
        php
        lda     L4825,x
        clc
        adc     #$24
        plp
        ldy     L4925,x
        bpl     L4E1E
L4E79:  lda     $96
        ror     a
        tax
        php
        lda     L4825,x
        clc
        adc     #$24
        plp
        ldy     L4925,x
        bmi     L4E8D
        jmp     L4E01

L4E8D:  lsr     a
        bne     L4E9A
        txa
        ror     a
        tax
        lda     L4821,x
        ldy     L4921,x
        rts

L4E9A:  txa
        ror     a
        tax
        php
        lda     L4825,x
        clc
        adc     #$24
        plp
        ldy     L4925,x
        rts

L4EA9:  lda     $86
        ldx     $94
        ldy     $D6
        jsr     L4F6D
        clc
        adc     $D4
        sta     $84
        tya
        adc     $D5
        sta     $85
        lda     #$02
        tax
        tay
        bit     $D6
        bmi     L4EE9
        lda     #$01
        sta     $8E
        lda     #$06
        sta     $8F
        jsr     L4F11
        txa
        inx
        stx     L5168
        jsr     L4E34
        lda     L4F31
        sta     L4CA1
        lda     L4F31+1
        sta     L4CA2
        lda     #$00
        ldx     #$00
        ldy     #$00
L4EE9:  pha
        lda     L4F37,x
        sta     L4D22
        lda     L4F37+1,x
        sta     L4D23
        pla
        tax
        lda     L4F33,x
        sta     L4CFC
        lda     L4F33+1,x
        sta     L4CFD
        lda     L4F3B,y
        sta     L4CBF
        lda     L4F3B+1,y
        sta     L4CC0
        rts

L4F11:  lda     $91
        asl     a
        tax
        inx
        lda     $93
        bne     L4F25
        dex
        inc     $8E
        inc     $84
        bne     L4F23
        inc     $85
L4F23:  lda     $92
L4F25:  sta     L0088
        lda     $96
        bne     L4F2E
        dex
        lda     $97
L4F2E:  sta     $89
        rts

L4F31:  .addr   L4CBE
L4F33:  .addr   L4CFE,L4D11
L4F37:  .addr   L4D24,L4D38
L4F3B:  .addr   L4D24,L4CC1

L4F3F:  ldx     $8C
        ldy     $90
        bmi     L4F48
        jsr     L4F70
L4F48:  clc
        adc     $8E
        sta     L4C5B
        tya
        adc     $8F
        sta     L4C5C
        ldx     #$02
        bit     $90
        bmi     L4F5C
        ldx     #$00
L4F5C:  lda     L4F69,x
        sta     L4C47
        lda     L4F6A,x
        sta     L4C48
        rts

L4F69:  lsr     a
L4F6A:  jmp     L4C67

L4F6D:  bmi     L4F8E
        asl     a
L4F70:  stx     L0082
        sty     L0083
        ldx     #$08
L4F76:  lsr     L0083
        bcc     L4F7D
        clc
        adc     L0082
L4F7D:  ror     a
        ror     $84
        dex
        bne     L4F76
        sty     L0082
        tay
        lda     $84
        sec
        sbc     L0082
        bcs     L4F8E
        dey
L4F8E:  rts

;;; ==================================================

SET_PATTERN_IMPL:  lda     #$00
        sta     $8E
        lda     $F9
        and     #$07
        lsr     a
        ror     $8E
        lsr     a
        ror     $8E
        adc     #$04
        sta     $8F
        ldx     #$07
L4FA3:  lda     $F7
        and     #$07
        tay
        lda     $E0,x
L4FAA:  dey
        bmi     L4FB2
        cmp     #$80
        rol     a
        bne     L4FAA
L4FB2:  ldy     #$27
L4FB4:  pha
        lsr     a
        sta     $C054
        sta     ($8E),y
        pla
        ror     a
        pha
        lsr     a
        sta     $C055
        sta     ($8E),y
        pla
        ror     a
        dey
        bpl     L4FB4
        lda     $8E
        sec
        sbc     #$40
        sta     $8E
        bcs     L4FDD
        ldy     $8F
        dey
        cpy     #$04
        bcs     L4FDB
        ldy     #$05
L4FDB:  sty     $8F
L4FDD:  dex
        bpl     L4FA3
        sta     $C054
        rts

;;; ==================================================

L4FE4:  .byte   0
DRAW_RECT_IMPL:
        ldy     #$03
L4FE7:  ldx     #$07
L4FE9:  lda     $9F,x
        sta     $92,x
        dex
        bpl     L4FE9
        ldx     L5016,y
        lda     $9F,x
        pha
        lda     $A0,x
        ldx     L501A,y
        sta     $93,x
        pla
        sta     $92,x
        sty     L4FE4
        jsr     L501E
        ldy     L4FE4
        dey
        bpl     L4FE7
        ldx     #$03
L500E:  lda     $9F,x
        sta     $EA,x
        dex
        bpl     L500E
L5015:  rts

L5016:  .byte   $00,$02,$04,$06
L501A:  .byte   $04,$06,$00,$02
L501E:  lda     $EE
        sec
        sbc     #$01
        cmp     #$FF
        beq     L5015
        adc     $96
        sta     $96
        bcc     L502F
        inc     $97
L502F:  lda     $EF
        sec
        sbc     #$01
        cmp     #$FF
        beq     L5015
        adc     $98
        sta     $98
        bcc     FILL_RECT_IMPL
        inc     $99
        ;; Fall through...
FILL_RECT_IMPL:
        jsr     L514C
L5043:  jsr     L50A9
        bcc     L5015
        jsr     L4DBC
        jsr     L4EA9
        jmp     L4CED

;;; ==================================================

.proc TEST_BOX_IMPL
        jsr     L514C
        lda     $EA
        ldx     $EB
        cpx     $93
        bmi     fail
        bne     :+
        cmp     $92
        bcc     fail
:       cpx     $97
        bmi     :+
        bne     fail
        cmp     $96
        bcc     :+
        bne     fail
:       lda     $EC
        ldx     $ED
        cpx     $95
        bmi     fail
        bne     :+
        cmp     $94
        bcc     fail
:       cpx     $99
        bmi     :+
        bne     fail
        cmp     $98
        bcc     :+
        bne     fail
:       lda     #$80            ; success!
        jmp     L40B1

fail:   rts
.endproc

;;; ==================================================

SET_BOX_IMPL:
        lda     $D0
        sec
        sbc     $D8
        sta     $F7
        lda     $D1
        sbc     $D9
        sta     $F8
        lda     $D2
        sec
        sbc     $DA
        sta     $F9
        lda     $D3
        sbc     $DB
        sta     $FA
        rts

L50A9:  lda     $DD
        cmp     $93
        bmi     L50B7
        bne     L50B9
        lda     $DC
        cmp     $92
        bcs     L50B9
L50B7:  clc
L50B8:  rts

L50B9:  lda     $97
        cmp     $D9
        bmi     L50B7
        bne     L50C7
        lda     $96
        cmp     $D8
        bcc     L50B8
L50C7:  lda     $DF
        cmp     $95
        bmi     L50B7
        bne     L50D5
        lda     $DE
        cmp     $94
        bcc     L50B8
L50D5:  lda     $99
        cmp     $DB
        bmi     L50B7
        bne     L50E3
        lda     $98
        cmp     $DA
        bcc     L50B8
L50E3:  ldy     #$00
        lda     $92
        sec
        sbc     $D8
        tax
        lda     $93
        sbc     $D9
        bpl     L50FE
        stx     $9B
        sta     $9C
        lda     $D8
        sta     $92
        lda     $D9
        sta     $93
        iny
L50FE:  lda     $DC
        sec
        sbc     $96
        tax
        lda     $DD
        sbc     $97
        bpl     L5116
        lda     $DC
        sta     $96
        lda     $DD
        sta     $97
        tya
        ora     #$04
        tay
L5116:  lda     $94
        sec
        sbc     $DA
        tax
        lda     $95
        sbc     $DB
        bpl     L5130
        stx     $9D
        sta     $9E
        lda     $DA
        sta     $94
        lda     $DB
        sta     $95
        iny
        iny
L5130:  lda     $DE
        sec
        sbc     $98
        tax
        lda     $DF
        sbc     $99
        bpl     L5148
        lda     $DE
        sta     $98
        lda     $DF
        sta     $99
        tya
        ora     #$08
        tay
L5148:  sty     $9A
        sec
        rts

L514C:  sec
        lda     $96
        sbc     $92
        lda     $97
        sbc     $93
        bmi     L5163
        sec
        lda     $98
        sbc     $94
        lda     $99
        sbc     $95
        bmi     L5163
        rts

L5163:  lda     #$81
        jmp     L40B1

;;; ==================================================

L5168:  .byte   0
L5169:  .byte   0

DRAW_BITMAP_IMPL:
        ldx     #$03
L516C:  lda     $8A,x
        sta     $9B,x
        lda     $92,x
        sta     $8A,x
        dex
        bpl     L516C
        lda     $96
        sec
        sbc     $92
        sta     L0082
        lda     $97
        sbc     $93
        sta     L0083
        lda     $9B
        sta     $92
        clc
        adc     L0082
        sta     $96
        lda     $9C
        sta     $93
        adc     L0083
        sta     $97
        lda     $98
        sec
        sbc     $94
        sta     L0082
        lda     $99
        sbc     $95
        sta     L0083
        lda     $9D
        sta     $94
        clc
        adc     L0082
        sta     $98
        lda     $9E
        sta     $95
        adc     L0083
        sta     $99

L51B3:  lda     #$00
        sta     $9B
        sta     $9C
        sta     $9D
        lda     $8F
        sta     $80
        jsr     L50A9
        bcs     L51C5
        rts

L51C5:  jsr     L4DBC
        lda     $91
        asl     a
        ldx     $93
        beq     L51D1
        adc     #$01
L51D1:  ldx     $96
        beq     L51D7
        adc     #$01
L51D7:  sta     L5169
        sta     L5168
        lda     #$02
        sta     $81
        lda     #$00
        sec
        sbc     $9D
        clc
        adc     $8C
        sta     $8C
        lda     #$00
        sec
        sbc     $9B
        tax
        lda     #$00
        sbc     $9C
        tay
        txa
        clc
        adc     $8A
        tax
        tya
        adc     $8B
        jsr     L4E8D
        sta     $8A
        tya
        rol     a
        cmp     #$07
        ldx     #$01
        bcc     L520E
        dex
        sbc     #$07
L520E:  stx     L4C8A
        inx
        stx     L4C91
        sta     $9B
        lda     $8A
        rol     a
        jsr     L4F3F
        jsr     L4EA9
        lda     #$01
        sta     $8E
        lda     #$06
        sta     $8F
        ldx     #$01
        lda     $87
        sec
        sbc     #$07
        bcc     L5234
        sta     $87
        dex
L5234:  stx     L4CC8
        inx
        stx     L4CD4
        lda     $87
        sec
        sbc     $9B
        bcs     L5249
        adc     #$07
        inc     L5168
        dec     $81
L5249:  tay
        bne     L5250
        ldx     #$00
        beq     L5276
L5250:  tya
        asl     a
        tay
        lda     L5293,y
        sta     L4CAE
        lda     L5294,y
        sta     L4CAF
        lda     L5287,y
        sta     L4CB4
        lda     L5288,y
        sta     L4CB5
        ldy     $81
        sty     L4CB1
        dey
        sty     L4CBA
        ldx     #$02
L5276:  lda     L5285,x
        sta     L4CA1
        lda     L5286,x
        sta     L4CA2
        jmp     L4CE7

L5285:  .byte   $BE
L5286:  .byte   $4C
L5287:  .byte   $A3
L5288:  jmp     L4221

        .byte   $21,$43,$21,$44,$21,$45,$21,$46
L5293:  .byte   $21
L5294:  .byte   $47,$A1,$42,$A1,$43,$A1,$44,$A1
        .byte   $45,$A1,$46,$A1
        .byte   $47
L52A1:  stx     $B0
        asl     a
        asl     a
        sta     $B3
        ldy     #$03
L52A9:  lda     ($80),y
        sta     $92,y
L52AE:  sta     $96,y
        dey
        bpl     L52A9
        lda     $94
        sta     $A7
        lda     $95
        sta     $A8
        ldy     #$00
        stx     $AE
L52C0:  stx     L0082
        lda     ($80),y
        sta     $0700,x
        pha
        iny
        lda     ($80),y
        sta     $073C,x
        tax
        pla
        iny
        cpx     $93
        bmi     L52DB
        bne     L52E1
        cmp     $92
        bcs     L52E1
L52DB:  sta     $92
        stx     $93
        bcc     L52EF
L52E1:  cpx     $97
        bmi     L52EF
        bne     L52EB
        cmp     $96
        bcc     L52EF
L52EB:  sta     $96
        stx     $97
L52EF:  ldx     L0082
        lda     ($80),y
        sta     $0780,x
        pha
        iny
        lda     ($80),y
        sta     $07BC,x
        tax
        pla
        iny
        cpx     $95
        bmi     L530A
        bne     L5310
        cmp     $94
        bcs     L5310
L530A:  sta     $94
        stx     $95
        bcc     L531E
L5310:  cpx     $99
        bmi     L531E
        bne     L531A
        cmp     $98
        bcc     L531E
L531A:  sta     $98
        stx     $99
L531E:  cpx     $A8
        stx     $A8
        bmi     L5330
        bne     L532C
        cmp     $A7
        bcc     L5330
        beq     L5330
L532C:  ldx     L0082
        stx     $AE
L5330:  sta     $A7
        ldx     L0082
        inx
        cpx     #$3C
        beq     L5398
        cpy     $B3
        bcc     L52C0
        lda     $94
        cmp     $98
        bne     L5349
        lda     $95
        cmp     $99
        beq     L5398
L5349:  stx     $B3
        bit     $BA
        bpl     L5351
        sec
        rts

L5351:  jmp     L50A9

L5354:  lda     $B4
        bpl     L5379
        asl     a
        asl     a
        adc     $80
        sta     $80
        bcc     L5362
        inc     $81
L5362:  ldy     #$00
        lda     ($80),y
        iny
        ora     ($80),y
        sta     $B4
        inc     $80
        bne     L5371
        inc     $81
L5371:  inc     $80
        bne     L5377
        inc     $81
L5377:  ldy     #$80
L5379:  rts

L537A:
        lda     #$80
        bne     L5380
L537E:  lda     #$00
L5380:  sta     $BA
        ldx     #$00
        stx     $AD
        jsr     L5362
L5389:  jsr     L52A1
        bcs     L539D
        ldx     $B0
L5390:  jsr     L5354
        bmi     L5389
        jmp     L546F

L5398:  lda     #$82
        jmp     L40B1

L539D:  ldy     #$01
        sty     $AF
        ldy     $AE
        cpy     $B0
        bne     L53A9
        ldy     $B3
L53A9:  dey
        sty     $AB
        php
L53AD:  sty     $AC
        iny
        cpy     $B3
        bne     L53B6
        ldy     $B0
L53B6:  sty     $AA
        cpy     $AE
        bne     L53BE
        dec     $AF
L53BE:  lda     $0780,y
        ldx     $07BC,y
        stx     L0083
L53C6:  sty     $A9
        iny
        cpy     $B3
        bne     L53CF
        ldy     $B0
L53CF:  cmp     $0780,y
        bne     L53DB
        ldx     $07BC,y
        cpx     L0083
        beq     L53C6
L53DB:  ldx     $AB
        sec
        sbc     $0780,x
        lda     L0083
        sbc     $07BC,x
        bmi     L5448
        lda     $A9
        plp
        bmi     L53F8
        tay
        sta     $0680,x
        lda     $AA
        sta     $06BC,x
        bpl     L545D
L53F8:  ldx     $AD
        cpx     #$10
        bcs     L5398
        sta     $0468,x
        lda     $AA
        sta     $04A8,x
        ldy     $AB
        lda     $0680,y
        sta     $0469,x
        lda     $06BC,y
        sta     $04A9,x
        lda     $0780,y
        sta     $05E8,x
        sta     $05E9,x
        lda     $07BC,y
        sta     L5E01,x
        sta     L5E02,x
        lda     $0700,y
        sta     L5E32,x
        lda     $073C,y
        sta     L5E42,x
        ldy     $AC
        lda     $0700,y
        sta     L5E31,x
        lda     $073C,y
        sta     L5E41,x
        inx
        inx
        stx     $AD
        ldy     $A9
        bpl     L545D
L5448:  plp
        bmi     L5450
        lda     #$80
        sta     $0680,x
L5450:  ldy     $AA
        txa
        sta     $0680,y
        lda     $AC
        sta     $06BC,y
        lda     #$80
L545D:  php
        sty     $AB
        ldy     $A9
        bit     $AF
        bmi     L5469
        jmp     L53AD

L5469:  plp
        ldx     $B3
        jmp     L5390

L546F:  ldx     #$00
        stx     $B1
        lda     #$80
        sta     $0428
        sta     $B2
L547A:  inx
        cpx     $AD
        bcc     L5482
        beq     L54B2
        rts

L5482:  lda     $B1
L5484:  tay
        lda     $05E8,x
        cmp     $05E8,y
        bcs     L54A2
        tya
        sta     $0428,x
        cpy     $B1
        beq     L549E
        ldy     L0082
        txa
        sta     $0428,y
        jmp     L547A

L549E:  stx     $B1
        bcs     L547A
L54A2:  sty     L0082
        lda     $0428,y
        bpl     L5484
        sta     $0428,x
        txa
        sta     $0428,y
        bpl     L547A
L54B2:  ldx     $B1
        lda     $05E8,x
        sta     $A9
        sta     $94
        lda     L5E01,x
        sta     $AA
        sta     $95
L54C2:  ldx     $B1
        bmi     L5534
L54C6:  lda     $05E8,x
        cmp     $A9
        bne     L5532
        lda     L5E01,x
        cmp     $AA
        bne     L5532
        lda     $0428,x
        sta     L0082
        jsr     L5606
        lda     $B2
        bmi     L5517
L54E0:  tay
        lda     L5E41,x
        cmp     L5E41,y
        bmi     L5520
        bne     L5507
        lda     L5E31,x
        cmp     L5E31,y
        bcc     L5520
        bne     L5507
        lda     L5E11,x
        cmp     L5E11,y
        bcc     L5520
        bne     L5507
        lda     L5E21,x
        cmp     L5E21,y
        bcc     L5520
L5507:  sty     L0083
        lda     $0428,y
        bpl     L54E0
        sta     $0428,x
        txa
        sta     $0428,y
        bpl     L552E
L5517:  sta     $0428,x
        stx     $B2
        jmp     L552E

L551F:  rts

L5520:  tya
        cpy     $B2
        beq     L5517
        sta     $0428,x
        txa
        ldy     L0083
        sta     $0428,y
L552E:  ldx     L0082
        bpl     L54C6
L5532:  stx     $B1
L5534:  lda     #$00
        sta     $AB
        lda     $B2
        sta     L0083
        bmi     L551F
L553E:  tax
        lda     $A9
        cmp     $05E8,x
        bne     L5584
        lda     $AA
        cmp     L5E01,x
        bne     L5584
        ldy     $0468,x
        lda     $0680,y
        bpl     L556C
        cpx     $B2
        beq     L5564
        ldy     L0083
        lda     $0428,x
        sta     $0428,y
        jmp     L55F8

L5564:  lda     $0428,x
        sta     $B2
        jmp     L55F8

L556C:  sta     $0468,x
        lda     $0700,y
        sta     L5E31,x
        lda     $073C,y
        sta     L5E41,x
        lda     $06BC,y
        sta     $04A8,x
        jsr     L5606
L5584:  stx     $AC
        ldy     L5E41,x
        lda     L5E31,x
        tax
        lda     $AB
        eor     #$FF
        sta     $AB
        bpl     L559B
        stx     $92
        sty     $93
        bmi     L55CE
L559B:  stx     $96
        sty     $97
        cpy     $93
        bmi     L55A9
        bne     L55B5
        cpx     $92
        bcs     L55B5
L55A9:  lda     $92
        stx     $92
        sta     $96
        lda     $93
        sty     $93
        sta     $97
L55B5:  lda     $A9
        sta     $94
        sta     $98
        lda     $AA
        sta     $95
        sta     $99
        bit     $BA
        bpl     L55CB
        jsr     TEST_BOX_IMPL
        jmp     L55CE

L55CB:  jsr     L5043
L55CE:  ldx     $AC
        lda     L5E21,x
        clc
        adc     $0528,x
        sta     L5E21,x
        lda     L5E11,x
        adc     $04E8,x
        sta     L5E11,x
        lda     L5E31,x
        adc     $0568,x
        sta     L5E31,x
        lda     L5E41,x
        adc     $05A8,x
        sta     L5E41,x
        lda     $0428,x
L55F8:  bmi     L55FD
        jmp     L553E

L55FD:  inc     $A9
        bne     L5603
        inc     $AA
L5603:  jmp     L54C2

L5606:  ldy     $04A8,x
        lda     $0780,y
        sta     $05E8,x
        sec
        sbc     $A9
        sta     $A3
        lda     $07BC,y
        sta     L5E01,x
        sbc     $AA
        sta     $A4
        lda     $0700,y
        sec
        sbc     L5E31,x
        sta     $A1
        lda     $073C,y
        sbc     L5E41,x
        sta     $A2
        php
        bpl     L563F
        lda     #$00
        sec
        sbc     $A1
        sta     $A1
        lda     #$00
        sbc     $A2
        sta     $A2
L563F:  stx     $84
        jsr     L569A
        ldx     $84
        plp
        bpl     L5662
        lda     #$00
        sec
        sbc     $9F
        sta     $9F
        lda     #$00
        sbc     $A0
        sta     $A0
        lda     #$00
        sbc     $A1
        sta     $A1
        lda     #$00
        sbc     $A2
        sta     $A2
L5662:  lda     $A2
        sta     $05A8,x
        cmp     #$80
        ror     a
        pha
        lda     $A1
        sta     $0568,x
        ror     a
        pha
        lda     $A0
        sta     $04E8,x
        ror     a
        pha
        lda     $9F
        sta     $0528,x
        ror     a
        sta     L5E21,x
        pla
        clc
        adc     #$80
        sta     L5E11,x
        pla
        adc     L5E31,x
        sta     L5E31,x
        pla
        adc     L5E41,x
        sta     L5E41,x
        rts

L5698:  lda     $A2
L569A:  ora     $A1
        bne     L56A8
        sta     $9F
        sta     $A0
        sta     $A1
        sta     $A2
        beq     L56D5
L56A8:  ldy     #$20
        lda     #$00
        sta     $9F
        sta     $A0
        sta     $A5
        sta     $A6
L56B4:  asl     $9F
        rol     $A0
        rol     $A1
        rol     $A2
        rol     $A5
        rol     $A6
        lda     $A5
        sec
        sbc     $A3
        tax
        lda     $A6
        sbc     $A4
        bcc     L56D2
        stx     $A5
        sta     $A6
        inc     $9F
L56D2:  dey
        bne     L56B4
L56D5:  rts

L56D6:
        lda     #$00
        sta     $BA
        jsr     L5362
L56DD:  lda     $80
        sta     $B7
        lda     $81
        sta     $B8
        lda     $B4
        sta     $B6
        ldx     #$00
        jsr     L52A1
        bcc     L572F
        lda     $B3
        sta     $B5
        ldy     #$00
L56F6:  dec     $B5
        beq     L5713
        sty     $B9
        ldx     #$00
L56FE:  lda     ($B7),y
        sta     $92,x
        iny
        inx
        cpx     #$08
        bne     L56FE
        jsr     L5783
        lda     $B9
        clc
        adc     #$04
        tay
        bne     L56F6
L5713:  ldx     #$00
L5715:  lda     ($B7),y
        sta     $92,x
        iny
        inx
        cpx     #$04
        bne     L5715
        ldy     #$03
L5721:  lda     ($B7),y
        sta     $96,y
        sta     $EA,y
        dey
        bpl     L5721
        jsr     L5783
L572F:  ldx     #$01
L5731:  lda     $B7,x
        sta     $80,x
        lda     $B5,x
        sta     $B3,x
        dex
        bpl     L5731
        jsr     L5354
        bmi     L56DD
        rts

L5742:
        lda     $A1
        ldx     $A2
        jsr     L5758
        lda     $A3
        ldx     $A4
        clc
        adc     $EC
        sta     $EC
        txa
        adc     $ED
        sta     $ED
        rts

L5758:  clc
        adc     $EA
        sta     $EA
        txa
        adc     $EB
        sta     $EB
        rts

;;; ==================================================

DRAW_LINE_IMPL:
        ldx     #$02
L5765:  lda     $A1,x
        clc
        adc     $EA,x
        sta     $92,x
        lda     $A2,x
        adc     $EB,x
        sta     $93,x
        dex
        dex
        bpl     L5765

L5776:
        ldx     #$03
L5778:  lda     $EA,x
        sta     $96,x
        lda     $92,x
        sta     $EA,x
        dex
        bpl     L5778
L5783:  lda     $99
        cmp     $95
        bmi     L57B0
        bne     L57BF
        lda     $98
        cmp     $94
        bcc     L57B0
        bne     L57BF
        lda     $92
        ldx     $93
        cpx     $97
        bmi     L57AD
        bne     L57A1
        cmp     $96
        bcc     L57AD
L57A1:  ldy     $96
        sta     $96
        sty     $92
        ldy     $97
        stx     $97
        sty     $93
L57AD:  jmp     L501E

L57B0:  ldx     #$03
L57B2:  lda     $92,x
        tay
        lda     $96,x
        sta     $92,x
        tya
        sta     $96,x
        dex
        bpl     L57B2
L57BF:  ldx     $EE
        dex
        stx     $A2
        lda     $EF
        sta     $A4
        lda     #$00
        sta     $A1
        sta     $A3
        lda     $92
        ldx     $93
        cpx     $97
        bmi     L57E9
        bne     L57E1
        cmp     $96
        bcc     L57E9
        bne     L57E1
        jmp     L501E

L57E1:  lda     $A1
        ldx     $A2
        sta     $A2
        stx     $A1
L57E9:  ldy     #$05
L57EB:  sty     L0082
        ldx     L583E,y
        ldy     #$03
L57F2:  lda     $92,x
        sta     L0083,y
        dex
        dey
        bpl     L57F2
        ldy     L0082
        ldx     L5844,y
        lda     $A1,x
        clc
        adc     L0083
        sta     L0083
        bcc     L580B
        inc     $84
L580B:  ldx     L584A,y
        lda     $A3,x
        clc
        adc     $85
        sta     $85
        bcc     L5819
        inc     $86
L5819:  tya
        asl     a
        asl     a
        tay
        ldx     #$00
L581F:  lda     L0083,x
        sta     L5852,y
        iny
        inx
        cpx     #$04
        bne     L581F
        ldy     L0082
        dey
        bpl     L57EB
        lda     L583C
        sta     $80
        lda     L583D
        sta     $81
        jmp     L537E

L583C:  .byte   $50
L583D:  .byte   $58
L583E:  .byte   $03,$03,$07,$07,$07,$03
L5844:  .byte   $00,$00,$00,$01,$01,$01
L584A:  .byte   $00,$01,$01,$01,$00,$00,$06,$00
L5852:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

L586A:
        lda     $80
        sta     $F2
        lda     $81
        sta     $F3
L5872:  ldy     #$00
L5874:  lda     ($F2),y
        sta     $FD,y
        iny
        cpy     #$03
        bne     L5874
        cmp     #$11
        bcs     L58B7
        lda     $F2
        ldx     $F3
        clc
        adc     #$03
        bcc     L588C
        inx
L588C:  sta     $FB
        stx     $FC
        sec
        adc     $FE
        bcc     L5896
        inx
L5896:  ldy     #$00
L5898:  sta     L58BC,y
        pha
        txa
        sta     L58CC,y
        pla
        sec
        adc     $FE
        bcc     L58A7
        inx
L58A7:  bit     $FD
        bpl     L58B1
        sec
        adc     $FE
        bcc     L58B1
        inx
L58B1:  iny
        cpy     $FF
        bne     L5898
        rts

L58B7:  lda     #$83
        jmp     L40B1

L58BC:  .byte   0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
L58CC:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

;;; ==================================================

MEASURE_TEXT_IMPL:
        jsr     L58E8
        ldy     #$03
        sta     ($80),y
        txa
        iny
        sta     ($80),y
        rts

L58E8:  ldx     #$00
        ldy     #$00
        sty     L0082
L58EE:  sty     L0083
        lda     ($A1),y
        tay
        txa
        clc
        adc     ($FB),y
        bcc     L58FB
        inc     L0082
L58FB:  tax
        ldy     L0083
        iny
        cpy     $A3
        bne     L58EE
        txa
        ldx     L0082
        rts

L5907:  sec
        sbc     #$01
        bcs     L590D
        dex
L590D:  clc
        adc     $EA
        sta     $96
        txa
        adc     $EB
        sta     $97
        lda     $EA
        sta     $92
        lda     $EB
        sta     $93
        lda     $EC
        sta     $98
        ldx     $ED
        stx     $99
        clc
        adc     #$01
        bcc     L592D
        inx
L592D:  sec
        sbc     $FF
        bcs     L5933
        dex
L5933:  sta     $94
        stx     $95
        rts

;;; ==================================================

DRAW_TEXT_IMPL:
        jsr     L5EFA
        jsr     L58E8
        sta     $A4
        stx     $A5
        ldy     #$00
        sty     $9F
        sty     $A0
        sty     $9B
        sty     $9D
        jsr     L5907
        jsr     L50A9
        bcc     L59B9
        tya
        ror     a
        bcc     L5972
        ldy     #$00
        ldx     $9C
L595C:  sty     $9F
        lda     ($A1),y
        tay
        lda     ($FB),y
        clc
        adc     $9B
        bcc     L596B
        inx
        beq     L5972
L596B:  sta     $9B
        ldy     $9F
        iny
        bne     L595C
L5972:  jsr     L4DBC
        jsr     L4EA9
        lda     $87
        clc
        adc     $9B
        bpl     L5985
        inc     $91
        dec     $A0
        adc     #$0E
L5985:  sta     $87
        lda     $91
        inc     $91
        ldy     $D6
        bpl     L599F
        asl     a
        tax
        lda     $87
        cmp     #$07
        bcs     L5998
        inx
L5998:  lda     $96
        beq     L599D
        inx
L599D:  stx     $91
L599F:  lda     $87
        sec
        sbc     #$07
        bcc     L59A8
        sta     $87
L59A8:  lda     #$00
        rol     a
        eor     #$01
        sta     $9C
        tax
        sta     $C054,x
        jsr     L59C3
        sta     $C054
L59B9:  jsr     L5EEA
        lda     $A4
        ldx     $A5
        jmp     L5758

L59C3:  lda     $98
        sec
        sbc     $94
        asl     a
        tax
        lda     L5D81,x
        sta     L5B02
        lda     L5D82,x
        sta     L5B03
        lda     L5DA1,x
        sta     L5A95
        lda     L5DA2,x
        sta     L5A96
        lda     L5DC1,x
        sta     L5C22
        lda     L5DC2,x
        sta     L5C23
        lda     L5DE1,x
        sta     L5CBE
        lda     L5DE2,x
        sta     L5CBF
        txa
        lsr     a
        tax
        sec
        stx     $80
        stx     $81
        lda     #$00
        sbc     $9D
        sta     $9D
        tay
        ldx     #$C3
        sec
L5A0C:  lda     L58BC,y
        sta     L5B05,x
        lda     L58CC,y
        sta     L5B06,x
        txa
        sbc     #$0D
        tax
        iny
        dec     $80
        bpl     L5A0C
        ldy     $9D
        ldx     #$4B
        sec
L5A26:  lda     L58BC,y
        sta     L5A98,x
        lda     L58CC,y
        sta     L5A99,x
        txa
        sbc     #$05
        tax
        iny
        dec     $81
        bpl     L5A26
        ldy     $94
        ldx     #$00
L5A3F:  bit     $D6
        bmi     L5A56
        lda     $84
        clc
        adc     $D6
        sta     $84
        sta     $20,x
        lda     $85
        adc     #$00
        sta     $85
        sta     $21,x
        bne     L5A65
L5A56:  lda     hires_table_lo,y
        clc
        adc     $86
        sta     $20,x
        lda     hires_table_hi,y
        ora     $D5
        sta     $21,x
L5A65:  cpy     $98
L5A68           := * + 1
        beq     L5A6E
        iny
        inx
        inx
        bne     L5A3F
L5A6E:  ldx     #$0F
        lda     #$00
L5A72:  sta     L0000,x
        dex
        bpl     L5A72
        sta     $81
        sta     $40
        lda     #$80
        sta     $42
        ldy     $9F
L5A81:  lda     ($A1),y
        tay
        bit     $81
        bpl     L5A8B
        sec
        adc     $FE
L5A8B:  tax
        lda     ($FB),y
        beq     L5AE7
        ldy     $87
        bne     L5AEA
L5A95           := * + 1
L5A96           := * + 2
        jmp     L5A97

L5A97:
L5A98           := * + 1
L5A99           := * + 2
        lda     $FFFF,x
        sta     $0F
        lda     $FFFF,x
        sta     $0E
        lda     $FFFF,x
        sta     $0D
        lda     $FFFF,x
        sta     $0C
        lda     $FFFF,x
        sta     $0B
        lda     $FFFF,x
        sta     $0A
        lda     $FFFF,x
        sta     $09
        lda     $FFFF,x
        sta     $08
        lda     $FFFF,x
        sta     $07
        lda     $FFFF,x
        sta     $06
        lda     $FFFF,x
        sta     $05
        lda     $FFFF,x
        sta     $04
        lda     $FFFF,x
        sta     $03
        lda     $FFFF,x
        sta     $02
        lda     $FFFF,x
        sta     $01
        lda     $FFFF,x
        sta     L0000
L5AE7:  jmp     L5BD4

L5AEA:  tya
        asl     a
        tay
        lda     L5287,y
        sta     $40
        lda     L5288,y
        sta     $41
        lda     L5293,y
        sta     $42
        lda     L5294,y
        sta     $43
L5B02           := * + 1
L5B03           := * + 2
        jmp     L5B04

L5B04:
L5B05           := * + 1
L5B06           := * + 2
        ldy     $FFFF,x
        lda     ($42),y
        sta     $1F
        lda     ($40),y
        ora     $0F
        sta     $0F
        ldy     $FFFF,x
        lda     ($42),y
        sta     $1E
        lda     ($40),y
        ora     $0E
        sta     $0E
        ldy     $FFFF,x
        lda     ($42),y
        sta     $1D
        lda     ($40),y
        ora     $0D
        sta     $0D
        ldy     $FFFF,x
        lda     ($42),y
        sta     $1C
        lda     ($40),y
        ora     $0C
        sta     $0C
        ldy     $FFFF,x
        lda     ($42),y
        sta     $1B
        lda     ($40),y
        ora     $0B
        sta     $0B
        ldy     $FFFF,x
        lda     ($42),y
        sta     $1A
        lda     ($40),y
        ora     $0A
        sta     $0A
        ldy     $FFFF,x
        lda     ($42),y
        sta     $19
        lda     ($40),y
        ora     $09
        sta     $09
        ldy     $FFFF,x
        lda     ($42),y
        sta     $18
        lda     ($40),y
        ora     $08
        sta     $08
        ldy     $FFFF,x
        lda     ($42),y
        sta     $17
        lda     ($40),y
        ora     $07
        sta     $07
        ldy     $FFFF,x
        lda     ($42),y
        sta     $16
        lda     ($40),y
        ora     $06
        sta     $06
        ldy     $FFFF,x
        lda     ($42),y
        sta     $15
        lda     ($40),y
        ora     $05
        sta     $05
        ldy     $FFFF,x
        lda     ($42),y
        sta     $14
        lda     ($40),y
        ora     $04
        sta     $04
        ldy     $FFFF,x
        lda     ($42),y
        sta     $13
        lda     ($40),y
        ora     $03
        sta     $03
        ldy     $FFFF,x
        lda     ($42),y
        sta     $12
        lda     ($40),y
        ora     $02
        sta     $02
        ldy     $FFFF,x
        lda     ($42),y
        sta     $11
        lda     ($40),y
        ora     $01
        sta     $01
        ldy     $FFFF,x
        lda     ($42),y
        sta     $10
        lda     ($40),y
        ora     L0000
        sta     L0000
L5BD4:  bit     $81
        bpl     L5BE2
        inc     $9F
        lda     #$00
        sta     $81
        lda     $9A
        bne     L5BF6
L5BE2:  txa
        tay
        lda     ($FB),y
        cmp     #$08
        bcs     L5BEE
        inc     $9F
        bcc     L5BF6
L5BEE:  sbc     #$07
        sta     $9A
        ror     $81
        lda     #$07
L5BF6:  clc
        adc     $87
        cmp     #$07
        bcs     L5C0D
        sta     $87
L5BFF:  ldy     $9F
        cpy     $A3
        beq     L5C08
        jmp     L5A81

L5C08:  ldy     $A0
        jmp     L5CB5

L5C0D:  sbc     #$07
        sta     $87
        ldy     $A0
        bne     L5C18
        jmp     L5CA2

L5C18:  bmi     L5C84
        dec     $91
        bne     L5C21
        jmp     L5CB5

L5C21:
L5C22           := * + 1
L5C23           := * + 2
        jmp     L5C24

L5C24:  lda     $0F
        eor     $F1
        sta     ($3E),y
        lda     $0E
        eor     $F1
        sta     ($3C),y
        lda     $0D
        eor     $F1
        sta     ($3A),y
        lda     $0C
        eor     $F1
        sta     ($38),y
        lda     $0B
        eor     $F1
        sta     ($36),y
        lda     $0A
        eor     $F1
        sta     ($34),y
        lda     $09
        eor     $F1
        sta     ($32),y
        lda     $08
        eor     $F1
        sta     ($30),y
        lda     $07
        eor     $F1
        sta     ($2E),y
        lda     $06
        eor     $F1
        sta     ($2C),y
        lda     $05
        eor     $F1
        sta     ($2A),y
        lda     $04
        eor     $F1
        sta     ($28),y
        lda     $03
        eor     $F1
        sta     ($26),y
        lda     $02
        eor     $F1
        sta     ($24),y
        lda     $01
        eor     $F1
        sta     ($22),y
        lda     L0000
        eor     $F1
        sta     ($20),y
L5C84:  bit     $D6
        bpl     L5C94
        lda     $9C
        eor     #$01
        tax
        sta     $9C
        sta     $C054,x
        beq     L5C96
L5C94:  inc     $A0
L5C96:  ldx     #$0F
L5C98:  lda     $10,x
        sta     L0000,x
        dex
        bpl     L5C98
        jmp     L5BFF

L5CA2:  ldx     $9C
        lda     $92,x
        dec     $91
        beq     L5CB0
        jsr     L5CB9
        jmp     L5C84

L5CB0:  and     $96,x
        bne     L5CB9
        rts

L5CB5:  ldx     $9C
        lda     $96,x
L5CB9:  ora     #$80
        sta     $80
L5CBE           := * + 1
L5CBF           := * + 2
        jmp     L5CC0

L5CC0:  lda     $0F
        eor     $F1
        eor     ($3E),y
        and     $80
        eor     ($3E),y
        sta     ($3E),y
        lda     $0E
        eor     $F1
        eor     ($3C),y
        and     $80
        eor     ($3C),y
        sta     ($3C),y
        lda     $0D
        eor     $F1
        eor     ($3A),y
        and     $80
        eor     ($3A),y
        sta     ($3A),y
        lda     $0C
        eor     $F1
        eor     ($38),y
        and     $80
        eor     ($38),y
        sta     ($38),y
        lda     $0B
        eor     $F1
        eor     ($36),y
        and     $80
        eor     ($36),y
        sta     ($36),y
        lda     $0A
        eor     $F1
        eor     ($34),y
        and     $80
        eor     ($34),y
        sta     ($34),y
        lda     $09
        eor     $F1
        eor     ($32),y
        and     $80
        eor     ($32),y
        sta     ($32),y
        lda     $08
        eor     $F1
        eor     ($30),y
        and     $80
        eor     ($30),y
        sta     ($30),y
        lda     $07
        eor     $F1
        eor     ($2E),y
        and     $80
        eor     ($2E),y
        sta     ($2E),y
        lda     $06
        eor     $F1
        eor     ($2C),y
        and     $80
        eor     ($2C),y
        sta     ($2C),y
        lda     $05
        eor     $F1
        eor     ($2A),y
        and     $80
        eor     ($2A),y
        sta     ($2A),y
        lda     $04
        eor     $F1
        eor     ($28),y
        and     $80
        eor     ($28),y
        sta     ($28),y
        lda     $03
        eor     $F1
        eor     ($26),y
        and     $80
        eor     ($26),y
        sta     ($26),y
        lda     $02
        eor     $F1
        eor     ($24),y
        and     $80
        eor     ($24),y
        sta     ($24),y
        lda     $01
        eor     $F1
        eor     ($22),y
        and     $80
        eor     ($22),y
        sta     ($22),y
        lda     L0000
        eor     $F1
        eor     ($20),y
        and     $80
        eor     ($20),y
        sta     ($20),y
        rts

L5D81:  .byte   $C7
L5D82:  .byte   $5B,$BA,$5B,$AD,$5B,$A0,$5B,$93
        .byte   $5B,$86,$5B,$79,$5B,$6C,$5B,$5F
        .byte   $5B,$52,$5B,$45,$5B,$38,$5B,$2B
        .byte   $5B,$1E,$5B,$11,$5B,$04,$5B
L5DA1:  .byte   $E2
L5DA2:  .byte   $5A,$DD,$5A,$D8,$5A,$D3,$5A,$CE
        .byte   $5A,$C9,$5A,$C4,$5A,$BF,$5A,$BA
        .byte   $5A,$B5,$5A,$B0,$5A,$AB,$5A,$A6
        .byte   $5A,$A1,$5A,$9C,$5A,$97,$5A
L5DC1:  .byte   $7E
L5DC2:  .byte   $5C,$78,$5C,$72,$5C,$6C,$5C,$66
        .byte   $5C,$60,$5C,$5A,$5C,$54,$5C,$4E
        .byte   $5C,$48,$5C,$42,$5C,$3C,$5C,$36
        .byte   $5C,$30,$5C,$2A,$5C,$24,$5C
L5DE1:  .byte   $74
L5DE2:  .byte   $5D,$68,$5D,$5C,$5D,$50,$5D,$44
        .byte   $5D,$38,$5D,$2C,$5D,$20,$5D,$14
        .byte   $5D,$08,$5D,$FC,$5C,$F0,$5C,$E4
        .byte   $5C,$D8,$5C,$CC,$5C,$C0,$5C
L5E01:  .byte   $00
L5E02:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
L5E11:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L5E21:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L5E31:  .byte   $00
L5E32:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
L5E41:  .byte   $00
L5E42:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00

L5E51:  lda     #$71
        sta     L0082
        jsr     L5E7B
        ldx     #$23
L5E5A:  lda     L5F1E,x
        sta     $8A,x
        sta     $D0,x
        dex
        bpl     L5E5A
        lda     L5E79
        ldx     L5E79+1
        jsr     L5EA0
        lda     #$7F
        sta     $F6
        jsr     FILL_RECT_IMPL
        lda     #$00
        sta     $F6
        rts

L5E79:  .addr   $5F42

L5E7B:  lda     $C05E
        sta     $C00D
        ldx     #$03
L5E83:  lsr     L0082
        lda     L5E98,x
        rol     a
        tay
        bcs     L5E91
        lda     $C000,y
        bcc     L5E94
L5E91:  sta     $C000,y
L5E94:  dex
        bpl     L5E83
        rts

L5E98:  .byte   $28,$29,$2A,$2B

;;; ==================================================

SET_STATE_IMPL:
        lda     $80
        ldx     $81
L5EA0:  sta     $F4
        stx     $F5
L5EA4:  lda     $F3
        beq     L5EAB
        jsr     L5872
L5EAB:  jsr     SET_BOX_IMPL
        jsr     SET_PATTERN_IMPL
        jmp     SET_FILL_MODE_IMPL

L5EB4:
        jsr     L40C8
        lda     $F4
        ldx     $F5
L5EBB:  ldy     #$00
L5EBD:  sta     ($80),y
        txa
        iny
        sta     ($80),y
        rts

;;; ==================================================

QUERY_SCREEN_IMPL:
        ldy     #$23
L5EC6:  lda     L5F1E,y
        sta     ($80),y
        dey
        bpl     L5EC6
L5ECE:  rts

;;; ==================================================

CONFIGURE_ZP_IMPL:
        lda     L0082
        cmp     L5F1B
        beq     L5ECE
        sta     L5F1B
        bcc     L5ECE
        jmp     L408A

L5EDE:
        lda     L0082
        cmp     L5F1C
        beq     L5ECE
        sta     L5F1C
        bcc     L5EFF
L5EEA:  bit     L5F1C
        bpl     L5EF9
        ldx     #$43
L5EF1:  lda     L5E01,x
        sta     L0000,x
        dex
        bpl     L5EF1
L5EF9:  rts


L5EFA:  bit     L5F1C
        bpl     L5EF9
L5EFF:  ldx     #$43
L5F01:  lda     L0000,x
        sta     L5E01,x
        dex
        bpl     L5F01
        rts

L5F0A:
        ldy     #$05
L5F0C:  lda     L5F15,y
        sta     ($80),y
        dey
        bpl     L5F0C
        rts

L5F15:  .byte   $01,$00,$00,$46,$01,$00
L5F1B:  .byte   $80
L5F1C:  .byte   $80
L5F1D:  .byte   $00
L5F1E:  .byte   $00,$00,$00,$00,$00,$20,$80,$00
        .byte   $00,$00,$00,$00,$2F,$02,$BF,$00

white_pattern:
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

        .byte   $FF,$00,$00,$00,$00,$00,$01,$01
        .byte   $00
L5F3F:  .byte   $00
L5F40:  .byte   $00
L5F41:  .byte   $00,$00,$00,$00,$00,$00,$20,$80
        .byte   $00,$00,$00,$00,$00,$2F,$02,$BF
        .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$01
        .byte   $01,$00,$00,$00,$00
L5F66:  .byte   $42,$5F,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
L5F72:  .res    128, 0
L5FF2:  .byte   $00
L5FF3:  .byte   $FF

.proc set_pos_params
xcoord: .word   0
ycoord: .word   0
.endproc

L5FF8:  .byte   $00
L5FF9:  .byte   $00
L5FFA:  .byte   $00
L5FFB:  .byte   $00
L5FFC:  .byte   $00
L5FFD:  .byte   $00
L5FFE:  .byte   $00
L5FFF:  .byte   $00
L6000:  .byte   $00
L6001:  .byte   $00
L6002:  .byte   $00
L6003:  .byte   $00
L6004:  .byte   $00
L6005:  .byte   $00
L6006:  .byte   $00
L6007:  .byte   $00
L6008:  .byte   $00
L6009:  .byte   $00
L600A:  .byte   $00
L600B:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
L602F:  .byte   $00,$00,$00,$00,$00,$00,$02,$00
        .byte   $06,$00,$0E,$00,$1E,$00,$3E,$00
        .byte   $7E,$00,$1A,$00,$30,$00,$30,$00
        .byte   $60,$00,$00,$00,$03,$00,$07,$00
        .byte   $0F,$00,$1F,$00,$3F,$00,$7F,$00
        .byte   $7F,$01,$7F,$00,$78,$00,$78,$00
        .byte   $70,$01,$70,$01,$01,$01
L6065:  .byte   $33
L6066:  .byte   $60
L6067:  lda     #$FF
        sta     L5FF3
        lda     #$00
        sta     L5FF2
        lda     L6065
        sta     $80
        lda     L6066
        sta     $81

;;; ==================================================

SET_CURSOR_IMPL:
        php
        sei
        lda     $80
        ldx     $81
        sta     L6142
        stx     L6143
        clc
        adc     #$18
        bcc     L608D
        inx
L608D:  sta     L6148
        stx     L6149
        ldy     #$30
        lda     ($80),y
        sta     L6002
        iny
        lda     ($80),y
        sta     L6003
        jsr     L61C6
        jsr     L60B2
        plp
L60A7:  rts

L60A8:  lda     L5FF3
        bne     L60A7
        bit     L5FF2
        bmi     L60A7
L60B2:  lda     #$00
        sta     L5FF3
        sta     L5FF2
        lda     set_pos_params::ycoord
        clc
        sbc     L6003
        sta     $84
        clc
        adc     #$0C
        sta     $85
        lda     set_pos_params::xcoord
        sec
        sbc     L6002
        tax
        lda     set_pos_params::xcoord+1
        sbc     #$00
        bpl     L60E1
        txa
        ror     a
        tax
        ldy     L499D,x
        lda     #$FF
        bmi     L60E4
L60E1:  jsr     L4E8D
L60E4:  sta     L0082
        tya
        rol     a
        cmp     #$07
        bcc     L60EE
        sbc     #$07
L60EE:  tay
        lda     #$2A
        rol     a
        eor     #$01
        sta     L0083
        sty     L6004
        tya
        asl     a
        tay
        lda     L5293,y
        sta     L6164
        lda     L5294,y
        sta     L6165
        lda     L5287,y
        sta     L616A
        lda     L5288,y
        sta     L616B
        ldx     #$03
L6116:  lda     L0082,x
        sta     L602F,x
        dex
        bpl     L6116
        ldx     #$17
        stx     $86
        ldx     #$23
        ldy     $85
L6126:  cpy     #$C0
        bcc     L612D
        jmp     L61B9

L612D:  lda     hires_table_lo,y
        sta     L0088
        lda     hires_table_hi,y
        ora     #$20
        sta     $89
        sty     $85
        stx     $87
        ldy     $86
        ldx     #$01
L6141:
L6142           := * + 1
L6143           := * + 2
        lda     $FFFF,y
        sta     L6005,x
L6148           := * + 1
L6149           := * + 2
        lda     $FFFF,y
        sta     L6008,x
        dey
        dex
        bpl     L6141
        lda     #$00
        sta     L6007
        sta     L600A
        ldy     L6004
        beq     L6172
        ldy     #$05
L6160:  ldx     L6004,y
L6164           := * + 1
L6165           := * + 2
        ora     $FF80,x
        sta     L6005,y
L616A           := * + 1
L616B           := * + 2
        lda     $FF00,x
        dey
        bne     L6160
        sta     L6005
L6172:  ldx     $87
        ldy     L0082
        lda     L0083
        jsr     L622A
        bcs     L618D
        lda     (L0088),y
        sta     L600B,x
        lda     L6008
        ora     (L0088),y
        eor     L6005
        sta     (L0088),y
        dex
L618D:  jsr     L6220
        bcs     L61A2
        lda     (L0088),y
        sta     L600B,x
        lda     L6009
        ora     (L0088),y
        eor     L6006
        sta     (L0088),y
        dex
L61A2:  jsr     L6220
        bcs     L61B7
        lda     (L0088),y
        sta     L600B,x
        lda     L600A
        ora     (L0088),y
        eor     L6007
        sta     (L0088),y
        dex
L61B7:  ldy     $85
L61B9:  dec     $86
        dec     $86
        dey
        cpy     $84
        beq     L621C
        jmp     L6126

L61C5:  rts

L61C6:  lda     L5FF3
        bne     L61C5
        bit     L5FF2
        bmi     L61C5
        ldx     #$03
L61D2:  lda     L602F,x
        sta     L0082,x
        dex
        bpl     L61D2
        ldx     #$23
        ldy     $85
L61DE:  cpy     #$C0
        bcs     L6217
        lda     hires_table_lo,y
        sta     L0088
        lda     hires_table_hi,y
        ora     #$20
        sta     $89
        sty     $85
L61F1           := * + 1
        ldy     L0082
        lda     L0083
        jsr     L622A
        bcs     L61FF
        lda     L600B,x
        sta     (L0088),y
        dex
L61FF:  jsr     L6220
        bcs     L620A
        lda     L600B,x
        sta     (L0088),y
        dex
L620A:  jsr     L6220
        bcs     L6215
        lda     L600B,x
        sta     (L0088),y
        dex
L6215:  ldy     $85
L6217:  dey
        cpy     $84
        bne     L61DE
L621C:  sta     $C054
        rts

L6220:  lda     L622E
        eor     #$01
        cmp     #$54
        beq     L622A
        iny
L622A:  sta     L622E
        .byte   $8D
L622E:  bbs7    $C0,L61F1
        plp
        rts

;;; ==================================================

SHOW_CURSOR_IMPL:
        php
        sei
        lda     L5FF3
        beq     L624C
        inc     L5FF3
        bmi     L624C
        beq     L6244
        dec     L5FF3
L6244:  bit     L5FF2
        bmi     L624C
        jsr     L60B2
L624C:  plp
        rts

L624E:
        php
        sei
        jsr     L61C6
        lda     #$80
        sta     L5FF2
        plp
        rts

;;; ==================================================

HIDE_CURSOR_IMPL:
        php
        sei
        jsr     L61C6
        dec     L5FF3
        plp
L6263:  rts

L6264:  .byte   0
L6265:  bit     L6339
        bpl     L627C
        lda     L7D74
        bne     L627C
        dec     L6264
        lda     L6264
        bpl     L6263
        lda     #$02
        sta     L6264
L627C:  ldx     #2
L627E:  lda     L5FF8,x
        cmp     set_pos_params,x
        bne     L628B
        dex
        bpl     L627E
        bmi     L629F
L628B:  jsr     L61C6
        ldx     #2
        stx     L5FF2
L6293:  lda     L5FF8,x
        sta     set_pos_params,x
        dex
        bpl     L6293
        jsr     L60A8
L629F:  bit     L851C
        bmi     L62A7
        jsr     L62BA
L62A7:  bit     L851C
        bpl     L62B1
        lda     #$00
        sta     L5FFC
L62B1:  lda     L7D74
        beq     L62B9
        jsr     L7EF5
L62B9:  rts

L62BA:  ldy     #$14
        jsr     L6313
        bit     L5FFF
        bmi     L62D9
        ldx     L851D
        lda     $03B8,x
        sta     L5FF8
        lda     $04B8,x
        sta     L5FF9
        lda     $0438,x
        sta     L5FFA
L62D9:  ldy     L5FFD
        beq     L62EF
L62DE:  lda     L5FF8
        asl     a
        sta     L5FF8
        lda     L5FF9
        rol     a
        sta     L5FF9
        dey
        bne     L62DE
L62EF:  ldy     L5FFE
        beq     L62FE
        lda     L5FFA
L62F7:  asl     a
        dey
        bne     L62F7
        sta     L5FFA
L62FE:  bit     L5FFF
        bmi     L6309
        lda     $06B8,x
        sta     L5FFC
L6309:  rts

L630A:
        lda     L6142
        ldx     L6143
        jmp     L5EBB

L6313:  bit     L851C
        bmi     L62B9
        bit     L5FFF
        bmi     L6332
        pha
        ldx     L851D
        stx     $89
        lda     #$00
        sta     L0088
        lda     (L0088),y
        sta     L0088
        pla
        ldy     L851E
        jmp     (L0088)

L6332:  jmp     (L6000)

L6335:  .byte   $00
L6336:  .byte   $00
L6337:  .byte   $00
L6338:  .byte   $00
L6339:  .byte   $00
L633A:  .byte   $00
L633B:  .byte   $00
L633C:  .byte   $00
L633D:  .byte   $00
L633E:  .byte   $00
L633F:  .byte   $00
L6340:  .byte   $00

L6341:
        php
        pla
        sta     L6340
        ldx     #$04
L6348:  lda     L0082,x
        sta     L6335,x
        dex
        bpl     L6348
        lda     #$7F
        sta     L5F3F
        lda     $87
        sta     L5F40
        lda     L0088
        sta     L5F41
        lda     $89
        sta     L6835
        lda     $8A
        sta     L6836
        lda     $8B
        sta     L633B
        lda     $8C
        sta     L633C
        jsr     L646F
        jsr     L6491
        ldy     #$02
        lda     ($87),y
        tax
        stx     L6822
        dex
        stx     L78CB
        inx
        inx
        inx
        stx     fill_rect_params2_height
        inx
        stx     L78CD
        stx     test_box_params_bottom
        stx     test_box_params2_top
        stx     fill_rect_params4_top
        inx
        stx     set_box_params_top
        stx     L78CF
        stx     L6594
        stx     fill_rect_params_top
        dex
        stx     L6847
        clc
        ldy     #$00
L63AC:  txa
        adc     L6847,y
        iny
        sta     L6847,y
        cpy     #$0E
        bcc     L63AC
        lda     #$01
        sta     L5FFD
        lda     #$00
        sta     L5FFE
        bit     L6336
        bvs     L63D1
        lda     #$02
        sta     L5FFD
        lda     #$01
        sta     L5FFE
L63D1:  ldx     L6338
        jsr     L84BD
        bit     L6338
        bpl     L63F6
        cpx     #$00
        bne     L63E5
        lda     #$92
        jmp     L40B1

L63E5:  lda     L6338
        and     #$7F
        beq     L63F6
        cpx     L6338
        beq     L63F6
        lda     #$91
        jmp     L40B1

L63F6:  stx     L6338
        lda     #$80
        sta     L633F
        lda     L6338
        bne     L640D
        bit     L6339
        bpl     L640D
        lda     #$00
        sta     L6339
L640D:  ldy     #$03
        lda     L6338
        sta     ($80),y
        iny
        lda     L6339
        sta     ($80),y
        bit     L6339
        bpl     L642A
        bit     L6337
        bpl     L642A
        jsr     MLI
        .byte   $40
        .addr   L6469
L642A:  lda     $FBB3
        pha
        lda     #$06
        sta     $FBB3
        ldy     #$12
        lda     #$01
        bit     L6339
        bpl     L643F
        cli
        ora     #$08
L643F:  jsr     L6313
        pla
        sta     $FBB3
        jsr     L5E51
        jsr     L6067
        jsr     L67D8
        lda     #$00
        sta     L700C
L6454:  jsr     L653F
        jsr     L6588
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern
        A2D_CALL A2D_FILL_RECT, fill_rect_params
        jmp     L6556

L6469:  .byte   $02
L646A:  .byte   0
        sed
        .byte   $66

.proc dealloc_interrupt_params
count:  .byte   1
int_num:.byte   0
.endproc

L646F:
        lda     #$00
        sta     L633A
        lda     L6339
        beq     L648B
        cmp     #$01
        beq     L6486
        cmp     #$03
        bne     L648C
        lda     #$80
        sta     L633A
L6486:  lda     #$80
        sta     L6339
L648B:  rts

L648C:  lda     #$93
        jmp     L40B1

L6491:
        lda     L6337
        beq     L649F
        cmp     #$01
        beq     L64A4
        lda     #$90
        jmp     L40B1

L649F:  lda     #$80
        sta     L6337
L64A4:  rts

L64A5:
        ldy     #$12
        lda     #$00
        jsr     L6313
        ldy     #$13
        jsr     L6313
        bit     L6339
        bpl     L64C7
        bit     L6337
        bpl     L64C7
        lda     L646A
        sta     dealloc_interrupt_params::int_num
        MLI_CALL DEALLOC_INTERRUPT, dealloc_interrupt_params
L64C7:  lda     L6340
        pha
        plp
        lda     #$00
        sta     L633F
        rts

L64D2:
        lda     L0082
        cmp     #$01
        bne     L64E5
        lda     $84
        bne     L64F6
        sta     L6522
        lda     L0083
        sta     L6521
        rts

L64E5:  cmp     #$02
        bne     L6508
        lda     $84
        bne     L64FF
        sta     L6538
        lda     L0083
        sta     L6537
        rts

L64F6:  lda     #$00
        sta     L6521
        sta     L6522
        rts

L64FF:  lda     #$00
        sta     L6537
        sta     L6538
        rts

L6508:  lda     #$94
        jmp     L40B1

L650D:  lda     L6522
        beq     L651D
        jsr     L653F
        jsr     L651E
        php
        jsr     L6556
        plp
L651D:  rts

L651E:  jmp     (L6521)

L6521:  .byte   0
L6522:  .byte   0
L6523:  lda     L6538
        beq     L6533
        jsr     L653F
        jsr     L6534
        php
        jsr     L6556
        plp
L6533:  rts

L6534:  jmp     (L6537)

L6537:  .byte   $00
L6538:  .byte   $00
L6539:  .byte   $00
L653A:  .byte   $00
L653B:  .byte   $00

L653C:  jsr     HIDE_CURSOR_IMPL
L653F:  lda     $80
        sta     L6539
        lda     $81
        sta     L653A
        lda     L5F1D
        sta     L653B
        lsr     L5F1B
        rts

L6553:  jsr     SHOW_CURSOR_IMPL
L6556:  asl     L5F1B
        lda     L6539
        sta     $80
        lda     L653A
        sta     $81
        lda     $F4
L6566           := * + 1
        ldx     $F5
L6567:  sta     L0082
        stx     L0083
        lda     L653B
        sta     L5F1D
        ldy     #$23
L6573:  lda     (L0082),y
        sta     $D0,y
        dey
        bpl     L6573
        jmp     L5EA4

L657E:  lda     L6586
        ldx     L6587
        bne     L6567
L6586:
L6587           := * + 1
L6588           := * + 2
        asl     $205F,x
        ror     $2065,x
        .byte   0
        rti

        .byte   $06
        .addr   L6592
        rts

L6592:  .byte   $00,$00
L6594:  .byte   $0D,$00,$00,$20,$80,$00

.proc fill_rect_params
left:   .word   0
top:    .word   0
right:  .word   559
bottom: .word   191
.endproc
        fill_rect_params_top := fill_rect_params::top

        .byte   $00,$00,$00,$00,$00,$00,$00,$00

checkerboard_pattern:
        .byte   $55,$AA,$55,$AA,$55,$AA,$55,$AA
        .byte   $00

L65B3:
        bit     $633F
        bmi     L65CD
        lda     $82
        sta     L6000
        lda     L0083
        sta     L6001
        lda     L65D2
        ldx     L65D3
        ldy     #$02
        jmp     L5EBD

L65CD:  lda     #$95
        jmp     L40B1

L65D2:  .byte   $F8
L65D3:  .byte   $5F

L65D4:
        clc
        bcc     L65D8

;;; ==================================================

GET_INPUT_IMPL:
        sec
L65D8:  php
        bit     L6339
        bpl     L65E1
        sei
        bmi     L65E4
L65E1:  jsr     L6663
L65E4:  jsr     L67FE
L65E7:  bcs     L6604
        plp
        php
        bcc     L65F0
        sta     L6752
L65F0:  tax
        ldy     #$00
L65F3:  lda     L6754,x
        sta     ($80),y
        inx
        iny
        cpy     #$04
        bne     L65F3
        lda     #$00
        sta     ($80),y
        beq     L6607
L6604:  jsr     L6645
L6607:  plp
        bit     L6339
        bpl     L660E
        cli
L660E:  rts

;;; ==================================================

SET_INPUT_IMPL:
        php
        sei
        lda     L0082
        bmi     L6626
        cmp     #$06
        bcs     L663B
        cmp     #$03
        beq     L6626
        ldx     L0083
        ldy     $84
        lda     $85
        jsr     L7E19
L6626:  jsr     L67E4
        bcs     L663F
        tax
        ldy     #$00
L662E:  lda     ($80),y
        sta     L6754,x
        inx
        iny
        cpy     #$04
        bne     L662E
        plp
        rts

L663B:  lda     #$98
        bmi     L6641
L663F:  lda     #$99
L6641:  plp
        jmp     L40B1

L6645:  lda     #$00
        bit     L5FFC
        bpl     L664E
        lda     #$04
L664E:  ldy     #$00
        sta     ($80),y
        iny
L6653:  lda     L5FF3,y
        sta     ($80),y
        iny
        cpy     #$05
        bne     L6653
        rts

L665E:  .byte   0
L665F:  .byte   0
L6660:  .byte   0
        .byte   0
L6662:  .byte   0

L6663:  bit     L6339
        bpl     L666D
        lda     #$97
        jmp     L40B1

L666D:  sec
        jsr     L650D
        bcc     L66EA
        lda     $C062
        asl     a
        lda     $C061
        and     #$80
        rol     a
        rol     a
        sta     L6662
        jsr     L7F66
        jsr     L6265
        lda     L5FFC
        asl     a
        eor     L5FFC
        bmi     L66B9
        bit     L5FFC
        bmi     L66EA
        bit     L6813
        bpl     L66B9
        lda     L7D74
        bne     L66B9
        lda     $C000
        bpl     L66EA
        and     #$7F
        sta     L665F
        bit     $C010
        lda     L6662
        sta     L6660
        lda     #$03
        sta     L665E
        bne     L66D8
L66B9:  bcc     L66C8
        lda     L6662
        beq     L66C4
        lda     #$05
        bne     L66CA
L66C4:  lda     #$01
        bne     L66CA
L66C8:  lda     #$02
L66CA:  sta     L665E
        ldx     #$02
L66CF:  lda     set_pos_params,x
        sta     L665F,x
        dex
        bpl     L66CF
L66D8:  jsr     L67E4
        tax
        ldy     #$00
L66DE:  lda     L665E,y
        sta     L6754,x
        inx
        iny
        cpy     #$04
        bne     L66DE
L66EA:  jmp     L6523

L66ED:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L66F6:  .byte   0
L66F7:  .byte   0
        cld
        lda     $C01C
        sta     L66F6
        lda     $C018
        sta     L66F7
        lda     $C054
        sta     $C001
        ldx     #$08
L670D:  lda     L0082,x
        sta     L66ED,x
        dex
        bpl     L670D
        ldy     #$13
        jsr     L6313
        bcs     L6720
        jsr     L666D
        clc
L6720:  bit     L633A
        bpl     L6726
        clc
L6726:  ldx     #$08
L6728:  lda     L66ED,x
        sta     L0082,x
        dex
        bpl     L6728
        lda     $C054
        sta     $C000
        lda     L66F6
        bpl     L673E
        lda     $C055
L673E:  lda     L66F7
        bpl     L6746
        sta     $C001
L6746:  rts

L6747:
        lda     L6750
        ldx     L6751
        jmp     L5EBB

L6750:  .byte   $F9
L6751:  .byte   $66
L6752:  .byte   $00
L6753:  .byte   $00
L6754:  .byte   $00
L6755:  .res    128, 0
        .byte   $00,$00,$00

L67D8:  php
        sei
        lda     #$00
        sta     L6752
        sta     L6753
        plp
        rts

L67E4:  lda     L6753
        cmp     #$80
        bne     L67EF
        lda     #$00
        bcs     L67F2
L67EF:  clc
        adc     #$04
L67F2:  cmp     L6752
        beq     L67FC
        sta     L6753
        clc
        rts

L67FC:  sec
        rts

L67FE:  .byte   $AD,$52,$67,$CD,$53,$67,$F0,$F6
        .byte   $C9,$80,$D0,$04,$A9,$00
        bcs     L6811
        clc
        adc     #$04
L6811:  clc
        rts

L6813:  .byte   $80
L6814:
        asl     L6813
        ror     L0082
        ror     L6813
        rts

L681D:  .byte   $02
L681E:  .byte   $09
L681F:  .byte   $10
L6820:  .byte   $09
L6821:  .byte   $1E
L6822:  .byte   $00
L6823:  .byte   $00
L6824:  .byte   $00

.proc test_box_params
left:   .word   $ffff
top:    .word   $ffff
right:  .word   $230
bottom: .word   $C
.endproc
        test_box_params_top := test_box_params::top
        test_box_params_bottom := test_box_params::bottom

.proc fill_rect_params2
left:   .word   0
top:    .word   0
width:  .word   0
height: .word   11
.endproc
        fill_rect_params2_height := fill_rect_params2::height

L6835:  .byte   $00
L6836:  .byte   $00

.proc test_box_params2
left:   .word   0
top:    .word   12
right:  .word   0
bottom: .word   0
.endproc
        test_box_params2_top := test_box_params2::top

.proc fill_rect_params4
left:   .word   0
top:    .word   12
right:  .word   0
bottom: .word   0
.endproc
        fill_rect_params4_top := fill_rect_params4::top

L6847:  .byte   $0C
L6848:  .byte   $18,$24,$30,$3C,$48,$54,$60,$6C
        .byte   $78,$84,$90,$9C,$A8,$B4
L6856:  .byte   $1E
L6857:  .byte   $1F
L6858:  .byte   $1D
L6859:  .byte   $01,$02
L685B:  .byte   $1E
L685C:  .byte   $FF,$01
L685E:  .byte   $1D
L685F:  .byte   $25
L6860:  .byte   $68
L6861:  .byte   $37
L6862:  pla
L6863:  .byte   $5D
L6864:  pla
L6865:  phy
L6866:  pla
L6867:  lda     L6823
        sta     L0082
        lda     L6824
        sta     L0083
        ldy     #$00
        lda     (L0082),y
        sta     $A8
        rts

L6878:  stx     $A7
        lda     #$02
        clc
L687D:  dex
        bmi     L6884
        adc     #$0C
        bne     L687D
L6884:  adc     L6823
        sta     $AB
        lda     L6824
        adc     #$00
        sta     $AC
        ldy     #$0B
L6892:  lda     ($AB),y
        sta     $AF,y
        dey
        bpl     L6892
        ldy     #$05
L689C:  lda     ($B3),y
        sta     $BA,y
        dey
        bne     L689C
        lda     ($B3),y
        sta     $AA
        rts

L68A9:  ldy     #$0B
L68AB:  lda     $AF,y
        sta     ($AB),y
        dey
        bpl     L68AB
        ldy     #$05
L68B5:  lda     $BA,y
        sta     ($B3),y
        dey
        bne     L68B5
        rts

L68BE:  stx     $A9
        lda     #$06
        clc
L68C3:  dex
        bmi     L68CA
        adc     #$06
        bne     L68C3
L68CA:  adc     $B3
        sta     $AD
        lda     $B4
        adc     #$00
        sta     $AE
        ldy     #$05
L68D6:  lda     ($AD),y
        sta     $BF,y
        dey
        bpl     L68D6
        rts

L68DF:  ldy     #$05
L68E1:  lda     $BF,y
        sta     ($AD),y
        dey
        bpl     L68E1
        rts

L68EA:  sty     $EC
        ldy     #$00
        sty     $ED
L68F0:  sta     $EA
        stx     $EB
        rts

L68F5:  sta     $F0
        jmp     SET_FILL_MODE_IMPL

L68FA:  jsr     L6906
        jmp     L58E8

L6900:  jsr     L6906
        jmp     DRAW_TEXT_IMPL

L6906:  sta     L0082
        stx     L0083
        clc
        adc     #$01
        bcc     L6910
        inx
L6910:  sta     $A1
        stx     $A2
        ldy     #$00
        lda     (L0082),y
        sta     $A3
        rts

L691B:  A2D_CALL A2D_GET_INPUT, L0082
        lda     L0082
        rts

L6924:  .byte   0
L6925:  .byte   0
L6926:
        lda     #$00
        sta     L633D
        sta     L633E
        lda     $80
        sta     L6823
        lda     $81
        sta     L6824
        jsr     L6867
        jsr     L653C
        jsr     L657E
        lda     L685F
        ldx     L6860
        jsr     L6A66
        lda     #$0C
        ldx     #$00
        ldy     L6822
        iny
        jsr     L68EA
        ldx     #$00
L6957:  jsr     L6878
        lda     $EA
        ldx     $EB
        sta     $B5
        stx     $B6
        sec
        sbc     #$08
        bcs     L6968
        dex
L6968:  sta     $B7
        stx     $B8
        sta     $BB
        stx     $BC
        ldx     #$00
        stx     $C5
        stx     $C6
L6976:  jsr     L68BE
        bit     $BF
        bvs     L69B4
        lda     $C3
        ldx     $C4
        jsr     L68FA
        sta     L0082
        stx     L0083
        lda     $BF
        and     #$03
        bne     L6997
        lda     $C1
        bne     L6997
        lda     L6820
        bne     L699A
L6997:  lda     L6821
L699A:  clc
        adc     L0082
        sta     L0082
        bcc     L69A3
        inc     L0083
L69A3:  sec
        sbc     $C5
        lda     L0083
        sbc     $C6
        bmi     L69B4
        lda     L0082
        sta     $C5
        lda     L0083
        sta     $C6
L69B4:  ldx     $A9
        inx
        cpx     $AA
        bne     L6976
        lda     $AA
        tax
        ldy     L6822
        iny
        iny
        iny
        jsr     L4F70
        pha
        lda     $C5
        sta     $A1
        lda     $C6
        sta     $A2
        lda     #$07
        sta     $A3
        lda     #$00
        sta     $A4
        jsr     L5698
        ldy     $A1
        iny
        iny
        pla
        tax
        jsr     L4F70
        sta     L6924
        sty     L6925
        sec
        sbc     L633D
        tya
        sbc     L633E
        bmi     L6A00
        lda     L6924
        sta     L633D
        lda     L6925
        sta     L633E
L6A00:  lda     $BB
        clc
        adc     $C5
        sta     $BD
        lda     $BC
        adc     #$00
        sta     $BE
        jsr     L68A9
        lda     $B1
        ldx     $B2
        jsr     L6900
        jsr     L6A5C
        lda     $EA
        ldx     $EB
        clc
        adc     #$08
        bcc     L6A24
        inx
L6A24:  sta     $B9
        stx     $BA
        jsr     L68A9
        lda     #$0C
        ldx     #$00
        jsr     L5758
        ldx     $A7
        inx
        cpx     $A8
        beq     L6A3C
        jmp     L6957

L6A3C:  lda     #$00
        sta     L7D7A
        sta     L7D7B
        jsr     L6553
        sec
        lda     L633B
        sbc     L633D
        lda     L633C
        sbc     L633E
        bpl     L6A5B
        lda     #$9C
        jmp     L40B1

L6A5B:  rts

L6A5C:  ldx     $A7
        jsr     L6878
        ldx     $A9
        jmp     L68BE

L6A66:  sta     L6A7B
        stx     L6A7B+1
        sta     L6A86
        stx     L6A86+1
        lda     #$00
        jsr     L68F5
        A2D_CALL A2D_FILL_RECT, 0, L6A7B
        lda     #$04
        jsr     L68F5
        A2D_CALL A2D_DRAW_RECT, 0, L6A86
        rts

L6A89:  jsr     L6A94
        bne     L6A93
        lda     #$9A
        jmp     L40B1

L6A93:  rts

L6A94:  lda     #$00
L6A96:  sta     $C6
        jsr     L6867
        ldx     #$00
L6A9D:  jsr     L6878
        bit     $C6
        bvs     L6ACA
        bmi     L6AAE
        lda     $AF
        cmp     L00C7
        bne     L6ACF
        beq     L6AD9
L6AAE:  lda     set_pos_params::xcoord
        ldx     set_pos_params::xcoord+1
        cpx     $B8
        bcc     L6ACF
        bne     L6ABE
        cmp     $B7
        bcc     L6ACF
L6ABE:  cpx     $BA
        bcc     L6AD9
        bne     L6ACF
        cmp     $B9
        bcc     L6AD9
        bcs     L6ACF
L6ACA:  jsr     L6ADC
        bne     L6AD9
L6ACF:  ldx     $A7
        inx
        cpx     $A8
        bne     L6A9D
        lda     #$00
        rts

L6AD9:  lda     $AF
        rts

L6ADC:  ldx     #$00
L6ADE:  jsr     L68BE
        ldx     $A9
        inx
        bit     $C6
        bvs     L6AFA
        bmi     L6AF0
        cpx     $C8
        bne     L6B16
        beq     L6B1C
L6AF0:  lda     L6847,x
        cmp     set_pos_params::ycoord
        bcs     L6B1C
        bcc     L6B16
L6AFA:  lda     $C9
        and     #$7F
        cmp     $C1
        beq     L6B06
        cmp     $C2
        bne     L6B16
L6B06:  cmp     #$20
        bcc     L6B1C
        lda     $BF
        and     #$C0
        bne     L6B16
        lda     $BF
        and     $CA
        bne     L6B1C
L6B16:  .byte   $E4
L6B17:  tax
        bne     L6ADE
        ldx     #$00
L6B1C:  rts

L6B1D:  lda     L00C7
        bne     L6B26
        lda     L6BD9
        sta     L00C7
L6B26:  jsr     L6A89
L6B29:  jsr     L653C
        jsr     L657E
        jsr     L6B35
        jmp     L6553

L6B35:  ldx     #$01
L6B37:  lda     $B7,x
        sta     fill_rect_params2::left,x
        lda     $B9,x
        sta     fill_rect_params2::width,x
        lda     $BB,x
        sta     test_box_params2::left,x
        sta     fill_rect_params4::left,x
        lda     $BD,x
        sta     test_box_params2::right,x
        sta     fill_rect_params4::right,x
        dex
        bpl     L6B37
        lda     #$02
        jsr     L68F5
        A2D_CALL A2D_FILL_RECT, fill_rect_params2
        rts

L6B60:
        lda     $C9
        cmp     #$1B
        bne     L6B70
        lda     $CA
        bne     L6B70
        jsr     L7D61
        jmp     L6BDB

L6B70:  lda     #$C0
        jsr     L6A96
        beq     L6B88
        lda     $B0
        bmi     L6B88
        lda     $BF
        and     #$C0
        bne     L6B88
        lda     $AF
        sta     L6BD9
        bne     L6B8B
L6B88:  lda     #$00
        tax
L6B8B:  ldy     #$00
        sta     ($80),y
        iny
        txa
        sta     ($80),y
        bne     L6B29
        rts

L6B96:  jsr     L6A89
        jsr     L6ADC
        cpx     #$00
L6B9E:  rts

L6B9F:  jsr     L6B96
        bne     L6B9E
        lda     #$9B
        jmp     L40B1

L6BA9:
        jsr     L6B9F
        asl     $BF
        ror     $C9
        ror     $BF
        jmp     L68DF

L6BB5:
        jsr     L6B9F
        lda     $C9
        beq     L6BC2
        lda     #$20
        ora     $BF
        bne     L6BC6
L6BC2:  lda     #$DF
        and     $BF
L6BC6:  sta     $BF
        jmp     L68DF

L6BCB:
        jsr     L6A89
        asl     $B0
        ror     $C8
        ror     $B0
        ldx     $A7
        jmp     L68A9

L6BD9:  .byte   0
L6BDA:  .byte   0
L6BDB:  jsr     L7ECD
        jsr     L6867
        jsr     L653F
        jsr     L657E
        bit     L7D74
        bpl     L6BF2
        jsr     L7FE1
        jmp     L6C23

L6BF2:  lda     #$00
        sta     L6BD9
        sta     L6BDA
        jsr     L691B
L6BFD:  bit     L7D81
        bpl     L6C05
        jmp     L8149

L6C05:  A2D_CALL A2D_SET_POS, L0083
        A2D_CALL A2D_TEST_BOX, test_box_params
        bne     L6C58
        lda     L6BD9
        beq     L6C23
        A2D_CALL A2D_TEST_BOX, test_box_params2
        bne     L6C73
        jsr     L6EA1
L6C23:  jsr     L691B
        beq     L6C2C
        cmp     #$02
        bne     L6BFD
L6C2C:  lda     L6BDA
        bne     L6C37
        jsr     L6D23
        jmp     L6C40

L6C37:  jsr     HIDE_CURSOR_IMPL
        jsr     L657E
        jsr     L6CF4
L6C40:  jsr     L6556
        lda     #$00
        ldx     L6BDA
        beq     L6C55
        lda     L6BD9
        ldy     $A7
        sty     L7D7A
        stx     L7D7B
L6C55:  jmp     L5EBB

L6C58:  jsr     L6EA1
        lda     #$80
        jsr     L6A96
        cmp     L6BD9
        beq     L6C23
        pha
        jsr     L6D23
        pla
        sta     L6BD9
        jsr     L6D26
        jmp     L6C23

L6C73:  lda     #$80
        sta     $C6
        jsr     L6ADC
        cpx     L6BDA
        beq     L6C23
        lda     $B0
        ora     $BF
        and     #$C0
        beq     L6C89
        ldx     #$00
L6C89:  txa
        pha
        jsr     L6EAA
        pla
        sta     L6BDA
        jsr     L6EAA
        jmp     L6C23

L6C98:  lda     $BC
        lsr     a
        lda     $BB
        ror     a
        tax
        lda     L4821,x
        sta     L0082
        lda     $BE
        lsr     a
        lda     $BD
        ror     a
        tax
        lda     L4821,x
        sec
        sbc     L0082
        sta     $90
        lda     L6835
        sta     $8E
        lda     L6836
        sta     $8F
        ldy     $AA
        ldx     L6847,y
        inx
        stx     L0083
        stx     fill_rect_params4::bottom
        stx     test_box_params2::bottom
        ldx     L6822
        inx
        inx
        inx
        stx     fill_rect_params4::top
        stx     test_box_params2::top
        rts

L6CD8:  lda     hires_table_lo,x
        clc
        adc     L0082
        sta     $84
        lda     hires_table_hi,x
        ora     #$20
        sta     $85
        rts

L6CE8:  lda     $8E
        sec
        adc     $90
        sta     $8E
        bcc     L6CF3
        inc     $8F
L6CF3:  rts

L6CF4:  jsr     L6C98
L6CF7:  jsr     L6CD8
        sta     $C055
        ldy     $90
L6CFF:  lda     ($8E),y
        sta     ($84),y
        dey
        bpl     L6CFF
        jsr     L6CE8
        sta     $C054
        ldy     $90
L6D0E:  lda     ($8E),y
        sta     ($84),y
        dey
        bpl     L6D0E
        jsr     L6CE8
        inx
        cpx     L0083
        bcc     L6CF7
        beq     L6CF7
        jmp     SHOW_CURSOR_IMPL

L6D22:  rts

L6D23:  clc
        bcc     L6D27
L6D26:  sec
L6D27:  lda     L6BD9
        beq     L6D22
        php
        sta     L00C7
        jsr     L6A94
        jsr     HIDE_CURSOR_IMPL
        jsr     L6B35
        plp
        bcc     L6CF4
        jsr     L6C98
L6D3E:  jsr     L6CD8
        sta     $C055
        ldy     $90
L6D46:  lda     ($84),y
        sta     ($8E),y
        dey
        bpl     L6D46
        jsr     L6CE8
        sta     $C054
        ldy     $90
L6D55:  lda     ($84),y
        sta     ($8E),y
        dey
        bpl     L6D55
        jsr     L6CE8
        inx
        cpx     L0083
        bcc     L6D3E
        beq     L6D3E
        jsr     L657E
        lda     L6861
        ldx     L6862
        jsr     L6A66
        inc     fill_rect_params4::left
        bne     L6D7A
        inc     fill_rect_params4::left+1
L6D7A:  lda     fill_rect_params4::right
        bne     L6D82
        dec     fill_rect_params4::right+1
L6D82:  dec     fill_rect_params4::right
        jsr     L6A5C
        ldx     #$00
L6D8A:  jsr     L68BE
        bit     $BF
        bvc     L6D94
        jmp     L6E18

L6D94:  lda     $BF
        and     #$20
        beq     L6DBD
        lda     L681D
        jsr     L6E25
        lda     L6858
        sta     L685E
        lda     $BF
        and     #$04
        beq     L6DB1
        lda     $C0
        sta     L685E
L6DB1:  lda     L6863
        ldx     L6864
        jsr     L6900
        jsr     L6A5C
L6DBD:  lda     L681E
        jsr     L6E25
        lda     $C3
        ldx     $C4
        jsr     L6900
        jsr     L6A5C
        lda     $BF
        and     #$03
        bne     L6DE0
        lda     $C1
        beq     L6E0A
        lda     L6859
        sta     L685B
        jmp     L6E0A

L6DE0:  cmp     #$01
        bne     L6DED
        lda     L6857
        sta     L685B
        jmp     L6DF3

L6DED:  lda     L6856
        sta     L685B
L6DF3:  lda     $C1
        sta     L685C
        lda     L681F
        jsr     L6E92
        lda     L6865
        ldx     L6866
        jsr     L6900
        jsr     L6A5C
L6E0A:  bit     $B0
        bmi     L6E12
        bit     $BF
        bpl     L6E18
L6E12:  jsr     L6E36
        jmp     L6E18

L6E18:  ldx     $A9
        inx
        cpx     $AA
        beq     L6E22
        jmp     L6D8A

L6E22:  jmp     SHOW_CURSOR_IMPL

L6E25:  ldx     $A9
        ldy     L6848,x
        dey
        ldx     $BC
        clc
        adc     $BB
        bcc     L6E33
        inx
L6E33:  jmp     L68EA

L6E36:  ldx     $A9
        lda     L6847,x
        sta     L6E8C
        inc     L6E8C
        lda     L6848,x
        sta     L6E90
        clc
        lda     $BB
        adc     #$05
        sta     L6E8A
        lda     $BC
        adc     #$00
        sta     L6E8B
        sec
        lda     $BD
        sbc     #$05
        sta     L6E8E
        lda     $BE
        sbc     #$00
        sta     L6E8F
        A2D_CALL A2D_SET_PATTERN, light_speckle_pattern
        lda     #$01
        jsr     L68F5
        A2D_CALL A2D_FILL_RECT, fill_rect_params3
        A2D_CALL A2D_SET_PATTERN, white_pattern
        lda     #$02
        jsr     L68F5
        rts

light_speckle_pattern:
        .byte   %10001000
        .byte   %01010101
        .byte   %10001000
        .byte   %01010101
        .byte   %10001000
        .byte   %01010101
        .byte   %10001000
        .byte   %01010101

fill_rect_params3:
L6E8A:  .byte   0
L6E8B:  .byte   0
L6E8C:  .byte   0
        .byte   0
L6E8E:  .byte   0
L6E8F:  .byte   0
L6E90:  .byte   0
        .byte   0
L6E92:  sta     L0082
        lda     $BD
        ldx     $BE
        sec
        sbc     L0082
        bcs     L6E9E
        dex
L6E9E:  jmp     L68F0

L6EA1:  jsr     L6EAA
        lda     #$00
        sta     L6BDA
L6EA9:  rts

L6EAA:  ldx     L6BDA
        beq     L6EA9
        ldy     fill_rect_params4::bottom+1,x ; ???
        iny
        sty     fill_rect_params4::top
        ldy     L6847,x
        sty     fill_rect_params4::bottom
        jsr     HIDE_CURSOR_IMPL
        lda     #$02
        jsr     L68F5
        A2D_CALL A2D_FILL_RECT, fill_rect_params4
        jmp     SHOW_CURSOR_IMPL

L6ECD:
        ldx     #$03
L6ECF:  lda     L0082,x
        sta     L6856,x
        dex
        bpl     L6ECF
        lda     L5F40
        sta     L0082
        lda     L5F41
        sta     L0083
        ldy     #$00
        lda     (L0082),y
        bmi     L6F02
        lda     #$02
        sta     L681D
        lda     #$09
        sta     L681E
        lda     #$10
        sta     L681F
        lda     #$09
        sta     L6820
        lda     #$1E
        sta     L6821
        bne     L6F1B
L6F02:  lda     #$02
        sta     L681D
        lda     #$10
        sta     L681E
        lda     #$1E
        sta     L681F
        lda     #$10
        sta     L6820
        lda     #$33
        sta     L6821
L6F1B:  rts

L6F1C:
        jsr     L6B9F
        lda     $C9
        beq     L6F30
        lda     #$04
        ora     $BF
        sta     $BF
        lda     $CA
        sta     $C0
        jmp     L68DF

L6F30:  lda     #$FB
        and     $BF
        sta     $BF
        jmp     L68DF

L6F39:  .byte   $00,$00
L6F3B:  .byte   $00,$00,$13,$0A,$61,$6F
L6F41:  .byte   $00,$00
L6F43:  .byte   $00
L6F44:  .byte   $00,$13,$0A,$82,$6F
L6F49:  .byte   $00,$00,$00,$00,$14,$09,$A3,$6F
L6F51:  .byte   $00
L6F52:  .byte   $00,$00,$00,$12,$09,$C1,$6F
L6F59:  .byte   $00,$00,$00,$00,$14,$0A,$E0,$6F
        .byte   $00,$00,$00,$00,$18,$00,$00,$66
        .byte   $00,$40,$01,$03,$30,$00,$0C,$7C
        .byte   $01,$3F,$40,$01,$03,$40,$01,$03
        .byte   $40,$7F,$03,$00,$00,$00,$7E,$7F
        .byte   $7F,$7E,$7F,$7F,$00,$00,$00,$40
        .byte   $7F,$03,$40,$01,$03,$40,$01,$03
        .byte   $7C,$01,$3F,$30,$00,$0C,$40,$01
        .byte   $03,$00,$66,$00,$00,$18,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$18,$40
        .byte   $00,$1E,$40,$40,$79,$4F,$30,$00
        .byte   $4C,$0C,$00,$4C,$30,$00,$4C,$40
        .byte   $79,$4F,$00,$1E,$40,$00,$18,$40
        .byte   $00,$00,$00,$01,$0C,$00,$01,$3C
        .byte   $00,$79,$4F,$01,$19,$00,$06,$19
        .byte   $00,$18,$19,$00,$06,$79,$4F,$01
        .byte   $01,$3C,$00,$01,$0C,$00,$00,$7F
        .byte   $7F,$7F,$01,$00,$40,$79,$3F,$40
        .byte   $19,$70,$4F,$19,$30,$4C,$19,$30
        .byte   $4C,$79,$3F,$4C,$61,$00,$4C,$61
        .byte   $7F,$4F,$01,$00,$40,$7F,$7F,$7F
L7001:  .byte   $39
L7002:  .byte   $6F
L7003:  .byte   $41
L7004:  .byte   $6F
L7005:  .byte   $49
L7006:  .byte   $6F
L7007:  .byte   $51
L7008:  .byte   $6F
L7009:  .byte   $59
L700A:  .byte   $6F
L700B:  .byte   $00
L700C:  .byte   $00
L700D:  .byte   $00
L700E:  .byte   $00
L700F:  .byte   $00
L7010:  .byte   $00
L7011:  .byte   $D3
L7012:  .byte   $6F
L7013:  lda     L7011
        sta     $A7
        lda     L7012
        sta     $A8
        lda     L700B
        ldx     L700C
        bne     L7038
L7025:  rts

L7026:  lda     $A9
        sta     $A7
        lda     $AA
        sta     $A8
        ldy     #$39
        lda     ($A9),y
        beq     L7025
        tax
        dey
        lda     ($A9),y
L7038:  sta     L700E
        stx     L700F
L703E:  lda     L700E
        ldx     L700F
L7044:  sta     $A9
        stx     $AA
        ldy     #$0B
L704A:  lda     ($A9),y
        sta     $AB,y
        dey
        bpl     L704A
        ldy     #$23
L7054:  lda     ($A9),y
        sta     $A3,y
        dey
        cpy     #$13
        bne     L7054
L705E:  lda     $A9
        ldx     $AA
        rts

L7063:  jsr     L7013
        beq     L7073
L7068:  lda     $AB
        cmp     L0082
        beq     L705E
        jsr     L7026
        bne     L7068
L7073:  rts

L7074:  jsr     L7063
        beq     L707A
        rts

L707A:  lda     #$9F
        jmp     L40B1

L707F:  A2D_CALL A2D_DRAW_RECT, L00C7
        rts

L7086:  A2D_CALL A2D_TEST_BOX, L00C7
        rts

L708D:  ldx     #$03
L708F:  lda     $B7,x
        sta     L00C7,x
        dex
        bpl     L708F
        ldx     #$02
L7098:  lda     $C3,x
        sec
        sbc     $BF,x
        tay
        lda     $C4,x
        sbc     $C0,x
        pha
        tya
        clc
        adc     L00C7,x
        sta     $CB,x
        pla
        adc     $C8,x
        sta     $CC,x
        dex
        dex
        bpl     L7098
L70B2:  lda     #$C7
        ldx     #$00
        rts

L70B7:  jsr     L708D
        lda     L00C7
        bne     L70C0
        dec     $C8
L70C0:  dec     L00C7
        bit     $B0
        bmi     L70D0
        lda     $AC
        and     #$04
        bne     L70D0
        lda     #$01
        bne     L70D2
L70D0:  lda     #$15
L70D2:  clc
        adc     $CB
        sta     $CB
        bcc     L70DB
        inc     $CC
L70DB:  lda     #$01
        bit     $AF
        bpl     L70E3
        lda     #$0B
L70E3:  clc
        adc     $CD
        sta     $CD
        bcc     L70EC
        inc     $CE
L70EC:  lda     #$01
        and     $AC
        bne     L70F5
        lda     L78CF
L70F5:  sta     L0082
        lda     $C9
        sec
        sbc     L0082
        sta     $C9
        bcs     L70B2
        dec     $CA
        bcc     L70B2
L7104:  jsr     L70B7
        lda     $CB
        ldx     $CC
        sec
        sbc     #$14
        bcs     L7111
        dex
L7111:  sta     L00C7
        stx     $C8
        lda     $AC
        and     #$01
        bne     L70B2
        lda     $C9
        clc
        adc     L78CD
        sta     $C9
        bcc     L70B2
        inc     $CA
        bcs     L70B2
L7129:  jsr     L70B7
L712C:  lda     $CD
        ldx     $CE
        sec
        sbc     #$0A
        bcs     L7136
        dex
L7136:  sta     $C9
        stx     $CA
        jmp     L70B2

L713D:  jsr     L7104
        jmp     L712C

L7143:  jsr     L70B7
        lda     $C9
        clc
        adc     L78CD
        sta     $CD
        lda     $CA
        adc     #$00
        sta     $CE
        jmp     L70B2

L7157:  jsr     L7143
        lda     L00C7
        ldx     $C8
        clc
        adc     #$0C
        bcc     L7164
        inx
L7164:  sta     L00C7
        stx     $C8
        clc
        adc     #$0E
        bcc     L716E
        inx
L716E:  sta     $CB
        stx     $CC
        lda     $C9
        ldx     $CA
        clc
        adc     #$02
        bcc     L717C
        inx
L717C:  sta     $C9
        stx     $CA
        clc
        adc     L78CB
        bcc     L7187
        inx
L7187:  sta     $CD
        stx     $CE
        jmp     L70B2

L718E:  jsr     L70B7
        jsr     L6A66
        lda     $AC
        and     #$01
        bne     L71AA
        jsr     L7143
        jsr     L6A66
        jsr     L73BF
        lda     $AD
        ldx     $AE
        jsr     L6900
L71AA:  jsr     L703E
        bit     $B0
        bpl     L71B7
        jsr     L7104
        jsr     L707F
L71B7:  bit     $AF
        bpl     L71C1
        jsr     L7129
        jsr     L707F
L71C1:  lda     $AC
        and     #$04
        beq     L71D3
        jsr     L713D
        jsr     L707F
        jsr     L7104
        jsr     L707F
L71D3:  jsr     L703E
        lda     $AB
        cmp     L700D
        bne     L71E3
        jsr     L6588
        jmp     L720B

L71E3:  rts

        ;;  Drawing title bar, maybe?
L71E4:  .byte   $01
stripes_pattern:
stripes_pattern_alt := *+1
        .byte   $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF
L71EE:  jsr     L7157
        lda     $C9
        and     #$01
        beq     L71FE
        A2D_CALL A2D_SET_PATTERN, stripes_pattern
        rts

L71FE:  A2D_CALL A2D_SET_PATTERN, stripes_pattern_alt
        rts

L7205:  lda     #$01
        ldx     #$00
        beq     L720F
L720B:  lda     #$03
        ldx     #$01
L720F:  stx     L71E4
        jsr     L68F5
        lda     $AC
        and     #$02
        beq     L7255
        lda     $AC
        and     #$01
        bne     L7255
        jsr     L7157
        jsr     L707F
        jsr     L71EE
        lda     L00C7
        ldx     $C8
        sec
        sbc     #$09
        bcs     L7234
        dex
L7234:  sta     $92
        stx     $93
        clc
        adc     #$06
        bcc     L723E
        inx
L723E:  sta     $96
        stx     $97
        lda     $C9
        sta     $94
        lda     $CA
        sta     $95
        lda     $CD
        sta     $98
        lda     $CE
        sta     $99
        jsr     FILL_RECT_IMPL
L7255:  lda     $AC
        and     #$01
        bne     L72C9
        jsr     L7143
        jsr     L73BF
        jsr     L5907
        jsr     L71EE
        lda     $CB
        ldx     $CC
        clc
        adc     #$03
        bcc     L7271
        inx
L7271:  tay
        lda     $AC
        and     #$02
        bne     L7280
        tya
        sec
        sbc     #$1A
        bcs     L727F
        dex
L727F:  tay
L7280:  tya
        ldy     $96
        sty     $CB
        ldy     $97
        sty     $CC
        ldy     $92
        sty     $96
        ldy     $93
        sty     $97
        sta     $92
        stx     $93
        lda     $96
        sec
        sbc     #$0A
        sta     $96
        bcs     L72A0
        dec     $97
L72A0:  jsr     FILL_RECT_IMPL
        lda     $CB
        clc
        adc     #$0A
        sta     $92
        lda     $CC
        adc     #$00
        sta     $93
        jsr     L7143
        lda     $CB
        sec
        sbc     #$03
        sta     $96
        lda     $CC
        sbc     #$00
        sta     $97
        jsr     FILL_RECT_IMPL
        A2D_CALL A2D_SET_PATTERN, white_pattern
L72C9:  jsr     L703E
        bit     $B0
        bpl     L7319
        jsr     L7104
        ldx     #$03
L72D5:  lda     L00C7,x
        sta     L6F39,x
        sta     L6F41,x
        dex
        bpl     L72D5
        inc     L6F3B
        lda     $CD
        ldx     $CE
        sec
        sbc     #$0A
        bcs     L72ED
        dex
L72ED:  pha
        lda     $AC
        and     #$04
        bne     L72F8
        bit     $AF
        bpl     L7300
L72F8:  pla
        sec
        sbc     #$0B
        bcs     L72FF
        dex
L72FF:  pha
L7300:  pla
        sta     L6F43
        stx     L6F44
        lda     L7003
        ldx     L7004
        jsr     L791C
        lda     L7001
        ldx     L7002
        jsr     L791C
L7319:  bit     $AF
        bpl     L7363
        jsr     L7129
        ldx     #$03
L7322:  lda     L00C7,x
        sta     L6F49,x
        sta     L6F51,x
        dex
        bpl     L7322
        lda     $CB
        ldx     $CC
        sec
        sbc     #$14
        bcs     L7337
        dex
L7337:  pha
        lda     $AC
        and     #$04
        bne     L7342
        bit     $B0
        bpl     L734A
L7342:  pla
        sec
        sbc     #$15
        bcs     L7349
        dex
L7349:  pha
L734A:  pla
        sta     L6F51
        stx     L6F52
        lda     L7007
        ldx     L7008
        jsr     L791C
        lda     L7005
        ldx     L7006
        jsr     L791C
L7363:  lda     #$00
        jsr     L68F5
        lda     $B0
        and     #$01
        beq     L737B
        lda     #$80
        sta     $8C
        lda     L71E4
        jsr     L79A0
        jsr     L703E
L737B:  lda     $AF
        and     #$01
        beq     L738E
        lda     #$00
        sta     $8C
        lda     L71E4
        jsr     L79A0
        jsr     L703E
L738E:  lda     $AC
        and     #$04
        beq     L73BE
        jsr     L713D
        lda     L71E4
        bne     L73A6
        lda     #$C7
        ldx     #$00
        jsr     L6A66
        jmp     L73BE

L73A6:  ldx     #$03
L73A8:  lda     L00C7,x
        sta     L6F59,x
        dex
        bpl     L73A8
        lda     #$04
        jsr     L68F5
        lda     L7009
        ldx     L700A
        jsr     L791C
L73BE:  rts

L73BF:  lda     $AD
        ldx     $AE
        jsr     L68FA
        sta     L0082
        stx     L0083
        lda     L00C7
        clc
        adc     $CB
        tay
        lda     $C8
        adc     $CC
        tax
        tya
        sec
        sbc     L0082
        tay
        txa
        sbc     L0083
        cmp     #$80
        ror     a
        sta     $EB
        tya
        ror     a
        sta     $EA
        lda     $CD
        ldx     $CE
        sec
        sbc     #$02
        bcs     L73F0
        dex
L73F0:  sta     $EC
        stx     $ED
        lda     L0082
        ldx     L0083
        rts

;;; ==================================================

QUERY_TARGET_IMPL:
        jsr     L653F
        A2D_CALL A2D_TEST_BOX, test_box_params
        beq     L7416
        lda     #$01
L7406:  ldx     #$00
L7408:  pha
        txa
        pha
        jsr     L6556
        pla
        tax
        pla
        ldy     #$04
        jmp     L5EBD

L7416:  lda     #$00
        sta     L747A
        jsr     L7013
        beq     L7430
L7420:  jsr     L70B7
        jsr     L7086
        bne     L7434
        jsr     L7026
        stx     L747A
        bne     L7420
L7430:  lda     #$00
        beq     L7406
L7434:  lda     $AC
        and     #$01
        bne     L745D
        jsr     L7143
        jsr     L7086
        beq     L745D
        lda     L747A
        bne     L7459
        lda     $AC
        and     #$02
        beq     L7459
        jsr     L7157
        jsr     L7086
        beq     L7459
        lda     #$05
        bne     L7472
L7459:  lda     #$03
        bne     L7472
L745D:  lda     L747A
        bne     L7476
        lda     $AC
        and     #$04
        beq     L7476
        jsr     L713D
        jsr     L7086
        beq     L7476
        lda     #$04
L7472:  ldx     $AB
        bne     L7408
L7476:  lda     #$02
        bne     L7472

;;; ==================================================

L747A:  .byte   0
CREATE_WINDOW_IMPL:
        lda     $80
        sta     $A9
        lda     $81
        sta     $AA
        ldy     #$00
        lda     ($A9),y
        bne     L748E
        lda     #$9E
        jmp     L40B1

L748E:  sta     L0082
        jsr     L7063
        beq     L749A
        lda     #$9D
        jmp     L40B1

L749A:  lda     $80
        sta     $A9
        lda     $81
        sta     $AA
        ldy     #$0A
        lda     ($A9),y
        ora     #$80
        sta     ($A9),y
        bmi     L74BD

L74AC:
        jsr     L7074
        cmp     L700B
        bne     L74BA
        cpx     L700C
        bne     L74BA
        rts

L74BA:  jsr     L74F4
L74BD:  ldy     #$38
        lda     L700B
        sta     ($A9),y
        iny
        lda     L700C
        sta     ($A9),y
        lda     $A9
        pha
        lda     $AA
        pha
        jsr     L653C
        jsr     L6588
        jsr     L7013
        beq     L74DE
        jsr     L7205
L74DE:  pla
        sta     L700C
        pla
        sta     L700B
        jsr     L7013
        lda     $AB
        sta     L700D
        jsr     L718E
        jmp     L6553

L74F4:  ldy     #$38
        lda     ($A9),y
        sta     ($A7),y
        iny
        lda     ($A9),y
        sta     ($A7),y
        rts

L7500:
        jsr     L7074
        lda     $A9
        ldx     $AA
        ldy     #$01
        jmp     L5EBD

L750C:  .byte   $00
L750D:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00

L7532:
        jsr     L7074
        lda     $AB
        cmp     L7010
        bne     L753F
        inc     L7871
L753F:  jsr     L653C
        jsr     L6588
        lda     L7871
        bne     L7550
        A2D_CALL A2D_SET_BOX, set_box_params
L7550:  jsr     L718E
        jsr     L6588
        lda     L7871
        bne     L7561
        A2D_CALL A2D_SET_BOX, set_box_params
L7561:  jsr     L703E
        lda     $F4
        sta     L750C
        lda     $F5
        sta     L750D
        jsr     L75C6
        php
        lda     L758A
        ldx     L758B
        jsr     L5EA0
        asl     L5F1B
        plp
        bcc     L7582
        rts

L7582:  jsr     L758C
L7585:  lda     #$A3
        jmp     L40B1

L758A:  .byte   $0E
L758B:  .byte   $75
L758C:  jsr     SHOW_CURSOR_IMPL
        lda     L750C
        ldx     L750D
        sta     $F4
        stx     $F5
        jmp     L6567

;;; ==================================================

QUERY_STATE_IMPL:
        jsr     L40C8
        jsr     L7074
        lda     L0083
        sta     $80
        lda     $84
        sta     $81
        ldx     #$07
L75AC:  lda     fill_rect_params,x
        sta     $D8,x
        dex
        bpl     L75AC
        jsr     L75C6
        bcc     L7585
        ldy     #$23
L75BB:  lda     $D0,y
        sta     ($80),y
        dey
        bpl     L75BB
        jmp     L40BD

L75C6:  jsr     L708D
        ldx     #$07
L75CB:  lda     #$00
        sta     $9B,x
        lda     L00C7,x
        sta     $92,x
        dex
        bpl     L75CB
        jsr     L50A9
        bcs     L75DC
        rts

L75DC:  ldy     #$14
L75DE:  lda     ($A9),y
        sta     $BC,y
        iny
        cpy     #$38
        bne     L75DE
        ldx     #$02
L75EA:  lda     $92,x
        sta     $D0,x
        lda     $93,x
        sta     $D1,x
        lda     $96,x
        sec
        sbc     $92,x
        sta     L0082,x
        lda     $97,x
        sbc     $93,x
        sta     L0083,x
        lda     $D8,x
        sec
        sbc     $9B,x
        sta     $D8,x
        lda     $D9,x
        sbc     $9C,x
        sta     $D9,x
        lda     $D8,x
        clc
        adc     L0082,x
        sta     $DC,x
        lda     $D9,x
        adc     L0083,x
        sta     $DD,x
        dex
        dex
        bpl     L75EA
        sec
        rts
L761F:
        jsr     L7074
        lda     $A9
        clc
        adc     #$14
        sta     $A9
        bcc     L762D
        inc     $AA
L762D:  ldy     #$23
L762F:  lda     (L0082),y
        sta     ($A9),y
        dey
        cpy     #$10
        bcs     L762F
        rts

L7639:
        jsr     L7013
        beq     L7642
        lda     $AB
        bne     L7644
L7642:  lda     #$00
L7644:  ldy     #$00
        sta     ($80),y
        rts

;;; ==================================================

L7649:  .byte   0
CLOSE_CLICK_IMPL:
        jsr     L7013
        beq     L7697
        jsr     L7157
        jsr     L653F
        jsr     L6588
        lda     #$80
L765A:  sta     L7649
        lda     #$02
        jsr     L68F5
        jsr     HIDE_CURSOR_IMPL
        A2D_CALL A2D_FILL_RECT, L00C7
        jsr     SHOW_CURSOR_IMPL
L766E:  jsr     L691B
        cmp     #$02
        beq     L768B
        A2D_CALL A2D_SET_POS, set_pos_params
        jsr     L7086
        eor     L7649
        bpl     L766E
        lda     L7649
        eor     #$80
        jmp     L765A

L768B:  jsr     L6556
        ldy     #$00
        lda     L7649
        beq     L7697
        lda     #$01
L7697:  sta     ($80),y
        rts

        .byte   $00
L769B:  .byte   $00
L769C:  .byte   $00
L769D:  .byte   $00
L769E:  .byte   $00
L769F:  .byte   $00
L76A0:  .byte   $00,$00,$00
L76A3:  .byte   $00
L76A4:  .byte   $00,$00,$00
L76A7:  .byte   $00

;;; ==================================================

DRAG_RESIZE_IMPL:
        lda     #$80
        bmi     L76AE

;;; ==================================================

DRAG_WINDOW_IMPL:
        lda     #$00
L76AE:  sta     L76A7
        jsr     L7ECD
        ldx     #$03
L76B6:  lda     L0083,x
        sta     L769B,x
        sta     L769F,x
        lda     #$00
        sta     L76A3,x
        dex
        bpl     L76B6
        jsr     L7074
        bit     L7D74
        bpl     L76D1
        jsr     L817C
L76D1:  jsr     L653C
        jsr     L784C
        lda     #$02
        jsr     L68F5
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern
L76E2:  jsr     L703E
        jsr     L7749
        jsr     L70B7
        jsr     L707F
        jsr     SHOW_CURSOR_IMPL
L76F1:  jsr     L691B
        cmp     #$02
        bne     L773B
        jsr     L707F
        bit     L7D81
        bmi     L770A
        ldx     #$03
L7702:  lda     L76A3,x
        bne     L7714
        dex
        bpl     L7702
L770A:  jsr     L6553
        lda     #$00
L770F:  ldy     #$05
        sta     ($80),y
        rts

L7714:  ldy     #$14
L7716:  lda     $A3,y
        sta     ($A9),y
        iny
        cpy     #$24
        bne     L7716
        jsr     HIDE_CURSOR_IMPL
        lda     $AB
        jsr     L7872
        jsr     L653C
        bit     L7D81
        bvc     L7733
        jsr     L8347
L7733:  jsr     L6553
        lda     #$80
        jmp     L770F

L773B:  jsr     L77E0
        beq     L76F1
        jsr     HIDE_CURSOR_IMPL
        jsr     L707F
        jmp     L76E2

L7749:  ldy     #$13
L774B:  lda     ($A9),y
        sta     $BB,y
        dey
        cpy     #$0B
        bne     L774B
        ldx     #$00
        stx     set_input_params_unk
        bit     L76A7
        bmi     L777D
L775F:  lda     $B7,x
        clc
        adc     L76A3,x
        sta     $B7,x
        lda     $B8,x
        adc     L76A4,x
        sta     $B8,x
        inx
        inx
        cpx     #$04
        bne     L775F
        lda     #$12
        cmp     $B9
        bcc     L777C
        sta     $B9
L777C:  rts

L777D:  lda     #$00
        sta     L83F5
L7782:  clc
        lda     $C3,x
        adc     L76A3,x
        sta     $C3,x
        lda     $C4,x
        adc     L76A4,x
        sta     $C4,x
        sec
        lda     $C3,x
        sbc     $BF,x
        sta     L0082
        lda     $C4,x
        sbc     $C0,x
        sta     L0083
        sec
        lda     L0082
        sbc     L00C7,x
        lda     L0083
        sbc     $C8,x
        bpl     L77BC
        clc
        lda     L00C7,x
        adc     $BF,x
        sta     $C3,x
        lda     $C8,x
        adc     $C0,x
        sta     $C4,x
        jsr     L83F6
        jmp     L77D7

L77BC:  sec
        lda     $CB,x
        sbc     L0082
        lda     $CC,x
        sbc     L0083
        bpl     L77D7
        clc
        lda     $CB,x
        adc     $BF,x
        sta     $C3,x
        lda     $CC,x
        adc     $C0,x
        sta     $C4,x
        jsr     L83F6
L77D7:  inx
        inx
        cpx     #$04
        bne     L7782
        jmp     L83FC

L77E0:  ldx     #$02
        ldy     #$00
L77E4:  lda     $84,x
        cmp     L76A0,x
        bne     L77EC
        iny
L77EC:  lda     L0083,x
        cmp     L769F,x
        bne     L77F4
        iny
L77F4:  sta     L769F,x
        sec
        sbc     L769B,x
        sta     L76A3,x
        lda     $84,x
        sta     L76A0,x
        sbc     L769C,x
        sta     L76A4,x
        dex
        dex
        bpl     L77E4
        cpy     #$04
        bne     L7814
        lda     set_input_params_unk
L7814:  rts

;;; ==================================================

DESTROY_WINDOW_IMPL:
        jsr     L7074
        jsr     L653C
        jsr     L784C
        jsr     L74F4
        ldy     #$0A
        lda     ($A9),y
        and     #$7F
        sta     ($A9),y
        jsr     L7013
        lda     $AB
        sta     L700D
        lda     #$00
        jmp     L7872

L7836:  jsr     L7013
        beq     L7849
        ldy     #$0A
        lda     ($A9),y
        and     #$7F
        sta     ($A9),y
        jsr     L74F4
        jmp     L7836

L7849:  jmp     L6454

L784C:  jsr     L6588
        jsr     L70B7
        ldx     #$07
L7854:  lda     L00C7,x
        sta     $92,x
        dex
        bpl     L7854
        jsr     L50A9
        ldx     #$03
L7860:  lda     $92,x
        sta     set_box_params_box,x
        sta     set_box_params,x
        lda     $96,x
        sta     set_box_params_size,x
        dex
        bpl     L7860
        rts

L7871:  .byte   0
L7872:  sta     L7010
        lda     #$00
        sta     L7871
        A2D_CALL A2D_SET_BOX, set_box_params
        lda     #$00
        jsr     L68F5
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern
        A2D_CALL A2D_FILL_RECT, set_box_params_box
        jsr     L6553
        jsr     L7013
        beq     L78CA
        php
        sei
        jsr     L67D8
L789E:  jsr     L7026
        bne     L789E
L78A3:  jsr     L67E4
        bcs     L78C9
        tax
        lda     #$06
        sta     L6754,x
        lda     $AB
        sta     L6755,x
        lda     $AB
        cmp     L700D
        beq     L78C9
        sta     L0082
        jsr     L7063
        lda     $A7
        ldx     $A8
        jsr     L7044
        jmp     L78A3

L78C9:  plp
L78CA:  rts

L78CB:  .byte   $08,$00
L78CD:  .byte   $0C,$00
L78CF:  .byte   $0D,$00

.proc set_box_params
left:   .word   0
top:    .word   $D
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoffset:.word   0
voffset:.word   0
width:  .word   0
height: .word   0
.endproc
        set_box_params_top  := set_box_params::top
        set_box_params_size := set_box_params::width
        set_box_params_box  := set_box_params::hoffset ; Re-used since h/voff are 0

L78E1:
        jsr     L7074
        ldx     #$02
L78E6:  lda     L0083,x
        clc
        adc     $B7,x
        sta     L0083,x
        lda     $84,x
        adc     $B8,x
        sta     $84,x
        dex
        dex
        bpl     L78E6
        bmi     L790F

;;; ==================================================

MAP_COORDS_IMPL:
        jsr     L7074
        ldx     #$02
L78FE:  lda     L0083,x
        sec
        sbc     $B7,x
        sta     L0083,x
        lda     $84,x
        sbc     $B8,x
        sta     $84,x
        dex
        dex
        bpl     L78FE
L790F:  ldy     #$05
L7911:  lda     $7E,y
        sta     ($80),y
        iny
        cpy     #$09
        bne     L7911
        rts

L791C:  sta     L0082
        stx     L0083
        ldy     #$03
L7922:  lda     #$00
        sta     $8A,y
        lda     (L0082),y
        sta     $92,y
        dey
        bpl     L7922
        iny
        sty     $91
        ldy     #$04
        lda     (L0082),y
        tax
        lda     L4828,x
        sta     $90
        txa
        ldx     $93
        clc
        adc     $92
        bcc     L7945
        inx
L7945:  sta     $96
        stx     $97
        iny
        lda     (L0082),y
        ldx     $95
        clc
        adc     $94
        bcc     L7954
        inx
L7954:  sta     $98
        stx     $99
        iny
        lda     (L0082),y
        sta     $8E
        iny
        lda     (L0082),y
        sta     $8F
        jmp     L51B3

L7965:
        lda     $8C
        cmp     #$01
        bne     L7971
        lda     #$80
        sta     $8C
        bne     L797C
L7971:  cmp     #$02
        bne     L797B
        lda     #$00
        sta     $8C
        beq     L797C
L797B:  rts

L797C:  jsr     L653C
        jsr     L7013
        bit     $8C
        bpl     L798C
        lda     $B0
        ldy     #$05
        bne     L7990
L798C:  lda     $AF
        ldy     #$04
L7990:  eor     $8D
        and     #$01
        eor     ($A9),y
        sta     ($A9),y
        lda     $8D
        jsr     L79A0
        jmp     L6553

L79A0:  bne     L79AF
        jsr     L79F1
        jsr     L657E
        A2D_CALL A2D_FILL_RECT, L00C7
        rts

L79AF:  bit     $8C
        bmi     L79B8
        bit     $AF
        bmi     L79BC
L79B7:  rts

L79B8:  bit     $B0
        bpl     L79B7
L79BC:  jsr     L657E
        jsr     L79F1
        A2D_CALL A2D_SET_PATTERN, light_speckles_pattern
        A2D_CALL A2D_FILL_RECT, L00C7
        A2D_CALL A2D_SET_PATTERN, white_pattern
        bit     $8C
        bmi     L79DD
        bit     $AF
        bvs     L79E1
L79DC:  rts

L79DD:  bit     $B0
        bvc     L79DC
L79E1:  jsr     L7A73
        jmp     L6A66

light_speckles_pattern:
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111

        .byte   $00,$00
L79F1:  bit     $8C
        bpl     L7A34
        jsr     L7104
        lda     $C9
        clc
        adc     #$0C
        sta     $C9
        bcc     L7A03
        inc     $CA
L7A03:  lda     $CD
        sec
        sbc     #$0B
        sta     $CD
        bcs     L7A0E
        dec     $CE
L7A0E:  lda     $AC
        and     #$04
        bne     L7A18
        bit     $AF
        bpl     L7A23
L7A18:  lda     $CD
        sec
        sbc     #$0B
        sta     $CD
        bcs     L7A23
        dec     $CE
L7A23:  inc     L00C7
        bne     L7A29
        inc     $C8
L7A29:  lda     $CB
        bne     L7A2F
        dec     $CC
L7A2F:  dec     $CB
        jmp     L7A70

L7A34:  jsr     L7129
        lda     L00C7
        clc
        adc     #$15
        sta     L00C7
        bcc     L7A42
        inc     $C8
L7A42:  lda     $CB
        sec
        sbc     #$15
        sta     $CB
        bcs     L7A4D
        dec     $CC
L7A4D:  lda     $AC
        and     #$04
        bne     L7A57
        bit     $B0
        bpl     L7A62
L7A57:  lda     $CB
        sec
        sbc     #$15
        sta     $CB
        bcs     L7A62
        dec     $CC
L7A62:  inc     $C9
        bne     L7A68
        inc     $CA
L7A68:  lda     $CD
        bne     L7A6E
        dec     $CE
L7A6E:  dec     $CD
L7A70:  jmp     L70B2

L7A73:  jsr     L79F1
        jsr     L7CE3
        jsr     L5698
        lda     $A1
        pha
        jsr     L7CFB
        jsr     L7CBA
        pla
        tax
        lda     $A3
        ldy     $A4
        cpx     #$01
        beq     L7A94
        ldx     $A0
        jsr     L7C93
L7A94:  sta     L0082
        sty     L0083
        ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L7AA4
        ldx     #$02
        lda     #$0C
L7AA4:  pha
        lda     L00C7,x
        clc
        adc     L0082
        sta     L00C7,x
        lda     $C8,x
        adc     L0083
        sta     $C8,x
        pla
        clc
        adc     L00C7,x
        sta     $CB,x
        lda     $C8,x
        adc     #$00
        sta     $CC,x
        jmp     L70B2

;;; ==================================================

QUERY_CLIENT_IMPL:
        jsr     L653F
        jsr     L7013
        bne     L7ACE
        lda     #$A0
        jmp     L40B1

L7ACE:  bit     $B0
        bpl     L7B15
        jsr     L7104
        jsr     L7086
        beq     L7B15
        ldx     #$00
        lda     $B0
        and     #$01
        beq     L7B11
        lda     #$80
        sta     $8C
        jsr     L79F1
        jsr     L7086
        beq     L7AFE
        bit     $B0
        bcs     L7B70
        jsr     L7A73
        jsr     L7086
        beq     L7B02
        ldx     #$05
        bne     L7B11
L7AFE:  lda     #$01
        bne     L7B04
L7B02:  lda     #$03
L7B04:  pha
        jsr     L7A73
        pla
        tax
        lda     $EC
        cmp     $C9
        bcc     L7B11
        inx
L7B11:  lda     #$01
        bne     L7B72
L7B15:  bit     $AF
        bpl     L7B64
        jsr     L7129
        jsr     L7086
        beq     L7B64
        ldx     #$00
        lda     $AF
        and     #$01
        beq     L7B60
        lda     #$00
        sta     $8C
        jsr     L79F1
        jsr     L7086
        beq     L7B45
        bit     $AF
        bvc     L7B70
        jsr     L7A73
        jsr     L7086
        beq     L7B49
        ldx     #$05
        bne     L7B60
L7B45:  lda     #$01
        bne     L7B4B
L7B49:  lda     #$03
L7B4B:  pha
        jsr     L7A73
        pla
        tax
        lda     $EB
        cmp     $C8
        bcc     L7B60
        bne     L7B5F
        lda     $EA
        cmp     L00C7
        bcc     L7B60
L7B5F:  inx
L7B60:  lda     #$02
        bne     L7B72
L7B64:  jsr     L708D
        jsr     L7086
        beq     L7B70
        lda     #$00
        beq     L7B72
L7B70:  lda     #$03
L7B72:  jmp     L7408

;;; ==================================================

RESIZE_WINDOW_IMPL:
        lda     L0082
        cmp     #$01
        bne     L7B81
        lda     #$80
        sta     L0082
        bne     L7B90
L7B81:  cmp     #$02
        bne     L7B8B
        lda     #$00
        sta     L0082
        beq     L7B90
L7B8B:  lda     #$A4
        jmp     L40B1

L7B90:  jsr     L7013
        bne     L7B9A
        lda     #$A0
        jmp     L40B1

L7B9A:  ldy     #$06
        bit     L0082
        bpl     L7BA2
        ldy     #$08
L7BA2:  lda     L0083
        sta     ($A9),y
        sta     $AB,y
        rts

;;; ==================================================

DRAG_SCROLL_IMPL:
        lda     L0082
        cmp     #$01
        bne     L7BB6
        lda     #$80
        sta     L0082
        bne     L7BC5
L7BB6:  cmp     #$02
        bne     L7BC0
        lda     #$00
        sta     L0082
        beq     L7BC5
L7BC0:  lda     #$A4
        jmp     L40B1

L7BC5:  lda     L0082
        sta     $8C
        ldx     #$03
L7BCB:  lda     L0083,x
        sta     L769B,x
        sta     L769F,x
        dex
        bpl     L7BCB
        jsr     L7013
        bne     L7BE0
        lda     #$A0
        jmp     L40B1

L7BE0:  jsr     L7A73
        jsr     L653F
        jsr     L6588
        lda     #$02
        jsr     L68F5
        A2D_CALL A2D_SET_PATTERN, light_speckles_pattern
        jsr     HIDE_CURSOR_IMPL
L7BF7:  jsr     L707F
        jsr     SHOW_CURSOR_IMPL
L7BFD:  jsr     L691B
        cmp     #$02
        beq     L7C66
        jsr     L77E0
        beq     L7BFD
        jsr     HIDE_CURSOR_IMPL
        jsr     L707F
        jsr     L7013
        jsr     L7A73
        ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L7C21
        ldx     #$02
        lda     #$0C
L7C21:  sta     L0082
        lda     L00C7,x
        clc
        adc     L76A3,x
        tay
        lda     $C8,x
        adc     L76A4,x
        cmp     L7CB9
        bcc     L7C3B
        bne     L7C41
        cpy     L7CB8
        bcs     L7C41
L7C3B:  lda     L7CB9
        ldy     L7CB8
L7C41:  cmp     L7CB7
        bcc     L7C53
        bne     L7C4D
        cpy     L7CB6
        bcc     L7C53
L7C4D:  lda     L7CB7
        ldy     L7CB6
L7C53:  sta     $C8,x
        tya
        sta     L00C7,x
        clc
        adc     L0082
        sta     $CB,x
        lda     $C8,x
        adc     #$00
        sta     $CC,x
        jmp     L7BF7

L7C66:  jsr     HIDE_CURSOR_IMPL
        jsr     L707F
        jsr     L6553
        jsr     L7CBA
        jsr     L5698
        ldx     $A1
        jsr     L7CE3
        lda     $A3
        ldy     #$00
        cpx     #$01
        bcs     L7C87
        ldx     $A0
        jsr     L7C93
L7C87:  ldx     #$01
        cmp     $A1
        bne     L7C8E
        dex
L7C8E:  ldy     #$05
        jmp     L5EBD

L7C93:  sta     L0082
        sty     L0083
        lda     #$80
        sta     $84
        ldy     #$00
        sty     $85
        txa
        beq     L7CB5
L7CA2:  lda     L0082
        clc
        adc     $84
        sta     $84
        lda     L0083
        adc     $85
        sta     $85
        bcc     L7CB2
        iny
L7CB2:  dex
        bne     L7CA2
L7CB5:  rts

L7CB6:  .byte   0
L7CB7:  .byte   0
L7CB8:  .byte   0
L7CB9:  .byte   0
L7CBA:  lda     L7CB6
        sec
        sbc     L7CB8
        sta     $A3
        lda     L7CB7
        sbc     L7CB9
        sta     $A4
        ldx     #$00
        bit     $8C
        bpl     L7CD3
        ldx     #$02
L7CD3:  lda     L00C7,x
        sec
        sbc     L7CB8
        sta     $A1
        lda     $C8,x
        sbc     L7CB9
        sta     $A2
        rts

L7CE3:  ldy     #$06
        bit     $8C
        bpl     L7CEB
        ldy     #$08
L7CEB:  lda     ($A9),y
        sta     $A3
        iny
        lda     ($A9),y
        sta     $A1
        lda     #$00
        sta     $A2
        sta     $A4
        rts

L7CFB:  ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L7D07
        ldx     #$02
        lda     #$0C
L7D07:  sta     L0082
        lda     L00C7,x
        ldy     $C8,x
        sta     L7CB8
        sty     L7CB9
        lda     $CB,x
        ldy     $CC,x
        sec
        sbc     L0082
        bcs     L7D1D
        dey
L7D1D:  sta     L7CB6
        sty     L7CB7
        rts

;;; ==================================================

UPDATE_SCROLL_IMPL:
        lda     $8C
        cmp     #$01
        bne     L7D30
        lda     #$80
        sta     $8C
        bne     L7D3F
L7D30:  cmp     #$02
        bne     L7D3A
        lda     #$00
        sta     $8C
        beq     L7D3F
L7D3A:  lda     #$A4
        jmp     L40B1

L7D3F:  jsr     L7013
        bne     L7D49
        lda     #$A0
        jmp     L40B1

L7D49:  ldy     #$07
        bit     $8C
        bpl     L7D51
        ldy     #$09
L7D51:  lda     $8D
        sta     ($A9),y
        jsr     L653C
        jsr     L657E
        jsr     L79A0
        jmp     L6553


L7D61:  lda     #$80
        sta     L7D74
        jmp     L67D8

L7D69:
        lda     L0082
        sta     L7D7A
        lda     L0083
        sta     L7D7B
        rts

L7D74:  .byte   $00
L7D75:  .byte   $00
L7D76:  .byte   $00
L7D77:  .byte   $00,$00
L7D79:  .byte   $00
L7D7A:  .byte   $00
L7D7B:  .byte   $00
L7D7C:  .byte   $00
L7D7D:  .byte   $00
L7D7E:  .byte   $00
L7D7F:  .byte   $00
L7D80:  .byte   $00
L7D81:  .byte   $00
L7D82:  .byte   $00
L7D83:  ldx     #$7F
L7D85:  lda     $80,x
        sta     L7D99,x
        dex
        bpl     L7D85
        rts

L7D8E:  ldx     #$7F
L7D90:  lda     L7D99,x
        sta     $80,x
        dex
        bpl     L7D90
        rts

L7D99:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L7E19:  bit     L5FFF
        bmi     L7E49
        bit     L851C
        bmi     L7E49
        pha
        txa
        sec
        jsr     L7E75
        ldx     L851D
        sta     $03B8,x
        tya
        sta     $04B8,x
        pla
        ldy     #$00
        clc
        jsr     L7E75
        ldx     L851D
        sta     $0438,x
        tya
        sta     $0538,x
        ldy     #$16
        jmp     L6313

L7E49:  stx     L5FF8
        sty     L5FF9
        sta     L5FFA
        bit     L5FFF
        bpl     L7E5C
        ldy     #$16
        jmp     L6313

L7E5C:  rts

L7E5D:  ldx     L7D7C
        ldy     L7D7D
        lda     L7D7E
        jmp     L7E19

L7E69:  ldx     L7D75
        ldy     L7D76
        lda     L7D77
        jmp     L7E19

L7E75:  bcc     L7E7D
        ldx     L5FFD
        bne     L7E82
L7E7C:  rts

L7E7D:  ldx     L5FFE
        beq     L7E7C
L7E82:  pha
        tya
        lsr     a
        tay
        pla
        ror     a
        dex
        bne     L7E82
        rts

L7E8C:  ldx     #$02
L7E8E:  lda     L7D75,x
        sta     L5FF8,x
        dex
        bpl     L7E8E
        rts

L7E98:  jsr     L7E8C
        jmp     L7E69

L7E9E:  jsr     L62BA
        ldx     #$02
L7EA3:  lda     L5FF8,x
        sta     L7D7C,x
        dex
        bpl     L7EA3
        rts

L7EAD:  jsr     L7F30
        lda     L7F2E
        sta     $80
        lda     L7F2F
        sta     $81
        jsr     SET_CURSOR_IMPL
        jsr     L7F3B
        lda     #$00
        sta     L7D74
        lda     #$40
        sta     L5FFC
        jmp     L7E5D

L7ECD:  lda     #$00
        sta     L7D81
        sta     set_input_params_unk
        rts

L7ED6:  lda     $C062
        asl     a
        lda     $C061
        and     #$80
        rol     a
        rol     a
        rts

L7EE2:  jsr     L7ED6
        sta     set_input_params_modifiers
L7EE8:  clc
        lda     $C000
        bpl     L7EF4
        stx     $C010
        and     #$7F
        sec
L7EF4:  rts

L7EF5:  lda     L7D74
        bne     L7EFB
        rts

L7EFB:  cmp     #$04
        beq     L7F48
        jsr     L7FB4
        lda     L7D74
        cmp     #$01
        bne     L7F0C
        jmp     L804D

L7F0C:  jmp     L825F

L7F0F:  jsr     L7F30
        lda     L6142
        sta     L7F2E
        lda     L6143
        sta     L7F2F
        lda     L6065
        sta     $80
        lda     L6066
        sta     $81
        jsr     SET_CURSOR_IMPL
        jmp     L7F3B

L7F2E:  .byte   0
L7F2F:  .byte   0
L7F30:  lda     $80
        sta     L7F46
        lda     $81
        sta     L7F47
        rts

L7F3B:  lda     L7F46
        sta     $80
        lda     L7F47
        sta     $81
        rts

L7F46:  .byte   0
L7F47:  .byte   0
L7F48:  jsr     L7ED6
        ror     a
        ror     a
        ror     L7D82
        lda     L7D82
        sta     L5FFC
        lda     #$00
        sta     L6662
        jsr     L7EE8
        bcc     L7F63
        jmp     L8292

L7F63:  jmp     L7E98

L7F66:  pha
        lda     L7D74
        bne     L7FA3
        pla
        cmp     #$03
        bne     L7FA2
        bit     L5FFC
        bmi     L7FA2
        lda     #$04
        sta     L7D74
        ldx     #$0A
L7F7D:  lda     $C030
        ldy     #$00
L7F82:  dey
        bne     L7F82
        dex
        bpl     L7F7D
L7F88:  jsr     L7ED6
        cmp     #$03
        beq     L7F88
        sta     L6662
        lda     #$00
        sta     L7D82
        ldx     #$02
L7F99:  lda     set_pos_params,x
        sta     L7D75,x
        dex
        bpl     L7F99
L7FA2:  rts

L7FA3:  cmp     #$04
        bne     L7FB2
        pla
        and     #$01
        bne     L7FB1
        lda     #$00
        sta     L7D74
L7FB1:  rts

L7FB2:  pla
        rts

L7FB4:  bit     L5FFC
        bpl     L7FC1
        lda     #$00
        sta     L7D74
        jmp     L7E69

L7FC1:  lda     L5FFC
        pha
        lda     #$C0
        sta     L5FFC
        pla
        and     #$20
        beq     L7FDE
        ldx     #$02
L7FD1:  lda     L5FF8,x
        sta     L7D75,x
        dex
        bpl     L7FD1
        stx     L7D79
        rts

L7FDE:  jmp     L7E8C

L7FE1:  php
        sei
        jsr     L7E9E
        lda     #$01
        sta     L7D74
        jsr     L800F
        lda     #$80
        sta     L5FFC
        jsr     L7F0F
        ldx     L7D7A
        jsr     L6878
        lda     $AF
        sta     L6BD9
        jsr     L6D26
        lda     L7D7B
        sta     L6BDA
        jsr     L6EAA
        plp
        rts

L800F:  ldx     L7D7A
        jsr     L6878
        clc
        lda     $B7
        adc     #$05
        sta     L7D75
        lda     $B8
        adc     #$00
        sta     L7D76
        ldy     L7D7B
        lda     L6847,y
        sta     L7D77
        lda     #$C0
        sta     L5FFC
        jmp     L7E98

L8035:  bit     L7D79
        bpl     L804C
        lda     L6BDA
        sta     L7D7B
        ldx     L6BD9
        dex
        stx     L7D7A
        lda     #$00
        sta     L7D79
L804C:  rts

L804D:  jsr     L7D83
        jsr     L8056
        jmp     L7D8E

L8056:  jsr     L7EE2
        bcs     L805C
        rts

L805C:  pha
        jsr     L8035
        pla
        cmp     #$1B
        bne     L8073
        lda     #$00
        sta     L7D80
        sta     L7D7F
        lda     #$80
        sta     L7D81
        rts

L8073:  cmp     #$0D
        bne     L807D
        jsr     L7E8C
        jmp     L7EAD

L807D:  cmp     #$0B
        bne     L80A3
L8081:  dec     L7D7B
        bpl     L8091
        ldx     L7D7A
        jsr     L6878
        ldx     $AA
        stx     L7D7B
L8091:  ldx     L7D7B
        beq     L80A0
        dex
        jsr     L68BE
        lda     $BF
        and     #$C0
        bne     L8081
L80A0:  jmp     L800F

L80A3:  cmp     #$0A
        bne     L80D0
L80A7:  inc     L7D7B
        ldx     L7D7A
        jsr     L6878
        lda     L7D7B
        cmp     $AA
        bcc     L80BE
        beq     L80BE
        lda     #$00
        sta     L7D7B
L80BE:  ldx     L7D7B
        beq     L80CD
        dex
        jsr     L68BE
        lda     $BF
        and     #$C0
        bne     L80A7
L80CD:  jmp     L800F

L80D0:  cmp     #$15
        bne     L80EB
        lda     #$00
        sta     L7D7B
        inc     L7D7A
        lda     L7D7A
        cmp     $A8
        bcc     L80E8
        lda     #$00
        sta     L7D7A
L80E8:  jmp     L800F

L80EB:  cmp     #$08
        bne     L8105
        lda     #$00
        sta     L7D7B
        dec     L7D7A
        bmi     L80FC
        jmp     L800F

L80FC:  ldx     $A8
        dex
        stx     L7D7A
        jmp     L800F

L8105:  jsr     L8110
        bcc     L810F
        lda     #$80
        sta     L7D81
L810F:  rts

L8110:  sta     $C9
        lda     set_input_params_modifiers
        and     #$03
        sta     $CA
        lda     L6BD9
        pha
        lda     L6BDA
        pha
        lda     #$C0
        jsr     L6A96
        beq     L813D
        stx     L7D80
        lda     $B0
        bmi     L813D
        lda     $BF
        and     #$C0
        bne     L813D
        lda     $AF
        sta     L7D7F
        sec
        bcs     L813E
L813D:  clc
L813E:  pla
        sta     L6BDA
        pla
        sta     L6BD9
        sta     L00C7
        rts

L8149:  php
        sei
        jsr     L6D23
        jsr     L7EAD
        lda     L7D7F
        sta     L00C7
        sta     L6BD9
        lda     L7D80
        sta     $C8
        sta     L6BDA
        jsr     L6556
        lda     L7D7F
        beq     L816F
        jsr     L6B1D
        lda     L7D7F
L816F:  sta     L6BD9
        ldx     L7D80
        stx     L6BDA
        plp
        jmp     L5EBB

L817C:  php
        sei
        jsr     L7E9E
        lda     #$80
        sta     L5FFC
        jsr     L70B7
        bit     L76A7
        bpl     L81E4
        lda     $AC
        and     #$04
        beq     L81D9
        ldx     #$00
L8196:  sec
        lda     $CB,x
        sbc     #$04
        sta     L7D75,x
        sta     L769B,x
        sta     L769F,x
        lda     $CC,x
        sbc     #$00
        sta     L7D76,x
        sta     L769C,x
        sta     L76A0,x
        inx
        inx
        cpx     #$04
        bcc     L8196
        sec
        lda     #$2F
        sbc     L769B
        lda     #$02
        sbc     L769C
        bmi     L81D9
        sec
        lda     #$BF
        sbc     L769D
        lda     #$00
        sbc     L769E
        bmi     L81D9
        jsr     L7E98
        jsr     L7F0F
        plp
        rts

L81D9:  lda     #$00
        sta     L7D74
        lda     #$A2
        plp
        jmp     L40B1

L81E4:  lda     $AC
        and     #$01
        beq     L81F4
        lda     #$00
        sta     L7D74
        lda     #$A1
        jmp     L40B1

L81F4:  ldx     #$00
L81F6:  clc
        lda     L00C7,x
        cpx     #$02
        beq     L8202
        adc     #$23
        jmp     L8204

L8202:  adc     #$05
L8204:  sta     L7D75,x
        sta     L769B,x
        sta     L769F,x
        lda     $C8,x
        adc     #$00
        sta     L7D76,x
        sta     L769C,x
        sta     L76A0,x
        inx
        inx
        cpx     #$04
        bcc     L81F6
        bit     L7D76
        bpl     L8235
        ldx     #$01
        lda     #$00
L8229:  sta     L7D75,x
        sta     L769B,x
        sta     L769F,x
        dex
        bpl     L8229
L8235:  jsr     L7E98
        jsr     L7F0F
        plp
        rts

L823D:  php
        clc
        adc     L7D77
        sta     L7D77
        plp
        bpl     L8254
        cmp     #$C0
        bcc     L8251
        lda     #$00
        sta     L7D77
L8251:  jmp     L7E98

L8254:  cmp     #$C0
        bcc     L8251
        lda     #$BF
        sta     L7D77
        bne     L8251
L825F:  jsr     L7D83
        jsr     L8268
        jmp     L7D8E

L8268:  jsr     L7EE2
        bcs     L826E
        rts

L826E:  cmp     #$1B
        bne     L827A
        lda     #$80
        sta     L7D81
        jmp     L7EAD

L827A:  cmp     #$0D
        bne     L8281
        jmp     L7EAD

L8281:  pha
        lda     set_input_params_modifiers
        beq     L828C
        ora     #$80
        sta     set_input_params_modifiers
L828C:  pla
        ldx     #$C0
        stx     L5FFC
L8292:  cmp     #$0B
        bne     L82A2
        lda     #$F8
        bit     set_input_params_modifiers
        bpl     L829F
        lda     #$D0
L829F:  jmp     L823D

L82A2:  cmp     #$0A
        bne     L82B2
        lda     #$08
        bit     set_input_params_modifiers
        bpl     L82AF
        lda     #$30
L82AF:  jmp     L823D

L82B2:  cmp     #$15
        bne     L82ED
        jsr     L839A
        bcc     L82EA
        clc
        lda     #$08
        bit     set_input_params_modifiers
        bpl     L82C5
        lda     #$40
L82C5:  adc     L7D75
        sta     L7D75
        lda     L7D76
        adc     #$00
        sta     L7D76
        sec
        lda     L7D75
        sbc     #$2F
        lda     L7D76
        sbc     #$02
        bmi     L82EA
        lda     #$02
        sta     L7D76
        lda     #$2F
        sta     L7D75
L82EA:  jmp     L7E98

L82ED:  cmp     #$08
        bne     L831D
        jsr     L8352
        bcc     L831A
        lda     L7D75
        bit     set_input_params_modifiers
        bpl     L8303
        sbc     #$40
        jmp     L8305

L8303:  sbc     #$08
L8305:  sta     L7D75
        lda     L7D76
        sbc     #$00
        sta     L7D76
        bpl     L831A
        lda     #$00
        sta     L7D75
        sta     L7D76
L831A:  jmp     L7E98

L831D:  sta     set_input_params_key
        ldx     #$23
L8322:  lda     $A7,x
        sta     $0600,x
        dex
        bpl     L8322
        lda     set_input_params_key
        jsr     L8110
        php
        ldx     #$23
L8333:  lda     $0600,x
        sta     $A7,x
        dex
        bpl     L8333
        plp
        bcc     L8346
        lda     #$40
        sta     L7D81
        jmp     L7EAD

L8346:  rts

L8347:  A2D_CALL A2D_SET_INPUT, set_input_params
        rts

.proc set_input_params          ; 1 byte shorter than normal, since KEY
state:  .byte   A2D_INPUT_KEY
key:    .byte   0
modifiers:
        .byte   0
unk:    .byte   0
.endproc
        set_input_params_key := set_input_params::key
        set_input_params_modifiers := set_input_params::modifiers
        set_input_params_unk := set_input_params::unk

L8352:  lda     L7D74
        cmp     #$04
        beq     L8368
        lda     L7D75
        bne     L8368
        lda     L7D76
        bne     L8368
        bit     L76A7
        bpl     L836A
L8368:  sec
        rts

L836A:  jsr     L70B7
        lda     $CC
        bne     L8380
        lda     #$09
        bit     set_input_params_modifiers
        bpl     L837A
        lda     #$41
L837A:  cmp     $CB
        bcc     L8380
        clc
        rts

L8380:  inc     set_input_params_unk
        clc
        lda     #$08
        .byte   $2C
        .byte   $50
L8388:  .byte   $83
        bpl     L838D
        lda     #$40
L838D:  adc     L769B
        sta     L769B
        bcc     L8398
        inc     L769C
L8398:  clc
        rts

L839A:  lda     L7D74
        cmp     #$04
        beq     L83B3
        bit     L76A7
        .byte   $30
L83A5:  ora     $75AD
        adc     $2FE9,x
        lda     L7D76
        sbc     #$02
        beq     L83B5
        sec
L83B3:  sec
        rts

L83B5:  jsr     L70B7
        sec
        lda     #$2F
        sbc     L00C7
        tax
        lda     #$02
        sbc     $C8
        beq     L83C6
        ldx     #$FF
L83C6:  bit     set_input_params_modifiers
        bpl     L83D1
        cpx     #$64
        bcc     L83D7
        bcs     L83D9
L83D1:  cpx     #$2C
        bcc     L83D7
        bcs     L83E2
L83D7:  clc
        rts

L83D9:  sec
        lda     L769B
        sbc     #$40
        jmp     L83E8

L83E2:  sec
        lda     L769B
        sbc     #$08
L83E8:  sta     L769B
        bcs     L83F0
        dec     L769C
L83F0:  inc     set_input_params_unk
        clc
        rts

L83F5:  .byte   0
L83F6:  lda     #$80
        sta     L83F5
L83FB:  rts

L83FC:  bit     L7D74
        bpl     L83FB
        bit     L83F5
        bpl     L83FB
        jsr     L70B7
        php
        sei
        ldx     #$00
L840D:  sec
        lda     $CB,x
        sbc     #$04
        sta     L7D75,x
        lda     $CC,x
        sbc     #$00
        sta     L7D76,x
        inx
        inx
        cpx     #$04
        bcc     L840D
        jsr     L7E98
        plp
        rts

L8427:
        lda     L0082
        sta     L5FFD
        lda     L0083
        sta     L5FFE
L8431:  bit     L851C
        bmi     L84AC
        lda     L5FFD
        asl     a
        tay
        lda     #$00
        sta     L5FF8
        sta     L5FF9
        bit     L5FFF
        bmi     L844E
        sta     $0478
        sta     $0578
L844E:  lda     L84AD,y
        sta     L5FFA
        bit     L5FFF
        bmi     L845C
        sta     $04F8
L845C:  lda     L84AE,y
        sta     L5FFB
        bit     L5FFF
        bmi     L846A
        sta     $05F8
L846A:  lda     #$00
        ldy     #$17
        jsr     L6313
        lda     L5FFE
        asl     a
        tay
        lda     #$00
        sta     L5FF8
        sta     L5FF9
        bit     L5FFF
        bmi     L8489
        sta     $0478
        sta     $0578
L8489:  lda     L84B5,y
        sta     L5FFA
        bit     L5FFF
        bmi     L8497
        sta     $04F8
L8497:  lda     L84B6,y
        sta     L5FFB
        bit     L5FFF
        bmi     L84A5
        sta     $05F8
L84A5:  lda     #$01
        ldy     #$17
        jsr     L6313
L84AC:  rts

L84AD:  .byte   $2F
L84AE:  .byte   $02,$17,$01,$8B,$00,$45,$00
L84B5:  .byte   $BF
L84B6:  .byte   $00,$5F,$00,$2F,$00,$17,$00

L84BD:  txa
        and     #$7F
        beq     L84CD
        jsr     L84F2
        sta     L851C
        beq     L84DE
        ldx     #$00
        rts

L84CD:  ldx     #$07
L84CF:  txa
        jsr     L84F2
        sta     L851C
        beq     L84DE
        dex
        bpl     L84CF
        ldx     #$00
        rts

L84DE:  ldy     #$19
        jsr     L6313
        jsr     L8431
        ldy     #$18
        jsr     L6313
        lda     L851D
        and     #$0F
        tax
        rts

L84F2:  ora     #$C0
        sta     $89
        lda     #$00
        sta     L0088
        ldy     #$0C
        lda     (L0088),y
        cmp     #$20
        bne     L8519
        ldy     #$FB
        lda     (L0088),y
        cmp     #$D6
        bne     L8519
        lda     $89
        sta     L851D
        asl     a
        asl     a
        asl     a
        asl     a
        sta     L851E
        lda     #$00
        rts

L8519:  lda     #$80
        rts

L851C:  .byte   0
L851D:  .byte   0
L851E:  .byte   0
        .byte   $03
        sbc     #$85
        php
        lda     $E904,x
        sta     $09
        ldy     #$14
        ldx     #$00
L852C:  lda     ($08),y
        sta     L8590,x
        iny
        inx
        cpx     #$04
        bne     L852C
        ldy     #$1C
        ldx     #$00
L853B:  lda     ($08),y
        sta     L8594,x
        iny
        inx
        cpx     #$04
        bne     L853B
        ldy     #$03
        lda     ($06),y
        sec
        sbc     L8590
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     L8591
        sta     ($06),y
        iny
        lda     ($06),y
        sec
        sbc     L8592
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     L8593
        sta     ($06),y
        ldy     #$03
        lda     ($06),y
        clc
        adc     L8594
        sta     ($06),y
        iny
        lda     ($06),y
        adc     L8595
        sta     ($06),y
        iny
        lda     ($06),y
        clc
        adc     L8596
        sta     ($06),y
        iny
        lda     ($06),y
        adc     L8597
        sta     ($06),y
        jsr     L83A5
        rts

L8590:  .byte   $24
L8591:  .byte   $00
L8592:  .byte   $23
L8593:  .byte   $00
L8594:  .byte   $00
L8595:  .byte   $00
L8596:  .byte   $00
L8597:  .byte   $00
        lda     #$00
        ldx     #$00
L859C:  sta     $D409,x
        sta     $D401,x
        sta     $D40D
        inx
        cpx     #$04
        bne     L859C
        lda     #$0A
        sta     $D40D
        sta     $D40F
        ldy     #$04
        lda     #$01
        ldx     #$D4
        jsr     A2D_RELAY
        rts

        lda     #$39
        ldx     #$1A
        jsr     L6B17
        ldx     $D5CA
        txs
        rts

        lda     #$56
        ldx     #$1A
        jsr     L6B17
        ldx     $D5CA
        txs
        rts

        lda     #$71
        ldx     #$1A
        jsr     L6B17
        ldx     $D5CA
        txs
        rts

        cmp     #$27
        bne     L85F2
        lda     #$22
        ldx     #$1B
        jsr     L6B17
        ldx     $D5CA
        txs
        jmp     L8625

L85F2:  cmp     #$45
        bne     L8604
        lda     #$3B
        ldx     #$1B
        jsr     L6B17
        ldx     $D5CA
        txs
        jmp     L8625

L8604:  cmp     #$52
        bne     L8616
        lda     #$5B
        ldx     #$1B
        jsr     L6B17
        ldx     $D5CA
        txs
        jmp     L8625

L8616:  cmp     #$57
        bne     L8625
        lda     #$7C
        ldx     #$1B
        jsr     L6B17
        ldx     $D5CA
        txs
L8625:  ldy     #$33
        lda     #$3F
        ldx     #$D6
        jsr     A2D_RELAY
        rts

        lda     #$9C
        ldx     #$1B
        jsr     L6B17
        ldx     $D5CA
        txs
        ldy     #$33
        lda     #$3F
        ldx     #$D6
        jsr     A2D_RELAY
        rts

        lda     #$BF
        ldx     #$1B
        jsr     L6B17
        ldx     $D5CA
        txs
        ldy     #$33
        lda     #$3F
        ldx     #$D6
        jsr     A2D_RELAY
        rts

        sta     L8737
        sty     L8738
        and     #$F0
        sta     online_params_unit
        sta     ALTZPOFF
        MLI_CALL ON_LINE, online_params
        sta     ALTZPON
        beq     L867B
L8672:  pha
        dec     $EF8A
        dec     $EF88
        pla
        rts

L867B:  lda     online_params_buffer
        beq     L8672
        jsr     L8388
        jsr     LD05E
        ldy     L8738
        sta     $D464,y
        asl     a
        tax
        lda     $F13A,x
        sta     $06
        lda     $F13B,x
        sta     $07
        ldx     #$00
        ldy     #$09
        lda     #$20
L869E:  sta     ($06),y
        iny
        inx
        cpx     #$12
        bne     L869E
        ldy     #$09
        lda     online_params_buffer
        and     #$0F
        sta     online_params_buffer
        sta     ($06),y
        ldx     #$00
        ldy     #$0B
L86B6:  lda     L877A,x
        cmp     #$41
        bcc     L86C4
        cmp     #$5F
        bcs     L86C4
        clc
        adc     #$20
L86C4:  sta     ($06),y
        iny
        inx
        cpx     online_params_buffer
        bne     L86B6
        ldy     #$09
        lda     ($06),y
        clc
        adc     #$02
        sta     ($06),y
        lda     L8737
        and     #$0F
        cmp     #$04
        bne     L86ED
        ldy     #$07
        lda     #$B4
        sta     ($06),y
        iny
        lda     #$14
        sta     ($06),y
        jmp     L870A

L86ED:  cmp     #$0B
        bne     L86FF
        ldy     #$07
        lda     #$70
        sta     ($06),y
        iny
        lda     #$14
        sta     ($06),y
        jmp     L870A

L86FF:  ldy     #$07
        lda     #$40
        sta     ($06),y
        iny
        lda     #$14
        sta     ($06),y
L870A:  ldy     #$02
        lda     #$00
        sta     ($06),y
        inc     L8738
        lda     L8738
        asl     a
        asl     a
        tax
        ldy     #$03
L871B:  lda     L8739,x
        sta     ($06),y
        inx
        iny
        cpy     #$07
        bne     L871B
        ldx     $EF8A
        dex
        ldy     #$00
        lda     ($06),y
        sta     $EF8B,x
        jsr     L83A5
        lda     #$00
        rts

L8737:  rts

L8738:  .byte   $04
L8739:  .byte   $00,$00,$00,$00,$F4,$01,$10,$00
        .byte   $F4,$01,$29,$00,$F4,$01,$42,$00
        .byte   $F4,$01,$5B,$00,$F4,$01,$74,$00
        .byte   $B8,$01,$10,$00,$B8,$01,$29,$00
        .byte   $B8,$01,$42,$00,$B8,$01,$5B,$00
        .byte   $B8,$01,$74,$00,$B8,$01,$8D,$00
        .byte   $90,$01,$10,$00,$90,$01,$29,$00
        .byte   $90,$01,$42,$00

.proc online_params
count:  .byte   2
unit:   .byte   $60
buffer: .addr   online_params_buffer
.endproc
        online_params_unit := online_params::unit

online_params_buffer:
        .byte   $0B
L877A:  .byte   "GRAPHICS.TK",$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$C8

;;; ==================================================
;;; Font

font_table:
        .byte   $00,$7F
glyph_height:
        .byte   $09
glyph_width_table:
        .byte   $01,$07,$07,$07,$07,$07,$01
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$03,$07,$06,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$05,$03,$04,$07,$06,$06,$06
        .byte   $02,$03,$03,$06,$06,$03,$06,$03
        .byte   $07,$06,$06,$06,$06,$06,$06,$06
        .byte   $06,$06,$06,$03,$03,$05,$06,$05
        .byte   $06,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$06
        .byte   $07,$07,$07,$07,$05,$06,$06,$04
        .byte   $06,$05,$07,$07,$06,$07,$06,$06
        .byte   $06,$06,$03,$05,$06,$03,$07,$06
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $07,$06,$06,$06,$04,$02,$04,$05
        .byte   $07

glyph_bitmaps:
        .byte   $00,$00,$00,$3F,$77,$01,$01
        .byte   $00,$00,$7F,$00,$00,$7F,$20,$3E
        .byte   $3E,$00,$00,$3C,$00,$00,$00,$00
        .byte   $00,$14,$55,$2A,$00,$7F,$00,$10
        .byte   $10,$00,$03,$05,$12,$04,$03,$02
        .byte   $01,$02,$01,$00,$00,$00,$00,$00
        .byte   $00,$0E,$0C,$0E,$0E,$1B,$1F,$0E
        .byte   $1F,$0E,$0E,$00,$00,$00,$00,$00
        .byte   $0E,$00,$1E,$1F,$1E,$1F,$3F,$3F
        .byte   $1E,$33,$3F,$3E,$33,$03,$33,$33
        .byte   $1E,$1F,$1E,$1F,$1E,$3F,$33,$1B
        .byte   $33,$33,$33,$3F,$0F,$00,$0F,$02
        .byte   $00,$03,$00,$03,$00,$30,$00,$1C
        .byte   $00,$03,$03,$0C,$03,$03,$00,$00
        .byte   $00,$00,$00,$00,$00,$06,$00,$00
        .byte   $00,$00,$00,$00,$04,$01,$01,$05
        .byte   $00,$00,$7F,$00,$21,$1C,$03,$01
        .byte   $00,$00,$01,$08,$08,$40,$20,$41
        .byte   $41,$00,$00,$42,$00,$00,$00,$08
        .byte   $00,$14,$2A,$55,$00,$3F,$40,$08
        .byte   $08,$00,$03,$05,$12,$1E,$13,$05
        .byte   $01,$01,$02,$04,$04,$00,$00,$00
        .byte   $30,$1B,$0F,$1B,$1B,$1B,$03,$1B
        .byte   $18,$1B,$1B,$00,$00,$0C,$00,$03
        .byte   $1B,$1E,$33,$33,$33,$33,$03,$03
        .byte   $33,$33,$0C,$18,$1B,$03,$3F,$33
        .byte   $33,$33,$33,$33,$33,$0C,$33,$1B
        .byte   $33,$33,$33,$30,$03,$00,$0C,$05
        .byte   $00,$06,$00,$03,$00,$30,$00,$06
        .byte   $00,$03,$00,$00,$03,$03,$00,$00
        .byte   $00,$00,$00,$00,$00,$06,$00,$00
        .byte   $00,$00,$00,$00,$02,$01,$02,$0A
        .byte   $00,$00,$41,$00,$12,$08,$07,$01
        .byte   $00,$0C,$01,$08,$1C,$40,$20,$5D
        .byte   $5D,$77,$03,$04,$1F,$0C,$18,$1C
        .byte   $0C,$14,$55,$2A,$0C,$1F,$60,$36
        .byte   $36,$00,$03,$00,$3F,$05,$08,$05
        .byte   $00,$01,$02,$15,$04,$00,$00,$00
        .byte   $18,$1B,$0C,$18,$18,$1B,$0F,$03
        .byte   $0C,$1B,$1B,$03,$03,$06,$0F,$06
        .byte   $18,$21,$33,$33,$03,$33,$03,$03
        .byte   $03,$33,$0C,$18,$0F,$03,$3F,$37
        .byte   $33,$33,$33,$33,$03,$0C,$33,$1B
        .byte   $33,$1E,$33,$18,$03,$01,$0C,$00
        .byte   $00,$0C,$1E,$1F,$1E,$3E,$0E,$06
        .byte   $0E,$0F,$03,$0C,$1B,$03,$1F,$0F
        .byte   $0E,$0F,$1E,$0F,$1E,$1F,$1B,$1B
        .byte   $23,$1B,$1B,$1F,$02,$01,$02,$00
        .byte   $00,$00,$41,$3F,$0C,$08,$0F,$01
        .byte   $00,$06,$01,$08,$3E,$40,$24,$45
        .byte   $55,$52,$02,$08,$0A,$00,$30,$36
        .byte   $12,$77,$2A,$55,$1E,$4E,$31,$7F
        .byte   $49,$00,$03,$00,$12,$0E,$04,$02
        .byte   $00,$01,$02,$0E,$1F,$00,$1F,$00
        .byte   $0C,$1B,$0C,$0C,$0C,$1F,$18,$0F
        .byte   $06,$0E,$1E,$00,$00,$03,$00,$0C
        .byte   $0C,$2D,$3F,$1F,$03,$33,$0F,$0F
        .byte   $3B,$3F,$0C,$18,$0F,$03,$33,$3B
        .byte   $33,$1F,$33,$1F,$1E,$0C,$33,$1B
        .byte   $33,$0C,$1E,$0C,$03,$02,$0C,$00
        .byte   $00,$00,$30,$33,$03,$33,$1B,$0F
        .byte   $1B,$1B,$03,$0C,$0F,$03,$2B,$1B
        .byte   $1B,$1B,$1B,$1B,$03,$06,$1B,$1B
        .byte   $2B,$0E,$1B,$18,$01,$01,$04,$00
        .byte   $2A,$00,$01,$20,$0C,$08,$1F,$01
        .byte   $7F,$7F,$01,$6B,$6B,$40,$26,$45
        .byte   $4D,$12,$02,$3E,$0A,$3F,$7F,$63
        .byte   $21,$00,$55,$2A,$3F,$64,$1B,$3F
        .byte   $21,$00,$03,$00,$12,$14,$02,$15
        .byte   $00,$01,$02,$15,$04,$00,$00,$00
        .byte   $06,$1B,$0C,$06,$18,$18,$18,$1B
        .byte   $03,$1B,$10,$00,$00,$06,$0F,$06
        .byte   $06,$3D,$33,$33,$03,$33,$03,$03
        .byte   $33,$33,$0C,$18,$0F,$03,$33,$33
        .byte   $33,$03,$33,$33,$30,$0C,$33,$1B
        .byte   $3F,$1E,$0C,$06,$03,$04,$0C,$00
        .byte   $00,$00,$3E,$33,$03,$33,$1F,$06
        .byte   $1B,$1B,$03,$0C,$07,$03,$2B,$1B
        .byte   $1B,$1B,$1B,$03,$0E,$06,$1B,$1B
        .byte   $2B,$04,$1B,$0C,$02,$01,$02,$00
        .byte   $14,$00,$01,$20,$12,$08,$3F,$01
        .byte   $00,$06,$01,$3E,$08,$40,$3F,$5D
        .byte   $55,$12,$02,$10,$0A,$00,$30,$7F
        .byte   $12,$77,$2A,$55,$1E,$71,$0E,$3F
        .byte   $21,$00,$00,$00,$3F,$0F,$19,$09
        .byte   $00,$01,$02,$04,$04,$00,$00,$00
        .byte   $03,$1B,$0C,$03,$1B,$18,$1B,$1B
        .byte   $03,$1B,$1B,$03,$03,$0C,$00,$03
        .byte   $00,$1D,$33,$33,$33,$33,$03,$03
        .byte   $33,$33,$0C,$1B,$1B,$03,$33,$33
        .byte   $33,$03,$33,$33,$33,$0C,$33,$0E
        .byte   $3F,$33,$0C,$03,$03,$08,$0C,$00
        .byte   $00,$00,$33,$33,$03,$33,$03,$06
        .byte   $1B,$1B,$03,$0C,$0F,$03,$2B,$1B
        .byte   $1B,$1B,$1B,$03,$18,$06,$1B,$0E
        .byte   $2B,$0E,$1B,$06,$02,$01,$02,$00
        .byte   $2A,$00,$01,$20,$2D,$08,$0D,$01
        .byte   $00,$0C,$01,$1C,$08,$40,$06,$41
        .byte   $41,$00,$00,$1A,$0A,$0C,$18,$00
        .byte   $0C,$14,$55,$2A,$0C,$7B,$04,$7E
        .byte   $6A,$00,$03,$00,$12,$04,$18,$16
        .byte   $00,$02,$01,$00,$00,$02,$00,$03
        .byte   $00,$0E,$1F,$1F,$0E,$18,$0E,$0E
        .byte   $03,$0E,$0E,$00,$03,$00,$00,$00
        .byte   $06,$01,$33,$1F,$1E,$1F,$3F,$03
        .byte   $1E,$33,$3F,$0E,$33,$3F,$33,$33
        .byte   $1E,$03,$1E,$33,$1E,$0C,$1E,$04
        .byte   $33,$33,$0C,$3F,$0F,$10,$0F,$00
        .byte   $00,$00,$3F,$1F,$1E,$3E,$1E,$06
        .byte   $1E,$1B,$03,$0C,$1B,$03,$2B,$1B
        .byte   $0E,$0F,$1E,$03,$0F,$06,$1E,$04
        .byte   $1F,$1B,$1E,$1F,$04,$01,$01,$00
        .byte   $14,$00,$7F,$3F,$3F,$1C,$18,$01
        .byte   $00,$00,$01,$08,$08,$40,$04,$3E
        .byte   $3E,$00,$00,$4F,$00,$00,$00,$00
        .byte   $00,$14,$2A,$55,$00,$7F,$00,$36
        .byte   $36,$00,$00,$00,$12,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$02,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$3E,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$30,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $1F,$00,$00,$00,$00,$00,$00,$00
        .byte   $18,$00,$00,$0C,$00,$00,$00,$00
        .byte   $00,$03,$18,$00,$00,$00,$00,$00
        .byte   $00,$00,$18,$00,$00,$00,$00,$00
        .byte   $2A
        ;; end of font glyphs

;;; ==================================================

        .byte   $00,$00,$00,$00,$77,$30,$01
        .byte   $00,$00,$7F,$00,$00,$7F,$00,$00
        .byte   $00,$00,$00,$7A,$00,$00,$00,$00
        .byte   $00,$14,$55,$2A,$00,$7F,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $0E,$00,$00,$07,$00,$00,$00,$00
        .byte   $00,$03,$18,$00,$00,$00,$00,$00
        .byte   $00,$00,$0E,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00

        ;; Entry point for "DESKTOP"
        jmp     $93BC

L8E03:  .byte   $08,$00
L8E05:  .byte   $00
L8E06:  .byte   $00
L8E07:  .byte   $00
L8E08:  .byte   $00
L8E09:  .byte   $00
L8E0A:  .byte   $00
L8E0B:  .byte   $00
L8E0C:  .byte   $00
L8E0D:  .byte   $00
L8E0E:  .byte   $00
L8E0F:  .byte   $00
L8E10:  .byte   $00
L8E11:  .byte   $00
L8E12:  .byte   $00
L8E13:  .byte   $00
L8E14:  .byte   $00
L8E15:  .byte   $00
L8E16:  .byte   $00
L8E17:  .byte   $00
L8E18:  .byte   $00
L8E19:  .byte   $00
L8E1A:  .byte   $00
L8E1B:  .byte   $00
L8E1C:  .byte   $00
L8E1D:  .byte   $00
L8E1E:  .byte   $00
L8E1F:  .byte   $00
L8E20:  .byte   $00
L8E21:  .byte   $00
L8E22:  .byte   $00
L8E23:  .byte   $00
L8E24:  .byte   $00
draw_bitmap_params2:  .byte   $00
L8E26:  .byte   $00
L8E27:  .byte   $00
L8E28:  .byte   $00
L8E29:  .byte   $00
L8E2A:  .byte   $00,$00,$00
L8E2D:  .byte   $00
L8E2E:  .byte   $00,$00,$00
L8E31:  .byte   $00
L8E32:  .byte   $00
L8E33:  .byte   $00,$00

.proc draw_bitmap_params
left:   .word   0
top:    .word   0
addr:   .addr   0
stride: .byte   0
        .byte   0               ; ???
hoff:   .word   0
voff:   .word   0
.endproc

        .byte   $00,$00
L8E43:  .byte   $00,$00

fill_rect_params6:  .byte   $00
L8E46:  .byte   $00,$00,$00
L8E49:  .byte   $00
L8E4A:  .byte   $00
L8E4B:  .byte   $00
L8E4C:  .byte   $00

.proc measure_text_params
addr:   .addr   text_buffer
length: .byte   0
width:  .word   0
.endproc
set_text_mask_params :=  measure_text_params::width + 1 ; re-used

.proc draw_text_params
addr:   .addr   text_buffer
length: .byte   0
.endproc

text_buffer:
        .res    19, 0

white_pattern2:
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF

checkerboard_pattern2:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

        .byte   $FF

dark_pattern:
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100

        .byte   $FF,$EE,$BB,$EE,$BB,$EE,$BB,$EE
        .byte   $BB
L8E94:  .byte   $FF
L8E95:  .byte   $00
L8E96:  .byte   $00
L8E97:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
L8F15:  .byte   $00
L8F16:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
L9015:  .byte   $00
L9016:  .byte   $00
L9017:  .byte   $00
L9018:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
L9096:  .byte   $00,$00
L9098:
        .res    678, 0


L933E:  .byte   $00

.proc query_target_params2
queryx: .word   0
queryy: .word   0
element:.byte   0
id:     .byte   0
.endproc

query_screen_params:  .byte   $00,$00,$00,$00,$00,$20,$80,$00
L934D:  .byte   $00,$00,$00,$00,$2F,$02,$BF,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00,$00,$00,$00,$00,$01,$01
        .byte   $96,$00,$00,$88
query_state_params:  .byte   $00,$6C,$93
set_state_params:  .byte   $00
L936D:  .byte   $00
L936E:  .byte   $00
L936F:  .byte   $00,$00,$00,$00,$00
L9374:  .byte   $00
L9375:  .byte   $00
L9376:  .byte   $00
L9377:  .byte   $00
L9378:  .byte   $00
L9379:  .byte   $00
L937A:  .byte   $00
L937B:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$80
set_fill_mode_params:  .byte   $00
set_fill_mode_params2:  .byte   $01
set_fill_mode_params3:  .byte   $02
set_fill_mode_params4:  .byte   $03
set_fill_mode_params5:  .byte   $04,$05,$06,$07
L939E:  .byte   $00
L939F:  .byte   $00,$19,$94,$54,$94,$C0,$94,$08
        .byte   $95,$A2,$95,$92,$96,$D2,$96,$5B
        .byte   $97,$7D,$97,$F7,$97,$BE,$9E,$A6
        .byte   $A2,$FB,$9E
        .byte   $8F
        .byte   $95

        ;; DESKTOP entry point (after jump)
L93BC:  pla
        sta     L9413
        clc
        adc     #$03
        tax
        pla
        sta     L9414
        adc     #$00
        pha
        txa
        pha
        ldx     #$00
L93CF:  lda     $06,x
        pha
        inx
        cpx     #$04
        bne     L93CF
        lda     L9413
        clc
        adc     #$01
        sta     $06
        lda     L9414
        adc     #$00
        sta     $07
        ldy     #$00
        lda     ($06),y
        asl     a
        tax
        lda     L939E,x
        sta     L9404
        lda     L939F,x
        sta     L9405
        iny
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $07
        stx     $06
        .byte   $20
L9404:  .byte   0
L9405:  .byte   0
        tay
        ldx     #$03
L9409:  pla
        sta     $06,x
        dex
        cpx     #$FF
        bne     L9409
        tya
        rts

L9413:  .byte   0
L9414:  .byte   0
set_pos_params2:  .byte   0
L9416:  .byte   0
L9417:  .byte   0
L9418:  .byte   0
        ldy     #$00
        lda     ($06),y
        ldx     L8E95
        beq     L9430
        dex
L9423:  .byte   $DD
        .byte   $96
L9425:  stx     $05F0
        dex
        bpl     L9423
        bmi     L9430
        lda     #$01
        rts

L9430:  jsr     L943E
        jsr     L9F98
        lda     #$01
        tay
        sta     ($06),y
        lda     #$00
        rts

L943E:  ldx     L8E95
        sta     L8E96,x
        inc     L8E95
        asl     a
        tax
        lda     $06
        sta     L8F15,x
        lda     $07
        sta     L8F16,x
        rts

L9454:  ldx     L8E95
        beq     L9466
        dex
        ldy     #$00
        lda     ($06),y
L945E:  cmp     L8E96,x
        beq     L9469
        dex
        bpl     L945E
L9466:  lda     #$01
        rts

L9469:  asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$01
        lda     ($06),y
        bne     L947E
        lda     #$02
        rts

L947E:  lda     L9015
        beq     L9498
        dey
        lda     ($06),y
        ldx     L9016
        dex
L948A:  cmp     L9017,x
        beq     L9495
        dex
        bpl     L948A
        jmp     L949D

L9495:  lda     #$03
        rts

L9498:  lda     #$01
        sta     L9015
L949D:  ldx     L9016
        ldy     #$00
        lda     ($06),y
        sta     L9017,x
        inc     L9016
        lda     ($06),y
        ldx     #$01
        jsr     LA324
        ldy     #$00
        lda     ($06),y
        ldx     #$01
        jsr     LA2E3
        jsr     L9F9F
        lda     #$00
        rts

        ldx     L8E95
        beq     L94D2
        dex
        ldy     #$00
        lda     ($06),y
L94CA:  cmp     L8E96,x
        beq     L94D5
        dex
        bpl     L94CA
L94D2:  lda     #$01
        rts

L94D5:  asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        lda     L9015
        bne     L94E9
        jmp     L9502

L94E9:  ldx     L9016
        dex
        ldy     #$00
        lda     ($06),y
L94F1:  cmp     L9017,x
        beq     L94FC
        dex
        bpl     L94F1
        jmp     L9502

L94FC:  jsr     L9F9F
        lda     #$00
        rts

L9502:  jsr     L9F98
        lda     #$00
        rts

        ldy     #$00
        ldx     L8E95
        beq     L951A
        dex
        lda     ($06),y
L9512:  cmp     L8E96,x
        beq     L951D
        dex
        bpl     L9512
L951A:  lda     #$01
        rts

L951D:  asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$01
        lda     ($06),y
        bne     L9532
        lda     #$02
        rts

L9532:  jsr     LA18A
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params
        jsr     LA39D
        ldy     #$00
        lda     ($06),y
        ldx     L8E95
        jsr     LA2E3
        dec     L8E95
        lda     #$00
        ldx     L8E95
        sta     L8E96,x
        ldy     #$01
        lda     #$00
        sta     ($06),y
        lda     L9015
        beq     L958C
        ldx     L9016
        dex
        ldy     #$00
        lda     ($06),y
L9566:  cmp     L9017,x
        beq     L9571
        dex
        bpl     L9566
        jmp     L958C

L9571:  ldx     L9016
        jsr     LA324
        dec     L9016
        lda     L9016
        bne     L9584
        lda     #$00
        sta     L9015
L9584:  lda     #$00
        ldx     L9016
        sta     L9017,x
L958C:  lda     #$00
        rts

        ldy     #$00
        lda     ($06),y
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        jmp     LA39D

        jmp     L9625

L95A5:
L95A6 := * + 1
        .res    128, 0

L9625:  lda     L9454
        beq     L9639
        lda     L9017
        sta     L95A5
        jsr     L93BC
        .byte   $0B
        lda     $95
        jmp     L9625

L9639:  ldx     #$7E
        lda     #$00
L963D:  sta     L95A6,x
        dex
        bpl     L963D
        ldx     #$00
        stx     L95A5
L9648:  lda     L8E96,x
        asl     a
        tay
        lda     L8F15,y
        sta     $08
        lda     L8F16,y
        sta     $09
        ldy     #$02
        lda     ($08),y
        and     #$0F
        ldy     #$00
        cmp     ($06),y
        bne     L9670
        ldy     #$00
        lda     ($08),y
        ldy     L95A5
        sta     L95A6,y
        inc     L95A5
L9670:  inx
        cpx     L8E95
        bne     L9648
        ldx     #$00
        txa
        pha
L967A:  lda     L95A6,x
        bne     L9681
        pla
        rts

L9681:  sta     L95A5
        jsr     L93BC
        .byte   $02
        lda     $95
        pla
        tax
        inx
        txa
        pha
        jmp     L967A

        jmp     L9697

L9695:  .byte   0
L9696:  .byte   0
L9697:  lda     L8E95
        sta     L9696
L969D:  ldx     L9696
        cpx     #$00
        beq     L96CF
        dec     L9696
        dex
        lda     L8E96,x
        sta     L9695
        asl     a
        tax
        lda     L8F15,x
        sta     $08
        lda     L8F16,x
        sta     $09
        ldy     #$02
        lda     ($08),y
        and     #$0F
        ldy     #$00
        cmp     ($06),y
        bne     L969D
        jsr     L93BC
        tsb     $95
        stx     $4C,y
        .byte   $9D
        .byte   $96
L96CF:  lda     #$00
        rts

        jmp     L96D7

L96D5:  .byte   0
L96D6:  .byte   0
L96D7:  lda     L8E95
        sta     L96D6
L96DD:  ldx     L96D6
        bne     L96E5
        lda     #$00
        rts

L96E5:  dec     L96D6
        dex
        lda     L8E96,x
        sta     L96D5
        asl     a
        tax
        lda     L8F15,x
        sta     $08
        lda     L8F16,x
        sta     $09
        ldy     #$02
        lda     ($08),y
        and     #$0F
        ldy     #$00
        cmp     ($06),y
        bne     L96DD
        ldy     #$00
        lda     ($08),y
        ldx     L8E95
        jsr     LA2E3
        dec     L8E95
        lda     #$00
        ldx     L8E95
        sta     L8E96,x
        ldy     #$01
        lda     #$00
        sta     ($08),y
        lda     L9015
        beq     L9758
        ldx     #$00
        ldy     #$00
L972B:  lda     ($08),y
        cmp     L9017,x
        beq     L973B
        inx
        cpx     L9016
        bne     L972B
        jmp     L9758

L973B:  lda     ($08),y
        ldx     L9016
        jsr     LA324
        dec     L9016
        lda     L9016
        bne     L9750
        lda     #$00
        sta     L9015
L9750:  lda     #$00
        ldx     L9016
        sta     L9017,x
L9758:  jmp     L96DD

        ldx     #$00
        txa
        tay
L975F:  sta     ($06),y
        iny
        inx
        cpx     #$14
        bne     L975F
        ldx     #$00
        ldy     #$00
L976B:  lda     L9017,x
        sta     ($06),y
        cpx     L9016
        beq     L977A
        iny
        inx
        jmp     L976B

L977A:  lda     #$00
        rts

        jmp     L9789

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L9789:  ldy     #$03
L978B:  lda     ($06),y
        sta     set_pos_params2,y
        dey
        bpl     L978B
        lda     $06
        sta     $08
        lda     $07
        sta     $09
        ldy     #$05
        lda     ($06),y
        sta     L97F5
        A2D_CALL A2D_SET_POS, set_pos_params2
        ldx     #$00
L97AA:  cpx     L8E95
        bne     L97B9
        ldy     #$04
        lda     #$00
        sta     ($08),y
        sta     L97F6
        rts

L97B9:  txa
        pha
        lda     L8E96,x
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$02
        lda     ($06),y
        and     #$0F
        cmp     L97F5
        bne     L97E0
        jsr     LA18A
        A2D_CALL $17, L8E03
        bne     L97E6
L97E0:  pla
        tax
        inx
        jmp     L97AA

L97E6:  pla
        tax
        lda     L8E96,x
        ldy     #$04
        sta     ($08),y
        sta     L97F6
        rts

        rts

        .byte   0
L97F5:  .byte   0
L97F6:  .byte   0
        ldy     #$00
        lda     ($06),y
        sta     L982A
        tya
        sta     ($06),y
        ldy     #$04
L9803:  lda     ($06),y
        sta     L9C8D,y
        sta     L9C91,y
        dey
        cpy     #$00
        bne     L9803
        jsr     LA365
        lda     L982A
        jsr     L9EB4
        sta     $06
        stx     $07
        ldy     #$02
        lda     ($06),y
        and     #$0F
        sta     L9829
        jmp     L983D

L9829:  .byte   $00
L982A:  .byte   $00,$00
L982C:  .byte   $00
L982D:  .byte   $00
L982E:  .byte   $00
L982F:  .byte   $00
L9830:  .byte   $00
L9831:  .byte   $00
L9832:  .byte   $00
L9833:  .byte   $00
L9834:  .byte   $00
L9835:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
L983D:  lda     #$00
        sta     L9830
        sta     L9833
L9845:  A2D_CALL $2C, L933E
        lda     L933E
        cmp     #$04
        beq     L9857
L9852:  lda     #$02
        jmp     L9C65

L9857:  lda     query_target_params2::queryx
        sec
        sbc     L9C8E
        sta     L982C
        lda     query_target_params2::queryx+1
        sbc     L9C8F
        sta     L982D
        lda     query_target_params2::queryy
        sec
        sbc     L9C90
        sta     L982E
        lda     query_target_params2::queryy+1
        sbc     L9C91
        sta     L982F
        lda     L982D
        bpl     L988C
        lda     L982C
        cmp     #$FB
        bcc     L98AC
        jmp     L9893

L988C:  lda     L982C
        cmp     #$05
        bcs     L98AC
L9893:  lda     L982F
        bpl     L98A2
        lda     L982E
        cmp     #$FB
        bcc     L98AC
        jmp     L9845

L98A2:  lda     L982E
        cmp     #$05
        bcs     L98AC
        jmp     L9845

L98AC:  lda     L9016
        cmp     #$15
        bcc     L98B6
        jmp     L9852

L98B6:  lda     #$96
        sta     $08
        lda     #$90
        sta     $09
        lda     L9015
        bne     L98C8
        lda     #$03
        jmp     L9C65

L98C8:  lda     L9017
        jsr     L9EB4
        sta     $06
        stx     $07
        ldy     #$02
        lda     ($06),y
        and     #$0F
        sta     L9832
        A2D_CALL A2D_QUERY_SCREEN, query_screen_params
        ldx     #$07
L98E3:  lda     L934D,x
        sta     L9835,x
        dex
        bpl     L98E3
        ldx     L9016
        stx     L9C74
L98F2:  lda     L9016,x
        jsr     L9EB4
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        cmp     #$01
        bne     L9909
        ldx     #$80
        stx     L9833
L9909:  sta     L9834
        jsr     L93BC
        ora     L9834
        beq     L9954
        jsr     LA18A
        lda     L9C74
        cmp     L9016
        beq     L9936
        jsr     LA365
        lda     $08
        sec
        sbc     #$22
        sta     $08
        bcs     L992D
        dec     $09
L992D:  ldy     #$01
        lda     #$80
        sta     ($08),y
        jsr     LA382
L9936:  ldx     #$21
        ldy     #$21
L993A:  lda     L8E03,x
        sta     ($08),y
        dey
        dex
        bpl     L993A
        lda     #$08
        ldy     #$00
        sta     ($08),y
        lda     $08
        clc
        adc     #$22
        sta     $08
        bcc     L9954
        inc     $09
L9954:  dec     L9C74
        beq     L995F
        ldx     L9C74
        jmp     L98F2

L995F:  ldx     #$07
L9961:  lda     L9098,x
        sta     L9C76,x
        dex
        bpl     L9961
        lda     #$96
        sta     $08
        lda     #$90
        sta     $09
L9972:  ldy     #$02
L9974:  lda     ($08),y
        cmp     L9C76
        iny
        lda     ($08),y
        sbc     L9C77
        bcs     L9990
        lda     ($08),y
        sta     L9C77
        dey
        lda     ($08),y
        sta     L9C76
        iny
        jmp     L99AA

L9990:  dey
        lda     ($08),y
        cmp     L9C7A
        iny
        lda     ($08),y
        sbc     L9C7B
        bcc     L99AA
        lda     ($08),y
        sta     L9C7B
        dey
        lda     ($08),y
        sta     L9C7A
        iny
L99AA:  iny
        lda     ($08),y
        cmp     L9C78
        iny
        lda     ($08),y
        sbc     L9C79
        bcs     L99C7
        lda     ($08),y
        sta     L9C79
        dey
        lda     ($08),y
        sta     L9C78
        iny
        jmp     L99E1

L99C7:  dey
        lda     ($08),y
        cmp     L9C7C
        iny
        lda     ($08),y
        sbc     L9C7D
        bcc     L99E1
        lda     ($08),y
        sta     L9C7D
        dey
        lda     ($08),y
        sta     L9C7C
        iny
L99E1:  iny
        cpy     #$22
        bne     L9974
        ldy     #$01
        lda     ($08),y
        beq     L99FC
        lda     $08
        clc
        adc     #$22
        sta     $08
        lda     $09
        adc     #$00
        sta     $09
        jmp     L9972

L99FC:  A2D_CALL A2D_SET_PATTERN, checkerboard_pattern2
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params3
        A2D_CALL $16, L9096
L9A0E:  A2D_CALL $2C, L933E
        lda     L933E
        cmp     #$04
        beq     L9A1E
        jmp     L9BA5

L9A1E:  ldx     #$03
L9A20:  lda     query_target_params2,x
        cmp     L9C92,x
        bne     L9A31
        dex
        bpl     L9A20
        jsr     L9E14
        jmp     L9A0E

L9A31:  ldx     #$03
L9A33:  lda     query_target_params2,x
        sta     L9C92,x
        dex
        bpl     L9A33
        lda     L9830
        beq     L9A84
        lda     L9831
        sta     query_target_params2::id
        jsr     L93BC
        ora     #$3F
        .byte   $93
        lda     query_target_params2::element
        cmp     L9830
        beq     L9A84
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern2
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params3
        A2D_CALL $16, L9096
        jsr     L93BC
        .byte   $0B
        bmi     $9A05           ; ???
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern2
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params3
        A2D_CALL $16, L9096
        lda     #$00
        sta     L9830
L9A84:  lda     query_target_params2::queryx
        sec
        sbc     L9C8E
        sta     L9C96
        lda     query_target_params2::queryx+1
        sbc     L9C8F
        sta     L9C97
        lda     query_target_params2::queryy
        sec
        sbc     L9C90
        sta     L9C98
        lda     query_target_params2::queryy+1
        sbc     L9C91
        sta     L9C99
        jsr     L9C9E
        ldx     #$00
L9AAF:  lda     L9C7A,x
        clc
        adc     L9C96,x
        sta     L9C7A,x
        lda     L9C7B,x
        adc     L9C97,x
        sta     L9C7B,x
        lda     L9C76,x
        clc
        adc     L9C96,x
        sta     L9C76,x
        lda     L9C77,x
        adc     L9C97,x
        sta     L9C77,x
        inx
        inx
        cpx     #$04
        bne     L9AAF
        lda     #$00
        sta     L9C75
        lda     L9C77
        bmi     L9AF7
        lda     L9C7A
        cmp     #$30
        lda     L9C7B
        sbc     #$02
        bcs     L9AFE
        jsr     L9DFA
        jmp     L9B0E

L9AF7:  jsr     L9CAA
        bmi     L9B0E
        bpl     L9B03
L9AFE:  jsr     L9CD1
        bmi     L9B0E
L9B03:  jsr     L9DB8
        lda     L9C75
        ora     #$80
        sta     L9C75
L9B0E:  lda     L9C79
        bmi     L9B31
        lda     L9C78
        cmp     #$0D
        lda     L9C79
        sbc     #$00
        bcc     L9B31
        lda     L9C7C
        cmp     #$C0
        lda     L9C7D
        sbc     #$00
        bcs     L9B38
        jsr     L9E07
        jmp     L9B48

L9B31:  jsr     L9D31
        bmi     L9B48
        bpl     L9B3D
L9B38:  jsr     L9D58
        bmi     L9B48
L9B3D:  jsr     L9DD9
        lda     L9C75
        ora     #$40
        sta     L9C75
L9B48:  bit     L9C75
        bpl     L9B52
        .byte   $50
L9B4E:  .byte   $03
        jmp     L9A0E

L9B52:  A2D_CALL $16, L9096
        lda     #$96
        sta     $08
        lda     #$90
        sta     $09
L9B60:  ldy     #$02
L9B62:  lda     ($08),y
        clc
        adc     L9C96
        sta     ($08),y
        iny
        lda     ($08),y
        adc     L9C97
        sta     ($08),y
        iny
        lda     ($08),y
        clc
        adc     L9C98
        sta     ($08),y
        iny
        lda     ($08),y
        adc     L9C99
        sta     ($08),y
        iny
        cpy     #$22
        bne     L9B62
        ldy     #$01
        lda     ($08),y
        beq     L9B9C
        lda     $08
        clc
        adc     #$22
        sta     $08
        bcc     L9B99
        inc     $09
L9B99:  jmp     L9B60

L9B9C:  A2D_CALL $16, L9096
        jmp     L9A0E

L9BA5:  A2D_CALL $16, L9096
        lda     L9830
        beq     L9BB9
        jsr     L93BC
        .byte   $0B
        bmi     L9B4E
        jmp     L9C63

L9BB9:  A2D_CALL A2D_QUERY_TARGET, query_target_params2
        lda     query_target_params2::id
        cmp     L9832
        beq     L9BE1
        bit     L9833
        bmi     L9BDC
        lda     query_target_params2::id
        bne     L9BD4
L9BD1:  jmp     L9852

L9BD4:  ora     #$80
        sta     L9830
        jmp     L9C63

L9BDC:  lda     L9832
        beq     L9BD1
L9BE1:  jsr     LA365
        A2D_CALL A2D_QUERY_SCREEN, query_screen_params
        A2D_CALL A2D_SET_STATE, query_screen_params
        ldx     L9016
L9BF3:  dex
        bmi     L9C18
        txa
        pha
        lda     L9017,x
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        jsr     LA18A
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params
        jsr     LA39D
        pla
        tax
        jmp     L9BF3

L9C18:  jsr     LA382
        ldx     L9016
        dex
        txa
        pha
        lda     #$96
        sta     $08
        lda     #$90
        sta     $09
L9C29:  lda     L9017,x
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$02
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        pla
        tax
        dex
        bmi     L9C63
        txa
        pha
        lda     $08
        clc
        adc     #$22
        sta     $08
        bcc     L9C60
        inc     $09
L9C60:  jmp     L9C29

L9C63:  lda     #$00
L9C65:  tay
        jsr     LA382
        tya
        tax
        ldy     #$00
        lda     L9830
        sta     ($06),y
        txa
        rts

L9C74:  .byte   $00
L9C75:  .byte   $00
L9C76:  .byte   $00
L9C77:  .byte   $00
L9C78:  .byte   $00
L9C79:  .byte   $00
L9C7A:  .byte   $00
L9C7B:  .byte   $00
L9C7C:  .byte   $00
L9C7D:  .byte   $00
L9C7E:  .byte   $00
L9C7F:  .byte   $00
L9C80:  .byte   $0D
L9C81:  .byte   $00
L9C82:  .byte   $30
L9C83:  .byte   $02
L9C84:  .byte   $C0
L9C85:  .byte   $00
L9C86:  .byte   $00
L9C87:  .byte   $00
L9C88:  .byte   $00
L9C89:  .byte   $00
L9C8A:  .byte   $00
L9C8B:  .byte   $00
L9C8C:  .byte   $00
L9C8D:  .byte   $00
L9C8E:  .byte   $00
L9C8F:  .byte   $00
L9C90:  .byte   $00
L9C91:  .byte   $00
L9C92:  .byte   $00,$00,$00,$00
L9C96:  .byte   $00
L9C97:  .byte   $00
L9C98:  .byte   $00
L9C99:  .byte   $00,$00,$00,$00,$00
L9C9E:  ldx     #$07
L9CA0:  lda     L9C76,x
        sta     L9C86,x
        dex
        bpl     L9CA0
        rts

L9CAA:  lda     L9C76
        cmp     L9C7E
        bne     L9CBD
        lda     L9C77
        cmp     L9C7F
        bne     L9CBD
        lda     #$00
        rts

L9CBD:  lda     #$00
        sec
        sbc     L9C86
        sta     L9C96
        lda     #$00
        sbc     L9C87
        sta     L9C97
        jmp     L9CF5

L9CD1:  lda     L9C7A
        cmp     L9C82
        bne     L9CE4
        lda     L9C7B
        cmp     L9C83
        bne     L9CE4
        lda     #$00
        rts

L9CE4:  lda     #$30
        sec
        sbc     L9C8A
        sta     L9C96
        lda     #$02
        sbc     L9C8B
        sta     L9C97
L9CF5:  lda     L9C86
        clc
        adc     L9C96
        sta     L9C76
        lda     L9C87
        adc     L9C97
        sta     L9C77
        lda     L9C8A
        clc
        adc     L9C96
        sta     L9C7A
        lda     L9C8B
        adc     L9C97
        sta     L9C7B
        lda     L9C8E
        clc
        adc     L9C96
        sta     L9C8E
        lda     L9C8F
        adc     L9C97
        sta     L9C8F
        lda     #$FF
        rts

L9D31:  lda     L9C78
        cmp     L9C80
        bne     L9D44
        lda     L9C79
        cmp     L9C81
        bne     L9D44
        lda     #$00
        rts

L9D44:  lda     #$0D
        sec
        sbc     L9C88
        sta     L9C98
        lda     #$00
        sbc     L9C89
        sta     L9C99
        jmp     L9D7C

L9D58:  lda     L9C7C
        cmp     L9C84
        bne     L9D6B
        lda     L9C7D
        cmp     L9C85
        bne     L9D6B
        lda     #$00
        rts

L9D6B:  lda     #$BF
        sec
        sbc     L9C8C
        sta     L9C98
        lda     #$00
        sbc     L9C8D
        sta     L9C99
L9D7C:  lda     L9C88
        clc
        adc     L9C98
        sta     L9C78
        lda     L9C89
        adc     L9C99
        sta     L9C79
        lda     L9C8C
        clc
        adc     L9C98
        sta     L9C7C
        lda     L9C8D
        adc     L9C99
        sta     L9C7D
        lda     L9C90
        clc
        adc     L9C98
        sta     L9C90
        lda     L9C91
        adc     L9C99
        sta     L9C91
        lda     #$FF
        rts

L9DB8:  lda     L9C86
        sta     L9C76
        lda     L9C87
        sta     L9C77
        lda     L9C8A
        sta     L9C7A
        lda     L9C8B
        sta     L9C7B
        lda     #$00
        sta     L9C96
        sta     L9C97
        rts

L9DD9:  lda     L9C88
        sta     L9C78
        lda     L9C89
        sta     L9C79
        lda     L9C8C
        sta     L9C7C
        lda     L9C8D
        sta     L9C7D
        lda     #$00
        sta     L9C98
        sta     L9C99
        rts

L9DFA:  lda     query_target_params2::queryx+1
        sta     L9C8F
        lda     query_target_params2::queryx
        sta     L9C8E
        rts

L9E07:  lda     query_target_params2::queryy+1
        sta     L9C91
        lda     query_target_params2::queryy
        sta     L9C90
        rts

L9E14:  bit     L9833
        bpl     L9E1A
        rts

L9E1A:  jsr     LA365
L9E1D:  A2D_CALL A2D_QUERY_TARGET, query_target_params2
        lda     query_target_params2::element
        bne     L9E2B
        sta     query_target_params2::id
L9E2B:  jsr     L93BC
        ora     #$3F
        .byte   $93
        lda     query_target_params2::element
        bne     L9E39
        jmp     L9E97

L9E39:  ldx     L9016
        dex
L9E3D:  cmp     L9017,x
        beq     L9E97
        dex
        bpl     L9E3D
        sta     L9EB3
        cmp     #$01
        beq     L9E6A
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$02
        lda     ($06),y
        and     #$0F
        sta     L9831
        lda     ($06),y
        and     #$70
        bne     L9E97
        lda     L9EB3
L9E6A:  sta     L9830
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern2
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params3
        A2D_CALL $16, L9096
        jsr     L93BC
        .byte   $02
        bmi     L9E1D
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern2
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params3
        A2D_CALL $16, L9096
L9E97:  A2D_CALL A2D_QUERY_SCREEN, query_screen_params
        A2D_CALL A2D_SET_STATE, query_screen_params
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern2
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params3
        jsr     LA382
        rts

L9EB3:  .byte   0
L9EB4:  asl     a
        tay
        lda     L8F16,y
        tax
        lda     L8F15,y
        rts

        jmp     L9EC3

        .byte   0
L9EC2:  .byte   0
L9EC3:  lda     L9015
        bne     L9ECB
        lda     #$01
        rts

L9ECB:  ldx     L9016
        ldy     #$00
        lda     ($06),y
        jsr     LA324
        ldx     L9016
        lda     #$00
        sta     L9016,x
        dec     L9016
        lda     L9016
        bne     L9EEA
        lda     #$00
        sta     L9015
L9EEA:  ldy     #$00
        lda     ($06),y
        sta     L9EC2
        jsr     L93BC
        .byte   $03
        .byte   $C2
        stz     a:$A9,x
        rts

        rts

        jmp     L9F07

L9EFE:  .byte   0
L9EFF:  .byte   0
L9F00:  .byte   0
L9F01:  .byte   0
L9F02:  .byte   0
L9F03:  .byte   0
L9F04:  .byte   0
L9F05:  .byte   0
L9F06:  .byte   0
L9F07:  ldy     #$00
        lda     ($06),y
        sta     L9EFE
        ldy     #$08
L9F10:  lda     ($06),y
        sta     L9EFE,y
        dey
        bne     L9F10
        lda     L9EFE
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        jsr     LA18A
        lda     L8E07
        cmp     L9F05
        lda     L8E08
        sbc     L9F06
        bpl     L9F8C
        lda     L8E1B
        cmp     L9F01
        lda     L8E1C
        sbc     L9F02
        bmi     L9F8C
        lda     L8E19
        cmp     L9F03
        lda     L8E1A
        sbc     L9F04
        bpl     L9F8C
        lda     L8E15
        cmp     L9EFF
        lda     L8E16
        sbc     L9F00
        bmi     L9F8C
        lda     L8E23
        cmp     L9F05
        lda     L8E24
        sbc     L9F06
        bmi     L9F8F
        lda     L8E21
        cmp     L9F03
        lda     L8E22
        sbc     L9F04
        bpl     L9F8C
        lda     L8E0D
        cmp     L9EFF
        lda     L8E0E
        sbc     L9F00
        bpl     L9F8F
L9F8C:  lda     #$00
        rts

L9F8F:  lda     #$01
        rts

L9F92:  .byte   0
L9F93:  .byte   0
L9F94:  .byte   0
        .byte   0
        .byte   0
        .byte   0
L9F98:  lda     #$00
        sta     L9F92
        beq     L9FA4
L9F9F:  lda     #$80
        sta     L9F92
L9FA4:  ldy     #$02
        lda     ($06),y
        and     #$0F
        bne     L9FB4
        lda     L9F92
        ora     #$40
        sta     L9F92
L9FB4:  ldy     #$03
L9FB6:  lda     ($06),y
        sta     L8E22,y
        iny
        cpy     #$09
        bne     L9FB6
        jsr     LA365
        lda     L8E29
        sta     $08
        lda     L8E2A
        sta     $09
        ldy     #$0B
L9FCF:  lda     ($08),y
        sta     L8E29,y
        dey
        bpl     L9FCF
        bit     L9F92
        bpl     L9FDF
        jsr     LA12C
L9FDF:  jsr     LA382
        ldy     #$09
L9FE4:  lda     ($06),y
        sta     L8E4B,y
        iny
        cpy     #$1D
        bne     L9FE4
L9FEE:  lda     draw_text_params::length
        sta     measure_text_params::length
        A2D_CALL A2D_MEASURE_TEXT, measure_text_params
        lda     measure_text_params::width
        cmp     L8E31
        bcs     LA010
        inc     draw_text_params::length
        ldx     draw_text_params::length
        lda     #$20
        sta     text_buffer-1,x
        jmp     L9FEE

LA010:  lsr     a
        sta     L9416
        lda     L8E31
        lsr     a
        sta     set_pos_params2
        lda     L9416
        sec
        sbc     set_pos_params2
        sta     set_pos_params2
        lda     draw_bitmap_params2
        sec
        sbc     set_pos_params2
        sta     set_pos_params2
        lda     L8E26
        sbc     #$00
        sta     L9416
        lda     L8E27
        clc
        adc     L8E33
        sta     L9417
        lda     L8E28
        adc     #$00
        sta     L9418
        lda     L9417
        clc
        adc     #$01
        sta     L9417
        lda     L9418
        adc     #$00
        sta     L9418
        lda     L9417
        clc
        adc     glyph_height
        sta     L9417
        lda     L9418
        adc     #$00
        sta     L9418
        ldx     #$03
LA06E:  lda     set_pos_params2,x
        sta     L9F94,x
        dex
        bpl     LA06E
        bit     L9F92
        bvc     LA097
        A2D_CALL A2D_QUERY_SCREEN, query_screen_params
        jsr     LA63F
LA085:  jsr     LA6A3
        jsr     LA097
        lda     L9F93
        bne     LA085
        A2D_CALL A2D_SET_BOX, query_screen_params
        rts

LA097:  A2D_CALL A2D_HIDE_CURSOR, $93BC ; These params should be ignored - bogus?
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params5
        bit     L9F92
        bpl     LA0C2
        bit     L9F92
        bvc     LA0B6
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params
        jmp     LA0C2

LA0B6:  A2D_CALL A2D_DRAW_BITMAP, draw_bitmap_params
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params3
LA0C2:  A2D_CALL A2D_DRAW_BITMAP, draw_bitmap_params2
        ldy     #$02
        lda     ($06),y
        and     #$80
        beq     LA0F2
        jsr     LA14D
        A2D_CALL A2D_SET_PATTERN, dark_pattern
        bit     L9F92
        bmi     LA0E6
        A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params4
        beq     LA0EC
LA0E6:  A2D_CALL A2D_SET_FILL_MODE, set_fill_mode_params2
LA0EC:  A2D_CALL A2D_FILL_RECT, fill_rect_params6
LA0F2:  ldx     #$03
LA0F4:  lda     L9F94,x
        sta     set_pos_params2,x
        dex
        bpl     LA0F4
        A2D_CALL A2D_SET_POS, set_pos_params2
        bit     L9F92
        bmi     LA10C
        lda     #$7F
        bne     LA10E
LA10C:  lda     #$00
LA10E:  sta     set_text_mask_params
        A2D_CALL A2D_SET_TEXT_MASK, set_text_mask_params
        lda     text_buffer+1
        and     #$DF
        sta     text_buffer+1
        A2D_CALL A2D_DRAW_TEXT, draw_text_params
        A2D_CALL A2D_SHOW_CURSOR
        rts

LA12C:  ldx     #$0F
LA12E:  lda     draw_bitmap_params2,x
        sta     draw_bitmap_params,x
        dex
        bpl     LA12E
        ldy     L8E43
LA13A:  lda     draw_bitmap_params::stride
        clc
        adc     draw_bitmap_params::addr
        sta     draw_bitmap_params::addr
        bcc     LA149
        inc     draw_bitmap_params::addr+1
LA149:  dey
        bpl     LA13A
        rts

LA14D:  ldx     #$00
LA14F:  lda     draw_bitmap_params2,x
        clc
        adc     L8E2D,x
        sta     fill_rect_params6,x
        lda     L8E26,x
        adc     L8E2E,x
        sta     L8E46,x
        lda     draw_bitmap_params2,x
        clc
        adc     L8E31,x
        sta     L8E49,x
        lda     L8E26,x
        adc     L8E32,x
        sta     L8E4A,x
        inx
        inx
        cpx     #$04
        bne     LA14F
        lda     L8E4B
        sec
        sbc     #$01
        sta     L8E4B
        bcs     LA189
        dec     L8E4C
LA189:  rts

LA18A:  jsr     LA365
        ldy     #$06
        ldx     #$03
LA191:  lda     ($06),y
        sta     L8E05,x
        dey
        dex
        bpl     LA191
        lda     L8E07
        sta     L8E0B
        lda     L8E08
        sta     L8E0C
        lda     L8E05
        sta     L8E21
        lda     L8E06
        sta     L8E22
        ldy     #$07
        lda     ($06),y
        sta     $08
        iny
        lda     ($06),y
        sta     $09
        ldy     #$08
        lda     ($08),y
        clc
        adc     L8E05
        sta     L8E09
        sta     L8E0D
        iny
        lda     ($08),y
        adc     L8E06
        sta     L8E0A
        sta     L8E0E
        ldy     #$0A
        lda     ($08),y
        clc
        adc     L8E07
        sta     L8E0F
        iny
        lda     ($08),y
        adc     L8E08
        sta     L8E10
        lda     L8E0F
        clc
        adc     #$02
        sta     L8E0F
        sta     L8E13
        sta     L8E1F
        sta     L8E23
        lda     L8E10
        adc     #$00
        sta     L8E10
        sta     L8E14
        sta     L8E20
        sta     L8E24
        lda     glyph_height
        clc
        adc     L8E0F
        sta     L8E17
        sta     L8E1B
        lda     L8E10
        adc     #$00
        sta     L8E18
        sta     L8E1C
        ldy     #$1C
        ldx     #$13
LA22A:  lda     ($06),y
        sta     text_buffer-1,x
        dey
        dex
        bpl     LA22A
LA233:  lda     draw_text_params::length
        sta     measure_text_params::length
        A2D_CALL A2D_MEASURE_TEXT, measure_text_params
        ldy     #$08
        lda     measure_text_params::width
        cmp     ($08),y
        bcs     LA256
        inc     draw_text_params::length
        ldx     draw_text_params::length
        lda     #$20
        sta     text_buffer-1,x
        jmp     LA233

LA256:  lsr     a
        sta     LA2A5
        lda     ($08),y
        lsr     a
        sta     LA2A4
        lda     LA2A5
        sec
        sbc     LA2A4
        sta     LA2A4
        lda     L8E05
        sec
        sbc     LA2A4
        sta     L8E1D
        sta     L8E19
        lda     L8E06
        sbc     #$00
        sta     L8E1E
        sta     L8E1A
        inc     measure_text_params::width
        inc     measure_text_params::width
        lda     L8E19
        clc
        adc     measure_text_params::width
        sta     L8E11
        sta     L8E15
        lda     L8E1A
        adc     #$00
        sta     L8E12
        sta     L8E16
        jsr     LA382
        rts

LA2A4:  .byte   0
LA2A5:  .byte   0
        jmp     LA2AE

LA2A9:  .byte   0
LA2AA:  jsr     LA382
        rts

LA2AE:  jsr     LA365
        ldx     L8E95
        dex
LA2B5:  bmi     LA2AA
        txa
        pha
        lda     L8E96,x
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$02
        lda     ($06),y
        and     #$0F
        bne     LA2DD
        ldy     #$00
        lda     ($06),y
        sta     LA2A9
        jsr     L93BC
        .byte   $03
        lda     #$A2
LA2DD:  pla
        tax
        dex
        jmp     LA2B5

LA2E3:  stx     LA322
        sta     LA323
        ldx     #$00
LA2EB:  lda     L8E96,x
        cmp     LA323
        beq     LA2FA
        inx
        cpx     L8E95
        bne     LA2EB
        rts

LA2FA:  lda     L8E97,x
        sta     L8E96,x
        inx
        cpx     L8E95
        bne     LA2FA
        ldx     L8E95
LA309:  cpx     LA322
        beq     LA318
        lda     L8E94,x
        sta     L8E95,x
        dex
        jmp     LA309

LA318:  ldx     LA322
        lda     LA323
        sta     L8E95,x
        rts

LA322:  .byte   0
LA323:  .byte   0
LA324:  stx     LA363
        sta     LA364
        ldx     #$00
LA32C:  lda     L9017,x
        cmp     LA364
        beq     LA33B
        inx
        cpx     L9016
        bne     LA32C
        rts

LA33B:  lda     L9018,x
        sta     L9017,x
        inx
        cpx     L9016
        bne     LA33B
        ldx     L9016
LA34A:  cpx     LA363
        beq     LA359
        lda     L9015,x
        sta     L9016,x
        dex
        jmp     LA34A

LA359:  ldx     LA363
        lda     LA364
        sta     L9016,x
        rts

LA363:  .byte   0
LA364:  .byte   0
LA365:  pla
        sta     LA380
        pla
        sta     LA381
        ldx     #$00
LA36F:  lda     $06,x
        pha
        inx
        cpx     #$04
        bne     LA36F
        lda     LA381
        pha
        lda     LA380
        pha
        rts

LA380:  .byte   0
LA381:  .byte   0
LA382:  pla
        sta     LA39B
        pla
        sta     LA39C
        ldx     #$03
LA38C:  pla
        sta     $06,x
        dex
        bpl     LA38C
        lda     LA39C
        pha
        lda     LA39B
        pha
        rts

LA39B:  .byte   0
LA39C:  .byte   0
LA39D:  A2D_CALL A2D_QUERY_SCREEN, query_screen_params
        A2D_CALL A2D_SET_STATE, query_screen_params
        jmp     LA3B9

LA3AC:  .byte   0
LA3AD:  .byte   0
LA3AE:  .byte   0
LA3AF:  .byte   0
LA3B0:  .byte   0
LA3B1:  .byte   0
LA3B2:  .byte   0
LA3B3:  .byte   0
        .byte   0
        .byte   0
        .byte   0
LA3B7:  .byte   0
LA3B8:  .byte   0
LA3B9:  ldy     #$00
        lda     ($06),y
        sta     LA3AC
        iny
        iny
        lda     ($06),y
        and     #$0F
        sta     LA3AD
        beq     LA3F4
        lda     #$80
        sta     LA3B7
        A2D_CALL A2D_SET_PATTERN, white_pattern2
        A2D_CALL $41, LA3B8
        lda     LA3B8
        sta     query_state_params
        A2D_CALL A2D_QUERY_STATE, query_state_params
        jsr     LA4CC
        jsr     LA938
        jsr     LA41C
        jmp     LA446

LA3F4:  A2D_CALL A2D_QUERY_SCREEN, query_screen_params
        jsr     LA63F
LA3FD:  jsr     LA6A3
        jsr     LA411
        lda     L9F93
        bne     LA3FD
        A2D_CALL A2D_SET_BOX, query_screen_params
        jmp     LA446

LA411:  lda     #$00
        sta     LA3B7
        A2D_CALL A2D_SET_PATTERN, checkerboard_pattern2
LA41C:  lda     L8E07
        sta     LA3B1
        lda     L8E08
        sta     LA3B2
        lda     L8E1D
        sta     LA3AF
        lda     L8E1E
        sta     LA3B0
        ldx     #$03
LA436:  lda     L8E15,x
        sta     LA3B3,x
        dex
        bpl     LA436
        A2D_CALL $15, L8E03
        rts

LA446:  jsr     LA365
        ldx     L8E95
        dex
LA44D:  cpx     #$FF
        bne     LA466
        bit     LA3B7
        bpl     LA462
        A2D_CALL A2D_QUERY_SCREEN, query_screen_params
        A2D_CALL A2D_SET_STATE, set_state_params
LA462:  jsr     LA382
        rts

LA466:  txa
        pha
        lda     L8E96,x
        cmp     LA3AC
        beq     LA4C5
        asl     a
        tax
        lda     L8F15,x
        sta     $08
        lda     L8F16,x
        sta     $09
        ldy     #$02
        lda     ($08),y
        and     #$07
        cmp     LA3AD
        bne     LA4C5
        lda     L9015
        beq     LA49D
        ldy     #$00
        lda     ($08),y
        ldx     #$00
LA492:  cmp     L9017,x
        beq     LA4C5
        inx
        cpx     L9016
        bne     LA492
LA49D:  ldy     #$00
        lda     ($08),y
        sta     LA3AE
        bit     LA3B7
        bpl     LA4AC
        jsr     LA4D3
LA4AC:  jsr     L93BC
        ora     LA3AE
        beq     LA4BA

        jsr     L93BC
        .byte   $03
        .addr   $A3AE

LA4BA:  bit     LA3B7
        bpl     LA4C5
        lda     LA3AE
        jsr     LA4DC
LA4C5:  pla
        tax
        dex
        jmp     LA44D

LA4CB:  .byte   0

LA4CC:  lda     #$80
        sta     LA4CB
        bmi     LA4E2
LA4D3:  pha
        lda     #$40
        sta     LA4CB
        jmp     LA4E2

LA4DC:  pha
        lda     #$00
        sta     LA4CB
LA4E2:  ldy     #$00
LA4E4:  lda     set_state_params,y
        sta     LA567,y
        iny
        cpy     #$04
        bne     LA4E4
        ldy     #$08
LA4F1:  lda     set_state_params,y
        sta     LA563,y
        iny
        cpy     #$0C
        bne     LA4F1
        bit     LA4CB
        bmi     LA506
        bvc     LA56F
        jmp     LA5CB

LA506:  ldx     #$00
LA508:  lda     L8E05,x
        sec
        sbc     LA567
        sta     L8E05,x
        lda     L8E06,x
        sbc     LA568
        sta     L8E06,x
        lda     L8E07,x
        sec
        sbc     LA569
        sta     L8E07,x
        lda     L8E08,x
        sbc     LA56A
        sta     L8E08,x
        inx
        inx
        inx
        inx
        cpx     #$20
        bne     LA508
        ldx     #$00
        lda     L8E05,x
        clc
        adc     LA56B
        sta     L8E05,x
        lda     L8E06,x
        adc     LA56C
        sta     L8E06,x
        lda     L8E07,x
        clc
        adc     LA56D
        sta     L8E07,x
        lda     L8E08,x
        adc     LA56E
        sta     L8E08,x
        inx
        inx
        inx
        inx
        .byte   $E0
LA563:  jsr     LD2D0
        rts

LA567:  .byte   0
LA568:  .byte   0
LA569:  .byte   0
LA56A:  .byte   0
LA56B:  .byte   0
LA56C:  .byte   0
LA56D:  .byte   0
LA56E:  .byte   0
LA56F:  pla
        tay
        jsr     LA365
        tya
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$03
        lda     ($06),y
        clc
        adc     LA567
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA568
        sta     ($06),y
        iny
        lda     ($06),y
        clc
        adc     LA569
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA56A
        sta     ($06),y
        ldy     #$03
        lda     ($06),y
        sec
        sbc     LA56B
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA56C
        sta     ($06),y
        iny
        lda     ($06),y
        sec
        sbc     LA56D
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA56E
        sta     ($06),y
        jsr     LA382
        rts

LA5CB:  pla
        tay
        jsr     LA365
        tya
        asl     a
        tax
        lda     L8F15,x
        sta     $06
        lda     L8F16,x
        sta     $07
        ldy     #$03
        lda     ($06),y
        sec
        sbc     LA567
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA568
        sta     ($06),y
        iny
        lda     ($06),y
        sec
        sbc     LA569
        sta     ($06),y
        iny
        lda     ($06),y
        sbc     LA56A
        sta     ($06),y
        ldy     #$03
        lda     ($06),y
        clc
        adc     LA56B
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA56C
        sta     ($06),y
        iny
        lda     ($06),y
        clc
        adc     LA56D
        sta     ($06),y
        iny
        lda     ($06),y
        adc     LA56E
        sta     ($06),y
        jsr     LA382
        rts

LA627:  .byte   $00
LA628:  .byte   $00
LA629:  .byte   $00
LA62A:  .byte   $00
LA62B:  .byte   $00
LA62C:  .byte   $00,$00,$00
set_box_params2:
        .byte   $00
LA630:  .byte   $00
LA631:  .byte   $00
LA632:  .byte   $00,$00,$20,$80,$00
LA637:  .byte   $00
LA638:  .byte   $00
LA639:  .byte   $00
LA63A:  .byte   $00
LA63B:  .byte   $00
LA63C:  .byte   $00
LA63D:  .byte   $00
LA63E:  .byte   $00
LA63F:  jsr     LA18A
        lda     L8E07
        sta     LA629
        sta     LA639
        sta     LA631
        lda     L8E08
        sta     LA62A
        sta     LA63A
        sta     LA632
        lda     L8E19
        sta     LA627
        sta     LA637
        sta     set_box_params2
        lda     L8E1A
        sta     LA628
        sta     LA638
        sta     LA630
        ldx     #$03
LA674:  lda     L8E15,x
        sta     LA62B,x
        sta     LA63B,x
        dex
        bpl     LA674
        lda     LA62B
        cmp     #$2F
        lda     LA62C
        sbc     #$02
        bmi     LA69C
        lda     #$2E
        sta     LA62B
        sta     LA63B
        lda     #$02
        sta     LA62C
        sta     LA63C
LA69C:  A2D_CALL A2D_SET_BOX, set_box_params2
        rts

LA6A3:  lda     #$00
        jmp     LA6C7

query_target_params:  .byte   $00,$00,$00,$00
LA6AC:  .byte   $00
LA6AD:  .byte   $00
LA6AE:  .byte   $00
LA6AF:  .byte   $00
LA6B0:  .byte   $00
LA6B1:  .byte   $00
LA6B2:  .byte   $00
LA6B3:  .byte   $00
LA6B4:  .byte   $00
LA6B5:  .byte   $00
LA6B6:  .byte   $00
LA6B7:  .byte   $00
LA6B8:  .byte   $00
LA6B9:  .byte   $00
LA6BA:  .byte   $00
LA6BB:  .byte   $00
LA6BC:  .byte   $00
LA6BD:  .byte   $00
LA6BE:  .byte   $00
LA6BF:  .byte   $00
LA6C0:  .byte   $00
LA6C1:  .byte   $00
LA6C2:  .byte   $00
LA6C3:  .byte   $00
LA6C4:  .byte   $00
LA6C5:  .byte   $00
LA6C6:  .byte   $00
LA6C7:  lda     L9F93
        beq     LA6FA
        lda     LA63B
        clc
        adc     #$01
        sta     LA637
        sta     set_box_params2
        lda     LA63C
        adc     #$00
        sta     LA638
        sta     LA630
        ldx     #$05
LA6E5:  lda     LA629,x
        sta     LA639,x
        dex
        bpl     LA6E5
        lda     LA639
        sta     LA631
        lda     LA63A
        sta     LA632
LA6FA:  lda     LA637
        sta     LA6B3
        sta     LA6BF
        lda     LA638
        sta     LA6B4
        sta     LA6C0
        lda     LA639
        sta     LA6B5
        sta     LA6B9
        lda     LA63A
        sta     LA6B6
        sta     LA6BA
        lda     LA63B
        sta     LA6B7
        sta     LA6BB
        lda     LA63C
        sta     LA6B8
        sta     LA6BC
        lda     LA63D
        sta     LA6BD
        sta     LA6C1
        lda     LA63E
        sta     LA6BE
        sta     LA6C2
        lda     #$00
        sta     LA6B0
LA747:  lda     LA6B0
        cmp     #$04
        bne     LA775
        lda     #$00
        sta     LA6B0
LA753:  A2D_CALL A2D_SET_BOX, set_box_params2
        lda     LA63C
        cmp     LA62C
        bne     LA76F
        lda     LA63B
        cmp     LA62B
        bcc     LA76F
        lda     #$00
        sta     L9F93
        rts

LA76F:  lda     #$01
        sta     L9F93
        rts

LA775:  lda     LA6B0
        asl     a
        asl     a
        tax
        ldy     #$00
LA77D:  lda     LA6B3,x
        sta     query_target_params,y
        iny
        inx
        cpy     #$04
        bne     LA77D
        inc     LA6B0
        A2D_CALL A2D_QUERY_TARGET, query_target_params
        lda     LA6AC
        beq     LA747
        lda     LA6AD
        sta     query_state_params
        A2D_CALL A2D_QUERY_STATE, query_state_params
        jsr     LA365
        A2D_CALL $3B, LA6AD
        lda     LA6AE
        sta     $06
        lda     LA6AF
        sta     $07
        ldy     #$01
        lda     ($06),y
        and     #$01
        bne     LA7C3
        sta     LA6B2
        beq     LA7C8
LA7C3:  lda     #$80
        sta     LA6B2
LA7C8:  ldy     #$04
        lda     ($06),y
        and     #$80
        sta     LA6B1
        iny
        lda     ($06),y
        and     #$80
        lsr     a
        ora     LA6B1
        sta     LA6B1
        lda     set_state_params
        sec
        sbc     #$02
        sta     set_state_params
        lda     L936D
        sbc     #$00
        sta     L936D
        lda     L9374
        sec
        sbc     #$02
        sta     L9374
        lda     L9375
        sbc     #$00
        sta     L9375
        bit     LA6B2
        bmi     LA820
        lda     L936E
        sec
        sbc     #$0E
        sta     L936E
        bcs     LA812
        dec     L936F
LA812:  lda     L9376
        sec
        sbc     #$0E
        sta     L9376
        bcs     LA820
        dec     L9377
LA820:  bit     LA6B1
        bpl     LA833
        lda     L937A
        clc
        adc     #$0C
        sta     L937A
        bcc     LA833
        inc     L937B
LA833:  bit     LA6B1
        bvc     LA846
        lda     L9378
        clc
        adc     #$14
        sta     L9378
        bcc     LA846
        inc     L9379
LA846:  jsr     LA382
        lda     L9378
        sec
        sbc     L9374
        sta     LA6C3
        lda     L9379
        sbc     L9375
        sta     LA6C4
        lda     L937A
        sec
        sbc     L9376
        sta     LA6C5
        lda     L937B
        sbc     L9377
        sta     LA6C6
        lda     LA6C3
        clc
        adc     set_state_params
        sta     LA6C3
        lda     L936D
        adc     LA6C4
        sta     LA6C4
        lda     LA6C5
        clc
        adc     L936E
        sta     LA6C5
        lda     LA6C6
        adc     L936F
        sta     LA6C6
        lda     LA63B
        cmp     LA6C3
        lda     LA63C
        sbc     LA6C4
        bmi     LA8B7
        lda     LA6C3
        clc
        adc     #$01
        sta     LA63B
        lda     LA6C4
        adc     #$00
        sta     LA63C
        jmp     LA8D4

LA8B7:  lda     set_state_params
        cmp     LA637
        lda     L936D
        sbc     LA638
        bmi     LA8D4
        lda     set_state_params
        sta     LA63B
        lda     L936D
        sta     LA63C
        jmp     LA6FA

LA8D4:  lda     L936E
        cmp     LA639
        lda     L936F
        sbc     LA63A
        bmi     LA8F6
        lda     L936E
        sta     LA63D
        lda     L936F
        sta     LA63E
        lda     #$01
        sta     L9F93
        jmp     LA6FA

LA8F6:  lda     LA6C5
        cmp     LA63D
        lda     LA6C6
        sbc     LA63E
        bpl     LA923
        lda     LA6C5
        clc
        adc     #$02
        sta     LA639
        sta     LA631
        lda     LA6C6
        adc     #$00
        sta     LA63A
        sta     LA632
        lda     #$01
        sta     L9F93
        jmp     LA6FA

LA923:  lda     LA63B
        sta     LA637
        sta     set_box_params2
        lda     LA63C
        sta     LA638
        sta     LA630
        jmp     LA753

LA938:  lda     L936E
        clc
        adc     #$0F
        sta     L936E
        lda     L936F
        adc     #$00
        sta     L936F
        lda     L9376
        clc
        adc     #$0F
        sta     L9376
        lda     L9377
        adc     #$00
        sta     L9377
        A2D_CALL A2D_SET_STATE, set_state_params
        rts

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$8C
        .byte   $A9,$04,$00,$00,$00,$01,$00,$1A
        .byte   $00,$0F,$00,$55,$2A,$55,$2A,$7F
        .byte   $7F,$7F,$7F,$03,$60,$01,$30,$03
        .byte   $60,$01,$70,$03,$60,$01,$30,$03
        .byte   $60,$01,$70,$03,$00,$00,$30,$03
        .byte   $60,$01,$70,$03,$70,$03,$30,$03
        .byte   $60,$01,$70,$03,$00,$00,$30,$03
        .byte   $00,$00,$70,$0D,$00,$00,$30,$03
        .byte   $00,$00,$70,$03,$00,$00,$30,$7F
        .byte   $7F,$7F,$7F,$D8,$A9,$06,$00,$01
        .byte   $00,$00,$00,$26,$00,$0B,$00,$7F
        .byte   $7F,$7F,$7F,$7F,$5F,$03,$00,$00
        .byte   $00,$00,$38,$03,$00,$00,$00,$00
        .byte   $58,$03,$00,$00,$00,$00,$38,$03
        .byte   $78,$71,$33,$30,$58,$03,$18,$33
        .byte   $76,$3D,$38,$03,$78,$71,$37,$37
        .byte   $58,$03,$18,$33,$36,$30,$38,$03
        .byte   $00,$00,$00,$00,$58,$7F,$7F,$7F
        .byte   $19,$33,$38,$2A,$55,$2A,$19,$33
        .byte   $58,$55,$2A,$55,$7F,$7F,$3F,$2C
        .byte   $AA,$03,$00,$00,$00,$00,$00,$14
        .byte   $00,$0B,$00,$7F,$7F,$3F,$63,$00
        .byte   $73,$63,$00,$73,$63,$7F,$63,$03
        .byte   $00,$60,$03,$00,$60,$73,$7F,$67
        .byte   $33,$00,$66,$33,$00,$66,$33,$00
        .byte   $66,$33,$00,$66,$7F,$7F,$7F,$5C
        .byte   $AA,$08,$00,$01,$00,$00,$00,$33
        .byte   $00,$09,$00,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$7F,$57,$03,$00,$00,$00,$00
        .byte   $00,$00,$2C,$03,$00,$00,$00,$00
        .byte   $00,$00,$5C,$03,$00,$00,$00,$00
        .byte   $00,$00,$2C,$63,$01,$00,$00,$00
        .byte   $00,$00,$5C,$03,$00,$00,$00,$00
        .byte   $00,$00,$5C,$03,$00,$00,$00,$00
        .byte   $00,$00,$2C,$03,$00,$00,$00,$00
        .byte   $00,$00,$5C,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$7F,$57,$75,$2A,$55,$2A,$55
        .byte   $2A,$75,$2A,$B8,$AA,$05,$00,$07
        .byte   $00,$01,$00,$1B,$00,$12,$00,$00
        .byte   $00,$00,$00,$00,$00,$55,$FF,$55
        .byte   $00,$00,$2A,$E3,$2A,$00,$00,$FF
        .byte   $FF,$FF,$00,$00,$03,$00,$E0,$00
        .byte   $00,$FF,$FF,$FF,$00,$00,$03,$00
        .byte   $60,$00,$00,$43,$10,$64,$00,$00
        .byte   $23,$08,$62,$00,$00,$23,$08,$62
        .byte   $00,$00,$23,$08,$62,$00,$00,$23
        .byte   $08,$62,$00,$00,$23,$08,$62,$00
        .byte   $00,$23,$08,$62,$00,$00,$23,$08
        .byte   $62,$00,$00,$23,$08,$62,$00,$00
        .byte   $43,$10,$64,$00,$00,$03,$00,$60
        .byte   $00,$00,$FF,$FF,$FF,$00,$00,$00
        .byte   $00,$00,$00


        PASCAL_STRING A2D_GLYPH_CAPPLE
        PASCAL_STRING "File"
        PASCAL_STRING "View"
        PASCAL_STRING "Special"
        PASCAL_STRING "Startup"
        PASCAL_STRING "Selector"

        PASCAL_STRING "New Folder ..."
        PASCAL_STRING "Open"
        PASCAL_STRING "Close"
        PASCAL_STRING "Close All"
        PASCAL_STRING "Select All"
        PASCAL_STRING "Copy a File ..."
        PASCAL_STRING "Delete a File ..."
        PASCAL_STRING "Eject"
        PASCAL_STRING "Quit"

        PASCAL_STRING "By Icon"
        PASCAL_STRING "By Name"
        PASCAL_STRING "By Date"
        PASCAL_STRING "By Size"
        PASCAL_STRING "By Type"

        PASCAL_STRING "Check Drives"
        PASCAL_STRING "Format a Disk ..."
        PASCAL_STRING "Erase a Disk ..."
        PASCAL_STRING "Disk Copy ..."
        PASCAL_STRING "Lock ..."
        PASCAL_STRING "Unlock ..."
        PASCAL_STRING "Get Info ..."
        PASCAL_STRING "Get Size ..."
        PASCAL_STRING "Rename an Icon ..."

        .byte   $06,$00,$01,$00,$1C
        .byte   $AB,$94,$E5,$00,$00,$00,$00,$00
        .byte   $00,$02,$00,$1E,$AB,$8E,$AC,$00
        .byte   $00,$00,$00,$00,$00,$04,$00,$23
        .byte   $AB,$DC,$AC,$00,$00,$00,$00,$00
        .byte   $00,$05,$00,$28,$AB,$00,$AD,$00
        .byte   $00,$00,$00,$00,$00,$08,$00,$30
        .byte   $AB,$D6,$E2,$00,$00,$00,$00,$00
        .byte   $00,$03,$00,$38,$AB,$F2,$E4,$00
        .byte   $00,$00,$00,$00,$00,$0C,$00,$00
        .byte   $00,$00,$00,$01,$00,$46,$66,$41
        .byte   $AB,$40,$00,$13,$00,$00,$00,$01
        .byte   $00,$4F,$6F,$50,$AB,$01,$00,$43
        .byte   $63,$55,$AB,$01,$00,$42,$62,$5B
        .byte   $AB,$01,$00,$41,$61,$65,$AB,$40
        .byte   $00,$13,$00,$00,$00,$01,$00,$59
        .byte   $79,$70,$AB,$01,$00,$44,$64,$80
        .byte   $AB,$40,$00,$13,$00,$00,$00,$01
        .byte   $00,$45,$65,$92,$AB,$01,$00,$51
        .byte   $71,$98,$AB,$05,$00,$00,$00,$00
        .byte   $00,$01,$00,$4A,$6A,$9D,$AB,$01
        .byte   $00,$4E,$6E,$A5,$AB,$01,$00,$54
        .byte   $74,$AD,$AB,$01,$00,$4B,$6B,$B5
        .byte   $AB,$01,$00,$4C,$6C,$BD,$AB,$0D
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C5,$AB,$40,$00,$13,$00,$00
        .byte   $00,$01,$00,$53,$73,$D2,$AB,$01
        .byte   $00,$5A,$7A,$E4,$AB,$00,$00,$00
        .byte   $00,$F5,$AB,$40,$00,$13,$00,$00
        .byte   $00,$00,$00,$00,$00,$03,$AC,$00
        .byte   $00,$00,$00,$0C,$AC,$40,$00,$13
        .byte   $00,$00,$00,$01,$00,$49,$69,$17
        .byte   $AC,$00,$00,$00,$00,$24,$AC,$40
        .byte   $00,$13,$00,$00,$00,$00,$00,$00
        .byte   $00,$31,$AC,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$04
        .byte   $00,$02,$00,$8C,$01,$62,$00,$05
        .byte   $00,$03,$00,$8B,$01,$61,$00,$28
        .byte   $00,$51,$00,$8C,$00,$5C,$00,$C1
        .byte   $00,$1E,$00,$25,$01,$29,$00,$04
        .byte   $01,$51,$00,$68,$01,$5C,$00,$C8
        .byte   $00,$51,$00,$F0,$00,$5C,$00,$04
        .byte   $01,$51,$00,$2C,$01,$5C,$00,$40
        .byte   $01,$51,$00,$68,$01,$5C,$00,$0F
        .byte   $4F,$4B,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$0D,$09
        .byte   $01,$5B,$00,$2D,$00,$5B,$00,$CD
        .byte   $00,$5B,$00,$09,$01,$5B,$00,$45
        .byte   $01,$5B,$00,$1C,$00,$70,$00,$1C
        .byte   $00,$87,$00,$00,$7F,$27,$00,$19
        .byte   $00,$68,$01,$50,$00,$28,$00,$3C
        .byte   $00,$68,$01,$50,$00,$41,$00,$2B
        .byte   $00,$41,$00,$33,$00,$41,$00,$23
        .byte   $00,$8A,$01,$2A,$00,$41,$00,$2B
        .byte   $00,$8A,$01,$32,$00

        PASCAL_STRING "Cancel        Esc"
        PASCAL_STRING " Yes"
        PASCAL_STRING " No"
        PASCAL_STRING " All"
        PASCAL_STRING "Source filename:"
        PASCAL_STRING "Destination filename:"

        .byte   $04,$00,$02,$00
        .byte   $8C,$01,$6C,$00,$05,$00,$03,$00
        .byte   $8B,$01,$6B,$00

        PASCAL_STRING "Apple II DeskTop"
        PASCAL_STRING "Copyright Apple Computer Inc., 1986"
        PASCAL_STRING "Copyright Version Soft, 1985 - 1986"
        PASCAL_STRING "All Rights Reserved"
        PASCAL_STRING "Authors: Stephane Cavril, Bernard Gallet, Henri Lamiraux"
        PASCAL_STRING "Richard Danais and Luc Barthelet"
        PASCAL_STRING "With thanks to: A. Gerard, J. Gerber, P. Pahl, J. Bernard"
        PASCAL_STRING "November 26, 1986"
        PASCAL_STRING "Version 1.1"

        PASCAL_STRING "Copy ..."
        PASCAL_STRING "Now Copying "
        PASCAL_STRING "from:"
        PASCAL_STRING "to :"
        PASCAL_STRING "Files remaining to copy: "
        PASCAL_STRING "That file already exists. Do you want to write over it ?"
        PASCAL_STRING "This file is too large to copy, click OK to continue."

        .byte   $6E,$00,$23
        .byte   $00,$AA,$00,$3B,$00

        PASCAL_STRING "Delete ..."
        PASCAL_STRING "Click OK to delete:"
        PASCAL_STRING "Clicking OK will immediately empty the trash of:"
        PASCAL_STRING "File:"
        PASCAL_STRING "Files remaining to be deleted:"
        PASCAL_STRING "This file is locked, do you want to delete it anyway ?"

        .byte   $91,$00,$3B,$00,$C8,$00,$3B,$00,$2C,$01,$3B,$00

        PASCAL_STRING "New Folder ..."
        PASCAL_STRING "in:"
        PASCAL_STRING "Enter the folder name:"
        PASCAL_STRING "Rename an Icon ..."
	PASCAL_STRING "Rename: "
        PASCAL_STRING "New name:"
        PASCAL_STRING "Get Info ..."
        PASCAL_STRING "Name"
        PASCAL_STRING "Locked"
        PASCAL_STRING "Size"
        PASCAL_STRING "Creation date"
        PASCAL_STRING "Last modification"
        PASCAL_STRING "Type"
        PASCAL_STRING "Write protected"
        PASCAL_STRING "Blocks free/size"
        PASCAL_STRING ": "


        .byte   $A0,$00,$3B,$00
        .byte   $91,$00,$3B,$00,$C8,$00,$3B,$00
        .byte   $B9,$00,$3B,$00,$CD,$00,$3B,$00
        .byte   $C3,$00,$3B,$00

        PASCAL_STRING "Format a Disk ..."
        PASCAL_STRING "Select the location where the disk is to be formatted"
        PASCAL_STRING "Enter the name of the new volume:"
        PASCAL_STRING "Do you want to format "
        PASCAL_STRING "Formatting the disk...."
        PASCAL_STRING "Formatting error. Check drive, then click OK to try again."
        PASCAL_STRING "Erase a Disk ..."
        PASCAL_STRING "Select the location where the disk is to be erased"
        PASCAL_STRING "Do you want to erase "
        PASCAL_STRING "Erasing the disk...."
        PASCAL_STRING "Erasing error. Check drive, then click OK to try again."
        PASCAL_STRING "Unlock ..."

        PASCAL_STRING "Click OK to unlock "
        PASCAL_STRING "Files remaining to be unlocked: "
        PASCAL_STRING "Lock ..."
        PASCAL_STRING "Click OK to lock "
        PASCAL_STRING "Files remaining to be locked: "

        PASCAL_STRING "Get Size ..."
        PASCAL_STRING "Number of files"
        PASCAL_STRING "Blocks used on disk"

        .byte   $6E,$00,$23,$00,$6E,$00,$2B,$00

        PASCAL_STRING "DownLoad ..."
        PASCAL_STRING "The RAMCard is full. The copy was not completed."
        PASCAL_STRING " "
        PASCAL_STRING "Warning !"
        PASCAL_STRING "Please insert the system disk."
        PASCAL_STRING "The Selector list is full. You must delete an entry"
        PASCAL_STRING "before you can add new entries."
        PASCAL_STRING "A window must be closed before opening this new catalog."

        PASCAL_STRING "There are too many windows open on the desktop !"
        PASCAL_STRING "Do you want to save the new Selector list"
        PASCAL_STRING "on the system disk ?"


        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$4C
        .byte   $D7,$B9,$00,$00,$00,$00,$00,$00
        .byte   $00,$FE,$1F,$00,$00,$00,$00,$00
        .byte   $FE,$1F,$00,$00,$00,$00,$00,$FE
        .byte   $1F,$00,$00,$00,$00,$00,$FE,$1F
        .byte   $00,$FF,$FF,$00,$00,$1E,$1F,$40
        .byte   $07,$F0,$00,$00,$1E,$1F,$60,$03
        .byte   $60,$00,$00,$FE,$1F,$F0,$F3,$4F
        .byte   $00,$00,$FE,$1F,$F8,$F3,$4F,$00
        .byte   $00,$FE,$1F,$FC,$FF,$4F,$00,$00
        .byte   $FE,$1F,$FC,$FF,$67,$00,$00,$FE
        .byte   $1F,$FC,$FF,$F3,$00,$00,$FE,$1F
        .byte   $FC,$FF,$F9,$00,$00,$FE,$1F,$FC
        .byte   $FF,$FC,$00,$00,$FE,$1F,$FC,$3F
        .byte   $FE,$00,$00,$FE,$1F,$FC,$1F,$FF
        .byte   $00,$00,$FE,$1F,$FC,$1F,$FF,$00
        .byte   $00,$3E,$00,$FE,$FF,$FF,$00,$00
        .byte   $FE,$03,$FF,$1F,$FF,$00,$00,$FE
        .byte   $43,$FF,$FF,$FF,$00,$00,$0E,$60
        .byte   $FF,$FF,$3F,$00,$00,$FE,$03,$00
        .byte   $00,$00,$00,$00,$FE,$03,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$08,$00,$03,$B6
        .byte   $07,$00,$00,$00,$00,$00,$24,$00
        .byte   $17,$00,$41,$00,$57,$00,$E5,$01
        .byte   $8E,$00,$04,$00,$02,$00,$A0,$01
        .byte   $35,$00,$05,$00,$03,$00,$9F,$01
        .byte   $34,$00
LB6D3:  .byte   $41
LB6D4:  .byte   $00
LB6D5:  .byte   $57
LB6D6:  .byte   $00,$00,$20,$80,$00,$00,$00,$00
        .byte   $00
LB6DF:  .byte   $A4
LB6E0:  .byte   $01
LB6E1:  .byte   $37,$00



        PASCAL_STRING {"OK            ",A2D_GLYPH_RETURN}

        .byte   $14,$00,$25,$00,$78,$00
        .byte   $30,$00,$19,$00,$2F,$00,$2C,$01
        .byte   $25,$00,$90,$01,$30,$00,$31,$01
        .byte   $2F,$00,$BE,$00,$10,$00,$4B,$00
        .byte   $1D,$00
LB713:  .byte   $00
LB714:  .byte   $00
LB715:  .byte   $00

        PASCAL_STRING "Try Again     A"
        PASCAL_STRING "Cancel     Esc"

        PASCAL_STRING "System Error"
        PASCAL_STRING "I/O error"
        PASCAL_STRING "No device connected"
        PASCAL_STRING "The disk is write protected."
        PASCAL_STRING "The syntax of the pathname is invalid."
        PASCAL_STRING "Part of the pathname doesn't exist."
        PASCAL_STRING "The volume cannot be found."

        PASCAL_STRING "The file cannot be found."
        PASCAL_STRING "That name already exists. Please use another name."
        PASCAL_STRING "The disk is full."
        PASCAL_STRING "The volume directory cannot hold more than 51 files."
        PASCAL_STRING "The file is locked."
        PASCAL_STRING "This is not a ProDOS disk."
        PASCAL_STRING "There is another volume with that name on the desktop."
        PASCAL_STRING "There are 2 volumes with the same name."
        PASCAL_STRING "This file cannot be run."
        PASCAL_STRING "That name is too long."
        PASCAL_STRING "Please insert source disk"
        PASCAL_STRING "Please insert destination disk"
        PASCAL_STRING "BASIC.SYSTEM not found"

LB986:  .byte   $14
LB987:  .byte   $00,$27,$28,$2B,$40,$44,$45,$46
        .byte   $47,$48,$49,$4E,$52,$57,$F9,$FA
        .byte   $FB,$FC,$FD,$FE
LB99B:  .byte   $35
LB99C:  .byte   $B7,$42,$B7,$4C,$B7,$60,$B7,$7D
        .byte   $B7,$A4,$B7,$C8,$B7,$E4,$B7,$FE
        .byte   $B7,$31,$B8,$43,$B8,$78,$B8,$8C
        .byte   $B8,$A7,$B8,$DE,$B8,$06,$B9,$1F
        .byte   $B9,$36,$B9,$50,$B9,$6F,$B9
LB9C3:  .byte   $00,$00,$00,$80,$00,$80,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$80,$80,$00,$48,$8A,$48,$A0
        .byte   $26,$A9,$00,$A2,$00,$20,$EC,$BF
        .byte   $A0,$24,$A9,$AD,$A2,$D2,$20,$EC
        .byte   $BF,$A0,$25,$A9,$00,$A2,$00,$20
        .byte   $EC,$BF,$8D,$08,$C0,$8D,$82,$C0
        .byte   $20,$DD,$FB,$8D
        ora     #$C0
        lda     LCBANK1
        lda     LCBANK1
        ldx     #$03
        lda     #$00
LBA0B:  sta     $D239,x
        sta     $D241,x
        dex
        bpl     LBA0B
        lda     #$26
        sta     $D245
        lda     #$02
        sta     $D246
        lda     #$B9
        sta     $D247
        lda     #$00
        sta     $D248
        ldy     #$04
        lda     #$39
        ldx     #$D2
        jsr     LBFEC
        lda     LB6D3
        ldx     LB6D4
        jsr     LBF8B
        sty     LBFCA
        sta     LBFCD
        lda     LB6D3
        clc
        adc     LB6DF
        pha
        lda     LB6D4
        adc     LB6E0
        tax
        pla
        jsr     LBF8B
        sty     LBFCC
        sta     LBFCE
        lda     LB6D5
        sta     LBFC9
        clc
        adc     LB6E1
        sta     LBFCB
        ldy     #$26
        lda     #$00
        ldx     #$00
        jsr     LBFEC
        jsr     LBE08
        ldy     #$25
        lda     #$00
        ldx     #$00
        jsr     LBFEC
        ldy     #$07
        lda     #$00
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$BB
        ldx     #$B6
        jsr     LBFEC
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$12
        lda     #$BB
        ldx     #$B6
        jsr     LBFEC
        ldy     #$06
        lda     #$D3
        ldx     #$B6
        jsr     LBFEC
        ldy     #$12
        lda     #$C3
        ldx     #$B6
        jsr     LBFEC
        ldy     #$12
        lda     #$CB
        ldx     #$B6
        jsr     LBFEC
        ldy     #$07
        lda     #$00
        ldx     #$D2
        jsr     LBFEC
        ldy     #$26
        lda     #$00
        ldx     #$00
        jsr     LBFEC
        ldy     #$14
        lda     #$AB
        ldx     #$B6
        jsr     LBFEC
        ldy     #$25
        lda     #$00
        ldx     #$00
        jsr     LBFEC
        pla
        tax
        pla
        ldy     LB986
        dey
LBAE5:  cmp     LB987,y
        beq     LBAEF
        dey
        bpl     LBAE5
        ldy     #$00
LBAEF:  tya
        asl     a
        tay
        lda     LB99B,y
        sta     LB714
        lda     LB99C,y
        sta     LB715
        cpx     #$00
        beq     LBB0B
        txa
        and     #$FE
        sta     LB713
        jmp     LBB14

LBB0B:  tya
        lsr     a
        tay
        lda     LB9C3,y
        sta     LB713
LBB14:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        bit     LB713
        bpl     LBB5C
        ldy     #$12
        lda     #$FF
        ldx     #$B6
        jsr     LBFEC
        ldy     #$0E
        lda     #$07
        ldx     #$B7
        jsr     LBFEC
        lda     #$26
        ldx     #$B7
        jsr     LBFD0
        bit     LB713
        bvs     LBB5C
        ldy     #$12
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        ldy     #$0E
        lda     #$FB
        ldx     #$B6
        jsr     LBFEC
        lda     #$16
        ldx     #$B7
        jsr     LBFD0
        jmp     LBB75

LBB5C:  ldy     #$12
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        ldy     #$0E
        lda     #$FB
        ldx     #$B6
        jsr     LBFEC
        lda     #$E3
        ldx     #$B6
        jsr     LBFD0
LBB75:  ldy     #$0E
        lda     #$0F
        ldx     #$B7
        jsr     LBFEC
        lda     LB714
        ldx     LB715
        jsr     LBFD0
LBB87:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     LBFEC
        lda     $D208
        cmp     #$01
        bne     LBB9A
        jmp     LBC0C

LBB9A:  cmp     #$03
        bne     LBB87
        lda     $D209
        and     #$7F
        bit     LB713
        bpl     LBBEE
        cmp     #$1B
        bne     LBBC3
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$FF
        ldx     #$B6
        jsr     LBFEC
        lda     #$01
        jmp     LBC55

LBBC3:  bit     LB713
        bvs     LBBEE
        cmp     #$61
        bne     LBBE3
LBBCC:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        lda     #$00
        jmp     LBC55

LBBE3:  cmp     #$41
        beq     LBBCC
        cmp     #$0D
        beq     LBBCC
        jmp     LBB87

LBBEE:  cmp     #$0D
        bne     LBC09
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        lda     #$02
        jmp     LBC55

LBC09:  jmp     LBB87

LBC0C:  jsr     LBDE1
        ldy     #$0E
        lda     #$09
        ldx     #$D2
        jsr     LBFEC
        bit     LB713
        bpl     LBC42
        ldy     #$13
        lda     #$FF
        ldx     #$B6
        jsr     LBFEC
        cmp     #$80
        bne     LBC2D
        jmp     LBCE9

LBC2D:  bit     LB713
        bvs     LBC42
        ldy     #$13
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        cmp     #$80
        bne     LBC52
        jmp     LBC6D

LBC42:  ldy     #$13
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        cmp     #$80
        bne     LBC52
        jmp     LBD65

LBC52:  jmp     LBB87

LBC55:  pha
        ldy     #$26
        lda     #$00
        ldx     #$00
        jsr     LBFEC
        jsr     LBE5D
        ldy     #$25
        lda     #$00
        ldx     #$00
        jsr     LBFEC
        pla
        rts

LBC6D:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        lda     #$00
        sta     LBCE8
LBC84:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     LBFEC
        lda     $D208
        cmp     #$02
        beq     LBCDB
        jsr     LBDE1
        ldy     #$0E
        lda     #$09
        ldx     #$D2
        jsr     LBFEC
        ldy     #$13
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        cmp     #$80
        beq     LBCB5
        lda     LBCE8
        beq     LBCBD
        jmp     LBC84

LBCB5:  lda     LBCE8
        bne     LBCBD
        jmp     LBC84

LBCBD:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        lda     LBCE8
        clc
        adc     #$80
        sta     LBCE8
        jmp     LBC84

LBCDB:  lda     LBCE8
        beq     LBCE3
        jmp     LBB87

LBCE3:  lda     #$00
        jmp     LBC55

LBCE8:  .byte   0
LBCE9:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$FF
        ldx     #$B6
        jsr     LBFEC
        lda     #$00
        sta     LBD64
LBD00:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     LBFEC
        lda     $D208
        cmp     #$02
        beq     LBD57
        jsr     LBDE1
        ldy     #$0E
        lda     #$09
        ldx     #$D2
        jsr     LBFEC
        ldy     #$13
        lda     #$FF
        ldx     #$B6
        jsr     LBFEC
        cmp     #$80
        beq     LBD31
        lda     LBD64
        beq     LBD39
        jmp     LBD00

LBD31:  lda     LBD64
        bne     LBD39
        jmp     LBD00

LBD39:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$FF
        ldx     #$B6
        jsr     LBFEC
        lda     LBD64
        clc
        adc     #$80
        sta     LBD64
        jmp     LBD00

LBD57:  lda     LBD64
        beq     LBD5F
        jmp     LBB87

LBD5F:  lda     #$01
        jmp     LBC55

LBD64:  .byte   0
LBD65:  lda     #$00
        sta     LBDE0
        ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
LBD7C:  ldy     #$2A
        lda     #$08
        ldx     #$D2
        jsr     LBFEC
        lda     $D208
        cmp     #$02
        beq     LBDD3
        jsr     LBDE1
        ldy     #$0E
        lda     #$09
        ldx     #$D2
        jsr     LBFEC
        ldy     #$13
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        cmp     #$80
        beq     LBDAD
        lda     LBDE0
        beq     LBDB5
        jmp     LBD7C

LBDAD:  lda     LBDE0
        bne     LBDB5
        jmp     LBD7C

LBDB5:  ldy     #$07
        lda     #$02
        ldx     #$D2
        jsr     LBFEC
        ldy     #$11
        lda     #$F3
        ldx     #$B6
        jsr     LBFEC
        lda     LBDE0
        clc
        adc     #$80
        sta     LBDE0
        jmp     LBD7C

LBDD3:  lda     LBDE0
        beq     LBDDB
        jmp     LBB87

LBDDB:  lda     #$02
        jmp     LBC55

LBDE0:  .byte   0
LBDE1:  lda     $D209
        sec
        sbc     LB6D3
        sta     $D209
        lda     $D20A
        sbc     LB6D4
        sta     $D20A
        lda     $D20B
        sec
        sbc     LB6D5
        sta     $D20B
        lda     $D20C
        sbc     LB6D6
        sta     $D20C
        rts

LBE08:  lda     #$00
        sta     LBE37
        lda     #$08
        sta     LBE38
        lda     LBFC9
        jsr     LBF10
        lda     LBFCB
        sec
        sbc     LBFC9
        tax
        inx
LBE21:  lda     LBFCA
        sta     LBE5C
LBE27:  lda     LBE5C
        lsr     a
        tay
        sta     $C054
        bcs     LBE34
        sta     $C055
LBE34:  lda     ($06),y
LBE37           := * + 1
LBE38           := * + 2
        sta     $1234
        inc     LBE37
        bne     LBE41
        inc     LBE38
LBE41:  lda     LBE5C
        cmp     LBFCC
        bcs     LBE4E
        inc     LBE5C
        bne     LBE27
LBE4E:  jsr     LBF52
        dex
        bne     LBE21
        lda     LBE37
        ldx     LBE38
        rts

        .byte   0
LBE5C:  .byte   0
LBE5D:  lda     #$00
        sta     LBEBC
        lda     #$08
        sta     LBEBD
        ldx     LBFCD
        ldy     LBFCE
        lda     #$FF
        cpx     #$00
        beq     LBE78
LBE73:  clc
        rol     a
        dex
        bne     LBE73
LBE78:  sta     LBF0C
        eor     #$FF
        sta     LBF0D
        lda     #$01
        cpy     #$00
        beq     LBE8B
LBE86:  sec
        rol     a
        dey
        bne     LBE86
LBE8B:  sta     LBF0E
        eor     #$FF
        sta     LBF0F
        lda     LBFC9
        jsr     LBF10
        lda     LBFCB
        sec
        sbc     LBFC9
        tax
        inx
        lda     LBFCA
        sta     LBF0B
LBEA8:  lda     LBFCA
        sta     LBF0B
LBEAE:  lda     LBF0B
        lsr     a
        tay
        sta     $C054
        bcs     LBEBB
        sta     $C055
LBEBB:  .byte   $AD
LBEBC:  .byte   0
LBEBD:  php
        pha
        lda     LBF0B
        cmp     LBFCA
        beq     LBEDD
        cmp     LBFCC
        bne     LBEEB
        lda     ($06),y
        and     LBF0F
        sta     ($06),y
        pla
        and     LBF0E
        ora     ($06),y
        pha
        jmp     LBEEB

LBEDD:  lda     ($06),y
        and     LBF0D
        sta     ($06),y
        pla
        and     LBF0C
        ora     ($06),y
        pha
LBEEB:  pla
        sta     ($06),y
        inc     LBEBC
        bne     LBEF6
        inc     LBEBD
LBEF6:  lda     LBF0B
        cmp     LBFCC
        bcs     LBF03
        inc     LBF0B
        bne     LBEAE
LBF03:  jsr     LBF52
        dex
        bne     LBEA8
        rts

        .byte   $00
LBF0B:  .byte   $00
LBF0C:  .byte   $00
LBF0D:  .byte   $00
LBF0E:  .byte   $00
LBF0F:  .byte   $00

LBF10:  sta     LBFCF
        and     #$07
        sta     LBFB0
        lda     LBFCF
        and     #$38
        sta     LBFAF
        lda     LBFCF
        and     #$C0
        sta     LBFAE
        jsr     LBF2C
        rts

LBF2C:  lda     LBFAE
        lsr     a
        lsr     a
        ora     LBFAE
        pha
        lda     LBFAF
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     LBF51
        pla
        ror     a
        sta     $06
        lda     LBFB0
        asl     a
        asl     a
        ora     LBF51
        ora     #$20
        sta     $07
        clc
        rts

LBF51:  .byte   0
LBF52:  lda     LBFB0
        cmp     #$07
        beq     LBF5F
        inc     LBFB0
        jmp     LBF2C

LBF5F:  lda     #$00
        sta     LBFB0
        lda     LBFAF
        cmp     #$38
        beq     LBF74
        clc
        adc     #$08
        sta     LBFAF
        jmp     LBF2C

LBF74:  lda     #$00
        sta     LBFAF
        lda     LBFAE
        clc
        adc     #$40
        sta     LBFAE
        cmp     #$C0
        beq     LBF89
        jmp     LBF2C

LBF89:  sec
        rts

LBF8B:  ldy     #$00
        cpx     #$02
        bne     LBF96
        ldy     #$49
        clc
        adc     #$01
LBF96:  cpx     #$01
        bne     LBFA4
        ldy     #$24
        clc
        adc     #$04
        bcc     LBFA4
        iny
        sbc     #$07
LBFA4:  cmp     #$07
        bcc     LBFAD
        sbc     #$07
        iny
        bne     LBFA4
LBFAD:  rts

LBFAE:  .byte   $00
LBFAF:  .byte   $00
LBFB0:  .byte   $00,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
LBFC9:  .byte   $00
LBFCA:  .byte   $00
LBFCB:  .byte   $00
LBFCC:  .byte   $00
LBFCD:  .byte   $00
LBFCE:  .byte   $00
LBFCF:  .byte   $00

LBFD0:  sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        beq     LBFEB
        sta     $08
        inc     $06
        bne     LBFE2
        inc     $07
LBFE2:  ldy     #$19
        lda     #$06
        ldx     #$00
        jsr     LBFEC
LBFEB:  rts

LBFEC:  sty     LBFF9-1
        sta     LBFF9
        stx     LBFF9+1
        A2D_CALL 0, 0, LBFF9
        rts

        .byte   0
        .byte   0
        .byte   0
        .byte   0
