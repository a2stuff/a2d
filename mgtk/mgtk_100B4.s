; Target assembler: cc65 v2.18.0 [--target none -C selector_mgtk_cc65.cfg]
; 6502bench SourceGen v1.6.0-alpha1
        .setcpu "6502"
P8_ALLOC_INTERRUPT = $40
P8_DEALLOC_INTERRUPT = $41

MON_WNDLEFT =   $20     ;left column of scroll window
MON_WNDWDTH =   $21     ;width of scroll window
MON_WNDTOP =    $22     ;top of scroll window
MON_CH  =       $24     ;cursor horizontal displacement
MON_GBASL =     $26     ;base address for lo-res drawing (lo)
MON_BASL =      $28     ;base address for text output (lo)
MON_H2  =       $2c     ;right end of horizontal line drawn by HLINE
MON_COLOR =     $30     ;lo-res graphics color
MON_INVFLAG =   $32     ;text mask (255=normal, 127=flash, 63=inv)
MON_CSWL =      $36     ;character output hook (lo)
MON_KSWL =      $38     ;character input hook (lo)
MON_PCL =       $3a     ;program counter save
MON_A1L =       $3c     ;general purpose
MON_A2L =       $3e     ;general purpose
MON_A3L =       $40     ;general purpose
MON_A3H =       $41     ;general purpose
MON_A4L =       $42     ;general purpose
MON_A4H =       $43     ;general purpose
params_addr =   $80
current_grafport = $d0
current_penpattern = $e0
current_colormask_and = $e8
current_colormask_or = $e9
current_penloc_x = $ea
current_penloc_y = $ec
current_penwidth = $ee
current_penheight = $ef
current_penmode = $f0
current_textback = $f1
current_textfont = $f2
active_port =   $f4
fill_eor_mask = $f6
x_offset =      $f7
y_offset =      $f9
glyph_widths =  $fb
glyph_type =    $fd
glyph_last =    $fe
glyph_height_p = $ff
SCRNHOLE0 =     $0478   ;text page 1 screen holes
SCRNHOLE1 =     $04f8   ;text page 1 screen holes
SCRNHOLE2 =     $0578   ;text page 1 screen holes
SCRNHOLE3 =     $05f8   ;text page 1 screen holes
P8_MLI  =       $bf00   ;ProDOS MLI call entry point
CLR80COL =      $c000   ;W use $C002-C005 for aux mem (80STOREOFF)
KBD     =       $c000   ;R last key pressed + 128
SET80VID =      $c00d   ;W enable 80-column display mode
KBDSTRB =       $c010   ;RW keyboard strobe
SPKR    =       $c030   ;RW toggle speaker
TXTPAGE1 =      $c054   ;RW display page 1
TXTPAGE2 =      $c055   ;RW display page 2 (or read/write aux mem)
SETAN3  =       $c05e   ;RW annunciator 3 off
BUTN0   =       $c061   ;R switch input 0 / open-apple
BUTN1   =       $c062   ;R switch input 1 / closed-apple
MON_VERSION =   $fbb3

;        .segment "SEG000"
        .org    $4000
MGTK:   bit     preserve_zp_flag
        bpl     adjust_stack
        ldx     #$7f
@L4007: lda     params_addr,x
        sta     zp_saved,x
        dex
        bpl     @L4007
        ldx     #$0b
@L4011: lda     active_saved,x
        sta     active_port,x
        dex
        bpl     @L4011
        jsr     apply_active_port_to_port
adjust_stack:
        pla
        sta     params_addr
        clc
        adc     #$03
        tax
        pla
        sta     params_addr+1
        adc     #$00
        pha
        txa
        pha
        tsx
        stx     stack_ptr_stash
        ldy     #$01
        lda     (params_addr),y
        asl     a
        tax
        lda     jump_table,x
        sta     jump+1
        lda     jump_table+1,x
        sta     jump+2
        iny
        lda     (params_addr),y
        pha
        iny
        lda     (params_addr),y
        sta     params_addr+1
        pla
        sta     params_addr
        ldy     param_lengths+1,x
        bpl     done_hiding
        txa
        pha
        tya
        pha
        lda     params_addr
        pha
        lda     params_addr+1
        pha
        bit     savebehind_usage+2
        bpl     @L4064
        jsr     hide_cursor
@L4064: pla
        sta     params_addr+1
        pla
        sta     params_addr
        pla
        and     #$7f
        tay
        pla
        tax
done_hiding:
        lda     param_lengths,x
        beq     jump
        sta     store+1
        dey
L4079:  lda     (params_addr),y
store:  sta     glyph_height_p,y
        dey
        bpl     L4079
jump:   jsr     $ffff
cleanup:
        bit     savebehind_usage+2
        bpl     @L408C
        jsr     show_cursor
@L408C: bit     preserve_zp_flag
        bpl     exit_with_0
        jsr     apply_port_to_active_port
        ldx     #$0b
@L4096: lda     active_port,x
        sta     active_saved,x
        dex
        bpl     @L4096
        ldx     #$7f
@L40A0: lda     zp_saved,x
        sta     params_addr,x
        dex
        bpl     @L40A0
exit_with_0:
        lda     #$00
rts1:   rts

exit_with_a:
        pha
        jsr     cleanup
        pla
        ldx     stack_ptr_stash
        txs
        ldy     #$ff
L40B6:  rts

apply_active_port_to_port:
        ldy     #$23
@L40B9: lda     (active_port),y
        sta     current_grafport,y
        dey
        bpl     @L40B9
        rts

apply_port_to_active_port:
        ldy     #$23
@L40C4: lda     current_grafport,y
        sta     (active_port),y
        dey
        bpl     @L40C4
        rts

hide_cursor_count:
        .byte   $00

hide_cursor:
        dec     hide_cursor_count
        jmp     HideCursorImpl

show_cursor:
        bit     hide_cursor_count
        bpl     L40B6
        inc     hide_cursor_count
        jmp     ShowCursorImpl

; ============================================================
; Jump Table
; ============================================================
; 
jump_table:
        .word   rts1
; ============================================================
; Graphics Primitives
; 
; Initialization Commands
        .word   InitGrafImpl
        .word   SetSwitchesImpl
; GrafPort Commands
        .word   InitPortImpl
        .word   SetPortImpl
        .word   GetPortImpl
        .word   SetPortBitsImpl
        .word   SetPenModeImpl
        .word   SetPatternImpl
        .word   rts1
        .word   rts1
        .word   SetFontImpl
        .word   rts1
; Drawing Commands
        .word   MoveImpl
        .word   rts1
        .word   LineImpl
        .word   LineToImpl
        .word   PaintRectImpl
        .word   FrameRectImpl
        .word   InRectImpl
        .word   PaintBitsImpl
        .word   PaintPolyImpl
        .word   FramePolyImpl
        .word   InPolyImpl
; Text Commands
        .word   TextWidthImpl
        .word   DrawTextImpl
; Utility Commands
        .word   SetZP1Impl
        .word   SetZP2Impl
        .word   VersionImpl
; ============================================================
; MouseGraphics ToolKit
; 
; Initialization Calls
        .word   StartDeskTopImpl
        .word   StopDeskTopImpl
        .word   SetUserHookImpl
        .word   AttachDriverImpl
        .word   ScaleMouseImpl
        .word   KeyboardMouseImpl
; Cursor Manager Calls
        .word   SetCursorImpl
        .word   ShowCursorImpl
        .word   HideCursorImpl
        .word   ObscureCursorImpl
        .word   GetCursorAddrImpl
; Event Manager Calls
        .word   CheckEventsImpl
        .word   GetEventImpl
        .word   FlushEventsImpl
        .word   PeekEventImpl
        .word   PostEventImpl
        .word   SetKeyEventImpl
; Menu Manager Commands
        .word   InitMenuImpl
        .word   SetMenuImpl
        .word   MenuSelectImpl
        .word   MenuKeyImpl
        .word   HiliteMenuImpl
        .word   DisableMenuImpl
        .word   DisableItemImpl
        .word   CheckItemImpl
        .word   SetMarkImpl
; Window Manager Calls
        .word   OpenWindowImpl
        .word   CloseWindowImpl
        .word   CloseAllImpl
        .word   GetWinPtrImpl
        .word   GetWinPortImpl
        .word   SetWinPortImpl
        .word   BeginUpdateImpl
        .word   EndUpdateImpl
        .word   FindWindowImpl
        .word   FrontWindowImpl
        .word   SelectWindowImpl
        .word   TrackGoAwayImpl
        .word   DragWindowImpl
        .word   GrowWindowImpl
        .word   ScreenToWindowImpl
        .word   WindowToScreenImpl
; Control Manager Calls
        .word   FindControlImpl
        .word   SetCtlMaxImpl
        .word   TrackThumbImpl
        .word   UpdateThumbImpl
        .word   ActivateCtlImpl
; Extra Calls
        .word   BitBltImpl
; ============================================================
; Parameter Definitions
; ============================================================
; 
param_lengths:
        .byte   $00,$00
; ============================================================
; Graphics Primitives
; 
; Initialization
        .byte   $00,$00
        .byte   $82,$01
; GrafPort
        .byte   $00,$00
        .byte   $d0,$24
        .byte   $00,$00
        .byte   $d0,$10
        .byte   $f0,$01
        .byte   $e0,$08
        .byte   $e8,$02
        .byte   $ee,$02
        .byte   $00,$00
        .byte   $f1,$01
; Drawing
        .byte   $a1,$04
        .byte   $ea,$04
        .byte   $a1,$84
        .byte   $92,$84
        .byte   $92,$88
        .byte   $9f,$88
        .byte   $92,$08
        .byte   $8a,$10
        .byte   $00,$80
        .byte   $00,$80
        .byte   $00,$00
; Text
        .byte   $a1,$03
        .byte   $a1,$83
; Utility
        .byte   $82,$01
        .byte   $82,$01
        .byte   $00,$00
; ============================================================
; MouseGraphics ToolKit
; 
; Initialization
        .byte   $82,$0c
        .byte   $00,$00
        .byte   $82,$03
        .byte   $82,$02
        .byte   $82,$02
        .byte   $82,$01
; Cursor Manager
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
; Event Manager
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $00,$00
        .byte   $82,$05
        .byte   $82,$01
; Menu Manager
        .byte   $82,$04
        .byte   $00,$00
        .byte   $00,$00
        .byte   $c7,$04
        .byte   $c7,$01
        .byte   $c7,$02
        .byte   $c7,$03
        .byte   $c7,$03
        .byte   $c7,$04
; Window Manager
        .byte   $00,$00
        .byte   $82,$01
        .byte   $00,$00
        .byte   $82,$01
        .byte   $82,$03
        .byte   $82,$02
        .byte   $82,$01
        .byte   $82,$01
        .byte   $ea,$04
        .byte   $00,$00
        .byte   $82,$01
        .byte   $00,$00
        .byte   $82,$05
        .byte   $82,$05
        .byte   $82,$05
        .byte   $82,$05
; Control Manager
        .byte   $ea,$04
        .byte   $82,$03
        .byte   $82,$05
        .byte   $8c,$03
        .byte   $8c,$02
; Extra Calls
        .byte   $8a,$10
; 
; Pre-Shift Tables
; 
shift_1_aux:
        .byte   $00,$02,$04,$06,$08,$0a,$0c,$0e
        .byte   $10,$12,$14,$16,$18,$1a,$1c,$1e
        .byte   $20,$22,$24,$26,$28,$2a,$2c,$2e
        .byte   $30,$32,$34,$36,$38,$3a,$3c,$3e
        .byte   $40,$42,$44,$46,$48,$4a,$4c,$4e
        .byte   $50,$52,$54,$56,$58,$5a,$5c,$5e
        .byte   $60,$62,$64,$66,$68,$6a,$6c,$6e
        .byte   $70,$72,$74,$76,$78,$7a,$7c,$7e
        .byte   $00,$02,$04,$06,$08,$0a,$0c,$0e
        .byte   $10,$12,$14,$16,$18,$1a,$1c,$1e
        .byte   $20,$22,$24,$26,$28,$2a,$2c,$2e
        .byte   $30,$32,$34,$36,$38,$3a,$3c,$3e
        .byte   $40,$42,$44,$46,$48,$4a,$4c,$4e
        .byte   $50,$52,$54,$56,$58,$5a,$5c,$5e
        .byte   $60,$62,$64,$66,$68,$6a,$6c,$6e
        .byte   $70,$72,$74,$76,$78,$7a,$7c,$7e
shift_1_main:
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
shift_2_aux:
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $20,$24,$28,$2c,$30,$34,$38,$3c
        .byte   $40,$44,$48,$4c,$50,$54,$58,$5c
        .byte   $60,$64,$68,$6c,$70,$74,$78,$7c
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $20,$24,$28,$2c,$30,$34,$38,$3c
        .byte   $40,$44,$48,$4c,$50,$54,$58,$5c
        .byte   $60,$64,$68,$6c,$70,$74,$78,$7c
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $20,$24,$28,$2c,$30,$34,$38,$3c
        .byte   $40,$44,$48,$4c,$50,$54,$58,$5c
        .byte   $60,$64,$68,$6c,$70,$74,$78,$7c
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $20,$24,$28,$2c,$30,$34,$38,$3c
        .byte   $40,$44,$48,$4c,$50,$54,$58,$5c
        .byte   $60,$64,$68,$6c,$70,$74,$78,$7c
shift_2_main:
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
shift_3_aux:
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
shift_3_main:
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
shift_4_aux:
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
shift_4_main:
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
        .byte   $0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a
        .byte   $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
        .byte   $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
        .byte   $0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d
        .byte   $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
        .byte   $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
shift_5_aux:
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
shift_5_main:
        .byte   $00,$00,$00,$00,$01,$01,$01,$01
        .byte   $02,$02,$02,$02,$03,$03,$03,$03
        .byte   $04,$04,$04,$04,$05,$05,$05,$05
        .byte   $06,$06,$06,$06,$07,$07,$07,$07
        .byte   $08,$08,$08,$08,$09,$09,$09,$09
        .byte   $0a,$0a,$0a,$0a,$0b,$0b,$0b,$0b
        .byte   $0c,$0c,$0c,$0c,$0d,$0d,$0d,$0d
        .byte   $0e,$0e,$0e,$0e,$0f,$0f,$0f,$0f
        .byte   $10,$10,$10,$10,$11,$11,$11,$11
        .byte   $12,$12,$12,$12,$13,$13,$13,$13
        .byte   $14,$14,$14,$14,$15,$15,$15,$15
        .byte   $16,$16,$16,$16,$17,$17,$17,$17
        .byte   $18,$18,$18,$18,$19,$19,$19,$19
        .byte   $1a,$1a,$1a,$1a,$1b,$1b,$1b,$1b
        .byte   $1c,$1c,$1c,$1c,$1d,$1d,$1d,$1d
        .byte   $1e,$1e,$1e,$1e,$1f,$1f,$1f,$1f
shift_6_aux:
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
shift_6_main:
        .byte   $00,$00,$01,$01,$02,$02,$03,$03
        .byte   $04,$04,$05,$05,$06,$06,$07,$07
        .byte   $08,$08,$09,$09,$0a,$0a,$0b,$0b
        .byte   $0c,$0c,$0d,$0d,$0e,$0e,$0f,$0f
        .byte   $10,$10,$11,$11,$12,$12,$13,$13
        .byte   $14,$14,$15,$15,$16,$16,$17,$17
        .byte   $18,$18,$19,$19,$1a,$1a,$1b,$1b
        .byte   $1c,$1c,$1d,$1d,$1e,$1e,$1f,$1f
        .byte   $20,$20,$21,$21,$22,$22,$23,$23
        .byte   $24,$24,$25,$25,$26,$26,$27,$27
        .byte   $28,$28,$29,$29,$2a,$2a,$2b,$2b
        .byte   $2c,$2c,$2d,$2d,$2e,$2e,$2f,$2f
        .byte   $30,$30,$31,$31,$32,$32,$33,$33
        .byte   $34,$34,$35,$35,$36,$36,$37,$37
        .byte   $38,$38,$39,$39,$3a,$3a,$3b,$3b
        .byte   $3c,$3c,$3d,$3d,$3e,$3e,$3f,$3f
div_7_table:
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $01,$01,$01,$01,$01,$01,$02,$02
        .byte   $02,$02,$02,$02,$02,$03,$03,$03
        .byte   $03,$03,$03,$03,$04,$04,$04,$04
        .byte   $04,$04,$04,$05,$05,$05,$05,$05
        .byte   $05,$05,$06,$06,$06,$06,$06,$06
        .byte   $06,$07,$07,$07,$07,$07,$07,$07
        .byte   $08,$08,$08,$08,$08,$08,$08,$09
        .byte   $09,$09,$09,$09,$09,$09,$0a,$0a
        .byte   $0a,$0a,$0a,$0a,$0a,$0b,$0b,$0b
        .byte   $0b,$0b,$0b,$0b,$0c,$0c,$0c,$0c
        .byte   $0c,$0c,$0c,$0d,$0d,$0d,$0d,$0d
        .byte   $0d,$0d,$0e,$0e,$0e,$0e,$0e,$0e
        .byte   $0e,$0f,$0f,$0f,$0f,$0f,$0f,$0f
        .byte   $10,$10,$10,$10,$10,$10,$10,$11
        .byte   $11,$11,$11,$11,$11,$11,$12,$12
        .byte   $12,$12,$12,$12,$12,$13,$13,$13
        .byte   $13,$13,$13,$13,$14,$14,$14,$14
        .byte   $14,$14,$14,$15,$15,$15,$15,$15
        .byte   $15,$15,$16,$16,$16,$16,$16,$16
        .byte   $16,$17,$17,$17,$17,$17,$17,$17
        .byte   $18,$18,$18,$18,$18,$18,$18,$19
        .byte   $19,$19,$19,$19,$19,$19,$1a,$1a
        .byte   $1a,$1a,$1a,$1a,$1a,$1b,$1b,$1b
        .byte   $1b,$1b,$1b,$1b,$1c,$1c,$1c,$1c
        .byte   $1c,$1c,$1c,$1d,$1d,$1d,$1d,$1d
        .byte   $1d,$1d,$1e,$1e,$1e,$1e,$1e,$1e
        .byte   $1e,$1f,$1f,$1f,$1f,$1f,$1f,$1f
        .byte   $20,$20,$20,$20,$20,$20,$20,$21
        .byte   $21,$21,$21,$21,$21,$21,$22,$22
        .byte   $22,$22,$22,$22,$22,$23,$23,$23
        .byte   $23,$23,$23,$23,$24,$24,$24,$24
mod_7_table:
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
        .byte   $00,$01,$02,$03,$04,$05,$06,$00
L498B:  .byte   $01,$02,$03,$04,$05,$06,$00,$01
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
        .byte   $00,$01,$02,$03,$04,$05,$06,$00
        .byte   $01,$02,$03,$04,$05,$06,$00,$01
        .byte   $02,$03,$04,$05,$06,$00,$01,$02
        .byte   $03,$04,$05,$06,$00,$01,$02,$03
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
        .byte   $a8,$a8,$a8,$a8,$a8,$a8,$a8,$a8
        .byte   $28,$28,$28,$28,$28,$28,$28,$28
        .byte   $a8,$a8,$a8,$a8,$a8,$a8,$a8,$a8
        .byte   $28,$28,$28,$28,$28,$28,$28,$28
        .byte   $a8,$a8,$a8,$a8,$a8,$a8,$a8,$a8
        .byte   $28,$28,$28,$28,$28,$28,$28,$28
        .byte   $a8,$a8,$a8,$a8,$a8,$a8,$a8,$a8
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $d0,$d0,$d0,$d0,$d0,$d0,$d0,$d0
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $d0,$d0,$d0,$d0,$d0,$d0,$d0,$d0
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $d0,$d0,$d0,$d0,$d0,$d0,$d0,$d0
        .byte   $50,$50,$50,$50,$50,$50,$50,$50
        .byte   $d0,$d0,$d0,$d0,$d0,$d0,$d0,$d0
hires_table_hi:
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $01,$05,$09,$0d,$11,$15,$19,$1d
        .byte   $01,$05,$09,$0d,$11,$15,$19,$1d
        .byte   $02,$06,$0a,$0e,$12,$16,$1a,$1e
        .byte   $02,$06,$0a,$0e,$12,$16,$1a,$1e
        .byte   $03,$07,$0b,$0f,$13,$17,$1b,$1f
        .byte   $03,$07,$0b,$0f,$13,$17,$1b,$1f
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $01,$05,$09,$0d,$11,$15,$19,$1d
        .byte   $01,$05,$09,$0d,$11,$15,$19,$1d
        .byte   $02,$06,$0a,$0e,$12,$16,$1a,$1e
        .byte   $02,$06,$0a,$0e,$12,$16,$1a,$1e
        .byte   $03,$07,$0b,$0f,$13,$17,$1b,$1f
        .byte   $03,$07,$0b,$0f,$13,$17,$1b,$1f
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $00,$04,$08,$0c,$10,$14,$18,$1c
        .byte   $01,$05,$09,$0d,$11,$15,$19,$1d
        .byte   $01,$05,$09,$0d,$11,$15,$19,$1d
        .byte   $02,$06,$0a,$0e,$12,$16,$1a,$1e
        .byte   $02,$06,$0a,$0e,$12,$16,$1a,$1e
        .byte   $03,$07,$0b,$0f,$13,$17,$1b,$1f
        .byte   $03,$07,$0b,$0f,$13,$17,$1b,$1f

src_addr .set   $82
vid_addr .set   $84
left_bytes .set $86
left_mod14 .set $87
left_sidemask .set $88
right_sidemask .set $89
src_y_coord .set $8c
bits_addr .set  $8e
src_mapwidth .set $90
width_bytes .set $91
left    .set    $92
top     .set    $94
right   .set    $96
bottom  .set    $98
fillmode_copy:
        lda     (vid_addr),y
        eor     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        eor     (vid_addr),y
        bcc     @L4BA3
@L4B9F: lda     (bits_addr),y
        eor     fill_eor_mask
@L4BA3: and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        dey
        bne     @L4B9F
fillmode_copy_onechar:
        lda     (vid_addr),y
        eor     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        rts

fillmode_or:
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        bcc     @L4BC9
@L4BC5: lda     (bits_addr),y
        eor     fill_eor_mask
@L4BC9: ora     (vid_addr),y
        and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        dey
        bne     @L4BC5
fillmode_or_onechar:
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        ora     (vid_addr),y
        and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        rts

fillmode_xor:
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        bcc     @L4BEF
@L4BEB: lda     (bits_addr),y
        eor     fill_eor_mask
@L4BEF: eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        dey
        bne     @L4BEB
fillmode_xor_onechar:
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        rts

fillmode_bic:
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        bcc     @L4C15
@L4C11: lda     (bits_addr),y
        eor     fill_eor_mask
@L4C15: eor     #$ff
        and     (vid_addr),y
        and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        dey
        bne     @L4C11
fillmode_bic_onechar:
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     #$ff
        and     (vid_addr),y
        and     current_colormask_and
        ora     current_colormask_or
        sta     (vid_addr),y
        rts

fill_next_line:
        cpx     bottom
        beq     L4C3B
        inx
L4C38:  jmp     start_fill_jmp

L4C3B:  rts

ndbm_get_srcbits:
        lda     load_addr+1
        adc     src_mapwidth
        sta     load_addr+1
        bcc     @L4C49
        inc     load_addr+2
@L4C49: ldy     src_width_bytes
load_addr:
        lda     $ffff,y
        and     #$7f
        sta     $0601,y
        dey
        bpl     load_addr
        bmi     L4C91

dhgr_get_srcbits:
        ldy     src_y_coord
        inc     src_y_coord
        lda     hires_table_hi,y
        ora     params_addr
        sta     src_addr+1
        lda     hires_table_lo,y
        adc     $8a
        sta     src_addr
L4C6B:  stx     params_addr+1
        ldy     #$00
        ldx     #$00
L4C71:  sta     TXTPAGE2
        lda     (src_addr),y
        and     #$7f
        sta     TXTPAGE1
L4C7B:  sta     $0601,x
        lda     (src_addr),y
        and     #$7f
L4C82:  sta     $0602,x
        iny
        inx
        inx
        cpx     src_width_bytes
        bcc     L4C71
        beq     L4C71
        ldx     params_addr+1
L4C91:  clc
L4C92:  jmp     shift_line_jmp

dhgr_shift_bits:
        stx     src_addr
        ldy     src_width_bytes
        lda     #$00
L4C9C:  ldx     $0601,y
L4C9F:  ora     shift_1_main,x
L4CA2:  sta     $0602,y
L4CA5:  lda     shift_1_aux,x
        dey
        bpl     L4C9C
L4CAB:  sta     $0601
        ldx     src_addr
shift_line_jmp:
        jmp     dhgr_next_line

dhgr_shift_line:
        stx     src_addr
        ldx     #$00
        ldy     #$00
L4CB9:  lda     $0601,x
        sta     TXTPAGE2
        sta     $0601,y
        sta     TXTPAGE1
L4CC5:  lda     $0602,x
        sta     $0601,y
        inx
        inx
        iny
        cpy     width_bytes
        bcc     L4CB9
        beq     L4CB9
        ldx     src_addr
        jmp     dhgr_next_line

bit_blit:
        ldx     top
        clc
        jmp     L4C38

do_fill:
        ldx     no_srcbits_addr
        stx     L4C38+1
        ldx     no_srcbits_addr+1
        stx     L4C38+2
        ldx     top
start_fill_jmp:
        jmp     dhgr_start_fill

ndbm_start_fill:
        txa
        ror     a
        ror     a
        ror     a
        and     #$c0
        ora     left_bytes
        sta     src_addr
        lda     #$04
        adc     #$00
        sta     src_addr+1
        jmp     L4C6B

dhgr_start_fill:
        txa
        ror     a
        ror     a
        ror     a
        and     #$c0
        ora     left_bytes
        sta     bits_addr
        lda     #$04
        adc     #$00
        sta     bits_addr+1
L4D13:  jmp     dhgr_next_line

ndbm_next_line:
        lda     vid_addr
        clc
        adc     current_grafport+6
        sta     vid_addr
        bcc     @L4D22
        inc     vid_addr+1
        clc
@L4D22: ldy     width_bytes
        jsr     fillmode_jmp
        jmp     fill_next_line

dhgr_next_line:
        lda     hires_table_hi,x
        ora     current_grafport+5
        sta     vid_addr+1
        lda     hires_table_lo,x
        clc
        adc     left_bytes
        sta     vid_addr
        ldy     #$01
        jsr     dhgr_fill_line
        ldy     #$00
        jsr     dhgr_fill_line
        jmp     fill_next_line

dhgr_fill_line:
        sta     TXTPAGE1,y
        lda     $0092,y
        ora     #$80
        sta     left_sidemask
        lda     $0096,y
        ora     #$80
        sta     right_sidemask
        ldy     width_bytes
fillmode_jmp:
        jmp     fillmode_copy

no_srcbits_addr:
        .word   start_fill_jmp
main_right_masks:
        .byte   $00,$00,$00,$00,$00,$00,$00
aux_right_masks:
        .byte   $01,$03,$07,$0f,$1f,$3f,$7f
main_left_masks:
        .byte   $7f,$7f,$7f,$7f,$7f,$7f,$7f
aux_left_masks:
        .byte   $7f,$7e,$7c,$78,$70,$60,$40
        .byte   $00,$00,$00,$00,$00,$00,$00
fill_mode_table:
        .word   fillmode_copy
        .word   fillmode_or
        .word   fillmode_xor
        .word   fillmode_bic
        .word   fillmode_copy
        .word   fillmode_or
        .word   fillmode_xor
        .word   fillmode_bic
fill_mode_table_onechar:
        .word   fillmode_copy_onechar
        .word   fillmode_or_onechar
        .word   fillmode_xor_onechar
        .word   fillmode_bic_onechar
        .word   fillmode_copy_onechar
        .word   fillmode_or_onechar
        .word   fillmode_xor_onechar
        .word   fillmode_bic_onechar

; 
; SetPenMode
; 
SetPenModeImpl:
        lda     current_penmode
        ldx     #$00
        cmp     #$04
        bcc     @L4DAB
        ldx     #$7f
@L4DAB: stx     fill_eor_mask
        rts

set_up_fill_mode:
        lda     x_offset
        clc
        adc     right
        sta     right
        lda     x_offset+1
        adc     right+1
        sta     right+1
        lda     y_offset
        clc
        adc     bottom
        sta     bottom
        lda     y_offset+1
        adc     bottom+1
        sta     bottom+1
        lda     x_offset
        clc
        adc     left
        sta     left
        lda     x_offset+1
        adc     left+1
        sta     left+1
        lda     y_offset
        clc
        adc     top
        sta     top
        lda     y_offset+1
        adc     top+1
        sta     top+1
        lsr     right+1
        beq     @L4DE9
        jmp     rl_ge256

@L4DE9: lda     right
        ror     a
        tax
        lda     div_7_table,x
        ldy     mod_7_table,x
L4DF3:  sta     src_addr
        tya
        rol     a
        tay
        lda     aux_right_masks,y
        sta     right+1
        lda     main_right_masks,y
        sta     right
        lsr     left+1
        bne     ll_ge256
        lda     left
        ror     a
        tax
        lda     div_7_table,x
        ldy     mod_7_table,x
L4E10:  sta     left_bytes
        tya
        rol     a
        tay
        sty     left_mod14
        lda     aux_left_masks,y
        sta     left+1
        lda     main_left_masks,y
        sta     left
        lda     src_addr
        sec
        sbc     left_bytes
L4E26:  sta     width_bytes
        pha
        lda     current_penmode
        asl     a
        tax
        pla
        bne     @L4E4D
        lda     left+1
        and     right+1
        sta     left+1
        sta     right+1
        lda     left
        and     right
        sta     left
        sta     right
        lda     fill_mode_table_onechar,x
        sta     no_srcbits_addr-2
        lda     fill_mode_table_onechar+1,x
        sta     no_srcbits_addr-1
        rts

@L4E4D: lda     fill_mode_table,x
        sta     no_srcbits_addr-2
        lda     fill_mode_table+1,x
        sta     no_srcbits_addr-1
        rts

ll_ge256:
        lda     left
        ror     a
        tax
        php
        lda     div_7_table+4,x
        clc
        adc     #$24
        plp
        ldy     mod_7_table+4,x
        bpl     L4E10
rl_ge256:
        lda     right
        ror     a
        tax
        php
        lda     div_7_table+4,x
        clc
        adc     #$24
        plp
        ldy     mod_7_table+4,x
        bmi     divmod7
        jmp     L4DF3

divmod7:
        lsr     a
        bne     @L4E8C
        txa
        ror     a
        tax
        lda     div_7_table,x
        ldy     mod_7_table,x
        rts

@L4E8C: txa
        ror     a
        tax
        php
        lda     div_7_table+4,x
        clc
        adc     #$24
        plp
        ldy     mod_7_table+4,x
        rts

set_dest:
        lda     left_bytes
        ldx     top
        ldy     current_grafport+6
        jsr     ndbm_calc_dest
        clc
        adc     current_grafport+4
        sta     vid_addr
        tya
        adc     current_grafport+5
        sta     vid_addr+1
        lda     #$02
        tax
        tay
        bit     current_grafport+6
        bmi     @L4EDB
        lda     #$01
        sta     bits_addr
        lda     #$06
        sta     bits_addr+1
        jsr     ndbm_fix_width
        txa
        inx
        stx     src_width_bytes
        jsr     L4E26
        lda     shift_line_jmp_addr
        sta     L4C92+1
        lda     shift_line_jmp_addr+1
        sta     L4C92+2
        lda     #$00
        ldx     #$00
        ldy     #$00
@L4EDB: pha
        lda     next_line_table,x
        sta     L4D13+1
        lda     next_line_table+1,x
        sta     L4D13+2
        pla
        tax
        lda     start_fill_table,x
        sta     start_fill_jmp+1
        lda     start_fill_table+1,x
        sta     start_fill_jmp+2
        lda     shift_line_table,y
        sta     shift_line_jmp+1
        lda     shift_line_table+1,y
        sta     shift_line_jmp+2
        rts

ndbm_fix_width:
        lda     width_bytes
        asl     a
        tax
        inx
        lda     left+1
        bne     @L4F17
        dex
        inc     bits_addr
        inc     vid_addr
        bne     @L4F15
        inc     vid_addr+1
@L4F15: lda     left
@L4F17: sta     left_sidemask
        lda     right
        bne     @L4F20
        dex
        lda     right+1
@L4F20: sta     right_sidemask
        rts

shift_line_jmp_addr:
        .word   shift_line_jmp
start_fill_table:
        .word   ndbm_start_fill
        .word   dhgr_start_fill
next_line_table:
        .word   ndbm_next_line
        .word   dhgr_next_line
shift_line_table:
        .word   ndbm_next_line
        .word   dhgr_shift_line

set_source:
        ldx     src_y_coord
        ldy     src_mapwidth
        jsr     ndbm_calc_dest
        clc
        adc     bits_addr
        sta     load_addr+1
        tya
        adc     bits_addr+1
        sta     load_addr+2
        ldx     #$02
        bit     src_mapwidth
        bmi     @L4F4C
        ldx     #$00
@L4F4C: lda     get_srcbits_table,x
        sta     L4C38+1
        lda     get_srcbits_table+1,x
        sta     L4C38+2
        rts

get_srcbits_table:
        .word   ndbm_get_srcbits
        .word   dhgr_get_srcbits

ndbm_calc_dest:
        bmi     @L4F7E
        stx     src_addr
        sty     src_addr+1
        nop
        ldx     #$08
@L4F66: lsr     src_addr+1
        bcc     @L4F6D
        clc
        adc     src_addr
@L4F6D: ror     a
        ror     vid_addr
        dex
        bne     @L4F66
        sty     src_addr
        tay
        lda     vid_addr
        sec
        sbc     src_addr
        bcs     @L4F7E
        dey
@L4F7E: rts

; 
; SetPattern
; 
SetPatternImpl:
        lda     #$00
        sta     bits_addr
        lda     y_offset
        and     #$07
        lsr     a
        ror     bits_addr
        lsr     a
        ror     bits_addr
        adc     #$04
        sta     bits_addr+1
        ldx     #$07
@L4F93: lda     x_offset
        and     #$07
        tay
        lda     current_penpattern,x
@L4F9A: dey
        bmi     @L4FA2
        cmp     #$80
        rol     a
        bne     @L4F9A
@L4FA2: ldy     #$27
@L4FA4: pha
        lsr     a
        sta     TXTPAGE1
        sta     (bits_addr),y
        pla
        ror     a
        pha
        lsr     a
        sta     TXTPAGE2
        sta     (bits_addr),y
        pla
        ror     a
        dey
        bpl     @L4FA4
        lda     bits_addr
        sec
        sbc     #$40
        sta     bits_addr
        bcs     @L4FCD
        ldy     bits_addr+1
        dey
        cpy     #$04
        bcs     @L4FCB
        ldy     #$05
@L4FCB: sty     bits_addr+1
@L4FCD: dex
        bpl     @L4F93
        sta     TXTPAGE1
        rts

frect_ctr:
        .byte   $00

; 
; FrameRect
; 
FrameRectImpl:
        ldy     #$03
@L4FD7: ldx     #$07
@L4FD9: lda     $9f,x
        sta     left,x
        dex
        bpl     @L4FD9
        ldx     rect_sides,y
        lda     $9f,x
        pha
        lda     $a0,x
        ldx     rect_coords,y
        sta     left+1,x
        pla
        sta     left,x
        sty     frect_ctr
        jsr     draw_line
        ldy     frect_ctr
        dey
        bpl     @L4FD7
        ldx     #$03
@L4FFE: lda     $9f,x
        sta     current_penloc_x,x
        dex
        bpl     @L4FFE
L5005:  rts

rect_sides:
        .byte   $00
        .byte   $02
        .byte   $04
        .byte   $06
rect_coords:
        .byte   $04
        .byte   $06
        .byte   $00
        .byte   $02

draw_line:
        lda     current_penwidth
        sec
        sbc     #$01
        cmp     #$ff
        beq     L5005
        adc     right
        sta     right
        bcc     @L501F
        inc     right+1
@L501F: lda     current_penheight
        sec
        sbc     #$01
        cmp     #$ff
        beq     L5005
        adc     bottom
        sta     bottom
        bcc     PaintRectImpl
        inc     bottom+1
; 
; PaintRect
; 
PaintRectImpl:
        jsr     L513C
L5033:  jsr     clip_rect
        bcc     L5005
        jsr     set_up_fill_mode
        jsr     set_dest
        jmp     do_fill

; 
; InRect
; 
InRectImpl:
        jsr     L513C
        lda     current_penloc_x
        ldx     current_penloc_x+1
        cpx     left+1
        bmi     @L507D
        bne     @L5052
        cmp     left
        bcc     @L507D
@L5052: cpx     right+1
        bmi     @L505E
        bne     @L507D
        cmp     right
        bcc     @L505E
        bne     @L507D
@L505E: lda     current_penloc_y
        ldx     current_penloc_y+1
        cpx     top+1
        bmi     @L507D
        bne     @L506C
        cmp     top
        bcc     @L507D
@L506C: cpx     bottom+1
        bmi     @L5078
        bne     @L507D
        cmp     bottom
        bcc     @L5078
        bne     @L507D
@L5078: lda     #$80
        jmp     exit_with_a

@L507D: rts

; 
; SetPortBits
; 
SetPortBitsImpl:
        lda     current_grafport
        sec
        sbc     current_grafport+8
        sta     x_offset
        lda     current_grafport+1
        sbc     current_grafport+9
        sta     x_offset+1
        lda     current_grafport+2
        sec
        sbc     current_grafport+10
        sta     y_offset
        lda     current_grafport+3
        sbc     current_grafport+11
        sta     y_offset+1
        rts

clip_rect:
        lda     current_grafport+13
        cmp     left+1
        bmi     @L50A7
        bne     @L50A9
        lda     current_grafport+12
        cmp     left
        bcs     @L50A9
@L50A7: clc
@L50A8: rts

@L50A9: lda     right+1
        cmp     current_grafport+9
        bmi     @L50A7
        bne     @L50B7
        lda     right
        cmp     current_grafport+8
        bcc     @L50A8
@L50B7: lda     current_grafport+15
        cmp     top+1
        bmi     @L50A7
        bne     @L50C5
        lda     current_grafport+14
        cmp     top
        bcc     @L50A8
@L50C5: lda     bottom+1
        cmp     current_grafport+11
        bmi     @L50A7
        bne     @L50D3
        lda     bottom
        cmp     current_grafport+10
        bcc     @L50A8
@L50D3: ldy     #$00
        lda     left
        sec
        sbc     current_grafport+8
        tax
        lda     left+1
        sbc     current_grafport+9
        bpl     @L50EE
        stx     $9b
        sta     $9c
        lda     current_grafport+8
        sta     left
        lda     current_grafport+9
        sta     left+1
        iny
@L50EE: lda     current_grafport+12
        sec
        sbc     right
        tax
        lda     current_grafport+13
        sbc     right+1
        bpl     @L5106
        lda     current_grafport+12
        sta     right
        lda     current_grafport+13
        sta     right+1
        tya
        ora     #$04
        tay
@L5106: lda     top
        sec
        sbc     current_grafport+10
        tax
        lda     top+1
        sbc     current_grafport+11
        bpl     @L5120
        stx     $9d
        sta     $9e
        lda     current_grafport+10
        sta     top
        lda     current_grafport+11
        sta     top+1
        iny
        iny
@L5120: lda     current_grafport+14
        sec
        sbc     bottom
        tax
        lda     current_grafport+15
        sbc     bottom+1
        bpl     @L5138
        lda     current_grafport+14
        sta     bottom
        lda     current_grafport+15
        sta     bottom+1
        tya
        ora     #$08
        tay
@L5138: sty     $9a
        sec
        rts

L513C:  sec
        lda     right
        sbc     left
        lda     right+1
        sbc     left+1
        bmi     @L5153
        sec
        lda     bottom
        sbc     top
        lda     bottom+1
        sbc     top+1
        bmi     @L5153
        rts

@L5153: lda     #$83
        jmp     exit_with_a

src_width_bytes:
        .byte   $00
unused_width:
        .byte   $00

; 
; PaintBits
; 
PaintBitsImpl:
        ldx     #$03
@L515C: lda     $8a,x
        sta     $9b,x
        lda     left,x
        sta     $8a,x
        dex
        bpl     @L515C
        lda     right
        sec
        sbc     left
        sta     src_addr
        lda     right+1
        sbc     left+1
        sta     src_addr+1
        lda     $9b
        sta     left
        clc
        adc     src_addr
        sta     right
        lda     $9c
        sta     left+1
        adc     src_addr+1
        sta     right+1
        lda     bottom
        sec
        sbc     top
        sta     src_addr
        lda     bottom+1
        sbc     top+1
        sta     src_addr+1
        lda     $9d
        sta     top
        clc
        adc     src_addr
        sta     bottom
        lda     $9e
        sta     top+1
        adc     src_addr+1
        sta     bottom+1
; 
; BitBlt
; 
BitBltImpl:
        lda     #$00
        sta     $9b
        sta     $9c
        sta     $9d
        lda     bits_addr+1
        sta     params_addr
        jsr     clip_rect
        bcs     @L51B5
        rts

@L51B5: jsr     set_up_fill_mode
        lda     width_bytes
        asl     a
        ldx     left+1
        beq     @L51C1
        adc     #$01
@L51C1: ldx     right
        beq     @L51C7
        adc     #$01
@L51C7: sta     unused_width
        sta     src_width_bytes
        lda     #$02
        sta     params_addr+1
        lda     #$00
        sec
        sbc     $9d
        clc
        adc     src_y_coord
        sta     src_y_coord
        lda     #$00
        sec
        sbc     $9b
        tax
        lda     #$00
        sbc     $9c
        tay
        txa
        clc
        adc     $8a
        tax
        tya
        adc     $8b
        jsr     divmod7
        sta     $8a
        tya
        rol     a
        cmp     #$07
        ldx     #$01
        bcc     @L51FE
        dex
        sbc     #$07
@L51FE: stx     L4C7B+1
        inx
        stx     L4C82+1
        sta     $9b
        lda     $8a
        rol     a
        jsr     set_source
        jsr     set_dest
        lda     #$01
        sta     bits_addr
        lda     #$06
        sta     bits_addr+1
        ldx     #$01
        lda     left_mod14
        sec
        sbc     #$07
        bcc     @L5224
        sta     left_mod14
        dex
@L5224: stx     L4CB9+1
        inx
        stx     L4CC5+1
        lda     left_mod14
        sec
        sbc     $9b
        bcs     @L5239
        adc     #$07
        inc     src_width_bytes
        dec     params_addr+1
@L5239: tay
        bne     @L5240
        ldx     #$00
        beq     @L5266

@L5240: tya
        asl     a
        tay
        lda     shift_table_main,y
        sta     L4C9F+1
        lda     shift_table_main+1,y
        sta     L4C9F+2
        lda     shift_table_aux,y
        sta     L4CA5+1
        lda     shift_table_aux+1,y
        sta     L4CA5+2
        ldy     params_addr+1
        sty     L4CA2+1
        dey
        sty     L4CAB+1
        ldx     #$02
@L5266: lda     shift_bits_table,x
        sta     L4C92+1
        lda     shift_bits_table+1,x
        sta     L4C92+2
        jmp     bit_blit

shift_bits_table:
        .word   shift_line_jmp
shift_table_aux:
        .word   dhgr_shift_bits
        .word   shift_1_aux
        .word   shift_2_aux
        .word   shift_3_aux
        .word   shift_4_aux
        .word   shift_5_aux
shift_table_main:
        .word   shift_6_aux
        .word   shift_1_main
        .word   shift_2_main
        .word   shift_3_main
        .word   shift_4_main
        .word   shift_5_main
        .word   shift_6_main

load_poly:
        stx     $b0
        asl     a
        asl     a
        sta     $b3
        ldy     #$03
@L5299: lda     (params_addr),y
        sta     $0092,y
        sta     $0096,y
        dey
        bpl     @L5299
        lda     top
        sta     $a7
        lda     top+1
        sta     $a8
        ldy     #$00
        stx     $ae
@L52B0: stx     src_addr
        lda     (params_addr),y
        sta     $0700,x
        pha
        iny
        lda     (params_addr),y
        sta     $073c,x
        tax
        pla
        iny
        cpx     left+1
        bmi     @L52CB
        bne     @L52D1
        cmp     left
        bcs     @L52D1
@L52CB: sta     left
        stx     left+1
        bcc     @L52DF
@L52D1: cpx     right+1
        bmi     @L52DF
        bne     @L52DB
        cmp     right
        bcc     @L52DF
@L52DB: sta     right
        stx     right+1
@L52DF: ldx     src_addr
        lda     (params_addr),y
        sta     $0780,x
        pha
        iny
        lda     (params_addr),y
        sta     $07bc,x
        tax
        pla
        iny
        cpx     top+1
        bmi     @L52FA
        bne     @L5300
        cmp     top
        bcs     @L5300
@L52FA: sta     top
        stx     top+1
        bcc     @L530E
@L5300: cpx     bottom+1
        bmi     @L530E
        bne     @L530A
        cmp     bottom
        bcc     @L530E
@L530A: sta     bottom
        stx     bottom+1
@L530E: cpx     $a8
        stx     $a8
        bmi     @L5320
        bne     @L531C
        cmp     $a7
        bcc     @L5320
        beq     @L5320
@L531C: ldx     src_addr
        stx     $ae
@L5320: sta     $a7
        ldx     src_addr
        inx
        cpx     #$3c
        beq     L5387
        cpy     $b3
        bcc     @L52B0
        lda     top
        cmp     bottom
        bne     @L5339
        lda     top+1
        cmp     bottom+1
        beq     L5387
@L5339: stx     $b3
        bit     $ba
        bpl     @L5340
        nop
@L5340: jmp     clip_rect

next_poly:
        lda     $b4
        bpl     L5368
        asl     a
        asl     a
        adc     params_addr
        sta     params_addr
        bcc     L5351
        inc     params_addr+1
L5351:  ldy     #$00
        lda     (params_addr),y
        iny
        ora     (params_addr),y
        sta     $b4
        inc     params_addr
        bne     @L5360
        inc     params_addr+1
@L5360: inc     params_addr
        bne     @L5366
        inc     params_addr+1
@L5366: ldy     #$80
L5368:  rts

; 
; InPoly
; 
InPolyImpl:
        lda     #$80
        bne     L536F

; 
; PaintPoly
; 
PaintPolyImpl:
        lda     #$00
L536F:  sta     $ba
        ldx     #$00
        stx     $ad
        jsr     L5351
L5378:  jsr     load_poly
        bcs     L538C
        ldx     $b0
L537F:  jsr     next_poly
        bmi     L5378
        jmp     L545E

L5387:  lda     #$81
        jmp     exit_with_a

L538C:  ldy     #$01
        sty     $af
        ldy     $ae
        cpy     $b0
        bne     @L5398
        ldy     $b3
@L5398: dey
        sty     $ab
        php
@L539C: sty     $ac
        iny
        cpy     $b3
        bne     @L53A5
        ldy     $b0
@L53A5: sty     $aa
        cpy     $ae
        bne     @L53AD
        dec     $af
@L53AD: lda     $0780,y
        ldx     $07bc,y
        stx     src_addr+1
@L53B5: sty     $a9
        iny
        cpy     $b3
        bne     @L53BE
        ldy     $b0
@L53BE: cmp     $0780,y
        bne     @L53CA
        ldx     $07bc,y
        cpx     src_addr+1
        beq     @L53B5
@L53CA: ldx     $ab
        sec
        sbc     $0780,x
        lda     src_addr+1
        sbc     $07bc,x
        bmi     @L5437
        lda     $a9
        plp
        bmi     @L53E7
        tay
        sta     $0680,x
        lda     $aa
        sta     $06bc,x
        bpl     @L544C
@L53E7: ldx     $ad
        cpx     #$10
        bcs     L5387
        sta     $0468,x
        lda     $aa
        sta     $04a8,x
        ldy     $ab
        lda     $0680,y
        sta     $0469,x
        lda     $06bc,y
        sta     $04a9,x
        lda     $0780,y
        sta     $05e8,x
        sta     $05e9,x
        lda     $07bc,y
        sta     poly_maxima_yh_table,x
        sta     poly_maxima_yh_table+1,x
        lda     $0700,y
        sta     poly_maxima_xl_table+1,x
        lda     $073c,y
        sta     poly_maxima_xh_table+1,x
        ldy     $ac
        lda     $0700,y
        sta     poly_maxima_xl_table,x
        lda     $073c,y
        sta     poly_maxima_xh_table,x
        inx
        inx
        stx     $ad
        ldy     $a9
        bpl     @L544C
@L5437: plp
        bmi     @L543F
        lda     #$80
        sta     $0680,x
@L543F: ldy     $aa
        txa
        sta     $0680,y
        lda     $ac
        sta     $06bc,y
        lda     #$80
@L544C: php
        sty     $ab
        ldy     $a9
        bit     $af
        bmi     @L5458
        jmp     @L539C

@L5458: plp
        ldx     $b3
        jmp     L537F

L545E:  ldx     #$00
        stx     $b1
        lda     #$80
        sta     $0428
        sta     $b2
@L5469: inx
        cpx     $ad
        bcc     @L5471
        beq     @L54A1
        rts

@L5471: lda     $b1
@L5473: tay
        lda     $05e8,x
        cmp     $05e8,y
        bcs     @L5491
        tya
        sta     $0428,x
        cpy     $b1
        beq     @L548D
        ldy     src_addr
        txa
        sta     $0428,y
        jmp     @L5469

@L548D: stx     $b1
        bcs     @L5469
@L5491: sty     src_addr
        lda     $0428,y
        bpl     @L5473
        sta     $0428,x
        txa
        sta     $0428,y
        bpl     @L5469
@L54A1: ldx     $b1
        lda     $05e8,x
        sta     $a9
        sta     top
        lda     poly_maxima_yh_table,x
        sta     $aa
        sta     top+1
@L54B1: ldx     $b1
        bmi     @L5523
@L54B5: lda     $05e8,x
        cmp     $a9
        bne     @L5521
        lda     poly_maxima_yh_table,x
        cmp     $aa
        bne     @L5521
        lda     $0428,x
        sta     src_addr
        jsr     @L55F5
        lda     $b2
        bmi     @L5506
@L54CF: tay
        lda     poly_maxima_xh_table,x
        cmp     poly_maxima_xh_table,y
        bmi     @L550F
        bne     @L54F6
        lda     poly_maxima_xl_table,x
        cmp     poly_maxima_xl_table,y
        bcc     @L550F
        bne     @L54F6
        lda     poly_maxima_x_frach,x
        cmp     poly_maxima_x_frach,y
        bcc     @L550F
        bne     @L54F6
        lda     poly_maxima_x_fracl,x
        cmp     poly_maxima_x_fracl,y
        bcc     @L550F
@L54F6: sty     src_addr+1
        lda     $0428,y
        bpl     @L54CF
        sta     $0428,x
        txa
        sta     $0428,y
        bpl     @L551D
@L5506: sta     $0428,x
        stx     $b2
        jmp     @L551D

@L550E: rts

@L550F: tya
        cpy     $b2
        beq     @L5506
        sta     $0428,x
        txa
        ldy     src_addr+1
        sta     $0428,y
@L551D: ldx     src_addr
        bpl     @L54B5
@L5521: stx     $b1
@L5523: lda     #$00
        sta     $ab
        lda     $b2
        sta     src_addr+1
        bmi     @L550E
@L552D: tax
        lda     $a9
        cmp     $05e8,x
        bne     @L5573
        lda     $aa
        cmp     poly_maxima_yh_table,x
        bne     @L5573
        ldy     $0468,x
        lda     $0680,y
        bpl     @L555B
        cpx     $b2
        beq     @L5553
        ldy     src_addr+1
        lda     $0428,x
        sta     $0428,y
        jmp     @L55E7

@L5553: lda     $0428,x
        sta     $b2
        jmp     @L55E7

@L555B: sta     $0468,x
        lda     $0700,y
        sta     poly_maxima_xl_table,x
        lda     $073c,y
        sta     poly_maxima_xh_table,x
        lda     $06bc,y
        sta     $04a8,x
        jsr     @L55F5
@L5573: stx     $ac
        ldy     poly_maxima_xh_table,x
        lda     poly_maxima_xl_table,x
        tax
        lda     $ab
        eor     #$ff
        sta     $ab
        bpl     @L558A
        stx     left
        sty     left+1
        bmi     @L55BD

@L558A: stx     right
        sty     right+1
        cpy     left+1
        bmi     @L5598
        bne     @L55A4
        cpx     left
        bcs     @L55A4
@L5598: lda     left
        stx     left
        sta     right
        lda     left+1
        sty     left+1
        sta     right+1
@L55A4: lda     $a9
        sta     top
        sta     bottom
        lda     $aa
        sta     top+1
        sta     bottom+1
        bit     $ba
        bpl     @L55BA
        jsr     InRectImpl
        jmp     @L55BD

@L55BA: jsr     L5033
@L55BD: ldx     $ac
        lda     poly_maxima_x_fracl,x
        clc
        adc     $0528,x
        sta     poly_maxima_x_fracl,x
        lda     poly_maxima_x_frach,x
        adc     $04e8,x
        sta     poly_maxima_x_frach,x
        lda     poly_maxima_xl_table,x
        adc     $0568,x
        sta     poly_maxima_xl_table,x
        lda     poly_maxima_xh_table,x
        adc     $05a8,x
        sta     poly_maxima_xh_table,x
        lda     $0428,x
@L55E7: bmi     @L55EC
        jmp     @L552D

@L55EC: inc     $a9
        bne     @L55F2
        inc     $aa
@L55F2: jmp     @L54B1

@L55F5: ldy     $04a8,x
        lda     $0780,y
        sta     $05e8,x
        sec
        sbc     $a9
        sta     $a3
        lda     $07bc,y
        sta     poly_maxima_yh_table,x
        sbc     $aa
        sta     $a4
        lda     $0700,y
        sec
        sbc     poly_maxima_xl_table,x
        sta     $a1
        lda     $073c,y
        sbc     poly_maxima_xh_table,x
        sta     $a2
        php
        bpl     @L562E
        lda     #$00
        sec
        sbc     $a1
        sta     $a1
        lda     #$00
        sbc     $a2
        sta     $a2
@L562E: stx     vid_addr
        jsr     L5689
        ldx     vid_addr
        plp
        bpl     @L5651
        lda     #$00
        sec
        sbc     $9f
        sta     $9f
        lda     #$00
        sbc     $a0
        sta     $a0
        lda     #$00
        sbc     $a1
        sta     $a1
        lda     #$00
        sbc     $a2
        sta     $a2
@L5651: lda     $a2
        sta     $05a8,x
        cmp     #$80
        ror     a
        pha
        lda     $a1
        sta     $0568,x
        ror     a
        pha
        lda     $a0
        sta     $04e8,x
        ror     a
        pha
        lda     $9f
        sta     $0528,x
        ror     a
        sta     poly_maxima_x_fracl,x
        pla
        clc
        adc     #$80
        sta     poly_maxima_x_frach,x
        pla
        adc     poly_maxima_xl_table,x
        sta     poly_maxima_xl_table,x
        pla
        adc     poly_maxima_xh_table,x
        sta     poly_maxima_xh_table,x
        rts

L5687:  lda     $a2
L5689:  ora     $a1
        bne     @L5697
        sta     $9f
        sta     $a0
        sta     $a1
        sta     $a2
        beq     @L56C4

@L5697: ldy     #$20
        lda     #$00
        sta     $9f
        sta     $a0
        sta     $a5
        sta     $a6
@L56A3: asl     $9f
        rol     $a0
        rol     $a1
        rol     $a2
        rol     $a5
        rol     $a6
        lda     $a5
        sec
        sbc     $a3
        tax
        lda     $a6
        sbc     $a4
        bcc     @L56C1
        stx     $a5
        sta     $a6
        inc     $9f
@L56C1: dey
        bne     @L56A3
@L56C4: rts

; 
; Frame Poly
; 
FramePolyImpl:
        lda     #$00
        sta     $ba
        jsr     L5351
@L56CC: lda     params_addr
        sta     $b7
        lda     params_addr+1
        sta     $b8
        lda     $b4
        sta     $b6
        ldx     #$00
        jsr     load_poly
        bcc     @L571E
        lda     $b3
        sta     $b5
        ldy     #$00
@L56E5: dec     $b5
        beq     @L5702
        sty     $b9
        ldx     #$00
@L56ED: lda     ($b7),y
        sta     left,x
        iny
        inx
        cpx     #$08
        bne     @L56ED
        jsr     L5772
        lda     $b9
        clc
        adc     #$04
        tay
        bne     @L56E5
@L5702: ldx     #$00
@L5704: lda     ($b7),y
        sta     left,x
        iny
        inx
        cpx     #$04
        bne     @L5704
        ldy     #$03
@L5710: lda     ($b7),y
        sta     $0096,y
        sta     current_penloc_x,y
        dey
        bpl     @L5710
        jsr     L5772
@L571E: ldx     #$01
@L5720: lda     $b7,x
        sta     params_addr,x
        lda     $b5,x
        sta     $b3,x
        dex
        bpl     @L5720
        jsr     next_poly
        bmi     @L56CC
        rts

; 
; Move
; 
MoveImpl:
        lda     $a1
        ldx     $a2
        jsr     adjust_xpos
        lda     $a3
        ldx     $a4
        clc
        adc     current_penloc_y
        sta     current_penloc_y
        txa
        adc     current_penloc_y+1
        sta     current_penloc_y+1
        rts

adjust_xpos:
        clc
        adc     current_penloc_x
        sta     current_penloc_x
        txa
        adc     current_penloc_x+1
        sta     current_penloc_x+1
        rts

; 
; Line
; 
LineImpl:
        ldx     #$02
@L5754: lda     $a1,x
        clc
        adc     current_penloc_x,x
        sta     left,x
        lda     $a2,x
        adc     current_penloc_x+1,x
        sta     left+1,x
        dex
        dex
        bpl     @L5754
; 
; LineTo
; 
LineToImpl:
        ldx     #$03
@L5767: lda     current_penloc_x,x
        sta     right,x
        lda     left,x
        sta     current_penloc_x,x
        dex
        bpl     @L5767
L5772:  lda     bottom+1
        cmp     top+1
        bmi     @L579F
        bne     @L57AE
        lda     bottom
        cmp     top
        bcc     @L579F
        bne     @L57AE
        lda     left
        ldx     left+1
        cpx     right+1
        bmi     @L579C
        bne     @L5790
        cmp     right
        bcc     @L579C
@L5790: ldy     right
        sta     right
        sty     left
        ldy     right+1
        stx     right+1
        sty     left+1
@L579C: jmp     draw_line

@L579F: ldx     #$03
@L57A1: lda     left,x
        tay
        lda     right,x
        sta     left,x
        tya
        sta     right,x
        dex
        bpl     @L57A1
@L57AE: ldx     current_penwidth
        dex
        stx     $a2
        lda     current_penheight
        sta     $a4
        lda     #$00
        sta     $a1
        sta     $a3
        lda     left
        ldx     left+1
        cpx     right+1
        bmi     @L57D8
        bne     @L57D0
        cmp     right
        bcc     @L57D8
        bne     @L57D0
        jmp     draw_line

@L57D0: lda     $a1
        ldx     $a2
        sta     $a2
        stx     $a1
@L57D8: ldy     #$05
@L57DA: sty     src_addr
        ldx     pt_offsets,y
        ldy     #$03
@L57E1: lda     left,x
        sta     $0083,y
        dex
        dey
        bpl     @L57E1
        ldy     src_addr
        ldx     penwidth_flags,y
        lda     $a1,x
        clc
        adc     src_addr+1
        sta     src_addr+1
        bcc     @L57FA
        inc     vid_addr
@L57FA: ldx     penheight_flags,y
        lda     $a3,x
        clc
        adc     vid_addr+1
        sta     vid_addr+1
        bcc     @L5808
        inc     left_bytes
@L5808: tya
        asl     a
        asl     a
        tay
        ldx     #$00
@L580E: lda     src_addr+1,x
        sta     paint_poly_points,y
        iny
        inx
        cpx     #$04
        bne     @L580E
        ldy     src_addr
        dey
        bpl     @L57DA
        lda     paint_poly_params_addr
        sta     params_addr
        lda     paint_poly_params_addr+1
        sta     params_addr+1
        jmp     PaintPolyImpl

paint_poly_params_addr:
        .word   paint_poly_params
pt_offsets:
        .byte   $03,$03,$07,$07,$07,$03
penwidth_flags:
        .byte   $00,$00,$00,$01,$01,$01
penheight_flags:
        .byte   $00,$01,$01,$01,$00,$00
paint_poly_params:
        .byte   $06
        .byte   $00
paint_poly_points:
        .res    24,$00

; 
; SetFont
; 
SetFontImpl:
        lda     params_addr
        sta     current_textfont
        lda     params_addr+1
        sta     current_textfont+1
L5861:  ldy     #$00
@L5863: lda     (current_textfont),y
        sta     glyph_type,y
        iny
        cpy     #$03
        bne     @L5863
        cmp     #$11
        bcs     @L58A6
        lda     current_textfont
        ldx     current_textfont+1
        clc
        adc     #$03
        bcc     @L587B
        inx
@L587B: sta     glyph_widths
        stx     glyph_widths+1
        sec
        adc     glyph_last
        bcc     @L5885
        inx
@L5885: ldy     #$00
@L5887: sta     glyph_row_lo,y
        pha
        txa
        sta     glyph_row_hi,y
        pla
        sec
        adc     glyph_last
        bcc     @L5896
        inx
@L5896: bit     glyph_type
        bpl     @L58A0
        sec
        adc     glyph_last
        bcc     @L58A0
        inx
@L58A0: iny
        cpy     glyph_height_p
        bne     @L5887
        rts

@L58A6: lda     #$82
        jmp     exit_with_a

glyph_row_lo:
        .res    16,$00
glyph_row_hi:
        .res    16,$00

; 
; TextWidth
; 
TextWidthImpl:
        jsr     measure_text
        ldy     #$03
        sta     (params_addr),y
        txa
        iny
        sta     (params_addr),y
        rts

measure_text:
        ldx     #$00
        ldy     #$00
        sty     src_addr
@L58DD: sty     src_addr+1
        lda     ($a1),y
        tay
        txa
        clc
        adc     (glyph_widths),y
        bcc     @L58EA
        inc     src_addr
@L58EA: tax
        ldy     src_addr+1
        iny
        cpy     $a3
        bne     @L58DD
        txa
        ldx     src_addr
        rts

penloc_to_bounds:
        sec
        sbc     #$01
        bcs     @L58FC
        dex
@L58FC: clc
        adc     current_penloc_x
        sta     right
        txa
        adc     current_penloc_x+1
        sta     right+1
        lda     current_penloc_x
        sta     left
        lda     current_penloc_x+1
        sta     left+1
        lda     current_penloc_y
        sta     bottom
        ldx     current_penloc_y+1
        stx     bottom+1
        clc
        adc     #$01
        bcc     @L591C
        inx
@L591C: sec
        sbc     glyph_height_p
        bcs     @L5922
        dex
@L5922: sta     top
        stx     top+1
        rts

; 
; DrawText
; 
DrawTextImpl:
        jsr     L5EEC
        jsr     measure_text
        sta     $a4
        stx     $a5
        ldy     #$00
        sty     $9f
        sty     $a0
        sty     $9b
        sty     $9d
        jsr     penloc_to_bounds
        jsr     clip_rect
        bcc     @L59A8
        tya
        ror     a
        bcc     @L5961
        ldy     #$00
        ldx     $9c
@L594B: sty     $9f
        lda     ($a1),y
        tay
        lda     (glyph_widths),y
        clc
        adc     $9b
        bcc     @L595A
        inx
        beq     @L5961
@L595A: sta     $9b
        ldy     $9f
        iny
        bne     @L594B
@L5961: jsr     set_up_fill_mode
        jsr     set_dest
        lda     left_mod14
        clc
        adc     $9b
        bpl     @L5974
        inc     width_bytes
        dec     $a0
        adc     #$0e
@L5974: sta     left_mod14
        lda     width_bytes
        inc     width_bytes
        ldy     current_grafport+6
        bpl     @L598E
        asl     a
        tax
        lda     left_mod14
        cmp     #$07
        bcs     @L5987
        inx
@L5987: lda     right
        beq     @L598C
        inx
@L598C: stx     width_bytes
@L598E: lda     left_mod14
        sec
        sbc     #$07
        bcc     @L5997
        sta     left_mod14
@L5997: lda     #$00
        rol     a
        eor     #$01
        sta     $9c
        tax
        sta     TXTPAGE1,x
        jsr     @L59B2
        sta     TXTPAGE1
@L59A8: jsr     L5EDC
        lda     $a4
        ldx     $a5
        jmp     adjust_xpos

@L59B2: lda     bottom
        sec
        sbc     top
        asl     a
        tax
        lda     shifted_draw_line_table,x
        sta     L5AF0+1
        lda     shifted_draw_line_table+1,x
        sta     L5AF0+2
        lda     unshifted_draw_line_table,x
        sta     L5A83+1
        lda     unshifted_draw_line_table+1,x
        sta     L5A83+2
        lda     unmasked_blit_line_table,x
        sta     L5C10+1
        lda     unmasked_blit_line_table+1,x
        sta     L5C10+2
        lda     masked_blit_line_table,x
        sta     L5CAC+1
        lda     masked_blit_line_table+1,x
        sta     L5CAC+2
        txa
        lsr     a
        tax
        sec
        stx     params_addr
        stx     params_addr+1
        lda     #$00
        sbc     $9d
        sta     $9d
        tay
        ldx     #$c3
        sec
@L59FB: lda     glyph_row_lo,y
        sta     shifted_draw_linemax+1,x
        lda     glyph_row_hi,y
        sta     shifted_draw_linemax+2,x
        txa
        sbc     #$0d
        tax
        iny
        dec     params_addr
        bpl     @L59FB
        ldy     $9d
        ldx     #$4b
        sec
@L5A15: lda     glyph_row_lo,y
        sta     unshifted_draw_linemax+1,x
        lda     glyph_row_hi,y
        sta     unshifted_draw_linemax+2,x
        txa
        sbc     #$05
        tax
        iny
        dec     params_addr+1
        bpl     @L5A15
        ldy     top
        ldx     #$00
@L5A2E: bit     current_grafport+6
        bmi     @L5A45
        lda     vid_addr
        clc
        adc     current_grafport+6
        sta     vid_addr
        sta     MON_WNDLEFT,x
        lda     vid_addr+1
        adc     #$00
        sta     vid_addr+1
        sta     MON_WNDWDTH,x
        bne     @L5A54
@L5A45: lda     hires_table_lo,y
        clc
        adc     left_bytes
        sta     MON_WNDLEFT,x
        lda     hires_table_hi,y
        ora     current_grafport+5
        sta     MON_WNDWDTH,x
@L5A54: cpy     bottom
        beq     @L5A5D
        iny
        inx
        inx
        bne     @L5A2E
@L5A5D: ldx     #$0f
        lda     #$00
@L5A61: sta     $00,x
        dex
        bpl     @L5A61
        sta     params_addr+1
        sta     MON_A3L
        lda     #$80
        sta     MON_A4L
        ldy     $9f
L5A70:  lda     ($a1),y
        tay
        bit     params_addr+1
        bpl     @L5A7A
        sec
        adc     glyph_last
@L5A7A: tax
        lda     (glyph_widths),y
        beq     zero_width_glyph
        ldy     left_mod14
        bne     shifted_draw
L5A83:  jmp     unshifted_draw_linemax

; unrolled loop
unshifted_draw_linemax:
        lda     $ffff,x
        sta     $0f
unshifted_draw_line_15:
        lda     $ffff,x
        sta     $0e
unshifted_draw_line_14:
        lda     $ffff,x
        sta     $0d
unshifted_draw_line_13:
        lda     $ffff,x
        sta     $0c
unshifted_draw_line_12:
        lda     $ffff,x
        sta     $0b
unshifted_draw_line_11:
        lda     $ffff,x
        sta     $0a
unshifted_draw_line_10:
        lda     $ffff,x
        sta     $09
unshifted_draw_line_9:
        lda     $ffff,x
        sta     $08
unshifted_draw_line_8:
        lda     $ffff,x
        sta     $07
unshifted_draw_line_7:
        lda     $ffff,x
        sta     $06
unshifted_draw_line_6:
        lda     $ffff,x
        sta     $05
unshifted_draw_line_5:
        lda     $ffff,x
        sta     $04
unshifted_draw_line_4:
        lda     $ffff,x
        sta     $03
unshifted_draw_line_3:
        lda     $ffff,x
        sta     $02
unshifted_draw_line_2:
        lda     $ffff,x
        sta     $01
unshifted_draw_line_1:
        lda     $ffff,x
        sta     $00
zero_width_glyph:
        jmp     do_blit

shifted_draw:
        tya
        asl     a
        tay
        lda     shift_table_aux,y
        sta     MON_A3L
        lda     shift_table_aux+1,y
        sta     MON_A3H
        lda     shift_table_main,y
        sta     MON_A4L
        lda     shift_table_main+1,y
        sta     MON_A4H
L5AF0:  jmp     shifted_draw_linemax

shifted_draw_linemax:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $1f
        lda     (MON_A3L),y
        ora     $0f
        sta     $0f
shifted_draw_line_15:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $1e
        lda     (MON_A3L),y
        ora     $0e
        sta     $0e
shifted_draw_line_14:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $1d
        lda     (MON_A3L),y
        ora     $0d
        sta     $0d
shifted_draw_line_13:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $1c
        lda     (MON_A3L),y
        ora     $0c
        sta     $0c
shifted_draw_line_12:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $1b
        lda     (MON_A3L),y
        ora     $0b
        sta     $0b
shifted_draw_line_11:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $1a
        lda     (MON_A3L),y
        ora     $0a
        sta     $0a
shifted_draw_line_10:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $19
        lda     (MON_A3L),y
        ora     $09
        sta     $09
shifted_draw_line_9:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $18
        lda     (MON_A3L),y
        ora     $08
        sta     $08
shifted_draw_line_8:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $17
        lda     (MON_A3L),y
        ora     $07
        sta     $07
shifted_draw_line_7:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $16
        lda     (MON_A3L),y
        ora     $06
        sta     $06
shifted_draw_line_6:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $15
        lda     (MON_A3L),y
        ora     $05
        sta     $05
shifted_draw_line_5:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $14
        lda     (MON_A3L),y
        ora     $04
        sta     $04
shifted_draw_line_4:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $13
        lda     (MON_A3L),y
        ora     $03
        sta     $03
shifted_draw_line_3:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $12
        lda     (MON_A3L),y
        ora     $02
        sta     $02
shifted_draw_line_2:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $11
        lda     (MON_A3L),y
        ora     $01
        sta     $01
shifted_draw_line_1:
        ldy     $ffff,x
        lda     (MON_A4L),y
        sta     $10
        lda     (MON_A3L),y
        ora     $00
        sta     $00
do_blit:
        bit     params_addr+1
        bpl     @L5BD1
        inc     $9f
        lda     #$00
        sta     params_addr+1
        lda     $9a
        bne     @L5BE5
@L5BD1: txa
        tay
        lda     (glyph_widths),y
        cmp     #$08
        bcs     @L5BDD
        inc     $9f
        bcc     @L5BE5

@L5BDD: sbc     #$07
        sta     $9a
        ror     params_addr+1
        lda     #$07
@L5BE5: clc
        adc     left_mod14
        cmp     #$07
        bcs     L5BFC
        sta     left_mod14
L5BEE:  ldy     $9f
        cpy     $a3
        beq     @L5BF7
        jmp     L5A70

@L5BF7: ldy     $a0
        jmp     L5CA4

L5BFC:  sbc     #$07
        sta     left_mod14
        ldy     $a0
        bne     @L5C07
        jmp     L5C91

@L5C07: bmi     next_byte
        dec     width_bytes
        bne     L5C10
        jmp     L5CA4

L5C10:  jmp     unmasked_blit_linemax

unmasked_blit_linemax:
        lda     $0f
        eor     current_textback
        sta     (MON_A2L),y
unmasked_blit_line_15:
        lda     $0e
        eor     current_textback
        sta     (MON_A1L),y
unmasked_blit_line_14:
        lda     $0d
        eor     current_textback
        sta     (MON_PCL),y
unmasked_blit_line_13:
        lda     $0c
        eor     current_textback
        sta     (MON_KSWL),y
unmasked_blit_line_12:
        lda     $0b
        eor     current_textback
        sta     (MON_CSWL),y
unmasked_blit_line_11:
        lda     $0a
        eor     current_textback
        sta     ($34),y
unmasked_blit_line_10:
        lda     $09
        eor     current_textback
        sta     (MON_INVFLAG),y
unmasked_blit_line_9:
        lda     $08
        eor     current_textback
        sta     (MON_COLOR),y
unmasked_blit_line_8:
        lda     $07
        eor     current_textback
        sta     ($2e),y
unmasked_blit_line_7:
        lda     $06
        eor     current_textback
        sta     (MON_H2),y
unmasked_blit_line_6:
        lda     $05
        eor     current_textback
        sta     ($2a),y
unmasked_blit_line_5:
        lda     $04
        eor     current_textback
        sta     (MON_BASL),y
unmasked_blit_line_4:
        lda     $03
        eor     current_textback
        sta     (MON_GBASL),y
unmasked_blit_line_3:
        lda     $02
        eor     current_textback
        sta     (MON_CH),y
unmasked_blit_line_2:
        lda     $01
        eor     current_textback
        sta     (MON_WNDTOP),y
unmasked_blit_line_1:
        lda     $00
        eor     current_textback
        sta     (MON_WNDLEFT),y
next_byte:
        bit     current_grafport+6
        bpl     @L5C83
        lda     $9c
        eor     #$01
        tax
        sta     $9c
        sta     TXTPAGE1,x
        beq     @L5C85
@L5C83: inc     $a0
@L5C85: ldx     #$0f
@L5C87: lda     $10,x
        sta     $00,x
        dex
        bpl     @L5C87
        jmp     L5BEE

L5C91:  ldx     $9c
        lda     left,x
        dec     width_bytes
        beq     @L5C9F
        jsr     L5CA8
        jmp     next_byte

@L5C9F: and     right,x
        bne     L5CA8
        rts

L5CA4:  ldx     $9c
        lda     right,x
L5CA8:  ora     #$80
        sta     params_addr
L5CAC:  jmp     masked_blit_linemax

masked_blit_linemax:
        lda     $0f
        eor     current_textback
        eor     (MON_A2L),y
        and     params_addr
        eor     (MON_A2L),y
        sta     (MON_A2L),y
masked_blit_line_15:
        lda     $0e
        eor     current_textback
        eor     (MON_A1L),y
        and     params_addr
        eor     (MON_A1L),y
        sta     (MON_A1L),y
masked_blit_line_14:
        lda     $0d
        eor     current_textback
        eor     (MON_PCL),y
        and     params_addr
        eor     (MON_PCL),y
        sta     (MON_PCL),y
masked_blit_line_13:
        lda     $0c
        eor     current_textback
        eor     (MON_KSWL),y
        and     params_addr
        eor     (MON_KSWL),y
        sta     (MON_KSWL),y
masked_blit_line_12:
        lda     $0b
        eor     current_textback
        eor     (MON_CSWL),y
        and     params_addr
        eor     (MON_CSWL),y
        sta     (MON_CSWL),y
masked_blit_line_11:
        lda     $0a
        eor     current_textback
        eor     ($34),y
        and     params_addr
        eor     ($34),y
        sta     ($34),y
masked_blit_line_10:
        lda     $09
        eor     current_textback
        eor     (MON_INVFLAG),y
        and     params_addr
        eor     (MON_INVFLAG),y
        sta     (MON_INVFLAG),y
masked_blit_line_9:
        lda     $08
        eor     current_textback
        eor     (MON_COLOR),y
        and     params_addr
        eor     (MON_COLOR),y
        sta     (MON_COLOR),y
masked_blit_line_8:
        lda     $07
        eor     current_textback
        eor     ($2e),y
        and     params_addr
        eor     ($2e),y
        sta     ($2e),y
masked_blit_line_7:
        lda     $06
        eor     current_textback
        eor     (MON_H2),y
        and     params_addr
        eor     (MON_H2),y
        sta     (MON_H2),y
masked_blit_line_6:
        lda     $05
        eor     current_textback
        eor     ($2a),y
        and     params_addr
        eor     ($2a),y
        sta     ($2a),y
masked_blit_line_5:
        lda     $04
        eor     current_textback
        eor     (MON_BASL),y
        and     params_addr
        eor     (MON_BASL),y
        sta     (MON_BASL),y
masked_blit_line_4:
        lda     $03
        eor     current_textback
        eor     (MON_GBASL),y
        and     params_addr
        eor     (MON_GBASL),y
        sta     (MON_GBASL),y
masked_blit_line_3:
        lda     $02
        eor     current_textback
        eor     (MON_CH),y
        and     params_addr
        eor     (MON_CH),y
        sta     (MON_CH),y
masked_blit_line_2:
        lda     $01
        eor     current_textback
        eor     (MON_WNDTOP),y
        and     params_addr
        eor     (MON_WNDTOP),y
        sta     (MON_WNDTOP),y
masked_blit_line_1:
        lda     $00
        eor     current_textback
        eor     (MON_WNDLEFT),y
        and     params_addr
        eor     (MON_WNDLEFT),y
        sta     (MON_WNDLEFT),y
        rts

shifted_draw_line_table:
        .word   shifted_draw_line_1
        .word   shifted_draw_line_2
        .word   shifted_draw_line_3
        .word   shifted_draw_line_4
        .word   shifted_draw_line_5
        .word   shifted_draw_line_6
        .word   shifted_draw_line_7
        .word   shifted_draw_line_8
        .word   shifted_draw_line_9
        .word   shifted_draw_line_10
        .word   shifted_draw_line_11
        .word   shifted_draw_line_12
        .word   shifted_draw_line_13
        .word   shifted_draw_line_14
        .word   shifted_draw_line_15
        .word   shifted_draw_linemax
unshifted_draw_line_table:
        .word   unshifted_draw_line_1
        .word   unshifted_draw_line_2
        .word   unshifted_draw_line_3
        .word   unshifted_draw_line_4
        .word   unshifted_draw_line_5
        .word   unshifted_draw_line_6
        .word   unshifted_draw_line_7
        .word   unshifted_draw_line_8
        .word   unshifted_draw_line_9
        .word   unshifted_draw_line_10
        .word   unshifted_draw_line_11
        .word   unshifted_draw_line_12
        .word   unshifted_draw_line_13
        .word   unshifted_draw_line_14
        .word   unshifted_draw_line_15
        .word   unshifted_draw_linemax
unmasked_blit_line_table:
        .word   unmasked_blit_line_1
        .word   unmasked_blit_line_2
        .word   unmasked_blit_line_3
        .word   unmasked_blit_line_4
        .word   unmasked_blit_line_5
        .word   unmasked_blit_line_6
        .word   unmasked_blit_line_7
        .word   unmasked_blit_line_8
        .word   unmasked_blit_line_9
        .word   unmasked_blit_line_10
        .word   unmasked_blit_line_11
        .word   unmasked_blit_line_12
        .word   unmasked_blit_line_13
        .word   unmasked_blit_line_14
        .word   unmasked_blit_line_15
        .word   unmasked_blit_linemax
masked_blit_line_table:
        .word   masked_blit_line_1
        .word   masked_blit_line_2
        .word   masked_blit_line_3
        .word   masked_blit_line_4
        .word   masked_blit_line_5
        .word   masked_blit_line_6
        .word   masked_blit_line_7
        .word   masked_blit_line_8
        .word   masked_blit_line_9
        .word   masked_blit_line_10
        .word   masked_blit_line_11
        .word   masked_blit_line_12
        .word   masked_blit_line_13
        .word   masked_blit_line_14
        .word   masked_blit_line_15
        .word   masked_blit_linemax
poly_maxima_yh_table:
        .res    16,$00
poly_maxima_x_frach:
        .res    16,$00
poly_maxima_x_fracl:
        .res    16,$00
poly_maxima_xl_table:
        .res    16,$00
poly_maxima_xh_table:
        .res    16,$00

; 
; InitGraf
; 
InitGrafImpl:
        lda     #$41
        sta     src_addr
        jsr     SetSwitchesImpl
        ldx     #$23
@L5E49: lda     standard_port,x
        sta     $8a,x
        sta     current_grafport,x
        dex
        bpl     @L5E49
        lda     saved_port_addr
        ldx     saved_port_addr+1
        jsr     assign_and_prepare_port
        lda     #$7f
        sta     fill_eor_mask
        jsr     PaintRectImpl
        lda     #$00
        sta     fill_eor_mask
        rts

saved_port_addr:
        .word   saved_port

; 
; SetSwitches
; 
switches .set   $82
SetSwitchesImpl:
        lda     SETAN3
        sta     SET80VID
        ldx     #$06
@L5E72: lsr     switches
        lda     @L5E87,x
        rol     a
        tay
        bcs     @L5E80
        lda     KBD,y
        bcc     @L5E83

@L5E80: sta     CLR80COL,y
@L5E83: dex
        bpl     @L5E72
        rts

@L5E87: .byte   $80
        .byte   $81
        .byte   $82
        .byte   $28
        .byte   $29
        .byte   $2a
        .byte   $2b

; 
; SetPort
; 
SetPortImpl:
        lda     params_addr
        ldx     params_addr+1
assign_and_prepare_port:
        sta     active_port
        stx     active_port+1
prepare_port:
        lda     current_textfont+1
        beq     @L5E9D
        jsr     L5861
@L5E9D: jsr     SetPortBitsImpl
        jsr     SetPatternImpl
        jmp     SetPenModeImpl

; 
; GetPort
; 
GetPortImpl:
        jsr     apply_port_to_active_port
        lda     active_port
        ldx     active_port+1
store_xa_at_params:
        ldy     #$00
store_xa_at_y:
        sta     (params_addr),y
        txa
        iny
        sta     (params_addr),y
        rts

; 
; InitPort
; 
InitPortImpl:
        ldy     #$23
@L5EB8: lda     standard_port,y
        sta     (params_addr),y
        dey
        bpl     @L5EB8
L5EC0:  rts

; 
; SetZP1
; 
flag    .set    $82
SetZP1Impl:
        lda     flag
        cmp     preserve_zp_flag
        beq     L5EC0
        sta     preserve_zp_flag
        bcc     L5EC0
        jmp     cleanup

; 
; SetZP2
; 
flag    .set    $82
SetZP2Impl:
        lda     flag
        cmp     low_zp_stash_flag
        beq     L5EC0
        sta     low_zp_stash_flag
        bcc     L5EF1
L5EDC:  bit     low_zp_stash_flag
        bpl     L5EEB
        ldx     #$43
@L5EE3: lda     poly_maxima_yh_table,x
        sta     $00,x
        dex
        bpl     @L5EE3
L5EEB:  rts

L5EEC:  bit     low_zp_stash_flag
        bpl     L5EEB
L5EF1:  ldx     #$43
@L5EF3: lda     $00,x
        sta     poly_maxima_yh_table,x
        dex
        bpl     @L5EF3
        rts

; 
; Version
; 
VersionImpl:
        ldy     #$05
@L5EFE: lda     version,y
        sta     (params_addr),y
        dey
        bpl     @L5EFE
        rts

version:
        .byte   1
        .byte   0
        .byte   0
        .byte   'B'
        .byte   4
        .byte   0
; 
; ============================================================
; 
preserve_zp_flag:
        .byte   $80
low_zp_stash_flag:
        .byte   $80
stack_ptr_stash:
        .byte   $00
; 
; Standard GrafPort
; 
standard_port:
        .word   $0000
        .word   $0000
        .word   $2000
        .word   $0080
        .word   $0000
        .word   $0000
        .word   $022f
        .word   $00bf
standard_port_penpattern:
        .byte   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte   $ff
        .byte   $00
        .word   $0000
        .word   $0000
        .byte   $01
        .byte   $01
        .byte   $00
standard_port_textback:
        .byte   $00
standard_port_textfont:
        .word   $0000
; 
; 
saved_port:
        .word   $0000
        .word   $0000
        .word   $2000
        .word   $0080
        .word   $0000
        .word   $0000
        .word   $022f
        .word   $00bf
        .res    9,$ff
        .res    5,$00
        .byte   $01
        .byte   $01
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
active_saved:
        .word   saved_port
        .res    10,$00
zp_saved:
        .res    128,$00
cursor_flag:
        .byte   $00
cursor_count:
        .byte   $ff
set_pos_params:
        .word   $0000
        .word   $0000
mouse_x:
        .word   $0000
mouse_y:
        .word   $0000
mouse_status:
        .byte   $00
mouse_scale_x:
        .word   $0000
mouse_scale_y:
        .word   $0000
mouse_hooked_flag:
        .byte   $00
mouse_hook:
        .word   $0000
cursor_hotspot_x:
        .byte   $00
cursor_hotspot_y:
        .byte   $00
cursor_mod_7:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
cursor_savebits:
        .res    36,$00
cursor_data:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
pointer_cursor:
        .word   %0000000000000000
        .word   %0000000000000010
        .word   %0000000000000110
        .word   %0000000000001110
        .word   %0000000000011110
        .word   %0000000000111110
        .word   %0000000001111110
        .word   %0000000000011010
        .word   %0000000000110000
        .word   %0000000000110000
        .word   %0000000001100000
        .word   %0000000000000000
        .word   %0000000000000011
        .word   %0000000000000111
        .word   %0000000000001111
        .word   %0000000000011111
        .word   %0000000000111111
        .word   %0000000001111111
        .word   %0000000101111111
        .word   %0000000001111111
        .word   %0000000001111000
        .word   %0000000001111000
        .word   %0000000101110000
        .word   %0000000101110000
        .byte   1
        .byte   1
pointer_cursor_addr:
        .word   pointer_cursor

set_pointer_cursor:
        lda     #$ff
        sta     cursor_count
        lda     #$00
        sta     cursor_flag
        lda     pointer_cursor_addr
        sta     params_addr
        lda     pointer_cursor_addr+1
        sta     params_addr+1
; 
; SetCursor
; 
SetCursorImpl:
        php
        sei
        lda     params_addr
        ldx     params_addr+1
        sta     active_cursor+1
        stx     active_cursor+2
        clc
        adc     #$18
        bcc     @L607F
        inx
@L607F: sta     L6139+1
        stx     L6139+2
        ldy     #$30
        lda     (params_addr),y
        sta     mouse_hook
        iny
        lda     (params_addr),y
        sta     mouse_hook+1
        jsr     restore_cursor_background
        jsr     update_cursor
        plp
L6099:  rts

update_cursor:
        lda     cursor_count
        bne     L6099
        bit     cursor_flag
        bmi     L6099
draw_cursor:
        lda     #$00
        sta     cursor_count
        sta     cursor_flag
        lda     set_pos_params+2
        clc
        sbc     mouse_hook+1
        sta     $84
        clc
        adc     #$0c
        sta     $85
        lda     set_pos_params
        sec
        sbc     mouse_hook
        tax
        lda     set_pos_params+1
        sbc     #$00
        bpl     @L60D3
        txa
        ror     a
        tax
        ldy     L498B+4,x
        lda     #$ff
        bmi     @L60D6

@L60D3: jsr     divmod7
@L60D6: sta     flag
        tya
        rol     a
        cmp     #$07
        bcc     @L60E0
        sbc     #$07
@L60E0: tay
        lda     #$2a
        rol     a
        eor     #$01
        sta     $83
        sty     cursor_hotspot_x
        tya
        asl     a
        tay
        lda     shift_table_main,y
        sta     L6155+1
        lda     shift_table_main+1,y
        sta     L6155+2
        lda     shift_table_aux,y
        sta     L615B+1
        lda     shift_table_aux+1,y
        sta     L615B+2
        ldx     #$03
@L6108: lda     flag,x
        sta     cursor_data,x
        dex
        bpl     @L6108
        ldx     #$17
        stx     $86
        ldx     #$23
        ldy     $85
L6118:  cpy     #$c0
        bcc     @L611F
        jmp     L61AB

@L611F: lda     hires_table_lo,y
        sta     $88
        lda     hires_table_hi,y
        ora     #$20
        sta     $89
        sty     $85
        stx     $87
        ldy     $86
        ldx     #$01
active_cursor:
        lda     $ffff,y
        sta     cursor_hotspot_y,x
L6139:  lda     $ffff,y
        sta     cursor_mod_7+2,x
        dey
        dex
        bpl     active_cursor
        lda     #$00
        sta     cursor_mod_7+1
        sta     cursor_savebits-1
        ldy     cursor_hotspot_x
        beq     L6164
        ldy     #$05
L6152:  ldx     cursor_hotspot_x,y
L6155:  ora     $ff80,x
        sta     cursor_hotspot_y,y
L615B:  lda     $ff00,x
        dey
        bne     L6152
        sta     cursor_hotspot_y
L6164:  ldx     $87
        ldy     flag
        lda     $83
        jsr     L621C
        bcs     @L617F
        lda     ($88),y
        sta     cursor_savebits,x
        lda     cursor_mod_7+2
        ora     ($88),y
        eor     cursor_hotspot_y
        sta     ($88),y
        dex
@L617F: jsr     L6212
        bcs     @L6194
        lda     ($88),y
        sta     cursor_savebits,x
        lda     cursor_mod_7+3
        ora     ($88),y
        eor     cursor_mod_7
        sta     ($88),y
        dex
@L6194: jsr     L6212
        bcs     @L61A9
        lda     ($88),y
        sta     cursor_savebits,x
        lda     cursor_savebits-1
        ora     ($88),y
        eor     cursor_mod_7+1
        sta     ($88),y
        dex
@L61A9: ldy     $85
L61AB:  dec     $86
        dec     $86
        dey
        cpy     $84
        beq     L620E
        jmp     L6118

L61B7:  rts

restore_cursor_background:
        lda     cursor_count
        bne     L61B7
        bit     cursor_flag
        bmi     L61B7
        ldx     #$03
@L61C4: lda     cursor_data,x
        sta     flag,x
        dex
        bpl     @L61C4
        ldx     #$23
        ldy     $85
@L61D0: cpy     #$c0
        bcs     @L6209
        lda     hires_table_lo,y
        sta     $88
        lda     hires_table_hi,y
        ora     #$20
        sta     $89
        sty     $85
        ldy     flag
        lda     $83
        jsr     L621C
        bcs     @L61F1
        lda     cursor_savebits,x
        sta     ($88),y
        dex
@L61F1: jsr     L6212
        bcs     @L61FC
        lda     cursor_savebits,x
        sta     ($88),y
        dex
@L61FC: jsr     L6212
        bcs     @L6207
        lda     cursor_savebits,x
        sta     ($88),y
        dex
@L6207: ldy     $85
@L6209: dey
        cpy     $84
        bne     @L61D0
L620E:  sta     TXTPAGE1
        rts

L6212:  lda     L621F+1
        eor     #$01
        cmp     #$54
        beq     L621C
        iny
L621C:  sta     L621F+1
L621F:  sta     $c0ff
        cpy     #$28
        rts

; 
; ShowCursor
; 
ShowCursorImpl:
        php
        sei
        lda     cursor_count
        beq     @L623E
        inc     cursor_count
        bmi     @L623E
        beq     @L6236
        dec     cursor_count
@L6236: bit     cursor_flag
        bmi     @L623E
        jsr     draw_cursor
@L623E: plp
        rts

; 
; ObscureCursor
; 
ObscureCursorImpl:
        php
        sei
        jsr     restore_cursor_background
        lda     #$80
        sta     cursor_flag
        plp
        rts

; 
; HideCursor
; 
HideCursorImpl:
        php
        sei
        jsr     restore_cursor_background
        dec     cursor_count
        plp
L6255:  rts

cursor_throttle:
        .byte   $00

move_cursor:
        bit     use_interrupts
        bpl     @L626E
        lda     kbd_mouse_state
        bne     @L626E
        dec     cursor_throttle
        lda     cursor_throttle
        bpl     L6255
        lda     #$02
        sta     cursor_throttle
@L626E: ldx     #$02
@L6270: lda     mouse_x,x
        cmp     set_pos_params,x
        bne     @L627D
        dex
        bpl     @L6270
        bmi     @L6291

@L627D: jsr     restore_cursor_background
        ldx     #$02
        stx     cursor_flag
@L6285: lda     mouse_x,x
        sta     set_pos_params,x
        dex
        bpl     @L6285
        jsr     update_cursor
@L6291: bit     no_mouse_flag
        bmi     @L6299
        jsr     read_mouse_pos
@L6299: bit     no_mouse_flag
        bpl     @L62A3
        lda     #$00
        sta     mouse_status
@L62A3: lda     kbd_mouse_state
        beq     L62AB
        jsr     handle_keyboard_mouse
L62AB:  rts

read_mouse_pos:
        ldy     #$14
        jsr     call_mouse
        bit     mouse_scale_y
        bmi     @L62CB
        ldx     mouse_firmware_hi
        lda     $03b8,x
        sta     mouse_x
        lda     $04b8,x
        sta     mouse_x+1
        lda     $0438,x
        sta     mouse_y
@L62CB: ldy     mouse_scale_x
        beq     @L62E1
@L62D0: lda     mouse_x
        asl     a
        sta     mouse_x
        lda     mouse_x+1
        rol     a
        sta     mouse_x+1
        dey
        bne     @L62D0
@L62E1: ldy     mouse_scale_x+1
        beq     @L62F0
        lda     mouse_y
@L62E9: asl     a
        dey
        bne     @L62E9
        sta     mouse_y
@L62F0: bit     mouse_scale_y
        bmi     @L62FB
        lda     $06b8,x
        sta     mouse_status
@L62FB: rts

; 
; GetCursorAddr
; 
GetCursorAddrImpl:
        lda     active_cursor+1
        ldx     active_cursor+2
        jmp     store_xa_at_params

call_mouse:
        bit     no_mouse_flag
        bmi     L62AB
        bit     mouse_scale_y
        bmi     hooked
        pha
        ldx     mouse_firmware_hi
        stx     $89
        lda     #$00
        sta     $88
        lda     ($88),y
        sta     $88
        pla
        ldy     mouse_operand
        jmp     ($0088)

hooked: jmp     (mouse_scale_y+1)

; 
; Init Parameters
; 
machid: .byte   $00
subid:  .byte   $00
op_sys: .byte   $00
slot_num:
        .byte   $00
use_interrupts:
        .byte   $00
savebehind_size:
        .word   $0000
savebehind_usage:
        .word   $0000
        .byte   $00
        .byte   $00

; 
; ============================================================
; 
; StartDeskTop
; 
params_machine .set $82
params_subid .set $83
params_op_sys .set $84
params_slot_num .set $85
params_use_irq .set $86
params_sysfontptr .set $87
params_savearea .set $89
params_savesize .set $8b
StartDeskTopImpl:
        php
        pla
        sta     savebehind_usage+3
        ldx     #$04
@L6339: lda     params_machine,x
        sta     machid,x
        dex
        bpl     @L6339
        lda     #$7f
        sta     standard_port_textback
        lda     params_sysfontptr
        sta     standard_port_textfont
        lda     params_sysfontptr+1
        sta     standard_port_textfont+1
        lda     params_savearea
        sta     savebehind_buffer
        lda     params_savearea+1
        sta     savebehind_buffer+1
        lda     params_savesize
        sta     savebehind_size
        lda     params_savesize+1
        sta     savebehind_size+1
        jsr     set_irq_mode
        jsr     set_op_sys
        ldy     #$02
        lda     (params_sysfontptr),y
        tax
        stx     sysfont_height
        dex
        stx     goaway_height
        inx
        inx
        inx
        stx     fill_rect_params2_height
        inx
        stx     wintitle_height
        stx     test_rect_bottom
        stx     test_rect_params2+2
        stx     fill_rect_params4+2
        inx
        stx     set_port_params+2
        stx     wintitle_height+2
        stx     desktop_port_bits+2
        stx     fill_rect_params+2
        lda     #$01
        sta     mouse_scale_x
        lda     #$00
        sta     mouse_scale_x+1
        bit     subid
        bvs     @L63AF
        lda     #$02
        sta     mouse_scale_x
        lda     #$01
        sta     mouse_scale_x+1
@L63AF: ldx     slot_num
        jsr     find_mouse
        bit     slot_num
        bpl     @L63D4
        cpx     #$00
        bne     @L63C3
        lda     #$92
        jmp     exit_with_a

@L63C3: lda     slot_num
        and     #$7f
        beq     @L63D4
        cpx     slot_num
        beq     @L63D4
        lda     #$91
        jmp     exit_with_a

@L63D4: stx     slot_num
        lda     #$80
        sta     savebehind_usage+2
        lda     slot_num
        bne     @L63EB
        bit     use_interrupts
        bpl     @L63EB
        lda     #$00
        sta     use_interrupts
@L63EB: ldy     #$03
        lda     slot_num
        sta     (params_addr),y
        iny
        lda     use_interrupts
        sta     (params_addr),y
        bit     use_interrupts
        bpl     @L6408
        bit     op_sys
        bpl     @L6408
        jsr     P8_MLI
        .byte   P8_ALLOC_INTERRUPT
        .word   alloc_interrupt_params
@L6408: lda     MON_VERSION
        pha
        lda     #$06
        sta     MON_VERSION
        ldy     #$12
        lda     #$01
        bit     use_interrupts
        bpl     @L641D
        cli
        ora     #$08
@L641D: jsr     call_mouse
        pla
        sta     MON_VERSION
        jsr     InitGrafImpl
        jsr     set_pointer_cursor
        jsr     FlushEventsImpl
        lda     #$00
        sta     current_window+1
L6432:  jsr     save_params_and_stack
        jsr     set_desktop_port
        jsr     MGTK
        .byte   $08
        .word   checkerboard_pattern
        jsr     MGTK
        .byte   $11
        .word   fill_rect_params
        jmp     restore_params_active_port

alloc_interrupt_params:
        .byte   $02
        .byte   $00
        .word   interrupt_handler
dealloc_interrupt_params:
        .byte   1
        .byte   $00
set_irq_mode:
        lda     use_interrupts
        beq     @L645B
        cmp     #$01
        bne     @L645C
        lda     #$80
        sta     use_interrupts
@L645B: rts

@L645C: lda     #$93
        jmp     exit_with_a

set_op_sys:
        lda     op_sys
        beq     @L646F
        cmp     #$01
        beq     @L6474
        lda     #$90
        jmp     exit_with_a

@L646F: lda     #$80
        sta     op_sys
@L6474: rts

; 
; StopDeskTop
; 
StopDeskTopImpl:
        ldy     #$12
        lda     #$00
        jsr     call_mouse
        ldy     #$13
        jsr     call_mouse
        bit     use_interrupts
        bpl     @L6497
        bit     op_sys
        bpl     @L6497
        lda     alloc_interrupt_params+1
        sta     dealloc_interrupt_params+1
        jsr     P8_MLI
        .byte   P8_DEALLOC_INTERRUPT
        .word   dealloc_interrupt_params
@L6497: lda     savebehind_usage+3
        pha
        plp
        lda     #$00
        sta     savebehind_usage+2
        rts

; 
; SetUserHook
; 
hook_id .set    $82
routine_ptr .set $83
SetUserHookImpl:
        lda     hook_id
        cmp     #$01
        bne     @L64B5
        lda     routine_ptr+1
        bne     @L64C6
        sta     before_events_hook+1
        lda     routine_ptr
        sta     before_events_hook
        rts

@L64B5: cmp     #$02
        bne     @L64D8
        lda     routine_ptr+1
        bne     @L64CF
        sta     after_events_hook+1
        lda     routine_ptr
        sta     after_events_hook
        rts

@L64C6: lda     #$00
        sta     before_events_hook
        sta     before_events_hook+1
        rts

@L64CF: lda     #$00
        sta     after_events_hook
        sta     after_events_hook+1
        rts

@L64D8: lda     #$94
        jmp     exit_with_a

call_before_events_hook:
        lda     before_events_hook+1
        beq     @L64ED
        jsr     save_params_and_stack
        jsr     before_events_hook_jmp
        php
        jsr     restore_params_active_port
        plp
@L64ED: rts

before_events_hook_jmp:
        jmp     (before_events_hook)

before_events_hook:
        .word   $0000

call_after_events_hook:
        lda     after_events_hook+1
        beq     $6503
        jsr     save_params_and_stack
        jsr     after_events_hook_jmp
        php
        jsr     restore_params_active_port
        plp
        rts

after_events_hook_jmp:
        jmp     (after_events_hook)

after_events_hook:
        .word   $0000
params_addr_save:
        .word   $0000
stack_ptr_save:
        .byte   $00

hide_cursor_save_params:
        jsr     HideCursorImpl
save_params_and_stack:
        lda     params_addr
        sta     params_addr_save
        lda     params_addr+1
        sta     params_addr_save+1
        lda     stack_ptr_stash
        sta     stack_ptr_save
        lsr     preserve_zp_flag
        rts

show_cursor_and_restore:
        jsr     ShowCursorImpl
restore_params_active_port:
        asl     preserve_zp_flag
        lda     params_addr_save
        sta     params_addr
        lda     params_addr_save+1
        sta     params_addr+1
        lda     active_port
        ldx     active_port+1
set_and_prepare_port:
        sta     hook_id
        stx     routine_ptr
        lda     stack_ptr_save
        sta     stack_ptr_stash
        ldy     #$23
@L6543: lda     (hook_id),y
        sta     current_grafport,y
        dey
        bpl     @L6543
        jmp     prepare_port

set_standard_port:
        lda     standard_port_addr
        ldx     standard_port_addr+1
        bne     set_and_prepare_port
standard_port_addr:
        .word   standard_port
set_desktop_port:
        jsr     set_standard_port
        jsr     MGTK
        .byte   $06
        .word   desktop_port_bits
        rts

desktop_port_bits:
        .byte   $00
        .byte   $00
        .byte   $0d
        .byte   $00
        .byte   $00
        .byte   $20
        .byte   $80
        .byte   $00
fill_rect_params:
        .word   $0000
        .word   $0000
        .word   $022f
        .word   $00bf
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
checkerboard_pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   $00

; 
; AttachDriver
; 
hook    .set    $82
mouse_state .set $84
AttachDriverImpl:
        bit     savebehind_usage+2
        bmi     @L659D
        lda     hook
        sta     mouse_scale_y+1
        lda     hook+1
        sta     mouse_hooked_flag
        lda     mouse_state_addr
        ldx     mouse_state_addr+1
        ldy     #$02
        jmp     store_xa_at_y

@L659D: lda     #$95
        jmp     exit_with_a

mouse_state_addr:
        .word   mouse_x

; 
; PeekEvent
; 
PeekEventImpl:
        clc
        bcc     L65A8

; 
; GetEvent
; 
GetEventImpl:
        sec
L65A8:  php
        bit     use_interrupts
        bpl     @L65B1
        sei
        bmi     @L65B4

@L65B1: jsr     CheckEventsImpl
@L65B4: jsr     next_event
        bcs     @L65D4
        plp
        php
        bcc     @L65C0

        sta     eventbuf_tail
@L65C0: tax
        ldy     #$00
@L65C3: lda     eventbuf,x
        sta     (params_addr),y
        inx
        iny
        cpy     #$04
        bne     @L65C3
        lda     #$00
        sta     (params_addr),y
        beq     @L65D7

@L65D4: jsr     return_move_event
@L65D7: plp
        bit     use_interrupts
        bpl     @L65DE
        cli
@L65DE: rts

; 
; PostEvent
; 
kind    .set    $82
xcoord  .set    $83
ycoord  .set    $85
PostEventImpl:
        php
        sei
        lda     kind
        bmi     @L65F6
        cmp     #$06
        bcs     @L660B
        cmp     #$03
        beq     @L65F6
        ldx     xcoord
        ldy     xcoord+1
        lda     ycoord
        jsr     set_mouse_pos
@L65F6: jsr     put_event
        bcs     @L660F
        tax
        ldy     #$00
@L65FE: lda     (params_addr),y
        sta     eventbuf,x
        inx
        iny
        cpy     #$04
        bne     @L65FE
        plp
        rts

@L660B: lda     #$98
        bmi     @L6611

@L660F: lda     #$99
@L6611: plp
        jmp     exit_with_a

return_move_event:
        lda     #$00
        bit     mouse_status
        bpl     @L661E
        lda     #$04
@L661E: ldy     #$00
        sta     (params_addr),y
        iny
@L6623: lda     cursor_count,y
        sta     (params_addr),y
        iny
        cpy     #$05
        bne     @L6623
        rts

L662E:  .byte   $00
L662F:  .byte   $00
L6630:  .byte   $00
        .byte   $00
input_modifiers:
        .byte   $00

; 
; CheckEvents
; 
CheckEventsImpl:
        bit     use_interrupts
        bpl     CheckEventsImpl_irq_entry
        lda     #$97
        jmp     exit_with_a

CheckEventsImpl_irq_entry:
        sec
        jsr     call_before_events_hook
        bcc     @L66B5
        lda     BUTN1
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        sta     input_modifiers
        jsr     activate_keyboard_mouse
        jsr     move_cursor
        lda     mouse_status
        asl     a
        eor     mouse_status
        bmi     @L6684
        bit     mouse_status
        bmi     @L66B5
        bit     check_kbd_flag
        bpl     @L6684
        lda     KBD
        bpl     @L66B5
        and     #$7f
        sta     L662F
        bit     KBDSTRB
        lda     input_modifiers
        sta     L6630
        lda     #$03
        sta     L662E
        bne     @L66A3

@L6684: bcc     @L6693
        lda     input_modifiers
        beq     @L668F
        lda     #$05
        bne     @L6695

@L668F: lda     #$01
        bne     @L6695

@L6693: lda     #$02
@L6695: sta     L662E
        ldx     #$02
@L669A: lda     set_pos_params,x
        sta     L662F,x
        dex
        bpl     @L669A
@L66A3: jsr     put_event
        tax
        ldy     #$00
@L66A9: lda     L662E,y
        sta     eventbuf,x
        inx
        iny
        cpy     #$04
        bne     @L66A9
@L66B5: jmp     call_after_events_hook

int_stash_zp:
        .res    9,$00

interrupt_handler:
        cld
interrupt_handler_body:
        ldx     #$08
@L66C4: lda     kind,x
        sta     int_stash_zp,x
        dex
        bpl     @L66C4
        ldy     #$13
        jsr     call_mouse
        bcs     @L66D7
        jsr     CheckEventsImpl_irq_entry
        clc
@L66D7: ldx     #$08
@L66D9: lda     int_stash_zp,x
        sta     kind,x
        dex
        bpl     @L66D9
        rts

int_handler_addr:
        .word   interrupt_handler_body

; 
; GetIntHandler
; 
GetIntHandlerImpl:
        lda     int_handler_addr
        ldx     int_handler_addr+1
        jmp     store_xa_at_params

eventbuf_tail:
        .byte   $00
eventbuf_head:
        .byte   $00
eventbuf:
        .res    132,$00

; 
; FlushEvents
; 
FlushEventsImpl:
        php
        sei
        lda     #$00
        sta     eventbuf_tail
        sta     eventbuf_head
        plp
        rts

put_event:
        lda     eventbuf_head
        cmp     #$80
        bne     @L678A
        lda     #$00
        bcs     @L678D
@L678A: clc
        adc     #$04
@L678D: cmp     eventbuf_tail
        beq     L6797
        sta     eventbuf_head
        clc
        rts

L6797:  sec
        rts

next_event:
        lda     eventbuf_tail
        cmp     eventbuf_head
        beq     L6797
        cmp     #$80
        bne     @L67A9
        lda     #$00
        bcs     @L67AC
@L67A9: clc
        adc     #$04
@L67AC: clc
        rts

check_kbd_flag:
        .byte   $80

; 
; SetKeyEvent
; 
handle_keys .set $82
SetKeyEventImpl:
        asl     check_kbd_flag
        ror     handle_keys
        ror     check_kbd_flag
        rts

; 
; Menu Drawing
; 
offset_checkmark:
        .byte   $02
offset_text:
        .byte   $09
offset_shortcut:
        .byte   $10
shortcut_x_adj:
        .byte   $09
non_shortcut_x_adj:
        .byte   $1e
sysfont_height:
        .byte   $c5
active_menu:
        .byte   $00
        .byte   $00
test_rect_params:
        .word   $ffff
        .word   $ffff
        .word   $0230
test_rect_bottom:
        .word   $000c
fill_rect_params2:
        .word   $0000
        .word   $0000
L67CC:  .word   $0000
fill_rect_params2_height:
        .word   $000b
savebehind_buffer:
        .word   $0000
test_rect_params2:
        .word   $0000
        .word   $000c
L67D6:  .word   $0000
L67D8:  .word   $0000
fill_rect_params4:
        .word   $0000
        .word   $000c
L67DE:  .word   $0000
L67E0:  .word   $0000
menu_item_y_table:
        .byte   12
        .byte   24
        .byte   36
        .byte   48
        .byte   60
        .byte   72
        .byte   84
        .byte   96
        .byte   108
        .byte   120
        .byte   132
        .byte   144
        .byte   156
        .byte   168
        .byte   180
solid_apple_glyph:
        .byte   $1e
open_apple_glyph:
        .byte   $1f
checkmark_glyph:
        .byte   $1d
controlkey_glyph:
        .byte   $01
shortcut_text:
        .byte   $02
        .byte   $1e
        .byte   $ff
mark_text:
        .byte   $01
        .byte   $1d
test_rect_params_addr:
        .word   test_rect_params
test_rect_params2_addr:
        .word   test_rect_params2
mark_text_addr:
        .word   mark_text
shortcut_text_addr:
        .word   shortcut_text

get_menu_count:
        lda     active_menu
        sta     handle_keys
        lda     active_menu+1
        sta     $83
        ldy     #$00
        lda     (handle_keys),y
        sta     $a8
        rts

get_menu:
        stx     $a7
        lda     #$02
        clc
@L6818: dex
        bmi     @L681F
        adc     #$0c
        bne     @L6818
@L681F: adc     active_menu
        sta     $ab
        lda     active_menu+1
        adc     #$00
        sta     $ac
        ldy     #$0b
@L682D: lda     ($ab),y
        sta     $00af,y
        dey
        bpl     @L682D
        ldy     #$05
@L6837: lda     ($b3),y
        sta     $00ba,y
        dey
        bne     @L6837
        lda     ($b3),y
        sta     $aa
        rts

put_menu:
        ldy     #$0b
@L6846: lda     $00af,y
        sta     ($ab),y
        dey
        bpl     @L6846
        ldy     #$05
@L6850: lda     $00ba,y
        sta     ($b3),y
        dey
        bne     @L6850
        rts

get_menu_item:
        stx     $a9
        lda     #$06
        clc
@L685E: dex
        bmi     @L6865
        adc     #$06
        bne     @L685E
@L6865: adc     $b3
        sta     $ad
        lda     $b4
        adc     #$00
        sta     $ae
        ldy     #$05
@L6871: lda     ($ad),y
        sta     $00bf,y
        dey
        bpl     @L6871
        rts

put_menu_item:
        ldy     #$05
@L687C: lda     $00bf,y
        sta     ($ad),y
        dey
        bpl     @L687C
        rts

set_penloc:
        sty     current_penloc_y
        ldy     #$00
        sty     current_penloc_y+1
L688B:  sta     current_penloc_x
        stx     current_penloc_x+1
        rts

set_fill_mode:
        sta     current_penmode
        jmp     SetPenModeImpl

do_measure_text:
        jsr     prepare_text_params
        jmp     measure_text

draw_text:
        jsr     prepare_text_params
        jmp     DrawTextImpl

prepare_text_params:
        sta     handle_keys
        stx     $83
        clc
        adc     #$01
        bcc     @L68AB
        inx
@L68AB: sta     $a1
        stx     $a2
        ldy     #$00
        lda     (handle_keys),y
        sta     $a3
        rts

get_and_return_event:
        jsr     MGTK
        .byte   $29
        .word   $0082
        lda     handle_keys
        rts

; 
; SetMenu
; 
SetMenuImpl:
        lda     params_addr
        sta     active_menu
        lda     params_addr+1
        sta     active_menu+1
        jsr     get_menu_count
        jsr     hide_cursor_save_params
        jsr     set_standard_port
        lda     test_rect_params_addr
        ldx     test_rect_params_addr+1
        jsr     fill_and_frame_rect
        lda     #$0c
        ldx     #$00
        ldy     sysfont_height
        iny
        jsr     set_penloc
        ldx     #$00
menuloop:
        jsr     get_menu
        lda     current_penloc_x
        ldx     current_penloc_x+1
        sta     $b5
        stx     $b6
        sec
        sbc     #$08
        bcs     @L68F9
        dex
@L68F9: sta     $b7
        stx     $b8
        sta     $bb
        stx     $bc
        ldx     #$00
        stx     $c5
        stx     $c6
@L6907: jsr     get_menu_item
        bit     $bf
        bvs     @L6945
        lda     $c3
        ldx     $c4
        jsr     do_measure_text
        sta     handle_keys
        stx     $83
        lda     $bf
        and     #$03
        bne     @L6928
        lda     $c1
        bne     @L6928
        lda     shortcut_x_adj
        bne     @L692B
@L6928: lda     non_shortcut_x_adj
@L692B: clc
        adc     handle_keys
        sta     handle_keys
        bcc     @L6934
        inc     $83
@L6934: sec
        sbc     $c5
        lda     $83
        sbc     $c6
        bmi     @L6945
        lda     handle_keys
        sta     $c5
        lda     $83
        sta     $c6
@L6945: ldx     $a9
        inx
        cpx     $aa
        bne     @L6907
        lda     $bb
        clc
        adc     $c5
        sta     $bd
        lda     $bc
        adc     #$00
        sta     $be
        jsr     put_menu
        lda     $b1
        ldx     $b2
        jsr     draw_text
        jsr     get_menu_and_menu_item
        lda     current_penloc_x
        ldx     current_penloc_x+1
        clc
        adc     #$08
        bcc     @L6970
        inx
@L6970: sta     $b9
        stx     $ba
        jsr     put_menu
        lda     #$0c
        ldx     #$00
        jsr     adjust_xpos
        ldx     $a7
        inx
        cpx     $a8
        beq     @L6988
        jmp     menuloop

@L6988: lda     #$00
        sta     cur_open_menu
        sta     cur_hilited_menu_item
        jmp     show_cursor_and_restore

get_menu_and_menu_item:
        ldx     $a7
        jsr     get_menu
        ldx     $a9
        jmp     get_menu_item

fill_and_frame_rect:
        sta     @L69B2
        stx     @L69B2+1
        sta     @L69BD
        stx     @L69BD+1
        lda     #$00
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $11
@L69B2: .word   $0000
        lda     #$04
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $12
@L69BD: .word   $0000
        rts

find_menu_by_id_or_fail:
        jsr     find_menu_by_id
        bne     @L69CA
        lda     #$9a
        jmp     exit_with_a

@L69CA: rts

find_menu_by_id:
        lda     #$00
find_menu:
        sta     $c6
        jsr     get_menu_count
        ldx     #$00
@L69D4: jsr     get_menu
        bit     $c6
        bvs     @L6A01
        bmi     @L69E5
        lda     $af
        cmp     $c7
        bne     @L6A06
        beq     @L6A10

@L69E5: lda     set_pos_params
        ldx     set_pos_params+1
        cpx     $b8
        bcc     @L6A06
        bne     @L69F5
        cmp     $b7
        bcc     @L6A06
@L69F5: cpx     $ba
        bcc     @L6A10
        bne     @L6A06
        cmp     $b9
        bcc     @L6A10
        bcs     @L6A06

@L6A01: jsr     find_menu_item
        bne     @L6A10
@L6A06: ldx     $a7
        inx
        cpx     $a8
        bne     @L69D4
        lda     #$00
        rts

@L6A10: lda     $af
        rts

find_menu_item:
        ldx     #$00
@L6A15: jsr     get_menu_item
        ldx     $a9
        inx
        bit     $c6
        bvs     @L6A31
        bmi     @L6A27
        cpx     $c8
        bne     @L6A4D
        beq     @L6A53

@L6A27: lda     menu_item_y_table,x
        cmp     set_pos_params+2
        bcs     @L6A53
        bcc     @L6A4D

@L6A31: lda     $c9
        and     #$7f
        cmp     $c1
        beq     @L6A3D
        cmp     $c2
        bne     @L6A4D
@L6A3D: cmp     #$20
        bcc     @L6A53
        lda     $bf
        and     #$c0
        bne     @L6A4D
        lda     $bf
        and     $ca
        bne     @L6A53
@L6A4D: cpx     $aa
        bne     @L6A15
        ldx     #$00
@L6A53: rts

; 
; HiliteMenu
; 
HiliteMenuImpl:
        lda     $c7
        bne     @L6A5D
        lda     cur_open_menu
        sta     $c7
@L6A5D: jsr     find_menu_by_id_or_fail
L6A60:  jsr     hide_cursor_save_params
        jsr     set_standard_port
        jsr     hilite_menu
        jmp     show_cursor_and_restore

hilite_menu:
        ldx     #$01
@L6A6E: lda     $b7,x
        sta     fill_rect_params2,x
        lda     $b9,x
        sta     L67CC,x
        lda     $bb,x
        sta     test_rect_params2,x
        sta     fill_rect_params4,x
        lda     $bd,x
        sta     L67D6,x
        sta     L67DE,x
        dex
        bpl     @L6A6E
        lda     #$02
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $11
        .word   fill_rect_params2
        rts

; 
; MenuKey
; 
menu_id .set    $c7
menu_item .set  $c8
which_key .set  $c9
key_mods .set   $ca
MenuKeyImpl:
        lda     which_key
        cmp     #$1b
        bne     @L6AA7
        lda     key_mods
        bne     @L6AA7
        jsr     KeyboardMouseImpl
        jmp     MenuSelectImpl

@L6AA7: lda     #$c0
        jsr     find_menu
        beq     @L6ABF
        lda     $b0
        bmi     @L6ABF
        lda     $bf
        and     #$c0
        bne     @L6ABF
        lda     $af
        sta     cur_open_menu
        bne     @L6AC2
@L6ABF: lda     #$00
        tax
@L6AC2: ldy     #$00
        sta     (params_addr),y
        iny
        txa
        sta     (params_addr),y
        bne     L6A60
        rts

find_menu_and_menu_item:
        jsr     find_menu_by_id_or_fail
        jsr     find_menu_item
        cpx     #$00
L6AD5:  rts

find_menu_item_or_fail:
        jsr     find_menu_and_menu_item
        bne     L6AD5
        lda     #$9b
        jmp     exit_with_a

; 
; DisableItem
; 
menu_id .set    $c7
menu_item .set  $c8
disable .set    $c9
DisableItemImpl:
        jsr     find_menu_item_or_fail
        asl     $bf
        ror     disable
        ror     $bf
        jmp     put_menu_item

; 
; CheckItem
; 
menu_id .set    $c7
menu_item .set  $c8
check   .set    $c9
CheckItemImpl:
        jsr     find_menu_item_or_fail
        lda     check
        beq     @L6AF9
        lda     #$20
        ora     $bf
        bne     @L6AFD
@L6AF9: lda     #$df
        and     $bf
@L6AFD: sta     $bf
        jmp     put_menu_item

; 
; DisableMenu
; 
menu_id .set    $c7
disable .set    $c8
DisableMenuImpl:
        jsr     find_menu_by_id_or_fail
        asl     $b0
        ror     disable
        ror     $b0
        ldx     $a7
        jmp     put_menu

cur_open_menu:
        .byte   $00
cur_hilited_menu_item:
        .byte   $00

; 
; MenuSelect
; 
menu_id .set    $c7
menu_item .set  $c8
MenuSelectImpl:
        jsr     kbd_mouse_init_tracking
        jsr     get_menu_count
        jsr     save_params_and_stack
        jsr     set_standard_port
        bit     kbd_mouse_state
        bpl     @L6B29
        jsr     kbd_menu_select
        jmp     in_menu

@L6B29: lda     #$00
        sta     cur_open_menu
        sta     cur_hilited_menu_item
        jsr     get_and_return_event
L6B34:  bit     movement_cancel
        bpl     @L6B3C
        jmp     kbd_menu_return

@L6B3C: jsr     MGTK
        .byte   $0e
        .word   $0083
        jsr     MGTK
        .byte   $13
        .word   test_rect_params
        bne     L6B8F
        lda     cur_open_menu
        beq     in_menu
        jsr     MGTK
        .byte   $13
        .word   test_rect_params2
        bne     L6BAA
        jsr     unhilite_cur_menu_item
in_menu:
        jsr     get_and_return_event
        beq     @L6B63
        cmp     #$02
        bne     L6B34
@L6B63: lda     cur_hilited_menu_item
        bne     @L6B6E
        jsr     hide_menu
        jmp     @L6B77

@L6B6E: jsr     HideCursorImpl
        jsr     set_standard_port
        jsr     L6C2B
@L6B77: jsr     restore_params_active_port
        lda     #$00
        ldx     cur_hilited_menu_item
        beq     @L6B8C
        lda     cur_open_menu
        ldy     $a7
        sty     kbd_mouse_y+3
        stx     saved_mouse_pos-1
@L6B8C: jmp     store_xa_at_params

L6B8F:  jsr     unhilite_cur_menu_item
        lda     #$80
        jsr     find_menu
        cmp     cur_open_menu
        beq     in_menu
        pha
        jsr     hide_menu
        pla
        sta     cur_open_menu
        jsr     draw_menu
        jmp     in_menu

L6BAA:  lda     #$80
        sta     $c6
        jsr     find_menu_item
        cpx     cur_hilited_menu_item
        beq     in_menu
        lda     $b0
        ora     $bf
        and     #$c0
        beq     @L6BC0
        ldx     #$00
@L6BC0: txa
        pha
        jsr     hilite_menu_item
        pla
        sta     cur_hilited_menu_item
        jsr     hilite_menu_item
        jmp     in_menu

set_up_savebehind:
        lda     $bc
        lsr     a
        lda     $bb
        ror     a
        tax
        lda     div_7_table,x
        sta     $82
        lda     $be
        lsr     a
        lda     $bd
        ror     a
        tax
        lda     div_7_table,x
        sec
        sbc     $82
        sta     $90
        lda     savebehind_buffer
        sta     $8e
        lda     savebehind_buffer+1
        sta     $8f
        ldy     $aa
        ldx     menu_item_y_table,y
        inx
        stx     $83
        stx     L67E0
        stx     L67D8
        ldx     sysfont_height
        inx
        inx
        inx
        stx     fill_rect_params4+2
        stx     test_rect_params2+2
        rts

savebehind_get_vidaddr:
        lda     hires_table_lo,x
        clc
        adc     $82
        sta     $84
        lda     hires_table_hi,x
        ora     #$20
        sta     $85
        rts

savebehind_next_line:
        lda     $8e
        sec
        adc     $90
        sta     $8e
        bcc     @L6C2A
        inc     $8f
@L6C2A: rts

L6C2B:  jsr     set_up_savebehind
@L6C2E: jsr     savebehind_get_vidaddr
        sta     TXTPAGE2
        ldy     $90
@L6C36: lda     ($8e),y
        sta     ($84),y
        dey
        bpl     @L6C36
        jsr     savebehind_next_line
        sta     TXTPAGE1
        ldy     $90
@L6C45: lda     ($8e),y
        sta     ($84),y
        dey
        bpl     @L6C45
        jsr     savebehind_next_line
        inx
        cpx     $83
        bcc     @L6C2E
        beq     @L6C2E
        jmp     ShowCursorImpl

L6C59:  rts

hide_menu:
        clc
        bcc     L6C5E

draw_menu:
        sec
L6C5E:  lda     cur_open_menu
        beq     L6C59
        php
        sta     menu_id
        jsr     find_menu_by_id
        jsr     HideCursorImpl
        jsr     hilite_menu
        plp
        bcc     L6C2B

        jsr     set_up_savebehind
@L6C75: jsr     savebehind_get_vidaddr
        sta     TXTPAGE2
        ldy     $90
@L6C7D: lda     ($84),y
        sta     ($8e),y
        dey
        bpl     @L6C7D
        jsr     savebehind_next_line
        sta     TXTPAGE1
        ldy     $90
@L6C8C: lda     ($84),y
        sta     ($8e),y
        dey
        bpl     @L6C8C
        jsr     savebehind_next_line
        inx
        cpx     $83
        bcc     @L6C75
        beq     @L6C75
        jsr     set_standard_port
        lda     test_rect_params2_addr
        ldx     test_rect_params2_addr+1
        jsr     fill_and_frame_rect
        inc     fill_rect_params4
        bne     @L6CB1
        inc     fill_rect_params4+1
@L6CB1: lda     L67DE
        bne     @L6CB9
        dec     L67DE+1
@L6CB9: dec     L67DE
        jsr     get_menu_and_menu_item
        ldx     #$00
@L6CC1: jsr     get_menu_item
        bit     $bf
        bvc     @L6CCB
        jmp     @L6D4F

@L6CCB: lda     $bf
        and     #$20
        beq     @L6CF4
        lda     offset_checkmark
        jsr     moveto_menuitem
        lda     checkmark_glyph
        sta     mark_text+1
        lda     $bf
        and     #$04
        beq     @L6CE8
        lda     $c0
        sta     mark_text+1
@L6CE8: lda     mark_text_addr
        ldx     mark_text_addr+1
        jsr     draw_text
        jsr     get_menu_and_menu_item
@L6CF4: lda     offset_text
        jsr     moveto_menuitem
        lda     $c3
        ldx     $c4
        jsr     draw_text
        jsr     get_menu_and_menu_item
        lda     $bf
        and     #$03
        bne     @L6D17
        lda     $c1
        beq     @L6D41
        lda     controlkey_glyph
        sta     shortcut_text+1
        jmp     @L6D41

@L6D17: cmp     #$01
        bne     @L6D24
        lda     open_apple_glyph
        sta     shortcut_text+1
        jmp     @L6D2A

@L6D24: lda     solid_apple_glyph
        sta     shortcut_text+1
@L6D2A: lda     $c1
        sta     shortcut_text+2
        lda     offset_shortcut
        jsr     L6DC9
        lda     shortcut_text_addr
        ldx     shortcut_text_addr+1
        jsr     draw_text
        jsr     get_menu_and_menu_item
@L6D41: bit     $b0
        bmi     @L6D49
        bit     $bf
        bpl     @L6D4F
@L6D49: jsr     dim_menuitem
        jmp     @L6D4F

@L6D4F: ldx     $a9
        inx
        cpx     $aa
        beq     @L6D59
        jmp     @L6CC1

@L6D59: jmp     ShowCursorImpl

moveto_menuitem:
        ldx     $a9
        ldy     menu_item_y_table+1,x
        dey
        ldx     $bc
        clc
        adc     $bb
        bcc     @L6D6A
        inx
@L6D6A: jmp     set_penloc

dim_menuitem:
        ldx     $a9
        lda     menu_item_y_table,x
        sta     fill_rect_params3_top
        inc     fill_rect_params3_top
        lda     menu_item_y_table+1,x
        sta     fill_rect_params3_bottom
        clc
        lda     $bb
        adc     #$05
        sta     fill_rect_params3
        lda     $bc
        adc     #$00
        sta     fill_rect_params3+1
        sec
        lda     $bd
        sbc     #$05
        sta     fill_rect_params3_right
        lda     $be
        sbc     #$00
        sta     fill_rect_params3_right+1
        jsr     MGTK
        .byte   $08
        .word   light_speckle_pattern
        lda     #$01
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $11
        .word   fill_rect_params3
        jsr     MGTK
        .byte   $08
        .word   standard_port_penpattern
        lda     #$02
        jsr     set_fill_mode
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
        .word   $0000
fill_rect_params3_top:
        .word   $0000
fill_rect_params3_right:
        .word   $0000
fill_rect_params3_bottom:
        .word   $0000

L6DC9:  sta     $82
        lda     $bd
        ldx     $be
        sec
        sbc     $82
        bcs     @L6DD5
        dex
@L6DD5: jmp     L688B

unhilite_cur_menu_item:
        jsr     hilite_menu_item
        lda     #$00
        sta     cur_hilited_menu_item
L6DE0:  rts

hilite_menu_item:
        ldx     cur_hilited_menu_item
        beq     L6DE0
        ldy     menu_item_y_table-1,x
        iny
        sty     fill_rect_params4+2
        ldy     menu_item_y_table,x
        sty     L67E0
        jsr     HideCursorImpl
        lda     #$02
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $11
        .word   fill_rect_params4
        jmp     ShowCursorImpl

; 
; InitMenu
; 
solid_char .set $82
open_char .set  $83
check_char .set $84
control_char .set $85
InitMenuImpl:
        ldx     #$03
@L6E06: lda     solid_char,x
        sta     solid_apple_glyph,x
        dex
        bpl     @L6E06
        lda     standard_port_textfont
        sta     solid_char
        lda     standard_port_textfont+1
        sta     open_char
        ldy     #$00
        lda     (solid_char),y
        bmi     @L6E39
        lda     #$02
        sta     offset_checkmark
        lda     #$09
        sta     offset_text
        lda     #$10
        sta     offset_shortcut
        lda     #$09
        sta     shortcut_x_adj
        lda     #$1e
        sta     non_shortcut_x_adj
        bne     @L6E52

@L6E39: lda     #$02
        sta     offset_checkmark
        lda     #$10
        sta     offset_text
        lda     #$1e
        sta     offset_shortcut
        lda     #$10
        sta     shortcut_x_adj
        lda     #$33
        sta     non_shortcut_x_adj
@L6E52: ldy     #$02
        lda     (solid_char),y
        cmp     #$0b
        nop
        tay
        iny
        iny
        iny
        ldx     #$00
@L6E5F: tya
        adc     menu_item_y_table,x
        inx
        sta     menu_item_y_table,x
        cpx     #$0e
        bcc     @L6E5F
        rts

; 
; SetMark
; 
menu_id .set    $c7
menu_item .set  $c8
set_char .set   $c9
mark_char .set  $ca
SetMarkImpl:
        jsr     find_menu_item_or_fail
        lda     set_char
        beq     @L6E80
        lda     #$04
        ora     $bf
        sta     $bf
        lda     mark_char
        sta     $c0
        jmp     put_menu_item

@L6E80: lda     #$fb
        and     $bf
        sta     $bf
        jmp     put_menu_item

up_scroll_params:
        .word   $0000
        .word   $0000
        .byte   $13
        .byte   $0a
        .word   up_scroll_bitmap
down_scroll_params:
        .word   $0000
        .word   $0000
        .byte   $13
        .byte   $0a
        .word   down_scroll_bitmap
left_scroll_params:
        .word   $0000
        .word   $0000
        .byte   $14
        .byte   $09
        .word   left_scroll_bitmap
right_scroll_params:
        .word   $0000
        .word   $0000
        .byte   $12
        .byte   $09
        .word   right_scroll_bitmap
resize_box_params:
        .word   $0000
        .word   $0000
        .byte   $14
        .byte   $0a
        .word   resize_box_bitmap
up_scroll_bitmap:
        .faraddr %000000000000000000000000
        .faraddr %000000000001100000000000
        .faraddr %000000000110011000000000
        .faraddr %000000110000000101000000
        .faraddr %000011000000000000110000
        .faraddr %001111110000000101111100
        .faraddr %000000110000000101000000
        .faraddr %000000110000000101000000
        .faraddr %000000110111111101000000
        .faraddr %000000000000000000000000
        .faraddr %011111110111111101111110
down_scroll_bitmap:
        .faraddr %011111110111111101111110
        .faraddr %000000000000000000000000
        .faraddr %000000110111111101000000
        .faraddr %000000110000000101000000
        .faraddr %000000110000000101000000
        .faraddr %001111110000000101111100
        .faraddr %000011000000000000110000
        .faraddr %000000110000000101000000
        .faraddr %000000000110011000000000
        .faraddr %000000000001100000000000
        .faraddr %000000000000000000000000
left_scroll_bitmap:
        .faraddr %000000000000000000000000
        .faraddr %010000000001100000000000
        .faraddr %010000000001111000000000
        .faraddr %010011110111100101000000
        .faraddr %010011000000000000110000
        .faraddr %010011000000000000001100
        .faraddr %010011000000000000110000
        .faraddr %010011110111100101000000
        .faraddr %010000000001111000000000
        .faraddr %010000000001100000000000
right_scroll_bitmap:
        .faraddr %000000000000000000000000
        .faraddr %000000000000110000000001
        .faraddr %000000000011110000000001
        .faraddr %000000010100111101111001
        .faraddr %000001100000000000011001
        .faraddr %000110000000000000011001
T6F23:  .faraddr %000001100000000000011001
        .faraddr %000000010100111101111001
        .faraddr %000000000011110000000001
        .faraddr %000000000000110000000001
unused: .byte   $00
resize_box_bitmap:
        .faraddr %011111110111111101111111
        .faraddr %010000000000000000000001
        .faraddr %010000000011111101111001
        .faraddr %010011110111000000011001
        .faraddr %010011000011000000011001
        .faraddr %010011000011000000011001
        .faraddr %010011000011111101111001
        .faraddr %010011000000000001100001
        .faraddr %010011110111111101100001
        .faraddr %010000000000000000000001
        .faraddr %011111110111111101111111
up_scroll_addr:
        .word   up_scroll_params
down_scroll_addr:
        .word   down_scroll_params
left_scroll_addr:
        .word   left_scroll_params
right_scroll_addr:
        .word   right_scroll_params
resize_box_addr:
        .word   resize_box_params
current_window:
        .word   $0000
sel_window_id:
        .byte   $00
found_window:
        .word   $0000
target_window_id:
        .byte   $00
root_window_addr:
        .word   T6F23

top_window:
        lda     root_window_addr
        sta     $a7
        lda     root_window_addr+1
        sta     $a8
        lda     current_window
        ldx     current_window+1
        bne     L6F88
L6F75:  rts

next_window:
        lda     $a9
        sta     $a7
        lda     $aa
        sta     $a8
        ldy     #$39
        lda     ($a9),y
        beq     L6F75
        tax
        dey
        lda     ($a9),y
L6F88:  sta     found_window
        stx     found_window+1
get_window:
        lda     found_window
        ldx     found_window+1
L6F94:  sta     $a9
        stx     $aa
        ldy     #$0b
@L6F9A: lda     ($a9),y
        sta     $00ab,y
        dey
        bpl     @L6F9A
        ldy     #$23
@L6FA4: lda     ($a9),y
        sta     $00a3,y
        dey
        cpy     #$13
        bne     @L6FA4
L6FAE:  lda     $a9
        ldx     $aa
        rts

window_by_id:
        jsr     top_window
        beq     @L6FC3
@L6FB8: lda     $ab
        cmp     $82
        beq     L6FAE
        jsr     next_window
        bne     @L6FB8
@L6FC3: rts

window_by_id_or_exit:
        jsr     window_by_id
        beq     @L6FCA
        rts

@L6FCA: lda     #$9e
        jmp     exit_with_a

frame_winrect:
        jsr     MGTK
        .byte   $12
        .word   $00c7
        rts

in_winrect:
        jsr     MGTK
        .byte   $13
        .word   $00c7
        rts

get_winrect:
        ldx     #$03
@L6FDF: lda     $b7,x
        sta     menu_id,x
        dex
        bpl     @L6FDF
        ldx     #$02
@L6FE8: lda     $c3,x
        sec
        sbc     $bf,x
        tay
        lda     $c4,x
        sbc     $c0,x
        pha
        tya
        clc
        adc     menu_id,x
        sta     $cb,x
        pla
        adc     menu_item,x
        sta     $cc,x
        dex
        dex
        bpl     @L6FE8
L7002:  lda     #$c7
        ldx     #$00
        rts

get_winframerect:
        jsr     get_winrect
        lda     menu_id
        bne     @L7010
        dec     menu_item
@L7010: dec     menu_id
        bit     $b0
        bmi     @L7020
        lda     $ac
        and     #$04
        bne     @L7020
        lda     #$01
        bne     @L7022

@L7020: lda     #$15
@L7022: clc
        adc     $cb
        sta     $cb
        bcc     @L702B
        inc     $cc
@L702B: lda     #$01
        bit     $af
        bpl     @L7033
        lda     #$0b
@L7033: clc
        adc     $cd
        sta     $cd
        bcc     @L703C
        inc     $ce
@L703C: lda     #$01
        and     $ac
        bne     @L7045
        lda     wintitle_height+2
@L7045: sta     $82
        lda     set_char
        sec
        sbc     $82
        sta     set_char
        bcs     L7002
        dec     mark_char
        bcc     L7002

get_win_vertscrollrect:
        jsr     get_winframerect
        lda     $cb
        ldx     $cc
        sec
        sbc     #$14
        bcs     @L7061
        dex
@L7061: sta     menu_id
        stx     menu_item
        lda     $ac
        and     #$01
        bne     L7002
        lda     set_char
        clc
        adc     wintitle_height
        sta     set_char
        bcc     L7002
        inc     mark_char
        bcs     L7002

get_win_horizscrollrect:
        jsr     get_winframerect
L707C:  lda     $cd
        ldx     $ce
        sec
        sbc     #$0a
        bcs     @L7086
        dex
@L7086: sta     set_char
        stx     mark_char
        jmp     L7002

get_win_growboxrect:
        jsr     get_win_vertscrollrect
        jmp     L707C

get_wintitlebar_rect:
        jsr     get_winframerect
        lda     set_char
        clc
        adc     wintitle_height
        sta     $cd
        lda     mark_char
        adc     #$00
        sta     $ce
        jmp     L7002

get_wingoaway_rect:
        jsr     get_wintitlebar_rect
        lda     menu_id
        ldx     menu_item
        clc
        adc     #$02
        bcc     @L70B4
        inx
@L70B4: sta     menu_id
        stx     menu_item
        clc
        adc     #$0e
        bcc     @L70BE
        inx
@L70BE: sta     $cb
        stx     $cc
        lda     set_char
        ldx     mark_char
        clc
        adc     #$02
        bcc     @L70CC
        inx
@L70CC: sta     set_char
        stx     mark_char
        clc
        adc     goaway_height
        bcc     @L70D7
        inx
@L70D7: sta     $cd
        stx     $ce
        jmp     L7002

draw_window:
        jsr     get_winframerect
        jsr     fill_and_frame_rect
        lda     $ac
        and     #$01
        bne     @L70FA
        jsr     get_wintitlebar_rect
        jsr     fill_and_frame_rect
        jsr     center_title_text
        lda     $ad
        ldx     $ae
        jsr     draw_text
@L70FA: jsr     get_window
        bit     $b0
        bpl     @L7107
        jsr     get_win_vertscrollrect
        jsr     frame_winrect
@L7107: bit     $af
        bpl     @L7111
        jsr     get_win_horizscrollrect
        jsr     frame_winrect
@L7111: lda     $ac
        and     #$04
        beq     @L7123
        jsr     get_win_growboxrect
        jsr     frame_winrect
        jsr     get_win_vertscrollrect
        jsr     frame_winrect
@L7123: jsr     get_window
        lda     $ab
        cmp     sel_window_id
        bne     @L7133
        jsr     set_desktop_port
        jmp     draw_winframe

@L7133: rts

draw_erase_mode:
        .byte   $01

erase_winframe:
        lda     #$01
        ldx     #$00
        beq     L713F

draw_winframe:
        lda     #$03
        ldx     #$01
L713F:  stx     draw_erase_mode
        jsr     set_fill_mode
        lda     $ac
        and     #$02
        beq     @L7157
        lda     $ac
        and     #$01
        bne     @L7157
        jsr     get_wingoaway_rect
        jsr     frame_winrect
@L7157: lda     #$02
        jsr     set_fill_mode
        lda     $ac
        and     #$01
        bne     @L7192
        jsr     get_wintitlebar_rect
        jsr     center_title_text
        jsr     penloc_to_bounds
        lda     $92
        sec
        sbc     #$0a
        sta     $92
        bcs     @L7176
        dec     $93
@L7176: lda     $96
        clc
        adc     #$0a
        sta     $96
        bcc     @L7181
        inc     $97
@L7181: lda     $94
        bne     @L7187
        dec     $95
@L7187: dec     $94
        inc     $98
        bne     @L718F
        inc     $99
@L718F: jsr     PaintRectImpl
@L7192: jsr     get_window
        bit     $b0
        bpl     @L71DF
        jsr     get_win_vertscrollrect
        ldx     #$03
@L719E: lda     menu_id,x
        sta     up_scroll_params,x
        sta     down_scroll_params,x
        dex
        bpl     @L719E
        lda     $cd
        ldx     $ce
        sec
        sbc     #$0a
        bcs     @L71B3
        dex
@L71B3: pha
        lda     $ac
        and     #$04
        bne     @L71BE
        bit     $af
        bpl     @L71C6
@L71BE: pla
        sec
        sbc     #$0b
        bcs     @L71C5
        dex
@L71C5: pha
@L71C6: pla
        sta     down_scroll_params+2
        stx     down_scroll_params+3
        lda     down_scroll_addr
        ldx     down_scroll_addr+1
        jsr     draw_icon
        lda     up_scroll_addr
        ldx     up_scroll_addr+1
        jsr     draw_icon
@L71DF: bit     $af
        bpl     @L7229
        jsr     get_win_horizscrollrect
        ldx     #$03
@L71E8: lda     menu_id,x
        sta     left_scroll_params,x
        sta     right_scroll_params,x
        dex
        bpl     @L71E8
        lda     $cb
        ldx     $cc
        sec
        sbc     #$14
        bcs     @L71FD
        dex
@L71FD: pha
        lda     $ac
        and     #$04
        bne     @L7208
        bit     $b0
        bpl     @L7210
@L7208: pla
        sec
        sbc     #$15
        bcs     @L720F
        dex
@L720F: pha
@L7210: pla
        sta     right_scroll_params
        stx     right_scroll_params+1
        lda     right_scroll_addr
        ldx     right_scroll_addr+1
        jsr     draw_icon
        lda     left_scroll_addr
        ldx     left_scroll_addr+1
        jsr     draw_icon
@L7229: lda     #$00
        jsr     set_fill_mode
        lda     $b0
        and     #$01
        beq     @L7241
        lda     #$80
        sta     $8c
        lda     draw_erase_mode
        jsr     L7866
        jsr     get_window
@L7241: lda     $af
        and     #$01
        beq     @L7254
        lda     #$00
        sta     $8c
        lda     draw_erase_mode
        jsr     L7866
        jsr     get_window
@L7254: lda     $ac
        and     #$04
        beq     @L7284
        jsr     get_win_growboxrect
        lda     draw_erase_mode
        bne     @L726C
        lda     #$c7
        ldx     #$00
        jsr     fill_and_frame_rect
        jmp     @L7284

@L726C: ldx     #$03
@L726E: lda     menu_id,x
        sta     resize_box_params,x
        dex
        bpl     @L726E
        lda     #$04
        jsr     set_fill_mode
        lda     resize_box_addr
        ldx     resize_box_addr+1
        jsr     draw_icon
@L7284: rts

center_title_text:
        lda     $ad
        ldx     $ae
        jsr     do_measure_text
        sta     $82
        stx     $83
        lda     menu_id
        clc
        adc     $cb
        tay
        lda     menu_item
        adc     $cc
        tax
        tya
        sec
        sbc     $82
        tay
        txa
        sbc     $83
        cmp     #$80
        ror     a
        sta     current_penloc_x+1
        tya
        ror     a
        sta     current_penloc_x
        lda     $cd
        ldx     $ce
        sec
        sbc     #$02
        bcs     @L72B6
        dex
@L72B6: sta     current_penloc_y
        stx     current_penloc_y+1
        lda     $82
        ldx     $83
        rts

; 
; FindWindow
; 
FindWindowImpl:
        jsr     save_params_and_stack
        jsr     MGTK
        .byte   $13
        .word   test_rect_params
        beq     L72DC
        lda     #$01
L72CC:  ldx     #$00
L72CE:  pha
        txa
        pha
        jsr     restore_params_active_port
        pla
        tax
        pla
        ldy     #$04
        jmp     store_xa_at_y

L72DC:  lda     #$00
        sta     next_selected
        jsr     top_window
        beq     @L72F6
@L72E6: jsr     get_winframerect
        jsr     in_winrect
        bne     @L72FA
        jsr     next_window
        stx     next_selected
        bne     @L72E6
@L72F6: lda     #$00
        beq     L72CC

@L72FA: lda     $ac
        and     #$01
        bne     @L7323
        jsr     get_wintitlebar_rect
        jsr     in_winrect
        beq     @L7323
        lda     next_selected
        bne     @L731F
        lda     $ac
        and     #$02
        beq     @L731F
        jsr     get_wingoaway_rect
        jsr     in_winrect
        beq     @L731F
        lda     #$05
        bne     @L7338

@L731F: lda     #$03
        bne     @L7338

@L7323: lda     next_selected
        bne     @L733C
        lda     $ac
        and     #$04
        beq     @L733C
        jsr     get_win_growboxrect
        jsr     in_winrect
        beq     @L733C
        lda     #$04
@L7338: ldx     $ab
        bne     L72CE
@L733C: lda     #$02
        bne     @L7338

next_selected:
        .byte   $00

; 
; OpenWindow
; 
OpenWindowImpl:
        lda     params_addr
        sta     $a9
        lda     params_addr+1
        sta     $aa
        ldy     #$00
        lda     ($a9),y
        bne     @L7354
        lda     #$9d
        jmp     exit_with_a

@L7354: sta     $82
        jsr     window_by_id
        beq     @L7360
        lda     #$9c
        jmp     exit_with_a

@L7360: lda     params_addr
        sta     $a9
        lda     params_addr+1
        sta     $aa
        ldy     #$0a
        lda     ($a9),y
        ora     #$80
        sta     ($a9),y
        bmi     L7383

; 
; SelectWindow
; 
SelectWindowImpl:
        jsr     window_by_id_or_exit
        cmp     current_window
        bne     @L7380
        cpx     current_window+1
        bne     @L7380
        rts

@L7380: jsr     L73BA
L7383:  ldy     #$38
        lda     current_window
        sta     ($a9),y
        iny
        lda     current_window+1
        sta     ($a9),y
        lda     $a9
        pha
        lda     $aa
        pha
        jsr     hide_cursor_save_params
        jsr     set_desktop_port
        jsr     top_window
        beq     @L73A4
        jsr     erase_winframe
@L73A4: pla
        sta     current_window+1
        pla
        sta     current_window
        jsr     top_window
        lda     $ab
        sta     sel_window_id
        jsr     draw_window
        jmp     show_cursor_and_restore

L73BA:  ldy     #$38
        lda     ($a9),y
        sta     ($a7),y
        iny
        lda     ($a9),y
        sta     ($a7),y
        rts

; 
; GetWinPtr
; 
GetWinPtrImpl:
        jsr     window_by_id_or_exit
        lda     $a9
        ldx     $aa
        ldy     #$01
        jmp     store_xa_at_y

previous_port:
        .word   $0000
update_port:
        .res    36,$00

; 
; BeginUpdate
; 
BeginUpdateImpl:
        jsr     window_by_id_or_exit
        lda     $ab
        cmp     target_window_id
        bne     @L7405
        inc     L7737
@L7405: jsr     hide_cursor_save_params
        jsr     set_desktop_port
        lda     L7737
        bne     @L7416
        jsr     MGTK
        .byte   $06
        .word   set_port_params
@L7416: jsr     draw_window
        jsr     set_desktop_port
        lda     L7737
        bne     @L7427
        jsr     MGTK
        .byte   $06
        .word   set_port_params
@L7427: jsr     get_window
        lda     active_port
        sta     previous_port
        lda     active_port+1
        sta     previous_port+1
        jsr     prepare_winport
        php
        lda     update_port_addr
        ldx     update_port_addr+1
        jsr     assign_and_prepare_port
        asl     preserve_zp_flag
        plp
        bcc     @L7448
        rts

@L7448: jsr     EndUpdateImpl
L744B:  lda     #$a2
        jmp     exit_with_a

update_port_addr:
        .word   update_port

; 
; EndUpdate
; 
EndUpdateImpl:
        jsr     ShowCursorImpl
        lda     previous_port
        ldx     previous_port+1
        sta     active_port
        stx     active_port+1
        jmp     set_and_prepare_port

; 
; GetWinPort
; 
GetWinPortImpl:
        jsr     apply_port_to_active_port
        jsr     window_by_id_or_exit
        lda     $83
        sta     params_addr
        lda     $84
        sta     params_addr+1
        ldx     #$07
@L7472: lda     fill_rect_params,x
        sta     current_grafport+8,x
        dex
        bpl     @L7472
        jsr     prepare_winport
        bcc     L744B
        ldy     #$23
@L7481: lda     current_grafport,y
        sta     (params_addr),y
        dey
        bpl     @L7481
        jmp     apply_active_port_to_port

prepare_winport:
        jsr     get_winrect
        ldx     #$07
@L7491: lda     #$00
        sta     $9b,x
        lda     menu_id,x
        sta     $92,x
        dex
        bpl     @L7491
        jsr     clip_rect
        bcs     @L74A2
        rts

@L74A2: ldy     #$14
@L74A4: lda     ($a9),y
        sta     $00bc,y
        iny
        cpy     #$38
        bne     @L74A4
        ldx     #$02
@L74B0: lda     $92,x
        sta     current_grafport,x
        lda     $93,x
        sta     current_grafport+1,x
        lda     $96,x
        sec
        sbc     $92,x
        sta     $82,x
        lda     $97,x
        sbc     $93,x
        sta     $83,x
        lda     current_grafport+8,x
        sec
        sbc     $9b,x
        sta     current_grafport+8,x
        lda     current_grafport+9,x
        sbc     $9c,x
        sta     current_grafport+9,x
        lda     current_grafport+8,x
        clc
        adc     $82,x
        sta     current_grafport+12,x
        lda     current_grafport+9,x
        adc     $83,x
        sta     current_grafport+13,x
        dex
        dex
        bpl     @L74B0
        sec
        rts

; 
; SetWinPort
; 
SetWinPortImpl:
        jsr     window_by_id_or_exit
        lda     $a9
        clc
        adc     #$14
        sta     $a9
        bcc     @L74F3
        inc     $aa
@L74F3: ldy     #$23
@L74F5: lda     ($82),y
        sta     ($a9),y
        dey
        cpy     #$10
        bcs     @L74F5
        rts

; 
; FrontWindow
; 
FrontWindowImpl:
        jsr     top_window
        beq     @L7508
        lda     $ab
        bne     @L750A
@L7508: lda     #$00
@L750A: ldy     #$00
        sta     (params_addr),y
        rts

in_close_box:
        .byte   $00

; 
; TrackGoAway
; 
TrackGoAwayImpl:
        jsr     top_window
        beq     @L755D
        jsr     get_wingoaway_rect
        jsr     save_params_and_stack
        jsr     set_desktop_port
        lda     #$80
@L7520: sta     in_close_box
        lda     #$02
        jsr     set_fill_mode
        jsr     HideCursorImpl
        jsr     MGTK
        .byte   $11
        .word   $00c7
        jsr     ShowCursorImpl
@L7534: jsr     get_and_return_event
        cmp     #$02
        beq     @L7551
        jsr     MGTK
        .byte   $0e
        .word   set_pos_params
        jsr     in_winrect
        eor     in_close_box
        bpl     @L7534
        lda     in_close_box
        eor     #$80
        jmp     @L7520

@L7551: jsr     restore_params_active_port
        ldy     #$00
        lda     in_close_box
        beq     @L755D
        lda     #$01
@L755D: sta     (params_addr),y
        rts

        .byte   $00
L7561:  .byte   $00
L7562:  .byte   $00
L7563:  .byte   $00
L7564:  .byte   $00
L7565:  .byte   $00
L7566:  .byte   $00
        .byte   $00
        .byte   $00
L7569:  .byte   $00
L756A:  .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00

; 
; GrowWindow
; 
GrowWindowImpl:
        lda     #$80
        bmi     L7574

; 
; DragWindow
; 
DragWindowImpl:
        lda     #$00
L7574:  sta     GrowWindowImpl-1
        jsr     kbd_mouse_init_tracking
        ldx     #$03
@L757C: lda     $83,x
        sta     L7561,x
        sta     L7565,x
        lda     #$00
        sta     L7569,x
        dex
        bpl     @L757C
        jsr     window_by_id_or_exit
        bit     kbd_mouse_state
        bpl     @L7597
        jsr     kbd_win_drag_or_grow
@L7597: jsr     hide_cursor_save_params
        jsr     L7712
        lda     #$02
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $08
        .word   checkerboard_pattern
@L75A8: jsr     get_window
        jsr     @L760F
        jsr     get_winframerect
        jsr     frame_winrect
        jsr     ShowCursorImpl
@L75B7: jsr     get_and_return_event
        cmp     #$02
        bne     @L7601
        jsr     frame_winrect
        bit     movement_cancel
        bmi     @L75D0
        ldx     #$03
@L75C8: lda     L7569,x
        bne     @L75DA
        dex
        bpl     @L75C8
@L75D0: jsr     show_cursor_and_restore
        lda     #$00
@L75D5: ldy     #$05
        sta     (params_addr),y
        rts

@L75DA: ldy     #$14
@L75DC: lda     $00a3,y
        sta     ($a9),y
        iny
        cpy     #$24
        bne     @L75DC
        jsr     HideCursorImpl
        lda     $ab
        jsr     L7738
        jsr     hide_cursor_save_params
        bit     movement_cancel
        bvc     @L75F9
        jsr     set_input
@L75F9: jsr     show_cursor_and_restore
        lda     #$80
        jmp     @L75D5

@L7601: jsr     L76A6
        beq     @L75B7
        jsr     HideCursorImpl
        jsr     frame_winrect
        jmp     @L75A8

@L760F: ldy     #$13
@L7611: lda     ($a9),y
        sta     $00bb,y
        dey
        cpy     #$0b
        bne     @L7611
        ldx     #$00
        stx     force_tracking_change
        bit     GrowWindowImpl-1
        bmi     @L7643
@L7625: lda     $b7,x
        clc
        adc     L7569,x
        sta     $b7,x
        lda     $b8,x
        adc     L756A,x
        sta     $b8,x
        inx
        inx
        cpx     #$04
        bne     @L7625
        lda     #$12
        cmp     $b9
        bcc     @L7642
        sta     $b9
@L7642: rts

@L7643: lda     #$00
        sta     grew_flag
@L7648: clc
        lda     $c3,x
        adc     L7569,x
        sta     $c3,x
        lda     $c4,x
        adc     L756A,x
        sta     $c4,x
        sec
        lda     $c3,x
        sbc     $bf,x
        sta     $82
        lda     $c4,x
        sbc     $c0,x
        sta     $83
        sec
        lda     $82
        sbc     menu_id,x
        lda     $83
        sbc     menu_item,x
        bpl     @L7682
        clc
        lda     menu_id,x
        adc     $bf,x
        sta     $c3,x
        lda     menu_item,x
        adc     $c0,x
        sta     $c4,x
        jsr     set_grew_flag
        jmp     @L769D

@L7682: sec
        lda     $cb,x
        sbc     $82
        lda     $cc,x
        sbc     $83
        bpl     @L769D
        clc
        lda     $cb,x
        adc     $bf,x
        sta     $c3,x
        lda     $cc,x
        adc     $c0,x
        sta     $c4,x
        jsr     set_grew_flag
@L769D: inx
        inx
        cpx     #$04
        bne     @L7648
        jmp     finish_grow

L76A6:  ldx     #$02
        ldy     #$00
@L76AA: lda     $84,x
        cmp     L7566,x
        bne     @L76B2
        iny
@L76B2: lda     $83,x
        cmp     L7565,x
        bne     @L76BA
        iny
@L76BA: sta     L7565,x
        sec
        sbc     L7561,x
        sta     L7569,x
        lda     $84,x
        sta     L7566,x
        sbc     L7562,x
        sta     L756A,x
        dex
        dex
        bpl     @L76AA
        cpy     #$04
        bne     @L76DA
        lda     force_tracking_change
@L76DA: rts

; 
; CloseWindow
; 
CloseWindowImpl:
        jsr     window_by_id_or_exit
        jsr     hide_cursor_save_params
        jsr     L7712
        jsr     L73BA
        ldy     #$0a
        lda     ($a9),y
        and     #$7f
        sta     ($a9),y
        jsr     top_window
        lda     $ab
        sta     sel_window_id
        lda     #$00
        jmp     L7738

; 
; CloseAll
; 
CloseAllImpl:
        jsr     top_window
        beq     @L770F
        ldy     #$0a
        lda     ($a9),y
        and     #$7f
        sta     ($a9),y
        jsr     L73BA
        jmp     CloseAllImpl

@L770F: jmp     L6432

L7712:  jsr     set_desktop_port
        jsr     get_winframerect
        ldx     #$07
@L771A: lda     menu_id,x
        sta     $92,x
        dex
        bpl     @L771A
        jsr     clip_rect
        ldx     #$03
@L7726: lda     $92,x
        sta     set_port_maprect,x
        sta     set_port_params,x
        lda     $96,x
        sta     L77A3,x
        dex
        bpl     @L7726
        rts

L7737:  .byte   $00

L7738:  sta     target_window_id
        lda     #$00
        sta     L7737
        jsr     MGTK
        .byte   $06
        .word   set_port_params
        lda     #$00
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $08
        .word   checkerboard_pattern
        jsr     MGTK
        .byte   $11
        .word   set_port_maprect
        jsr     show_cursor_and_restore
        jsr     top_window
        beq     @L7790
        php
        sei
        jsr     FlushEventsImpl
@L7764: jsr     next_window
        bne     @L7764
@L7769: jsr     put_event
        bcs     @L778F
        tax
        lda     #$06
        sta     eventbuf,x
        lda     $ab
        sta     eventbuf+1,x
        lda     $ab
        cmp     sel_window_id
        beq     @L778F
        sta     $82
        jsr     window_by_id
        lda     $a7
        ldx     $a8
        jsr     L6F94
        jmp     @L7769

@L778F: plp
@L7790: rts

goaway_height:
        .byte   $08
        .byte   $00
wintitle_height:
        .byte   $0c
        .byte   $00
        .byte   $0d
        .byte   $00
set_port_params:
        .byte   $00
        .byte   $00
        .byte   $0d
        .byte   $00
        .byte   $00
        .byte   $20
        .byte   $80
        .byte   $00
set_port_maprect:
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
L77A3:  .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00

; 
; WindowToScreen
; 
window_id .set  $82
windowx .set    $83
windowy .set    $85
screenx .set    $87
screeny .set    $89
WindowToScreenImpl:
        jsr     window_by_id_or_exit
        ldx     #$02
@L77AC: lda     windowx,x
        clc
        adc     $b7,x
        sta     windowx,x
        lda     windowx+1,x
        adc     $b8,x
        sta     windowx+1,x
        dex
        dex
        bpl     @L77AC
        bmi     copy_map_results

; 
; ScreenToWindow
; 
window_id .set  $82
screenx .set    $83
screeny .set    $85
windowx .set    $87
windowy .set    $89
ScreenToWindowImpl:
        jsr     window_by_id_or_exit
        ldx     #$02
@L77C4: lda     screenx,x
        sec
        sbc     $b7,x
        sta     screenx,x
        lda     screenx+1,x
        sbc     $b8,x
        sta     screenx+1,x
        dex
        dex
        bpl     @L77C4
copy_map_results:
        ldy     #$05
@L77D7: lda     $007e,y
        sta     (params_addr),y
        iny
        cpy     #$09
        bne     @L77D7
        rts

draw_icon:
        sta     window_id
        stx     screenx
        ldy     #$03
@L77E8: lda     #$00
        sta     $008a,y
        lda     (window_id),y
        sta     $0092,y
        dey
        bpl     @L77E8
        iny
        sty     $91
        ldy     #$04
        lda     (window_id),y
        tax
        lda     div_7_table+7,x
        sta     $90
        txa
        ldx     $93
        clc
        adc     $92
        bcc     @L780B
        inx
@L780B: sta     $96
        stx     $97
        iny
        lda     (window_id),y
        ldx     $95
        clc
        adc     $94
        bcc     @L781A
        inx
@L781A: sta     $98
        stx     $99
        iny
        lda     (window_id),y
        sta     $8e
        iny
        lda     (window_id),y
        sta     $8f
        jmp     BitBltImpl

; 
; ActivateCtl
; 
which_ctl .set  $8c
activate .set   $8d
ActivateCtlImpl:
        lda     which_ctl
        cmp     #$01
        bne     @L7837
        lda     #$80
        sta     which_ctl
        bne     @L7842

@L7837: cmp     #$02
        bne     @L7841
        lda     #$00
        sta     which_ctl
        beq     @L7842

@L7841: rts

@L7842: jsr     hide_cursor_save_params
        jsr     top_window
        bit     which_ctl
        bpl     @L7852
        lda     $b0
        ldy     #$05
        bne     @L7856

@L7852: lda     $af
        ldy     #$04
@L7856: eor     activate
        and     #$01
        eor     ($a9),y
        sta     ($a9),y
        lda     activate
        jsr     L7866
        jmp     show_cursor_and_restore

L7866:  bne     @L7875
        jsr     L78B7
        jsr     set_standard_port
        jsr     MGTK
        .byte   $11
        .word   $00c7
        rts

@L7875: bit     which_ctl
        bmi     @L787E
        bit     $af
        bmi     @L7882
@L787D: rts

@L787E: bit     $b0
        bpl     @L787D
@L7882: jsr     set_standard_port
        jsr     L78B7
        jsr     MGTK
        .byte   $08
        .word   light_speckles_pattern
        jsr     MGTK
        .byte   $11
        .word   $00c7
        jsr     MGTK
        .byte   $08
        .word   standard_port_penpattern
        bit     which_ctl
        bmi     @L78A3
        bit     $af
        bvs     @L78A7
@L78A2: rts

@L78A3: bit     $b0
        bvc     @L78A2
@L78A7: jsr     L7939
        jmp     fill_and_frame_rect

light_speckles_pattern:
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   $00
        .byte   $00

L78B7:  bit     which_ctl
        bpl     @L78FA
        jsr     get_win_vertscrollrect
        lda     $c9
        clc
        adc     #$0b
        sta     $c9
        bcc     @L78C9
        inc     $ca
@L78C9: lda     $cd
        sec
        sbc     #$0b
        sta     $cd
        bcs     @L78D4
        dec     $ce
@L78D4: lda     $ac
        and     #$04
        bne     @L78DE
        bit     $af
        bpl     @L78E9
@L78DE: lda     $cd
        sec
        sbc     #$0b
        sta     $cd
        bcs     @L78E9
        dec     $ce
@L78E9: inc     $c7
        bne     @L78EF
        inc     $c8
@L78EF: lda     $cb
        bne     @L78F5
        dec     $cc
@L78F5: dec     $cb
        jmp     @L7936

@L78FA: jsr     get_win_horizscrollrect
        lda     $c7
        clc
        adc     #$15
        sta     $c7
        bcc     @L7908
        inc     $c8
@L7908: lda     $cb
        sec
        sbc     #$15
        sta     $cb
        bcs     @L7913
        dec     $cc
@L7913: lda     $ac
        and     #$04
        bne     @L791D
        bit     $b0
        bpl     @L7928
@L791D: lda     $cb
        sec
        sbc     #$15
        sta     $cb
        bcs     @L7928
        dec     $cc
@L7928: inc     $c9
        bne     @L792E
        inc     $ca
@L792E: lda     $cd
        bne     @L7934
        dec     $ce
@L7934: dec     $cd
@L7936: jmp     L7002

L7939:  jsr     L78B7
        jsr     L7BA9
        jsr     L5687
        lda     $a1
        pha
        jsr     L7BC1
        jsr     L7B80
        pla
        tax
        lda     $a3
        ldy     $a4
        cpx     #$01
        beq     @L795A
        ldx     $a0
        jsr     L7B59
@L795A: sta     $82
        sty     $83
        ldx     #$00
        lda     #$14
        bit     which_ctl
        bpl     @L796A
        ldx     #$02
        lda     #$0c
@L796A: pha
        lda     $c7,x
        clc
        adc     $82
        sta     $c7,x
        lda     $c8,x
        adc     $83
        sta     $c8,x
        pla
        clc
        adc     $c7,x
        sta     $cb,x
        lda     $c8,x
        adc     #$00
        sta     $cc,x
        jmp     L7002

; 
; FindControl
; 
FindControlImpl:
        jsr     save_params_and_stack
        jsr     top_window
        bne     @L7994
        lda     #$9f
        jmp     exit_with_a

@L7994: bit     $b0
        bpl     @L79DB
        jsr     get_win_vertscrollrect
        jsr     in_winrect
        beq     @L79DB
        ldx     #$00
        lda     $b0
        and     #$01
        beq     @L79D7
        lda     #$80
        sta     which_ctl
        jsr     L78B7
        jsr     in_winrect
        beq     @L79C4
        bit     $b0
        bcs     @L7A36
        jsr     L7939
        jsr     in_winrect
        beq     @L79C8
        ldx     #$05
        bne     @L79D7

@L79C4: lda     #$01
        bne     @L79CA

@L79C8: lda     #$03
@L79CA: pha
        jsr     L7939
        pla
        tax
        lda     current_penloc_y
        cmp     $c9
        bcc     @L79D7
        inx
@L79D7: lda     #$01
        bne     @L7A38

@L79DB: bit     $af
        bpl     @L7A2A
        jsr     get_win_horizscrollrect
        jsr     in_winrect
        beq     @L7A2A
        ldx     #$00
        lda     $af
        and     #$01
        beq     @L7A26
        lda     #$00
        sta     which_ctl
        jsr     L78B7
        jsr     in_winrect
        beq     @L7A0B
        bit     $af
        bvc     @L7A36
        jsr     L7939
        jsr     in_winrect
        beq     @L7A0F
        ldx     #$05
        bne     @L7A26

@L7A0B: lda     #$01
        bne     @L7A11

@L7A0F: lda     #$03
@L7A11: pha
        jsr     L7939
        pla
        tax
        lda     current_penloc_x+1
        cmp     $c8
        bcc     @L7A26
        bne     @L7A25
        lda     current_penloc_x
        cmp     $c7
        bcc     @L7A26
@L7A25: inx
@L7A26: lda     #$02
        bne     @L7A38

@L7A2A: jsr     get_winrect
        jsr     in_winrect
        beq     @L7A36
        lda     #$00
        beq     @L7A38

@L7A36: lda     #$03
@L7A38: jmp     L72CE

; 
; SetCtlMax
; 
which_ctl .set  $82
ctlmax  .set    $83
SetCtlMaxImpl:
        lda     which_ctl
        cmp     #$01
        bne     @L7A47
        lda     #$80
        sta     which_ctl
        bne     @L7A56

@L7A47: cmp     #$02
        bne     @L7A51
        lda     #$00
        sta     which_ctl
        beq     @L7A56

@L7A51: lda     #$a3
        jmp     exit_with_a

@L7A56: jsr     top_window
        bne     @L7A60
        lda     #$9f
        jmp     exit_with_a

@L7A60: ldy     #$06
        bit     which_ctl
        bpl     @L7A68
        ldy     #$08
@L7A68: lda     ctlmax
        sta     ($a9),y
        sta     $00ab,y
        rts

; 
; TrackThumb
; 
which_ctl .set  $82
mousex  .set    $83
mousey  .set    $85
thumbpos .set   $87
thumbmoved .set $88
TrackThumbImpl:
        lda     which_ctl
        cmp     #$01
        bne     @L7A7C
        lda     #$80
        sta     which_ctl
        bne     @L7A8B

@L7A7C: cmp     #$02
        bne     @L7A86
        lda     #$00
        sta     which_ctl
        beq     @L7A8B

@L7A86: lda     #$a3
        jmp     exit_with_a

@L7A8B: lda     which_ctl
        sta     $8c
        ldx     #$03
@L7A91: lda     mousex,x
        sta     L7561,x
        sta     L7565,x
        dex
        bpl     @L7A91
        jsr     top_window
        bne     @L7AA6
        lda     #$9f
        jmp     exit_with_a

@L7AA6: jsr     L7939
        jsr     save_params_and_stack
        jsr     set_desktop_port
        lda     #$02
        jsr     set_fill_mode
        jsr     MGTK
        .byte   $08
        .word   light_speckles_pattern
        jsr     HideCursorImpl
@L7ABD: jsr     frame_winrect
        jsr     ShowCursorImpl
@L7AC3: jsr     get_and_return_event
        cmp     #$02
        beq     @L7B2C
        jsr     L76A6
        beq     @L7AC3
        jsr     HideCursorImpl
        jsr     frame_winrect
        jsr     top_window
        jsr     L7939
        ldx     #$00
        lda     #$14
        bit     $8c
        bpl     @L7AE7
        ldx     #$02
        lda     #$0c
@L7AE7: sta     which_ctl
        lda     $c7,x
        clc
        adc     L7569,x
        tay
        lda     $c8,x
        adc     L756A,x
        cmp     L7B7F
        bcc     @L7B01
        bne     @L7B07
        cpy     L7B7E
        bcs     @L7B07
@L7B01: lda     L7B7F
        ldy     L7B7E
@L7B07: cmp     L7B7D
        bcc     @L7B19
        bne     @L7B13
        cpy     L7B7C
        bcc     @L7B19
@L7B13: lda     L7B7D
        ldy     L7B7C
@L7B19: sta     $c8,x
        tya
        sta     $c7,x
        clc
        adc     which_ctl
        sta     $cb,x
        lda     $c8,x
        adc     #$00
        sta     $cc,x
        jmp     @L7ABD

@L7B2C: jsr     HideCursorImpl
        jsr     frame_winrect
        jsr     show_cursor_and_restore
        jsr     L7B80
        jsr     L5687
        ldx     $a1
        jsr     L7BA9
        lda     $a3
        ldy     #$00
        cpx     #$01
        bcs     @L7B4D
        ldx     $a0
        jsr     L7B59
@L7B4D: ldx     #$01
        cmp     $a1
        bne     @L7B54
        dex
@L7B54: ldy     #$05
        jmp     store_xa_at_y

L7B59:  sta     which_ctl
        sty     mousex
        lda     #$80
        sta     mousex+1
        ldy     #$00
        sty     mousey
        txa
        beq     @L7B7B
@L7B68: lda     which_ctl
        clc
        adc     mousex+1
        sta     mousex+1
        lda     mousex
        adc     mousey
        sta     mousey
        bcc     @L7B78
        iny
@L7B78: dex
        bne     @L7B68
@L7B7B: rts

L7B7C:  .byte   $00
L7B7D:  .byte   $00
L7B7E:  .byte   $00
L7B7F:  .byte   $00

L7B80:  lda     L7B7C
        sec
        sbc     L7B7E
        sta     $a3
        lda     L7B7D
        sbc     L7B7F
        sta     $a4
        ldx     #$00
        bit     $8c
        bpl     @L7B99
        ldx     #$02
@L7B99: lda     $c7,x
        sec
        sbc     L7B7E
        sta     $a1
        lda     $c8,x
        sbc     L7B7F
        sta     $a2
        rts

L7BA9:  ldy     #$06
        bit     $8c
        bpl     @L7BB1
        ldy     #$08
@L7BB1: lda     ($a9),y
        sta     $a3
        iny
        lda     ($a9),y
        sta     $a1
        lda     #$00
        sta     $a2
        sta     $a4
        rts

L7BC1:  ldx     #$00
        lda     #$14
        bit     $8c
        bpl     @L7BCD
        ldx     #$02
        lda     #$0c
@L7BCD: sta     which_ctl
        lda     $c7,x
        ldy     $c8,x
        sta     L7B7E
        sty     L7B7F
        lda     $cb,x
        ldy     $cc,x
        sec
        sbc     which_ctl
        bcs     @L7BE3
        dey
@L7BE3: sta     L7B7C
        sty     L7B7D
        rts

; 
; UpdateThumb
; 
which_ctl .set  $82
thumbpos .set   $83
UpdateThumbImpl:
        lda     $8c
        cmp     #$01
        bne     @L7BF6
        lda     #$80
        sta     $8c
        bne     @L7C05

@L7BF6: cmp     #$02
        bne     @L7C00
        lda     #$00
        sta     $8c
        beq     @L7C05

@L7C00: lda     #$a3
        jmp     exit_with_a

@L7C05: jsr     top_window
        bne     @L7C0F
        lda     #$9f
        jmp     exit_with_a

@L7C0F: ldy     #$07
        bit     $8c
        bpl     @L7C17
        ldy     #$09
@L7C17: lda     $8d
        sta     ($a9),y
        jsr     hide_cursor_save_params
        jsr     set_standard_port
        jsr     L7866
        jmp     show_cursor_and_restore

; 
; KeyboardMouse
; 
KeyboardMouseImpl:
        lda     #$80
        sta     kbd_mouse_state
        jmp     FlushEventsImpl

; 
; Keyboard Mouse Data
; 
kbd_mouse_state:
        .byte   $00
kbd_mouse_x:
        .byte   $00
        .byte   $00
kbd_mouse_y:
        .res    5,$00
saved_mouse_pos:
        .res    5,$00
movement_cancel:
        .byte   $00
        .byte   $00

kbd_mouse_save_zp:
        ldx     #$7f
@L7C40: lda     params_addr,x
        sta     kbd_mouse_zp_stash,x
        dex
        bpl     @L7C40
        rts

kbd_mouse_restore_zp:
        ldx     #$7f
@L7C4B: lda     kbd_mouse_zp_stash,x
        sta     params_addr,x
        dex
        bpl     @L7C4B
        rts

kbd_mouse_zp_stash:
        .res    128,$00

set_mouse_pos:
        bit     mouse_scale_y
        bmi     no_firmware
        bit     no_mouse_flag
        bmi     no_firmware
        pha
        txa
        sec
        jsr     scale_mouse_coord
        ldx     mouse_firmware_hi
        sta     $03b8,x
        tya
        sta     $04b8,x
        pla
        ldy     #$00
        clc
        jsr     scale_mouse_coord
        ldx     mouse_firmware_hi
        sta     $0438,x
        tya
        sta     $0538,x
        ldy     #$16
        jmp     call_mouse

no_firmware:
        stx     mouse_x
        sty     mouse_x+1
        sta     mouse_y
        bit     mouse_scale_y
        bpl     not_hooked
        ldy     #$16
        jmp     call_mouse

not_hooked:
        rts

restore_mouse_pos:
        ldx     saved_mouse_pos
        ldy     saved_mouse_pos+1
        lda     saved_mouse_pos+2
        jmp     set_mouse_pos

set_mouse_pos_from_kbd_mouse:
        ldx     kbd_mouse_x
        ldy     kbd_mouse_x+1
        lda     kbd_mouse_y
        jmp     set_mouse_pos

scale_mouse_coord:
        bcc     scale_y
        ldx     mouse_scale_x
        bne     L7D3D
L7D37:  rts

scale_y:
        ldx     mouse_scale_x+1
        beq     L7D37
L7D3D:  pha
        tya
        lsr     a
        tay
        pla
        ror     a
        dex
        bne     L7D3D
        rts

kbd_mouse_to_mouse:
        ldx     #$02
@L7D49: lda     kbd_mouse_x,x
        sta     mouse_x,x
        dex
        bpl     @L7D49
        rts

position_kbd_mouse:
        jsr     kbd_mouse_to_mouse
        jmp     set_mouse_pos_from_kbd_mouse

save_mouse_pos:
        jsr     read_mouse_pos
        ldx     #$02
@L7D5E: lda     mouse_x,x
        sta     saved_mouse_pos,x
        dex
        bpl     @L7D5E
        rts

restore_cursor:
        jsr     stash_addr
        lda     kbd_mouse_cursor_stash
        sta     params_addr
        lda     kbd_mouse_cursor_stash+1
        sta     params_addr+1
        jsr     SetCursorImpl
        jsr     restore_addr
        lda     #$00
        sta     kbd_mouse_state
        lda     #$40
        sta     mouse_status
        jmp     restore_mouse_pos

kbd_mouse_init_tracking:
        lda     #$00
        sta     movement_cancel
        sta     force_tracking_change
        rts

compute_modifiers:
        lda     BUTN1
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        rts

get_key:
        jsr     compute_modifiers
        sta     set_input_modifiers
get_key_no_modifiers:
        clc
        lda     KBD
        bpl     @L7DAF
        stx     KBDSTRB
        and     #$7f
        sec
@L7DAF: rts

handle_keyboard_mouse:
        lda     kbd_mouse_state
        bne     @L7DB6
        rts

@L7DB6: cmp     #$04
        beq     kbd_mouse_mousekeys
        jsr     kbd_mouse_sync_cursor
        lda     kbd_mouse_state
        cmp     #$01
        bne     @L7DC7
        jmp     kbd_mouse_do_menu

@L7DC7: jmp     kbd_mouse_do_window

stash_cursor:
        jsr     stash_addr
        lda     active_cursor+1
        sta     kbd_mouse_cursor_stash
        lda     active_cursor+2
        sta     kbd_mouse_cursor_stash+1
        lda     pointer_cursor_addr
        sta     params_addr
        lda     pointer_cursor_addr+1
        sta     params_addr+1
        jsr     SetCursorImpl
        jmp     restore_addr

kbd_mouse_cursor_stash:
        .byte   $00
        .byte   $00

stash_addr:
        lda     params_addr
        sta     stashed_addr
        lda     params_addr+1
        sta     stashed_addr+1
        rts

restore_addr:
        lda     stashed_addr
        sta     params_addr
        lda     stashed_addr+1
        sta     params_addr+1
        rts

stashed_addr:
        .byte   $00
        .byte   $00

kbd_mouse_mousekeys:
        jsr     compute_modifiers
        ror     a
        ror     a
        ror     movement_cancel+1
        lda     movement_cancel+1
        sta     mouse_status
        lda     #$00
        sta     input_modifiers
        jsr     get_key_no_modifiers
        bcc     @L7E1E
        jmp     mousekeys_input

@L7E1E: jmp     position_kbd_mouse

activate_keyboard_mouse:
        pha
        lda     kbd_mouse_state
        bne     in_kbd_mouse
        pla
        cmp     #$03
        bne     L7E5D
        bit     mouse_status
        bmi     L7E5D
        lda     #$04
        sta     kbd_mouse_state
        ldx     #$0a
beeploop:
        lda     SPKR
        ldy     #$00
@L7E3D: dey
        bne     @L7E3D
        dex
        bpl     beeploop
waitloop:
        jsr     compute_modifiers
        cmp     #$03
        beq     waitloop
        sta     input_modifiers
        lda     #$00
        sta     movement_cancel+1
        ldx     #$02
@L7E54: lda     set_pos_params,x
        sta     kbd_mouse_x,x
        dex
        bpl     @L7E54
L7E5D:  rts

in_kbd_mouse:
        cmp     #$04
        bne     @L7E6D
        pla
        and     #$01
        bne     @L7E6C
        lda     #$00
        sta     kbd_mouse_state
@L7E6C: rts

@L7E6D: pla
        rts

kbd_mouse_sync_cursor:
        bit     mouse_status
        bpl     @L7E7C
        lda     #$00
        sta     kbd_mouse_state
        jmp     set_mouse_pos_from_kbd_mouse

@L7E7C: lda     mouse_status
        pha
        lda     #$c0
        sta     mouse_status
        pla
        and     #$20
        beq     @L7E99
        ldx     #$02
@L7E8C: lda     mouse_x,x
        sta     kbd_mouse_x,x
        dex
        bpl     @L7E8C
        stx     kbd_mouse_y+2
        rts

@L7E99: jmp     kbd_mouse_to_mouse

kbd_menu_select:
        php
        sei
        jsr     save_mouse_pos
        lda     #$01
        sta     kbd_mouse_state
        jsr     position_menu_item
        lda     #$80
        sta     mouse_status
        jsr     stash_cursor
        ldx     kbd_mouse_y+3
        jsr     get_menu
        lda     $af
        sta     cur_open_menu
        jsr     draw_menu
        lda     saved_mouse_pos-1
        sta     cur_hilited_menu_item
        jsr     hilite_menu_item
        plp
        rts

position_menu_item:
        ldx     kbd_mouse_y+3
        jsr     get_menu
        clc
        lda     $b7
        adc     #$05
        sta     kbd_mouse_x
        lda     $b8
        adc     #$00
        sta     kbd_mouse_x+1
        ldy     saved_mouse_pos-1
        lda     menu_item_y_table,y
        sta     kbd_mouse_y
        lda     #$c0
        sta     mouse_status
        jmp     position_kbd_mouse

kbd_menu_select_item:
        bit     kbd_mouse_y+2
        bpl     @L7F07
        lda     cur_hilited_menu_item
        sta     saved_mouse_pos-1
        ldx     cur_open_menu
        dex
        stx     kbd_mouse_y+3
        lda     #$00
        sta     kbd_mouse_y+2
@L7F07: rts

kbd_mouse_do_menu:
        jsr     kbd_mouse_save_zp
        jsr     @L7F11
        jmp     kbd_mouse_restore_zp

@L7F11: jsr     get_key
        bcs     handle_menu_key
        rts

handle_menu_key:
        pha
        jsr     kbd_menu_select_item
        pla
        cmp     #$1b
        bne     @L7F2E
        lda     #$00
        sta     movement_cancel-1
        sta     saved_mouse_pos+3
        lda     #$80
        sta     movement_cancel
        rts

@L7F2E: cmp     #$0d
        bne     @L7F38
        jsr     kbd_mouse_to_mouse
        jmp     restore_cursor

@L7F38: cmp     #$0b
        bne     @L7F5E
@L7F3C: dec     saved_mouse_pos-1
        bpl     @L7F4C
        ldx     kbd_mouse_y+3
        jsr     get_menu
        ldx     $aa
        stx     saved_mouse_pos-1
@L7F4C: ldx     saved_mouse_pos-1
        beq     @L7F5B
        dex
        jsr     get_menu_item
        lda     $bf
        and     #$c0
        bne     @L7F3C
@L7F5B: jmp     position_menu_item

@L7F5E: cmp     #$0a
        bne     @L7F8B
@L7F62: inc     saved_mouse_pos-1
        ldx     kbd_mouse_y+3
        jsr     get_menu
        lda     saved_mouse_pos-1
        cmp     $aa
        bcc     @L7F79
        beq     @L7F79
        lda     #$00
        sta     saved_mouse_pos-1
@L7F79: ldx     saved_mouse_pos-1
        beq     @L7F88
        dex
        jsr     get_menu_item
        lda     $bf
        and     #$c0
        bne     @L7F62
@L7F88: jmp     position_menu_item

@L7F8B: cmp     #$15
        bne     @L7FA6
        lda     #$00
        sta     saved_mouse_pos-1
        inc     kbd_mouse_y+3
        lda     kbd_mouse_y+3
        cmp     $a8
        bcc     @L7FA3
        lda     #$00
        sta     kbd_mouse_y+3
@L7FA3: jmp     position_menu_item

@L7FA6: cmp     #$08
        bne     @L7FC0
        lda     #$00
        sta     saved_mouse_pos-1
        dec     kbd_mouse_y+3
        bmi     @L7FB7
        jmp     position_menu_item

@L7FB7: ldx     $a8
        dex
        stx     kbd_mouse_y+3
        jmp     position_menu_item

@L7FC0: jsr     kbd_menu_by_shortcut
        bcc     @L7FCA
        lda     #$80
        sta     movement_cancel
@L7FCA: rts

kbd_menu_by_shortcut:
        sta     $c9
        lda     set_input_modifiers
        and     #$03
        sta     $ca
        lda     cur_open_menu
        pha
        lda     cur_hilited_menu_item
        pha
        lda     #$c0
        jsr     find_menu
        beq     @L7FF8
        stx     movement_cancel-1
        lda     $b0
        bmi     @L7FF8
        lda     $bf
        and     #$c0
        bne     @L7FF8
        lda     $af
        sta     saved_mouse_pos+3
        sec
        bcs     @L7FF9

@L7FF8: clc
@L7FF9: pla
        sta     cur_hilited_menu_item
        pla
        sta     cur_open_menu
        sta     $c7
        rts

kbd_menu_return:
        plp
        sei
        jsr     hide_menu
        jsr     restore_cursor
        lda     saved_mouse_pos+3
        sta     $c7
        sta     cur_open_menu
        lda     movement_cancel-1
        sta     $c8
        sta     cur_hilited_menu_item
        jsr     restore_params_active_port
        lda     saved_mouse_pos+3
        beq     @L802A
        jsr     HiliteMenuImpl
        lda     saved_mouse_pos+3
@L802A: sta     cur_open_menu
        ldx     movement_cancel-1
        stx     cur_hilited_menu_item
        plp
        jmp     store_xa_at_params

kbd_win_drag_or_grow:
        php
        sei
        jsr     save_mouse_pos
        lda     #$80
        sta     mouse_status
        jsr     get_winframerect
        bit     GrowWindowImpl-1
        bpl     @L809F
        lda     $ac
        and     #$04
        beq     @L8094
        ldx     #$00
@L8051: sec
        lda     $cb,x
        sbc     #$04
        sta     kbd_mouse_x,x
        sta     L7561,x
        sta     L7565,x
        lda     $cc,x
        sbc     #$00
        sta     kbd_mouse_x+1,x
        sta     L7562,x
        sta     L7566,x
        inx
        inx
        cpx     #$04
        bcc     @L8051
        sec
        lda     #$2f
        sbc     L7561
        lda     #$02
        sbc     L7562
        bmi     @L8094
        sec
        lda     #$bf
        sbc     L7563
        lda     #$00
        sbc     L7564
        bmi     @L8094
        jsr     position_kbd_mouse
        jsr     stash_cursor
        plp
        rts

@L8094: lda     #$00
        sta     kbd_mouse_state
        lda     #$a1
        plp
        jmp     exit_with_a

@L809F: lda     $ac
        and     #$01
        beq     @L80AF
        lda     #$00
        sta     kbd_mouse_state
        lda     #$a0
        jmp     exit_with_a

@L80AF: ldx     #$00
@L80B1: clc
        lda     $c7,x
        cpx     #$02
        beq     @L80BD
        adc     #$14
        jmp     @L80BF

@L80BD: adc     #$05
@L80BF: sta     kbd_mouse_x,x
        sta     L7561,x
        sta     L7565,x
        lda     $c8,x
        adc     #$00
        sta     kbd_mouse_x+1,x
        sta     L7562,x
        sta     L7566,x
        inx
        inx
        cpx     #$04
        bcc     @L80B1
        bit     kbd_mouse_x+1
        bpl     @L80F0
        ldx     #$01
        lda     #$00
@L80E4: sta     kbd_mouse_x,x
        sta     L7561,x
        sta     L7565,x
        dex
        bpl     @L80E4
@L80F0: jsr     position_kbd_mouse
        jsr     stash_cursor
        plp
        rts

kbd_mouse_add_to_y:
        php
        clc
        adc     kbd_mouse_y
        sta     kbd_mouse_y
        plp
        bpl     @L810F
        cmp     #$c0
        bcc     @L810C
        lda     #$00
        sta     kbd_mouse_y
@L810C: jmp     position_kbd_mouse

@L810F: cmp     #$c0
        bcc     @L810C
        lda     #$bf
        sta     kbd_mouse_y
        bne     @L810C

kbd_mouse_do_window:
        jsr     kbd_mouse_save_zp
        jsr     @L8123
        jmp     kbd_mouse_restore_zp

@L8123: jsr     get_key
        bcs     @L8129
        rts

@L8129: cmp     #$1b
        bne     @L8135
        lda     #$80
        sta     movement_cancel
        jmp     restore_cursor

@L8135: cmp     #$0d
        bne     @L813C
        jmp     restore_cursor

@L813C: pha
        lda     set_input_modifiers
        beq     @L8147
        ora     #$80
        sta     set_input_modifiers
@L8147: pla
        ldx     #$c0
        stx     mouse_status
mousekeys_input:
        cmp     #$0b
        bne     @L815D
        lda     #$f8
        bit     set_input_modifiers
        bpl     @L815A
        lda     #$d0
@L815A: jmp     kbd_mouse_add_to_y

@L815D: cmp     #$0a
        bne     @L816D
        lda     #$08
        bit     set_input_modifiers
        bpl     @L816A
        lda     #$30
@L816A: jmp     kbd_mouse_add_to_y

@L816D: cmp     #$15
        bne     @L81A8
        jsr     kbd_mouse_check_xmax
        bcc     @L81A5
        clc
        lda     #$08
        bit     set_input_modifiers
        bpl     @L8180
        lda     #$40
@L8180: adc     kbd_mouse_x
        sta     kbd_mouse_x
        lda     kbd_mouse_x+1
        adc     #$00
        sta     kbd_mouse_x+1
        sec
        lda     kbd_mouse_x
        sbc     #$2f
        lda     kbd_mouse_x+1
        sbc     #$02
        bmi     @L81A5
        lda     #$02
        sta     kbd_mouse_x+1
        lda     #$2f
        sta     kbd_mouse_x
@L81A5: jmp     position_kbd_mouse

@L81A8: cmp     #$08
        bne     @L81D8
        jsr     kbd_mouse_check_xmin
        bcc     @L81D5
        lda     kbd_mouse_x
        bit     set_input_modifiers
        bpl     @L81BE
        sbc     #$40
        jmp     @L81C0

@L81BE: sbc     #$08
@L81C0: sta     kbd_mouse_x
        lda     kbd_mouse_x+1
        sbc     #$00
        sta     kbd_mouse_x+1
        bpl     @L81D5
        lda     #$00
        sta     kbd_mouse_x
        sta     kbd_mouse_x+1
@L81D5: jmp     position_kbd_mouse

@L81D8: sta     set_input_params+1
        ldx     #$23
@L81DD: lda     $a7,x
        sta     $0600,x
        dex
        bpl     @L81DD
        lda     set_input_params+1
        jsr     kbd_menu_by_shortcut
        php
        ldx     #$23
@L81EE: lda     $0600,x
        sta     $a7,x
        dex
        bpl     @L81EE
        plp
        bcc     @L8201
        lda     #$40
        sta     movement_cancel
        jmp     restore_cursor

@L8201: rts

set_input:
        jsr     MGTK
        .byte   $2c
        .word   set_input_params
        rts

set_input_params:
        .byte   $03
        .byte   $00
set_input_modifiers:
        .byte   $00
force_tracking_change:
        .byte   $00

kbd_mouse_check_xmin:
        lda     kbd_mouse_state
        cmp     #$04
        beq     @L8223
        lda     kbd_mouse_x
        bne     @L8223
        lda     kbd_mouse_x+1
        bne     @L8223
        bit     GrowWindowImpl-1
        bpl     @L8225
@L8223: sec
        rts

@L8225: jsr     get_winframerect
        lda     $cc
        bne     @L823B
        lda     #$09
        bit     set_input_modifiers
        bpl     @L8235
        lda     #$41
@L8235: cmp     $cb
        bcc     @L823B
        clc
        rts

@L823B: inc     force_tracking_change
        clc
        lda     #$08
        bit     set_input_modifiers
        bpl     @L8248
        lda     #$40
@L8248: adc     L7561
        sta     L7561
        bcc     @L8253
        inc     L7562
@L8253: clc
        rts

kbd_mouse_check_xmax:
        lda     kbd_mouse_state
        cmp     #$04
        beq     @L826E
        bit     GrowWindowImpl-1
        bmi     @L826E
        lda     kbd_mouse_x
        sbc     #$2f
        lda     kbd_mouse_x+1
        sbc     #$02
        beq     @L8270
        sec
@L826E: sec
        rts

@L8270: jsr     get_winframerect
        sec
        lda     #$2f
        sbc     $c7
        tax
        lda     #$02
        sbc     $c8
        beq     @L8281
        ldx     #$ff
@L8281: bit     set_input_modifiers
        bpl     @L828C
        cpx     #$55
        bcc     @L8292
        bcs     @L8294

@L828C: cpx     #$1d
        bcc     @L8292
        bcs     @L829D

@L8292: clc
        rts

@L8294: sec
        lda     L7561
        sbc     #$40
        jmp     @L82A3

@L829D: sec
        lda     L7561
        sbc     #$08
@L82A3: sta     L7561
        bcs     @L82AB
        dec     L7562
@L82AB: inc     force_tracking_change
        clc
        rts

grew_flag:
        .byte   $00

set_grew_flag:
        lda     #$80
        sta     grew_flag
L82B6:  rts

finish_grow:
        bit     kbd_mouse_state
        bpl     L82B6
        bit     grew_flag
        bpl     L82B6
        jsr     get_winframerect
        php
        sei
        ldx     #$00
@L82C8: sec
        lda     $cb,x
        sbc     #$04
        sta     kbd_mouse_x,x
        lda     $cc,x
        sbc     #$00
        sta     kbd_mouse_x+1,x
        inx
        inx
        cpx     #$04
        bcc     @L82C8
        jsr     position_kbd_mouse
        plp
        rts

; 
; ScaleMouse
; 
x_exponent .set $82
y_exponent .set $83
ScaleMouseImpl:
        lda     x_exponent
        sta     mouse_scale_x
        lda     y_exponent
        sta     mouse_scale_x+1
L82EC:  bit     no_mouse_flag
        bmi     @L8367
        lda     mouse_scale_x
        asl     a
        tay
        lda     #$00
        sta     mouse_x
        sta     mouse_x+1
        bit     mouse_scale_y
        bmi     @L8309
        sta     SCRNHOLE0
        sta     SCRNHOLE2
@L8309: lda     clamp_x_table,y
        sta     mouse_y
        bit     mouse_scale_y
        bmi     @L8317
        sta     SCRNHOLE1
@L8317: lda     clamp_x_table+1,y
        sta     mouse_y+1
        bit     mouse_scale_y
        bmi     @L8325
        sta     SCRNHOLE3
@L8325: lda     #$00
        ldy     #$17
        jsr     call_mouse
        lda     mouse_scale_x+1
        asl     a
        tay
        lda     #$00
        sta     mouse_x
        sta     mouse_x+1
        bit     mouse_scale_y
        bmi     @L8344
        sta     SCRNHOLE0
        sta     SCRNHOLE2
@L8344: lda     clamp_y_table,y
        sta     mouse_y
        bit     mouse_scale_y
        bmi     @L8352
        sta     SCRNHOLE1
@L8352: lda     clamp_y_table+1,y
        sta     mouse_y+1
        bit     mouse_scale_y
        bmi     @L8360
        sta     SCRNHOLE3
@L8360: lda     #$01
        ldy     #$17
        jsr     call_mouse
@L8367: rts

clamp_x_table:
        .word   559
        .word   279
        .word   139
        .word   69
clamp_y_table:
        .word   191
        .word   95
        .word   47
        .word   23

; 
; Update Mouse Slot
; 
find_mouse:
        txa
        and     #$7f
        beq     @L8388
        jsr     check_mouse_in_a
        sta     no_mouse_flag
        beq     @L8399
        ldx     #$00
        rts

@L8388: ldx     #$07
@L838A: txa
        jsr     check_mouse_in_a
        sta     no_mouse_flag
        beq     @L8399
        dex
        bpl     @L838A
        ldx     #$00
        rts

@L8399: ldy     #$19
        jsr     call_mouse
        jsr     L82EC
        ldy     #$18
        jsr     call_mouse
        lda     mouse_firmware_hi
        and     #$0f
        tax
        rts

check_mouse_in_a:
        ora     #$c0
        sta     $89
        lda     #$00
        sta     $88
        ldy     #$0c
        lda     ($88),y
        cmp     #$20
        bne     @L83D4
        ldy     #$fb
        lda     ($88),y
        cmp     #$d6
        bne     @L83D4
        lda     $89
        sta     mouse_firmware_hi
        asl     a
        asl     a
        asl     a
        asl     a
        sta     mouse_operand
        lda     #$00
        rts

@L83D4: lda     #$80
        rts

no_mouse_flag:
        .byte   $00
mouse_firmware_hi:
        .byte   $00
mouse_operand:
        .byte   $00
