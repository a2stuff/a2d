
        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ==================================================
;;; Overlay for Common Routines (Selector, File Copy/Delete)
;;; ==================================================
        .org $5000

        dummy1234 := $1234

        jmp     L50B1

        .byte   $02
L5004:  .byte   $00,$17,$50,$03,$28,$50,$00,$10
L500C:  .byte   $00,$04
L500E:  .byte   $00,$00,$14,$00,$02,$00,$00,$01
L5016:  .byte   $00
L5017:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L5027:  .byte   $00
L5028:  .byte   $00
L5029:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
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
L50A8:  .byte   $00
L50A9:  .byte   $00
L50AA:  .byte   $00
L50AB:  .byte   $00
L50AC:  .byte   $70,$00,$70,$00,$70
L50B1:  sty     L5102
        stx     L5101
        tsx
        stx     L50AA
        pha
        lda     #$00
        sta     L5027
        sta     L50A8
        sta     $D8EB
        sta     $D8EC
        sta     $D8F0
        sta     $D8F1
        sta     $D8F2
        sta     L5606
        sta     L5104
        sta     L5103
        sta     L5105
        lda     #$14
        sta     $D8E9
        lda     #$FF
        sta     $D920
        pla
        asl     a
        tax
        lda     L50AB,x
        sta     L50FF
        lda     L50AC,x
        sta     L5100
        ldy     L5102
        ldx     L5101
L50FF           := * + 1
L5100           := * + 2
        jmp     dummy1234

L5101:  .byte   0
L5102:  .byte   0
L5103:  .byte   0
L5104:  .byte   0
L5105:  .byte   0
L5106:  bit     $D8EC
        bpl     L5118
        dec     $D8E9
        bne     L5118
        jsr     L6D24
        lda     #$14
        sta     $D8E9
L5118:  MGTK_RELAY_CALL MGTK::GetEvent, $D208
        lda     $D208
        cmp     #$01
        bne     L512E
        jsr     L51AF
        jmp     L5106

L512E:  cmp     #$03
        bne     L5135
        jsr     L59B9
L5135:  MGTK_RELAY_CALL MGTK::FindWindow, $D209
        lda     $D20D
        bne     L5146
        jmp     L5106

L5146:  lda     $D20E
        cmp     $D5B7
        beq     L5151
        jmp     L5106

L5151:  lda     $D5B7
        jsr     L62C8
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        bit     L51AE
        bmi     L5183
        MGTK_RELAY_CALL MGTK::InRect, $DA9E
        cmp     #$80
        bne     L5196
        beq     L5190
L5183:  MGTK_RELAY_CALL MGTK::InRect, $DAAA
        cmp     #$80
        bne     L5196
L5190:  jsr     L55E0
        jmp     L5199

L5196:  jsr     L55BA
L5199:  MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D239
        jmp     L5106

L51AE:  .byte   0
L51AF:  MGTK_RELAY_CALL MGTK::FindWindow, $D209
        lda     $D20D
        bne     L51BE
        rts

L51BE:  cmp     #$02
        bne     L51C6
        jmp     L51C7

        rts

L51C6:  rts

L51C7:  lda     $D20E
        cmp     $D5B7
        beq     L51D2
        jmp     L531F

L51D2:  lda     $D5B7
        jsr     L62C8
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $D9E0
        cmp     #$80
        beq     L5200
        jmp     L5239

L5200:  bit     L5105
        bmi     L520A
        lda     $D920
        bpl     L520D
L520A:  jmp     L5308

L520D:  tax
        lda     $1780,x
        bmi     L5216
L5213:  jmp     L5308

L5216:  lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E0
        jsr     L5888
        bmi     L5213
        jsr     L5607
        jmp     L5308

L5239:  MGTK_RELAY_CALL MGTK::InRect, $D9F0
        cmp     #$80
        beq     L5249
        jmp     L526B

L5249:  bit     L5105
        bmi     L5268
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9F0
        jsr     L590E
        bmi     L5268
        jsr     L565C
L5268:  jmp     L5308

L526B:  MGTK_RELAY_CALL MGTK::InRect, $D9D0
        cmp     #$80
        beq     L527B
        jmp     L529D

L527B:  bit     L5105
        bmi     L529A
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D0
        jsr     L577C
        bmi     L529A
        jsr     L567F
L529A:  jmp     L5308

L529D:  MGTK_RELAY_CALL MGTK::InRect, $D9D8
        cmp     #$80
        beq     L52AD
        jmp     L52CD

L52AD:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D8
        jsr     L56F6
        bmi     L52CA
        jsr     L6D42
        jsr     L6D1E
L52CA:  jmp     L5308

L52CD:  MGTK_RELAY_CALL MGTK::InRect, $D9E8
        cmp     #$80
        beq     L52DD
        jmp     L52FA

L52DD:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E8
        jsr     L5802
        bmi     L52F7
        jsr     L6D21
L52F7:  jmp     L5308

L52FA:  bit     L5103
        bpl     L5304
        jsr     L531B
        bmi     L5308
L5304:  jsr     L6D45
        rts

L5308:  MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D215
        rts

L531B:  jsr     L59B8
        rts

L531F:  bit     L5105
        bmi     L5340
        MGTK_RELAY_CALL MGTK::FindControl, $D209
        lda     $D20D
        beq     L5341
        cmp     #$01
        bne     L5340
        lda     $D5F6
        and     #$01
        beq     L5340
        jmp     L5469

L5340:  rts

L5341:  lda     $D5F1
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        lda     $D20F
        clc
        adc     $D60F
        sta     $D20F
        lda     $D210
        adc     $D610
        sta     $D210
        lsr16    $D20F
        lsr16    $D20F
        lsr16    $D20F
        lda     $D920
        cmp     $D20F
        beq     L5380
        jmp     L542F

L5380:  jsr     L5C4F
        beq     L5386
        rts

L5386:  ldx     $D920
        lda     $1780,x
        bmi     L53B5
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D8
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D8
        jsr     L6D1E
        jmp     L5340

L53B5:  and     #$7F
        pha
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E0
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E0
        lda     #$00
        sta     L542E
        lda     #$00
        sta     $08
        lda     #$18
        sta     $09
        pla
        asl     a
        rol     L542E
        asl     a
        rol     L542E
        asl     a
        rol     L542E
        asl     a
        rol     L542E
        clc
        adc     $08
        sta     $08
        lda     L542E
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     L5F0D
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D215
        rts

L542E:  .byte   0
L542F:  lda     $D20F
        cmp     $177F
        bcc     L5438
        rts

L5438:  lda     $D920
        bmi     L5446
        jsr     L6D2A
        lda     $D920
        jsr     L6274
L5446:  lda     $D20F
        sta     $D920
        bit     $D8F0
        bpl     L5457
        jsr     L6D30
        jsr     L6D27
L5457:  lda     $D920
        jsr     L6274
        jsr     L6D2D
        jsr     L5C4F
        bmi     L5468
        jmp     L5386

L5468:  rts

L5469:  lda     $D20E
        cmp     #$01
        bne     L5473
        jmp     L550A

L5473:  cmp     #$02
        bne     L547A
        jmp     L5533

L547A:  cmp     #$03
        bne     L5481
        jmp     L54BA

L5481:  cmp     #$04
        bne     L5488
        jmp     L54DF

L5488:  lda     #$01
        sta     $D208
        MGTK_RELAY_CALL MGTK::TrackThumb, $D208
        lda     $D20E
        bne     L549C
        rts

L549C:  lda     $D20D
        sta     $D209
        lda     #$01
        sta     $D208
        MGTK_RELAY_CALL MGTK::UpdateThumb, $D208
        lda     $D20D
        jsr     L6227
        jsr     L606D
        rts

L54BA:  lda     $D5FA
        sec
        sbc     #$09
        bpl     L54C4
        lda     #$00
L54C4:  sta     $D209
        lda     #$01
        sta     $D208
        MGTK_RELAY_CALL MGTK::UpdateThumb, $D208
        lda     $D209
        jsr     L6227
        jsr     L606D
        rts

L54DF:  lda     $D5FA
        clc
        adc     #$09
        cmp     $177F
        beq     L54EF
        bcc     L54EF
        lda     $177F
L54EF:  sta     $D209
        lda     #$01
        sta     $D208
        MGTK_RELAY_CALL MGTK::UpdateThumb, $D208
        lda     $D209
        jsr     L6227
        jsr     L606D
        rts

L550A:  lda     $D5FA
        bne     L5510
        rts

L5510:  sec
        sbc     #$01
        sta     $D209
        lda     #$01
        sta     $D208
        MGTK_RELAY_CALL MGTK::UpdateThumb, $D208
        lda     $D209
        jsr     L6227
        jsr     L606D
        jsr     L555F
        jmp     L550A

L5533:  lda     $D5FA
        cmp     $D5F9
        bne     L553C
        rts

L553C:  clc
        adc     #$01
        sta     $D209
        lda     #$01
        sta     $D208
        MGTK_RELAY_CALL MGTK::UpdateThumb, $D208
        lda     $D209
        jsr     L6227
        jsr     L606D
        jsr     L555F
        jmp     L5533

L555F:  MGTK_RELAY_CALL MGTK::PeekEvent, $D208
        lda     $D208
        cmp     #$01
        beq     L5576
        cmp     #$04
        beq     L5576
        pla
        pla
        rts

L5576:  MGTK_RELAY_CALL MGTK::GetEvent, $D208
        MGTK_RELAY_CALL MGTK::FindWindow, $D209
        lda     $D20E
        cmp     $D5F1
        beq     L5593
        pla
        pla
        rts

L5593:  lda     $D20D
        cmp     #$02
        beq     L559D
        pla
        pla
        rts

L559D:  MGTK_RELAY_CALL MGTK::FindControl, $D209
        lda     $D20D
        cmp     #$01
        beq     L55B0
        pla
        pla
        rts

L55B0:  lda     $D20E
        cmp     #$03
        bcc     L55B9
        pla
        pla
L55B9:  rts

L55BA:  bit     L5606
        bpl     L55DF
        MGTK_RELAY_CALL MGTK::HideCursor, $0000
        MGTK_RELAY_CALL MGTK::SetCursor, $D2AD
        MGTK_RELAY_CALL MGTK::ShowCursor, $0000
        lda     #$00
        sta     L5606
L55DF:  rts

L55E0:  bit     L5606
        bmi     L5605
        MGTK_RELAY_CALL MGTK::HideCursor, $0000
        MGTK_RELAY_CALL MGTK::SetCursor, $D2DF
        MGTK_RELAY_CALL MGTK::ShowCursor, $0000
        lda     #$80
        sta     L5606
L5605:  rts

L5606:  .byte   0
L5607:  ldx     $D920
        lda     $1780,x
        and     #$7F
        pha
        bit     $D8F0
        bpl     L5618
        jsr     L6D30
L5618:  lda     #$00
        sta     L565B
        lda     #$00
        sta     $08
        lda     #$18
        sta     $09
        pla
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        asl     a
        rol     L565B
        clc
        adc     $08
        sta     $08
        lda     L565B
        adc     $09
        sta     $09
        ldx     $09
        lda     $08
        jsr     L5F0D
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        rts

L565B:  .byte   0
L565C:  lda     #$FF
        sta     $D920
        jsr     L5EB8
        jsr     L5E87
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        jsr     L6D30
        jsr     L6D27
        rts

L567F:  lda     #$00
        sta     L56E2
        ldx     L5028
        bne     L568C
        jmp     L56E1

L568C:  lda     L5028,x
        and     #$7F
        cmp     #$2F
        beq     L569B
        dex
        bpl     L568C
        jmp     L56E1

L569B:  cpx     #$01
        bne     L56A2
        jmp     L56E1

L56A2:  jsr     L5F49
        lda     $D920
        pha
        lda     #$FF
        sta     $D920
        jsr     L5F5B
        jsr     L6161
        lda     #$00
        jsr     L6227
        jsr     L61B1
        jsr     L606D
        pla
        sta     $D920
        bit     L56E2
        bmi     L56D6
        jsr     L6D2A
        lda     $D920
        bmi     L56DC
        jsr     L6D2A
        jmp     L56DC

L56D6:  jsr     L6D30
        jsr     L6D27
L56DC:  lda     #$FF
        sta     $D920
L56E1:  rts

L56E2:  .byte   0
L56E3:  MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D239
        rts

L56F6:  lda     #$00
        sta     L577B
L56FB:  MGTK_RELAY_CALL MGTK::GetEvent, $D208
        lda     $D208
        cmp     #$02
        beq     L575E
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $D9D8
        cmp     #$80
        beq     L5738
        lda     L577B
        beq     L5740
        jmp     L56FB

L5738:  lda     L577B
        bne     L5740
        jmp     L56FB

L5740:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D8
        lda     L577B
        clc
        adc     #$80
        sta     L577B
        jmp     L56FB

L575E:  lda     L577B
        beq     L5766
        return  #$FF

L5766:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D8
        return  #$00

L577B:  .byte   0
L577C:  lda     #$00
        sta     L5801
L5781:  MGTK_RELAY_CALL MGTK::GetEvent, $D208
        lda     $D208
        cmp     #$02
        beq     L57E4
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $D9D0
        cmp     #$80
        beq     L57BE
        lda     L5801
        beq     L57C6
        jmp     L5781

L57BE:  lda     L5801
        bne     L57C6
        jmp     L5781

L57C6:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D0
        lda     L5801
        clc
        adc     #$80
        sta     L5801
        jmp     L5781

L57E4:  lda     L5801
        beq     L57EC
        return  #$FF

L57EC:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D0
        return  #$00

L5801:  .byte   0
L5802:  lda     #$00
        sta     L5887
L5807:  MGTK_RELAY_CALL MGTK::GetEvent, $D208
        lda     $D208
        cmp     #$02
        beq     L586A
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $D9E8
        cmp     #$80
        beq     L5844
        lda     L5887
        beq     L584C
        jmp     L5807

L5844:  lda     L5887
        bne     L584C
        jmp     L5807

L584C:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E8
        lda     L5887
        clc
        adc     #$80
        sta     L5887
        jmp     L5807

L586A:  lda     L5887
        beq     L5872
        return  #$FF

L5872:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E8
        return  #$01

L5887:  .byte   0
L5888:  lda     #$00
        sta     L590D
L588D:  MGTK_RELAY_CALL MGTK::GetEvent, $D208
        lda     $D208
        cmp     #$02
        beq     L58F0
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $D9E0
        cmp     #$80
        beq     L58CA
        lda     L590D
        beq     L58D2
        jmp     L588D

L58CA:  lda     L590D
        bne     L58D2
        jmp     L588D

L58D2:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E0
        lda     L590D
        clc
        adc     #$80
        sta     L590D
        jmp     L588D

L58F0:  lda     L590D
        beq     L58F8
        return  #$FF

L58F8:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E0
        return  #$00

L590D:  .byte   0
L590E:  lda     #$00
        sta     L5993
L5913:  MGTK_RELAY_CALL MGTK::GetEvent, $D208
        lda     $D208
        cmp     #$02
        beq     L5976
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $D9F0
        cmp     #$80
        beq     L5950
        lda     L5993
        beq     L5958
        jmp     L5913

L5950:  lda     L5993
        bne     L5958
        jmp     L5913

L5958:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9F0
        lda     L5993
        clc
        adc     #$80
        sta     L5993
        jmp     L5913

L5976:  lda     L5993
        beq     L597E
        return  #$FF

L597E:  MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9F0
        return  #$01

L5993:  .byte   0
L5994:  sty     L59A8
        stax    L59A9
        php
        sei
        sta     ALTZPOFF
        lda     ROMIN2
        jsr     MLI
L59A8:  .byte   0
L59A9:  .byte   0
L59AA:  .byte   0
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts

L59B8:  rts

L59B9:  lda     $D20A
        beq     L59F7
        lda     $D209
        and     #$7F
        cmp     #$08
        bne     L59CA
        jmp     L6D3F

L59CA:  cmp     #$15
        bne     L59D1
        jmp     L6D42

L59D1:  bit     L5105
        bmi     L59E4
        cmp     #$0A
        bne     L59DD
        jmp     L5C0E

L59DD:  cmp     #$0B
        bne     L59E4
        jmp     L5BF6

L59E4:  cmp     #$30
        bcc     L59EF
        cmp     #$3A
        bcs     L59EF
        jmp     L5B23

L59EF:  bit     L5105
        bmi     L5A4F
        jmp     L5B70

L59F7:  lda     $D209
        and     #$7F
        cmp     #$08
        bne     L5A03
        jmp     L6D39

L5A03:  cmp     #$15
        bne     L5A0A
        jmp     L6D3C

L5A0A:  cmp     #$0D
        bne     L5A11
        jmp     L5ACC

L5A11:  cmp     #$1B
        bne     L5A18
        jmp     L5AF7

L5A18:  cmp     #$7F
        bne     L5A1F
        jmp     L5B1F

L5A1F:  bit     L5105
        bpl     L5A27
        jmp     L5AC4

L5A27:  cmp     #$09
        bne     L5A52
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9F0
        MGTK_RELAY_CALL MGTK::PaintRect, $D9F0
        jsr     L565C
L5A4F:  jmp     L5AC8

L5A52:  cmp     #$0F
        bne     L5A8B
        lda     $D920
        bmi     L5AC8
        tax
        lda     $1780,x
        bmi     L5A64
        jmp     L5AC8

L5A64:  lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E0
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E0
        jsr     L5607
        jmp     L5AC8

L5A8B:  cmp     #$03
        bne     L5AB6
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D0
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D0
        jsr     L567F
        jmp     L5AC8

L5AB6:  cmp     #$0A
        bne     L5ABD
        jmp     L5B26

L5ABD:  cmp     #$0B
        bne     L5AC4
        jmp     L5B4C

L5AC4:  jsr     L6D33
        rts

L5AC8:  jsr     L56E3
        rts

L5ACC:  lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D8
        MGTK_RELAY_CALL MGTK::PaintRect, $D9D8
        jsr     L6D42
        jsr     L6D1E
        jsr     L56E3
        rts

L5AF7:  lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E8
        MGTK_RELAY_CALL MGTK::PaintRect, $D9E8
        jsr     L6D21
        jsr     L56E3
        rts

L5B1F:  jsr     L6D36
        rts

L5B23:  jmp     L59B8

L5B26:  lda     $177F
        beq     L5B37
        lda     $D920
        bmi     L5B47
        tax
        inx
        cpx     $177F
        bcc     L5B38
L5B37:  rts

L5B38:  jsr     L6274
        jsr     L6D2A
        inc     $D920
        lda     $D920
        jmp     L5C2F

L5B47:  lda     #$00
        jmp     L5C2F

L5B4C:  lda     $177F
        beq     L5B58
        lda     $D920
        bmi     L5B68
        bne     L5B59
L5B58:  rts

L5B59:  jsr     L6274
        jsr     L6D2A
        dec     $D920
        lda     $D920
        jmp     L5C2F

L5B68:  ldx     $177F
        dex
        txa
        jmp     L5C2F

L5B70:  cmp     #$41
        bcs     L5B75
L5B74:  rts

L5B75:  cmp     #$5B
        bcc     L5B83
        cmp     #$61
        bcc     L5B74
        cmp     #$7B
        bcs     L5B74
        and     #$5F
L5B83:  jsr     L5B9D
        bmi     L5B74
        cmp     $D920
        beq     L5B74
        pha
        lda     $D920
        bmi     L5B99
        jsr     L6274
        jsr     L6D2A
L5B99:  pla
        jmp     L5C2F

L5B9D:  sta     L5BF5
        lda     #$00
        sta     L5BF3
L5BA5:  lda     L5BF3
        cmp     $177F
        beq     L5BC4
        jsr     L5BCB
        ldy     #$01
        lda     ($06),y
        cmp     L5BF5
        bcc     L5BBE
        beq     L5BC7
        jmp     L5BC4

L5BBE:  inc     L5BF3
        jmp     L5BA5

L5BC4:  return  #$FF

L5BC7:  return  L5BF3

L5BCB:  tax
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        asl     a
        rol     L5BF4
        clc
        adc     #$00
        sta     $06
        lda     L5BF4
        adc     #$18
        sta     $07
        rts

L5BF3:  .byte   0
L5BF4:  .byte   0
L5BF5:  .byte   0
L5BF6:  lda     $177F
        beq     L5C02
        lda     $D920
        bmi     L5C09
        bne     L5C03
L5C02:  rts

L5C03:  jsr     L6274
        jsr     L6D2A
L5C09:  lda     #$00
        jmp     L5C2F

L5C0E:  lda     $177F
        beq     L5C1E
        ldx     $D920
        bmi     L5C27
        inx
        cpx     $177F
        bne     L5C1F
L5C1E:  rts

L5C1F:  dex
        txa
        jsr     L6274
        jsr     L6D2A
L5C27:  ldx     $177F
        dex
        txa
        jmp     L5C2F

L5C2F:  sta     $D920
        jsr     L6D2D
        lda     $D920
        jsr     L6586
        jsr     L6163
        jsr     L606D
        copy16  #$2001, $D484
        jsr     L6D27
        rts

L5C4F:  ldx     #$03
L5C51:  lda     $D209,x
        sta     L5CF0,x
        dex
        bpl     L5C51
        lda     $D2AB
        sta     L5CEF
L5C60:  dec     L5CEF
        beq     L5CA6
        MGTK_RELAY_CALL MGTK::PeekEvent, $D208
        jsr     L5CA9
        bmi     L5CA6
        lda     #$FF
        sta     L5CF6
        lda     $D208
        sta     L5CF5
        cmp     #$00
        beq     L5C60
        cmp     #$04
        beq     L5C60
        cmp     #$02
        bne     L5C96
        MGTK_RELAY_CALL MGTK::GetEvent, $D208
        jmp     L5C60

L5C96:  cmp     #$01
        bne     L5CA6
        MGTK_RELAY_CALL MGTK::GetEvent, $D208
        return  #$00

L5CA6:  return  #$FF

L5CA9:  lda     $D209
        sec
        sbc     L5CF0
        sta     L5CF4
        lda     $D20A
        sbc     L5CF1
        bpl     L5CC5
        lda     L5CF4
        cmp     #$FB
        bcs     L5CCC
L5CC2:  return  #$FF

L5CC5:  lda     L5CF4
        cmp     #$05
        bcs     L5CC2
L5CCC:  lda     $D20B
        sec
        sbc     L5CF2
        sta     L5CF4
        lda     $D20C
        sbc     L5CF3
        bpl     L5CE5
        lda     L5CF4
        cmp     #$FC
        bcs     L5CEC
L5CE5:  lda     L5CF4
        cmp     #$04
        bcs     L5CC2
L5CEC:  return  #$00

L5CEF:  .byte   0
L5CF0:  .byte   0
L5CF1:  .byte   0
L5CF2:  .byte   0
L5CF3:  .byte   0
L5CF4:  .byte   0
L5CF5:  .byte   0
L5CF6:  .byte   0
        MGTK_RELAY_CALL MGTK::OpenWindow, $D5B7
        MGTK_RELAY_CALL MGTK::OpenWindow, $D5F1
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::FrameRect, $D9C0
        MGTK_RELAY_CALL MGTK::FrameRect, $D9D8
        MGTK_RELAY_CALL MGTK::FrameRect, $D9E0
        MGTK_RELAY_CALL MGTK::FrameRect, $D9D0
        MGTK_RELAY_CALL MGTK::FrameRect, $D9E8
        MGTK_RELAY_CALL MGTK::FrameRect, $D9F0
        jsr     L5D82
        jsr     L5D93
        jsr     L5DA4
        jsr     L5DB5
        jsr     L5DC6
        MGTK_RELAY_CALL MGTK::MoveTo, $D9F8
        MGTK_RELAY_CALL MGTK::LineTo, $D9FC
        MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D239
        rts

L5D82:  MGTK_RELAY_CALL MGTK::MoveTo, $DA03
        addr_call L5DED, $DA07
        rts

L5D93:  MGTK_RELAY_CALL MGTK::MoveTo, $DA21
        addr_call L5DED, $DA25
        rts

L5DA4:  MGTK_RELAY_CALL MGTK::MoveTo, $DA17
        addr_call L5DED, $DA1B
        rts

L5DB5:  MGTK_RELAY_CALL MGTK::MoveTo, $DA2A
        addr_call L5DED, $DA2E
        rts

L5DC6:  MGTK_RELAY_CALL MGTK::MoveTo, $DA40
        addr_call L5DED, $DA44
        rts

L5DD7:  sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L5DE0:  lda     ($06),y
        sta     $D380,y
        dey
        bpl     L5DE0
        ldax    #$D380
        rts

L5DED:  jsr     L5DD7
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc     $06
        bne     L5E00
        inc     $07
L5E00:  MGTK_RELAY_CALL MGTK::DrawText, $0006
        rts

        jsr     L5DD7
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc     $06
        bne     L5E1D
        inc     $07
L5E1D:  MGTK_RELAY_CALL MGTK::TextWidth, $0006
        lsr     $0A
        ror     $09
        lda     #$01
        sta     L5E56
        lda     #$F4
        lsr     L5E56
        ror     a
        sec
        sbc     $09
        sta     $D90B
        lda     L5E56
        sbc     $0A
        sta     $D90C
        MGTK_RELAY_CALL MGTK::MoveTo, $D90B
        MGTK_RELAY_CALL MGTK::DrawText, $0006
        rts

L5E56:  .byte   0
        jsr     L5DD7
        sta     $06
        stx     $07
        MGTK_RELAY_CALL MGTK::MoveTo, $DA55
        lda     $06
        ldx     $07
        jsr     L5DED
        rts

        jsr     L5DD7
        sta     $06
        stx     $07
        MGTK_RELAY_CALL MGTK::MoveTo, $DA59
        lda     $06
        ldx     $07
        jsr     L5DED
        rts

L5E87:  ldx     L5027
        lda     $BF32,x
        and     #$F0
        sta     L5004
        yax_call L5994, $C5, $5003
        lda     L5017
        and     #$0F
        sta     L5017
        bne     L5EAB
        jsr     L5EB8
        jmp     L5E87

L5EAB:  lda     #$00
        sta     L5028
        addr_call L5F0D, $5017
        rts

L5EB8:  inc     L5027
        lda     L5027
        cmp     $BF31
        beq     L5ECA
        bcc     L5ECA
        lda     #$00
        sta     L5027
L5ECA:  rts

L5ECB:  lda     #$00
        sta     L5F0C
L5ED0:  yax_call L5994, $C8, $5007
        beq     L5EE9
        jsr     L5E87
        lda     #$FF
        sta     $D920
        sta     L5F0C
        jmp     L5ED0

L5EE9:  lda     L500C
        sta     L500E
        sta     L5016
        yax_call L5994, $CA, $500D
        beq     L5F0B
        jsr     L5E87
        lda     #$FF
        sta     $D920
        sta     L5F0C
        jmp     L5ED0

L5F0B:  rts

L5F0C:  .byte   0
L5F0D:  jsr     L5DD7
        sta     $06
        stx     $07
        ldx     L5028
        lda     #$2F
        sta     L5029,x
        inc     L5028
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     L5028
        cmp     #$41
        bcc     L5F2F
        return  #$FF

L5F2F:  pha
        tax
L5F31:  lda     ($06),y
        sta     L5028,x
        dey
        dex
        cpx     L5028
        bne     L5F31
        pla
        sta     L5028
        lda     #$FF
        sta     $D920
        return  #$00

L5F49:  ldx     L5028
        cpx     #$00
        beq     L5F5A
        dec     L5028
        lda     L5028,x
        cmp     #$2F
        bne     L5F49
L5F5A:  rts

L5F5B:  jsr     L5ECB
        lda     #$00
        sta     L6067
        sta     L6068
        sta     L50A9
        lda     #$01
        sta     L6069
        lda     $1423
        sta     L606A
        lda     $1424
        sta     L606B
        lda     $1425
        and     #$7F
        sta     $177F
        bne     L5F87
        jmp     L6012

L5F87:  copy16  #$142B, $06
L5F8F:  ldy     #$00
        lda     ($06),y
        and     #$0F
        bne     L5F9A
        jmp     L6007

L5F9A:  ldx     L6067
        txa
        sta     $1780,x
        ldy     #$00
        lda     ($06),y
        and     #$F0
        cmp     #$D0
        beq     L5FB6
        bit     L50A8
        bpl     L5FC1
        inc     L6068
        jmp     L6007

L5FB6:  lda     $1780,x
        ora     #$80
        sta     $1780,x
        inc     L50A9
L5FC1:  ldy     #$00
        lda     ($06),y
        and     #$0F
        sta     ($06),y
        copy16  #$1800, $08
        lda     #$00
        sta     L606C
        lda     L6067
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        asl     a
        rol     L606C
        clc
        adc     $08
        sta     $08
        lda     L606C
        adc     $09
        sta     $09
        ldy     #$00
        lda     ($06),y
        tay
L5FFA:  lda     ($06),y
        sta     ($08),y
        dey
        bpl     L5FFA
        inc     L6067
        inc     L6068
L6007:  inc     L6069
        lda     L6068
        cmp     $177F
        bne     L6035
L6012:  yax_call L5994, $CC, $5015
        bit     L50A8
        bpl     L6026
        lda     L50A9
        sta     $177F
L6026:  jsr     L62DE
        jsr     L64E2
        lda     L5F0C
        bpl     L6033
        sec
        rts

L6033:  clc
        rts

L6035:  lda     L6069
        cmp     L606B
        beq     L604E
        lda     $06
        clc
        adc     L606A
        sta     $06
        lda     $07
        adc     #$00
        sta     $07
        jmp     L5F8F

L604E:  yax_call L5994, $CA, $500D
        copy16  #$1404, $06
        lda     #$00
        sta     L6069
        jmp     L5F8F

L6067:  .byte   0
L6068:  .byte   0
L6069:  .byte   0
L606A:  .byte   0
L606B:  .byte   0
L606C:  .byte   0
L606D:  lda     $D5F1
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::PaintRect, $D60D
        lda     #$10
        sta     $D917
        lda     #$08
        sta     $D919
        lda     #$00
        sta     $D91A
        sta     L6128
L608E:  lda     L6128
        cmp     $177F
        bne     L60A9
        MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D239
        rts

L60A9:  MGTK_RELAY_CALL MGTK::MoveTo, $D917
        ldx     L6128
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        asl     a
        rol     L6127
        clc
        adc     #$00
        tay
        lda     L6127
        adc     #$18
        tax
        tya
        jsr     L5DED
        ldx     L6128
        lda     $1780,x
        bpl     L60FF
        lda     #$01
        sta     $D917
        MGTK_RELAY_CALL MGTK::MoveTo, $D917
        addr_call L5DED, $D91D
        lda     #$10
        sta     $D917
L60FF:  lda     L6128
        cmp     $D920
        bne     L6110
        jsr     L6274
        lda     $D5F1
        jsr     L62C8
L6110:  inc     L6128
        add16   $D919, #$0008, $D919
        jmp     L608E

L6127:  .byte   0
L6128:  .byte   0
L6129:  stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     L6135
        rts

L6135:  dey
        beq     L613A
        bpl     L613B
L613A:  rts

L613B:  lda     ($0A),y
        and     #$7F
        cmp     #$2F
        beq     L6147
        cmp     #$2E
        bne     L614B
L6147:  dey
        jmp     L6135

L614B:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #$41
        bcc     L615D
        cmp     #$5B
        bcs     L615D
        clc
        adc     #$20
        sta     ($0A),y
L615D:  dey
        jmp     L6135

L6161:  lda     #$00
L6163:  sta     L61B0
        lda     $177F
        cmp     #$0A
        bcs     L6181
        copy16  #$0001, $D208
        MGTK_RELAY_CALL MGTK::ActivateCtl, $D208
        rts

L6181:  lda     $177F
        sta     $D5F9
        lda     #$01
        sta     $D208
        sta     $D209
        MGTK_RELAY_CALL MGTK::ActivateCtl, $D208
        lda     L61B0
        sta     $D209
        jsr     L6227
        lda     #$01
        sta     $D208
        MGTK_RELAY_CALL MGTK::UpdateThumb, $D208
        rts

L61B0:  .byte   0
L61B1:  lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::PaintRect, $D9C8
        copy16  #$5028, $06
        ldy     #$00
        lda     ($06),y
        sta     L6226
        iny
L61D0:  iny
        lda     ($06),y
        cmp     #$2F
        beq     L61DE
        cpy     L6226
        bne     L61D0
        beq     L61E2
L61DE:  dey
        sty     L6226
L61E2:  ldy     #$00
        ldx     #$00
L61E6:  inx
        iny
        lda     ($06),y
        sta     $0220,x
        cpy     L6226
        bne     L61E6
        stx     $0220
        addr_call L6129, $0220
        MGTK_RELAY_CALL MGTK::MoveTo, $DA51
        addr_call L5DED, $DA5F
        addr_call L5DED, $0220
        MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D239
        rts

L6226:  .byte   0
L6227:  sta     L6273
        clc
        adc     #$09
        cmp     $177F
        beq     L6234
        bcs     L623A
L6234:  lda     L6273
        jmp     L624A

L623A:  lda     $177F
        cmp     #$0A
        bcs     L6247
        lda     L6273
        jmp     L624A

L6247:  sec
        sbc     #$09
L624A:  ldx     #$00
        stx     L6273
        asl     a
        rol     L6273
        asl     a
        rol     L6273
        asl     a
        rol     L6273
        sta     $D60F
        ldx     L6273
        stx     $D610
        clc
        adc     #$46
        sta     $D613
        lda     L6273
        adc     #$00
        sta     $D614
        rts

L6273:  .byte   0
L6274:  ldx     #$00
        stx     L62C7
        asl     a
        rol     L62C7
        asl     a
        rol     L62C7
        asl     a
        rol     L62C7
        sta     $D911
        ldx     L62C7
        stx     $D912
        clc
        adc     #$07
        sta     $D915
        lda     L62C7
        adc     #$00
        sta     $D916
        lda     $D5F1
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::PaintRect, $D90F
        MGTK_RELAY_CALL MGTK::InitPort, $D239
        MGTK_RELAY_CALL MGTK::SetPort, $D239
        rts

L62C7:  .byte   0
L62C8:  sta     $D212
        MGTK_RELAY_CALL MGTK::GetWinPort, $D212
        MGTK_RELAY_CALL MGTK::SetPort, $D215
        rts

L62DE:  ldax    #$0F5A
L62E2:  sta     L63C2,x
        dex
        bpl     L62E2
        lda     #$00
        sta     L63BF
        sta     L63BE
L62F0:  lda     L63BF
        cmp     $177F
        bne     L62FB
        jmp     L6377

L62FB:  lda     L63BE
        jsr     L6451
        ldy     #$00
        lda     ($06),y
        bmi     L633D
        and     #$0F
        sta     L63C1
        ldy     #$01
L630E:  lda     ($06),y
        cmp     L63C1,y
        beq     L631A
        bcs     L633D
        jmp     L6322

L631A:  iny
        cpy     #$10
        bne     L630E
        jmp     L633D

L6322:  lda     L63BE
        sta     L63C0
        ldx     #$0F
        lda     #$20
L632C:  sta     L63C2,x
        dex
        bpl     L632C
        ldy     L63C1
L6335:  lda     ($06),y
        sta     L63C1,y
        dey
        bne     L6335
L633D:  inc     L63BE
        lda     L63BE
        cmp     $177F
        beq     L634B
        jmp     L62FB

L634B:  lda     L63C0
        jsr     L6451
        ldy     #$00
        lda     ($06),y
        ora     #$80
        sta     ($06),y
        ldax    #$0F5A
L635D:  sta     L63C2,x
        dex
        bpl     L635D
        ldx     L63BF
        lda     L63C0
        sta     L63D2,x
        lda     #$00
        sta     L63BE
        inc     L63BF
        jmp     L62F0

L6377:  ldx     $177F
        dex
        stx     L63BF
L637E:  lda     L63BF
        bpl     L63AD
        ldx     $177F
        beq     L63AC
        dex
L6389:  lda     L63D2,x
        tay
        lda     $1780,y
        bpl     L639A
        lda     L63D2,x
        ora     #$80
        sta     L63D2,x
L639A:  dex
        bpl     L6389
        ldx     $177F
        beq     L63AC
        dex
L63A3:  lda     L63D2,x
        sta     $1780,x
        dex
        bpl     L63A3
L63AC:  rts

L63AD:  jsr     L6451
        ldy     #$00
        lda     ($06),y
        and     #$7F
        sta     ($06),y
        dec     L63BF
        jmp     L637E

L63BE:  .byte   0
L63BF:  .byte   0
L63C0:  .byte   0
L63C1:  .byte   0
L63C2:  .res 16, 0
L63D2:  .res 127, 0
L6451:  ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        asl     a
        rol     L647B
        clc
        adc     $06
        sta     $06
        lda     L647B
        adc     $07
        sta     $07
        rts

L647B:  .byte   0
        sta     $06
        stx     $07
        ldy     #$01
        lda     ($06),y
        cmp     #$2F
        bne     L64DE
        dey
        lda     ($06),y
        cmp     #$02
        bcc     L64DE
        tay
        lda     ($06),y
        cmp     #$2F
        beq     L64DE
        ldx     #$00
        stx     L64E1
L649B:  lda     ($06),y
        cmp     #$2F
        beq     L64AB
        inx
        cpx     #$10
        beq     L64DE
        dey
        bne     L649B
        beq     L64B3
L64AB:  inc     L64E1
        ldx     #$00
        dey
        bne     L649B
L64B3:  ldy     #$00
        lda     ($06),y
        tay
L64B8:  lda     ($06),y
        and     #$7F
        cmp     #$2E
        beq     L64D8
        cmp     #$2F
        bcc     L64DE
        cmp     #$3A
        bcc     L64D8
        cmp     #$41
        bcc     L64DE
        cmp     #$5B
        bcc     L64D8
        cmp     #$61
        bcc     L64DE
        cmp     #$7B
        bcs     L64DE
L64D8:  dey
        bne     L64B8
        return  #$00

L64DE:  return  #$FF

L64E1:  .byte   0
L64E2:  lda     $177F
        bne     L64E8
L64E7:  rts

L64E8:  lda     #$00
        sta     L6515
        lda     #$00
        sta     $06
        lda     #$18
        sta     $07
L64F5:  lda     L6515
        cmp     $177F
        beq     L64E7
        lda     $06
        ldx     $07
        jsr     L6129
        inc     L6515
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     L64F5
        inc     $07
        jmp     L64F5

L6515:  .byte   0
        sta     $06
        stx     $07
        ldy     #$00
        lda     ($06),y
        tay
L651F:  lda     ($06),y
        sta     L6576,y
        dey
        bpl     L651F
        lda     #$00
        sta     L6575
        lda     #$00
        sta     $06
        lda     #$18
        sta     $07
L6534:  lda     L6575
        cmp     $177F
        beq     L6564
        ldy     #$00
        lda     ($06),y
        cmp     L6576
        bne     L6553
        tay
L6546:  lda     ($06),y
        cmp     L6576,y
        bne     L6553
        dey
        bne     L6546
        jmp     L6567

L6553:  inc     L6575
        lda     $06
        clc
        adc     #$10
        sta     $06
        bcc     L6534
        inc     $07
        jmp     L6534

L6564:  return  #$FF

L6567:  ldx     $177F
        lda     L6575
L656D:  dex
        cmp     $1780,x
        bne     L656D
        txa
        rts

L6575:  .byte   0
L6576:  .res 16, 0

L6586:  bpl     L658B
L6588:  return  #$00

L658B:  cmp     #$09
        bcc     L6588
        sec
        sbc     #$08
        rts

        lda     $D5B7
        jsr     L62C8
        jsr     L6E45
        sta     $06
        stx     $07
        lda     $DAA8
        sta     $08
        lda     $DAA9
        sta     $09
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        bit     $D8EB
        bpl     L65C8
        MGTK_RELAY_CALL MGTK::SetTextBG, $DA5D
        lda     #$00
        sta     $D8EB
        beq     L65D6
L65C8:  MGTK_RELAY_CALL MGTK::SetTextBG, $DA5E
        lda     #$FF
        sta     $D8EB
L65D6:  copy16  #$D8EF, $06
        lda     $D8EE
        sta     $08
        MGTK_RELAY_CALL MGTK::DrawText, $0006
        jsr     L56E3
        rts

        lda     $D5B7
        jsr     L62C8
        jsr     L6E72
        sta     $06
        stx     $07
        lda     $DAB4
        sta     $08
        lda     $DAB5
        sta     $09
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        bit     $D8EB
        bpl     L6626
        MGTK_RELAY_CALL MGTK::SetTextBG, $DA5D
        lda     #$00
        sta     $D8EB
        jmp     L6634

L6626:  MGTK_RELAY_CALL MGTK::SetTextBG, $DA5E
        lda     #$FF
        sta     $D8EB
L6634:  copy16  #$D8EF, $06
        lda     $D8EE
        sta     $08
        MGTK_RELAY_CALL MGTK::DrawText, $0006
        jsr     L56E3
        rts

        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::PaintRect, $DA9E
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::FrameRect, $DA9E
        MGTK_RELAY_CALL MGTK::MoveTo, $DAA6
        lda     $D402
        beq     L6684
        addr_call L5DED, $D402
L6684:  addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        rts

        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::PaintRect, $DAAA
        MGTK_RELAY_CALL MGTK::SetPenMode, $D202
        MGTK_RELAY_CALL MGTK::FrameRect, $DAAA
        MGTK_RELAY_CALL MGTK::MoveTo, $DAB2
        lda     $D443
        beq     L66C9
        addr_call L5DED, $D443
L66C9:  addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        rts

        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $DA9E
        cmp     #$80
        beq     L6719
        bit     L5104
        bpl     L6718
        MGTK_RELAY_CALL MGTK::InRect, $DAAA
        cmp     #$80
        bne     L6718
        jmp     L6D1E

L6718:  rts

L6719:  jsr     L6E45
        sta     $06
        stx     $07
        lda     $D20D
        cmp     $06
        lda     $D20E
        sbc     $07
        bcs     L672F
        jmp     L67C4

L672F:  jsr     L6E45
        stax    L684D
        ldx     $D484
        inx
        lda     #$20
        sta     $D484,x
        inc     $D484
        copy16  #$D484, $06
        lda     $D484
        sta     $08
L6751:  MGTK_RELAY_CALL MGTK::TextWidth, $0006
        lda     $09
        clc
        adc     L684D
        sta     $09
        lda     $0A
        adc     L684E
        sta     $0A
        lda     $09
        cmp     $D20D
        lda     $0A
        sbc     $D20E
        bcc     L6783
        dec     $08
        lda     $08
        cmp     #$01
        bne     L6751
        dec     $D484
        jmp     L6846

L6783:  lda     $08
        cmp     $D484
        bcc     L6790
        dec     $D484
        jmp     L6B44

L6790:  ldx     #$02
        ldy     $D402
        iny
L6796:  lda     $D484,x
        sta     $D402,y
        cpx     $08
        beq     L67A5
        iny
        inx
        jmp     L6796

L67A5:  sty     $D402
        ldy     #$02
        ldx     $08
        inx
L67AD:  lda     $D484,x
        sta     $D484,y
        cpx     $D484
        beq     L67BD
        iny
        inx
        jmp     L67AD

L67BD:  dey
        sty     $D484
        jmp     L6846

L67C4:  copy16  #$D402, $06
        lda     $D402
        sta     $08
L67D1:  MGTK_RELAY_CALL MGTK::TextWidth, $0006
        lda     $09
        clc
        adc     $DAA6
        sta     $09
        lda     $0A
        adc     $DAA7
        sta     $0A
        lda     $09
        cmp     $D20D
        lda     $0A
        sbc     $D20E
        bcc     L6800
        dec     $08
        lda     $08
        cmp     #$01
        bcs     L67D1
        jmp     L6B01

L6800:  inc     $08
        ldy     #$00
        ldx     $08
L6806:  cpx     $D402
        beq     L6816
        inx
        iny
        lda     $D402,x
        sta     $D3C2,y
        jmp     L6806

L6816:  iny
        sty     $D3C1
        ldx     #$01
        ldy     $D3C1
L681F:  cpx     $D484
        beq     L682F
        inx
        iny
        lda     $D484,x
        sta     $D3C1,y
        jmp     L681F

L682F:  sty     $D3C1
        lda     $D8EF
        sta     $D3C2
L6838:  lda     $D3C1,y
        sta     $D484,y
        dey
        bpl     L6838
        lda     $08
        sta     $D402
L6846:  jsr     L6D27
        jsr     L6EA3
        rts

L684D:  .byte   0
L684E:  .byte   0
        lda     $D5B7
        sta     $D208
        MGTK_RELAY_CALL MGTK::ScreenToWindow, $D208
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $D20D
        MGTK_RELAY_CALL MGTK::InRect, $DAAA
        cmp     #$80
        beq     L6890
        bit     L5104
        bpl     L688F
        MGTK_RELAY_CALL MGTK::InRect, $DA9E
        cmp     #$80
        bne     L688F
        jmp     L6D21

L688F:  rts

L6890:  jsr     L6E72
        sta     $06
        stx     $07
        lda     $D20D
        cmp     $06
        lda     $D20E
        sbc     $07
        bcs     L68A6
        jmp     L693B

L68A6:  jsr     L6E72
        stax    L69C4
        ldx     $D484
        inx
        lda     #$20
        sta     $D484,x
        inc     $D484
        copy16  #$D484, $06
        lda     $D484
        sta     $08
L68C8:  MGTK_RELAY_CALL MGTK::TextWidth, $0006
        lda     $09
        clc
        adc     L69C4
        sta     $09
        lda     $0A
        adc     L69C5
        sta     $0A
        lda     $09
        cmp     $D20D
        lda     $0A
        sbc     $D20E
        bcc     L68FA
        dec     $08
        lda     $08
        cmp     #$01
        bne     L68C8
        dec     $D484
        jmp     L69BD

L68FA:  lda     $08
        cmp     $D484
        bcc     L6907
        dec     $D484
        jmp     L6CF0

L6907:  ldx     #$02
        ldy     $D443
        iny
L690D:  lda     $D484,x
        sta     $D443,y
        cpx     $08
        beq     L691C
        iny
        inx
        jmp     L690D

L691C:  sty     $D443
        ldy     #$02
        ldx     $08
        inx
L6924:  lda     $D484,x
        sta     $D484,y
        cpx     $D484
        beq     L6934
        iny
        inx
        jmp     L6924

L6934:  dey
        sty     $D484
        jmp     L69BD

L693B:  copy16  #$D443, $06
        lda     $D443
        sta     $08
L6948:  MGTK_RELAY_CALL MGTK::TextWidth, $0006
        lda     $09
        clc
        adc     $DAB2
        sta     $09
        lda     $0A
        adc     $DAB3
        sta     $0A
        lda     $09
        cmp     $D20D
        lda     $0A
        sbc     $D20E
        bcc     L6977
        dec     $08
        lda     $08
        cmp     #$01
        bcs     L6948
        jmp     L6CAD

L6977:  inc     $08
        ldy     #$00
        ldx     $08
L697D:  cpx     $D443
        beq     L698D
        inx
        iny
        lda     $D443,x
        sta     $D3C2,y
        jmp     L697D

L698D:  iny
        sty     $D3C1
        ldx     #$01
        ldy     $D3C1
L6996:  cpx     $D484
        beq     L69A6
        inx
        iny
        lda     $D484,x
        sta     $D3C1,y
        jmp     L6996

L69A6:  sty     $D3C1
        lda     $D8EF
        sta     $D3C2
L69AF:  lda     $D3C1,y
        sta     $D484,y
        dey
        bpl     L69AF
        lda     $08
        sta     $D443
L69BD:  jsr     L6D27
        jsr     L6E9F
        rts

L69C4:  .byte   0
L69C5:  .byte   0
        sta     L6A17
        lda     $D402
        clc
        adc     $D484
        cmp     #$3F
        bcc     L69D5
        rts

L69D5:  lda     L6A17
        ldx     $D402
        inx
        sta     $D402,x
        sta     $D8F7
        jsr     L6E45
        inc     $D402
        sta     $06
        stx     $07
        lda     $DAA8
        sta     $08
        lda     $DAA9
        sta     $09
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        addr_call L5DED, $D8F6
        addr_call L5DED, $D484
        jsr     L6EA3
        rts

L6A17:  .byte   0
        lda     $D402
        bne     L6A1E
        rts

L6A1E:  dec     $D402
        jsr     L6E45
        sta     $06
        stx     $07
        lda     $DAA8
        sta     $08
        lda     $DAA9
        sta     $09
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        jsr     L6EA3
        rts

        lda     $D402
        bne     L6A59
        rts

L6A59:  ldx     $D484
        cpx     #$01
        beq     L6A6B
L6A60:  lda     $D484,x
        sta     $D485,x
        dex
        cpx     #$01
        bne     L6A60
L6A6B:  ldx     $D402
        lda     $D402,x
        sta     $D486
        dec     $D402
        inc     $D484
        jsr     L6E45
        sta     $06
        stx     $07
        lda     $DAA8
        sta     $08
        lda     $DAA9
        sta     $09
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        jsr     L6EA3
        rts

        lda     $D484
        cmp     #$02
        bcs     L6AB4
        rts

L6AB4:  ldx     $D402
        inx
        lda     $D486
        sta     $D402,x
        inc     $D402
        ldx     $D484
        cpx     #$03
        bcc     L6AD6
        ldx     #$02
L6ACA:  lda     $D485,x
        sta     $D484,x
        inx
        cpx     $D484
        bne     L6ACA
L6AD6:  dec     $D484
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $DAA6
        addr_call L5DED, $D402
        addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        jsr     L6EA3
        rts

L6B01:  lda     $D402
        bne     L6B07
        rts

L6B07:  ldy     $D402
        lda     $D484
        cmp     #$02
        bcc     L6B20
        ldx     #$01
L6B13:  iny
        inx
        lda     $D484,x
        sta     $D402,y
        cpx     $D484
        bne     L6B13
L6B20:  sty     $D402
L6B23:  lda     $D402,y
        sta     $D485,y
        dey
        bne     L6B23
        ldx     $D402
        inx
        stx     $D484
        lda     #$06
        sta     $D485
        lda     #$00
        sta     $D402
        jsr     L6D27
        jsr     L6EA3
        rts

L6B44:  lda     $D484
        cmp     #$02
        bcs     L6B4C
        rts

L6B4C:  ldx     #$01
        ldy     $D402
L6B51:  inx
        iny
        lda     $D484,x
        sta     $D402,y
        cpx     $D484
        bne     L6B51
        sty     $D402
        copy16  #$0601, $D484
        jsr     L6D27
        jsr     L6EA3
        rts

        sta     L6BC3
        lda     $D443
        clc
        adc     $D484
        cmp     #$3F
        bcc     L6B81
        rts

L6B81:  lda     L6BC3
        ldx     $D443
        inx
        sta     $D443,x
        sta     $D8F7
        jsr     L6E72
        inc     $D443
        sta     $06
        stx     $07
        lda     $DAB4
        sta     $08
        lda     $DAB5
        sta     $09
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        addr_call L5DED, $D8F6
        addr_call L5DED, $D484
        jsr     L6E9F
        rts

L6BC3:  .byte   0
        lda     $D443
        bne     L6BCA
        rts

L6BCA:  dec     $D443
        jsr     L6E72
        sta     $06
        stx     $07
        lda     $DAB4
        sta     $08
        lda     $DAB5
        sta     $09
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        jsr     L6E9F
        rts

        lda     $D443
        bne     L6C05
        rts

L6C05:  ldx     $D484
        cpx     #$01
        beq     L6C17
L6C0C:  lda     $D484,x
        sta     $D485,x
        dex
        cpx     #$01
        bne     L6C0C
L6C17:  ldx     $D443
        lda     $D443,x
        sta     $D486
        dec     $D443
        inc     $D484
        jsr     L6E72
        sta     $06
        stx     $07
        lda     $DAB4
        sta     $08
        lda     $DAB5
        sta     $09
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $0006
        addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        jsr     L6E9F
        rts

        lda     $D484
        cmp     #$02
        bcs     L6C60
        rts

L6C60:  ldx     $D443
        inx
        lda     $D486
        sta     $D443,x
        inc     $D443
        ldx     $D484
        cpx     #$03
        bcc     L6C82
        ldx     #$02
L6C76:  lda     $D485,x
        sta     $D484,x
        inx
        cpx     $D484
        bne     L6C76
L6C82:  dec     $D484
        lda     $D5B7
        jsr     L62C8
        MGTK_RELAY_CALL MGTK::MoveTo, $DAB2
        addr_call L5DED, $D443
        addr_call L5DED, $D484
        addr_call L5DED, $D8F8
        jsr     L6E9F
        rts

L6CAD:  lda     $D443
        bne     L6CB3
        rts

L6CB3:  ldy     $D443
        lda     $D484
        cmp     #$02
        bcc     L6CCC
        ldx     #$01
L6CBF:  iny
        inx
        lda     $D484,x
        sta     $D443,y
        cpx     $D484
        bne     L6CBF
L6CCC:  sty     $D443
L6CCF:  lda     $D443,y
        sta     $D485,y
        dey
        bne     L6CCF
        ldx     $D443
        inx
        stx     $D484
        lda     #$06
        sta     $D485
        lda     #$00
        sta     $D443
        jsr     L6D27
        jsr     L6E9F
        rts

L6CF0:  lda     $D484
        cmp     #$02
        bcs     L6CF8
        rts

L6CF8:  ldx     #$01
        ldy     $D443
L6CFD:  inx
        iny
        lda     $D484,x
        sta     $D443,y
        cpx     $D484
        bne     L6CFD
        sty     $D443
        copy16  #$0601, $D484
        jsr     L6D27
        jsr     L6E9F
        rts

L6D1E:  jmp     0
L6D21:  jmp     0
L6D24:  jmp     0
L6D27:  jmp     0
L6D2A:  jmp     0
L6D2D:  jmp     0
L6D30:  jmp     0
L6D33:  jmp     0
L6D36:  jmp     0
L6D39:  jmp     0
L6D3C:  jmp     0
L6D3F:  jmp     0
L6D42:  jmp     0
L6D45:  jmp     0

L6D48:  sta     $06
        stx     $07
        ldx     $D402
        lda     #$2F
        sta     $D403,x
        inc     $D402
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     $D402
        pha
        tax
L6D62:  lda     ($06),y
        sta     $D402,x
        dey
        dex
        cpx     $D402
        bne     L6D62
        pla
        sta     $D402
        rts

L6D73:  sta     $06
        stx     $07
        ldx     $D443
        lda     #$2F
        sta     $D444,x
        inc     $D443
        ldy     #$00
        lda     ($06),y
        tay
        clc
        adc     $D443
        pha
        tax
L6D8D:  lda     ($06),y
        sta     $D443,x
        dey
        dex
        cpx     $D443
        bne     L6D8D
        pla
        sta     $D443
        rts

L6D9E:  ldx     $D402
        cpx     #$00
        beq     L6DAF
        dec     $D402
        lda     $D402,x
        cmp     #$2F
        bne     L6D9E
L6DAF:  rts

L6DB0:  ldx     $D443
        cpx     #$00
        beq     L6DC1
        dec     $D443
        lda     $D443,x
        cmp     #$2F
        bne     L6DB0
L6DC1:  rts

        jsr     L6D9E
        jsr     L6D27
        rts

        jsr     L6DB0
        jsr     L6D27
        rts

        lda     #$00
        beq     L6DD6
        lda     #$80
L6DD6:  sta     L6E1C
        copy16  #$1800, $06
        ldx     $D920
        lda     $1780,x
        and     #$7F
        ldx     #$00
        stx     L6E1B
        asl     a
        rol     L6E1B
        asl     a
        rol     L6E1B
        asl     a
        rol     L6E1B
        asl     a
        rol     L6E1B
        clc
        adc     $06
        tay
        lda     L6E1B
        adc     $07
        tax
        tya
        bit     L6E1C
        bpl     L6E14
        jsr     L6D73
        jmp     L6E17

L6E14:  jsr     L6D48
L6E17:  jsr     L6D27
        rts

L6E1B:  .byte   0
L6E1C:  .byte   0
        ldx     L5028
L6E20:  lda     L5028,x
        sta     $D402,x
        dex
        bpl     L6E20
        addr_call L6129, $D402
        rts

        ldx     L5028
L6E34:  lda     L5028,x
        sta     $D443,x
        dex
        bpl     L6E34
        addr_call L6129, $D443
        rts

L6E45:  lda     #$00
        sta     $09
        sta     $0A
        lda     $D402
        beq     L6E63
        sta     $08
        copy16  #$D403, $06
        MGTK_RELAY_CALL MGTK::TextWidth, $0006
L6E63:  lda     $09
        clc
        adc     $DAA6
        tay
        lda     $0A
        adc     $DAA7
        tax
        tya
        rts

L6E72:  lda     #$00
        sta     $09
        sta     $0A
        lda     $D443
        beq     L6E90
        sta     $08
        copy16  #$D444, $06
        MGTK_RELAY_CALL MGTK::TextWidth, $0006
L6E90:  lda     $09
        clc
        adc     $DAB2
        tay
        lda     $0A
        adc     $DAB3
        tax
        tya
        rts

L6E9F:  lda     #$FF
        bmi     L6EA5
L6EA3:  lda     #$00
L6EA5:  bmi     L6EB6
        ldx     $D402
L6EAA:  lda     $D402,x
        sta     $D3C1,x
        dex
        bpl     L6EAA
        jmp     L6EC2

L6EB6:  ldx     $D443
L6EB9:  lda     $D443,x
        sta     $D3C1,x
        dex
        bpl     L6EB9
L6EC2:  lda     $D920
        sta     L6F3D
        bmi     L6EFB
        ldx     #$00
        stx     $06
        ldx     #$18
        stx     $07
        ldx     #$00
        stx     L6F3C
        tax
        lda     $1780,x
        and     #$7F
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        asl     a
        rol     L6F3C
        clc
        adc     $06
        tay
        lda     L6F3C
        adc     $07
        tax
        tya
        jsr     L5F0D
L6EFB:  addr_call L6129, $D3C1
        addr_call L6129, $5028
        lda     $D3C1
        cmp     L5028
        bne     L6F26
        tax
L6F12:  lda     $D3C1,x
        cmp     L5028,x
        bne     L6F26
        dex
        bne     L6F12
        lda     #$00
        sta     $D8F0
        jsr     L6F2F
        rts

L6F26:  lda     #$FF
        sta     $D8F0
        jsr     L6F2F
        rts

L6F2F:  lda     L6F3D
        sta     $D920
        bpl     L6F38
        rts

L6F38:  jsr     L5F49
        rts

L6F3C:  .byte   0
L6F3D:  .byte   0

        PAD_TO $7000
