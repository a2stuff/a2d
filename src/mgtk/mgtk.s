;;; ============================================================
;;; MouseGraphics ToolKit
;;; ============================================================

.scope mgtk
        MGTKEntry := *

kScreenWidth    = 560
kScreenHeight   = 192

;;; ============================================================

;;; ZP Usage

        params_addr     := $80

        ;; $8A initialized same way as current port (see $01 IMPL)


        ;; $A8          - Menu count

        ;; $A9-$AA      - Address of current winfo
        ;; $AB-...      - Copy of first 12 bytes of current winfo

        ;; $D0-$F3      - Current GrafPort
        ;;  $D0-$DF      - portmap
        ;;   $D0-D3       - viewloc (x/y words)
        ;;   $D4-D5       - mapbits - screen address = $2000
        ;;   $D6-D7       - mapwidth - screen stride = $80
        ;;   $D8-DF       - maprect (x1/y1/x2/y2)
        ;;  $E0-$E7      - penpattern
        ;;  $E8-$E9      - colormasks (AND, OR)
        ;;  $EA-$ED      - penloc (x/y words)
        ;;  $EE-$EF      - penwidth/penheight
        ;;  $F0          - penmode
        ;;  $F1          - textback
        ;;  $F2-$F3      - textfont

        ;;  $F4-$F5      - Active port (???)
        ;;  $F6-$FA      - fill_eor_mask/x_offset/y_offset
        ;;  $FB-$FC      - glyph widths
        ;;  $FD          - font type (0=regular, $80=double width)
        ;;  $FE          - last glyph index (count is this + 1)
        ;;  $FF          - glyph height

        current_grafport          := $D0
        current_portmap           := $D0
        current_viewloc_x         := $D0
        current_viewloc_y         := $D2
        current_mapbits           := $D4
        current_mapwidth          := $D6
        current_maprect_x1        := $D8
        current_maprect_y1        := $DA
        current_maprect_x2        := $DC
        current_maprect_y2        := $DE
        current_penpattern        := $E0
        current_colormasks        := $E8
        current_colormask_and     := $E8
        current_colormasks_or     := $E9
        current_penloc            := $EA
        current_penloc_x          := $EA
        current_penloc_y          := $EC
        current_pensize           := $EE
        current_penwidth          := $EE
        current_penheight         := $EF
        current_penmode           := $F0
        current_textback          := $F1
        current_textfont          := $F2

        active_port     := $F4  ; address of live port block

        fill_eor_mask   := $F6
        x_offset        := $F7
        y_offset        := $F9

        glyph_widths    := $FB  ; address
        glyph_type      := $FD  ; 0=regular, $80=double width
        glyph_last      := $FE  ; last glyph index
        glyph_height_p  := $FF  ; glyph height


;;; ============================================================
;;; MGTK

.proc Dispatch
        lda     LOWSCR
        sta     SET80STORE

        bit     preserve_zp_flag ; save ZP?
        bpl     adjust_stack

        ;; Save $80...$FF, swap in what MGTK needs at $F4...$FF
        COPY_BYTES $80, $80, zp_saved
        COPY_BYTES $C, active_saved, active_port
        jsr     ApplyActivePortToPort

adjust_stack:                   ; Adjust stack to account for params
        pla                     ; and stash address at params_addr.
        sta     params_addr
        clc
        adc     #<3
        tax
        pla
        sta     params_addr+1
        adc     #>3
        phax

        tsx
        stx     stack_ptr_stash

        ldy     #1              ; Command index
        lda     (params_addr),y
        asl     a
        tax
        copy16  jump_table,x, jump_addr
                                ; not copylohi because parm table
                                ; is cleaner as words not bytes
        iny                     ; Point params_addr at params
        lda     (params_addr),y
        pha
        iny
        lda     (params_addr),y
        sta     params_addr+1
        pla
        sta     params_addr

        ;; Param length format is a byte pair;
        ;; * first byte is ZP address to copy bytes to
        ;; * second byte's high bit is "hide cursor" flag
        ;; * rest of second byte is # bytes to copy

        ldy     param_lengths+1,x ; Check param length...
        bpl     done_hiding

        bit     desktop_initialized_flag
        bpl     done_hiding
        txa                     ; if high bit was set, stash
        pha                     ; registers and params_addr and then
        tya                     ; hide cursor
        pha
        lda     params_addr
        pha
        lda     params_addr+1
        pha
        jsr     HideCursor
        pla
        sta     params_addr+1
        pla
        sta     params_addr
        pla
        and     #$7F            ; clear high bit in length count
        tay
        pla
        tax

done_hiding:
        lda     param_lengths,x ; ZP offset for params
        beq     jump            ; nothing to copy
        sta     store+1
        dey
:       lda     (params_addr),y
store:  sta     $FF,y           ; self modified
        dey
        bpl     :-

        jump_addr := *+1
jump:   jsr     $FFFF           ; the actual call

        ;; Exposed for routines to call directly
cleanup:
        bit     desktop_initialized_flag
    IF NS
        jsr     ShowCursor
    END_IF

        bit     preserve_zp_flag
    IF NS
        jsr     ApplyPortToActivePort
        COPY_BYTES $C, active_port, active_saved
        COPY_BYTES $80, zp_saved, $80
    END_IF

        ;; default is to return with A=0
exit_with_0:
        lda     #0

rts1:   rts
.endproc ; Dispatch

;;; ============================================================
;;; Routines can jmp here to exit with A set

exit_with_a:
        pha
        jsr     Dispatch::cleanup
        pla
        ldx     stack_ptr_stash
        txs
        ldy     #$FF
rts2:   rts

        ;; Macro for exit_with_a

.macro EXIT_CALL arg
        lda     #arg
        jmp     exit_with_a
.endmacro

;;; ============================================================
;;; Copy port params (36 bytes) to/from active port addr

.proc ApplyActivePortToPort
        ldy     #.sizeof(MGTK::GrafPort)-1
:       lda     (active_port),y
        sta     current_grafport,y
        dey
        bpl     :-
        rts
.endproc ; ApplyActivePortToPort

.proc ApplyPortToActivePort
        ldy     #.sizeof(MGTK::GrafPort)-1
:       lda     current_grafport,y
        sta     (active_port),y
        dey
        bpl     :-
        rts
.endproc ; ApplyPortToActivePort

;;; ============================================================
;;; Drawing calls show/hide cursor before/after
;;; A recursion count is kept to allow re-entrancy.

hide_cursor_count:
        .byte   0

.proc HideCursor
        dec     hide_cursor_count
        jmp     HideCursorImpl
.endproc ; HideCursor

.proc ShowCursor
        bit     hide_cursor_count
        bpl     rts2
        inc     hide_cursor_count
        jmp     ShowCursorImpl
.endproc ; ShowCursor

;;; ============================================================
;;; Jump table for MGTK entry point calls

        ;; jt_rts can be used if the only thing the
        ;; routine needs to do is copy params into
        ;; the zero page (port)
        jt_rts := Dispatch::rts1

jump_table:
        .addr   jt_rts              ; $00 NoOp

        ;; ----------------------------------------
        ;; Graphics Primitives


        ;; Initialization Commands
        .addr   InitGrafImpl        ; $01 InitGraf
        .addr   SetSwitchesImpl     ; $02 SetSwitches

        ;; GrafPort Commands
        .addr   InitPortImpl        ; $03 InitPort
        .addr   SetPortImpl         ; $04 SetPort
        .addr   GetPortImpl         ; $05 GetPort
        .addr   SetPortBitsImpl     ; $06 SetPortBits
        .addr   SetPenModeImpl      ; $07 SetPenMode
        .addr   SetPatternImpl      ; $08 SetPattern
        .addr   jt_rts              ; $09 SetColorMasks
        .addr   jt_rts              ; $0A SetPenSize
        .addr   SetFontImpl         ; $0B SetFont
        .addr   jt_rts              ; $0C SetTextBG

        ;; Drawing Commands
        .addr   MoveImpl            ; $0D Move
        .addr   jt_rts              ; $0E MoveTo
        .addr   LineImpl            ; $0F Line
        .addr   LineToImpl          ; $10 LineTo
        .addr   PaintRectImpl       ; $11 PaintRect
        .addr   FrameRectImpl       ; $12 FrameRect
        .addr   InRectImpl          ; $13 InRect
        .addr   PaintBitsImpl       ; $14 PaintBits
        .addr   PaintPolyImpl       ; $15 PaintPoly
        .addr   FramePolyImpl       ; $16 FramePoly
        .addr   InPolyImpl          ; $17 InPoly

        ;; Text Commands
        .addr   TextWidthImpl       ; $18 TextWidth
        .addr   DrawTextImpl        ; $19 DrawText

        ;; Utility Commands
        .addr   SetZP1Impl          ; $1A SetZP1
        .addr   SetZP2Impl          ; $1B SetZP2
        .addr   VersionImpl         ; $1C Version

        ;; ----------------------------------------
        ;; MouseGraphics ToolKit

        ;; Initialization Calls
        .addr   StartDeskTopImpl    ; $1D StartDeskTop
        .addr   StopDeskTopImpl     ; $1E StopDeskTop
        .addr   SetUserHookImpl     ; $1F SetUserHook
        .addr   AttachDriverImpl    ; $20 AttachDriver
        .addr   ScaleMouseImpl      ; $21 ScaleMouseImpl
        .addr   KeyboardMouse       ; $22 KeyboardMouse
        .addr   GetIntHandlerImpl   ; $23 GetIntHandler

        ;; Cursor Manager Calls
        .addr   SetCursorImpl       ; $24 SetCursor
        .addr   ShowCursorImpl      ; $25 ShowCursor
        .addr   HideCursorImpl      ; $26 HideCursor
        .addr   ObscureCursorImpl   ; $27 ObscureCursor
        .addr   GetCursorAdrImpl    ; $28 GetCursorAdr

        ;; Event Manager Calls
        .addr   CheckEventsImpl     ; $29 CheckEvents
        .addr   GetEventImpl        ; $2A GetEvent
        .addr   FlushEventsImpl     ; $2B FlushEvents
        .addr   PeekEventImpl       ; $2C PeekEvent
        .addr   PostEventImpl       ; $2D PostEvent
        .addr   SetKeyEventImpl     ; $2E SetKeyEvent

        ;; Menu Manager Calls
        .addr   InitMenuImpl        ; $2F InitMenu
        .addr   SetMenuImpl         ; $30 SetMenu
        .addr   MenuSelectImpl      ; $31 MenuSelect
        .addr   MenuKeyImpl         ; $32 MenuKey
        .addr   HiliteMenuImpl      ; $33 HiliteMenu
        .addr   DisableMenuImpl     ; $34 DisableMenu
        .addr   DisableItemImpl     ; $35 DisableItem
        .addr   CheckItemImpl       ; $36 CheckItem
        .addr   SetMarkImpl         ; $37 SetMark

        ;; Window Manager Calls
        .addr   OpenWindowImpl      ; $38 OpenWindow
        .addr   CloseWindowImpl     ; $39 CloseWindow
        .addr   CloseAllImpl        ; $3A CloseAll
        .addr   GetWinPtrImpl       ; $3B GetWinPtr
        .addr   GetWinPortImpl      ; $3C GetWinPort
        .addr   SetWinPortImpl      ; $3D SetWinPort
        .addr   BeginUpdateImpl     ; $3E BeginUpdate
        .addr   EndUpdateImpl       ; $3F EndUpdate
        .addr   FindWindowImpl      ; $40 FindWindow
        .addr   FrontWindowImpl     ; $41 FrontWindow
        .addr   SelectWindowImpl    ; $42 SelectWindow
        .addr   TrackGoAwayImpl     ; $43 TrackGoAway
        .addr   DragWindowImpl      ; $44 DragWindow
        .addr   GrowWindowImpl      ; $45 GrowWindow
        .addr   ScreenToWindowImpl  ; $46 ScreenToWindow
        .addr   WindowToScreenImpl  ; $47 WindowToScreenImpl

        ;; Control Manager Calls
        .addr   FindControlImpl     ; $48 FindControl
        .addr   SetCtlMaxImpl       ; $49 SetCtlMax
        .addr   TrackThumbImpl      ; $4A TrackThumb
        .addr   UpdateThumbImpl     ; $4B UpdateThumb
        .addr   ActivateCtlImpl     ; $4C ActivateCtl

        ;; ----------------------------------------
        ;; Extra Calls
        .addr   BitBltImpl          ; $4D BitBlt
        .addr   GetDeskPatImpl      ; $4E GetDeskPat
        .addr   SetDeskPatImpl      ; $4F SetDeskPat
        .addr   DrawMenuImpl        ; $50 DrawMenuBar
        .addr   GetWinFrameRectImpl ; $51 GetWinFrameRect
        .addr   RedrawDeskTopImpl   ; $52 RedrawDeskTop
        .addr   FindControlExImpl   ; $53 FindControlEx
        .addr   PaintBitsImpl       ; $54 PaintBitsHC
        .addr   FlashMenuBarImpl    ; $55 FlashMenuBar
        .addr   SaveScreenRectImpl  ; $56 SaveScreenRect
        .addr   RestoreScreenRectImpl ; $57 RestoreScreenRect
        .addr   InflateRectImpl     ; $58 InflateRect
        .addr   UnionRectsImpl      ; $59 UnionRects
        .addr   MulDivImpl          ; $5A MulDiv
        .addr   ShieldCursorImpl    ; $5B ShieldCursor
        .addr   UnshieldCursorImpl  ; $5C UnshieldCursor

        ;; Entry point param lengths
        ;; (length, ZP destination, hide cursor flag)
param_lengths:

.macro PARAM_DEFN length, zp, cursor
        .byte zp, ((length) | ((cursor) << 7))
.endmacro

        ;; ----------------------------------------
        ;; Graphics Primitives
        PARAM_DEFN  0, $00, 0                ; $00 NoOp

        ;; Initialization
        PARAM_DEFN  0, $00, 0                ; $01 InitGraf
        PARAM_DEFN  1, $82, 0                ; $02 SetSwitches

        ;; GrafPort
        PARAM_DEFN  0, $00, 0                ; $03 InitPort
        PARAM_DEFN 36, current_grafport, 0   ; $04 SetPort
        PARAM_DEFN  0, $00, 0                ; $05 GetPort
        PARAM_DEFN 16, current_portmap, 0    ; $06 SetPortBits
        PARAM_DEFN  1, current_penmode, 0    ; $07 SetPenMode
        PARAM_DEFN  8, current_penpattern, 0 ; $08 SetPattern
        PARAM_DEFN  2, current_colormasks, 0 ; $09 SetColorMasks
        PARAM_DEFN  2, current_pensize, 0    ; $0A SetPenSize
        PARAM_DEFN  0, $00, 0                ; $0B SetFont
        PARAM_DEFN  1, current_textback, 0   ; $0C SetTextBG

        ;; Drawing
        PARAM_DEFN  4, $A1, 0                ; $0D Move
        PARAM_DEFN  4, current_penloc, 0     ; $0E MoveTo
        PARAM_DEFN  4, $A1, 1                ; $0F Line
        PARAM_DEFN  4, $92, 1                ; $10 LineTo
        PARAM_DEFN  8, $92, 1                ; $11 PaintRect
        PARAM_DEFN  8, $9F, 1                ; $12 FrameRect
        PARAM_DEFN  8, $92, 0                ; $13 InRect
        PARAM_DEFN 16, $8A, 0                ; $14 PaintBits
        PARAM_DEFN  0, $00, 1                ; $15 PaintPoly
        PARAM_DEFN  0, $00, 1                ; $16 FramePoly
        PARAM_DEFN  0, $00, 0                ; $17 InPoly

        ;; Text
        PARAM_DEFN  3, $A1, 0                ; $18 TextWidth
        PARAM_DEFN  3, $A1, 1                ; $19 DrawText

        ;; Utility
        PARAM_DEFN  1, $82, 0                ; $1A SetZP1
        PARAM_DEFN  1, $82, 0                ; $1B SetZP2
        PARAM_DEFN  0, $00, 0                ; $1C Version

        ;; ----------------------------------------
        ;; MouseGraphics ToolKit Calls

        ;; Initialization
        PARAM_DEFN 12, $82, 0                ; $1D StartDeskTop
        PARAM_DEFN  0, $00, 0                ; $1E StopDeskTop
        PARAM_DEFN  3, $82, 0                ; $1F SetUserHook
        PARAM_DEFN  2, $82, 0                ; $20 AttachDriver
        PARAM_DEFN  2, $82, 0                ; $21 ScaleMouse
        PARAM_DEFN  0, $00, 0                ; $22 KeyboardMouse
        PARAM_DEFN  0, $00, 0                ; $23 GetIntHandler

        ;; Cursor Manager
        PARAM_DEFN  0, $00, 0                ; $24 SetCursor
        PARAM_DEFN  0, $00, 0                ; $25 ShowCursor
        PARAM_DEFN  0, $00, 0                ; $26 HideCursor
        PARAM_DEFN  0, $00, 0                ; $27 ObscureCursor
        PARAM_DEFN  0, $00, 0                ; $28 GetCursorAdr

        ;; Event Manager
        PARAM_DEFN  0, $00, 0                ; $29 CheckEvents
        PARAM_DEFN  0, $00, 0                ; $2A GetEvent
        PARAM_DEFN  0, $00, 0                ; $2B FlushEvents
        PARAM_DEFN  0, $00, 0                ; $2C PeekEvent
        PARAM_DEFN  5, $82, 0                ; $2D PostEvent
        PARAM_DEFN  1, $82, 0                ; $2E SetKeyEvent

        ;; Menu Manager
        PARAM_DEFN  4, $82, 0                ; $2F InitMenu
        PARAM_DEFN  0, $00, 0                ; $30 SetMenu
        PARAM_DEFN  0, $00, 0                ; $31 MenuSelect
        PARAM_DEFN  4, $C7, 0                ; $32 MenuKey
        PARAM_DEFN  1, $C7, 0                ; $33 HiliteMenu
        PARAM_DEFN  2, $C7, 0                ; $34 DisableMenu
        PARAM_DEFN  3, $C7, 0                ; $35 DisableItem
        PARAM_DEFN  3, $C7, 0                ; $36 CheckItem
        PARAM_DEFN  4, $C7, 0                ; $37 SetMark

        ;; Window Manager
        PARAM_DEFN  0, $00, 0                ; $38 OpenWindow
        PARAM_DEFN  1, $82, 0                ; $39 CloseWindow
        PARAM_DEFN  0, $00, 0                ; $3A CloseAll
        PARAM_DEFN  1, $82, 0                ; $3B GetWinPtr
        PARAM_DEFN  3, $82, 0                ; $3C GetWinPort
        PARAM_DEFN  2, $82, 0                ; $3D SetWinPort
        PARAM_DEFN  1, $82, 0                ; $3E BeginUpdate
        PARAM_DEFN  1, $82, 0                ; $3F EndUpdate
        PARAM_DEFN  4, current_penloc, 0     ; $40 FindWindow
        PARAM_DEFN  0, $00, 0                ; $41 FrontWindow
        PARAM_DEFN  1, $82, 0                ; $42 SelectWindow
        PARAM_DEFN  0, $00, 0                ; $43 TrackGoAway
        PARAM_DEFN  5, $82, 0                ; $44 DragWindow
        PARAM_DEFN  5, $82, 0                ; $45 GrowWindow
        PARAM_DEFN  5, $82, 0                ; $46 ScreenToWindow
        PARAM_DEFN  5, $82, 0                ; $47 WindowToScreen

        ;; Control Manager
        PARAM_DEFN  4, current_penloc, 0     ; $48 FindControl
        PARAM_DEFN  2, $82, 0                ; $49 SetCtlMax
        PARAM_DEFN  5, $82, 0                ; $4A TrackThumb
        PARAM_DEFN  2, $8C, 0                ; $4B UpdateThumb
        PARAM_DEFN  2, $8C, 0                ; $4C ActivateCtl

        ;; Extra Calls
        PARAM_DEFN 16, $8A, 0                ; $4D BitBlt
        PARAM_DEFN  0, $00, 0                ; $4E GetDeskPat
        PARAM_DEFN  0, $00, 0                ; $4F SetDeskPat
        PARAM_DEFN  0, $00, 0                ; $50 DrawMenuBar
        PARAM_DEFN  5, $82, 0                ; $51 GetWinFrameRect
        PARAM_DEFN  0, $00, 0                ; $52 RedrawDeskTop
        PARAM_DEFN  7, $82, 0                ; $53 FindControlEx
        PARAM_DEFN 16, $8A, 1                ; $54 PaintBitsHC
        PARAM_DEFN  0, $00, 0                ; $55 FlashMenuBar
        PARAM_DEFN  8, $92, 1                ; $56 SaveScreenRect
        PARAM_DEFN  8, $92, 1                ; $57 RestoreScreenRect
        PARAM_DEFN  6, $82, 0                ; $58 InflateRect
        PARAM_DEFN  4, $82, 0                ; $59 UnionRects
        PARAM_DEFN  6, $82, 0                ; $5A MulDiv
        PARAM_DEFN 16, $8A, 0                ; $5B ShieldCursor
        PARAM_DEFN  0, $00, 0                ; $5C UnshieldCursor

;;; ============================================================
;;; Pre-Shift Tables

shift_1_aux:
        .byte   $00,$02,$04,$06,$08,$0A,$0C,$0E
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
        .byte   $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
        .byte   $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
        .byte   $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F

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

div7_table:
        .byte   $00,$00,$00,$00,$00,$00,$00
        .byte   $01,$01,$01,$01,$01,$01,$01,$02
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

mod7_table:
        .byte   $00,$01,$02,$03
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
        .byte   $04,$05,$06,$00,$01,$02,$03,$04
        .byte   $05,$06,$00,$01,$02,$03,$04,$05
        .byte   $06,$00,$01,$02,$03,$04,$05,$06
        .byte   $00,$01,$02,$03

;;; ============================================================

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

;;; ============================================================
;;; Routines called during PaintRect etc based on
;;; current_penmode

        ;; ZP usage
        src_addr             := $82        ; pointer to source bitmap
        vid_addr             := $84        ; pointer to video memory
        left_bytes           := $86        ; offset of leftmost coordinate in chars (0-39)
        bits_addr            := $8E        ; pointer to pattern/bitmap
        left_mod14           := $87        ; starting x-coordinate mod 14
        left_sidemask        := $88        ; bitmask applied to clip left edge of rect
        right_sidemask       := $89        ; bitmask applied to clip right edge of rect
        src_y_coord          := $8C

        src_mapwidth         := $90        ; source stride; $80 = DHGR layout
        width_bytes          := $91        ; width of rectangle in chars

        left_masks_table     := $92        ; bitmasks for left edge indexed by page (0=main, 1=aux)
        right_masks_table    := $96        ; bitmasks for right edge indexed by page (0=main, 1=aux)

        left                 := $92
        top                  := $94        ; top/starting/current y-coordinate
        right                := $96
        bottom               := $98        ; bottom/ending/maximum y-coordinate

        clipped_left         := $9B        ; number of bits clipped off left side
        clipped_top          := $9D        ; number of bits clipped off top side

        fixed_div_dividend   := $A1        ; parameters used by FixedDiv proc
        fixed_div_divisor    := $A3
        fixed_div_quotient   := $9F        ; fixed 16.16 format

        ;; Text page usage (main/aux)
        pattern_buffer  := $0400        ; buffer for currently selected pattern (page-aligned)
        bitmap_buffer   := $0601        ; scratchpad area for drawing bitmaps/patterns

        poly_maxima_links := $0428
        poly_maxima_prev_vertex := $0468
        poly_maxima_next_vertex := $04A8
        poly_maxima_slope0 := $0528
        poly_maxima_slope1 := $04E8
        poly_maxima_slope2 := $0568
        poly_maxima_slope3 := $05A8
        poly_maxima_yl_table := $05E8

        poly_vertex_prev_link := $0680
        poly_vertex_next_link := $06BC

        poly_xl_buffer  := $0700
        poly_xh_buffer  := $073C
        poly_yl_buffer  := $0780
        poly_yh_buffer  := $07BC


        .assert <pattern_buffer = 0, error, "pattern_buffer must be page-aligned"


.proc FillmodeCopy
        lda     (vid_addr),y
        eor     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        eor     (vid_addr),y
        bcc     :+
loop:   lda     (bits_addr),y
        eor     fill_eor_mask
:       and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        dey
        bne     loop
.endproc ; FillmodeCopy
.proc FillmodeCopyOnechar
        lda     (vid_addr),y
        eor     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc ; FillmodeCopyOnechar

.proc FillmodeOr
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        bcc     :+
loop:   lda     (bits_addr),y
        eor     fill_eor_mask
:       ora     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        dey
        bne     loop
.endproc ; FillmodeOr
.proc FillmodeOrOnechar
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        ora     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc ; FillmodeOrOnechar

.proc Fillmode2XOR
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        bcc     :+
loop:   lda     (bits_addr),y
        eor     fill_eor_mask
:       eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        dey
        bne     loop
.endproc ; Fillmode2XOR
.proc Fillmode2XOROnechar
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc ; Fillmode2XOROnechar

.proc FillmodeBIC
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     right_sidemask
        bcc     :+
loop:   lda     (bits_addr),y
        eor     fill_eor_mask
:       eor     #$FF
        and     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        dey
        bne     loop
.endproc ; FillmodeBIC
.proc FillmodeBICOnechar
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     #$FF
        and     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc ; FillmodeBICOnechar


        ;; Main fill loop.

.proc FillNextLine
        cpx     bottom                  ; fill done?
        beq     :+
        inx

get_srcbits_jmp:
get_srcbits_jmp_addr := *+1
        jmp     start_fill_jmp          ; patched to *_get_srcbits if there
                                        ; is a source bitmap
:       rts
.endproc ; FillNextLine

        ;; Copy a line of source data from a non-display bitmap buffer to
        ;; the staging buffer at $0601.

.proc NDBMGetSrcbits
        lda     load_addr
        adc     src_mapwidth
        sta     load_addr
        bcc     :+
        inc     load_addr+1

:       ldy     src_width_bytes

:
load_addr       := *+1
        lda     $FFFF,y                 ; off-screen BMP will be patched here
        and     #$7F
        sta     bitmap_buffer,y
        dey
        bpl     :-
        bmi     shift_bits_clc_jmp
.endproc ; NDBMGetSrcbits

        ;; Copy a line of source data from the DHGR screen to the staging
        ;; buffer at $0601.

.proc DHGRGetSrcbits
        index         := $81
        src_byte_off  := $8A        ; char offset within source line

        ldy     src_y_coord
        inc     src_y_coord
        lda     hires_table_hi,y
        ora     $80
        sta     src_addr+1
        lda     hires_table_lo,y
        adc     src_byte_off
        sta     src_addr

get_bits:
        stx     index
        ldy     #0
        ldx     #0
loop:   sta     HISCR
        lda     (src_addr),y
        and     #$7F
        sta     LOWSCR

offset1_addr    := *+1
        sta     bitmap_buffer,x
        lda     (src_addr),y
        and     #$7F

offset2_addr    := *+1
        sta     bitmap_buffer+1,x
        iny
        inx
        inx
        cpx     src_width_bytes
        bcc     loop
        beq     loop
        ldx     index

shift_bits_clc_jmp:
        clc

shift_bits_jmp:
shift_bits_jmp_addr := *+1
        jmp     shift_line_jmp  ; patched to DHGRShiftBits when needed
.endproc ; DHGRGetSrcbits


shift_bits_clc_jmp := DHGRGetSrcbits::shift_bits_clc_jmp


        ;; Subprocedure used to shift bitmap data by a number of bits.

.proc DHGRShiftBits
        index   := $82

        stx     index
        ldy     src_width_bytes
        lda     #$00
loop:   ldx     bitmap_buffer,y

shift_main_addr := *+1
        ora     shift_1_main,x
offset2_addr := *+1
        sta     bitmap_buffer+1,y
shift_aux_addr := *+1
        lda     shift_1_aux,x
        dey
        bpl     loop
offset1_addr := *+1
        sta     bitmap_buffer
        ldx     index

shift_line_jmp:
shift_line_jmp_addr := *+1
        jmp     DHGRNextLine    ; patched to DHGRShiftLine when needed
.endproc ; DHGRShiftBits


shift_line_jmp := DHGRShiftBits::shift_line_jmp


        ;; Subprocedure used to shift bitmap data by an integral number of
        ;; chars.

.proc DHGRShiftLine
        index   := $82

        stx     index
        ldx     #0
        ldy     #0
loop:
offset1_addr := *+1
        lda     bitmap_buffer,x
        sta     HISCR
        sta     bitmap_buffer,y
        sta     LOWSCR

offset2_addr := *+1
        lda     bitmap_buffer+1,x
        sta     bitmap_buffer,y
        inx
        inx
        iny
        cpy     width_bytes
        bcc     loop
        beq     loop

        ldx     index
        jmp     DHGRNextLine
.endproc ; DHGRShiftLine


        ;; Entry point to start bit blit kOperation.

.proc BitBlit
        ldx     top
        clc
        jmp     FillNextLine::get_srcbits_jmp
.endproc ; BitBlit


        ;; Entry point to start fill after fill mode and destination have
        ;; been set.

.proc DoFill
        ldx     no_srcbits_addr                         ; Disable srcbits fetching
        stx     FillNextLine::get_srcbits_jmp_addr    ; for fill kOperation.
        ldx     no_srcbits_addr+1
        stx     FillNextLine::get_srcbits_jmp_addr+1

        ldx     top
        FALL_THROUGH_TO start_fill_jmp
.endproc ; DoFill

start_fill_jmp:
start_fill_jmp_addr := *+1
        jmp     DHGRStartFill         ; patched to *_start_fill


        ;; Start a fill targeting a non-display bitmap (NDBM)

.proc NDBMStartFill
        txa                     ; pattern y-offset
        ldx     #src_addr
        jsr     StartFillCommon
        jmp     DHGRGetSrcbits::get_bits
.endproc ; NDBMStartFill


        ;; Start a fill targeting the DHGR screen.

.proc DHGRStartFill
        txa                     ; pattern y-offset
        ldx     #bits_addr
        jsr     StartFillCommon

next_line_jmp_addr := *+1
        jmp     DHGRNextLine
.endproc ; DHGRStartFill

.proc StartFillCommon
        pha
        ror     a
        ror     a
        ror     a
        and     #$C0            ; to high 2 bits
        ora     left_bytes
        sta     $0,x

        lda     #>pattern_buffer
        adc     #0
        sta     $1,x
        pla
        tax
        rts
.endproc ; StartFillCommon


        ;; Advance to the next line and fill (non-display bitmap
        ;; destination.)

.proc NDBMNextLine
        lda     vid_addr
        clc
        adc     current_mapwidth
        sta     vid_addr
        bcc     :+
        inc     vid_addr+1
        clc
:       ldy     width_bytes

        jsr     fillmode_jmp
        jmp     FillNextLine
.endproc ; NDBMNextLine


        ;; Set vid_addr for the next line and fill (DHGR destination.)

.proc DHGRNextLine
        lda     hires_table_hi,x
        ora     current_mapbits+1
        sta     vid_addr+1
        lda     hires_table_lo,x
        clc
        adc     left_bytes
        sta     vid_addr

        ldy     #1                      ; aux mem
        jsr     DHGRFillLine
        ldy     #0                      ; main mem
        jsr     DHGRFillLine
        jmp     FillNextLine
.endproc ; DHGRNextLine


        ;; Fill one line in either main or aux screen memory.

.proc DHGRFillLine
        sta     LOWSCR,y

        lda     left_masks_table,y
        ora     #$80
        sta     left_sidemask

        lda     right_masks_table,y
        ora     #$80
        sta     right_sidemask

        ldy     width_bytes
        FALL_THROUGH_TO fillmode_jmp
.endproc ; DHGRFillLine

fillmode_jmp:
        jmp     FillmodeCopy       ; modified with fillmode routine

        ;; Address of jump used when drawing from a pattern rather than
        ;; source data bits.
no_srcbits_addr:
        .addr   start_fill_jmp

main_right_masks:
        .byte   $00,$00,$00,$00,$00,$00,$00
aux_right_masks:
        .byte   $01,$03,$07,$0F,$1F,$3F,$7F

main_left_masks:
        .byte   $7F,$7F,$7F,$7F,$7F,$7F,$7F
aux_left_masks:
        .byte   $7F,$7E,$7C,$78,$70,$60,$40
        .byte   $00,$00,$00,$00,$00,$00,$00


        ;; Tables used for fill modes

        ; Fill routines that handle >1 char between left and right limits.
fill_mode_table_low:
        .byte   <FillmodeCopy,<FillmodeOr,<Fillmode2XOR,<FillmodeBIC
        .byte   <FillmodeCopy,<FillmodeOr,<Fillmode2XOR,<FillmodeBIC
fill_mode_table_high:
        .byte   >FillmodeCopy,>FillmodeOr,>Fillmode2XOR,>FillmodeBIC
        .byte   >FillmodeCopy,>FillmodeOr,>Fillmode2XOR,>FillmodeBIC

        ; Fill routines that handle only 1 char.
fill_mode_table_onechar_low:
        .byte   <FillmodeCopyOnechar,<FillmodeOrOnechar,<Fillmode2XOROnechar,<FillmodeBICOnechar
        .byte   <FillmodeCopyOnechar,<FillmodeOrOnechar,<Fillmode2XOROnechar,<FillmodeBICOnechar
fill_mode_table_onechar_high:
        .byte   >FillmodeCopyOnechar,>FillmodeOrOnechar,>Fillmode2XOROnechar,>FillmodeBICOnechar
        .byte   >FillmodeCopyOnechar,>FillmodeOrOnechar,>Fillmode2XOROnechar,>FillmodeBICOnechar

;;; ============================================================
;;; SetPenMode

.proc SetPenModeImpl
        lda     current_penmode
        ldx     #0
    IF A >= #4
        ldx     #$7F
    END_IF
        stx     fill_eor_mask
        rts
.endproc ; SetPenModeImpl

        ;; Called from PaintRect, DrawText, etc to configure
        ;; fill routines from mode.

.proc SetUpFillMode
        x1      := $92
        x2      := $96

        x1_bytes := $86
        x2_bytes := $82

        add16   x_offset, x2, x2
        add16   y_offset, bottom, bottom

        add16   x_offset, x1, x1
        add16   y_offset, top, top

        lda     x2+1
        ldx     x2
        jsr     DivMod7
        sta     x2_bytes
        tya
        rol     a
        tay
        lda     aux_right_masks,y
        sta     right_masks_table+1
        lda     main_right_masks,y
        sta     right_masks_table

        lda     x1+1
        ldx     x1
        jsr     DivMod7
        sta     x1_bytes
        tya
        rol     a
        tay
        sty     left_mod14
        lda     aux_left_masks,y
        sta     left_masks_table+1
        lda     main_left_masks,y
        sta     left_masks_table
        lda     x2_bytes
        sec
        sbc     x1_bytes

set_width:                                      ; Set width for destination.
        sta     width_bytes
        ldx     current_penmode
        cmp     #0
        bne     :+                              ; Check if one or more than one is needed

        lda     left_masks_table+1              ; Only one char is needed, so combine
        and     right_masks_table+1             ; the left and right masks and use the
        sta     left_masks_table+1              ; one-char fill subroutine.
        sta     right_masks_table+1
        lda     left_masks_table
        and     right_masks_table
        sta     left_masks_table
        sta     right_masks_table

        copylohi  fill_mode_table_onechar_low,x, fill_mode_table_onechar_high,x, fillmode_jmp+1
        rts

:       copylohi  fill_mode_table_low,x, fill_mode_table_high,x, fillmode_jmp+1
        rts
.endproc ; SetUpFillMode

;;; Inputs: X = x lo, A = x hi
;;; Outputs: A = (x/2) / 7, Y = (x/2) % 7
.proc DivMod7
        lsr     a
        bne     :+

        ;; x < 512
        txa
        ror     a
        tax
        RETURN  A=div7_table,x, Y=mod7_table,x

        ;; x >= 512
:       txa
        ror     a
        tax
        ldy     mod7_table+4,x
        lda     div7_table+4,x
        bcc     :+
        adc     #$23
        sec
        rts
:
        adc     #$24            ; keep C=0 for x < 560
        rts
.endproc ; DivMod7

        ;; Set up destination (for either on-screen or off-screen bitmap.)

.proc SetDest
kDestNDBM       = 0             ; draw to off-screen bitmap
kDestDHGR       = 1             ; draw to DHGR screen

        lda     left_bytes
        ldx     top
        ldy     current_mapwidth
        jsr     NDBMCalcDest
        clc
        adc     current_mapbits
        sta     vid_addr
        tya
        adc     current_mapbits+1
        sta     vid_addr+1

        lda     #2*kDestDHGR
        tax
        tay
        bit     current_mapwidth
        bmi     on_screen               ; negative for on-screen destination

        copy16  #bitmap_buffer, bits_addr

        jsr     ndbm_fix_width
        txa
        inx
        stx     src_width_bytes
        jsr     SetUpFillMode::set_width

        copy16  shift_line_jmp_addr, DHGRGetSrcbits::shift_bits_jmp_addr
        lda     #2*kDestNDBM
        tax
        tay

on_screen:
        pha
        lda     next_line_table,x
        sta     DHGRStartFill::next_line_jmp_addr
        lda     next_line_table+1,x
        sta     DHGRStartFill::next_line_jmp_addr+1
        pla
        tax
        copy16  start_fill_table,x, start_fill_jmp+1
        copy16  shift_line_table,y, DHGRShiftBits::shift_line_jmp_addr
        rts
.endproc ; SetDest


        ;; Fix up the width and masks for an off-screen destination,

ndbm_fix_width:
        lda     width_bytes
        asl     a
        tax
        inx

        lda     left_masks_table+1
        bne     :+
        dex
        inc     bits_addr
        inc16   vid_addr
        lda     left_masks_table
:       sta     left_sidemask

        lda     right_masks_table
        bne     :+
        dex
        lda     right_masks_table+1
:       sta     right_sidemask
        rts

;;              kDestNDBM        kDestDHGR
shift_line_jmp_addr:
        .addr   shift_line_jmp

start_fill_table:
        .addr   NDBMStartFill, DHGRStartFill
next_line_table:
        .addr   NDBMNextLine,  DHGRNextLine
shift_line_table:
        .addr   NDBMNextLine,  DHGRShiftLine


        ;; Set source for bitmap transfer (either on-screen or off-screen bitmap.)

.proc SetSource
kSrcNDBM        = 0
kSrcDHGR        = 1

        ldx     src_y_coord
        ldy     src_mapwidth
        bmi     :+
        jsr     MultXY

:       clc
        adc     bits_addr
        sta     NDBMGetSrcbits::load_addr
        tya
        adc     bits_addr+1
        sta     NDBMGetSrcbits::load_addr+1

        ldx     #2*kSrcDHGR
        bit     src_mapwidth
        bmi     :+

        ldx     #2*kSrcNDBM
:       copy16  get_srcbits_table,x, FillNextLine::get_srcbits_jmp_addr
        rts

;;              kSrcNDBM           kSrcDHGR
get_srcbits_table:
        .addr   NDBMGetSrcbits,  DHGRGetSrcbits
.endproc ; SetSource


        ;; Calculate destination for off-screen bitmap.

.proc NDBMCalcDest
        bmi     on_screen        ; do nothing for on-screen destination
        asl     a

MultXY:
        stx     $82
        sty     $83
        ldx     #8
loop:   lsr     $83
        bcc     :+
        clc
        adc     $82
:       ror     a
        ror     vid_addr
        dex
        bne     loop

        sty     $82
        tay
        lda     vid_addr
        sec
        sbc     $82
        bcs     on_screen
        dey
on_screen:
        rts
.endproc ; NDBMCalcDest


MultXY := NDBMCalcDest::MultXY


;;; ============================================================
;;; SetPattern

;; Expands the pattern to 8 rows of DHGR-style bitmaps at
;; $0400, $0440, $0480, $04C0, $0500, $0540, $0580, $05C0
;; (using both main and aux mem.)

.proc SetPatternImpl
        ;; Since expanding the pattern takes ~16000 cycles,
        ;; make sure it is necessary - compare to what we
        ;; already have expanded and expand if different.
        ldx     #7
:       lda     current_penpattern,x
        cmp     expanded_pattern,x
        bne     expand          ; no, expand it
        dex
        bpl     :-
        rts                     ; yes, skip!

:       lda     current_penpattern,x
expand:
        sta     expanded_pattern,x
        dex
        bpl     :-

        lda     #<pattern_buffer
        sta     bits_addr

        lda     y_offset
        and     #7
        lsr     a
        ror     bits_addr
        lsr     a
        ror     bits_addr
        adc     #>pattern_buffer
        sta     bits_addr+1

        ldx     #7
loop:   txa
        pha

        lda     x_offset
        and     #7
        tay

        lda     current_penpattern,x
:       dey
        bmi     :+
        cmp     #$80
        rol     a
        bne     :-

:       ldy     #$27
:       tax
        lsr     a
        sta     LOWSCR
        sta     (bits_addr),y
        txa
        ror     a
        tax
        lsr     a
        sta     HISCR
        sta     (bits_addr),y
        txa
        ror     a
        dey
        bpl     :-

        lda     bits_addr
        sec
        sbc     #$40
        sta     bits_addr
        bcs     next

        ldy     bits_addr+1
        dey
        cpy     #>pattern_buffer
        bcs     :+
        ldy     #>pattern_buffer+1
:       sty     bits_addr+1

next:   pla
        tax
        dex
        bpl     loop
        sta     LOWSCR
        rts


expanded_pattern:
        ;; Randomly selected; just needs to not match any initial pattern.
        .byte   19, 121, 11, 204, 183, 106, 212, 5
        .assert * - expanded_pattern = 8, error, "pattern size"
.endproc ; SetPatternImpl


;;; ============================================================
;;; FrameRect

;;; 8 bytes of params, copied to $9F

.proc FrameRectImpl
        left   := $9F
        top    := $A1
        right  := $A3
        bottom := $A5

        ldy     #3
rloop:  COPY_BYTES 8, left, left_masks_table
        ldx     rect_sides,y
        lda     left,x
        pha
        lda     $A0,x
        ldx     rect_coords,y
        sta     $93,x
        pla
        sta     left_masks_table,x
        sty     frect_ctr
        jsr     DrawLine
frect_ctr := * + 1
        ldy     #0
        dey
        bpl     rloop
        COPY_BYTES 4, left, current_penloc
.endproc ; FrameRectImpl
prts:   rts

rect_sides:
        .byte   0,2,4,6
rect_coords:
        .byte   4,6,0,2

.proc DrawLine
        x2      := right

        ldx     current_penwidth    ; Also: draw horizontal line $92 to $96 at $98
        beq     prts
        dex
        txa
        clc
        adc     x2
        sta     x2
        bcc     :+
        inc     x2+1

:       ldx     current_penheight
        beq     prts
        dex
        txa
        clc
        adc     bottom
        sta     bottom
        bcc     PaintRectImpl
        inc     bottom+1
        FALL_THROUGH_TO PaintRectImpl
.endproc ; DrawLine


;;; ============================================================
;;; PaintRect

;;; 8 bytes of params, copied to $92

.proc PaintRectImpl
        jsr     CheckRect
DoPaint:
        jsr     ClipRect
        bcc     prts
        jsr     SetUpFillMode
        jsr     SetDest
        jmp     DoFill
.endproc ; PaintRectImpl


;;; ============================================================
;;; InRect

;;; 8 bytes of params, copied to $92

.proc InRectImpl
        jsr     CheckRect
        ldax    current_penloc_x
        cpx     left+1
        bmi     fail
        bne     :+
        cmp     left
        bcc     fail

:       cpx     right+1
        bmi     :+
        bne     fail
        cmp     right
        bcc     :+
        bne     fail

:       ldax    current_penloc_y
        cpx     top+1
        bmi     fail
        bne     :+
        cmp     top
        bcc     fail

:       cpx     bottom+1
        bmi     :+
        bne     fail
        cmp     bottom
        bcc     :+
        bne     fail
:       EXIT_CALL MGTK::inrect_inside           ; success!

fail:   rts
.endproc ; InRectImpl

;;; ============================================================
;;; SetPortBits

.proc SetPortBitsImpl
        sub16   current_viewloc_x, current_maprect_x1, x_offset
        sub16   current_viewloc_y, current_maprect_y1, y_offset
        rts
.endproc ; SetPortBitsImpl

;;; ============================================================

.proc ClipRect
        lda     current_maprect_x2+1
        cmp     left+1
        bmi     fail
        bne     in_left
        lda     current_maprect_x2
        cmp     left
        bcs     in_left
fail:   clc
fail2:  rts

in_left:
        lda     right+1
        cmp     current_maprect_x1+1
        bmi     fail
        bne     in_right
        lda     right
        cmp     current_maprect_x1
        bcc     fail2

in_right:
        lda     current_maprect_y2+1
        cmp     top+1
        bmi     fail
        bne     in_bottom
        lda     current_maprect_y2
        cmp     top
        bcc     fail2

in_bottom:
        lda     bottom+1
        cmp     current_maprect_y1+1
        bmi     fail
        bne     in_top
        lda     bottom
        cmp     current_maprect_y1
        bcc     fail2

in_top: ldy     #0
        lda     left
        sec
        sbc     current_maprect_x1
        tax
        lda     left+1
        sbc     current_maprect_x1+1
        bpl     :+

        stx     clipped_left
        sta     clipped_left+1
        copy16  current_maprect_x1, left
        iny

:       lda     current_maprect_x2
        sec
        sbc     right
        tax
        lda     current_maprect_x2+1
        sbc     right+1
        bpl     :+

        copy16  current_maprect_x2, right
        tya
        ora     #$04
        tay

:       lda     top
        sec
        sbc     current_maprect_y1
        tax
        lda     top+1
        sbc     current_maprect_y1+1
        bpl     :+

        stx     clipped_top
        sta     clipped_top+1
        copy16  current_maprect_y1, top
        iny
        iny

:       lda     current_maprect_y2
        sec
        sbc     bottom
        tax
        lda     current_maprect_y2+1
        sbc     bottom+1
        bpl     :+
        copy16  current_maprect_y2, bottom
        tya
        ora     #$08
        tay

:       sty     $9A
        RETURN  C=1
.endproc ; ClipRect

;;; ============================================================

.proc CheckRect
        ;; `right` >= `left` ?
        sec
        lda     right
        sbc     left
        lda     right+1
        sbc     left+1
        bmi     bad_rect

        ;; `bottom` >= `top` ?
        sec
        lda     bottom
        sbc     top
        lda     bottom+1
        sbc     top+1
        bmi     bad_rect
        rts

bad_rect:
        EXIT_CALL MGTK::Error::empty_object
.endproc ; CheckRect


;;; ============================================================

;;; 16 bytes of params, copied to $8A

src_width_bytes:
        .res    1          ; width of source data in chars

.proc PaintBitsImpl

        dbi_left   := $8A
        dbi_top    := $8C
        dbi_bitmap := $8E     ; aka bits_addr
        dbi_stride := $90     ; aka src_mapwidth
        dbi_hoff   := $92     ; aka left
        dbi_voff   := $94     ; aka top
        dbi_width  := $96     ; aka right
        dbi_height := $98     ; aka bottom

        dbi_x      := $9B
        dbi_y      := $9D

        offset     := $82


        ldx     #3         ; copy left/top to $9B/$9D
:       lda     dbi_left,x ; and hoff/voff to $8A/$8C (overwriting left/top)
        sta     dbi_x,x
        lda     dbi_hoff,x
        sta     dbi_left,x
        dex
        bpl     :-

        sub16   dbi_width, dbi_hoff, offset
        lda     dbi_x
        sta     left

        clc
        adc     offset
        sta     right
        lda     dbi_x+1
        sta     left+1
        adc     offset+1
        sta     right+1

        sub16   dbi_height, dbi_voff, offset
        lda     dbi_y
        sta     top
        clc
        adc     offset
        sta     bottom
        lda     dbi_y+1
        sta     top+1
        adc     offset+1
        sta     bottom+1
        FALL_THROUGH_TO BitBltImpl
.endproc ; PaintBitsImpl

;;; ============================================================

;;; $4D BitBlt

;;; 16 bytes of params, copied to $8A

        src_byte_off      := $8A        ; char offset within source line
        bit_offset        := $9B
        shift_bytes       := $81

.proc BitBltImpl
        lda     #0
        sta     clipped_left
        sta     clipped_left+1
        sta     clipped_top

        lda     bits_addr+1
        sta     $80

        jsr     ClipRect
        RTS_IF CC

        jsr     SetUpFillMode
        lda     width_bytes
        asl     a
        ldx     left_masks_table+1      ; need left mask on aux?
        cpx     #1                      ; set carry if >= 1
        adc     #0
        ldx     right_masks_table       ; need right mask on main?
        cpx     #1                      ; set carry if >= 1
        adc     #0
        sta     src_width_bytes         ; adjusted width in chars

        lda     #2
        sta     shift_bytes
        lda     #0                      ; Calculate starting Y-coordinate
        sec                             ;  = dbi_top - clipped_top
        sbc     clipped_top
        clc
        adc     PaintBitsImpl::dbi_top
        sta     PaintBitsImpl::dbi_top

        lda     #0                      ; Calculate starting X-coordinate
        sec                             ;  = dbi_left - clipped_left
        sbc     clipped_left
        tax
        lda     #0
        sbc     clipped_left+1
        tay

        txa
        clc
        adc     PaintBitsImpl::dbi_left
        tax
        tya
        adc     PaintBitsImpl::dbi_left+1

        jsr     DivMod7
        sta     src_byte_off
        tya                             ; bit offset between src and dest
        rol     a
        cmp     #7
        ldx     #1
        bcc     :+
        dex
        sbc     #7

:       stx     DHGRGetSrcbits::offset1_addr
        inx
        stx     DHGRGetSrcbits::offset2_addr
        sta     bit_offset

        lda     src_byte_off
        rol     a

        jsr     SetSource
        jsr     SetDest
        copy16  #bitmap_buffer, bits_addr
        ldx     #1
        lda     left_mod14

        sec
        sbc     #7
        bcc     :+
        sta     left_mod14
        dex
:       stx     DHGRShiftLine::offset1_addr
        inx
        stx     DHGRShiftLine::offset2_addr

        lda     left_mod14
        sec
        sbc     bit_offset
        bcs     :+
        adc     #7
        inc     src_width_bytes
        dec     shift_bytes
:       tay                                     ; check if bit shift required
        bne     :+
        ;;ldx     #2*kBitsNoBitShift
        .assert <kBitsNoBitShift = 0, error, "kBitsNoBitShift must be 0"
        tax
        beq     no_bitshift

:       copylohi shift_table_main_low,y, shift_table_main_high,y, DHGRShiftBits::shift_main_addr

        copylohi shift_table_aux_low,y, shift_table_aux_high,y, DHGRShiftBits::shift_aux_addr

        ldy     shift_bytes
        sty     DHGRShiftBits::offset2_addr
        dey
        sty     DHGRShiftBits::offset1_addr

        ldx     #2*kBitsBitShift
no_bitshift:
        copy16  shift_bits_table,x, DHGRGetSrcbits::shift_bits_jmp_addr
        jmp     BitBlit

kBitsNoBitShift = 0
kBitsBitShift   = 1

;;              kBitsNoBitShift    kBitsBitShift
shift_bits_table:
        .addr   shift_line_jmp,    DHGRShiftBits
.endproc ; BitBltImpl


        shift_table_aux_low := *-1
        .byte   <shift_1_aux,<shift_2_aux,<shift_3_aux
        .byte   <shift_4_aux,<shift_5_aux,<shift_6_aux

        shift_table_aux_high := *-1
        .byte   >shift_1_aux,>shift_2_aux,>shift_3_aux
        .byte   >shift_4_aux,>shift_5_aux,>shift_6_aux

        shift_table_main_low := *-1
        .byte   <shift_1_main,<shift_2_main,<shift_3_main
        .byte   <shift_4_main,<shift_5_main,<shift_6_main

        shift_table_main_high := *-1
        .byte   >shift_1_main,>shift_2_main,>shift_3_main
        .byte   >shift_4_main,>shift_5_main,>shift_6_main

        vertex_limit     := $B3
        vertices_count   := $B4
        poly_oper        := $BA       ; positive = paint; negative = test
        start_index      := $AE

        poly_oper_paint  := $00
        poly_oper_test   := $80


.proc LoadPoly
        point_index      := $82
        low_point        := $A7

        kMaxPolyPoints   = 60

        stx     $B0
        asl     a
        asl     a               ; # of vertices * 4 = length
        sta     vertex_limit

        ;; Initialize rect to first point of polygon.
        ldy     #3              ; Copy params_addr... to $92... and $96...
:       lda     (params_addr),y
        sta     left,y
        sta     right,y
        dey
        bpl     :-

        copy16  top, low_point  ; y coord

        iny
        stx     start_index
loop:   stx     point_index

        lda     (params_addr),y
        sta     poly_xl_buffer,x
        pha
        iny
        lda     (params_addr),y
        sta     poly_xh_buffer,x
        tax
        pla
        iny

        cpx     left+1
        bmi     :+
        bne     in_left
        cmp     left
        bcs     in_left

:       stax    left
        bcc     in_right

in_left:
        cpx     right+1
        bmi     in_right
        bne     :+
        cmp     right
        bcc     in_right

:       stax    right

in_right:
        ldx     point_index
        lda     (params_addr),y
        sta     poly_yl_buffer,x
        pha
        iny
        lda     (params_addr),y
        sta     poly_yh_buffer,x
        tax
        pla
        iny

        cpx     top+1
        bmi     :+
        bne     in_top
        cmp     top
        bcs     in_top

:       stax    top
        bcc     in_bottom

in_top: cpx     bottom+1
        bmi     in_bottom
        bne     :+
        cmp     bottom
        bcc     in_bottom

:       stax    bottom

in_bottom:
        cpx     low_point+1
        stx     low_point+1
        bmi     set_low_point
        bne     :+
        cmp     low_point
        bcc     set_low_point
        beq     set_low_point

:       ldx     point_index
        stx     start_index

set_low_point:
        sta     low_point

        ldx     point_index
        inx
        cpx     #kMaxPolyPoints
        beq     bad_poly
        cpy     vertex_limit
        bcc     loop

        lda     top
        cmp     bottom
        bne     :+
        lda     top+1
        cmp     bottom+1
        beq     bad_poly

:       stx     vertex_limit
        bit     poly_oper
        bpl     :+
        RETURN  C=1

:       jmp     ClipRect
.endproc ; LoadPoly


.proc NextPoly
        lda     vertices_count
        bpl     orts
        asl     a
        asl     a
        adc     params_addr
        sta     params_addr
        bcc     ora_2_param_bytes
        inc     params_addr+1
        FALL_THROUGH_TO ora_2_param_bytes
.endproc ; NextPoly

        ;; ORAs together first two bytes at (params_addr) and stores
        ;; in $B4, then advances params_addr
ora_2_param_bytes:
        ldy     #0
        lda     (params_addr),y
        iny
        ora     (params_addr),y
        sta     vertices_count
        inc16   params_addr
        inc16   params_addr
        ldy     #$80
orts:   rts

;;; ============================================================
;;; InPoly

InPolyImpl:
        lda     #poly_oper_test
        bne     PaintPolyImpl_entry2

;;; ============================================================
;;; PaintPoly

        ;; also called from the end of LineToImpl

        num_maxima       := $AD
        kMaxNumMaxima    = 8

        low_vertex       := $B0


.proc PaintPolyImpl

        lda     #poly_oper_paint
entry2: sta     poly_oper
        ldx     #0
        stx     num_maxima
        jsr     ora_2_param_bytes

loop:   jsr     LoadPoly
        bcs     ProcessPoly
        ldx     low_vertex
next:   jsr     NextPoly
        bmi     loop

        jmp     FillPolys

bad_poly:
        EXIT_CALL MGTK::Error::bad_object
.endproc ; PaintPolyImpl


        temp_yh        := $83
        next_vertex    := $AA
        current_vertex := $AC
        loop_ctr       := $AF


.proc ProcessPoly
        ldy     #1
        sty     loop_ctr         ; do 2 iterations of the following loop

        ldy     start_index      ; starting vertex
        cpy     low_vertex       ; lowest vertex
        bne     :+
        ldy     vertex_limit     ; highest vertex
:       dey
        sty     $AB              ; one before starting vertex

        php
loop:   sty     current_vertex   ; current vertex
        iny
        cpy     vertex_limit
        bne     :+
        ldy     low_vertex

:       sty     next_vertex      ; next vertex
        cpy     start_index      ; have we come around complete circle?
        bne     :+
        dec     loop_ctr         ; this completes one loop

:       lda     poly_yl_buffer,y
        ldx     poly_yh_buffer,y
        stx     temp_yh
vloop:  sty     $A9              ; starting from next vertex, search ahead
        iny                      ; for a subsequent vertex with differing y
        cpy     vertex_limit
        bne     :+
        ldy     low_vertex
:
        cmp     poly_yl_buffer,y
        bne     :+
        ldx     poly_yh_buffer,y
        cpx     temp_yh
        beq     vloop

:       ldx     $AB              ; find y difference with current vertex
        sec
        sbc     poly_yl_buffer,x
        lda     temp_yh
        sbc     poly_yh_buffer,x
        bmi     y_less

        lda     $A9              ; vertex before new vertex

        plp                      ; check maxima flag
        bmi     new_maxima       ; if set, go create new maxima

        tay
        sta     poly_vertex_prev_link,x   ; link current vertex -> vertex before new vertex
        lda     next_vertex
        sta     poly_vertex_next_link,x   ; link current vertex -> next vertex
        bpl     next

new_maxima:
        ldx     num_maxima
        cpx     #2*kMaxNumMaxima         ; too many maxima points (documented limitation)
        bcs     bad_poly

        sta     poly_maxima_prev_vertex,x ; vertex before new vertex
        lda     next_vertex
        sta     poly_maxima_next_vertex,x ; current vertex

        ldy     $AB
        lda     poly_vertex_prev_link,y
        sta     poly_maxima_prev_vertex+1,x
        lda     poly_vertex_next_link,y
        sta     poly_maxima_next_vertex+1,x

        lda     poly_yl_buffer,y
        sta     poly_maxima_yl_table,x
        sta     poly_maxima_yl_table+1,x

        lda     poly_yh_buffer,y
        sta     poly_maxima_yh_table,x
        sta     poly_maxima_yh_table+1,x

        lda     poly_xl_buffer,y
        sta     poly_maxima_xl_table+1,x
        lda     poly_xh_buffer,y
        sta     poly_maxima_xh_table+1,x

        ldy     current_vertex
        lda     poly_xl_buffer,y
        sta     poly_maxima_xl_table,x
        lda     poly_xh_buffer,y
        sta     poly_maxima_xh_table,x
        inx
        inx
        stx     num_maxima
        ldy     $A9
        bpl     next

y_less: plp                         ; check maxima flag
        bmi     :+
        lda     #$80
        sta     poly_vertex_prev_link,x             ; link current vertex -> #$80

:       ldy     next_vertex
        txa
        sta     poly_vertex_prev_link,y             ; link next vertex -> current vertex
        lda     current_vertex
        sta     poly_vertex_next_link,y
        lda     #$80                ; set negative flag so next iteration captures a maxima

next:   php
        sty     $AB
        ldy     $A9
        bit     loop_ctr
        bmi     :+
        jmp     loop

:       plp
        ldx     vertex_limit
        jmp     PaintPolyImpl::next
.endproc ; ProcessPoly


        scan_y       := $A9
        lr_flag      := $AB
        start_maxima := $B1

.proc FillPolys
        ldx     #0
        stx     start_maxima
        lda     #$80
        sta     poly_maxima_links
        sta     $B2

loop:   inx
        cpx     num_maxima
        bcc     :+
        beq     links_done
        rts

:       lda     start_maxima
next_link:
        tay
        lda     poly_maxima_yl_table,x
        cmp     poly_maxima_yl_table,y
        bcs     x_ge_y
        tya                            ; poly_maxima_y[xReg] < poly_maxima_y[yReg]
        sta     poly_maxima_links,x    ; then xReg linked to yReg
        cpy     start_maxima
        beq     :+                     ; if yReg was the start, set the start to xReg
        ldy     $82
        txa
        sta     poly_maxima_links,y    ; else $82 linked to xReg
        jmp     loop

:       stx     start_maxima           ; set start to xReg
        bcs     loop                   ; always

x_ge_y: sty     $82                    ; poly_maxima_y[xReg] >= poly_maxima_y[yReg]
        lda     poly_maxima_links,y
        bpl     next_link              ; if yReg was the end
        sta     poly_maxima_links,x    ; then set xReg as end
        txa
        sta     poly_maxima_links,y    ; and link yReg to xReg
        bpl     loop                   ; always
links_done:

        ldx     start_maxima
        lda     poly_maxima_yl_table,x
        sta     scan_y
        sta     top
        lda     poly_maxima_yh_table,x
        sta     scan_y+1
        sta     top+1

scan_loop:
        ldx     start_maxima
        bmi     L5534
scan_next:
        lda     poly_maxima_yl_table,x
        cmp     scan_y
        bne     L5532
        lda     poly_maxima_yh_table,x
        cmp     scan_y+1
        bne     L5532

        lda     poly_maxima_links,x
        sta     $82
        jsr     CalcSlope

        lda     $B2
        bmi     L5517

L54E0:  tay
        lda     poly_maxima_xh_table,x
        cmp     poly_maxima_xh_table,y
        bmi     L5520
        bne     :+

        lda     poly_maxima_xl_table,x
        cmp     poly_maxima_xl_table,y
        bcc     L5520
        bne     :+

        lda     poly_maxima_x_frach,x
        cmp     poly_maxima_x_frach,y
        bcc     L5520
        bne     :+

        lda     poly_maxima_x_fracl,x
        cmp     poly_maxima_x_fracl,y
        bcc     L5520

:       sty     $83
        lda     poly_maxima_links,y
        bpl     L54E0
        sta     poly_maxima_links,x
        txa
        sta     poly_maxima_links,y
        bpl     L552E

L5517:  sta     poly_maxima_links,x
        stx     $B2
        jmp     L552E

done:   rts

L5520:  tya
        cpy     $B2
        beq     L5517
        sta     poly_maxima_links,x
        txa
        ldy     $83
        sta     poly_maxima_links,y

L552E:  ldx     $82
        bpl     scan_next

L5532:  stx     $B1
L5534:  lda     #0
        sta     lr_flag

        lda     $B2
        sta     $83
        bmi     done

scan_loop2:
        tax
        lda     scan_y
        cmp     poly_maxima_yl_table,x
        bne     scan_point
        lda     scan_y+1
        cmp     poly_maxima_yh_table,x
        bne     scan_point

        ldy     poly_maxima_prev_vertex,x
        lda     poly_vertex_prev_link,y
        bpl     shift_point

        cpx     $B2
        beq     :+

        ldy     $83
        lda     poly_maxima_links,x
        sta     poly_maxima_links,y
        jmp     scan_next_link

:       lda     poly_maxima_links,x
        sta     $B2
        jmp     scan_next_link

shift_point:
        sta     poly_maxima_prev_vertex,x
        lda     poly_xl_buffer,y
        sta     poly_maxima_xl_table,x
        lda     poly_xh_buffer,y
        sta     poly_maxima_xh_table,x
        lda     poly_vertex_next_link,y
        sta     poly_maxima_next_vertex,x

        jsr     CalcSlope

scan_point:
        stx     current_vertex
        ldy     poly_maxima_xh_table,x
        lda     poly_maxima_xl_table,x
        tax

        lda     lr_flag            ; alternate flag left/right
        eor     #$FF
        sta     lr_flag
        bpl     :+

        stx     left
        sty     left+1
        bmi     skip_rect

:       stx     right
        sty     right+1

        cpy     left+1
        bmi     :+
        bne     no_swap_lr
        cpx     left
        bcs     no_swap_lr

:       lda     left
        stx     left
        sta     right
        lda     left+1
        sty     left+1
        sta     right+1

no_swap_lr:
        lda     scan_y
        sta     top
        sta     bottom
        lda     scan_y+1
        sta     top+1
        sta     bottom+1

        bit     poly_oper
        bpl     DoPaint

        jsr     InRectImpl
        jmp     skip_rect

DoPaint:
        jsr     PaintRectImpl::DoPaint

skip_rect:
        ldx     current_vertex

        lda     poly_maxima_x_fracl,x
        clc
        adc     poly_maxima_slope0,x
        sta     poly_maxima_x_fracl,x
        lda     poly_maxima_x_frach,x
        adc     poly_maxima_slope1,x
        sta     poly_maxima_x_frach,x

        lda     poly_maxima_xl_table,x
        adc     poly_maxima_slope2,x
        sta     poly_maxima_xl_table,x
        lda     poly_maxima_xh_table,x
        adc     poly_maxima_slope3,x
        sta     poly_maxima_xh_table,x

        lda     poly_maxima_links,x
scan_next_link:
        bmi     :+
        jmp     scan_loop2

:       inc16   scan_y
        jmp     scan_loop
.endproc ; FillPolys


.proc CalcSlope
        index   := $84

        ldy     poly_maxima_next_vertex,x

        lda     poly_yl_buffer,y
        sta     poly_maxima_yl_table,x
        sec
        sbc     scan_y
        sta     <fixed_div_divisor
        lda     poly_yh_buffer,y
        sta     poly_maxima_yh_table,x
        sbc     scan_y+1
        sta     <fixed_div_divisor+1

        lda     poly_xl_buffer,y
        sec
        sbc     poly_maxima_xl_table,x
        sta     <fixed_div_dividend
        lda     poly_xh_buffer,y
        sbc     poly_maxima_xh_table,x
        sta     <fixed_div_dividend+1

        php
        bpl     :+
        sub16   #0, fixed_div_dividend, fixed_div_dividend

:       stx     index
        jsr     fixed_div2
        ldx     index
        plp
        bpl     :+

        sub16   #0, fixed_div_quotient, fixed_div_quotient
        lda     #0
        sbc     fixed_div_quotient+2
        sta     fixed_div_quotient+2
        lda     #0
        sbc     fixed_div_quotient+3
        sta     fixed_div_quotient+3

:       lda     fixed_div_quotient+3
        sta     poly_maxima_slope3,x
        cmp     #$80
        ror     a
        pha
        lda     fixed_div_quotient+2
        sta     poly_maxima_slope2,x
        ror     a
        pha
        lda     fixed_div_quotient+1
        sta     poly_maxima_slope1,x
        ror     a
        pha
        lda     fixed_div_quotient
        sta     poly_maxima_slope0,x
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
.endproc ; CalcSlope

PaintPolyImpl_entry2 := PaintPolyImpl::entry2
bad_poly := PaintPolyImpl::bad_poly


.proc FixedDiv
        dividend   := $A1       ; 16.0 format
        divisor    := $A3       ; 16.0 format
        quotient   := $9F       ; 16.16 format
        temp       := $A5

        lda     dividend+1
entry2: ora     dividend
        bne     :+

        sta     quotient
        sta     quotient+1
        sta     dividend
        sta     dividend+1
        beq     done            ; always

:       ldy     #32
        lda     #0
        sta     quotient
        sta     quotient+1
        sta     temp
        sta     temp+1

loop:   asl     quotient
        rol     quotient+1
        rol     dividend
        rol     dividend+1
        rol     temp
        rol     temp+1

        lda     temp
        sec
        sbc     divisor
        tax
        lda     temp+1
        sbc     divisor+1
        bcc     :+
        stx     temp
        sta     temp+1
        inc     quotient
:
        dey
        bne     loop

done:   rts
.endproc ; FixedDiv

fixed_div2 := FixedDiv::entry2



;;; ============================================================
;;; FramePoly

.proc FramePolyImpl
        lda     #0
        sta     poly_oper
        jsr     ora_2_param_bytes

        ptr := $B7
        draw_line_params := $92

poly_loop:
        copy16  params_addr, ptr

        lda     vertices_count             ; ORAd param bytes
        sta     $B6
        ldx     #0
        jsr     LoadPoly
        bcc     next

        lda     $B3
        sta     $B5             ; loop counter

        ;; Loop for drawing
        ldy     #0
loop:   ldx     #0
        dec     $B5
        beq     endloop
        sty     $B9

:       lda     (ptr),y
        sta     draw_line_params,x
        iny
        inx
        cpx     #8
        bne     :-
        jsr     DRAW_LINE_ABS_IMPL_do_draw_line

        lda     $B9
        clc
        adc     #4
        tay
        bne     loop
        tax

endloop:
        ;; Draw from last point back to start
:       lda     (ptr),y
        sta     draw_line_params,x
        iny
        inx
        cpx     #4
        bne     :-
        ldy     #3
:       lda     (ptr),y
        sta     draw_line_params+4,y
        sta     current_penloc,y
        dey
        bpl     :-
        jsr     DRAW_LINE_ABS_IMPL_do_draw_line

        ;; Handle multiple segments, e.g. when drawing outlines for multi icons?

next:   ldx     #1
:       lda     ptr,x
        sta     $80,x
        lda     $B5,x
        sta     $B3,x
        dex
        bpl     :-

        jsr     NextPoly        ; Advance to next polygon in list
        bmi     poly_loop
        rts
.endproc ; FramePolyImpl

;;; ============================================================
;;; Move

;;; 4 bytes of params, copied to $A1

.proc MoveImpl
        xdelta := $A1
        ydelta := $A3

        ldax    xdelta
        jsr     AdjustXPos
        lda     ydelta
        clc
        adc     current_penloc_y
        sta     current_penloc_y
        lda     ydelta+1
        adc     current_penloc_y+1
        sta     current_penloc_y+1
        rts
.endproc ; MoveImpl

        ;; Adjust current_penloc_x by (X,A)
.proc AdjustXPos
        clc
        adc     current_penloc_x
        sta     current_penloc_x
        txa
        adc     current_penloc_x+1
        sta     current_penloc_x+1
        rts
.endproc ; AdjustXPos

;;; ============================================================
;;; LineImpl

;;; 4 bytes of params, copied to $A1

.proc LineImpl

        xdelta := $A1
        ydelta := $A2

        ldx     #2              ; Convert relative x/y to absolute x/y at $92,$94
loop:   add16   xdelta,x, current_penloc_x,x, $92,x
        dex
        dex
        bpl     loop
        FALL_THROUGH_TO LineToImpl
.endproc ; LineImpl

;;; ============================================================
;;; LineTo

;;; 4 bytes of params, copied to $92

.proc LineToImpl

        params  := $92

        pt1     := $92
        x1      := pt1
        y1      := pt1+2

        pt2     := $96
        x2      := pt2
        y2      := pt2+2

        loop_ctr := $82
        temp_pt  := $83


        ldx     #3
:       lda     current_penloc,x     ; move pos to $96, assign params to pos
        sta     pt2,x
        lda     pt1,x
        sta     current_penloc,x
        dex
        bpl     :-

        ;; Called from elsewhere; draw $92,$94 to $96,$98; values modified
do_draw_line:
        lda     y2+1
        cmp     y1+1
        bmi     swap_start_end
        bne     L57BF
        lda     y2
        cmp     y1
        bcc     swap_start_end
        bne     L57BF

        ;; y1 == y2
        lda     x1
        ldx     x1+1
        cpx     x2+1
        bmi     draw_line_jmp
        bne     :+
        cmp     x2
        bcc     draw_line_jmp

:       ldy     x2              ; swap so x1 < x2
        sta     x2
        sty     x1
        ldy     x2+1
        stx     x2+1
        sty     x1+1
draw_line_jmp:
        jmp     DrawLine

swap_start_end:
        ldx     #3              ; Swap start/end
:       ldy     pt1,x
        lda     pt2,x
        sta     pt1,x
        tya
        sta     pt2,x
        dex
        bpl     :-

L57BF:  ldx     current_penwidth
        dex
        stx     $A2
        lda     current_penheight
        sta     $A4
        lda     #0
        sta     $A1
        sta     $A3

        lda     x1
        ldx     x1+1
        cpx     x2+1
        bmi     L57E9
        bne     L57E1
        cmp     x2
        bcc     L57E9
        bne     L57E1
        jmp     DrawLine

L57E1:  lda     $A1
        ldx     $A2
        sta     $A2
        stx     $A1

L57E9:  ldy     #5                ; do 6 points
loop:   sty     loop_ctr
        ldx     pt_offsets,y      ; offset into the pt1,pt2 structure
        ldy     #3
:       lda     pt1,x
        sta     temp_pt,y
        dex
        dey
        bpl     :-

        ldy     loop_ctr
        ldx     penwidth_flags,y  ; when =1, will add the current_penwidth
        lda     $A1,x
        clc
        adc     temp_pt
        sta     temp_pt
        bcc     :+
        inc     temp_pt+1
:
        ldx     penheight_flags,y ; when =2, will add the current_penheight
        lda     $A3,x
        clc
        adc     temp_pt+2
        sta     temp_pt+2
        bcc     :+
        inc     temp_pt+3
:
        tya
        asl     a
        asl     a
        tay

        ldx     #0
:       lda     temp_pt,x
        sta     paint_poly_points,y
        iny
        inx
        cpx     #4
        bne     :-

        ldy     loop_ctr
        dey
        bpl     loop

        copy16  paint_poly_params_addr, params_addr
        jmp     PaintPolyImpl

paint_poly_params_addr:
        .addr   paint_poly_params

;;       Points  0  1  2  3  4  5
pt_offsets:
        .byte    3, 3, 7, 7, 7, 3
penwidth_flags:
        .byte    0, 0, 0, 1, 1, 1
penheight_flags:
        .byte    0, 1, 1, 1, 0, 0

        ;; params for a PaintPoly call
paint_poly_params:
        .byte   6         ; number of points
        .byte   0
paint_poly_points:
        .res    4*6       ; points

.endproc ; LineToImpl
        DRAW_LINE_ABS_IMPL_do_draw_line := LineToImpl::do_draw_line

;;; ============================================================
;;; SetFont

.define kMaxFontHeight 16

.proc SetFontImpl
        copy16  params_addr, current_textfont ; set font to passed address

        ;; Compute addresses of each row of the glyphs.
prepare_font:
        ldy     #0              ; copy first 3 bytes of font defn (type, lastchar, height) to $FD-$FF
:       lda     (current_textfont),y
        sta     $FD,y
        iny
        cpy     #3
        bne     :-

        cmp     #kMaxFontHeight+1       ; if height >= 17, skip this next bit
        bcs     end

        ldax    current_textfont
        addax8  #3
        stax    glyph_widths    ; set $FB/$FC to start of widths

        sec
        adc     glyph_last
        bcc     :+
        inx

:       ldy     #0              ; loop 0... height-1
loop:   sta     glyph_row_lo,y
        pha
        txa
        sta     glyph_row_hi,y
        pla

        sec
        adc     glyph_last
        bcc     :+
        inx

:       bit     glyph_type   ; ($80 = double width, so double the offset)
        bpl     :+

        sec
        adc     glyph_last
        bcc     :+
        inx

:       iny
        cpy     glyph_height_p
        bne     loop
        rts

end:    EXIT_CALL MGTK::Error::font_too_big
.endproc ; SetFontImpl

glyph_row_lo:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
glyph_row_hi:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

;;; ============================================================
;;; TextWidth

;;; 3 bytes of params, copied to $A1

.proc TextWidthImpl
        jsr     MeasureText
        ldy     #3              ; Store result (X,A) at params+3
        sta     (params_addr),y
        txa
        iny
        sta     (params_addr),y
        rts
.endproc ; TextWidthImpl

        ;; Call with data at ($A1), length in $A3, result in (A,X)
.proc MeasureText
        data   := $A1
        length := $A3

        accum  := $82           ; hi
        pos    := $83

        ldx     #0              ; X=lo
        ldy     #0
        sty     accum
loop:   sty     pos
        lda     (data),y
        tay
        txa
        clc
        adc     (glyph_widths),y
        bcc     :+
        inc     accum
:       tax
        ldy     pos
        iny
        cpy     length
        bne     loop
        txa                     ; now A=lo
        RETURN  X=accum         ; A,X
.endproc ; MeasureText

;;; ============================================================

        ;; Turn the current penloc into left, right, top, and bottom.
        ;;
        ;; Inputs:
        ;;    A = width
        ;;    $FF = height
        ;;
.proc PenlocToBounds
        subax8  #1
        clc
        adc     current_penloc_x
        sta     right
        txa
        adc     current_penloc_x+1
        sta     right+1

        copy16  current_penloc_x, left

        lda     current_penloc_y
        sta     bottom
        ldx     current_penloc_y+1
        stx     bottom+1
        addax8  #1
        subax8  glyph_height_p
        stax    top
        rts
.endproc ; PenlocToBounds

;;; ============================================================

;;; 3 bytes of params, copied to $A1

.proc DrawTextImpl
        text_bits_buf := $00
        vid_addrs_table := $20

        shift_aux_ptr := $40
        shift_main_ptr := $42

        blit_mask := $80
        doublewidth_flag := $81

        remaining_width := $9A
        vid_page := $9C
        text_index := $9F
        text_addr := $A1        ; param
        text_len  := $A3        ; param
        text_width := $A4       ; computed


        jsr     maybe_unstash_low_zp
        jsr     MeasureText
        stax    text_width

        ldy     #0
        sty     text_index
        sty     $A0
        sty     clipped_left
        sty     clipped_top
        jsr     PenlocToBounds
        jsr     ClipRect
        bcc     text_clipped

        tya
        ror     a
        bcc     no_left_clip

        ldy     #0
        ldx     vid_page
left_clip_loop:
        sty     text_index
        lda     (text_addr),y
        tay
        lda     (glyph_widths),y
        clc
        adc     clipped_left             ; exit loop when first partially or
        bcc     :+                       ; fully visible glyph is found
        inx
        beq     no_left_clip
:       sta     clipped_left
        ldy     text_index
        iny
        bne     left_clip_loop

no_left_clip:
        jsr     SetUpFillMode
        jsr     SetDest

        lda     left_mod14
        clc
        adc     clipped_left
        bpl     :+
        ;; Fix for https://github.com/a2stuff/a2d/issues/505
        ;; Left clipping of a glyph needed, so need to inc `width_bytes`.
        ;; But don't want to double this, so defer the inc until later.
        ;; $A0 is used as a flag.
        dec     $A0
        adc     #14
:       sta     left_mod14

        lda     width_bytes
        inc     width_bytes
        ldy     current_mapwidth
        bpl     text_clip_ndbm

        ;; For an on-screen destination, width_bytes is set up for the
        ;; pattern blitter, which thinks in terms of double (main & aux)
        ;; transfers. We actually want single transfers here, so we need to
        ;; double it and restore the carry.
        asl     a
        tax
        lda     left_mod14
        cmp     #7
        bcs     :+
        inx
:       lda     right
        beq     :+
        inx
:       stx     width_bytes

text_clip_ndbm:
        ;; If we identified a left clip above, increase `width_bytes` now that
        ;; we're past the potential doubling.
        bit     $A0
        bpl     :+
        inc     width_bytes
:
        lda     left_mod14
        sec
        sbc     #7
        bcc     :+
        sta     left_mod14
:
        lda     #0
        rol     a              ; if left_mod14 was >= 7, then A=1 else A=0
        eor     #1             ; if left_mod14 <7, then A=1 (aux) else A=0 (main)
        sta     vid_page
        tax
        sta     LOWSCR,x       ; set starting page
        jsr     do_draw
        sta     LOWSCR

text_clipped:
        jsr     maybe_stash_low_zp
        ldax    text_width
        jmp     AdjustXPos


do_draw:
        lda     bottom
        sec
        sbc     top
        tax

        ;; Calculate offsets to the draw and blit routines so that they draw
        ;; the exact number of needed lines.
        lda     shifted_draw_line_table_low,x
        sta     shifted_draw_jmp_addr
        lda     shifted_draw_line_table_high,x
        sta     shifted_draw_jmp_addr+1

        lda     unshifted_draw_line_table_low,x
        sta     unshifted_draw_jmp_addr
        lda     unshifted_draw_line_table_high,x
        sta     unshifted_draw_jmp_addr+1

        lda     unmasked_blit_line_table_low,x
        sta     unmasked_blit_jmp_addr
        lda     unmasked_blit_line_table_high,x
        sta     unmasked_blit_jmp_addr+1

        lda     masked_blit_line_table_low,x
        sta     masked_blit_jmp_addr
        lda     masked_blit_line_table_high,x
        sta     masked_blit_jmp_addr+1

        sec
        stx     $80
        stx     $81
        lda     #0
        sbc     clipped_top
        sta     clipped_top
        tay

        ldx     #(kMaxFontHeight-1)*shifted_draw_line_size
        sec

:       lda     glyph_row_lo,y
        sta     shifted_draw_linemax+1,x
        lda     glyph_row_hi,y
        sta     shifted_draw_linemax+2,x
        txa
        sbc     #shifted_draw_line_size
        tax
        iny
        dec     $80
        bpl     :-

        ldy     clipped_top
        ldx     #(kMaxFontHeight-1)*unshifted_draw_line_size
        sec
:       lda     glyph_row_lo,y
        sta     unshifted_draw_linemax+1,x
        lda     glyph_row_hi,y
        sta     unshifted_draw_linemax+2,x
        txa
        sbc     #unshifted_draw_line_size
        tax
        iny
        dec     $81
        bpl     :-

        ldy     top
        ldx     #0

        ;; Populate the pointers in vid_addrs_table for the lines we are
        ;; going to be drawing to.
text_dest_loop:
        bit     current_mapwidth
        bmi     text_dest_dhgr

        lda     vid_addr
        clc
        adc     current_mapwidth
        sta     vid_addr
        sta     vid_addrs_table,x

        lda     vid_addr+1
        adc     #0
        sta     vid_addr+1
        sta     vid_addrs_table+1,x
        bne     text_dest_next

text_dest_dhgr:
        lda     hires_table_lo,y
        clc
        adc     left_bytes
        sta     vid_addrs_table,x

        lda     hires_table_hi,y
        ora     current_mapbits+1
        sta     vid_addrs_table+1,x

text_dest_next:
        cpy     bottom
        beq     :+
        iny
        inx
        inx
        bne     text_dest_loop
:

        ldx     #15
        lda     #0
:       sta     text_bits_buf,x
        dex
        bpl     :-
        sta     doublewidth_flag
        sta     shift_aux_ptr               ; zero
        lda     #$80
        sta     shift_main_ptr

        ldy     text_index
next_glyph:
        lda     (text_addr),y
        tay

        bit     doublewidth_flag
        bpl     :+
        sec
        adc     glyph_last
:
        tax
        lda     (glyph_widths),y
        beq     zero_width_glyph

        ldy     left_mod14
        bne     shifted_draw

        ;; Transfer one column of one glyph into the text_bits_buf[0..15]

unshifted_draw_jmp_addr := *+1
        jmp     unshifted_draw_linemax           ; patched to jump into following block


        ;; Unrolled loop from kMaxFontHeight-1 down to 0
unshifted_draw_linemax:
        .repeat kMaxFontHeight, line
        .ident (.sprintf ("unshifted_draw_line_%d", kMaxFontHeight-line-1)):
:       lda     $FFFF,x
        sta     text_bits_buf+kMaxFontHeight-line-1

        .ifndef unshifted_draw_line_size
        unshifted_draw_line_size := * - :-
        .else
        .assert unshifted_draw_line_size = * - :-, error, "unshifted_draw_line_size inconsistent"
        .endif

        .endrepeat


zero_width_glyph:
        jmp     do_blit


        ;; Transfer one column of one glyph, shifting it into
        ;; text_bits_buf[0..15] and text_bits_buf[16..31] by left_mod14 bits.

shifted_draw:
        copylohi shift_table_aux_low,y, shift_table_aux_high,y, shift_aux_ptr
        copylohi shift_table_main_low,y, shift_table_main_high,y, shift_main_ptr

shifted_draw_jmp_addr := *+1
        jmp     shifted_draw_linemax      ; patched to jump into following block


        ;; Unrolled loop from kMaxFontHeight-1 down to 0
shifted_draw_linemax:
        .repeat kMaxFontHeight, line
        .ident (.sprintf ("shifted_draw_line_%d", kMaxFontHeight-line-1)):

:       ldy     $FFFF,x             ; All of these $FFFFs are modified
        lda     (shift_main_ptr),y
        sta     text_bits_buf+16+kMaxFontHeight-line-1
        lda     (shift_aux_ptr),y
        ora     text_bits_buf+kMaxFontHeight-line-1
        sta     text_bits_buf+kMaxFontHeight-line-1

        .ifndef shifted_draw_line_size
        shifted_draw_line_size := * - :-
        .else
        .assert shifted_draw_line_size = * - :-, error, "shifted_draw_line_size inconsistent"
        .endif

        .endrepeat


do_blit:
        bit     doublewidth_flag
        bpl     :+

        inc     text_index             ; completed a double-width glyph
        lda     #0
        sta     doublewidth_flag
        lda     remaining_width
        bne     advance_x              ; always

:       txa
        tay
        lda     (glyph_widths),y
        cmp     #8
        bcs     :+
        inc     text_index             ; completed a single-width glyph
        bcc     advance_x

:       sbc     #7
        sta     remaining_width
        ror     doublewidth_flag       ; will set to negative
        lda     #7                     ; did the first 7 pixels of a
                                       ; double-width glyph
advance_x:
        clc
        adc     left_mod14
        cmp     #7
        bcs     advance_byte
        sta     left_mod14

L5BFF:  ldy     text_index
        cpy     text_len
        beq     :+
        jmp     next_glyph

:       ldy     $A0

jmp_last_blit:
        jmp     last_blit

advance_byte:
        sbc     #7
        sta     left_mod14

        ldy     $A0
        bne     :+
        jmp     first_blit

:       bmi     next_byte
        dec     width_bytes
        beq     jmp_last_blit

unmasked_blit:
unmasked_blit_jmp_addr := *+1
        jmp     unmasked_blit_linemax        ; patched to jump into block below


;;; Per JB: "looks like the quickdraw fast-path draw unclipped pattern slab"

        ;; Unrolled loop from kMaxFontHeight-1 down to 0
unmasked_blit_linemax:
        .repeat kMaxFontHeight, line
        .ident (.sprintf ("unmasked_blit_line_%d", kMaxFontHeight-line-1)):
:       lda     text_bits_buf+kMaxFontHeight-line-1
        eor     current_textback
        sta     (vid_addrs_table + 2*(kMaxFontHeight-line-1)),y

        .ifndef unmasked_blit_line_size
        unmasked_blit_line_size := * - :-
        .else
        .assert unmasked_blit_line_size = * - :-, error, "unmasked_blit_line_size inconsistent"
        .endif

        .endrepeat


next_byte:
        bit     current_mapwidth
        bpl     text_ndbm

        lda     vid_page
        eor     #1
        tax
        sta     vid_page
        sta     LOWSCR,x
        beq     :+
text_ndbm:
        inc     $A0
:
        COPY_BYTES 16, text_bits_buf+16, text_bits_buf
        jmp     L5BFF


        ;; This is the first (left-most) blit, so it needs masks. If this is
        ;; also the last blit, apply the right mask as well.
first_blit:
        ldx     vid_page
        lda     left_masks_table,x
        dec     width_bytes
        beq     single_byte_blit

        jsr     masked_blit
        jmp     next_byte

single_byte_blit:                      ; a single byte length blit; i.e. start
        and     right_masks_table,x    ; and end bytes are the same
        bne     masked_blit
        rts


        ;; This is the last (right-most) blit, so we have to set up masking.
last_blit:
        ldx     vid_page
        lda     right_masks_table,x
masked_blit:
        ora     #$80
        sta     blit_mask

masked_blit_jmp_addr := *+1
        jmp     masked_blit_linemax


;;; Per JB: "looks like the quickdraw slow-path draw clipped pattern slab"

        ;; Unrolled loop from kMaxFontHeight-1 down to 0
masked_blit_linemax:
        .repeat kMaxFontHeight, line
        .ident (.sprintf ("masked_blit_line_%d", kMaxFontHeight-line-1)):
:       lda     text_bits_buf+kMaxFontHeight-line-1
        eor     current_textback
        eor     (vid_addrs_table + 2*(kMaxFontHeight-line-1)),y
        and     blit_mask
        eor     (vid_addrs_table + 2*(kMaxFontHeight-line-1)),y
        sta     (vid_addrs_table + 2*(kMaxFontHeight-line-1)),y

        .ifndef masked_blit_line_size
        masked_blit_line_size := * - :-
        .else
        .assert masked_blit_line_size = * - :-, error, "masked_blit_line_size inconsistent"
        .endif

        .endrepeat

        rts


shifted_draw_line_table_low:
        .repeat kMaxFontHeight, line
        .byte   <.ident (.sprintf ("shifted_draw_line_%d", line))
        .endrepeat

shifted_draw_line_table_high:
        .repeat kMaxFontHeight, line
        .byte   >.ident (.sprintf ("shifted_draw_line_%d", line))
        .endrepeat

unshifted_draw_line_table_low:
        .repeat kMaxFontHeight, line
        .byte   <.ident (.sprintf ("unshifted_draw_line_%d", line))
        .endrepeat

unshifted_draw_line_table_high:
        .repeat kMaxFontHeight, line
        .byte   >.ident (.sprintf ("unshifted_draw_line_%d", line))
        .endrepeat

unmasked_blit_line_table_low:
        .repeat kMaxFontHeight, line
        .byte   <.ident (.sprintf ("unmasked_blit_line_%d", line))
        .endrepeat

unmasked_blit_line_table_high:
        .repeat kMaxFontHeight, line
        .byte   >.ident (.sprintf ("unmasked_blit_line_%d", line))
        .endrepeat

masked_blit_line_table_low:
        .repeat kMaxFontHeight, line
        .byte   <.ident (.sprintf ("masked_blit_line_%d", line))
        .endrepeat

masked_blit_line_table_high:
        .repeat kMaxFontHeight, line
        .byte   >.ident (.sprintf ("masked_blit_line_%d", line))
        .endrepeat

.endproc ; DrawTextImpl

;;; ============================================================

low_zp_stash_buffer:
poly_maxima_yh_table:
        .res    16

poly_maxima_x_frach:
        .res    16

poly_maxima_x_fracl:
        .res    16

poly_maxima_xl_table:
        .res    16

poly_maxima_xh_table:
        .res    16


;;; ============================================================
;;; InitGraf

.proc InitGrafImpl

        lda     #$71            ; %0001 lo nibble = HiRes, Page 1, Full, Graphics
        sta     $82             ; (why is high nibble 7 ???)
        jsr     SetSwitchesImpl

        ;; Initialize port
        ldx     #.sizeof(MGTK::GrafPort)-1
    DO
        lda     standard_port,x
        sta     $8A,x
        sta     current_grafport,x
        dex
    WHILE POS

        ldax    #saved_port
        jsr     assign_and_prepare_port

        copy8   #$7F, fill_eor_mask
        jsr     PaintRectImpl
        copy8   #$00, fill_eor_mask
        rts
.endproc ; InitGrafImpl

;;; ============================================================
;;; SetSwitches

;;; 1 byte param, copied to $82

;;; Toggle display softswitches
;;;   bit 0: LoRes if clear, HiRes if set
;;;   bit 1: Page 1 if clear, Page 2 if set
;;;   bit 2: Full screen if clear, split screen if set
;;;   bit 3: Graphics if clear, text if set

.proc SetSwitchesImpl
        PARAM_BLOCK params, $82
switches        .byte
        END_PARAM_BLOCK

        lda     DHIRESON        ; enable dhr graphics
        sta     SET80VID

        ldx     #3
loop:   lsr     params::switches ; shift low bit into carry
        lda     table,x
        rol     a
        tay                     ; y = table[x] * 2 + carry
        bcs     store

        lda     $C000,y         ; why load vs. store ???
        bcc     :+

store:  sta     $C000,y

:       dex
        bpl     loop
        rts

table:  .byte   <(TXTCLR / 2), <(MIXCLR / 2), <(LOWSCR / 2), <(LORES / 2)
.endproc ; SetSwitchesImpl

;;; ============================================================
;;; SetPort

.proc SetPortImpl
        ldax    params_addr
        FALL_THROUGH_TO assign_and_prepare_port
.endproc ; SetPortImpl

        ;; Call with port address in (X,A)
assign_and_prepare_port:
        stax    active_port
        FALL_THROUGH_TO prepare_port

        ;; Initializes font (if needed), port, pattern, and fill mode
prepare_port:
        lda     current_textfont+1
    IF NOT ZERO                 ; only prepare font if necessary
        jsr     SetFontImpl::prepare_font
    END_IF
        jsr     SetPortBitsImpl
        jsr     SetPatternImpl
        jmp     SetPenModeImpl

;;; ============================================================
;;; GetPort

.proc GetPortImpl
        jsr     ApplyPortToActivePort
        ldax    active_port
        FALL_THROUGH_TO store_xa_at_params
.endproc ; GetPortImpl

        ;; Store result (X,A) at params
store_xa_at_params:
        ldy     #0

        ;; Store result (X,A) at params+Y
store_xa_at_y:
        sta     (params_addr),y
        txa
        iny
        sta     (params_addr),y
        rts

;;; ============================================================
;;; InitPort

.proc InitPortImpl
        ldy     #.sizeof(MGTK::GrafPort)-1 ; Store 36 bytes at params
loop:   lda     standard_port,y
        sta     (params_addr),y
        dey
        bpl     loop
.endproc ; InitPortImpl
rts3:   rts

;;; ============================================================
;;; SetZP1

;;; 1 byte of params, copied to $82

.proc SetZP1Impl
        PARAM_BLOCK params, $82
flag    .byte
        END_PARAM_BLOCK

        lda     params::flag
        cmp     preserve_zp_flag
        beq     :+
        ;; TODO: Why not do this unconditionally?
        sta     preserve_zp_flag
:       rts
.endproc ; SetZP1Impl

;;; ============================================================
;;; SetZP2

;;; 1 byte of params, copied to $82

;;; If high bit set stash ZP $00-$43 to buffer if not already stashed.
;;; If high bit clear unstash ZP $00-$43 from buffer if not already unstashed.

.proc SetZP2Impl
        PARAM_BLOCK params, $82
flag    .byte
        END_PARAM_BLOCK

        lda     params::flag
        cmp     low_zp_stash_flag
        beq     rts3
        sta     low_zp_stash_flag
        bcc     unstash

maybe_stash:
        bit     low_zp_stash_flag
        bpl     end

        ;; Copy buffer to ZP $00-$43
stash:  COPY_BYTES $44, low_zp_stash_buffer, $00

end:    rts

maybe_unstash:
        bit     low_zp_stash_flag
        bpl     end

        ;; Copy ZP $00-$43 to buffer
unstash:
        COPY_BYTES $44, $00, low_zp_stash_buffer
        rts
.endproc ; SetZP2Impl
        maybe_stash_low_zp := SetZP2Impl::maybe_stash
        maybe_unstash_low_zp := SetZP2Impl::maybe_unstash

;;; ============================================================
;;; Version

.proc VersionImpl
        ldy     #5              ; Store 6 bytes at params
    DO
        lda     version,y
        sta     (params_addr),y
        dey
    WHILE POS
        rts

.params version
major:  .byte   1               ; 1.1.0
minor:  .byte   1
patch:  .byte   0
status: .byte   'A'             ; A = Alpha, B = Beta, F = Final
release:.byte   1               ; ???
        .byte   0               ; ???
.endparams
.endproc ; VersionImpl

;;; ============================================================

preserve_zp_flag:         ; if high bit set, ZP saved during MGTK calls
        .byte   $80

low_zp_stash_flag:
        .byte   $80

stack_ptr_stash:
        .byte   0

;;; ============================================================

;;; Standard GrafPort

.params standard_port
viewloc:        .word   0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        .word   0, 0, kScreenWidth-1, kScreenHeight-1
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         .word   0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   MGTK::textbg_black
textfont:       .addr   0
        REF_GRAFPORT_MEMBERS
.endparams

;;; ============================================================

.params saved_port
viewloc:        .word   0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        .word   0, 0, kScreenWidth-1, kScreenHeight-1
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         .word   0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   MGTK::textbg_black
textfont:       .addr   0
        REF_GRAFPORT_MEMBERS
.endparams

active_saved:           ; saved copy of $F4...$FF when ZP swapped
        .addr   saved_port
        .res    10, 0

zp_saved:               ; top half of ZP for when preserve_zp_flag set
        .res    128, 0

        ;; cursor shown/hidden flags/counts
cursor_flag:                    ; high bit clear if cursor drawn, set if not drawn
        .byte   0
cursor_count:
        .byte   $FF             ; decremented on hide, incremented on shown; 0 = visible

        DEFINE_POINT cursor_pos, 0, 0

mouse_state:
mouse_x:        .word   0
mouse_y:        .word   0
mouse_status:   .byte   0       ; bit 7 = is down, bit 6 = was down, still down

mouse_scale_x:  .byte   $00
mouse_scale_y:  .byte   $00

mouse_hooked_flag:              ; High bit set if mouse is "hooked", and calls
        .byte   0               ; bypassed; never appears to be set.

mouse_hook:
        .addr   0

cursor_hotspot_x:  .byte   $00
cursor_hotspot_y:  .byte   $00

cursor_mod7:
        .res    1

cursor_bits:
        .res    3
cursor_mask:
        .res    3

cursor_savebits:
        .res    3*MGTK::cursor_height           ; Saved 3 screen bytes per row.

cursor_data:
        kCursorDrawDataSize = 3
        .res    kCursorDrawDataSize             ; Saved values of cursor_char..cursor_y2.

pointer_cursor:
        PIXELS  ".............."
        PIXELS  ".#............"
        PIXELS  ".##..........."
        PIXELS  ".###.........."
        PIXELS  ".####........."
        PIXELS  ".#####........"
        PIXELS  ".######......."
        PIXELS  ".#.##........."
        PIXELS  "....##........"
        PIXELS  "....##........"
        PIXELS  ".....##......."
        PIXELS  ".............."

        PIXELS  "##............"
        PIXELS  "###..........."
        PIXELS  "####.........."
        PIXELS  "#####........."
        PIXELS  "######........"
        PIXELS  "#######......."
        PIXELS  "########......"
        PIXELS  "########......"
        PIXELS  "#######......."
        PIXELS  "...####......."
        PIXELS  "....####......"
        PIXELS  "....####......"

        .byte   1,1

ibeam_cursor:
        PIXELS  ".............."
        PIXELS  ".##...##......"
        PIXELS  "...#.#........"
        PIXELS  "....#........."
        PIXELS  "....#........."
        PIXELS  "....#........."
        PIXELS  "....#........."
        PIXELS  "....#........."
        PIXELS  "...#.#........"
        PIXELS  ".##...##......"
        PIXELS  ".............."
        PIXELS  ".............."

        PIXELS  ".##...##......"
        PIXELS  "####.####....."
        PIXELS  ".#######......"
        PIXELS  "...###........"
        PIXELS  "...###........"
        PIXELS  "...###........"
        PIXELS  "...###........"
        PIXELS  "...###........"
        PIXELS  ".#######......"
        PIXELS  "####.####....."
        PIXELS  ".##...##......"
        PIXELS  ".............."

        .byte   4,5

watch_cursor:
        PIXELS  ".............."
        PIXELS  "..#######....."
        PIXELS  "..#######....."
        PIXELS  ".#.......#...."
        PIXELS  ".#....#..#...."
        PIXELS  ".#..##...##..."
        PIXELS  ".#.......#...."
        PIXELS  ".#.......#...."
        PIXELS  "..#######....."
        PIXELS  "..#######....."
        PIXELS  ".............."
        PIXELS  ".............."

        PIXELS  "..#######....."
        PIXELS  ".#########...."
        PIXELS  ".#########...."
        PIXELS  "###########..."
        PIXELS  "###########..."
        PIXELS  "############.."
        PIXELS  "###########..."
        PIXELS  "###########..."
        PIXELS  ".#########...."
        PIXELS  ".#########...."
        PIXELS  "..#######....."
        PIXELS  ".............."

        .byte   5,5

system_cursor_table_lo: .byte   <pointer_cursor, <ibeam_cursor, <watch_cursor
system_cursor_table_hi: .byte   >pointer_cursor, >ibeam_cursor, >watch_cursor

.proc SetPointerCursor
        ldx     #$FF
        stx     cursor_count
        inx
        stx     cursor_flag
        lda     #<pointer_cursor
        sta     params_addr
        lda     #>pointer_cursor
        sta     params_addr+1
        FALL_THROUGH_TO SetCursorImpl
.endproc ; SetPointerCursor

;;; ============================================================
;;; SetCursor


.proc SetCursorImpl
        php
        sei

        ;; SystemCursor?
        lda     params_addr+1
    IF ZERO
        ldx     params_addr
        copy8   system_cursor_table_lo-1,x, params_addr
        copy8   system_cursor_table_hi-1,x, params_addr+1
    END_IF

        ldax    params_addr

        ;; No-op if same
        cmp     active_cursor
        bne     :+
        cpx     active_cursor+1
        beq     finish
:
        stax    active_cursor
        addax8  #MGTK::Cursor::mask
        stax    active_cursor_mask

        ldy     #MGTK::Cursor::hotspot
        lda     (params_addr),y
        sta     cursor_hotspot_x
        iny
        lda     (params_addr),y
        sta     cursor_hotspot_y

        jsr     RestoreCursorBackground
        jsr     DrawCursor

finish:
        plp
.endproc ; SetCursorImpl
srts:   rts

        cursor_bytes      := $82 ; `kCursorDrawDataSize` bytes here hold state for draw/restore
        cursor_col        := $82 ; column (0...39)
        cursor_y1         := $83 ; top row of cursor - 1
        cursor_y2         := $84 ; bottom row of cursor

        vid_ptr           := $88

.proc UpdateCursor
        lda     cursor_count           ; hidden? if so, skip
        bne     srts
        bit     cursor_flag
        bmi     srts
        FALL_THROUGH_TO DrawCursor
.endproc ; UpdateCursor

.proc DrawCursor
        lda     #0
        sta     cursor_count
        sta     cursor_flag

        lda     cursor_pos::ycoord
        clc
        sbc     cursor_hotspot_y
        sta     cursor_y1
        clc
        adc     #MGTK::cursor_height
    IF A >= #192
        lda     #191
    END_IF
        sta     cursor_y2

        ;; Compute bytes to draw
        sec
        sbc     cursor_y1       ; number of lines
        asl                     ; *= 2
        sbc     #0              ; -1
        sta     left_bytes      ; index into `cursor_bits`/`cursor_mask`

        lda     cursor_pos::xcoord
        sec
        sbc     cursor_hotspot_x
        tax
        lda     cursor_pos::xcoord+1
        sbc     #0
        bpl     :+

        txa                            ; X-coord is negative: X-reg = X-coord + 256
        ror     a                      ; Will shift in zero:  X-reg = X-coord/2 + 128
        tax                            ; Negative mod7 table starts at 252 (since 252%7 = 0), and goes backwards
        ldy     mod7_table+252-128,x   ; Index (X-coord / 2 = X-reg - 128) relative to mod7_table+252
        lda     #$FF                   ; Char index = -1
        bmi     set_divmod

:       jsr     DivMod7
set_divmod:
        sta     cursor_col             ; char index in line

        tya
        rol     a
        cmp     #7
        bcc     :+
        sbc     #7
:       tay

        sty     cursor_mod7
        copylohi shift_table_main_low,y, shift_table_main_high,y, cursor_shift_main_addr
        copylohi shift_table_aux_low,y, shift_table_aux_high,y, cursor_shift_aux_addr

        ;; Set up loop invariants (both for here and restore code)
        lda     #<LOWSCR/2
        rol     a                      ; if mod >= 7, then will be HISCR, else LOWSCR
        eor     #1

        sta     switch_sta1
        sta     switch_sta3
        sta     restore_switch_sta1
        sta     restore_switch_sta3
        eor     #1
        sta     switch_sta2
        sta     restore_switch_sta2

        ldx     #OPC_INY
        ldy     #OPC_NOP
        and     #1
    IF ZERO
        ldx     #OPC_NOP
        ldy     #OPC_INY
    END_IF
        stx     switch_iny1
        sty     switch_iny2
        stx     restore_switch_iny1
        sty     restore_switch_iny2

        ;; Stash calculations for later use in `RestoreCursorBackground`
        COPY_BYTES kCursorDrawDataSize, cursor_bytes, cursor_data

        ;; Iterate from bottom of cursor to the top
        ldx     #(MGTK::cursor_height * 3) - 1 ; index into `cursor_savebits`
        ldy     cursor_y2
dloop:
        lda     hires_table_lo,y
        sta     vid_ptr
        lda     hires_table_hi,y
        ora     #$20
        sta     vid_ptr+1

        sty     cursor_y2
        stx     left_mod14      ; save X = index into `cursor_savebits`

        ldy     left_bytes      ; index into `cursor_bits`/`cursor_mask`
        ldx     #1
    DO
active_cursor           := * + 1
        lda     $FFFF,y
        sta     cursor_bits,x
active_cursor_mask      := * + 1
        lda     $FFFF,y
        sta     cursor_mask,x
        dey
        dex
    WHILE POS

        sty     left_bytes
        lda     #0
        sta     cursor_bits+2
        sta     cursor_mask+2

        ldy     cursor_mod7
    IF NOT ZERO
        ldy     #5
      DO
        ldx     cursor_bits-1,y

        cursor_shift_main_addr := * + 1
        ora     $FF80,x
        sta     cursor_bits,y

        cursor_shift_aux_addr := * + 1
        lda     $FF00,x
        dey
      WHILE NOT ZERO
        sta     cursor_bits
    END_IF

        ldx     left_mod14      ; restore X = index into `cursor_savebits`
        ldy     cursor_col

        switch_sta1 := *+1
        sta     $C0FF
        cpy     #40
    IF CC
        lda     (vid_ptr),y
        sta     cursor_savebits,x
        ora     cursor_mask
        eor     cursor_bits
        sta     (vid_ptr),y
        dex
    END_IF

        switch_iny1 := *
        iny
        switch_sta2 := *+1
        sta     $C0FF
        cpy     #40
    IF CC
        lda     (vid_ptr),y
        sta     cursor_savebits,x
        ora     cursor_mask+1
        eor     cursor_bits+1
        sta     (vid_ptr),y
        dex
    END_IF

        switch_iny2 := *
        iny
        switch_sta3 := *+1
        sta     $C0FF
        cpy     #40
    IF_CC
        lda     (vid_ptr),y
        sta     cursor_savebits,x
        ora     cursor_mask+2
        eor     cursor_bits+2
        sta     (vid_ptr),y
        dex
    END_IF

        ldy     cursor_y2
drnext:
        dey
        cpy     cursor_y1
        beq     drts
        jmp     dloop
.endproc ; DrawCursor
drts:   rts

active_cursor        := DrawCursor::active_cursor
active_cursor_mask   := DrawCursor::active_cursor_mask


.proc RestoreCursorBackground
        lda     cursor_count    ; already hidden?
        bne     ret
        bit     cursor_flag
        bmi     ret

        ;; Unstash calculations from `DrawCursor`
        COPY_BYTES kCursorDrawDataSize, cursor_data, cursor_bytes

        ;; Iterate from bottom of cursor to the top
        ldx     #(MGTK::cursor_height * 3) - 1 ; index into `cursor_savebits`
        ldy     cursor_y2
    DO
        lda     hires_table_lo,y
        sta     vid_ptr
        lda     hires_table_hi,y
        ora     #$20
        sta     vid_ptr+1

        sty     cursor_y2

        ldy     cursor_col

        switch_sta1 := *+1
        sta     $C0FF
        cpy     #40
      IF CC
        lda     cursor_savebits,x
        sta     (vid_ptr),y
        dex
      END_IF

        switch_iny1 := *
        iny
        switch_sta2 := *+1
        sta     $C0FF
        cpy     #40
      IF CC
        lda     cursor_savebits,x
        sta     (vid_ptr),y
        dex
      END_IF

        switch_iny2 := *
        iny
        switch_sta3 := *+1
        sta     $C0FF
        cpy     #40
      IF CC
        lda     cursor_savebits,x
        sta     (vid_ptr),y
        dex
      END_IF

        ldy     cursor_y2
        dey
    WHILE Y <> cursor_y1

        sta     LOWSCR
ret:    rts
.endproc ; RestoreCursorBackground
restore_switch_sta1 := RestoreCursorBackground::switch_sta1
restore_switch_sta2 := RestoreCursorBackground::switch_sta2
restore_switch_sta3 := RestoreCursorBackground::switch_sta3
restore_switch_iny1 := RestoreCursorBackground::switch_iny1
restore_switch_iny2 := RestoreCursorBackground::switch_iny2

;;; ============================================================
;;; ShowCursor

.proc ShowCursorImpl
        php
        sei
        lda     cursor_count
        beq     done
        inc     cursor_count
        bmi     done
        beq     :+
        dec     cursor_count
:       bit     cursor_flag
        bmi     done
        jsr     DrawCursor
done:
        plp
        rts
.endproc ; ShowCursorImpl

;;; ============================================================
;;; ObscureCursor

.proc ObscureCursorImpl
        php
        sei
        jsr     RestoreCursorBackground
        lda     #$80
        sta     cursor_flag
        plp
        rts
.endproc ; ObscureCursorImpl

;;; ============================================================
;;; HideCursor

.proc HideCursorImpl
        php
        sei
        jsr     RestoreCursorBackground
        dec     cursor_count
        plp
.endproc ; HideCursorImpl
mrts:   rts

;;; ============================================================

cursor_throttle:
        .byte   0

.proc MoveCursor
        bit     use_interrupts
        bpl     :+

        .assert kKeyboardMouseStateInactive = 0, error, "kKeyboardMouseStateInactive must be 0"
        lda     kbd_mouse_state
        bne     :+
        dec     cursor_throttle
        lda     cursor_throttle
        bpl     mrts
        lda     #2
        sta     cursor_throttle
:

        ;; --------------------------------------------------

        bit     no_mouse_flag
        bmi     :+
        jsr     ReadMousePos

:       bit     no_mouse_flag
        bpl     :+
        lda     #0
        sta     mouse_status

        .assert kKeyboardMouseStateInactive = 0, error, "kKeyboardMouseStateInactive must be 0"
:       lda     kbd_mouse_state
        beq     :+
        jsr     HandleKeyboardMouse
:

        ;; --------------------------------------------------

        ldx     #2
:       lda     mouse_x,x
        cmp     cursor_pos,x
        bne     mouse_moved
        dex
        bpl     :-
        bmi     no_move

        ;; --------------------------------------------------

mouse_moved:
        jsr     WaitVBL

        ;; Budget is 4550 (VBI)

        ;; The below is currently ~7635 cycles (2137 + 5446)
        ;; First opt: 2149 + 5265 = ~7414
        ;; Second opt: 2006 + 4457 = ~6463
        ;; Third opt: 1201 + 4454 = ~5655
        ;; Fourth opt: 1019 + 4334 = ~5353

        jsr     RestoreCursorBackground
        ldx     #2
        stx     cursor_flag
:       lda     mouse_x,x
        sta     cursor_pos,x
        dex
        bpl     :-
        jsr     UpdateCursor

no_move:
.endproc ; MoveCursor
rts4:   rts

;;; ============================================================

.proc ReadMousePos
        ldy     #READMOUSE
        jsr     CallMouse
        bit     mouse_hooked_flag
        bmi     do_scale_x

        ldx     mouse_firmware_hi
        lda     MOUSE_X_LO->$C000,x
        sta     mouse_x
        lda     MOUSE_X_HI->$C000,x
        sta     mouse_x+1
        lda     MOUSE_Y_LO->$C000,x
        sta     mouse_y

        ;; Scale X
do_scale_x:
        ldy     mouse_scale_x
        beq     do_scale_y
:       asl     mouse_x
        rol     mouse_x+1
        dey
        bne     :-

        ;; Scale Y
do_scale_y:
        ldy     mouse_scale_y
        beq     done_scaling
        lda     mouse_y
:       asl     a
        dey
        bne     :-
        sta     mouse_y

done_scaling:
        bit     mouse_hooked_flag
        bmi     done
        lda     MOUSE_STATUS->$C000,x
        sta     mouse_status
done:   rts
.endproc ; ReadMousePos

;;; ============================================================
;;; GetCursorAdr

.proc GetCursorAdrImpl
        ldax    active_cursor
        jmp     store_xa_at_params
.endproc ; GetCursorAdrImpl

;;; ============================================================

;;; Inputs: Y = routine
;;; NOTE: C does not reflect call result

.proc CallMouseWithROMBankedIn
        ;; Mouse firmware inspects ROM `VERSION` byte
        bit     RDLCRAM
        php
        bit     ROMIN2          ; Bank ROM in unconditionally

        jsr     CallMouse

        plp
    IF NS
        bit     LCBANK1         ; Bank RAM back in if needed
        bit     LCBANK1
    END_IF

        rts
.endproc ; CallMouseWithROMBankedIn

;;; ============================================================

        ;; Call mouse firmware, kOperation in Y, param in A
.proc CallMouse
        proc_ptr          := $88

        bit     no_mouse_flag
        bmi     rts4

        bit     mouse_hooked_flag
        bmi     hooked
        pha
        ldx     mouse_firmware_hi
        stx     proc_ptr+1
        lda     #$00
        sta     proc_ptr
        lda     (proc_ptr),y
        sta     proc_ptr
        pla
        ldy     mouse_operand
        jmp     (proc_ptr)

hooked: jmp     (mouse_hook)
.endproc ; CallMouse


;;; Init parameters

machid: .byte   0
subid:  .byte   0
op_sys: .byte   $00
slot_num:
        .byte   $00
use_interrupts:
        .byte   $00

always_handle_irq:
        .byte   $00

savebehind_size:
        .res    2
savebehind_usage:
        .res    2

desktop_initialized_flag:
        .byte   0

save_p_reg:
        .byte   $00


;;; ============================================================
;;; StartDeskTop

;;; 12 bytes of params, copied to $82

.proc StartDeskTopImpl
        PARAM_BLOCK params, $82
machine         .byte
subid           .byte
op_sys          .byte
slot_num        .byte
use_irq         .byte
sysfontptr      .addr
savearea        .addr
savesize        .word
        END_PARAM_BLOCK

        php
        pla
        sta     save_p_reg

        COPY_BYTES 5, params::machine, machid

        lda     #$7F
        sta     standard_port::textback

        copy16  params::sysfontptr, standard_port::textfont
        copy16  params::savearea, savebehind_buffer
        copy16  params::savesize, savebehind_size

        jsr     SetIRQMode
        jsr     SetOpSys

        ldy     #MGTK::Font::height
        lda     (params::sysfontptr),y
        tax
        stx     sysfont_height
        dex
        dex
        dex
        stx     goaway_height                 ; goaway height = font height - 3

        tax
        inx
        inx
        stx     hilite_menu_rect + MGTK::Rect::y2 ; menu bar height = font height + 2

        inx
        stx     wintitle_height               ; win title height = font height + 3

        stx     menu_bar_rect + MGTK::Rect::y2
        stx     menu_hittest_rect + MGTK::Rect::y1
        stx     menu_fill_rect + MGTK::Rect::y1

        inx                                   ; font height + 4: top of desktop area
        stx     set_port_top
        stx     winframe_top
        stx     desktop_mapinfo+MGTK::MapInfo::viewloc+MGTK::Point::ycoord
        stx     desktop_mapinfo+MGTK::MapInfo::maprect+MGTK::Rect::y1

        stx     menu_item_y_table
        dex
        dex

        clc
        ldy     #$00
    DO
        txa
        adc     menu_item_y_table,y
        iny
        sta     menu_item_y_table,y
    WHILE Y < #MGTK::max_menu_items

        ldx     #0
        stx     mouse_scale_y
        inx
        stx     mouse_scale_x

        bit     subid
    IF VC
        ;; Per Technical Note: Apple IIc #1: Mouse Differences on IIe and IIc
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/aiic/tn.aiic.1.htm
        inc     mouse_scale_x
        inc     mouse_scale_y

        copy16  #vbl_iic_proc, vbl_proc_addr
    ELSE
        ;; IIe or IIgs?
        bit     RDLCRAM
        php
        bit     ROMIN2          ; Bank ROM in unconditionally

        CALL    IDROUTINE, C=1
      IF_CC
        ;; IIgs!
        copy16  #vbl_iigs_proc, vbl_proc_addr
      END_IF

        plp
      IF NS
        bit     LCBANK1         ; Bank RAM back in if needed
        bit     LCBANK1
      END_IF
    END_IF

        ldx     slot_num
        jsr     FindMouse

        bit     slot_num
        bpl     found_mouse
        txa
    IF ZERO
        EXIT_CALL MGTK::Error::no_mouse
    END_IF

        lda     slot_num
        and     #$7F
        beq     found_mouse
        cpx     slot_num
        beq     found_mouse
        EXIT_CALL $91

found_mouse:
        stx     slot_num

        lda     #$80
        sta     desktop_initialized_flag

        ldy     slot_num
        bne     no_mouse
        bit     use_interrupts
        bpl     no_mouse
        asl
        sta     use_interrupts
no_mouse:

        ldy     #params::slot_num - params
        lda     slot_num
        sta     (params_addr),y
        iny
        lda     use_interrupts
        sta     (params_addr),y
        bit     use_interrupts
        bpl     no_irq
        bit     op_sys
        bpl     no_irq

        MLI_CALL ALLOC_INTERRUPT, alloc_interrupt_params

no_irq:
        ldy     #SETMOUSE
        lda     #1

        bit     use_interrupts
        bpl     :+
        cli
        ora     #8
:
        jsr     CallMouseWithROMBankedIn ; ensure `VERSION` is accurate

        jsr     InitGrafImpl
        jsr     SetPointerCursor
        jsr     FlushEventsImpl

        lda     #0
        sta     current_window+1

reset_desktop:
        jsr     SaveParamsAndStack
        jsr     SetDesktopPort

        ;; TODO: Consider clearing `KBDSTRB` to avoid lingering keypresses.

        ;; Fills the desktop background on startup (menu left black)
        MGTK_CALL MGTK::SetPattern, desktop_pattern
        MGTK_CALL MGTK::PaintRect, desktop_mapinfo+MGTK::MapInfo::maprect
        jmp     RestoreParamsActivePort
.endproc ; StartDeskTopImpl

        DEFINE_ALLOC_INTERRUPT_PARAMS alloc_interrupt_params, InterruptHandler
        DEFINE_DEALLOC_INTERRUPT_PARAMS dealloc_interrupt_params


.proc SetIRQMode
        lda     #0
        sta     always_handle_irq

        lda     use_interrupts
        beq     irts
        ldy     #$80

        cmp     #1
        beq     irq_on
        cmp     #3
        bne     irq_err

        sty     always_handle_irq
irq_on:
        sty     use_interrupts
irts:   rts

irq_err:
        EXIT_CALL MGTK::Error::invalid_irq_setting
.endproc ; SetIRQMode

.proc SetOpSys
        lda     op_sys
        beq     is_prodos
        lsr
        beq     is_pascal

        EXIT_CALL MGTK::Error::invalid_op_sys

is_prodos:
        lda     #$80
        sta     op_sys
is_pascal:
        rts
.endproc ; SetOpSys

;;; ============================================================
;;; StopDeskTop

.proc StopDeskTopImpl
        ldy     #SETMOUSE
        lda     #MOUSE_MODE_OFF
        jsr     CallMouse
        ldy     #SERVEMOUSE
        jsr     CallMouse

        bit     use_interrupts
    IF NS
        bit     op_sys
      IF NS
        copy8   alloc_interrupt_params::int_num, dealloc_interrupt_params::int_num
        MLI_CALL DEALLOC_INTERRUPT, dealloc_interrupt_params
      END_IF
    END_IF

        lda     save_p_reg
        pha
        plp
        copy8   #0, desktop_initialized_flag
        rts
.endproc ; StopDeskTopImpl

;;; ============================================================
;;; SetUserHook

;;; 3 bytes of params, copied to $82

before_events_hook := before_events_hook_jmp + 1
after_events_hook := after_events_hook_jmp + 1
.proc SetUserHookImpl
        PARAM_BLOCK params, $82
hook_id         .byte
routine_ptr     .addr
        END_PARAM_BLOCK

        lda     params::hook_id
        cmp     #1
        bne     :+

        lda     params::routine_ptr+1
        bne     clear_before_events_hook
        sta     before_events_hook+1
        lda     params::routine_ptr
        sta     before_events_hook
        rts

:       cmp     #2
        bne     invalid_hook

        lda     params::routine_ptr+1
        bne     clear_after_events_hook
        sta     after_events_hook+1
        lda     params::routine_ptr
        sta     after_events_hook
        rts

clear_before_events_hook:
        lda     #0
        sta     before_events_hook
        sta     before_events_hook+1
        rts

clear_after_events_hook:
        lda     #0
        sta     after_events_hook
        sta     after_events_hook+1
        rts

invalid_hook:
        EXIT_CALL MGTK::Error::invalid_hook
.endproc ; SetUserHookImpl


.proc CallBeforeEventsHook
        lda     before_events_hook+1
    IF NOT ZERO
        jsr     SaveParamsAndStack

        jsr     before_events_hook_jmp
        php
        jsr     RestoreParamsActivePort
        plp
    END_IF

        rts
.endproc ; CallBeforeEventsHook
before_events_hook_jmp:
        jmp     $0000


.proc CallAfterEventsHook
        lda     after_events_hook+1
        beq     :+
        jsr     SaveParamsAndStack

        jsr     after_events_hook_jmp
        php
        jsr     RestoreParamsActivePort
        plp
:       rts
.endproc ; CallAfterEventsHook
after_events_hook_jmp:
        jmp     $0000


params_addr_save:
        .res    2

stack_ptr_save:
        .res    1


.proc HideCursorSaveParams
        jsr     HideCursorImpl
        FALL_THROUGH_TO SaveParamsAndStack
.endproc ; HideCursorSaveParams

.proc SaveParamsAndStack
        copy16  params_addr, params_addr_save
        lda     stack_ptr_stash
        sta     stack_ptr_save
        lsr     preserve_zp_flag
        rts
.endproc ; SaveParamsAndStack


.proc ShowCursorAndRestore
        jsr     ShowCursorImpl
        FALL_THROUGH_TO RestoreParamsActivePort
.endproc ; ShowCursorAndRestore

.proc RestoreParamsActivePort
        asl     preserve_zp_flag
        copy16  params_addr_save, params_addr
        ldax    active_port
        FALL_THROUGH_TO SetAndPreparePort
.endproc ; RestoreParamsActivePort

.proc SetAndPreparePort
        stax    $82
        copy8   stack_ptr_save, stack_ptr_stash

        ldy     #.sizeof(MGTK::GrafPort)-1
    DO
        copy8   ($82),y, current_grafport,y
        dey
    WHILE POS

        jmp     prepare_port
.endproc ; SetAndPreparePort


.proc SetStandardPort
        ldax    #standard_port
        bne     SetAndPreparePort ; always
.endproc ; SetStandardPort

.proc SetDesktopPort
        jsr     SetStandardPort
        MGTK_CALL MGTK::SetPortBits, desktop_mapinfo
        rts
.endproc ; SetDesktopPort


.params desktop_mapinfo
        ;; `viewloc` and `maprect` initialized by `StartDeskTopImpl`
        DEFINE_POINT viewloc, 0, 13
mapbits:        .word   $2000
mapwidth:       .byte   $80
reserved:       .res    1
        DEFINE_RECT maprect, 0, 0, kScreenWidth-1, kScreenHeight-1
        REF_MAPINFO_MEMBERS
.endparams

desktop_pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

checkerboard_pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

;;; ============================================================
;;; AttachDriver

;;; 2 bytes of params, copied to $82

.proc AttachDriverImpl
        PARAM_BLOCK params, $82
hook         .addr
mouse_state  .word
        END_PARAM_BLOCK

        bit     desktop_initialized_flag
    IF NC
        copy16  params::hook, mouse_hook

        ldax    #mouse_state
        ldy     #2
        jmp     store_xa_at_y
    END_IF

        EXIT_CALL MGTK::Error::desktop_already_initialized
.endproc ; AttachDriverImpl

;;; ============================================================
;;; PeekEvent

.proc PeekEventImpl
        clc
        .byte   OPC_BCS         ; mask next byte (sec)
        FALL_THROUGH_TO GetEventImpl
.endproc ; PeekEventImpl


;;; ============================================================
;;; GetEvent

.proc GetEventImpl
        sec                     ; masked if `PeekEvent` is called
        php
        bit     use_interrupts
        bpl     :+
        sei
        bmi     no_check

:       jsr     CheckEventsImpl

no_check:
        jsr     NextEvent
        bcs     no_event

        plp
        php
        bcc     :+              ; skip advancing tail mark if in peek mode
        sta     eventbuf_tail

:       tax
        ldy     #0              ; Store 5 bytes at params
:       lda     eventbuf,x
        sta     (params_addr),y
        inx
        iny
        cpy     #4
        bne     :-
        lda     #0
        sta     (params_addr),y
        beq     ret

no_event:
        jsr     ReturnMoveEvent

ret:    plp
        bit     use_interrupts
        bpl     :+
        cli
:       rts
.endproc ; GetEventImpl

;;; ============================================================

;;; 5 bytes of params, copied to $82

.proc PostEventImpl
        PARAM_BLOCK params, $82
kind    .byte
xcoord  .word                  ; also used for key/modifiers/window id
ycoord  .word
        END_PARAM_BLOCK

        php
        sei
        lda     params::kind
        bmi     event_ok

        cmp     #MGTK::EventKind::update
        bcs     bad_event
        cmp     #MGTK::EventKind::key_down
        beq     event_ok

        ldx     params::xcoord
        ldy     params::xcoord+1
        lda     params::ycoord
        jsr     SetMouseCoords
        jsr     SetMousePos

event_ok:
        jsr     PutEvent
        bcs     no_room
        tax

        ldy     #0
:       lda     (params_addr),y
        sta     eventbuf,x
        inx
        iny
        cpy     #MGTK::short_event_size
        bne     :-

        plp
        rts

bad_event:
        lda     #MGTK::Error::invalid_event
        bmi     error_return

no_room:
        lda     #MGTK::Error::event_queue_full
error_return:
        plp
        jmp     exit_with_a
.endproc ; PostEventImpl


        ;; Return a no_event (if mouse up) or drag event (if mouse down)
        ;; and report the current mouse position.
.proc ReturnMoveEvent
        lda     #MGTK::EventKind::no_event
        .assert MGTK::EventKind::no_event = 0, error, "MGTK::EventKind::no_event is not zero"
        tay

        bit     mouse_status
    IF NS
        lda     #MGTK::EventKind::drag
    END_IF

        ;; Y = 0
        sta     (params_addr),y         ; Store 5 bytes at params
        iny
    DO
        lda     cursor_pos-1,y
        sta     (params_addr),y
        iny
    WHILE Y <> #MGTK::event_size
        rts
.endproc ; ReturnMoveEvent


;;; ============================================================
;;; CheckEvents


.params input
state:  .byte   0

key        := *
kmods      := * + 1

xpos       := *
ypos       := * + 2
modifiers  := * + 3

        .res    4, 0
.endparams

.proc CheckEventsImpl
        bit     use_interrupts
        bpl     irq_entry
        EXIT_CALL MGTK::Error::irq_in_use

irq_entry:
        sec                     ; called from interrupt handler
        jsr     CallBeforeEventsHook
        bcc     end

        jsr     ComputeModifiers
        sta     input::modifiers

        jsr     MoveCursor      ; will consume keypress if in `kbd_mouse_state`
        lda     mouse_status    ; bit 7 = is down, bit 6 = was down, still down
        asl     a
        eor     mouse_status
        bmi     mouse           ; N = (is down & !was down)
        bcs     end             ; C = is down

        ;; --------------------------------------------------
        ;; Keyboard event?

        bit     check_kbd_flag
        bpl     mouse

        .assert kKeyboardMouseStateInactive = 0, error, "kKeyboardMouseStateInactive must be 0"
        lda     kbd_mouse_state
        bne     mouse           ; key consumed in `MoveCursor`

        lda     KBD
        bpl     end             ; no key
        and     #CHAR_MASK
        sta     input::key
        bit     KBDSTRB         ; clear strobe

        ;; Check if "MouseKeys" mode should be activated
        jsr     CheckActivateMouseKeys
        bcc     end

        lda     input::modifiers
        sta     input::kmods
        lda     #MGTK::EventKind::key_down
        sta     input::state
        bne     put_key_event   ; always

        ;; --------------------------------------------------
        ;; Mouse event?

mouse:
        bcc     up
        lda     input::modifiers
        beq     :+
        lda     #MGTK::EventKind::apple_key
        bne     set_state       ; always

:       lda     #MGTK::EventKind::button_down
        bne     set_state       ; always

up:     bit     mouse_status
        bvc     end
        lda     #MGTK::EventKind::button_up

set_state:
        sta     input::state

        COPY_BYTES 3, cursor_pos, input::key

put_key_event:
        jsr     PutEvent
        tax                     ; X = offset in `eventbuf`
        ldy     #0
    DO
        copy8   input,y, eventbuf,x
        inx
        iny
    WHILE Y <> #MGTK::short_event_size

end:    jmp     CallAfterEventsHook
.endproc ; CheckEventsImpl

;;; ============================================================
;;; Interrupt Handler

int_stash_zp:
        .res    9, 0
int_stash_rdpage2:
        .byte   0
int_stash_rd80store:
        .byte   0

.proc InterruptHandler
        cld                     ; required for interrupt handlers

body:                           ; returned by GetIntHandler

        lda     RDPAGE2         ; record softswitch state
        sta     int_stash_rdpage2
        lda     RD80STORE
        sta     int_stash_rd80store
        lda     LOWSCR
        sta     SET80STORE

        COPY_BYTES 9, $82, int_stash_zp ; preserve 9 bytes of ZP

        ldy     #SERVEMOUSE
        jsr     CallMouse
        bcs     :+
        jsr     CheckEventsImpl::irq_entry
        clc
:
        bit     always_handle_irq
        bpl     :+
        clc                     ; carry clear if interrupt handled

:       COPY_BYTES 9, int_stash_zp, $82 ; restore ZP

        lda     LOWSCR          ;  restore soft switches
        sta     CLR80STORE
        lda     int_stash_rdpage2
    IF NS
        lda     HISCR
    END_IF

        lda     int_stash_rd80store
    IF NS
        sta     SET80STORE
    END_IF

        rts
.endproc ; InterruptHandler

;;; ============================================================
;;; GetIntHandler

.proc GetIntHandlerImpl
        ldax    #InterruptHandler::body
        jmp     store_xa_at_params
.endproc ; GetIntHandlerImpl

;;; ============================================================
;;; FlushEvents

;;; This is called during init by the DAs, just before
;;; entering the input loop.

eventbuf_tail:  .byte   0
eventbuf_head:  .byte   0

kEventBufSize   = 33              ; max # of events in queue

eventbuf:
        .scope  eventbuf
        kind      := *
        key       := *+1
        modifiers := *+2
        window_id := *+1
.endscope ; eventbuf

        .res    kEventBufSize*MGTK::short_event_size

.proc FlushEventsImpl
        php
        sei
        lda     #0
        sta     eventbuf_tail
        sta     eventbuf_head
        ;; TODO: Consider clearing `KBDSTRB` to avoid a race where the
        ;; keypress hasn't been seen yet when `FlushEvents` is called.
        plp
        rts
.endproc ; FlushEventsImpl

        ;; called during PostEvent and a few other places
.proc PutEvent
        lda     eventbuf_head   ; if head is not at end, advance

    IF A = #(kEventBufSize-1)*MGTK::short_event_size
        lda     #-MGTK::short_event_size & 255 ; otherwise reset and then add
    END_IF

        clc
        adc     #MGTK::short_event_size
        cmp     eventbuf_tail           ; did head catch up with tail?
        beq     rts_with_carry_set
        sta     eventbuf_head           ; nope, maybe next time
        clc
.endproc ; PutEvent

rts_with_carry_set:
        rts

        ;; called during GetEvent
.proc NextEvent
        lda     eventbuf_tail           ; equal?
        cmp     eventbuf_head
        beq     rts_with_carry_set
    IF A = #$80
        lda     #-MGTK::short_event_size & 255
    END_IF

        clc
        adc     #MGTK::short_event_size
        RETURN  C=0
.endproc ; NextEvent


;;; ============================================================
;;; SetKeyEvent

;;; 1 byte of params, copied to $82

check_kbd_flag:  .byte   $80

.proc SetKeyEventImpl
        PARAM_BLOCK params, $82
handle_keys     .byte
        END_PARAM_BLOCK

        asl     check_kbd_flag
        ror     params::handle_keys
        ror     check_kbd_flag
        rts
.endproc ; SetKeyEventImpl

;;; ============================================================

;;; Menu drawing metrics

offset_checkmark:   .byte   2
offset_text:        .byte   9
offset_shortcut:    .byte   16
shortcut_x_adj:     .byte   9
non_shortcut_x_adj: .byte   30
sysfont_height:     .byte   0


active_menu:
        .addr   0

        ;; Modified by `StartDeskTopImpl`
        DEFINE_RECT menu_bar_rect, AS_WORD(-1), AS_WORD(-1), kScreenWidth, $C

        ;; Modified by `StartDeskTopImpl` and `HiliteMenu`
        DEFINE_RECT hilite_menu_rect, 0, 0, 0, 11

savebehind_buffer:
        .word   0

        DEFINE_RECT menu_hittest_rect, 0, 12, 0, 0

        DEFINE_RECT menu_fill_rect, 0, 12, 0, 0

menu_item_y_table:
        .res    MGTK::max_menu_items+1 ; last entry represents height of menu

menu_glyphs:
open_apple_glyph:
        .byte   $1F
solid_apple_glyph:
        .byte   $1E
        .assert (solid_apple_glyph - open_apple_glyph) = 1, error, "solid_apple_glyph must follow open_apple_glyph immediately"
checkmark_glyph:
        .byte   $1D
controlkey_glyph:
        .byte   $01

shortcut_text:
        .byte   2              ; length
        .byte   $1E
        .byte   $FF

mark_text:
        .byte   1              ; length
        .byte   $1D

menu_bar_rect_addr:
        .addr   menu_bar_rect

menu_hittest_rect_addr:
        .addr   menu_hittest_rect

mark_text_addr:
        .addr   mark_text

shortcut_text_addr:
        .addr   shortcut_text


        menu_index        := $A7
        menu_count        := $A8
        menu_item_index   := $A9
        menu_item_count   := $AA
        menu_ptr          := $AB
        menu_item_ptr     := $AD


        PARAM_BLOCK curmenu, $AF
        ;; Public members
menu_id     .byte
disabled    .byte
title       .addr
menu_items  .addr

        ;; Reserved area in menu
x_penloc   .word
x_min      .word
x_max      .word
        END_PARAM_BLOCK


        PARAM_BLOCK curmenuinfo, $BB
        ;; Reserved area before first menu item
x_min      .word
x_max      .word
        END_PARAM_BLOCK


        PARAM_BLOCK curmenuitem, $BF
        ;; Public members
options    .byte
mark_char  .byte
shortcut1  .byte
shortcut2  .byte
name       .addr
        END_PARAM_BLOCK


.proc GetMenuCount
        copy16  active_menu, $82
        ldy     #0
        lda     ($82),y
        sta     menu_count
        rts
.endproc ; GetMenuCount


.proc GetMenu
        stx     menu_index
        lda     #2
        clc
    DO
        dex
        BREAK_IF NEG
        adc     #12
    WHILE NOT ZERO

        adc     active_menu
        sta     menu_ptr
        lda     active_menu+1
        adc     #0
        sta     menu_ptr+1

        ldy     #.sizeof(MGTK::MenuBarItem)-1
    DO
        copy8   (menu_ptr),y, curmenu,y
        dey
    WHILE POS

        ldy     #.sizeof(MGTK::MenuItem)-1
    DO
        copy8   (curmenu::menu_items),y, curmenuinfo-1,y
        dey
    WHILE NOT ZERO

        copy8   (curmenu::menu_items),y, menu_item_count
        rts
.endproc ; GetMenu


.proc PutMenu
        ldy     #.sizeof(MGTK::MenuBarItem)-1
    DO
        copy8   curmenu,y, (menu_ptr),y
        dey
    WHILE POS

        ldy     #.sizeof(MGTK::MenuItem)-1
    DO
        copy8   curmenuinfo-1,y, (curmenu::menu_items),y
        dey
    WHILE NOT ZERO

        rts
.endproc ; PutMenu


.proc GetMenuItem
        stx     menu_item_index
        lda     #.sizeof(MGTK::MenuItem)
        clc
    DO
        dex
        BREAK_IF NEG
        adc     #.sizeof(MGTK::MenuItem)
    WHILE NOT ZERO

        adc     curmenu::menu_items
        sta     menu_item_ptr
        lda     curmenu::menu_items+1
        adc     #0
        sta     menu_item_ptr+1

        ldy     #.sizeof(MGTK::MenuItem)-1
    DO
        copy8   (menu_item_ptr),y, curmenuitem,y
        dey
    WHILE POS

        rts
.endproc ; GetMenuItem

.proc PutMenuItem
        ldy     #.sizeof(MGTK::MenuItem)-1
    DO
        copy8   curmenuitem,y, (menu_item_ptr),y
        dey
    WHILE POS

        rts
.endproc ; PutMenuItem

        ;; Set penloc to X=AX, Y=Y
.proc SetPenloc
        sty     current_penloc_y
        ldy     #0
        sty     current_penloc_y+1
set_x:  stax    current_penloc_x
        rts
.endproc ; SetPenloc

.proc SetFillModeXOR
        lda     #MGTK::penXOR
        FALL_THROUGH_TO SetFillMode
.endproc ; SetFillModeXOR

        ;; Set fill mode to A
.proc SetFillMode
        sta     current_penmode
        jmp     SetPenModeImpl
.endproc ; SetFillMode

.proc DoMeasureText
        jsr     PrepareTextParams
        jmp     MeasureText
.endproc ; DoMeasureText

.proc DrawText
        jsr     PrepareTextParams
        jmp     DrawTextImpl
.endproc ; DrawText

        ;; Prepare $A1,$A2 as params for TextWidth/DrawText call
        ;; ($A3 is length)
.proc PrepareTextParams
        temp_ptr := $82

        stax    temp_ptr
        tay
        iny
        bne     :+
        inx
:       styx    MeasureText::data
        ldy     #0
        lda     (temp_ptr),y
        sta     MeasureText::length
        rts
.endproc ; PrepareTextParams

.proc GetAndReturnEvent
        PARAM_BLOCK event, $82
kind       .byte
.union
mouse_pos  .tag MGTK::Point
.struct
key        .byte
modifiers  .byte
.endstruct
.endunion
        END_PARAM_BLOCK

        MGTK_CALL MGTK::GetEvent, event
        RETURN  A=event
.endproc ; GetAndReturnEvent


;;; ============================================================
;;; SetMenu

need_savebehind:
        .res    2

.proc SetMenuImpl
        temp      := $82
        max_width := $C5

        copy16  params_addr, active_menu

draw_menu_impl:
        lda     #0
        sta     savebehind_usage
        sta     savebehind_usage+1

        jsr     GetMenuCount    ; into menu_count
        jsr     HideCursorSaveParams
        jsr     SetStandardPort

        ldax    menu_bar_rect_addr
        jsr     FillAndFrameRect

        ldax    #12
        ldy     sysfont_height
        iny
        jsr     SetPenloc

        ldx     #0
menuloop:
        jsr     GetMenu
        ldax    current_penloc_x
        stax    curmenu::x_penloc
        subax8  #8
        stax    curmenu::x_min
        stax    curmenuinfo::x_min

        ldx     #0
        stx     max_width
        stx     max_width+1

itemloop:
        jsr     GetMenuItem
        bit     curmenuitem::options
        bvs     filler                  ; bit 6 - is filler

        ldax    curmenuitem::name
        jsr     DoMeasureText
        stax    temp

        lda     curmenuitem::options
        and     #3                      ; OA+SA
        ora     curmenuitem::shortcut1
    IF ZERO
        lda     shortcut_x_adj
        bne     has_shortcut
    END_IF

        lda     non_shortcut_x_adj
has_shortcut:
        clc
        adc     temp
        sta     temp
        bcc     :+
        inc     temp+1
:
        sec
        sbc     max_width
        lda     temp+1
        sbc     max_width+1
    IF POS
        copy16  temp, max_width          ; calculate max width
    END_IF

filler: ldx     menu_item_index
        inx
        cpx     menu_item_count
        bne     itemloop

        add16_8 max_width, offset_text

        lda     menu_item_count
        tax
        ldy     sysfont_height
        iny
        iny
        iny
        jsr     MultXY          ; num items * (sysfont_height+3)
        pha

        copy16  max_width, FixedDiv::dividend
        copy16  #7, FixedDiv::divisor
        jsr     FixedDiv                ; max width / 7

        ldy     FixedDiv::quotient+2
        iny
        iny
        pla
        tax
        jsr     MultXY          ; total height * ((max width / 7)+2)

        sta     need_savebehind
        sty     need_savebehind+1
        sec
        sbc     savebehind_usage
        tya
        sbc     savebehind_usage+1
    IF POS
        copy16  need_savebehind, savebehind_usage ; calculate max savebehind data needed
    END_IF

        add16   curmenuinfo::x_min, max_width, curmenuinfo::x_max

        jsr     PutMenu

        ldax    curmenu::title
        jsr     DrawText
        jsr     GetMenuAndMenuItem

        ldax    current_penloc_x
        addax8  #8
        stax    curmenu::x_max

        jsr     PutMenu

        ldax    #12
        jsr     AdjustXPos

        ldx     menu_index
        inx
        cpx     menu_count
        jne     menuloop

        jsr     ShowCursorAndRestore
        sec
        lda     savebehind_size
        sbc     savebehind_usage
        lda     savebehind_size+1
        sbc     savebehind_usage+1
    IF NEG
        EXIT_CALL MGTK::Error::insufficient_savebehind_area
    END_IF

        rts
.endproc ; SetMenuImpl
        DrawMenuImpl := SetMenuImpl::draw_menu_impl

.proc GetMenuAndMenuItem
        ldx     menu_index
        jsr     GetMenu

        ldx     menu_item_index
        jmp     GetMenuItem
.endproc ; GetMenuAndMenuItem


        ;; Fills rect (params at X,A) then inverts border
.proc FillAndFrameRect
        stax    fill_params
        stax    draw_params
        lda     #MGTK::pencopy
        jsr     SetFillMode
        MGTK_CALL MGTK::PaintRect, 0, fill_params
        lda     #MGTK::notpencopy
        jsr     SetFillMode
        MGTK_CALL MGTK::FrameRect, 0, draw_params
        rts
.endproc ; FillAndFrameRect


.proc FindMenuByIdOrFail
        jsr     FindMenuById
    IF ZERO
        EXIT_CALL MGTK::Error::menu_not_found
    END_IF
        rts
.endproc ; FindMenuByIdOrFail


        find_mode             := $C6

        find_mode_by_id       := $00        ; find menu/menu item by id
        find_menu_id          := $C7
        find_menu_item_id     := $C8

        find_mode_by_coord    := $80        ; find menu by x-coord/menu item by y-coord
                                            ; coordinate is in `cursor_pos`

        find_mode_by_shortcut := $C0        ; find menu and menu item by shortcut key
        find_shortcut         := $C9
        find_options          := $CA


.proc FindMenuById
        lda     #find_mode_by_id
find_menu:
        sta     find_mode

        jsr     GetMenuCount
        ldx     #0
loop:   jsr     GetMenu
        bit     find_mode
        bvs     find_menu_item_mode
        bmi     :+

        lda     curmenu::menu_id          ; search by menu id
        cmp     find_menu_id
        bne     next
found:  RETURN  A=curmenu::menu_id ; reload to clear Z flag

:       ldax    cursor_pos::xcoord ; search by x coordinate bounds
        cpx     curmenu::x_min+1
        bcc     next
        bne     :+
        cmp     curmenu::x_min
        bcc     next
:       cpx     curmenu::x_max+1
        bcc     found
        bne     next
        cmp     curmenu::x_max
        bcs     next
        bcc     found

find_menu_item_mode:
        jsr     FindMenuItem
        bne     found

next:   ldx     menu_index
        inx
        cpx     menu_count
        bne     loop
        RETURN  A=#0
.endproc ; FindMenuById

find_menu := FindMenuById::find_menu


.proc FindMenuItem
        ldx     #0
loop:   jsr     GetMenuItem
        ldx     menu_item_index
        inx
        bit     find_mode
        bvs     find_by_shortcut
        bmi     :+

        cpx     find_menu_item_id
        bne     next
        rts

:       lda     menu_item_y_table,x
        cmp     cursor_pos::ycoord
        bcc     next
        rts

find_by_shortcut:
        lda     find_shortcut
        and     #CHAR_MASK
        cmp     curmenuitem::shortcut1
        beq     :+
        cmp     curmenuitem::shortcut2
        bne     next

:       cmp     #$20             ; is control char
        bcc     found
        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
        bne     next

        lda     curmenuitem::options
        and     find_options
        bne     found

next:   cpx     menu_item_count
        bne     loop
        ldx     #0
found:  rts
.endproc ; FindMenuItem


;;; ============================================================
;;; HiliteMenu

;;; 2 bytes of params, copied to $C7

.proc HiliteMenuImpl
        menu_param := $C7

        lda     menu_param
    IF ZERO
        lda     cur_open_menu_id
        sta     menu_param
    END_IF

        jsr     FindMenuByIdOrFail

do_hilite:
        jsr     HideCursorSaveParams
        jsr     SetStandardPort
        jsr     HiliteMenu
        jmp     ShowCursorAndRestore
.endproc ; HiliteMenuImpl

        ;; Highlight/Unhighlight top level menu item
.proc HiliteMenu
        ldx     #1
loop:   lda     curmenu::x_min,x
        sta     hilite_menu_rect+MGTK::Rect::x1,x
        lda     curmenu::x_max,x
        sta     hilite_menu_rect+MGTK::Rect::x2,x

        lda     curmenuinfo::x_min,x
        sta     menu_hittest_rect+MGTK::Rect::x1,x
        sta     menu_fill_rect+MGTK::Rect::x1,x

        lda     curmenuinfo::x_max,x
        sta     menu_hittest_rect+MGTK::Rect::x2,x
        sta     menu_fill_rect+MGTK::Rect::x2,x

        dex
        bpl     loop

        jsr     SetFillModeXOR
        MGTK_CALL MGTK::PaintRect, hilite_menu_rect
        rts
.endproc ; HiliteMenu

;;; ============================================================
;;; MenuKey

;;; 4 bytes of params, copied to $C7

.proc MenuKeyImpl
        PARAM_BLOCK params, $C7
menu_id    .byte
menu_item  .byte
which_key  .byte
key_mods   .byte
        END_PARAM_BLOCK

        lda     params::which_key
        cmp     #CHAR_ESCAPE
        bne     :+

        lda     params::key_mods
        bne     :+
        jsr     KeyboardMouse
        jmp     MenuSelectImpl

:       lda     #find_mode_by_shortcut
        jsr     find_menu
        beq     not_found

        lda     curmenu::disabled
        bmi     not_found

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
        bne     not_found

        lda     curmenu::menu_id
        sta     cur_open_menu_id
        bne     found

not_found:
        lda     #0
        tax
found:  ldy     #0
        sta     (params_addr),y
        iny
        txa
        sta     (params_addr),y
        bne     HiliteMenuImpl::do_hilite
        rts
.endproc ; MenuKeyImpl


.proc FindMenuAndMenuItem
        jsr     FindMenuByIdOrFail
        jsr     FindMenuItem
        cpx     #0
.endproc ; FindMenuAndMenuItem
rrts:   rts

.proc FindMenuItemOrFail
        jsr     FindMenuAndMenuItem
        bne     rrts
        EXIT_CALL MGTK::Error::menu_item_not_found
.endproc ; FindMenuItemOrFail


;;; ============================================================
;;; DisableItem

;;; 3 bytes of params, copied to $C7

.proc DisableItemImpl
        PARAM_BLOCK params, $C7
menu_id    .byte
menu_item  .byte
disable    .byte
        END_PARAM_BLOCK


        jsr     FindMenuItemOrFail

        asl     curmenuitem::options
        ror     params::disable
        ror     curmenuitem::options

        jmp     PutMenuItem
.endproc ; DisableItemImpl

;;; ============================================================
;;; CheckItem

;;; 3 bytes of params, copied to $C7

.proc CheckItemImpl
        PARAM_BLOCK params, $C7
menu_id    .byte
menu_item  .byte
check      .byte
        END_PARAM_BLOCK

        jsr     FindMenuItemOrFail

        lda     params::check
    IF NOT ZERO
        lda     #MGTK::MenuOpt::item_is_checked
        ora     curmenuitem::options
        bne     set_options            ; always
    END_IF

        lda     #AS_BYTE(~MGTK::MenuOpt::item_is_checked)
        and     curmenuitem::options

set_options:
        sta     curmenuitem::options
        jmp     PutMenuItem
.endproc ; CheckItemImpl

;;; ============================================================
;;; DisableMenu

;;; 2 bytes of params, copied to $C7

.proc DisableMenuImpl
        PARAM_BLOCK params, $C7
menu_id    .byte
disable    .byte
        END_PARAM_BLOCK

        jsr     FindMenuByIdOrFail

        asl     curmenu::disabled
        ror     params::disable
        ror     curmenu::disabled

        ldx     menu_index
        jmp     PutMenu
.endproc ; DisableMenuImpl

;;; ============================================================
;;; MenuSelect

cur_open_menu_id:
        .byte   0

cur_hilited_menu_item:
        .byte   0

was_in_menu_flag:
        .byte   0

.proc MenuSelectImpl
        PARAM_BLOCK params, $C7
menu_id    .byte
menu_item  .byte
        END_PARAM_BLOCK

        jsr     GetMenuCount
        jsr     SaveParamsAndStack
        jsr     SetStandardPort

        lda     #0
        sta     cur_open_menu_id
        sta     cur_hilited_menu_item
        sta     was_in_menu_flag
        sta     movement_cancel

        ;; Initiated with mouse or keyboard?
        bit     kbd_mouse_state
        jpl     in_menu_bar     ; use mouse coords for menu

        lda     #kKeyboardMouseStateInactive
        sta     kbd_mouse_state
        ldx     #0
        jsr     GetMenu         ; X = index
        lda     curmenu::menu_id
        jmp     imb_change

        ;; --------------------------------------------------

event_loop:
        COPY_BYTES kLastCursorPosLen, cursor_pos::xcoord, last_cursor_pos

        jsr     GetAndReturnEvent

        ;; --------------------

        cmp     #MGTK::EventKind::button_down
        jeq     handle_click

        ;; --------------------

    IF A = #MGTK::EventKind::button_up
        bit     was_in_menu_flag
        jmi     handle_click
        lda     cur_open_menu_id
        bne     event_loop
        jeq     handle_click    ; always
    END_IF

        ;; --------------------

    IF A = #MGTK::EventKind::key_down
        ;; Set up `sel_menu_*`
        lda     menu_index    ; TODO: Verify this is valid
        sta     sel_menu_index
        sta     last_menu_index
        lda     cur_hilited_menu_item
        sta     sel_menu_item_index

        ;; BUG: hit 'A' when menu showing, redraws
        ;; `menu_index` changes

        ;; Process the key
        lda     GetAndReturnEvent::event::modifiers
        sta     set_input_modifiers
        lda     GetAndReturnEvent::event::key
        jsr     HandleMenuKey

        ;; Done?
        bit     movement_cancel
      IF NS
        ;; Menu selection or cancel
        jsr     close_menu
        jsr     RestoreParamsActivePort

        lda     sel_menu_item_index
       IF ZERO
        ;; Cancel - just exit with 0,0
        tax
        jmp     store_xa_at_params
       END_IF

        ldx     sel_menu_index
        jsr     GetMenu
        lda     curmenu::menu_id
        pha                     ; A = menu id
        ldx     cur_hilited_menu_item ; left non-zero if selected
       IF ZERO
        sta     HiliteMenuImpl::menu_param
        jsr     HiliteMenuImpl
       END_IF
        pla                     ; A = menu id
        ldx     sel_menu_item_index
        jmp     store_xa_at_params
      END_IF

        ;; Did `sel_menu_index` change?
        ldx     sel_menu_index
      IF X <> last_menu_index
        lda     #0
        sta     cur_hilited_menu_item
        jsr     GetMenu         ; X = index
        lda     curmenu::menu_id
        jmp     imb_change
      END_IF

        ;; Did `sel_menu_item_index` change?
        ldx     sel_menu_item_index
      IF X <> cur_hilited_menu_item
        jmp     imi_change
      END_IF

        jmp     event_loop
    END_IF

        ;; --------------------

    IF A NOT_IN #MGTK::EventKind::drag, #MGTK::EventKind::no_event
        jmp     event_loop
    END_IF

        ;; Was there a move?
        ldx     #kLastCursorPosLen-1
    DO
        lda     cursor_pos,x
        cmp     last_cursor_pos,x
        bne     :+
        dex
    WHILE POS
        jmp     event_loop      ; no move, ignore
:
        ;; Moved - mouse pos dominates
        MGTK_CALL MGTK::MoveTo, mouse_state
        MGTK_CALL MGTK::InRect, menu_bar_rect
        bne     in_menu_bar
        lda     cur_open_menu_id
        jeq     event_loop

        MGTK_CALL MGTK::InRect, menu_hittest_rect     ; test in menu
        bne     in_menu_item
        jsr     UnhiliteCurMenuItem
        jmp     event_loop

        ;; --------------------------------------------------
        ;; Tear down menu

handle_click:
        jsr     close_menu
        FALL_THROUGH_TO restore

        ;; --------------------------------------------------
        ;; Exit menu loop
restore:
        jsr     RestoreParamsActivePort

        lda     #0
        ldx     cur_hilited_menu_item
    IF NOT ZERO
        lda     cur_open_menu_id
    END_IF
        jmp     store_xa_at_params

        ;; --------------------------------------------------
        ;; Over an item in the menu bar
in_menu_bar:
        jsr     UnhiliteCurMenuItem

        lda     #find_mode_by_coord
        jsr     find_menu

        cmp     cur_open_menu_id
        jeq     event_loop
imb_change:
        pha
        jsr     HideMenu
        pla
        sta     cur_open_menu_id

        jsr     DrawMenuBar
        jmp     event_loop

        ;; --------------------------------------------------
        ;; Over an item the current menu
in_menu_item:
        lda     #find_mode_by_coord
        sta     was_in_menu_flag
        sta     find_mode
        jsr     FindMenuItem
        cpx     cur_hilited_menu_item
        jeq     event_loop

imi_change:
        lda     curmenu::disabled
        ora     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
    IF NOT ZERO
        ldx     #0
    END_IF
        txa
        pha
        jsr     HiliteMenuItem
        pla
        sta     cur_hilited_menu_item
        jsr     HiliteMenuItem

        jmp     event_loop

        ;; --------------------------------------------------

close_menu:
        lda     cur_hilited_menu_item
        jeq     HideMenu        ; unhilite menu bar item

        jsr     HideCursorImpl  ; leaves menu bar item alone
        ldx     menu_index
        jsr     GetMenu
        jsr     SetStandardPort
        jmp     RestoreMenuSavebehind

        ;; --------------------------------------------------

        ;; Keyboard navigation of menu
.proc HandleMenuKey
        pha
        ldx     sel_menu_index
        jsr     GetMenu
        pla

    IF A = #CHAR_ESCAPE
        ;; Escape - exit menu loop with no selection
        lda     #0
        sta     sel_menu_index
        sta     sel_menu_item_index
        sta     cur_hilited_menu_item ; ignore it
        lda     #$80
        sta     movement_cancel
        rts
    END_IF

    IF A = #CHAR_RETURN
        ;; Return - exit menu loop with selection
        lda     #$80
        sta     movement_cancel
        rts
    END_IF

    IF A = #CHAR_UP
      DO
        bit     curmenu::disabled
        bmi     zero

        dec     sel_menu_item_index
       IF NEG
        ldx     menu_item_count
        stx     sel_menu_item_index
       END_IF

        ldx     sel_menu_item_index
        BREAK_IF ZERO
        dex
        jsr     GetMenuItem

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
      WHILE NOT ZERO

        jmp     finish
    END_IF

    IF A = #CHAR_DOWN
      DO
        bit     curmenu::disabled
        bmi     zero

        inc     sel_menu_item_index

        lda     sel_menu_item_index
        cmp     menu_item_count
        bcc     :+              ; TODO: `BLE` ?
        beq     :+

zero:   lda     #0
        sta     sel_menu_item_index

:       ldx     sel_menu_item_index
        BREAK_IF ZERO
        dex
        jsr     GetMenuItem
        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
      WHILE NOT ZERO

        jmp     finish
    END_IF

    IF A = #CHAR_RIGHT
        copy8   #0, sel_menu_item_index

        inc     sel_menu_index
        ldx     sel_menu_index
      IF X GE menu_count
        sta     sel_menu_index
      END_IF

        jmp     finish
    END_IF

    IF A = #CHAR_LEFT
        copy8   #0, sel_menu_item_index

        dec     sel_menu_index
      IF NEG
        ldx     menu_count
        dex
        stx     sel_menu_index
      END_IF

        jmp     finish
    END_IF

        jsr     KbdMenuByShortcut
    IF CS
        copy8   #$80, movement_cancel
        copy8   #0, cur_hilited_menu_item ; ignore it
    END_IF

        ldx     sel_menu_index
        jsr     GetMenu

finish: rts
.endproc ; HandleMenuKey

.proc KbdMenuByShortcut
        sta     find_shortcut
        lda     set_input_modifiers
        and     #3
        sta     find_options

        lda     cur_open_menu_id
        pha
        lda     cur_hilited_menu_item
        pha

        lda     #find_mode_by_shortcut
        jsr     find_menu
        beq     fail

        stx     sel_menu_item_index
        lda     curmenu::disabled
        bmi     fail

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
        bne     fail

        lda     z:menu_index
        sta     sel_menu_index
        sec
        .byte   OPC_BCC         ; mask next byte (clc)

fail:   clc
        pla
        sta     cur_hilited_menu_item
        pla
        sta     cur_open_menu_id
        sta     find_menu_id
        rts
.endproc ; KbdMenuByShortcut

;;; Used to track selection changes via keyboard. These are only valid
;;; for the duration of a `MenuSelectImpl` call, while processing
;;; an `EventKind::key_down` event.
sel_menu_index:
        .byte   0
sel_menu_item_index:
        .byte   0
last_menu_index:
        .byte   0

kLastCursorPosLen = 3           ; don't bother with Y high byte
last_cursor_pos:
        .res    kLastCursorPosLen
.endproc ; MenuSelectImpl

;;; ============================================================

        savebehind_left_bytes := $82
        savebehind_bottom := $83

        savebehind_buf_addr := $8E
        savebehind_vid_addr := $84
        savebehind_mapwidth := $90


.proc SetUpMenuSavebehind
        lda     curmenuinfo::x_min+1
        ldx     curmenuinfo::x_min
        jsr     DivMod7
        sta     savebehind_left_bytes

        lda     curmenuinfo::x_max+1
        ldx     curmenuinfo::x_max
        jsr     DivMod7
        sec
        sbc     savebehind_left_bytes
        sta     savebehind_mapwidth

        copy16  savebehind_buffer, savebehind_buf_addr

        ldy     menu_item_count
        ldx     menu_item_y_table,y ; height of menu
        inx
        stx     savebehind_bottom
        stx     menu_fill_rect+MGTK::Rect::y2
        stx     menu_hittest_rect+MGTK::Rect::y2

        ldx     sysfont_height
        inx
        inx
        inx
        stx     menu_fill_rect+MGTK::Rect::y1
        stx     menu_hittest_rect+MGTK::Rect::y1
        rts
.endproc ; SetUpMenuSavebehind

.proc SetUpRectSavebehind
        rect := $92

        lda     rect+MGTK::Rect::x1+1
        ldx     rect+MGTK::Rect::x1
        jsr     DivMod7
        sta     savebehind_left_bytes

        lda     rect+MGTK::Rect::x2+1
        ldx     rect+MGTK::Rect::x2
        jsr     DivMod7
        sec
        sbc     savebehind_left_bytes
        sta     savebehind_mapwidth

        copy16  savebehind_buffer, savebehind_buf_addr

        lda     rect+MGTK::Rect::y2
        sta     savebehind_bottom

        RETURN  X=rect+MGTK::Rect::y1
.endproc ; SetUpRectSavebehind

.proc SavebehindGetVidaddr
        lda     hires_table_lo,x
        clc
        adc     savebehind_left_bytes
        sta     savebehind_vid_addr
        lda     hires_table_hi,x
        ora     #$20
        sta     savebehind_vid_addr+1
        rts
.endproc ; SavebehindGetVidaddr

;;; ============================================================

.proc SaveScreenRectImpl
        jsr     SetUpRectSavebehind
        FALL_THROUGH_TO DoSavebehind
.endproc ; SaveScreenRectImpl

.proc DoSavebehind
loop:   jsr     SavebehindGetVidaddr
        sta     HISCR
        jsr     row
        sta     LOWSCR
        jsr     row

        inx
        cpx     savebehind_bottom
        bcc     loop
        beq     loop

        rts

row:    ldy     savebehind_mapwidth
:       lda     (savebehind_vid_addr),y
        sta     (savebehind_buf_addr),y
        dey
        bpl     :-
        FALL_THROUGH_TO SavebehindNextLine
.endproc ; DoSavebehind

.proc SavebehindNextLine
        lda     savebehind_buf_addr
        sec                     ; note: extra +1
        adc     savebehind_mapwidth
        sta     savebehind_buf_addr
        bcc     :+
        inc     savebehind_buf_addr+1
:       rts
.endproc ; SavebehindNextLine

.proc RestoreScreenRectImpl
        jsr     SetUpRectSavebehind
        jmp     RestoreSavebehind
.endproc ; RestoreScreenRectImpl

.proc RestoreMenuSavebehind
        jsr     SetUpMenuSavebehind
        FALL_THROUGH_TO RestoreSavebehind
.endproc ; RestoreMenuSavebehind

.proc RestoreSavebehind
loop:   jsr     SavebehindGetVidaddr
        sta     HISCR
        jsr     row

        sta     LOWSCR
        jsr     row

        inx
        cpx     savebehind_bottom
        bcc     loop            ; TODO: `BLE` ?
        beq     loop
        jmp     ShowCursorImpl

row:    ldy     savebehind_mapwidth
    DO
        lda     (savebehind_buf_addr),y
        sta     (savebehind_vid_addr),y
        dey
    WHILE POS
        bmi     SavebehindNextLine ; always
.endproc ; RestoreSavebehind


dmrts:  rts


.proc HideMenu
        clc
        .byte   OPC_BCS         ; mask next byte (sec)
        FALL_THROUGH_TO DrawMenuBar
.endproc ; HideMenu


.proc DrawMenuBar
        sec                     ; masked if `HideMenu` is called
        lda     cur_open_menu_id
        beq     dmrts
        php

        sta     find_menu_id
        jsr     FindMenuById
        jsr     HideCursorImpl
        jsr     HiliteMenu

        plp
        bcc     RestoreMenuSavebehind

        jsr     SetUpMenuSavebehind
        jsr     DoSavebehind

        jsr     SetStandardPort

        ldax    menu_hittest_rect_addr
        jsr     FillAndFrameRect
        inc16   menu_fill_rect+MGTK::Rect::x1
        dec16   menu_fill_rect+MGTK::Rect::x2

        jsr     GetMenuAndMenuItem

        ldx     #0
loop:   jsr     GetMenuItem
        bit     curmenuitem::options
        bvc     :+

        jsr     DrawFiller
        jmp     next

:       lda     curmenuitem::options
        and     #MGTK::MenuOpt::item_is_checked
        beq     no_mark

        lda     offset_checkmark
        jsr     MovetoMenuitem

        lda     checkmark_glyph
        sta     mark_text+1

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::item_has_mark
        beq     :+
        lda     curmenuitem::mark_char
        sta     mark_text+1

:       ldax    mark_text_addr
        jsr     DrawText
        jsr     GetMenuAndMenuItem

no_mark:
        lda     offset_text
        jsr     MovetoMenuitem

        ldax    curmenuitem::name
        jsr     DrawText

        jsr     GetMenuAndMenuItem

        lda     #2              ; default is modifier + character
        sta     shortcut_text

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::open_apple | MGTK::MenuOpt::solid_apple
        .assert MGTK::MenuOpt::open_apple = 1, error, "MGTK::MenuOpt::open_apple must be 1"
        .assert MGTK::MenuOpt::solid_apple = 2, error, "MGTK::MenuOpt::solid_apple must be 2"
        bne     oa_sa

        lda     curmenuitem::shortcut1
        beq     no_shortcut

        ;; Special case: if both the same, use glyph at that code point
        cmp     curmenuitem::shortcut2
        bne     :+
        dec     shortcut_text   ; just use single character
        sta     shortcut_text+1
        bne     offset          ; always
:

        ldx     controlkey_glyph
        stx     shortcut_text+1
        ora     #$40            ; control -> uppercase
        bne     sst             ; always

oa_sa:  cmp     #MGTK::MenuOpt::open_apple | MGTK::MenuOpt::solid_apple
        bne     :+
        lda     #MGTK::MenuOpt::open_apple ; just show OA
:       tax
        lda     open_apple_glyph-MGTK::MenuOpt::open_apple,x
        sta     shortcut_text+1

        lda     curmenuitem::shortcut1
sst:    sta     shortcut_text+2

offset: lda     offset_shortcut
        jsr     MovetoFromright

        ldax    shortcut_text_addr
        jsr     DrawText
        jsr     GetMenuAndMenuItem

no_shortcut:
        lda     curmenu::disabled
        ora     curmenuitem::options
        bpl     next

        jsr     DimMenuitem

next:   ldx     menu_item_index
        inx
        cpx     menu_item_count
        beq     :+
        jmp     loop
:       jmp     ShowCursorImpl
.endproc ; DrawMenuBar


.proc MovetoMenuitem
        ldx     menu_item_index
        ldy     menu_item_y_table+1,x ; ???
        dey
        ldx     curmenuinfo::x_min+1
        addax8  curmenuinfo::x_min
        jmp     SetPenloc
.endproc ; MovetoMenuitem


.proc DimMenuitem
        ldx     menu_item_index
        ldy     menu_item_y_table,x
        iny
        sty     menu_item_rect+MGTK::Rect::y1
        lda     menu_item_y_table+1,x
        sta     menu_item_rect+MGTK::Rect::y2

        MGTK_CALL MGTK::SetPattern, checkerboard_pattern

        lda     #MGTK::penOR
ep2:    jsr     SetFillMode

        add16   curmenuinfo::x_min, #1, menu_item_rect+MGTK::Rect::x1
        sub16   curmenuinfo::x_max, #1, menu_item_rect+MGTK::Rect::x2

        MGTK_CALL MGTK::PaintRect, menu_item_rect
        MGTK_CALL MGTK::SetPattern, standard_port::pattern

        jmp     SetFillModeXOR
.endproc ; DimMenuitem

.proc DrawFiller
        ldx     menu_item_index
        ldy     sysfont_height
        iny                     ; /= 2, but round up
        tya
        lsr
        clc
        adc     menu_item_y_table,x
        sta     menu_item_rect+MGTK::Rect::y1
        sta     menu_item_rect+MGTK::Rect::y2

        MGTK_CALL MGTK::SetPattern, checkerboard_pattern

        lda     #MGTK::pencopy
        beq     DimMenuitem::ep2 ; always
.endproc ; DrawFiller

        DEFINE_RECT menu_item_rect, 0, 0, 0, 0

        ;; Move to the given distance from the right side of the menu.
.proc MovetoFromright
        sta     $82
        ldax    curmenuinfo::x_max
        subax8  $82
        jmp     SetPenloc::set_x
.endproc ; MovetoFromright

.proc UnhiliteCurMenuItem
        jsr     HiliteMenuItem
        lda     #0
        sta     cur_hilited_menu_item
.endproc ; UnhiliteCurMenuItem
hmrts:  rts

.proc HiliteMenuItem
        ldx     cur_hilited_menu_item
        beq     hmrts
        ldy     menu_item_y_table-1,x
        sty     menu_fill_rect+MGTK::Rect::y1
        ldy     menu_item_y_table,x
        sty     menu_fill_rect+MGTK::Rect::y2
        jsr     HideCursorImpl

        jsr     SetFillModeXOR
        MGTK_CALL MGTK::PaintRect, menu_fill_rect
        jmp     ShowCursorImpl
.endproc ; HiliteMenuItem

;;; ============================================================
;;; InitMenu

;;; 4 bytes of params, copied to $82

.proc InitMenuImpl
        PARAM_BLOCK params, $82
solid_char      .byte
open_char       .byte
check_char      .byte
control_char    .byte
        END_PARAM_BLOCK

        COPY_BYTES 4, params, menu_glyphs

        copy16  standard_port::textfont, params
        lda     #2
        sta     offset_checkmark
        ldx     #16
        ldy     #0
        lda     (params),y
        asl
        ldy     #30
        bcs     :+                    ; branch if double-width font

        lda     #9
        sta     offset_text
        sta     shortcut_x_adj
        stx     offset_shortcut
        sty     non_shortcut_x_adj
        rts

:       stx     offset_text
        stx     shortcut_x_adj
        sty     offset_shortcut
        lda     #51
        sta     non_shortcut_x_adj
        rts
.endproc ; InitMenuImpl

;;; ============================================================
;;; SetMark

;;; 4 bytes of params, copied to $C7

.proc SetMarkImpl
        PARAM_BLOCK params, $C7
menu_id    .byte
menu_item  .byte
set_char   .byte
mark_char  .byte
        END_PARAM_BLOCK


        jsr     FindMenuItemOrFail

        lda     params::set_char
        beq     :+

        lda     #MGTK::MenuOpt::item_has_mark
        ora     curmenuitem::options
        sta     curmenuitem::options

        lda     params::mark_char
        sta     curmenuitem::mark_char
        jmp     PutMenuItem

:       lda     #$FF^MGTK::MenuOpt::item_has_mark
        and     curmenuitem::options
        sta     curmenuitem::options
        jmp     PutMenuItem
.endproc ; SetMarkImpl

.struct Bitmap
xcoord  .word
ycoord  .word
width   .byte
height  .byte
bits    .addr
.endstruct

.params up_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   19,10
        .addr   up_scroll_bitmap
.endparams

.params down_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   19,10
        .addr   down_scroll_bitmap
.endparams

.params left_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   20,9
        .addr   left_scroll_bitmap
.endparams

.params right_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   18,9
        .addr   right_scroll_bitmap
.endparams

.params resize_box_params
xcoord: .res    2
ycoord: .res    2
        .byte   20,10
        .addr   resize_box_bitmap
.endparams

        ;;  Up Scroll
up_scroll_bitmap:
        PIXELS  "....................."
        PIXELS  "..........##........."
        PIXELS  "........##..##......."
        PIXELS  "......##......##....."
        PIXELS  "....##..........##..."
        PIXELS  "..######......######."
        PIXELS  "......##......##....."
        PIXELS  "......##......##....."
        PIXELS  "......##########....."
        PIXELS  "....................."
        PIXELS  ".####################"

        ;; Down Scroll
down_scroll_bitmap:
        PIXELS  ".####################"
        PIXELS  "....................."
        PIXELS  "......##########....."
        PIXELS  "......##......##....."
        PIXELS  "......##......##....."
        PIXELS  "..######......######."
        PIXELS  "....##..........##..."
        PIXELS  "......##......##....."
        PIXELS  "........##..##......."
        PIXELS  "..........##........."
        PIXELS  "....................."

        ;;  Left Scroll
left_scroll_bitmap:
        PIXELS  "....................."
        PIXELS  "..........##........#"
        PIXELS  "........####........#"
        PIXELS  "......##..########..#"
        PIXELS  "....##..........##..#"
        PIXELS  "..##............##..#"
        PIXELS  "....##..........##..#"
        PIXELS  "......##..########..#"
        PIXELS  "........####........#"
        PIXELS  "..........##........#"

        ;; Right Scroll
right_scroll_bitmap:
        PIXELS  "....................."
        PIXELS  "#........##.........."
        PIXELS  "#........####........"
        PIXELS  "#..########..##......"
        PIXELS  "#..##..........##...."
        PIXELS  "#..##............##.."
        PIXELS  "#..##..........##...."
        PIXELS  "#..########..##......"
        PIXELS  "#........####........"
        PIXELS  "#........##.........."

        ;; Resize Box
resize_box_bitmap:
        PIXELS  "#####################"
        PIXELS  "#...................#"
        PIXELS  "#..##########.......#"
        PIXELS  "#..##......#######..#"
        PIXELS  "#..##......##...##..#"
        PIXELS  "#..##......##...##..#"
        PIXELS  "#..##########...##..#"
        PIXELS  "#....##.........##..#"
        PIXELS  "#....#############..#"
        PIXELS  "#...................#"
        PIXELS  "#####################"

up_scroll_addr:
        .addr   up_scroll_params

down_scroll_addr:
        .addr   down_scroll_params

left_scroll_addr:
        .addr   left_scroll_params

right_scroll_addr:
        .addr   right_scroll_params

resize_box_addr:
        .addr   resize_box_params

current_window:
        .word   0

sel_window_id:
        .byte   0

found_window:
        .word   0

target_window_id:
        .byte   0

        ;; The root window is not a real window, but a structure whose
        ;; nextwinfo field lines up with current_window.
root_window_addr:
        .addr   current_window - MGTK::Winfo::nextwinfo


        which_control        := $8C
        which_control_horiz  := $00
        which_control_vert   := $80

        previous_window      := $A7
        window               := $A9


        ;; First 12 bytes of winfo only
        PARAM_BLOCK current_winfo, $AB
id         .byte
options    .byte
title      .addr
hscroll    .byte
vscroll    .byte
hthumbmax  .byte
hthumbpos  .byte
vthumbmax  .byte
vthumbpos  .byte
status     .byte
reserved   .byte
        END_PARAM_BLOCK


        ;; First 16 bytes of win's grafport only
        PARAM_BLOCK current_winport, $B7
viewloc    .tag MGTK::Point
mapbits    .addr
mapwidth   .byte
reserved   .byte
maprect    .tag MGTK::Rect
        END_PARAM_BLOCK

        PARAM_BLOCK winrect, $C7
x1         .word
y1         .word
x2         .word
y2         .word
        END_PARAM_BLOCK


        ;; Start window enumeration at top ???
.proc TopWindow
        copy16  root_window_addr, previous_window
        ldax    current_window
        bne     set_found_window
end:    rts
.endproc ; TopWindow

        ;; Look up next window in chain. $A9/$AA will point at
        ;; window params block (also returned in X,A).
.proc NextWindow
        copy16  window, previous_window
        ldy     #MGTK::Winfo::nextwinfo+1
        lda     (window),y
        beq     TopWindow::end  ; if high byte is 0, end of chain
        tax
        dey
        lda     (window),y
set_found_window:
        stax    found_window
        FALL_THROUGH_TO GetWindow
.endproc ; NextWindow

        ;; Load/refresh the ZP window data areas at $AB and $B7.
.proc GetWindow
        ldax    found_window
get_from_ax:
        stax    window

        ldy     #11             ; copy first 12 bytes of window definition to
:       lda     (window),y         ; to $AB
        sta     current_winfo,y
        dey
        bpl     :-

        ; copy first 16 bytes of grafport to $B7
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::pattern-1
:       lda     (window),y
        sta     current_winport - MGTK::Winfo::port,y
        dey
        cpy     #MGTK::Winfo::port-1
        bne     :-

return_window:
        RETURN  AX=window
.endproc ; GetWindow
        set_found_window := NextWindow::set_found_window


        ;; Look up window state by id (in $82); $A9/$AA will point at
        ;; winfo (also X,A).
.proc WindowById
        jsr     TopWindow
        beq     end
loop:   lda     current_winfo::id
        cmp     $82
        beq     GetWindow::return_window
        jsr     NextWindow
        bne     loop
end:    rts
.endproc ; WindowById

        ;; Look up window state by id (in $82); $A9/$AA will point at
        ;; winfo (also X,A).
        ;; This will exit the MGTK call directly (restoring stack, etc)
        ;; if the window is not found.
.proc WindowByIdOrExit
        jsr     WindowById
        RTS_IF NOT_ZERO

        EXIT_CALL MGTK::Error::window_not_found
.endproc ; WindowByIdOrExit


.proc FrameWinRect
        MGTK_CALL MGTK::FrameRect, winrect
        rts
.endproc ; FrameWinRect

.proc InWinRect
        MGTK_CALL MGTK::InRect, winrect
        rts
.endproc ; InWinRect

        ;; Retrieve the rectangle of the current window and put it in winrect.
        ;;
        ;; The rectangle is defined by placing the top-left corner at the viewloc
        ;; of the window and setting the width and height matching the width
        ;; and height of the maprect of the window's port.
        ;;
.proc GetWinRect
        COPY_BLOCK current_winport::viewloc, winrect ; copy viewloc to left/top of winrect

        ldx     #2
:       lda     current_winport::maprect + MGTK::Rect::x2,x ; x2/y2
        sec
        sbc     current_winport::maprect + MGTK::Rect::x1,x ; x1/y1
        tay
        lda     current_winport::maprect + MGTK::Rect::x2+1,x
        sbc     current_winport::maprect + MGTK::Rect::x1+1,x
        pha

        tya
        clc
        adc     winrect::x1,x   ; x1/y1
        sta     winrect::x2,x   ; x2/y2
        pla
        adc     winrect::x1+1,x
        sta     winrect::x2+1,x
        dex
        dex
        bpl     :-
        FALL_THROUGH_TO return_winrect
.endproc ; GetWinRect
return_winrect:
        RETURN  AX=#winrect

        ;; Return the window's rect including framing: title bar and scroll
        ;; bars.
.proc GetWinFrameRect
        jsr     GetWinRect
        dec16   winrect

        bit     current_winfo::vscroll
        bmi     vert_scroll

        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     vert_scroll
        lda     #$01
        bne     :+

vert_scroll:
        lda     #$15
:       clc
        adc     winrect::x2
        sta     winrect::x2
        bcc     :+
        inc     winrect::x2+1
:       lda     #1

        bit     current_winfo::hscroll
        bpl     :+

        lda     #$0B
:       clc
        adc     winrect::y2
        sta     winrect::y2
        bcc     :+
        inc     winrect::y2+1
:
        lda     #MGTK::Option::dialog_box
        and     current_winfo::options
        bne     :+
        lda     winframe_top
:       sta     $82

        lda     winrect::y1
        sec
        sbc     $82
        sta     winrect::y1
        bcs     return_winrect
        dec     winrect::y1+1
        bcc     return_winrect
.endproc ; GetWinFrameRect


.proc GetWinVertScrollRect
        jsr     GetWinFrameRect
        ldax    winrect::x2
        subax8  #$14
        stax    winrect::x1

        lda     current_winfo::options
        ;;and     #MGTK::Option::dialog_box
        ;;bne     return_winrect
        .assert MGTK::Option::dialog_box = 1, error, "dialog_box must be 1"
        lsr
        bcs     return_winrect

        lda     winrect::y1
        clc
        adc     wintitle_height
        sta     winrect::y1
        bcc     return_winrect
        inc     winrect::y1+1
        bcs     return_winrect
.endproc ; GetWinVertScrollRect


.proc GetWinHorizScrollRect
        jsr     GetWinFrameRect
get_rect:
        ldax    winrect::y2
        subax8  #$0A
        stax    winrect::y1
        jmp     return_winrect
.endproc ; GetWinHorizScrollRect


.proc GetWinGrowBoxRect
        jsr     GetWinVertScrollRect
        jmp     GetWinHorizScrollRect::get_rect
.endproc ; GetWinGrowBoxRect


.proc GetWinTitleBarRect
        jsr     GetWinFrameRect

        lda     winrect::y1
        clc
        adc     wintitle_height
        sta     winrect::y2
        lda     winrect::y1+1
        adc     #0
        sta     winrect::y2+1

        jmp     return_winrect
.endproc ; GetWinTitleBarRect


.proc GetWinGoAwayRect
        jsr     GetWinTitleBarRect

        ldax    winrect::x1
        addax8  #kGoAwayLeft
        stax    winrect::x1
        addax8  #kGoAwayWidth
        stax    winrect::x2

        ldax    winrect::y1
        addax8  #kGoAwayTop
        stax    winrect::y1
        addax8  goaway_height
        stax    winrect::y2

        jmp     return_winrect
.endproc ; GetWinGoAwayRect


.proc DrawWindow
        jsr     GetWinFrameRect
        jsr     FillAndFrameRect

preserve_content:
        lda     current_winfo::options
        ;;and     #MGTK::Option::dialog_box
        ;;bne     no_titlebar
        .assert MGTK::Option::dialog_box = 1, error, "dialog_box must be 1"
        lsr
        bcs     no_titlebar

        jsr     GetWinTitleBarRect
        jsr     FillAndFrameRect
        jsr     CenterTitleText

        inc16   current_penloc_y ; bias glyphs downwards
        ldax    current_winfo::title
        jsr     DrawText

no_titlebar:
        jsr     GetWindow

        bit     current_winfo::vscroll
        bpl     no_vert_scroll

        jsr     GetWinVertScrollRect
        jsr     FrameWinRect

no_vert_scroll:
        bit     current_winfo::hscroll
        bpl     :+

        jsr     GetWinHorizScrollRect
        jsr     FrameWinRect

:       lda     current_winfo::options
        and     #MGTK::Option::grow_box
        beq     :+

        jsr     GetWinGrowBoxRect
        jsr     FrameWinRect
        jsr     GetWinVertScrollRect
        jsr     FrameWinRect

:       jsr     GetWindow

        lda     current_winfo::id
        cmp     sel_window_id
        bne     :+

        jsr     SetDesktopPort
        jmp     DrawWinframe
:       rts
.endproc ; DrawWindow
DrawWindowPreserveContent := DrawWindow::preserve_content

        ;;  Drawing title bar, maybe?
draw_erase_mode:
        .byte   1

stripes_pattern:
stripes_pattern_alt := *+1
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111

;;; Also sets `top` and `bottom` using "go away" rect
.proc SetStripesPattern
        jsr     GetWinGoAwayRect
        copy16  winrect::y1, top
        copy16  winrect::y2, bottom

        lda     winrect::y1
        ror
        bcc     :+
        MGTK_CALL MGTK::SetPattern, stripes_pattern
        rts

:       MGTK_CALL MGTK::SetPattern, stripes_pattern_alt
        rts
.endproc ; SetStripesPattern


.proc EraseWinframe
        lda     #MGTK::penOR
        ldx     #0
        beq     :+              ; always
.endproc ; EraseWinframe

.proc DrawWinframe
        lda     #MGTK::penBIC
        ldx     #1

:       stx     draw_erase_mode
        jsr     SetFillMode

        lda     current_winfo::options
        and     #MGTK::Option::go_away_box | MGTK::Option::dialog_box
        .assert MGTK::Option::go_away_box = 2, error, "go_away_box must be 2"
        .assert MGTK::Option::dialog_box = 1, error, "dialog_box must be 1"
        lsr
        bcs     no_goaway
        beq     no_goaway

        ;; --------------------------------------------------
        ;; Draw "go away" box

        jsr     GetWinGoAwayRect
        jsr     FrameWinRect

        ;; --------------------------------------------------
        ;; Draw stripes to left of "go away" box

        jsr     SetStripesPattern ; also inits `top` and `bottom`

        kStripesXInset = 3
        kTitleXInset = 10

        ;; Left edge
        ldax    winrect::x1
        subax8  #kGoAwayLeft - kStripesXInset
        stax    left

        ;; Right edge
        addax8  #(kGoAwayLeft - kStripesXInset) - kStripesXInset
        stax    right

        jsr     PaintRectImpl

no_goaway:
        lda     current_winfo::options
        ;;and     #MGTK::Option::dialog_box
        ;;bne     no_titlebar
        .assert MGTK::Option::dialog_box = 1, error, "dialog_box must be 1"
        lsr
        bcs     no_titlebar

        ;; --------------------------------------------------
        ;; Measure title

        jsr     GetWinTitleBarRect
        jsr     CenterTitleText
        jsr     PenlocToBounds  ; inits `left` and `right`

        ;; --------------------------------------------------
        ;; Draw stripes to left of title

        jsr     SetStripesPattern ; sets `winrect` to "go away" box, inits `top` and `bottom`

        ;; Calculate A,X = left edge (to right of "go away" box, if necessary)
        ldax    winrect::x2     ; right edge of "go away" box
        addax8  #kStripesXInset
        tay

        lda     current_winfo::options
        and     #MGTK::Option::go_away_box
    IF ZERO
        ;; There was no "go away" box, so further offset left
        tya
        subax8  #kGoAwayLeft + kGoAwayWidth
        tay
    END_IF
        tya

        ;; Stash right edge of title text temporarily in `winrect::x2`
        ldy     right
        sty     winrect::x2
        ldy     right+1
        sty     winrect::x2+1

        ;; Set `right` to left edge of title text
        ldy     left
        sty     right
        ldy     left+1
        sty     right+1

        ;; Set `left` as calculated
        stax    left

        ;; Add padding to left of title
        sub16_8 right, #kTitleXInset

        cmp16   right, left     ; skip if degenerate
    IF POS
        jsr     PaintRectImpl
    END_IF

        ;; --------------------------------------------------
        ;; Draw stripes to right of title

        ;; Use stashed right edge of title text, with padding, as `left`
        add16   winrect::x2, #kTitleXInset, left
        jsr     GetWinTitleBarRect

        ;; Use right edge of window, inset, as `right`
        sub16   winrect::x2, #kStripesXInset, right

        jsr     PaintRectImpl
        MGTK_CALL MGTK::SetPattern, standard_port::pattern

        ;; --------------------------------------------------
no_titlebar:
        jsr     GetWindow

        bit     current_winfo::vscroll
        bpl     no_vscroll

        jsr     GetWinVertScrollRect
        ldx     #3
:       lda     winrect,x
        sta     up_scroll_params,x
        sta     down_scroll_params,x
        dex
        bpl     :-

        inc     up_scroll_params::ycoord
        ldax    winrect::y2
        subax8  #$0A
        tay
        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::hscroll
        bpl     no_hscroll

:       tya
        subax8  #$0B
        tay

no_hscroll:
        styx    down_scroll_params::ycoord

        ldax    down_scroll_addr
        jsr     DrawIcon

        ldax    up_scroll_addr
        jsr     DrawIcon

no_vscroll:
        bit     current_winfo::hscroll
        bpl     no_hscrollbar

        jsr     GetWinHorizScrollRect
        ldx     #3
:       lda     winrect,x
        sta     left_scroll_params,x
        sta     right_scroll_params,x
        dex
        bpl     :-

        ldax    winrect::x2
        subax8  #$14
        tay
        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::vscroll
        bpl     no_vscroll2

:       tya
        subax8  #$15
        tay

no_vscroll2:
        styx    right_scroll_params

        ldax    right_scroll_addr
        jsr     DrawIcon

        ldax    left_scroll_addr
        jsr     DrawIcon

no_hscrollbar:
        lda     #MGTK::pencopy
        jsr     SetFillMode

        lda     current_winfo::vscroll
        lsr
        bcc     :+

        lda     #which_control_vert
        sta     which_control
        lda     draw_erase_mode
        jsr     DrawOrEraseScrollbar
        jsr     GetWindow

:       lda     current_winfo::hscroll
        lsr
        bcc     :+

        lda     #which_control_horiz
        sta     which_control
        lda     draw_erase_mode
        jsr     DrawOrEraseScrollbar
        jsr     GetWindow

:       lda     current_winfo::options
        and     #MGTK::Option::grow_box
        beq     ret

        jsr     GetWinGrowBoxRect
        lda     draw_erase_mode
        bne     draw_resize
        ldax    #winrect
        jmp     FillAndFrameRect

        ;; Draw resize box
draw_resize:
        ldx     #3
:       lda     winrect,x
        sta     resize_box_params,x
        dex
        bpl     :-

        lda     #MGTK::notpencopy
        jsr     SetFillMode
        ldax    resize_box_addr
        jmp     DrawIcon
ret:    rts
.endproc ; DrawWinframe


.proc CenterTitleText
        text_width = $82

        ldax    current_winfo::title
        jsr     DoMeasureText
        stax    text_width

        lda     winrect::x1
        clc
        adc     winrect::x2
        tay

        lda     winrect::x1+1
        adc     winrect::x2+1
        tax

        tya
        sec
        sbc     text_width
        sta     current_penloc_x

        txa
        sbc     text_width+1
        cmp     #$80
        ror     a
        sta     current_penloc_x+1
        ror     current_penloc_x

        ldax    winrect::y2
        subax8  #2
        stax    current_penloc_y

        RETURN  AX=text_width
.endproc ; CenterTitleText

;;; ============================================================

;;; 4 bytes of params, copied to current_penloc

.proc FindWindowImpl
        PARAM_BLOCK params, $EA
mousex      .word
mousey      .word
which_area  .byte
window_id   .byte
        END_PARAM_BLOCK

        jsr     SaveParamsAndStack

        MGTK_CALL MGTK::InRect, menu_bar_rect ; check if in menubar
        beq     not_menubar

        lda     #MGTK::Area::menubar
return_no_window:
        ldx     #0
return_result:
        phax

        ;; `RestoreParamsActivePort` isn't needed, and is
        ;; very slow, so do the minimum here.
        asl     preserve_zp_flag
        copy16  params_addr_save, params_addr

        plax
        ldy     #params::which_area - params
        jmp     store_xa_at_y

not_menubar:
        lda     #0              ; first window we see is the selected one
        sta     not_selected

        jsr     TopWindow
        beq     no_windows

loop:   jsr     GetWinFrameRect
        jsr     InWinRect
        bne     in_window

        jsr     NextWindow
        stx     not_selected    ; set to non-zero for subsequent windows
        bne     loop

no_windows:
        lda     #MGTK::Area::desktop
        beq     return_no_window

in_window:
        lda     current_winfo::options
        ;;and     #MGTK::Option::dialog_box
        ;;bne     in_content
        .assert MGTK::Option::dialog_box = 1, error, "dialog_box must be 1"
        lsr
        bcs     in_content

        jsr     GetWinTitleBarRect
        jsr     InWinRect
        beq     in_content

        lda     not_selected
        bne     :+

        lda     current_winfo::options
        and     #MGTK::Option::go_away_box
        beq     :+

        jsr     GetWinGoAwayRect
        jsr     InWinRect
        beq     :+
        lda     #MGTK::Area::close_box
        bne     return_window

:       lda     #MGTK::Area::dragbar
        bne     return_window

in_content:
        lda     not_selected
        bne     :+

        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        beq     :+

        jsr     GetWinGrowBoxRect
        jsr     InWinRect
        beq     :+
        lda     #MGTK::Area::grow_box
return_window:
        ldx     current_winfo::id
        bne     return_result

:       lda     #MGTK::Area::content
        bne     return_window

not_selected:
        .byte   0

.endproc ; FindWindowImpl

;;; ============================================================
;;; OpenWindow

;;; params points to a winfo structure

.proc OpenWindowImpl
        win_id := $82

        copy16  params_addr, window

        ldy     #MGTK::Winfo::window_id
        lda     (window),y
        bne     :+
        EXIT_CALL MGTK::Error::window_id_required

:       sta     win_id
        jsr     WindowById
        beq     :+
        EXIT_CALL MGTK::Error::window_already_exists

:       copy16  params_addr, window

        ldy     #MGTK::Winfo::status
        lda     (window),y
        ora     #$80
        sta     (window),y
        bmi     do_select_win
.endproc ; OpenWindowImpl


;;; ============================================================
;;; SelectWindow

;;; 1 byte of params, copied to $82

.proc SelectWindowImpl
        jsr     WindowByIdOrExit
    IF A = current_window
        RTS_IF X = current_window+1
    END_IF

        jsr     LinkWindow
do_select_win:
        ldy     #MGTK::Winfo::nextwinfo
        lda     current_window
        sta     (window),y
        iny
        lda     current_window+1
        sta     (window),y

        lda     window
        pha
        lda     window+1
        pha
        jsr     HideCursorSaveParams
        jsr     SetDesktopPort

        jsr     TopWindow
        beq     :+
        jsr     EraseWinframe
:       pla
        sta     current_window+1
        pla
        sta     current_window

        jsr     TopWindow
        lda     current_winfo::id
        sta     sel_window_id

        jsr     SetDesktopPort
        jsr     DrawWindow
        jmp     ShowCursorAndRestore
.endproc ; SelectWindowImpl

do_select_win   := SelectWindowImpl::do_select_win


.proc LinkWindow
        ldy     #MGTK::Winfo::nextwinfo
        lda     (window),y
        sta     (previous_window),y
        iny
        lda     (window),y
        sta     (previous_window),y
        rts
.endproc ; LinkWindow


;;; ============================================================
;;; GetWinPtr

;;; 1 byte of params, copied to $82

.proc GetWinPtrImpl
        ptr := $A9

        jsr     WindowByIdOrExit
        ldax    ptr
        ldy     #1
        jmp     store_xa_at_y
.endproc ; GetWinPtrImpl

;;; ============================================================
;;; BeginUpdate

;;; 1 byte of params, copied to $82

previous_port:
        .res    2

update_port:
        .tag    MGTK::GrafPort

.proc BeginUpdateImpl
        lda     $82
        bne     win

        ;; Desktop
        jsr     HideCursorSaveParams
        jsr     SetDesktopPort
        MGTK_CALL MGTK::SetPortBits, set_port_params
        copy16  active_port, previous_port
        ldax    update_port_addr
        jsr     assign_and_prepare_port
        asl     preserve_zp_flag
        rts

        ;; Window
win:    jsr     WindowByIdOrExit

        lda     current_winfo::id
        cmp     target_window_id
        bne     :+
        inc     matched_target

:       jsr     HideCursorSaveParams
        jsr     SetDesktopPort
        lda     matched_target
        bne     :+
        MGTK_CALL MGTK::SetPortBits, set_port_params

:       jsr     DrawWindow
        jsr     SetDesktopPort
        lda     matched_target
        bne     :+
        MGTK_CALL MGTK::SetPortBits, set_port_params

:       jsr     GetWindow
        copy16  active_port, previous_port

        jsr     PrepareWinport
        php
        ldax    update_port_addr
        jsr     assign_and_prepare_port

        asl     preserve_zp_flag
        plp
        RTS_IF CS

        jsr     EndUpdateImpl
        FALL_THROUGH_TO err_obscured
.endproc ; BeginUpdateImpl

err_obscured:
        EXIT_CALL MGTK::Error::window_obscured

;;; ============================================================
;;; EndUpdate

;;; 1 byte of params, copied to $82

update_port_addr:
        .addr   update_port

.proc EndUpdateImpl
        jsr     ShowCursorImpl

        ldax    previous_port
        stax    active_port
        jmp     SetAndPreparePort
.endproc ; EndUpdateImpl

;;; ============================================================
;;; GetWinPort

;;; 3 bytes of params, copied to $82

.proc GetWinPortImpl
        PARAM_BLOCK params, $82
win_id    .byte
win_port  .addr
        END_PARAM_BLOCK


        jsr     ApplyPortToActivePort

        jsr     WindowByIdOrExit
        copy16  params::win_port, params_addr

        COPY_STRUCT MGTK::Rect, desktop_mapinfo+MGTK::MapInfo::maprect, current_maprect_x1

        jsr     PrepareWinport
        bcc     err_obscured

        ldy     #.sizeof(MGTK::GrafPort)-1
:       lda     current_grafport,y
        sta     (params_addr),y
        dey
        bpl     :-

        jmp     ApplyActivePortToPort
.endproc ; GetWinPortImpl


.proc PrepareWinport
        jsr     GetWinRect

        ldx     #7
        lda     #0
:       sta     clipped_left,x
        ldy     winrect,x
        sty     left,x
        dex
        bpl     :-

        jsr     ClipRect
        RTS_IF CC

        ;; Load window's grafport into current_grafport.
        ldy     #MGTK::Winfo::port
:       lda     (window),y
        sta     current_grafport - MGTK::Winfo::port,y
        iny
        cpy     #MGTK::Winfo::port + .sizeof(MGTK::GrafPort)
        bne     :-

        ldx     #2
:       lda     left,x
        sta     current_viewloc_x,x
        lda     left+1,x
        sta     current_viewloc_x+1,x
        lda     right,x
        sec
        sbc     left,x
        sta     $82,x
        lda     right+1,x
        sbc     left+1,x
        sta     $83,x

        lda     current_maprect_x1,x
        ;;sec
        sbc     clipped_left,x
        sta     current_maprect_x1,x
        lda     current_maprect_x1+1,x
        sbc     clipped_left+1,x
        sta     current_maprect_x1+1,x

        lda     current_maprect_x1,x
        clc
        adc     $82,x
        sta     current_maprect_x2,x
        lda     current_maprect_x1+1,x
        adc     $83,x
        sta     current_maprect_x2+1,x

        dex
        dex
        bpl     :-

        RETURN  C=1
.endproc ; PrepareWinport

;;; ============================================================
;;; SetWinPort

;;; 2 bytes of params, copied to $82

        ;; This updates win grafport from params ???
        ;; The math is weird; $82 is the window id so
        ;; how does ($82),y do anything useful - is
        ;; this buggy ???

        ;; It seems like it's trying to update a fraction
        ;; of the drawing port (from `pattern` to `font`)

.proc SetWinPortImpl
        ptr := window

        jsr     WindowByIdOrExit
        lda     ptr
        clc
        adc     #MGTK::Winfo::port
        sta     ptr
        bcc     :+
        inc     ptr+1

:       ldy     #.sizeof(MGTK::GrafPort)-1
loop:   lda     ($82),y
        sta     (ptr),y
        dey
        cpy     #$10
        bcs     loop
        rts
.endproc ; SetWinPortImpl

;;; ============================================================
;;; FrontWindow

.proc FrontWindowImpl
        jsr     TopWindow
        beq     nope
        lda     current_winfo::id
        bne     :+

nope:   lda     #0
:       ldy     #0
        sta     (params_addr),y
        rts
.endproc ; FrontWindowImpl

;;; ============================================================
;;; TrackGoAway

in_close_box:  .byte   0

.proc TrackGoAwayImpl
        jsr     TopWindow
        beq     end

        jsr     GetWinGoAwayRect
        jsr     SaveParamsAndStack
        jsr     SetDesktopPort

        lda     #$80
toggle: sta     in_close_box

        jsr     SetFillModeXOR

        jsr     HideCursorImpl
        MGTK_CALL MGTK::PaintRect, winrect
        jsr     ShowCursorImpl

loop:   jsr     GetAndReturnEvent
        cmp     #MGTK::EventKind::button_up
        beq     :+

        MGTK_CALL MGTK::MoveTo, cursor_pos
        jsr     InWinRect
        eor     in_close_box
        bpl     loop
        lda     in_close_box
        eor     #$80
        jmp     toggle

:       jsr     RestoreParamsActivePort
        ldy     #0
        lda     in_close_box
        asl
        rol
end:    sta     (params_addr),y
        rts
.endproc ; TrackGoAwayImpl

;;; ============================================================

.params drag_initialpos
xcoord: .res    2
ycoord: .res    2
.endparams

.params drag_curpos
xcoord: .res    2
ycoord: .res    2
.endparams

.params drag_delta
xdelta: .res    2
ydelta: .res    2
.endparams

        ;; High bit set if window is being resized, clear if moved.
drag_resize_flag:
        .byte   0

;;; ============================================================

;;; 5 bytes of params, copied to $82

GrowWindowImpl:
        lda     #$80
        bmi     DragWindowImpl_drag_or_grow

;;; ============================================================

;;; 5 bytes of params, copied to $82

.proc DragWindowImpl
        PARAM_BLOCK params, $82
window_id  .byte
dragx      .word
dragy      .word
moved      .byte
        END_PARAM_BLOCK

        lda     #0
drag_or_grow:
        sta     drag_resize_flag
        jsr     KbdMouseInitTracking

        ldx     #3
:       lda     params::dragx,x
        sta     drag_initialpos,x
        sta     drag_curpos,x
        lda     #0
        sta     drag_delta,x
        dex
        bpl     :-

        jsr     WindowByIdOrExit

        bit     kbd_mouse_state
        bpl     :+
        jsr     KbdWinDragOrGrow

:       jsr     HideCursorSaveParams
        jsr     WinframeToSetPort

        jsr     SetFillModeXOR
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern

loop:   jsr     GetWindow
        jsr     UpdateWinForDrag

        jsr     GetWinFrameRect
        jsr     FrameWinRect
        jsr     ShowCursorImpl

no_change:
        jsr     GetAndReturnEvent
        cmp     #MGTK::EventKind::button_up
        bne     dragging

        jsr     FrameWinRect

        bit     movement_cancel
        bmi     canceled

        ldx     #3
:       lda     drag_delta,x
        bne     changed
        dex
        bpl     :-

canceled:
        jsr     ShowCursorAndRestore
        lda     #0
return_moved:
        ldy     #params::moved - params
        sta     (params_addr),y
        rts

changed:
        ldy     #MGTK::Winfo::port
:       lda     current_winport - MGTK::Winfo::port,y
        sta     (window),y
        iny
        cpy     #MGTK::Winfo::port + 16
        bne     :-
        jsr     HideCursorImpl

        lda     current_winfo::id
        jsr     EraseWindow
        jsr     HideCursorSaveParams

        bit     movement_cancel
        bvc     :+
        jsr     SetInput

:       jsr     ShowCursorAndRestore
        lda     #$80
        bne     return_moved

dragging:
        jsr     CheckIfChanged
        beq     no_change

        jsr     HideCursorImpl
        jsr     FrameWinRect
        jmp     loop
.endproc ; DragWindowImpl


.proc UpdateWinForDrag
        win_width := $82

        PARAM_BLOCK content, $C7
minwidth   .word
minheight  .word
maxwidth   .word
maxheight  .word
        END_PARAM_BLOCK


        ;; Copy mincontwidth..maxcontheight from the window to content
        ldy     #MGTK::Winfo::port-1
:       lda     (window),y
        sta     content - MGTK::Winfo::mincontwidth,y
        dey
        cpy     #MGTK::Winfo::mincontwidth-1
        bne     :-

        ldx     #0
        stx     force_tracking_change
        bit     drag_resize_flag
        bmi     grow

:       add16   current_winport::viewloc + MGTK::Point::xcoord,x, drag_delta,x, current_winport::viewloc + MGTK::Point::xcoord,x
        inx
        inx
        cpx     #4
        bne     :-

        lda     #$12
        cmp     current_winport::viewloc + MGTK::Point::ycoord
        bcc     :+
        sta     current_winport::viewloc + MGTK::Point::ycoord
:       rts

grow:   lda     #0
        sta     grew_flag
loop:   add16   current_winport::maprect + MGTK::Rect::x2,x, drag_delta,x, current_winport::maprect + MGTK::Rect::x2,x
        sub16   current_winport::maprect + MGTK::Rect::x2,x, current_winport::maprect + MGTK::Rect::x1,x, win_width

        ;;sec
        lda     win_width
        sbc     content::minwidth,x
        lda     win_width+1
        sbc     content::minwidth+1,x
        bpl     :+

        add16   content::minwidth,x, current_winport::maprect + MGTK::Rect::x1,x, current_winport::maprect + MGTK::Rect::x2,x
        bcc     set_grew        ; always

:       sec
        lda     content::maxwidth,x
        sbc     win_width
        lda     content::maxwidth+1,x
        sbc     win_width+1
        bpl     next

        add16   content::maxwidth,x, current_winport::maprect + MGTK::Rect::x1,x, current_winport::maprect + MGTK::Rect::x2,x

set_grew:
        jsr     SetGrewFlag

next:   inx
        inx
        cpx     #4
        bne     loop
        jmp     FinishGrow
.endproc ; UpdateWinForDrag


        ;; Return with Z=1 if the drag position was not changed, or Z=0
        ;; if the drag position was changed or force_tracking_change is set.
.proc CheckIfChanged
        ldx     #2
        ldy     #0

loop:   lda     GetAndReturnEvent::event::mouse_pos+1,x
        cmp     drag_curpos+1,x
        bne     :+
        iny
:
        lda     GetAndReturnEvent::event::mouse_pos,x
        cmp     drag_curpos,x
        bne     :+
        iny
:       sta     drag_curpos,x

        sec
        sbc     drag_initialpos,x
        sta     drag_delta,x

        lda     GetAndReturnEvent::event::mouse_pos+1,x
        sta     drag_curpos+1,x
        sbc     drag_initialpos+1,x
        sta     drag_delta+1,x

        dex
        dex
        bpl     loop

        cpy     #4
        bne     :+
        lda     force_tracking_change
:       rts
.endproc ; CheckIfChanged

DragWindowImpl_drag_or_grow := DragWindowImpl::drag_or_grow


;;; ============================================================
;;; CloseWindow

;;; 1 byte of params, copied to $82

.proc CloseWindowImpl
        jsr     WindowByIdOrExit

        jsr     HideCursorSaveParams

        jsr     WinframeToSetPort
        php                     ; Save C=1 if valid port
        jsr     LinkWindow

        ldy     #MGTK::Winfo::status
        lda     (window),y
        and     #$7F
        sta     (window),y

        jsr     TopWindow
        lda     current_winfo::id
        sta     sel_window_id

        plp
    IF CC
        ;; Port was not valid; the window was entirely offscreen, so
        ;; erasing and posting updates is not required. But newly
        ;; active window may need redrawing.
        jsr     TopWindow
      IF NOT_ZERO
        jsr     SetDesktopPort
        jsr     DrawWindowPreserveContent
      END_IF
        jmp     ShowCursorAndRestore
    END_IF

        lda     #0
        beq     EraseWindow
.endproc ; CloseWindowImpl

;;; ============================================================
;;; CloseAll

.proc CloseAllImpl
        jsr     TopWindow
        beq     :+

        ldy     #MGTK::Winfo::status
        lda     (window),y
        and     #$7F
        sta     (window),y
        jsr     LinkWindow

        jmp     CloseAllImpl
:       jmp     StartDeskTopImpl::reset_desktop
.endproc ; CloseAllImpl


.proc WinframeToSetPort
        jsr     SetDesktopPort
        jsr     GetWinFrameRect

        COPY_BLOCK winrect, left
        jsr     ClipRect

        ldx     #3
:       lda     left,x
        sta     set_port_maprect,x
        sta     set_port_params,x
        lda     right,x
        sta     set_port_size,x
        dex
        bpl     :-

        rts
.endproc ; WinframeToSetPort


matched_target:
        .byte   0

        ;; Erases window after destruction
.proc EraseWindow
        sta     target_window_id
        lda     #0
        sta     matched_target
        MGTK_CALL MGTK::SetPortBits, set_port_params

        lda     #MGTK::pencopy
        jsr     SetFillMode

        MGTK_CALL MGTK::SetPattern, desktop_pattern
        MGTK_CALL MGTK::PaintRect, set_port_maprect

        jsr     ShowCursorAndRestore

        php
        sei
        jsr     FlushEventsImpl

        ;; Update for the desktop
        jsr     PutEvent
        bcs     plp_ret
        tax
        lda     #MGTK::EventKind::update
        sta     eventbuf::kind,x
        lda     #0
        sta     eventbuf::window_id,x

        ;; Updates for windows
        jsr     TopWindow
        beq     plp_ret

:       jsr     NextWindow
        bne     :-

loop:   jsr     PutEvent
        bcs     plp_ret
        tax

        lda     #MGTK::EventKind::update
        sta     eventbuf::kind,x
        lda     current_winfo::id
        sta     eventbuf::window_id,x

        lda     current_winfo::id
        cmp     sel_window_id
        beq     plp_ret

        sta     $82
        jsr     WindowById

        ldax    previous_window
        jsr     GetWindow::get_from_ax
        jmp     loop

plp_ret:
        plp
        rts
.endproc ; EraseWindow


kGoAwayLeft     = 12
kGoAwayWidth    = 12
kGoAwayTop      = 3

goaway_height:  .word   6       ; font height - 3
wintitle_height:.word  12       ; font height + 3
winframe_top:   .word  13       ; font height + 4

.params set_port_params
        DEFINE_POINT viewloc, 0,$D
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0,0,0,0
        REF_MAPINFO_MEMBERS
.endparams
        set_port_top  := set_port_params::viewloc::ycoord
        set_port_size := set_port_params::maprect::x2
        set_port_maprect  := set_port_params::maprect::x1 ; Re-used since h/voff are 0

;;; ============================================================
;;; WindowToScreen

        ;; $83/$84 += $B7/$B8
        ;; $85/$86 += $B9/$BA

.proc WindowToScreenImpl
        PARAM_BLOCK params, $82
window_id       .byte
windowx         .word
windowy         .word
screenx         .word           ; out
screeny         .word           ; out
        END_PARAM_BLOCK

        jsr     WindowByIdOrExit

        ldx     #2
loop:   add16   params::windowx,x, current_winport::viewloc,x, params::windowx,x
        dex
        dex
        bpl     loop
        bmi     CopyMapResults                  ; always
.endproc ; WindowToScreenImpl

;;; ============================================================
;;; ScreenToWindow

;;; 5 bytes of params, copied to $82

.proc ScreenToWindowImpl
        PARAM_BLOCK params, $82
window_id       .byte
screenx         .word
screeny         .word
windowx         .word           ; out
windowy         .word           ; out
        END_PARAM_BLOCK

        jsr     WindowByIdOrExit

        ldx     #2
:       sub16   params::screenx,x, current_winport::viewloc,x, params::screenx,x
        dex
        dex
        bpl     :-
        FALL_THROUGH_TO CopyMapResults
.endproc ; ScreenToWindowImpl

.proc CopyMapResults
        ldy     #ScreenToWindowImpl::params::windowx - ScreenToWindowImpl::params
:       lda     ScreenToWindowImpl::params + (ScreenToWindowImpl::params::screenx - ScreenToWindowImpl::params::windowx),y
        sta     (params_addr),y
        iny
        cpy     #.sizeof(ScreenToWindowImpl::params)      ; results are 2 words (x, y) at params_addr+5
        bne     :-
        rts
.endproc ; CopyMapResults

;;; ============================================================


        ;; Used to draw scrollbar arrows and resize box
.proc DrawIcon
        icon_ptr := $82

        stax    icon_ptr

        ldy     #3
:       lda     #0
        sta     PaintBitsImpl::dbi_left,y
        lda     (icon_ptr),y
        sta     left,y
        dey
        bpl     :-

        iny
        sty     $91             ; zero

        ldy     #Bitmap::width
        lda     (icon_ptr),y
        tax
        lda     div7_table+7,x
        sta     src_mapwidth

        txa
        ldx     left+1
        addax8  left
        stax    right

        iny
        lda     (icon_ptr),y    ; height
        ldx     top+1
        addax8  top
        stax    bottom

        iny
        lda     (icon_ptr),y
        sta     bits_addr
        iny
        lda     (icon_ptr),y
        sta     bits_addr+1
        jmp     BitBltImpl
.endproc ; DrawIcon

;;; ============================================================
;;; ActivateCtl

;;; 2 bytes of params, copied to $8C

.proc ActivateCtlImpl
        PARAM_BLOCK params, $8C
which_ctl  .byte
activate   .byte
        END_PARAM_BLOCK


        lda     #which_control_vert
        ldx     which_control
        cpx     #MGTK::Ctl::vertical_scroll_bar
        beq     activate

        ;;lda     #which_control_horiz
        .assert which_control_vert = $80, error, "which_control_vert must be $80"
        .assert which_control_horiz = 0, error, "which_control_horiz must be 0"
        asl
        cpx     #MGTK::Ctl::horizontal_scroll_bar
        beq     activate

        rts

activate:
        sta     which_control
        jsr     TopWindow

        ldy     #MGTK::Winfo::vscroll
        bit     which_control
        bpl     :+

        lda     current_winfo::vscroll
        bne     toggle

:       lda     current_winfo::hscroll
        ;;ldy     #MGTK::Winfo::hscroll
        .assert (MGTK::Winfo::vscroll - MGTK::Winfo::hscroll) = 1, error, "hscroll must be 1 less than vscroll"
        dey

toggle: eor     params::activate
        and     #1
        eor     (window),y
        RTS_IF A = (window),y   ; no-op if no change
        sta     (window),y

        jsr     HideCursorSaveParams
        lda     params::activate
        jsr     DrawOrEraseScrollbar
        jmp     ShowCursorAndRestore
.endproc ; ActivateCtlImpl


.proc DrawOrEraseScrollbar
        bne     do_draw

        jsr     GetScrollbarScrollArea
        jsr     SetStandardPort
        MGTK_CALL MGTK::PaintRect, winrect
        rts

do_draw:
        bit     which_control
        bmi     vert_scrollbar
        bit     current_winfo::hscroll
        bmi     has_scroll
ret:    rts

vert_scrollbar:
        bit     current_winfo::vscroll
        bpl     ret
has_scroll:
        jsr     SetStandardPort
        jsr     GetScrollbarScrollArea

        MGTK_CALL MGTK::SetPattern, light_speckles_pattern
        MGTK_CALL MGTK::PaintRect, winrect
        MGTK_CALL MGTK::SetPattern, standard_port::pattern

        bit     which_control
        bmi     vert_thumb

        bit     current_winfo::hscroll
        bvs     has_thumb
ret2:   rts

vert_thumb:
        bit     current_winfo::vscroll
        bvc     ret2
has_thumb:
        jsr     GetThumbRect
        jmp     FillAndFrameRect
.endproc ; DrawOrEraseScrollbar


light_speckles_pattern:
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111

.proc GetScrollbarScrollArea
        bit     which_control
        bpl     horiz

        jsr     GetWinVertScrollRect

        add16_8 winrect::y1, #$0C
        sub16_8 winrect::y2, #$0B

        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::hscroll
        bpl     v_noscroll

:
        sub16_8 winrect::y2, #$0B

v_noscroll:
        inc16   winrect::x1
        dec16   winrect::x2
        jmp     return_winrect_jmp


horiz:  jsr     GetWinHorizScrollRect
        add16_8 winrect::x1, #$15
        sub16_8 winrect::x2, #$15

        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::vscroll
        bpl     h_novscroll

:       sub16_8 winrect::x2, #$15

h_novscroll:
        inc16   winrect::y1
        dec16   winrect::y2

return_winrect_jmp:
        jmp     return_winrect
.endproc ; GetScrollbarScrollArea


        thumb_max := $A3
        thumb_pos := $A1

        kXThumbWidth  = 20
        kYThumbHeight = 12


.proc GetThumbRect
        thumb_coord := $82

        jsr     GetScrollbarScrollArea

        jsr     GetThumbVals
        jsr     FixedDiv

        lda     fixed_div_quotient+2    ; 8.0 integral part
        pha
        jsr     CalcCtlBounds
        jsr     SetUpThumbDivision
        pla
        tax

        lda     thumb_max
        ldy     thumb_max+1

        ;;cpx     #1              ; 100%
        dex
        beq     :+

        ldx     fixed_div_quotient+1    ; 0.8 fractional part
        jsr     GetThumbCoord

:       sta     thumb_coord
        sty     thumb_coord+1

        ldx     #0              ; x-coords
        lda     #kXThumbWidth

        bit     which_control
        bpl     :+

        ldx     #2              ; y-coords
        lda     #kYThumbHeight
:       pha
        add16   winrect,x, thumb_coord, winrect,x
        pla
        ;;clc
        adc     winrect::x1,x
        sta     winrect::x2,x
        lda     winrect::x1+1,x
        adc     #0
        sta     winrect::x2+1,x
        jmp     return_winrect
.endproc ; GetThumbRect

;;; ============================================================
;;; FindControl

;;; 4 bytes of params, copied to current_penloc

.proc FindControlImpl
        jsr     SaveParamsAndStack

        jsr     TopWindow
        bne     :+
        EXIT_CALL MGTK::Error::no_active_window
:

ep:
        bit     current_winfo::vscroll
        bpl     no_vscroll

        jsr     GetWinVertScrollRect
        jsr     InWinRect
        beq     no_vscroll

        ldx     #0
        lda     current_winfo::vscroll
        lsr
        bcc     vscrollbar

        lda     #which_control_vert
        sta     which_control

        jsr     GetScrollbarScrollArea
        jsr     InWinRect
        beq     in_arrows

        bit     current_winfo::vscroll
        bvc     return_dead_zone

        jsr     GetThumbRect
        jsr     InWinRect
        beq     no_thumb

        ldx     #MGTK::Part::thumb
        bne     vscrollbar

in_arrows:
        lda     #MGTK::Part::up_arrow
        bne     :+

no_thumb:
        lda     #MGTK::Part::page_up
:       pha
        jsr     GetThumbRect
        pla
        tax
        lda     current_penloc_y
        cmp     winrect::y1
        bcc     :+
        inx                     ; part_down_arrow / part_page_down
:
vscrollbar:
        lda     #MGTK::Ctl::vertical_scroll_bar
        bne     return_result

no_vscroll:
        bit     current_winfo::hscroll
        bpl     no_hscroll

        jsr     GetWinHorizScrollRect
        jsr     InWinRect
        beq     no_hscroll

        ldx     #0
        lda     current_winfo::hscroll
        lsr
        bcc     hscrollbar

        lda     #which_control_horiz
        sta     which_control

        jsr     GetScrollbarScrollArea
        jsr     InWinRect
        beq     in_harrows

        bit     current_winfo::hscroll
        bvc     return_dead_zone

        jsr     GetThumbRect
        jsr     InWinRect
        beq     no_hthumb

        ldx     #MGTK::Part::thumb
        bne     hscrollbar

in_harrows:
        lda     #MGTK::Part::left_arrow
        bne     :+

no_hthumb:
        lda     #MGTK::Part::page_left
:       pha
        jsr     GetThumbRect
        pla
        tax
        scmp16  current_penloc_x, winrect::x1
        bmi     hscrollbar
        inx

hscrollbar:
        lda     #MGTK::Ctl::horizontal_scroll_bar
        bne     return_result

no_hscroll:
        jsr     GetWinRect
        jsr     InWinRect
        beq     return_dead_zone

        lda     #MGTK::Ctl::not_a_control
        beq     return_result

return_dead_zone:
        lda     #MGTK::Ctl::dead_zone
return_result:
        jmp     FindWindowImpl::return_result
.endproc ; FindControlImpl

.proc FindControlExImpl
        PARAM_BLOCK params, $82
mousex          .word
mousey          .word
which_ctl       .byte
which_part      .byte
window_id       .byte
        END_PARAM_BLOCK

        jsr     SaveParamsAndStack

        ;; Needed for FindControl
        COPY_STRUCT MGTK::Point, params::mousex, current_penloc

        ;; Needed for WindowByIdOrExit
        copy8   params::window_id, $82

        jsr     WindowByIdOrExit
        jmp     FindControlImpl::ep
.endproc ; FindControlExImpl

;;; ============================================================
;;; SetCtlMax

;;; 3 bytes of params, copied to $82

.proc SetCtlMaxImpl
        PARAM_BLOCK params, $82
which_ctl  .byte
ctlmax     .byte
        END_PARAM_BLOCK

        lda     params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+
        lda     #$80
        sta     params::which_ctl
        bne     got_ctl        ; always

:       eor     #MGTK::Ctl::horizontal_scroll_bar
        bne     :+
        sta     params::which_ctl
        beq     got_ctl        ; always

:       EXIT_CALL MGTK::Error::control_not_found

got_ctl:
        jsr     TopWindow
        bne     :+

        EXIT_CALL MGTK::Error::no_active_window

:       ldy     #MGTK::Winfo::hthumbmax
        bit     params::which_ctl
        bpl     :+

        ldy     #MGTK::Winfo::vthumbmax
:       lda     params::ctlmax
        sta     (window),y
        sta     current_winfo,y
        rts
.endproc ; SetCtlMaxImpl

;;; ============================================================
;;; TrackThumb

;;; 5 bytes of params, copied to $82

.proc TrackThumbImpl
        PARAM_BLOCK params, $82
which_ctl   .byte
mouse_pos   .tag MGTK::Point
thumbpos    .byte
thumbmoved  .byte
        END_PARAM_BLOCK

        thumb_dim := $82


        lda     params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+

        lda     #which_control_vert
        sta     params::which_ctl
        bne     got_ctl                    ; always

:       eor     #MGTK::Ctl::horizontal_scroll_bar
        bne     :+

        ;;lda     #which_control_horiz
        .assert which_control_horiz = 0, error, "which_control_horiz must be 0"
        sta     params::which_ctl
        beq     got_ctl                    ; always

:       EXIT_CALL MGTK::Error::control_not_found

got_ctl:lda     params::which_ctl
        sta     which_control

        ldx     #3
:       lda     params::mouse_pos,x
        sta     drag_initialpos,x
        sta     drag_curpos,x
        dex
        bpl     :-

        jsr     TopWindow
    IF ZERO
        EXIT_CALL MGTK::Error::no_active_window
    END_IF

        jsr     GetThumbRect

        ;; Stash initial position, to detect no-op
        initial_pos := $8A

        ldx     #0
        bit     which_control
    IF NS
        ldx     #2
    END_IF
        lda     winrect,x
        sta     initial_pos
        lda     winrect+1,x
        sta     initial_pos+1

        jsr     SaveParamsAndStack
        jsr     SetDesktopPort

        jsr     SetFillModeXOR
        MGTK_CALL MGTK::SetPattern, light_speckles_pattern

        jsr     HideCursorImpl
drag_loop:
        jsr     FrameWinRect
        jsr     ShowCursorImpl

no_change:
        jsr     GetAndReturnEvent
        cmp     #MGTK::EventKind::button_up
        beq     drag_done

        jsr     CheckIfChanged
        beq     no_change

        jsr     HideCursorImpl
        jsr     FrameWinRect

        jsr     TopWindow
        jsr     GetThumbRect

        ldx     #0
        lda     #kXThumbWidth

        bit     which_control
        bpl     :+

        ldx     #2
        lda     #kYThumbHeight

:       sta     thumb_dim

        lda     winrect,x
        clc
        adc     drag_delta,x
        tay
        lda     winrect+1,x
        adc     drag_delta+1,x
        cmp     ctl_bound1+1
        bcc     :+
        bne     in_bound1
        cpy     ctl_bound1
        bcs     in_bound1

:       lda     ctl_bound1+1
        ldy     ctl_bound1

in_bound1:
        cmp     ctl_bound2+1
        bcc     in_bound2
        bne     :+
        cpy     ctl_bound2
        bcc     in_bound2

:       lda     ctl_bound2+1
        ldy     ctl_bound2

in_bound2:
        sta     winrect+1,x
        tya
        sta     winrect,x
        clc
        adc     thumb_dim
        sta     winrect::x2,x
        lda     winrect+1,x
        adc     #0
        sta     winrect::x2+1,x
        bcc     drag_loop               ; always

drag_done:
        jsr     HideCursorImpl
        jsr     FrameWinRect
        jsr     ShowCursorAndRestore

        ;; Did position change?
        ldx     #0
        bit     which_control
        bpl     :+
        ldx     #2
:       lda     winrect,x
        cmp     initial_pos
        bne     :+
        lda     winrect+1,x
        cmp     initial_pos+1
        bne     :+
        lda     thumb_pos       ; (out) thumbpos = original value
        ldx     #0              ; (out) thumbmoved = 0
        beq     store           ; always
:
        jsr     SetUpThumbDivision

        jsr     FixedDiv
        ldx     FixedDiv::quotient+2    ; 8.0 integral part

        jsr     GetThumbVals

        lda     FixedDiv::divisor
        ldy     #0
        cpx     #1
        bcs     :+

        ldx     fixed_div_quotient+1     ; 0.8 fractional part
        jsr     GetThumbCoord
:
        ldx     #1              ; (out) thumbmoved
store:
        ldy     #params::thumbpos - params
        jmp     store_xa_at_y
.endproc ; TrackThumbImpl


        ;; Calculates the thumb coordinates given the maximum position
        ;; and current fraction.
        ;;
        ;; Inputs:
        ;;    A,Y = maximum position of thumb in 16.0 format
        ;;    X   = fraction in fixed 0.8 format
        ;;
        ;; Outputs:
        ;;    A,Y = current position of thumb in 16.0 format
        ;;          (= maximum position * fraction)
        ;;
.proc GetThumbCoord
        increment := $82
        accum     := $84

        sta     increment       ; fixed 8.8 = max position/256
        sty     increment+1

        lda     #$80            ; fixed 8.8 = 1/2
        sta     accum
        ldy     #$00
        sty     accum+1

        txa                     ; fixed 8.0 = fraction*256
        beq     ret
loop:   add16   increment, accum, accum ; returning with A=high byte of accum
        bcc     :+
        iny
:       dex                     ; (accum low),A,Y is in fixed 16.8
        bne     loop            ; return A,Y
ret:    rts
.endproc ; GetThumbCoord


ctl_bound2:
        .res 2
ctl_bound1:
        .res 2


        ;; Set FixedDiv::divisor and FixedDiv::dividend up for the
        ;; proportion calculation for the control in which_control.
.proc SetUpThumbDivision
        sub16   ctl_bound2, ctl_bound1, FixedDiv::divisor
        ldx     #0
        bit     which_control
        bpl     :+

        ldx     #2
:       sub16   winrect,x, ctl_bound1, FixedDiv::dividend
        rts
.endproc ; SetUpThumbDivision


        ;; Set thumb_max and thumb_pos according to the control indicated
        ;; in which_control.
.proc GetThumbVals
        ldy     #MGTK::Winfo::hthumbmax

        bit     which_control
    IF NS
        ldy     #MGTK::Winfo::vthumbmax
    END_IF

        lda     (window),y
        sta     thumb_max
        iny
        lda     (window),y
        sta     thumb_pos

        lda     #0
        sta     thumb_pos+1
        sta     thumb_max+1
        rts
.endproc ; GetThumbVals


.proc CalcCtlBounds
        offset := $82

        ldx     #0
        lda     #kXThumbWidth

        bit     which_control
   IF NS
        ldx     #2
        lda     #kYThumbHeight
   END_IF

        sta     offset

        lda     winrect::x1,x
        ldy     winrect::x1+1,x
        sta     ctl_bound1
        sty     ctl_bound1+1

        lda     winrect::x2,x
        ldy     winrect::x2+1,x
        sec
        sbc     offset
        bcs     :+
        dey
:       sta     ctl_bound2
        sty     ctl_bound2+1
        rts
.endproc ; CalcCtlBounds


;;; ============================================================
;;; UpdateThumb

;;; 3 bytes of params, copied to $8C

.proc UpdateThumbImpl
        PARAM_BLOCK params, $8C
which_ctl   .byte
thumbpos    .byte
        END_PARAM_BLOCK


        lda     which_control
    IF A = #MGTK::Ctl::vertical_scroll_bar
        lda     #which_control_vert
        sta     which_control
        bne     check_win       ; always
    END_IF

        eor     #MGTK::Ctl::horizontal_scroll_bar
    IF ZERO
        ;;lda     #which_control_horiz
        .assert which_control_horiz = 0, error, "which_control_horiz must be 0"
        sta     which_control
        beq     check_win       ; always
    END_IF

        EXIT_CALL MGTK::Error::control_not_found

check_win:
        jsr     TopWindow
    IF ZERO
        EXIT_CALL MGTK::Error::no_active_window
    END_IF

        ldy     #MGTK::Winfo::hthumbpos
        bit     which_control
    IF NS
        ldy     #MGTK::Winfo::vthumbpos
    END_IF

        lda     params::thumbpos
        RTS_IF A = (window),y   ; no-op if no change
        sta     (window),y

        jsr     HideCursorSaveParams
        jsr     SetStandardPort
        jsr     DrawOrEraseScrollbar
        jmp     ShowCursorAndRestore
.endproc ; UpdateThumbImpl

;;; ============================================================
;;; KeyboardMouse

;;; 1 byte of params, copied to $82

.proc KeyboardMouse
        lda     #kKeyboardMouseStateForced
        sta     kbd_mouse_state
        jmp     FlushEventsImpl
.endproc ; KeyboardMouse

;;; ============================================================


kKeyboardMouseStateInactive = 0  ; Disabled
kKeyboardMouseStateMouseKeys = 4 ; MouseKeys mode
kKeyboardMouseStateForced = $80  ; KeyboardMouse call

kbd_mouse_state:
        .byte   kKeyboardMouseStateInactive


kbd_mouse_x:  .word     0
kbd_mouse_y:  .word     0

saved_mouse_pos:
saved_mouse_x:  .word   0
saved_mouse_y:  .byte   0

movement_cancel:  .byte   $00
kbd_mouse_status:  .byte   $00

;;; ============================================================
;;; X = xlo, Y = xhi, A = y


.proc SetMousePos
        bit     mouse_hooked_flag
        bmi     no_firmware
        bit     no_mouse_flag
        bmi     no_firmware

        pha
        txa
        sec
        jsr     ScaleMouseCoord

        ldx     mouse_firmware_hi
        sta     MOUSE_X_LO->$C000,x
        tya
        sta     MOUSE_X_HI->$C000,x

        pla
        ldy     #$00
        clc
        jsr     ScaleMouseCoord

        ldx     mouse_firmware_hi
        sta     MOUSE_Y_LO->$C000,x
        tya
        sta     MOUSE_Y_HI->$C000,x

        ldy     #POSMOUSE
        jmp     CallMouse

no_firmware:
        jsr     SetMouseCoords
        bit     mouse_hooked_flag
        bpl     not_hooked
        ldy     #POSMOUSE
        jmp     CallMouse

not_hooked:
        rts
.endproc ; SetMousePos

.proc SetMouseCoords
        stx     mouse_x
        sty     mouse_x+1
        sta     mouse_y
        rts
.endproc ; SetMouseCoords

;;; ============================================================

.proc RestoreMousePos
        ldx     saved_mouse_x
        ldy     saved_mouse_x+1
        lda     saved_mouse_y
        jmp     SetMousePos
.endproc ; RestoreMousePos

.proc SetMousePosFromKbdMouse
        ldx     kbd_mouse_x
        ldy     kbd_mouse_x+1
        lda     kbd_mouse_y
        jmp     SetMousePos
.endproc ; SetMousePosFromKbdMouse


.proc ScaleMouseCoord
        bcc     scale_y
        ldx     mouse_scale_x
        bne     :+
ret:    rts

scale_y:
        ldx     mouse_scale_y
        beq     ret

:       pha
        tya
        lsr     a
        tay
        pla
        ror     a
        dex
        bne     :-
        rts
.endproc ; ScaleMouseCoord


.proc KbdMouseToMouse
        COPY_BYTES 3, kbd_mouse_x, mouse_x
        rts
.endproc ; KbdMouseToMouse

.proc PositionKbdMouse
        jsr     KbdMouseToMouse
        jmp     SetMousePosFromKbdMouse
.endproc ; PositionKbdMouse


.proc SaveMousePos
        jsr     ReadMousePos
        COPY_BYTES 3, mouse_x, saved_mouse_pos
        rts
.endproc ; SaveMousePos

.proc UnstashCursor
        jsr     stash_addr
        copy16  kbd_mouse_cursor_stash, params_addr
        jsr     SetCursorImpl
        jsr     restore_addr

        ;; Exit special state
        lda     #kKeyboardMouseStateInactive
        sta     kbd_mouse_state
        ;; Flag a button release to finish the implied drag
        lda     #$40
        sta     mouse_status
        jmp     RestoreMousePos
.endproc ; UnstashCursor

.proc KbdMouseInitTracking
        lda     #0
        sta     movement_cancel
        sta     force_tracking_change
        rts
.endproc ; KbdMouseInitTracking

        ;; Look at buttons (apple keys), compute modifiers in A
        ;; (bit 0 = button 0 / open apple, bit 1 = button 1 / solid apple)
.proc ComputeModifiers
        lda     BUTN1
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        rts
.endproc ; ComputeModifiers


;;; Will consume keypress, so must not be called if processing keys
;;; normally in `CheckEventsImpl`
;;; Assert: `kbd_mouse_state` is not `kKeyboardMouseStateInactive`
.proc GetKey
        jsr     ComputeModifiers
        sta     set_input_modifiers
no_modifiers:
        clc
        lda     KBD
    IF NS
        stx     KBDSTRB
        and     #CHAR_MASK
        sec
    END_IF
        rts
.endproc ; GetKey


;;; Assert: `kbd_mouse_state` is not `kKeyboardMouseStateInactive`
.proc HandleKeyboardMouse
        cmp     #kKeyboardMouseStateMouseKeys
        beq     KbdMouseMousekeys

        jsr     KbdMouseSyncCursor
        jmp     KbdMouseDoWindow
.endproc ; HandleKeyboardMouse


.proc StashCursor
        jsr     stash_addr
        copy16  active_cursor, kbd_mouse_cursor_stash
        copy16  #pointer_cursor, params_addr
        jsr     SetCursorImpl
        jmp     restore_addr
.endproc ; StashCursor

kbd_mouse_cursor_stash:
        .res    2

stash_addr:
        copy16  params_addr, stashed_addr
        rts

restore_addr:
        copy16  stashed_addr, params_addr
        rts

stashed_addr:  .addr     0


.proc KbdMouseMousekeys
        jsr     ComputeModifiers  ; C=_ A=____ __SO
        ror     a                 ; C=O A=____ ___S
        ror     a                 ; C=S A=O___ ____
        ror     kbd_mouse_status  ; shift solid apple into bit 7 of kbd_mouse_status
        lda     kbd_mouse_status  ; becomes mouse button
        sta     mouse_status
        lda     #0
        sta     input::modifiers

        jsr     GetKey::no_modifiers
        jcs     MousekeysInput

        jmp     PositionKbdMouse
.endproc ; KbdMouseMousekeys


;;; Input: `input::modifiers` and `input::key` have been set
.proc CheckActivateMouseKeys
        ;; Activate?
        bit     mouse_status
        bmi     ignore          ; branch away if button is down

        ;; Check for OA+SA+Space
        lda     input::modifiers
        cmp     #3
        bne     ignore
        lda     input::key
        cmp     #' '            ; space?
        bne     ignore

        ;; Give immediate feedback
        jsr     PlayTone1
        jsr     PlayTone2

        ;; Wait for OA and SA to be released
    DO
        jsr     ComputeModifiers
    WHILE NOT ZERO
        sta     input::modifiers

        lda     #kKeyboardMouseStateMouseKeys
        sta     kbd_mouse_state
        lda     #0
        sta     kbd_mouse_status ; reset mouse button status
        COPY_BYTES 3, cursor_pos, kbd_mouse_x

        RETURN  C=0

ignore:
        RETURN  C=1

.endproc ; CheckActivateMouseKeys

.proc EndMouseKeys
        jsr     PlayTone2
        jsr     PlayTone1
        lda     #kKeyboardMouseStateInactive
        sta     kbd_mouse_state

        RETURN  C=0
.endproc ; EndMouseKeys

.proc PlayTone1
        lda     #$00            ; pitch = 256
        ldx     #$40            ; duration = 16384
        bne     PlayTone        ; always
.endproc ; PlayTone1

.proc PlayTone2
        lda     #$E0            ; pitch = 224
        ldx     #$49            ; duration = 16352
        FALL_THROUGH_TO PlayTone
.endproc ; PlayTone2

;;; A = pitch, A*X = duration
.proc PlayTone
beeploop:
        bit     SPKR
        tay
    DO
        dey
    WHILE NOT ZERO
        dex
        bne     beeploop

        rts
.endproc ; PlayTone

.proc KbdMouseSyncCursor
        bit     mouse_status
    IF NS
        lda     #kKeyboardMouseStateInactive
        sta     kbd_mouse_state
        jmp     SetMousePosFromKbdMouse
    END_IF

        lda     mouse_status
        ldx     #$C0
        stx     mouse_status
        and     #$20
    IF NOT_ZERO
        COPY_BYTES 3, mouse_x, kbd_mouse_x
        rts
    END_IF

        jmp     KbdMouseToMouse
.endproc ; KbdMouseSyncCursor



.proc KbdWinDragOrGrow
        php
        sei
        jsr     SaveMousePos
        lda     #$80
        sta     mouse_status

        jsr     GetWinFrameRect
        bit     drag_resize_flag
        bpl     do_drag

        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        beq     no_grow

        ldx     #0
:       sec
        lda     winrect::x2,x
        sbc     #4
        sta     kbd_mouse_x,x
        sta     drag_initialpos,x
        sta     drag_curpos,x

        lda     winrect::x2+1,x
        sbc     #0
        sta     kbd_mouse_x+1,x
        sta     drag_initialpos+1,x
        sta     drag_curpos+1,x

        inx
        inx
        cpx     #4
        bcc     :-

        sec
        lda     #<(kScreenWidth-1)
        sbc     drag_initialpos::xcoord
        lda     #>(kScreenWidth-1)
        sbc     drag_initialpos::xcoord+1
        bmi     no_grow

        sec
        lda     #<(kScreenHeight-1)
        sbc     drag_initialpos::ycoord
        lda     #>(kScreenHeight-1)
        sbc     drag_initialpos::ycoord+1
        bmi     no_grow
        jsr     PositionKbdMouse
        jsr     StashCursor
        plp
        rts

no_grow:
        lda     #kKeyboardMouseStateInactive
        sta     kbd_mouse_state
        lda     #MGTK::Error::window_not_resizable
        plp
        jmp     exit_with_a

do_drag:
        ldx     #0
        lda     current_winfo::options
        ;;and     #MGTK::Option::dialog_box
        ;;beq     no_dialog
        .assert MGTK::Option::dialog_box = 1, error, "dialog_box must be 1"
        lsr
        bcc     no_dialog

        ;;ldx     #kKeyboardMouseStateInactive
        .assert kKeyboardMouseStateInactive = 0, error, "kKeyboardMouseStateInactive must be 0"
        stx     kbd_mouse_state
        EXIT_CALL MGTK::Error::window_not_draggable

no_dialog:
dragloop:
        clc
        lda     winrect::x1,x
        cpx     #2
        beq     is_y
        adc     #$23 - 5

is_y:   adc     #5
        sta     kbd_mouse_x,x
        sta     drag_initialpos,x
        sta     drag_curpos,x

        lda     winrect::x1+1,x
        adc     #0
        sta     kbd_mouse_x+1,x
        sta     drag_initialpos+1,x
        sta     drag_curpos+1,x
        inx
        inx
        cpx     #4
        bcc     dragloop

        bit     kbd_mouse_x+1
        bpl     xpositive

        ldx     #1
        lda     #0
:       sta     kbd_mouse_x,x
        sta     drag_initialpos,x
        sta     drag_curpos,x
        dex
        bpl     :-

xpositive:
        jsr     PositionKbdMouse
        jsr     StashCursor
        plp
        rts
.endproc ; KbdWinDragOrGrow


.proc KbdMouseAddToY
        php
        clc
        adc     kbd_mouse_y
        sta     kbd_mouse_y
        plp

    IF NEG
        ;; Negative offset - if wrapped, clamp to 0
      IF A >= #<kScreenHeight
        lda     #0
        sta     kbd_mouse_y
      END_IF

pos:    jmp     PositionKbdMouse
    END_IF

        ;; Positive offset - if beyond screen, clamp to max
        cmp     #<kScreenHeight
        bcc     pos
        lda     #<(kScreenHeight-1)
        sta     kbd_mouse_y
        bne     pos             ; always
.endproc ; KbdMouseAddToY


.proc KbdMouseDoWindow
        jsr     GetKey
        RTS_IF CC

    IF A = #CHAR_ESCAPE
        copy8   #$80, movement_cancel
        jmp     UnstashCursor
    END_IF

    IF A = #CHAR_RETURN
        jmp     UnstashCursor
    END_IF

        tax
        lda     set_input_modifiers
        beq     :+
        ora     #$80
        sta     set_input_modifiers
:
        txa
        ldx     #$C0
        stx     mouse_status
        FALL_THROUGH_TO MousekeysInput
.endproc ; KbdMouseDoWindow

.proc MousekeysInput
    IF A = #CHAR_ESCAPE
        jmp     EndMouseKeys
    END_IF

    IF A = #CHAR_UP
        lda     #256-48
        bit     set_input_modifiers
        bmi     :+              ; leave N flag set
        lda     #256-8          ; sets N flag
:       jmp     KbdMouseAddToY  ; N flag must be set here
    END_IF

    IF A = #CHAR_DOWN
        lda     #8
        bit     set_input_modifiers
        bpl     :+              ; leave N flag clear
        lda     #48             ; clears N flag
:       jmp     KbdMouseAddToY  ; N flag must be clear here
    END_IF

    IF A = #CHAR_RIGHT
        jsr     KbdMouseCheckXmax
        bcc     out_of_bounds

        clc
        lda     #8
        bit     set_input_modifiers
        bpl     :+
        lda     #64

:       adc     kbd_mouse_x
        sta     kbd_mouse_x
        bcc     :+
        inc     kbd_mouse_x+1
:
        sec
        lda     kbd_mouse_x
        sbc     #<(kScreenWidth-1)
        lda     kbd_mouse_x+1
        sbc     #>(kScreenWidth-1)
        bmi     out_of_bounds

        lda     #>(kScreenWidth-1)
        sta     kbd_mouse_x+1
        lda     #<(kScreenWidth-1)
        sta     kbd_mouse_x
out_of_bounds:
        jmp     PositionKbdMouse
    END_IF

    IF A = #CHAR_LEFT
        jsr     KbdMouseCheckXmin
        bcc     out_of_boundsl

        lda     kbd_mouse_x
        bit     set_input_modifiers
        bpl     :+
        sbc     #64 - 8

:       sbc     #8
        sta     kbd_mouse_x
        lda     kbd_mouse_x+1
        sbc     #0
        sta     kbd_mouse_x+1
        bpl     out_of_boundsl

        lda     #0
        sta     kbd_mouse_x
        sta     kbd_mouse_x+1
out_of_boundsl:
        jmp     PositionKbdMouse
    END_IF

        sta     set_input_key   ; TODO: Is this needed any more?
        rts
.endproc ; MousekeysInput


.proc SetInput
        MGTK_CALL MGTK::PostEvent, set_input_params
        rts
.endproc ; SetInput

.params set_input_params          ; 1 byte shorter than normal, since KEY
state:  .byte   MGTK::EventKind::key_down
key:    .byte   0
modifiers:
        .byte   0
.endparams
        set_input_key := set_input_params::key
        set_input_modifiers := set_input_params::modifiers

        ;; Set to true to force the return value of CheckIfChanged to true
        ;; during a tracking kOperation.
force_tracking_change:
        .byte   0


.proc KbdMouseCheckXmin
        lda     kbd_mouse_state
        cmp     #kKeyboardMouseStateMouseKeys
        beq     ret_ok

        lda     kbd_mouse_x
        bne     ret_ok
        lda     kbd_mouse_x+1
        bne     ret_ok

        bit     drag_resize_flag
        bpl     :+
ret_ok: RETURN  C=1

:       jsr     GetWinFrameRect
        lda     winrect::x2+1
        bne     min_ok
        lda     #9
        bit     set_input_params::modifiers
        bpl     :+

        lda     #65
:       cmp     winrect::x2
        bcc     min_ok
        RETURN  C=0

min_ok: inc     force_tracking_change

        clc
        lda     #8
        bit     set_input_params::modifiers
        bpl     :+
        lda     #64

:       adc     drag_initialpos
        sta     drag_initialpos
        bcc     :+
        inc     drag_initialpos+1
:
        RETURN  C=0
.endproc ; KbdMouseCheckXmin


.proc KbdMouseCheckXmax
        lda     kbd_mouse_state
        cmp     #kKeyboardMouseStateMouseKeys
        beq     :+

        bit     drag_resize_flag
        bmi     :+

        lda     kbd_mouse_x
        sbc     #<(kScreenWidth-1)
        lda     kbd_mouse_x+1
        sbc     #>(kScreenWidth-1)
        beq     is_max

:
        RETURN  C=1

is_max: jsr     GetWinFrameRect
        sec
        lda     #<(kScreenWidth-1)
        sbc     winrect::x1
        tax
        lda     #>(kScreenWidth-1)
        sbc     winrect::x1+1
        beq     :+

        ldx     #256-1
:       bit     set_input_modifiers
        bpl     :+

        cpx     #100
        bcc     clc_rts
        bcs     ge_100

:       cpx     #44
        bcs     in_range

clc_rts:
        RETURN  C=0

ge_100: sec
        lda     drag_initialpos
        sbc     #64
        jmp     :+

in_range:
        sec
        lda     drag_initialpos
        sbc     #8
:       sta     drag_initialpos
        bcs     :+
        dec     drag_initialpos+1
:
        inc     force_tracking_change
        RETURN  C=0
.endproc ; KbdMouseCheckXmax


grew_flag:
        .byte   0

.proc SetGrewFlag
        lda     #$80
        sta     grew_flag
grts:   rts
.endproc ; SetGrewFlag


.proc FinishGrow
        bit     kbd_mouse_state
        bpl     SetGrewFlag::grts

        bit     grew_flag
        bpl     SetGrewFlag::grts

        jsr     GetWinFrameRect
        php
        sei
        ldx     #0
:       sub16   winrect::x2,x, #4, kbd_mouse_x,x
        inx
        inx
        cpx     #4
        bcc     :-

        jsr     PositionKbdMouse
        plp
        rts
.endproc ; FinishGrow

;;; ============================================================
;;; ScaleMouse

;;; Sets up mouse clamping

;;; 2 bytes of params, copied to $82
;;; byte 1 controls x clamp, 2 controls y clamp
;;; clamp is to fractions of screen (0 = full, 1 = 1/2, 2 = 1/4, 3 = 1/8) (why???)

.proc ScaleMouseImpl
        PARAM_BLOCK params, $82
x_exponent      .byte
y_exponent      .byte
        END_PARAM_BLOCK

        lda     params::x_exponent
        sta     mouse_scale_x
        lda     params::y_exponent
        sta     mouse_scale_y

set_clamps:
        bit     no_mouse_flag   ; called after INITMOUSE
        bmi     end

        ldy     mouse_scale_x
        lda     clamp_x_table_low,y
        ldx     clamp_x_table_high,y
        ldy     #CLAMP_X
        jsr     set_clamp

        ldy     mouse_scale_y
        lda     clamp_y_table_low,y
        ldx     clamp_y_table_high,y
        ldy     #CLAMP_Y
        FALL_THROUGH_TO set_clamp

set_clamp:
        sta     mouse_y
        stx     mouse_y+1
        bit     mouse_hooked_flag
        bmi     :+
        sta     CLAMP_MAX_LO
        stx     CLAMP_MAX_HI
:
        lda     #0
        sta     mouse_x
        sta     mouse_x+1
        bit     mouse_hooked_flag
        bmi     :+
        sta     CLAMP_MIN_LO
        sta     CLAMP_MIN_HI
:
        tya                     ; CLAMP_X or CLAMP_Y
        ldy     #CLAMPMOUSE
        jmp     CallMouse

end:    rts

clamp_x_table_low:  .byte   <(kScreenWidth-1), <(kScreenWidth/2-1), <(kScreenWidth/4-1), <(kScreenWidth/8-1)
clamp_x_table_high: .byte   >(kScreenWidth-1), >(kScreenWidth/2-1), >(kScreenWidth/4-1), >(kScreenWidth/8-1)
clamp_y_table_low:  .byte   <(kScreenHeight-1), <(kScreenHeight/2-1), <(kScreenHeight/4-1), <(kScreenHeight/8-1)
clamp_y_table_high: .byte   >(kScreenHeight-1), >(kScreenHeight/2-1), >(kScreenHeight/4-1), >(kScreenHeight/8-1)

.endproc ; ScaleMouseImpl

;;; ============================================================
;;; Locate Mouse Slot


        ;; If X's high bit is set, only slot in low bits is tested.
        ;; Otherwise all slots are scanned.

.proc FindMouse
        txa
        and     #$7F
        beq     scan
        jsr     CheckMouseInA
        sta     no_mouse_flag
        beq     found
        RETURN  X=#0

        ;; Scan for mouse starting at slot 7
scan:   ldx     #7
loop:   txa
        jsr     CheckMouseInA
        sta     no_mouse_flag
        beq     found
        dex
        bpl     loop
        inx                     ; no mouse found
        rts

found:
        ldy     #INITMOUSE
        jsr     CallMouseWithROMBankedIn ; ensure `VERSION` is accurate

        jsr     ScaleMouseImpl::set_clamps
        ldy     #HOMEMOUSE
        jsr     CallMouse
        lda     mouse_firmware_hi
        and     #$0F
        tax                     ; return with mouse slot in X
        rts

        ;; Check for mouse in slot A
.proc CheckMouseInA
        ptr := $88

        ora     #>$C000
        sta     ptr+1
        lda     #<$0000
        sta     ptr

        ldy     #$0C            ; $Cn0C = $20
        lda     (ptr),y
        cmp     #$20
        bne     nope

        ldy     #$FB            ; $CnFB = $D6
        lda     (ptr),y
        cmp     #$D6
        bne     nope

        lda     ptr+1           ; yay, found it!
        sta     mouse_firmware_hi
        asl     a
        asl     a
        asl     a
        asl     a
        sta     mouse_operand
        RETURN  A=#$00

nope:   RETURN  A=#$80
.endproc ; CheckMouseInA
.endproc ; FindMouse

no_mouse_flag:               ; high bit set if no mouse present
        .byte   0
mouse_firmware_hi:           ; e.g. if mouse is in slot 4, this is $C4
        .byte   0
mouse_operand:               ; e.g. if mouse is in slot 4, this is $40
        .byte   0



;;; ============================================================
;;; GetDeskPat

.proc GetDeskPatImpl
        ldax    #desktop_pattern
        jmp     store_xa_at_params
.endproc ; GetDeskPatImpl

;;; ============================================================
;;; SetDeskPat

.proc SetDeskPatImpl
        ldy     #.sizeof(MGTK::Pattern)-1
:       lda     (params_addr),y
        sta     desktop_pattern,y
        dey
        bpl     :-
        rts
.endproc ; SetDeskPatImpl

;;; ============================================================
;;; GetWinFrameRect

;;; 5 bytes of params, copied to $82

.proc GetWinFrameRectImpl
        PARAM_BLOCK params, $82
window_id  .byte
rect       .tag MGTK::Rect
        END_PARAM_BLOCK

        jsr     WindowByIdOrExit
        jsr     GetWinFrameRect

        ;; Copy Rect from winrect to params_addr + 1
        kOffset = params::rect - params
        ldy     #kOffset + .sizeof(MGTK::Rect)
:       lda     winrect - kOffset,y
        sta     (params_addr),y
        dey
        bne     :-              ; leave window_id alone
        rts
.endproc ; GetWinFrameRectImpl

;;; ============================================================
;;; RedrawDeskTop

.proc RedrawDeskTopImpl
        COPY_STRUCT desktop_mapinfo, set_port_params

        ;; Restored by `EraseWindow`
        jsr     HideCursorSaveParams

        lda     #0              ; window to erase (none)
        jmp     EraseWindow
.endproc ; RedrawDeskTopImpl

;;; ============================================================

.proc FlashMenuBarImpl
        jsr     SaveParamsAndStack
        jsr     SetStandardPort
        jsr     SetFillModeXOR
        MGTK_CALL MGTK::PaintRect, menu_bar_rect
        jmp     RestoreParamsActivePort
.endproc ; FlashMenuBarImpl

;;; ============================================================

.proc InflateRectImpl
        PARAM_BLOCK params, $82
rect       .addr
xdelta     .word
ydelta     .word
        END_PARAM_BLOCK

        ldy     #0

        ;; Subtract from x1 and y1; Y is 0...3
        ldx     #2
:       sec
        lda     (params::rect),y
        sbc     params::xdelta,y
        sta     (params::rect),y
        iny
        lda     (params::rect),y
        sbc     params::xdelta,y
        sta     (params::rect),y
        iny
        dex
        bne     :-

        ;; Add to x1 and y1; Y is 4...7
        ldx     #2
:       clc
        lda     (params::rect),y
        adc     params::xdelta - 4,y
        sta     (params::rect),y
        iny
        lda     (params::rect),y
        adc     params::xdelta - 4,y
        sta     (params::rect),y
        iny
        dex
        bne     :-

        rts
.endproc ; InflateRectImpl

;;; ============================================================

.proc UnionRectsImpl
        PARAM_BLOCK, $82
rect1_ptr  .addr
rect2_ptr  .addr
        END_PARAM_BLOCK

        ldy     #0
        jsr     do_pair
        ldy     #2
        FALL_THROUGH_TO do_pair

        ;; Process a pair (e.g. x1 and x2, or y1 and y2)
do_pair:
        ;; left or top
        jsr     compare
        bpl     :+
        jsr     assign
:       iny
        iny
        iny

        ;; right or bottom
        jsr     compare
        bmi     :+
        jsr     assign
:
        rts

compare:
        lda     (rect1_ptr),y
        cmp     (rect2_ptr),y
        iny
        lda     (rect1_ptr),y
        sbc     (rect2_ptr),y
        bvc     :+              ; signed compare
        eor     #$80
:       rts

assign:
        dey
        lda     (rect1_ptr),y
        sta     (rect2_ptr),y
        iny
        lda     (rect1_ptr),y
        sta     (rect2_ptr),y
        rts

.endproc ; UnionRectsImpl

;;; ============================================================

.proc MulDivImpl
        PARAM_BLOCK params, $82
number          .word           ; (in)
numerator       .word           ; (in)
denominator     .word           ; (in)
result          .word           ; (out)
remainder       .word           ; (out)
        END_PARAM_BLOCK

AUXL    := params::number       ; $54 in original routines
AUXH    := params::number+1
ACL     := params::numerator    ; $50 in original routines
ACH     := params::numerator+1
AUX2L   := params::denominator  ; not in original routines
AUX2H   := params::denominator+1
XTNDL   := $90                  ; $52 in original routines
XTNDH   := $91
TMPL    := $92                  ; not in original routines
TMPH    := $93

        ;; Prepare, per "Apple II Monitors Peeled" pp.71

        lda     #0
        sta     XTNDL
        sta     XTNDH

        ;; From MUL routine in Apple II Monitor, by Woz
        ;; "Apple II Reference Manual" pp.162

        ldy     #16             ; Index for 16 bits
MUL2:   lda     ACL             ; ACX * AUX + XTND
        lsr                     ;   to AC, XTND
        bcc     MUL4            ; If no carry,
        clc                     ;   no partial product.
        ldx     #AS_BYTE(-2)
MUL3:   lda     XTNDL+2,x       ; Add multiplicand (AUX)
        adc     AUXL+2,x        ;  to partial product
        sta     XTNDL+2,x       ;     (XTND).
        inx
        bne     MUL3

;;; Original has this which is one byte shorter but requires AC and
;;; XTND to be adjacent:
;;;
;;; MUL4:   ldx     #3
;;; MUL5:   ror     ACL,x
;;;         dex
;;;         bpl     MUL5

MUL4:   ror     XTNDH
        ror     XTNDL
        ror     ACH
        ror     ACL

        dey
        bne     MUL2

        ;; Numerator: ACX,XTNDX
        ;; Denominator: AUX2X
        ;; Remainder: AUXX,TMPH

        lda     #0              ; clear remainder
        sta     AUXL
        sta     AUXH
        sta     TMPL
        sta     TMPH

        ldy     #32             ; bits remaining

DIV2:   asl     ACL             ; shift high bits of numerator...
        rol     ACH
        rol     XTNDL
        rol     XTNDH

        rol     AUXL            ; into remainder
        rol     AUXH
        rol     TMPL
        rol     TMPH

        sec                     ; is remainder > denominator?

        lda     AUXL            ; temp = remainder - denominator
        sbc     AUX2L
        pha
        lda     AUXH
        sbc     AUX2H
        pha
        lda     TMPL
        sbc     #0
        tax
        lda     TMPH
        sbc     #0

        bcs     DIV3

        pla                     ; no, drop temp value
        pla
        jmp     next

DIV3:   inc     ACL             ; yes

        sta     TMPH            ; remainder = temp
        stx     TMPL
        pla
        sta     AUXH
        pla
        sta     AUXL

next:   dey
        bne     DIV2
        FALL_THROUGH_TO finish

        ;; --------------------------------------------------
        ;; Update `result`/`remainder` in passed param block

finish:
        lda     ACL             ; result
        ldy     #(params::result - params)
        sta     (params_addr),y
        iny
        lda     ACL+1
        sta     (params_addr),y
        iny
        lda     AUXL            ; remainder
        sta     (params_addr),y
        iny
        lda     AUXL+1
        sta     (params_addr),y

        rts
.endproc ; MulDivImpl

;;; ============================================================
;;; ShieldCursor

;;; 16 bytes of params, copied to $8A

.proc ShieldCursorImpl
        ;; Input is a `MapInfo`
        left   := $8A
        top    := $8C
        bitmap := $8E           ; unused
        stride := $90           ; unused
        hoff   := $92           ; unused (TODO: should it be?)
        voff   := $94           ; unused (TODO: should it be?)
        width  := $96
        height := $98

        right   := width
        bottom  := height

        kSlop = 14    ; Two DHR bytes worth of pixels

        jsr     CheckRect

        ;; Offset passed rect by current port
        ldx     #2              ; loop over dimensions
    DO
        add16   left,x, current_winport::viewloc+MGTK::Point::xcoord,x, left,x
        dex
        dex
    WHILE POS

        ;; Offset passed rect by hotspot
        add16_8 left, cursor_hotspot_x
        add16_8 top, cursor_hotspot_y

        ;; Compute the far edges
        ldx     #2              ; loop over dimensions
    DO
        add16   left,x, width,x, right,x
        dex
        dex
    WHILE POS

        ;; Account for cursor size and render slop
        sub16_8 left, #MGTK::cursor_width * 7 + kSlop
        add16_8 right, #kSlop
        sub16_8 top, #MGTK::cursor_height

        ldx     #2              ; loop over dimensions
    DO
        lda     cursor_pos+1,x
        cmp     left+1,x
        bmi     outside
        bne     :+
        lda     cursor_pos,x
        cmp     left,x
        bcc     outside
:
        lda     cursor_pos+1,x
        cmp     right+1,x
        bmi     :+
        bne     outside
        lda     cursor_pos,x
        cmp     right,x
        bcc     :+
        bne     outside
:
        dex
        dex
    WHILE POS

        SET_BIT7_FLAG cursor_shielded_flag
        jmp     HideCursorImpl

outside:
ret:    rts
.endproc ; ShieldCursorImpl

.proc UnshieldCursorImpl
        rol     cursor_shielded_flag
        bcc     ShieldCursorImpl::ret
        jmp     ShowCursorImpl
.endproc ; UnshieldCursorImpl

cursor_shielded_flag:
        .byte   0

;;; ============================================================

.proc WaitVBL
        php
        sei

        proc_addr := *+1
        jsr     iie_proc

        plp
        rts

;;; --------------------------------------------------
;;; IIe

iie_proc:
:       bit RDVBLBAR            ; wait for end of VBL (if in it)
        bpl     :-
:       bit RDVBLBAR            ; wait for start of next VBL
        bmi     :-
        rts

;;; --------------------------------------------------
;;;IIgs

iigs_proc:
:       bit RDVBLBAR            ; wait for end of VBL (if in it)
        bmi     :-
:       bit RDVBLBAR            ; wait for start of next VBL
        bpl     :-
        rts

;;; --------------------------------------------------
;;; IIc

iic_proc:
        lda     IOUDISON        ; = RDIOUDIS
        pha                     ; save IOUDIS state
        sta     IOUDISOFF

        lda     RDVBLMSK
        pha                     ; save VBL interrupt state
        sta     ENVBL

        ;; TODO: Is this enough?
:       bit     RDVBLBAR
        bpl     :-

        pla                     ; restore VBL interrupt state
    IF NC
        sta     DISVBL
    END_IF

        pla                     ; restore IOUDIS state
    IF NC
        sta     IOUDISON
    END_IF
        rts

.endproc
vbl_proc_addr := WaitVBL::proc_addr
vbl_iigs_proc := WaitVBL::iigs_proc
vbl_iic_proc := WaitVBL::iic_proc

;;; ============================================================

.endscope ; mgtk

        ;; Room for future expansion
        PAD_TO $8800
