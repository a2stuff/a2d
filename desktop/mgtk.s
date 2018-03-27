        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ============================================================
;;; MouseGraphics ToolKit
;;; ============================================================

.proc mgtk
        .org $4000

        screen_width := 560
        screen_height := 192

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

.proc dispatch
        .assert * = MGTK::MLI, error, "Entry point must be at $4000"

        lda     LOWSCR
        sta     SET80COL

        bit     preserve_zp_flag ; save ZP?
        bpl     adjust_stack

        ;; Save $80...$FF, swap in what MGTK needs at $F4...$FF
        ldx     #$7F
:       lda     $80,x
        sta     zp_saved,x
        dex
        bpl     :-
        ldx     #$0B
:       lda     active_saved,x
        sta     active_port,x
        dex
        bpl     :-
        jsr     apply_active_port_to_port

adjust_stack:                   ; Adjust stack to account for params
        pla                     ; and stash address at params_addr.
        sta     params_addr
        clc
        adc     #<3
        tax
        pla
        sta     params_addr+1
        adc     #>3
        pha
        txa
        pha

        tsx
        stx     stack_ptr_stash

        ldy     #1              ; Command index
        lda     (params_addr),y
        asl     a
        tax
        copy16  jump_table,x, jump_addr

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

        txa                     ; if high bit was set, stash
        pha                     ; registers and params_addr and then
        tya                     ; optionally hide cursor
        pha
        lda     params_addr
        pha
        lda     params_addr+1
        pha
        bit     desktop_initialized_flag
        bpl     :+
        jsr     hide_cursor
:       pla
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
        bpl     :+
        jsr     show_cursor

:       bit     preserve_zp_flag
        bpl     exit_with_0
        jsr     apply_port_to_active_port
        ldx     #$0B
:       lda     active_port,x
        sta     active_saved,x
        dex
        bpl     :-
        ldx     #$7F
:       lda     zp_saved,x
        sta     $80,x
        dex
        bpl     :-

        ;; default is to return with A=0
exit_with_0:
        lda     #0

rts1:   rts
.endproc

;;; ============================================================
;;; Routines can jmp here to exit with A set

exit_with_a:
        pha
        jsr     dispatch::cleanup
        pla
        ldx     stack_ptr_stash
        txs
        ldy     #$FF
rts2:   rts

        ;; TODO: Macro for exit_with_a

.macro exit_call arg
        lda     #arg
        jmp     exit_with_a
.endmacro

;;; ============================================================
;;; Copy port params (36 bytes) to/from active port addr

.proc apply_active_port_to_port
        ldy     #MGTK::grafport_size-1
:       lda     (active_port),y
        sta     current_grafport,y
        dey
        bpl     :-
        rts
.endproc

.proc apply_port_to_active_port
        ldy     #MGTK::grafport_size-1
:       lda     current_grafport,y
        sta     (active_port),y
        dey
        bpl     :-
        rts
.endproc

;;; ============================================================
;;; Drawing calls show/hide cursor before/after
;;; A recursion count is kept to allow rentrancy.

hide_cursor_count:
        .byte   0

.proc hide_cursor
        dec     hide_cursor_count
        jmp     HideCursorImpl
.endproc

.proc show_cursor
        bit     hide_cursor_count
        bpl     rts2
        inc     hide_cursor_count
        jmp     ShowCursorImpl
.endproc

;;; ============================================================
;;; Jump table for MGTK entry point calls

        ;; jt_rts can be used if the only thing the
        ;; routine needs to do is copy params into
        ;; the zero page (port)
        jt_rts := dispatch::rts1

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
        .addr   SetUserHookImpl               ; $1F SetUserHook
        .addr   AttachDriverImpl    ; $20 AttachDriver
        .addr   ScaleMouseImpl      ; $21 ScaleMouseImpl
        .addr   KeyboardMouse       ; $22 KeyboardMouse
        .addr   GetIntHandlerImpl   ; $23 GetIntHandler

        ;; Cursor Manager Calls
        .addr   SetCursorImpl       ; $24 SetCursor
        .addr   ShowCursorImpl      ; $25 ShowCursor
        .addr   HideCursorImpl      ; $26 HideCursor
        .addr   ObscureCursorImpl   ; $27 ObscureCursor
        .addr   GetCursorAddrImpl   ; $28 GetCursorAddr

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

        ;; Extra Calls
        .addr   BitBltImpl          ; $4D BitBlt
        .addr   SetMenuSelectionImpl; $4E SetMenuSelection

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
        PARAM_DEFN  1, $82, 0                ; $22 KeyboardMouse
        PARAM_DEFN  0, $00, 0                ; $23 GetIntHandler

        ;; Cursor Manager
        PARAM_DEFN  0, $00, 0                ; $24 SetCursor
        PARAM_DEFN  0, $00, 0                ; $25 ShowCursor
        PARAM_DEFN  0, $00, 0                ; $26 HideCursor
        PARAM_DEFN  0, $00, 0                ; $27 ObscureCursor
        PARAM_DEFN  0, $00, 0                ; $28 GetCursorAddr

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
        PARAM_DEFN  3, $82, 0                ; $49 SetCtlMax
        PARAM_DEFN  5, $82, 0                ; $4A TrackThumb
        PARAM_DEFN  3, $8C, 0                ; $4B UpdateThumb
        PARAM_DEFN  2, $8C, 0                ; $4C ActivateCtl

        ;; Extra Calls
        PARAM_DEFN 16, $8A, 0                ; $4D ???
        PARAM_DEFN  2, $82, 0                ; $4E SetMenuSelection

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
        src_addr          := $82        ; pointer to source bitmap
        vid_addr          := $84        ; pointer to video memory
        left_bytes        := $86        ; offset of leftmost coordinate in chars (0-39)
        bits_addr         := $8E        ; pointer to pattern/bitmap
        width_mod14       := $87        ; width of rectangle mod 14
        left_sidemask     := $88        ; bitmask applied to clip left edge of rect
        right_sidemask    := $89        ; bitmask applied to clip right edge of rect
        src_y_coord       := $8C

        src_mapwidth      := $90        ; source stride; $80 = DHGR layout
        width_bytes       := $91        ; width of rectangle in chars

        left_masks_table  := $92        ; bitmasks for left edge indexed by page (0=main, 1=aux)
        right_masks_table := $96        ; bitmasks for right edge indexed by page (0=main, 1=aux)

        top               := $94        ; top/starting/current y-coordinate
        bottom            := $98        ; bottom/ending/maximum y-coordinate
        left              := $92
        right             := $96

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


.proc fillmode_copy
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
.endproc
.proc fillmode_copy_onechar
        lda     (vid_addr),y
        eor     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc

.proc fillmode_or
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
.endproc
.proc fillmode_or_onechar
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        ora     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc

.proc fillmode2_xor
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
.endproc
.proc fillmode2_xor_onechar
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc

.proc fillmode_bic
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
.endproc
.proc fillmode_bic_onechar
        lda     (bits_addr),y
        eor     fill_eor_mask
        and     left_sidemask
        eor     #$FF
        and     (vid_addr),y
        and     current_colormask_and
        ora     current_colormasks_or
        sta     (vid_addr),y
        rts
.endproc


        ;; Main fill loop.

.proc fill_next_line
        cpx     bottom                  ; fill done?
        beq     :+
        inx

get_srcbits_jmp:
get_srcbits_jmp_addr := *+1
        jmp     start_fill_jmp          ; patched to *_get_srcbits if there
                                        ; is a source bitmap
:       rts
.endproc

        ;; Copy a line of source data from a non-display bitmap buffer to
        ;; the staging buffer at $0601.

.proc ndbm_get_srcbits
        lda     load_addr
        adc     src_mapwidth
        sta     load_addr
        bcc     :+
        inc     load_addr+1

:       ldy     src_width_bytes

loop:
load_addr       := *+1
        lda     $FFFF,y                 ; off-screen BMP will be patched here
        and     #$7F
        sta     bitmap_buffer,y
        dey
        bpl     loop
        bmi     shift_bits_clc_jmp
.endproc

        ;; Copy a line of source data from the DHGR screen to the staging
        ;; buffer at $0601.

.proc dhgr_get_srcbits
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
        jmp     shift_line_jmp          ; patched to dhgr_shift_bits when needed
.endproc


shift_bits_clc_jmp := dhgr_get_srcbits::shift_bits_clc_jmp


        ;; Subprocedure used to shift bitmap data by a number of bits.

.proc dhgr_shift_bits
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
        jmp     dhgr_next_line          ; patched to dhgr_shift_line when needed
.endproc


shift_line_jmp := dhgr_shift_bits::shift_line_jmp


        ;; Subprocedure used to shift bitmap data by an integral number of
        ;; chars.

.proc dhgr_shift_line
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
        jmp     dhgr_next_line
.endproc


        ;; Entry point to start bit blit operation.

.proc bit_blit
        ldx     top
        clc
        jmp     fill_next_line::get_srcbits_jmp
.endproc


        ;; Entry point to start fill after fill mode and destination have
        ;; been set.

.proc do_fill
        ldx     no_srcbits_addr                         ; Disable srcbits fetching
        stx     fill_next_line::get_srcbits_jmp_addr    ; for fill operation.
        ldx     no_srcbits_addr+1
        stx     fill_next_line::get_srcbits_jmp_addr+1

        ldx     top
        ;; Fall-through
.endproc

start_fill_jmp:
start_fill_jmp_addr := *+1
        jmp     dhgr_start_fill         ; patched to *_start_fill


        ;; Start a fill targeting a non-display bitmap (NDBM)

.proc ndbm_start_fill
        txa                     ; pattern y-offset
        ror     a
        ror     a
        ror     a
        and     #$C0            ; to high 2 bits
        ora     left_bytes
        sta     src_addr

        lda     #>pattern_buffer
        adc     #0
        sta     src_addr+1
        jmp     dhgr_get_srcbits::get_bits
.endproc


        ;; Start a fill targeting the DHGR screen.

.proc dhgr_start_fill
        txa                     ; pattern y-offset
        ror     a
        ror     a
        ror     a
        and     #$C0            ; to high 2 bits
        ora     left_bytes
        sta     bits_addr

        lda     #>pattern_buffer
        adc     #0
        sta     bits_addr+1

next_line_jmp_addr := *+1
        jmp     dhgr_next_line
.endproc


        ;; Advance to the next line and fill (non-display bitmap
        ;; destination.)

.proc ndbm_next_line
        lda     vid_addr
        clc
        adc     current_mapwidth
        sta     vid_addr
        bcc     :+
        inc     vid_addr+1
        clc
:       ldy     width_bytes

        jsr     fillmode_jmp
        jmp     fill_next_line
.endproc


        ;; Set vid_addr for the next line and fill (DHGR destination.)

.proc dhgr_next_line
        lda     hires_table_hi,x
        ora     current_mapbits+1
        sta     vid_addr+1
        lda     hires_table_lo,x
        clc
        adc     left_bytes
        sta     vid_addr

        ldy     #1                      ; aux mem
        jsr     dhgr_fill_line
        ldy     #0                      ; main mem
        jsr     dhgr_fill_line
        jmp     fill_next_line
.endproc


        ;; Fill one line in either main or aux screen memory.

.proc dhgr_fill_line
        sta     LOWSCR,y

        lda     left_masks_table,y
        ora     #$80
        sta     left_sidemask

        lda     right_masks_table,y
        ora     #$80
        sta     right_sidemask

        ldy     width_bytes
        ;; Fall-through
.endproc

fillmode_jmp:
        jmp     fillmode_copy       ; modified with fillmode routine

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
fill_mode_table:
        .addr   fillmode_copy,fillmode_or,fillmode2_xor,fillmode_bic
        .addr   fillmode_copy,fillmode_or,fillmode2_xor,fillmode_bic

        ; Fill routines that handle only 1 char.
fill_mode_table_onechar:
        .addr   fillmode_copy_onechar,fillmode_or_onechar,fillmode2_xor_onechar,fillmode_bic_onechar
        .addr   fillmode_copy_onechar,fillmode_or_onechar,fillmode2_xor_onechar,fillmode_bic_onechar

;;; ============================================================
;;; SetPenMode

.proc SetPenModeImpl
        lda     current_penmode
        ldx     #0
        cmp     #4
        bcc     :+
        ldx     #$7F
:       stx     fill_eor_mask
        rts
.endproc

        ;; Called from PaintRect, DrawText, etc to configure
        ;; fill routines from mode.

.proc set_up_fill_mode
        x1      := $92
        x2      := $96

        x1_bytes := $86
        x2_bytes := $82

        add16   x_offset, x2, x2
        add16   y_offset, bottom, bottom

        add16   x_offset, x1, x1
        add16   y_offset, top, top

        lsr     x2+1
        beq     :+
        jmp     rl_ge256

:       lda     x2
        ror     a
        tax
        lda     div7_table,x
        ldy     mod7_table,x

set_x2_bytes:
        sta     x2_bytes
        tya
        rol     a
        tay
        lda     aux_right_masks,y
        sta     right_masks_table+1
        lda     main_right_masks,y
        sta     right_masks_table

        lsr     x1+1
        bne     ll_ge256
        lda     x1
        ror     a
        tax
        lda     div7_table,x
        ldy     mod7_table,x

set_x1_bytes:
        sta     x1_bytes
        tya
        rol     a
        tay
        sty     width_mod14
        lda     aux_left_masks,y
        sta     left_masks_table+1
        lda     main_left_masks,y
        sta     left_masks_table
        lda     x2_bytes
        sec
        sbc     x1_bytes

set_width:                                      ; Set width for destination.
        sta     width_bytes
        pha
        lda     current_penmode
        asl     a
        tax
        pla
        bne     :+                              ; Check if one or more than one is needed

        lda     left_masks_table+1              ; Only one char is needed, so combine
        and     right_masks_table+1             ; the left and right masks and use the
        sta     left_masks_table+1              ; one-char fill subroutine.
        sta     right_masks_table+1
        lda     left_masks_table
        and     right_masks_table
        sta     left_masks_table
        sta     right_masks_table

        copy16  fill_mode_table_onechar,x, fillmode_jmp+1
        rts

:       copy16  fill_mode_table,x, fillmode_jmp+1
        rts

ll_ge256:                               ; Divmod for left limit >= 256
        lda     x1
        ror     a
        tax
        php
        lda     div7_table+4,x
        clc
        adc     #$24
        plp
        ldy     mod7_table+4,x
        bpl     set_x1_bytes

rl_ge256:                               ; Divmod for right limit >= 256
        lda     x2
        ror     a
        tax
        php
        lda     div7_table+4,x
        clc
        adc     #$24
        plp
        ldy     mod7_table+4,x
        bmi     divmod7
        jmp     set_x2_bytes
.endproc


.proc divmod7
        lsr     a
        bne     :+
        txa
        ror     a
        tax
        lda     div7_table,x
        ldy     mod7_table,x
        rts

:       txa
        ror     a
        tax
        php
        lda     div7_table+4,x
        clc
        adc     #$24
        plp
        ldy     mod7_table+4,x
        rts
.endproc


        ;; Set up destination (for either on-screen or off-screen bitmap.)

.proc set_dest
        DEST_NDBM       := 0            ; draw to off-screen bitmap
        DEST_DHGR       := 1            ; draw to DHGR screen

        lda     left_bytes
        ldx     top
        ldy     current_mapwidth
        jsr     ndbm_calc_dest
        clc
        adc     current_mapbits
        sta     vid_addr
        tya
        adc     current_mapbits+1
        sta     vid_addr+1

        lda     #2*DEST_DHGR
        tax
        tay
        bit     current_mapwidth
        bmi     on_screen               ; negative for on-screen destination

        copy16  #bitmap_buffer, bits_addr

        jsr     ndbm_fix_width
        txa
        inx
        stx     src_width_bytes
        jsr     set_up_fill_mode::set_width

        copy16  shift_line_jmp_addr, dhgr_get_srcbits::shift_bits_jmp_addr
        lda     #2*DEST_NDBM
        ldx     #2*DEST_NDBM
        ldy     #2*DEST_NDBM

on_screen:
        pha
        lda     next_line_table,x
        sta     dhgr_start_fill::next_line_jmp_addr
        lda     next_line_table+1,x
        sta     dhgr_start_fill::next_line_jmp_addr+1
        pla
        tax
        copy16  start_fill_table,x, start_fill_jmp+1
        copy16  shift_line_table,y, dhgr_shift_bits::shift_line_jmp_addr
        rts
.endproc


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

;;              DEST_NDBM        DEST_DHGR
shift_line_jmp_addr:
        .addr   shift_line_jmp

start_fill_table:
        .addr   ndbm_start_fill, dhgr_start_fill
next_line_table:
        .addr   ndbm_next_line,  dhgr_next_line
shift_line_table:
        .addr   ndbm_next_line,  dhgr_shift_line


        ;; Set source for bitmap transfer (either on-screen or off-screen bitmap.)

.proc set_source
        SRC_NDBM        := 0
        SRC_DHGR        := 1

        ldx     src_y_coord
        ldy     src_mapwidth
        bmi     :+
        jsr     ndbm_calc_off

:       clc
        adc     bits_addr
        sta     ndbm_get_srcbits::load_addr
        tya
        adc     bits_addr+1
        sta     ndbm_get_srcbits::load_addr+1

        ldx     #2*SRC_DHGR
        bit     src_mapwidth
        bmi     :+

        ldx     #2*SRC_NDBM
:       copy16  get_srcbits_table,x, fill_next_line::get_srcbits_jmp_addr
        rts

;;              SRC_NDBM           SRC_DHGR
get_srcbits_table:
        .addr   ndbm_get_srcbits,  dhgr_get_srcbits
.endproc


        ;; Calculate destination for off-screen bitmap.

.proc ndbm_calc_dest
        bmi     on_screen        ; do nothing for on-screen destination
        asl     a

calc_off:
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
.endproc


ndbm_calc_off := ndbm_calc_dest::calc_off


;;; ============================================================
;;; SetPattern

;; Expands the pattern to 8 rows of DHGR-style bitmaps at
;; $0400, $0440, $0480, $04C0, $0500, $0540, $0580, $05C0
;; (using both main and aux mem.)

.proc SetPatternImpl
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
loop:   lda     x_offset
        and     #7
        tay

        lda     current_penpattern,x
:       dey
        bmi     :+
        cmp     #$80
        rol     a
        bne     :-

:       ldy     #$27
:       pha
        lsr     a
        sta     LOWSCR
        sta     (bits_addr),y
        pla
        ror     a
        pha
        lsr     a
        sta     HISCR
        sta     (bits_addr),y
        pla
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

next:   dex
        bpl     loop
        sta     LOWSCR
        rts
.endproc


;;; ============================================================
;;; FrameRect

;;; 8 bytes of params, copied to $9F

frect_ctr:  .byte   0

.proc FrameRectImpl
        left   := $9F
        top    := $A1
        right  := $A3
        bottom := $A5

        ldy     #3
rloop:  ldx     #7
:       lda     left,x
        sta     left_masks_table,x
        dex
        bpl     :-
        ldx     rect_sides,y
        lda     left,x
        pha
        lda     $A0,x
        ldx     rect_coords,y
        sta     $93,x
        pla
        sta     left_masks_table,x
        sty     frect_ctr
        jsr     draw_line
        ldy     frect_ctr
        dey
        bpl     rloop
        ldx     #3
:       lda     left,x
        sta     current_penloc,x
        dex
        bpl     :-
.endproc
prts:   rts

rect_sides:
        .byte   0,2,4,6
rect_coords:
        .byte   4,6,0,2

.proc draw_line
        x2      := right

        lda     current_penwidth    ; Also: draw horizontal line $92 to $96 at $98
        sec
        sbc     #1
        cmp     #$FF
        beq     prts
        adc     x2
        sta     x2
        bcc     :+
        inc     x2+1

:       lda     current_penheight
        sec
        sbc     #1
        cmp     #$FF
        beq     prts
        adc     bottom
        sta     bottom
        bcc     PaintRectImpl
        inc     bottom+1
        ;; Fall through...
.endproc


;;; ============================================================
;;; PaintRect

;;; 8 bytes of params, copied to $92

.proc PaintRectImpl
        jsr     check_rect
do_paint:
        jsr     clip_rect
        bcc     prts
        jsr     set_up_fill_mode
        jsr     set_dest
        jmp     do_fill
.endproc


;;; ============================================================
;;; InRect

;;; 8 bytes of params, copied to $92

.proc InRectImpl
        jsr     check_rect
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
:       exit_call MGTK::error_in_object           ; success!

fail:   rts
.endproc

;;; ============================================================
;;; SetPortBits

.proc SetPortBitsImpl
        sub16   current_viewloc_x, current_maprect_x1, x_offset
        sub16   current_viewloc_y, current_maprect_y1, y_offset
        rts
.endproc


        clipped_left := $9B        ; number of bits clipped off left side
        clipped_top := $9D         ; number of bits clipped off top side


.proc clip_rect
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
        sec
        rts
.endproc


.proc check_rect
        sec
        lda     right
        sbc     left
        lda     right+1
        sbc     left+1
        bmi     bad_rect
        sec
        lda     bottom
        sbc     top
        lda     bottom+1
        sbc     top+1
        bmi     bad_rect
        rts

bad_rect:
        exit_call MGTK::error_empty_object
.endproc


;;; ============================================================

;;; 16 bytes of params, copied to $8A

src_width_bytes:
        .res    1          ; width of source data in chars

L5169:  .byte   0

PaintBitsImpl:

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
        ;; fall through to BitBlt

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

        jsr     clip_rect
        bcs     :+
        rts

:       jsr     set_up_fill_mode
        lda     width_bytes
        asl     a
        ldx     left_masks_table+1      ; need left mask on aux?
        beq     :+
        adc     #1
:       ldx     right_masks_table       ; need right mask on main?
        beq     :+
        adc     #1
:       sta     L5169
        sta     src_width_bytes         ; adjusted width in chars

        lda     #2
        sta     shift_bytes
        lda     #0                      ; Calculate starting Y-coordinate
        sec                             ;  = dbi_top - clipped_top
        sbc     clipped_top
        clc
        adc     dbi_top
        sta     dbi_top

        lda     #0                      ; Calculate starting X-coordinate
        sec                             ;  = dbi_left - clipped_left
        sbc     clipped_left
        tax
        lda     #0
        sbc     clipped_left+1
        tay

        txa
        clc
        adc     dbi_left
        tax
        tya
        adc     dbi_left+1

        jsr     divmod7
        sta     src_byte_off
        tya                             ; bit offset between src and dest
        rol     a
        cmp     #7
        ldx     #1
        bcc     :+
        dex
        sbc     #7

:       stx     dhgr_get_srcbits::offset1_addr
        inx
        stx     dhgr_get_srcbits::offset2_addr
        sta     bit_offset

        lda     src_byte_off
        rol     a

        jsr     set_source
        jsr     set_dest
        copy16  #bitmap_buffer, bits_addr
        ldx     #1
        lda     width_mod14

        sec
        sbc     #7
        bcc     :+
        sta     width_mod14
        dex
:       stx     dhgr_shift_line::offset1_addr
        inx
        stx     dhgr_shift_line::offset2_addr

        lda     width_mod14
        sec
        sbc     bit_offset
        bcs     :+
        adc     #7
        inc     src_width_bytes
        dec     shift_bytes
:       tay                                     ; check if bit shift required
        bne     :+
        ldx     #2*BITS_NO_BITSHIFT
        beq     no_bitshift

:       tya
        asl     a
        tay
        copy16  shift_table_main,y, dhgr_shift_bits::shift_main_addr

        copy16  shift_table_aux,y, dhgr_shift_bits::shift_aux_addr

        ldy     shift_bytes
        sty     dhgr_shift_bits::offset2_addr
        dey
        sty     dhgr_shift_bits::offset1_addr

        ldx     #2*BITS_BITSHIFT
no_bitshift:
        copy16  shift_bits_table,x, dhgr_get_srcbits::shift_bits_jmp_addr
        jmp     bit_blit

BITS_NO_BITSHIFT := 0
BITS_BITSHIFT := 1

;;              BITS_NO_BITSHIFT   BITS_BITSHIFT
shift_bits_table:
        .addr   shift_line_jmp,    dhgr_shift_bits
.endproc


        shift_table_aux := *-2
        .addr   shift_1_aux,shift_2_aux,shift_3_aux
        .addr   shift_4_aux,shift_5_aux,shift_6_aux

        shift_table_main := *-2
        .addr   shift_1_main,shift_2_main,shift_3_main
        .addr   shift_4_main,shift_5_main,shift_6_main


        vertex_limit     := $B3
        vertices_count   := $B4
        poly_oper        := $BA       ; positive = paint; negative = test
        start_index      := $AE

        poly_oper_paint  := $00
        poly_oper_test   := $80


.proc load_poly
        point_index      := $82
        low_point        := $A7

        max_poly_points  := 60

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

        ldy     #0
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
        cpx     #max_poly_points
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
        sec
        rts

:       jmp     clip_rect
.endproc


.proc next_poly
        lda     vertices_count
        bpl     orts
        asl     a
        asl     a
        adc     params_addr
        sta     params_addr
        bcc     ora_2_param_bytes
        inc     params_addr+1
        ;; Fall-through
.endproc

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
        max_num_maxima   := 8

        low_vertex       := $B0


.proc PaintPolyImpl

        lda     #poly_oper_paint
entry2: sta     poly_oper
        ldx     #0
        stx     num_maxima
        jsr     ora_2_param_bytes

loop:   jsr     load_poly
        bcs     process_poly
        ldx     low_vertex
next:   jsr     next_poly
        bmi     loop

        jmp     fill_polys

bad_poly:
        exit_call MGTK::error_bad_object
.endproc


        temp_yh        := $83
        next_vertex    := $AA
        current_vertex := $AC
        loop_ctr       := $AF


.proc process_poly
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
        cpx     #2*max_num_maxima         ; too many maxima points (documented limitation)
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
.endproc


        scan_y       := $A9
        lr_flag      := $AB
        start_maxima := $B1

.proc fill_polys
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
        jsr     calc_slope

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

        jsr     calc_slope

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
        bpl     do_paint

        jsr     InRectImpl
        jmp     skip_rect

do_paint:
        jsr     PaintRectImpl::do_paint

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
.endproc


.proc calc_slope
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
        sub16   #0, <fixed_div_dividend, <fixed_div_dividend

:       stx     index
        jsr     fixed_div2
        ldx     index
        plp
        bpl     :+

        sub16   #0, <fixed_div_quotient, <fixed_div_quotient
        lda     #0
        sbc     <fixed_div_quotient+2
        sta     <fixed_div_quotient+2
        lda     #0
        sbc     <fixed_div_quotient+3
        sta     <fixed_div_quotient+3

:       lda     <fixed_div_quotient+3
        sta     poly_maxima_slope3,x
        cmp     #$80
        ror     a
        pha
        lda     <fixed_div_quotient+2
        sta     poly_maxima_slope2,x
        ror     a
        pha
        lda     <fixed_div_quotient+1
        sta     poly_maxima_slope1,x
        ror     a
        pha
        lda     <fixed_div_quotient
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
.endproc

PaintPolyImpl_entry2 := PaintPolyImpl::entry2
bad_poly := PaintPolyImpl::bad_poly


.proc fixed_div
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
.endproc

fixed_div2 := fixed_div::entry2

fixed_div_dividend   := fixed_div::dividend
fixed_div_divisor    := fixed_div::divisor
fixed_div_quotient   := fixed_div::quotient


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
        jsr     load_poly
        bcc     next

        lda     $B3
        sta     $B5             ; loop counter

        ;; Loop for drawing
        ldy     #0
loop:   dec     $B5
        beq     endloop
        sty     $B9

        ldx     #0
:       lda     (ptr),y
        sta     draw_line_params,x
        iny
        inx
        cpx     #8
        bne     :-
        jsr     DRAW_LINE_ABS_IMPL_L5783

        lda     $B9
        clc
        adc     #4
        tay
        bne     loop

endloop:
        ;; Draw from last point back to start
        ldx     #0
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
        jsr     DRAW_LINE_ABS_IMPL_L5783

        ;; Handle multiple segments, e.g. when drawing outlines for multi icons?

next:   ldx     #1
:       lda     ptr,x
        sta     $80,x
        lda     $B5,x
        sta     $B3,x
        dex
        bpl     :-

        jsr     next_poly           ; Advance to next polygon in list
        bmi     poly_loop
        rts
.endproc

;;; ============================================================
;;; Move

;;; 4 bytes of params, copied to $A1

.proc MoveImpl
        xdelta := $A1
        ydelta := $A3

        ldax    xdelta
        jsr     adjust_xpos
        ldax    ydelta
        clc
        adc     current_penloc_y
        sta     current_penloc_y
        txa
        adc     current_penloc_y+1
        sta     current_penloc_y+1
        rts
.endproc

        ;; Adjust current_penloc_x by (X,A)
.proc adjust_xpos
        clc
        adc     current_penloc_x
        sta     current_penloc_x
        txa
        adc     current_penloc_x+1
        sta     current_penloc_x+1
        rts
.endproc

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
        ;; fall through
.endproc

;;; ============================================================
;;; LineTo

;;; 4 bytes of params, copied to $92

.proc LineToImpl

        params  := $92
        xend    := params + 0
        yend    := params + 2

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
L5783:
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
        jmp     draw_line

swap_start_end:
        ldx     #3              ; Swap start/end
:       lda     pt1,x
        tay
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
        jmp     draw_line

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

.endproc
        DRAW_LINE_ABS_IMPL_L5783 := LineToImpl::L5783

;;; ============================================================
;;; SetFont

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

        cmp     #17             ; if height >= 17, skip this next bit
        bcs     end

        ldax    current_textfont
        clc
        adc     #3
        bcc     :+
        inx
:       stax    glyph_widths    ; set $FB/$FC to start of widths

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

end:    exit_call MGTK::error_font_too_big
.endproc

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
        jsr     measure_text
        ldy     #3              ; Store result (X,A) at params+3
        sta     (params_addr),y
        txa
        iny
        sta     (params_addr),y
        rts
.endproc

        ;; Call with data at ($A1), length in $A3, result in (X,A)
.proc measure_text
        data   := $A1
        length := $A3

        accum  := $82

        ldx     #0
        ldy     #0
        sty     accum
loop:   sty     accum+1
        lda     (data),y
        tay
        txa
        clc
        adc     (glyph_widths),y
        bcc     :+
        inc     accum
:       tax
        ldy     accum+1
        iny
        cpy     length
        bne     loop
        txa
        ldx     accum
        rts
.endproc

;;; ============================================================

L5907:  sec
        sbc     #1
        bcs     L590D
        dex
L590D:  clc
        adc     current_penloc_x
        sta     $96
        txa
        adc     current_penloc_x+1
        sta     $97
        copy16  current_penloc_x, $92
        lda     current_penloc_y
        sta     $98
        ldx     current_penloc_y+1
        stx     $99
        clc
        adc     #1
        bcc     L592D
        inx
L592D:  sec
        sbc     $FF
        bcs     L5933
        dex
L5933:  stax    $94
        rts

;;; ============================================================

;;; 3 bytes of params, copied to $A1

.proc DrawTextImpl
        text_addr := $A1        ; param
        text_len  := $A3        ; param
        text_width := $A4       ; computed

        jsr     maybe_unstash_low_zp
        jsr     measure_text
        stax    text_width
        ldy     #0
        sty     $9F
        sty     $A0
        sty     $9B
        sty     $9D
        jsr     L5907
        jsr     clip_rect
        bcc     L59B9
        tya
        ror     a
        bcc     L5972
        ldy     #0
        ldx     $9C
L595C:  sty     $9F
        lda     (text_addr),y
        tay
        lda     (glyph_widths),y
        clc
        adc     $9B
        bcc     L596B
        inx
        beq     L5972
L596B:  sta     $9B
        ldy     $9F
        iny
        bne     L595C
L5972:  jsr     set_up_fill_mode
        jsr     set_dest
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
        ldy     current_mapwidth
        bpl     L599F
        asl     a
        tax
        lda     $87
        cmp     #7
        bcs     L5998
        inx
L5998:  lda     $96
        beq     L599D
        inx
L599D:  stx     $91
L599F:  lda     $87
        sec
        sbc     #7
        bcc     L59A8
        sta     $87
L59A8:  lda     #0
        rol     a
        eor     #1
        sta     $9C
        tax
        sta     LOWSCR,x
        jsr     L59C3
        sta     LOWSCR
L59B9:  jsr     maybe_stash_low_zp
        ldax    text_width
        jmp     adjust_xpos

L59C3:  lda     $98
        sec
        sbc     $94
        asl     a
        tax
        copy16  L5D81,x, L5B02
        copy16  L5DA1,x, L5A95
        copy16  L5DC1,x, L5C22
        copy16  L5DE1,x, L5CBE
        txa
        lsr     a
        tax
        sec
        stx     $80
        stx     $81
        lda     #0
        sbc     $9D
        sta     $9D
        tay
        ldx     #$C3
        sec
L5A0C:  lda     glyph_row_lo,y
        sta     L5B04+1,x
        lda     glyph_row_hi,y
        sta     L5B04+2,x
        txa
        sbc     #$0D
        tax
        iny
        dec     $80
        bpl     L5A0C
        ldy     $9D
        ldx     #$4B
        sec
L5A26:  lda     glyph_row_lo,y
        sta     L5A97+1,x
        lda     glyph_row_hi,y
        sta     L5A97+2,x
        txa
        sbc     #$05
        tax
        iny
        dec     $81
        bpl     L5A26
        ldy     $94
        ldx     #$00
L5A3F:  bit     current_mapwidth
        bmi     L5A56
        lda     $84
        clc
        adc     current_mapwidth
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
        ora     current_mapbits+1
        sta     $21,x
L5A65:  cpy     $98
        beq     L5A6E
        iny
        inx
        inx
        bne     L5A3F
L5A6E:  ldx     #$0F
        lda     #$00
L5A72:  sta     $0000,x
        dex
        bpl     L5A72
        sta     $81
        sta     $40
        lda     #$80
        sta     $42
        ldy     $9F
L5A81:  lda     (text_addr),y
        tay
        bit     $81
        bpl     L5A8B
        sec
        adc     $FE
L5A8B:  tax
        lda     (glyph_widths),y
        beq     L5AE7
        ldy     $87
        bne     L5AEA
L5A95           := * + 1
        jmp     L5A97

L5A97:  lda     $FFFF,x
        sta     $0F
L5A9C:  lda     $FFFF,x
        sta     $0E
L5AA1:  lda     $FFFF,x
        sta     $0D
L5AA6:  lda     $FFFF,x
        sta     $0C
L5AAB:  lda     $FFFF,x
        sta     $0B
L5AB0:  lda     $FFFF,x
        sta     $0A
L5AB5:  lda     $FFFF,x
        sta     $09
L5ABA:  lda     $FFFF,x
        sta     $08
L5ABF:  lda     $FFFF,x
        sta     $07
L5AC4:  lda     $FFFF,x
        sta     $06
L5AC9:  lda     $FFFF,x
        sta     $05
L5ACE:  lda     $FFFF,x
        sta     $04
L5AD3:  lda     $FFFF,x
        sta     $03
L5AD8:  lda     $FFFF,x
        sta     $02
L5ADD:  lda     $FFFF,x
        sta     $01
L5AE2:  lda     $FFFF,x
        sta     $0000
L5AE7:  jmp     L5BD4

L5AEA:  tya
        asl     a
        tay
        copy16  shift_table_aux,y, $40
        copy16  shift_table_main,y, $42
L5B02           := * + 1
        jmp     L5B04

L5B04:  ldy     $FFFF,x         ; All of these $FFFFs are modified
        lda     ($42),y
        sta     $1F
        lda     ($40),y
        ora     $0F
        sta     $0F
L5B11:  ldy     $FFFF,x
        lda     ($42),y
        sta     $1E
        lda     ($40),y
        ora     $0E
        sta     $0E
L5B1E:  ldy     $FFFF,x
        lda     ($42),y
        sta     $1D
        lda     ($40),y
        ora     $0D
        sta     $0D
L5B2B:  ldy     $FFFF,x
        lda     ($42),y
        sta     $1C
        lda     ($40),y
        ora     $0C
        sta     $0C
L5B38:  ldy     $FFFF,x
        lda     ($42),y
        sta     $1B
        lda     ($40),y
        ora     $0B
        sta     $0B
L5B45:  ldy     $FFFF,x
        lda     ($42),y
        sta     $1A
        lda     ($40),y
        ora     $0A
        sta     $0A
L5B52:  ldy     $FFFF,x
        lda     ($42),y
        sta     $19
        lda     ($40),y
        ora     $09
        sta     $09
L5B5F:  ldy     $FFFF,x
        lda     ($42),y
        sta     $18
        lda     ($40),y
        ora     $08
        sta     $08
L5B6C:  ldy     $FFFF,x
        lda     ($42),y
        sta     $17
        lda     ($40),y
        ora     $07
        sta     $07
L5B79:  ldy     $FFFF,x
        lda     ($42),y
        sta     $16
        lda     ($40),y
        ora     $06
        sta     $06
L5B86:  ldy     $FFFF,x
        lda     ($42),y
        sta     $15
        lda     ($40),y
        ora     $05
        sta     $05
L5B93:  ldy     $FFFF,x
        lda     ($42),y
        sta     $14
        lda     ($40),y
        ora     $04
        sta     $04
L5BA0:  ldy     $FFFF,x
        lda     ($42),y
        sta     $13
        lda     ($40),y
        ora     $03
        sta     $03
L5BAD:  ldy     $FFFF,x
        lda     ($42),y
        sta     $12
        lda     ($40),y
        ora     $02
        sta     $02
L5BBA:  ldy     $FFFF,x
        lda     ($42),y
        sta     $11
        lda     ($40),y
        ora     $01
        sta     $01
L5BC7:  ldy     $FFFF,x
        lda     ($42),y
        sta     $10
        lda     ($40),y
        ora     $0000
        sta     $0000
L5BD4:  bit     $81
        bpl     L5BE2
        inc     $9F
        lda     #$00
        sta     $81
        lda     $9A
        bne     L5BF6
L5BE2:  txa
        tay
        lda     (glyph_widths),y
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
        cpy     text_len
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
        L5C22 := * + 1
        jmp     L5C24


;;; Per JB: "looks like the quickdraw fast-path draw unclipped pattern slab"

L5C24:  lda     $0F
        eor     current_textback
        sta     ($3E),y
L5C2A:  lda     $0E
        eor     current_textback
        sta     ($3C),y
L5C30:  lda     $0D
        eor     current_textback
        sta     ($3A),y
L5C36:  lda     $0C
        eor     current_textback
        sta     ($38),y
L5C3C:  lda     $0B
        eor     current_textback
        sta     ($36),y
L5C42:  lda     $0A
        eor     current_textback
        sta     ($34),y
L5C48:  lda     $09
        eor     current_textback
        sta     ($32),y
L5C4E:  lda     $08
        eor     current_textback
        sta     ($30),y
L5C54:  lda     $07
        eor     current_textback
        sta     ($2E),y
L5C5A:  lda     $06
        eor     current_textback
        sta     ($2C),y
L5C60:  lda     $05
        eor     current_textback
        sta     ($2A),y
L5C66:  lda     $04
        eor     current_textback
        sta     ($28),y
L5C6C:  lda     $03
        eor     current_textback
        sta     ($26),y
L5C72:  lda     $02
        eor     current_textback
        sta     ($24),y
L5C78:  lda     $01
        eor     current_textback
        sta     ($22),y
L5C7E:  lda     $00
        eor     current_textback
        sta     ($20),y
L5C84:  bit     current_mapwidth
        bpl     L5C94
        lda     $9C
        eor     #$01
        tax
        sta     $9C
        sta     LOWSCR,x
        beq     L5C96
L5C94:  inc     $A0
L5C96:  ldx     #$0F
L5C98:  lda     $10,x
        sta     $0000,x
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
        jmp     L5CC0

;;; Per JB: "looks like the quickdraw slow-path draw clipped pattern slab"

L5CC0:  lda     $0F
        eor     current_textback
        eor     ($3E),y
        and     $80
        eor     ($3E),y
        sta     ($3E),y
L5CCC:  lda     $0E
        eor     current_textback
        eor     ($3C),y
        and     $80
        eor     ($3C),y
        sta     ($3C),y
L5CD8:  lda     $0D
        eor     current_textback
        eor     ($3A),y
        and     $80
        eor     ($3A),y
        sta     ($3A),y
L5CE4:  lda     $0C
        eor     current_textback
        eor     ($38),y
        and     $80
        eor     ($38),y
        sta     ($38),y
L5CF0:  lda     $0B
        eor     current_textback
        eor     ($36),y
        and     $80
        eor     ($36),y
        sta     ($36),y
L5CFC:  lda     $0A
        eor     current_textback
        eor     ($34),y
        and     $80
        eor     ($34),y
        sta     ($34),y
L5D08:  lda     $09
        eor     current_textback
        eor     ($32),y
        and     $80
        eor     ($32),y
        sta     ($32),y
L5D14:  lda     $08
        eor     current_textback
        eor     ($30),y
        and     $80
        eor     ($30),y
        sta     ($30),y
L5D20:  lda     $07
        eor     current_textback
        eor     ($2E),y
        and     $80
        eor     ($2E),y
        sta     ($2E),y
L5D2C:  lda     $06
        eor     current_textback
        eor     ($2C),y
        and     $80
        eor     ($2C),y
        sta     ($2C),y
L5D38:  lda     $05
        eor     current_textback
        eor     ($2A),y
        and     $80
        eor     ($2A),y
        sta     ($2A),y
L5D44:  lda     $04
        eor     current_textback
        eor     ($28),y
        and     $80
        eor     ($28),y
        sta     ($28),y
L5D50:  lda     $03
        eor     current_textback
        eor     ($26),y
        and     $80
        eor     ($26),y
        sta     ($26),y
L5D5C:  lda     $02
        eor     current_textback
        eor     ($24),y
        and     $80
        eor     ($24),y
        sta     ($24),y
L5D68:  lda     $01
        eor     current_textback
        eor     ($22),y
        and     $80
        eor     ($22),y
        sta     ($22),y
L5D74:  lda     $00
        eor     current_textback
        eor     ($20),y
        and     $80
        eor     ($20),y
        sta     ($20),y
        rts

L5D81:  .addr   L5BC7,L5BBA,L5BAD,L5BA0,L5B93,L5B86,L5B79,L5B6C,L5B5F,L5B52,L5B45,L5B38,L5B2B,L5B1E,L5B11,L5B04
L5DA1:  .addr   L5AE2,L5ADD,L5AD8,L5AD3,L5ACE,L5AC9,L5AC4,L5ABF,L5ABA,L5AB5,L5AB0,L5AAB,L5AA6,L5AA1,L5A9C,L5A97
L5DC1:  .addr   L5C7E,L5C78,L5C72,L5C6C,L5C66,L5C60,L5C5A,L5C54,L5C4E,L5C48,L5C42,L5C3C,L5C36,L5C30,L5C2A,L5C24
L5DE1:  .addr   L5D74,L5D68,L5D5C,L5D50,L5D44,L5D38,L5D2C,L5D20,L5D14,L5D08,L5CFC,L5CF0,L5CE4,L5CD8,L5CCC,L5CC0
.endproc

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
        ldx     #MGTK::grafport_size-1
loop:   lda     standard_port,x
        sta     $8A,x
        sta     current_grafport,x
        dex
        bpl     loop

        ldax    saved_port_addr
        jsr     assign_and_prepare_port

        lda     #$7F
        sta     fill_eor_mask
        jsr     PaintRectImpl
        lda     #$00
        sta     fill_eor_mask
        rts

saved_port_addr:
        .addr   saved_port
.endproc

;;; ============================================================
;;; SetSwitches

;;; 1 byte param, copied to $82

;;; Toggle display softswitches
;;;   bit 0: LoRes if clear, HiRes if set
;;;   bit 1: Page 1 if clear, Page 2 if set
;;;   bit 2: Full screen if clear, split screen if set
;;;   bit 3: Graphics if clear, text if set

.proc SetSwitchesImpl
        param := $82

        lda     DHIRESON        ; enable dhr graphics
        sta     SET80VID

        ldx     #3
loop:   lsr     param           ; shift low bit into carry
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
.endproc

;;; ============================================================
;;; SetPort

.proc SetPortImpl
        ldax    params_addr
        ;; fall through
.endproc

        ;; Call with port address in (X,A)
assign_and_prepare_port:
        stax    active_port
        ;; fall through

        ;; Initializes font (if needed), port, pattern, and fill mode
prepare_port:
        lda     current_textfont+1
        beq     :+              ; only prepare font if necessary
        jsr     SetFontImpl::prepare_font
:       jsr     SetPortBitsImpl
        jsr     SetPatternImpl
        jmp     SetPenModeImpl

;;; ============================================================
;;; GetPort

.proc GetPortImpl
        jsr     apply_port_to_active_port
        ldax    active_port
        ;;  fall through
.endproc

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
        ldy     #MGTK::grafport_size-1 ; Store 36 bytes at params
loop:   lda     standard_port,y
        sta     (params_addr),y
        dey
        bpl     loop
.endproc
rts3:   rts

;;; ============================================================
;;; SetZP1

;;; 1 byte of params, copied to $82

.proc SetZP1Impl
        param := $82

        lda     param
        cmp     preserve_zp_flag
        beq     rts3
        sta     preserve_zp_flag
        bcc     rts3
        jmp     dispatch::cleanup
.endproc

;;; ============================================================
;;; SetZP2

;;; 1 byte of params, copied to $82

;;; If high bit set stash ZP $00-$43 to buffer if not already stashed.
;;; If high bit clear unstash ZP $00-$43 from buffer if not already unstashed.

.proc SetZP2Impl
        lda     $82
        cmp     low_zp_stash_flag
        beq     rts3
        sta     low_zp_stash_flag
        bcc     unstash

maybe_stash:
        bit     low_zp_stash_flag
        bpl     end

        ;; Copy buffer to ZP $00-$43
stash:
        ldx     #$43
:       lda     low_zp_stash_buffer,x
        sta     $00,x
        dex
        bpl     :-

end:    rts

maybe_unstash:
        bit     low_zp_stash_flag
        bpl     end

        ;; Copy ZP $00-$43 to buffer
unstash:
        ldx     #$43
:       lda     $00,x
        sta     low_zp_stash_buffer,x
        dex
        bpl     :-
        rts
.endproc
        maybe_stash_low_zp := SetZP2Impl::maybe_stash
        maybe_unstash_low_zp := SetZP2Impl::maybe_unstash

;;; ============================================================
;;; Version

.proc VersionImpl
        ldy     #5              ; Store 6 bytes at params
loop:   lda     version,y
        sta     (params_addr),y
        dey
        bpl     loop
        rts

.proc version
major:  .byte   1               ; 1.0.0
minor:  .byte   0
patch:  .byte   0
status: .byte   'F'             ; Final???
release:.byte   1               ; ???
        .byte   0               ; ???
.endproc
.endproc

;;; ============================================================

preserve_zp_flag:         ; if high bit set, ZP saved during MGTK calls
        .byte   $80

low_zp_stash_flag:
        .byte   $80

stack_ptr_stash:
        .byte   0

;;; ============================================================

;;; Standard GrafPort

.proc standard_port
viewloc:        .word   0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        .word   0, 0, screen_width-1, screen_height-1
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         .word   0, 0
penwidth:       .byte   1
penheight:      .byte   1
mode:           .byte   0
textback:       .byte   0
textfont:       .addr   0
.endproc

;;; ============================================================

.proc saved_port
viewloc:        .word   0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        .word   0, 0, screen_width-1, screen_height-1
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         .word   0, 0
penwidth:       .byte   1
penheight:      .byte   1
mode:           .byte   0
textback:       .byte   0
textfont:       .addr   0
.endproc

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

.proc set_pos_params
xcoord: .word   0
ycoord: .word   0
.endproc

mouse_state:
mouse_x:        .word   0
mouse_y:        .word   0
mouse_status:   .byte   0

mouse_scale_x:  .byte   $00
mouse_scale_y:  .byte   $00

mouse_hooked_flag:              ; High bit set if mouse is "hooked", and calls
        .byte   0               ; bypassed; never appears to be set.

mouse_hook:
        .addr   0

cursor_hotspot_x:  .byte   $00
cursor_hotspot_y:  .byte   $00

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
L602F:  .byte   $00,$00,$00,$00
L6033:  .byte   $00,$00,$02,$00
        .byte   $06,$00,$0E,$00,$1E,$00,$3E,$00
        .byte   $7E,$00,$1A,$00,$30,$00,$30,$00
        .byte   $60,$00,$00,$00,$03,$00,$07,$00
        .byte   $0F,$00,$1F,$00,$3F,$00,$7F,$00
        .byte   $7F,$01,$7F,$00,$78,$00,$78,$00
        .byte   $70,$01,$70,$01,$01,$01
L6065:  .addr   L6033
L6067:  lda     #$FF
        sta     cursor_count
        lda     #0
        sta     cursor_flag
        copy16  L6065, params_addr
        ;; fall through

;;; ============================================================
;;; SetCursor

        cursor_height := 12
        cursor_width  := 2
        cursor_mask_offset := cursor_width * cursor_height
        cursor_hotspot_offset := 2 * cursor_width * cursor_height

SetCursorImpl:
        php
        sei
        ldax    params_addr
        stax    active_cursor
        clc
        adc     #cursor_mask_offset
        bcc     :+
        inx
:       stax    active_cursor_mask
        ldy     #cursor_hotspot_offset
        lda     (params_addr),y
        sta     cursor_hotspot_x
        iny
        lda     (params_addr),y
        sta     cursor_hotspot_y
        jsr     restore_cursor_background
        jsr     draw_cursor
        plp
L60A7:  rts

update_cursor:
        lda     cursor_count           ; hidden? if so, skip
        bne     L60A7
        bit     cursor_flag
        bmi     L60A7

draw_cursor:
        lda     #$00
        sta     cursor_count
        sta     cursor_flag
        lda     set_pos_params::ycoord
        clc
        sbc     cursor_hotspot_y
        sta     $84
        clc
        adc     #$0C
        sta     $85
        lda     set_pos_params::xcoord
        sec
        sbc     cursor_hotspot_x
        tax
        lda     set_pos_params::xcoord+1
        sbc     #$00
        bpl     L60E1
        txa
        ror     a
        tax
        ldy     mod7_table+124,x ; ???
        lda     #$FF
        bmi     L60E4
L60E1:  jsr     divmod7
L60E4:  sta     $82
        tya
        rol     a
        cmp     #$07
        bcc     L60EE
        sbc     #$07
L60EE:  tay
        lda     #$2A
        rol     a
        eor     #$01
        sta     $83
        sty     L6004
        tya
        asl     a
        tay
        copy16  shift_table_main,y, L6164
        copy16  shift_table_aux,y, L616A
        ldx     #$03
L6116:  lda     $82,x
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
        sta     $88
        lda     hires_table_hi,y
        ora     #$20
        sta     $89
        sty     $85
        stx     $87
        ldy     $86
        ldx     #$01
L6141:
active_cursor           := * + 1
        lda     $FFFF,y
        sta     L6005,x
active_cursor_mask      := * + 1
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
        ora     $FF80,x
        sta     L6005,y
L616A           := * + 1
        lda     $FF00,x
        dey
        bne     L6160
        sta     L6005
L6172:  ldx     $87
        ldy     $82
        lda     $83
        jsr     L622A
        bcs     L618D
        lda     ($88),y
        sta     L600B,x
        lda     L6008
        ora     ($88),y
        eor     L6005
        sta     ($88),y
        dex
L618D:  jsr     L6220
        bcs     L61A2
        lda     ($88),y
        sta     L600B,x
        lda     L6009
        ora     ($88),y
        eor     L6006
        sta     ($88),y
        dex
L61A2:  jsr     L6220
        bcs     L61B7
        lda     ($88),y
        sta     L600B,x
        lda     L600A
        ora     ($88),y
        eor     L6007
        sta     ($88),y
        dex
L61B7:  ldy     $85
L61B9:  dec     $86
        dec     $86
        dey
        cpy     $84
        beq     L621C
        jmp     L6126

L61C5:  rts

restore_cursor_background:
        lda     cursor_count           ; already hidden?
        bne     L61C5
        bit     cursor_flag
        bmi     L61C5

        ldx     #$03
L61D2:  lda     L602F,x
        sta     $82,x
        dex
        bpl     L61D2
        ldx     #$23
        ldy     $85
L61DE:  cpy     #$C0
        bcs     L6217
        lda     hires_table_lo,y
        sta     $88
        lda     hires_table_hi,y
        ora     #$20
        sta     $89
        sty     $85
        ldy     $82
        lda     $83
        jsr     L622A
        bcs     L61FF
        lda     L600B,x
        sta     ($88),y
        dex
L61FF:  jsr     L6220
        bcs     L620A
        lda     L600B,x
        sta     ($88),y
        dex
L620A:  jsr     L6220
        bcs     L6215
        lda     L600B,x
        sta     ($88),y
        dex
L6215:  ldy     $85
L6217:  dey
        cpy     $84
        bne     L61DE
L621C:  sta     LOWSCR
        rts

L6220:  lda     L622E
        eor     #$01
        cmp     #$54
        beq     L622A
        iny
L622A:  sta     L622E

        L622E := *+1
        sta     $C0FF
        cpy     #$28
        rts

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
        jsr     draw_cursor
done:   plp
        rts
.endproc

;;; ============================================================
;;; ObscureCursor

.proc ObscureCursorImpl
        php
        sei
        jsr     restore_cursor_background
        lda     #$80
        sta     cursor_flag
        plp
        rts
.endproc

;;; ============================================================
;;; HideCursor

HideCursorImpl:
        php
        sei
        jsr     restore_cursor_background
        dec     cursor_count
        plp
L6263:  rts

;;; ============================================================

L6264:  .byte   0
L6265:  bit     L6339
        bpl     L627C
        lda     kbd_mouse_state
        bne     L627C
        dec     L6264
        lda     L6264
        bpl     L6263
        lda     #$02
        sta     L6264
L627C:  ldx     #2
L627E:  lda     mouse_x,x
        cmp     set_pos_params,x
        bne     L628B
        dex
        bpl     L627E
        bmi     L629F
L628B:  jsr     restore_cursor_background
        ldx     #2
        stx     cursor_flag
L6293:  lda     mouse_x,x
        sta     set_pos_params,x
        dex
        bpl     L6293
        jsr     update_cursor
L629F:  bit     no_mouse_flag
        bmi     L62A7
        jsr     read_mouse_pos
L62A7:  bit     no_mouse_flag
        bpl     L62B1
        lda     #$00
        sta     mouse_status
L62B1:  lda     kbd_mouse_state
        beq     rts4
        jsr     L7EF5
rts4:   rts

;;; ============================================================

.proc read_mouse_pos
        ldy     #READMOUSE
        jsr     call_mouse
        bit     mouse_hooked_flag
        bmi     do_scale_x

        ldx     mouse_firmware_hi
        lda     MOUSE_X_LO,x
        sta     mouse_x
        lda     MOUSE_X_HI,x
        sta     mouse_x+1
        lda     MOUSE_Y_LO,x
        sta     mouse_y

        ;; Scale X
do_scale_x:
        ldy     mouse_scale_x
        beq     do_scale_y
:       lda     mouse_x
        asl     a
        sta     mouse_x
        lda     mouse_x+1
        rol     a
        sta     mouse_x+1
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
        lda     MOUSE_STATUS,x
        sta     mouse_status
done:   rts
.endproc

;;; ============================================================
;;; GetCursorAddr

.proc GetCursorAddrImpl
        ldax    active_cursor
        jmp     store_xa_at_params
.endproc

;;; ============================================================

        ;; Call mouse firmware, operation in Y, param in A
.proc call_mouse
        bit     no_mouse_flag
        bmi     rts4

        bit     mouse_hooked_flag
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
        jmp     ($88)

hooked: jmp     (mouse_hook)
.endproc

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

desktop_initialized_flag:
        .byte   0

L6340:  .byte   $00

;;; ============================================================
;;; StartDeskTop

;;; 12 bytes of params, copied to $82

StartDeskTopImpl:
        php
        pla
        sta     L6340
        ldx     #$04
L6348:  lda     $82,x
        sta     L6335,x
        dex
        bpl     L6348
        lda     #$7F
        sta     standard_port::textback
        copy16  $87, standard_port::textfont
        copy16  $89, L6835
        copy16  $8B, L633B
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
        stx     test_rect_bottom
        stx     test_rect_params2_top
        stx     fill_rect_params4_top
        inx
        stx     set_port_top
        stx     L78CF
        stx     L6594
        stx     fill_rect_top
        dex
        stx     menu_item_y_table
        clc
        ldy     #$00
L63AC:  txa
        adc     menu_item_y_table,y
        iny
        sta     menu_item_y_table,y
        cpy     #$0E
        bcc     L63AC
        lda     #1
        sta     mouse_scale_x
        lda     #0
        sta     mouse_scale_y
        bit     L6336
        bvs     L63D1
        lda     #2
        sta     mouse_scale_x
        lda     #1
        sta     mouse_scale_y
L63D1:  ldx     L6338
        jsr     find_mouse
        bit     L6338
        bpl     L63F6
        cpx     #$00
        bne     L63E5
        exit_call MGTK::error_no_mouse

L63E5:  lda     L6338
        and     #$7F
        beq     L63F6
        cpx     L6338
        beq     L63F6
        exit_call $91

L63F6:  stx     L6338
        lda     #$80
        sta     desktop_initialized_flag
        lda     L6338
        bne     L640D
        bit     L6339
        bpl     L640D
        lda     #$00
        sta     L6339
L640D:  ldy     #$03
        lda     L6338
        sta     (params_addr),y
        iny
        lda     L6339
        sta     (params_addr),y
        bit     L6339
        bpl     L642A
        bit     L6337
        bpl     L642A
        MLI_CALL ALLOC_INTERRUPT, alloc_interrupt_params
L642A:  lda     $FBB3
        pha
        lda     #$06
        sta     $FBB3
        ldy     #SETMOUSE
        lda     #$01
        bit     L6339
        bpl     L643F
        cli
        ora     #$08
L643F:  jsr     call_mouse
        pla
        sta     $FBB3
        jsr     InitGrafImpl
        jsr     L6067
        jsr     FlushEventsImpl
        lda     #$00
        sta     L700C
L6454:  jsr     L653F
        jsr     L6588
        ;; Fills the desktop background on startup (menu left black)
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::PaintRect, fill_rect_params
        jmp     L6556

        DEFINE_ALLOC_INTERRUPT_PARAMS alloc_interrupt_params, interrupt_handler
        DEFINE_DEALLOC_INTERRUPT_PARAMS dealloc_interrupt_params

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

L648C:  exit_call $93

L6491:
        lda     L6337
        beq     L649F
        cmp     #$01
        beq     L64A4
        exit_call $90

L649F:  lda     #$80
        sta     L6337
L64A4:  rts

;;; ============================================================
;;; StopDeskTop

.proc StopDeskTopImpl
        ldy     #SETMOUSE
        lda     #MOUSE_MODE_OFF
        jsr     call_mouse
        ldy     #SERVEMOUSE
        jsr     call_mouse
        bit     L6339
        bpl     :+
        bit     L6337
        bpl     :+
        lda     alloc_interrupt_params::int_num
        sta     dealloc_interrupt_params::int_num
        MLI_CALL DEALLOC_INTERRUPT, dealloc_interrupt_params
:       lda     L6340
        pha
        plp
        lda     #$00
        sta     desktop_initialized_flag
        rts
.endproc

;;; ============================================================
;;; SetUserHook

;;; 3 bytes of params, copied to $82

SetUserHookImpl:
        lda     $82
        cmp     #$01
        bne     L64E5
        lda     $84
        bne     L64F6
        sta     L6522
        lda     $83
        sta     L6521
        rts

L64E5:  cmp     #$02
        bne     L6508
        lda     $84
        bne     L64FF
        sta     L6538
        lda     $83
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

L6508:  exit_call MGTK::error_invalid_hook

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
L6539:  .word   0
L653B:  .byte   $00

L653C:  jsr     HideCursorImpl
L653F:  copy16  params_addr, L6539
        lda     stack_ptr_stash
        sta     L653B
        lsr     preserve_zp_flag
        rts

L6553:  jsr     ShowCursorImpl
L6556:  asl     preserve_zp_flag
        copy16  L6539, params_addr
        ldax    active_port
L6567:  stax    $82
        lda     L653B
        sta     stack_ptr_stash
        ldy     #MGTK::grafport_size-1
L6573:  lda     ($82),y
        sta     current_grafport,y
        dey
        bpl     L6573
        jmp     prepare_port

L657E:  ldax    L6586
        bne     L6567
L6586:  .addr   standard_port

L6588:  jsr     L657E
        MGTK_CALL MGTK::SetPortBits, L6592
        rts

L6592:  .byte   $00,$00
L6594:  .byte   $0D,$00,$00,$20,$80,$00

.proc fill_rect_params
left:   .word   0
top:    .word   0
right:  .word   screen_width-1
bottom: .word   screen_height-1
.endproc
        fill_rect_top := fill_rect_params::top

        .byte   $00,$00,$00,$00,$00,$00,$00,$00

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

;;; ============================================================
;;; AttachDriver

;;; 2 bytes of params, copied to $82

.proc AttachDriverImpl
        params := $82

        bit     desktop_initialized_flag
        bmi     fail

        copy16  params, mouse_hook

        ldax    mouse_state_addr
        ldy     #2
        jmp     store_xa_at_y

fail:   exit_call MGTK::error_desktop_not_initialized

mouse_state_addr:
        .addr   mouse_state
.endproc

;;; ============================================================
;;; PeekEvent

PeekEventImpl:
        clc
        bcc     L65D8

;;; ============================================================
;;; GetEvent

GetEventImpl:
        sec
L65D8:  php
        bit     L6339
        bpl     L65E1
        sei
        bmi     L65E4
L65E1:  jsr     CheckEventsImpl
L65E4:  jsr     L67FE
        bcs     L6604
        plp
        php
        bcc     L65F0
        sta     L6752
L65F0:  tax
        ldy     #0              ; Store 5 bytes at params
L65F3:  lda     L6754,x
        sta     (params_addr),y
        inx
        iny
        cpy     #4
        bne     L65F3
        lda     #$00
        sta     (params_addr),y
        beq     L6607
L6604:  jsr     L6645
L6607:  plp
        bit     L6339
        bpl     L660E
        cli
L660E:  rts

;;; ============================================================

;;; 5 bytes of params, copied to $82

PostEventImpl:
        php
        sei
        lda     $82
        bmi     L6626
        cmp     #$06
        bcs     L663B
        cmp     #$03
        beq     L6626
        ldx     $83
        ldy     $84
        lda     $85
        jsr     set_mouse_pos
L6626:  jsr     L67E4
        bcs     L663F
        tax
        ldy     #$00
L662E:  lda     (params_addr),y
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
        jmp     exit_with_a

L6645:  lda     #0
        bit     mouse_status
        bpl     L664E
        lda     #4
L664E:  ldy     #0
        sta     (params_addr),y         ; Store 5 bytes at params
        iny
L6653:  lda     cursor_count,y
        sta     (params_addr),y
        iny
        cpy     #$05
        bne     L6653
        rts

;;; ============================================================
;;; CheckEvents


.proc input
state:  .byte   0

key        := *
kmods      := * + 1

xpos       := *
ypos       := * + 2
modifiers  := * + 3

        .res    4, 0
.endproc

.proc CheckEventsImpl
        bit     L6339
        bpl     L666D
        exit_call MGTK::error_irq_in_use

L666D:
        sec                     ; called from interrupt handler
        jsr     L650D
        bcc     end

        lda     BUTN1           ; Look at buttons (apple keys), compute modifiers
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        sta     input::modifiers

        jsr     L7F66
        jsr     L6265
        lda     mouse_status    ; bit 7 = is down, bit 6 = was down, still down
        asl     a
        eor     mouse_status
        bmi     L66B9           ; minus = (is down & !was down)

        bit     mouse_status
        bmi     end             ; minus = is down
        bit     check_kbd_flag
        bpl     L66B9
        lda     kbd_mouse_state
        bne     L66B9

        lda     KBD
        bpl     end             ; no key
        and     #$7F
        sta     input::key
        bit     KBDSTRB         ; clear strobe

        lda     input::modifiers
        sta     input::kmods
        lda     #MGTK::event_kind_key_down
        sta     input::state
        bne     L66D8

L66B9:  bcc     up
        lda     input::modifiers
        beq     :+
        lda     #MGTK::event_kind_apple_key
        bne     set_state

:       lda     #MGTK::event_kind_button_down
        bne     set_state

up:     lda     #MGTK::event_kind_button_up

set_state:
        sta     input::state

        ldx     #2
:       lda     set_pos_params,x
        sta     input::key,x
        dex
        bpl     :-

L66D8:  jsr     L67E4
        tax
        ldy     #$00
L66DE:  lda     input,y
        sta     L6754,x
        inx
        iny
        cpy     #$04
        bne     L66DE

end:    jmp     L6523
.endproc

;;; ============================================================
;;; Interrupt Handler

int_stash_zp:
        .res    9, 0
int_stash_rdpage2:
        .byte   0
int_stash_rd80store:
        .byte   0

.proc interrupt_handler
        cld                     ; required for interrupt handlers

body:                           ; returned by GetIntHandler

        lda     RDPAGE2         ; record softswitch state
        sta     int_stash_rdpage2
        lda     RD80STORE
        sta     int_stash_rd80store
        lda     LOWSCR
        sta     SET80COL

        ldx     #8              ; preserve 9 bytes of ZP
sloop:  lda     $82,x
        sta     int_stash_zp,x
        dex
        bpl     sloop

        ldy     #SERVEMOUSE
        jsr     call_mouse
        bcs     :+
        jsr     CheckEventsImpl::L666D
        clc
:       bit     L633A
        bpl     :+
        clc                     ; carry clear if interrupt handled

:       ldx     #8              ; restore ZP
rloop:  lda     int_stash_zp,x
        sta     $82,x
        dex
        bpl     rloop

        lda     LOWSCR          ;  restore soft switches
        sta     CLR80COL
        lda     int_stash_rdpage2
        bpl     :+
        lda     HISCR
:       lda     int_stash_rd80store
        bpl     :+
        sta     SET80COL

:       rts
.endproc

;;; ============================================================
;;; GetIntHandler

.proc GetIntHandlerImpl
        ldax    L6750
        jmp     store_xa_at_params

L6750:  .addr   interrupt_handler::body
.endproc

;;; ============================================================
;;; FlushEvents

;;; This is called during init by the DAs, just before
;;; entering the input loop.

L6752:  .byte   0
L6753:  .byte   0

L6754:  .byte   $00
L6755:  .res    128, 0
        .byte   $00,$00,$00

.proc FlushEventsImpl
        php
        sei
        lda     #0
        sta     L6752
        sta     L6753
        plp
        rts
.endproc
        ;; called during PostEvent and a few other places
.proc L67E4
        lda     L6753
        cmp     #$80            ; if L6753 is not $80, add $4
        bne     :+
        lda     #$00            ; otherwise reset to 0
        bcs     compare
:       clc
        adc     #$04

compare:
        cmp     L6752           ; did L6753 catch up with L6752?
        beq     rts_with_carry_set
        sta     L6753           ; nope, maybe next time
        clc
        rts
.endproc

rts_with_carry_set:
        sec
        rts

        ;; called during GetEvent
L67FE:  lda     L6752           ; equal?
        cmp     L6753
        beq     rts_with_carry_set
        cmp     #$80
        bne     L680E
        lda     #0
        bcs     L6811
L680E:  clc
        adc     #$04
L6811:  clc
        rts

;;; ============================================================
;;; SetKeyEvent

;;; 1 byte of params, copied to $82

check_kbd_flag:  .byte   $80

.proc SetKeyEventImpl
        params := $82

        asl     check_kbd_flag
        ror     params
        ror     check_kbd_flag
        rts
.endproc

;;; ============================================================


L681D:  .byte   $02
L681E:  .byte   $09
L681F:  .byte   $10
L6820:  .byte   $09
L6821:  .byte   $1E
L6822:  .byte   $00

active_menu:
        .addr   0


.proc test_rect_params
left:   .word   $ffff
top:    .word   $ffff
right:  .word   $230
bottom: .word   $C
.endproc
        test_rect_top := test_rect_params::top
        test_rect_bottom := test_rect_params::bottom

.proc fill_rect_params2
left:   .word   0
top:    .word   0
width:  .word   0
height: .word   11
.endproc
        fill_rect_params2_height := fill_rect_params2::height

L6835:  .word   0

.proc test_rect_params2
left:   .word   0
top:    .word   12
right:  .word   0
bottom: .word   0
.endproc
        test_rect_params2_top := test_rect_params2::top

.proc fill_rect_params4
left:   .word   0
top:    .word   12
right:  .word   0
bottom: .word   0
.endproc
        fill_rect_params4_top := fill_rect_params4::top

menu_item_y_table:
        .repeat 15, i
        .byte   12 + 12 * i
        .endrepeat

L6856:  .byte   $1E
L6857:  .byte   $1F
L6858:  .byte   $1D
L6859:  .byte   $01,$02
L685B:  .byte   $1E
L685C:  .byte   $FF,$01
L685E:  .byte   $1D
L685F:  .addr   $6825
L6861:  .addr   $6837
L6863:  .addr   $685D
L6865:  .addr   $685A

get_menu_count:
        copy16  active_menu, $82
        ldy     #0
        lda     ($82),y
        sta     $A8
        rts

L6878:  stx     $A7
        lda     #$02
        clc
L687D:  dex
        bmi     L6884
        adc     #$0C
        bne     L687D
L6884:  adc     active_menu
        sta     $AB
        lda     active_menu+1
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

L68BE:  stx     scan_y
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

L68EA:  sty     current_penloc_y
        ldy     #0
        sty     current_penloc_y+1
L68F0:  stax    current_penloc_x
        rts

        ;; Set fill mode to A
set_fill_mode:
        sta     current_penmode
        jmp     SetPenModeImpl

do_measure_text:
        jsr     prepare_text_params
        jmp     measure_text

draw_text:
        jsr     prepare_text_params
        jmp     DrawTextImpl

        ;; Prepare $A1,$A2 as params for TextWidth/DrawText call
        ;; ($A3 is length)
prepare_text_params:
        stax    $82
        clc
        adc     #1
        bcc     L6910
        inx
L6910:  stax    $A1
        ldy     #0
        lda     ($82),y
        sta     $A3
        rts

L691B:  MGTK_CALL MGTK::GetEvent, $82
        return  $82

;;; ============================================================
;;; SetMenu

L6924:  .byte   0
L6925:  .byte   0

SetMenuImpl:
        lda     #$00
        sta     L633D
        sta     L633E
        copy16  params_addr, active_menu

        jsr     get_menu_count  ; into $A8
        jsr     L653C
        jsr     L657E
        ldax    L685F
        jsr     fill_and_frame_rect

        ldax    #$0C
        ldy     L6822
        iny
        jsr     L68EA
        ldx     #$00
L6957:  jsr     L6878
        ldax    current_penloc_x
        stax    $B5
        sec
        sbc     #$08
        bcs     L6968
        dex
L6968:  stax    $B7
        stax    $BB
        ldx     #$00
        stx     $C5
        stx     $C6
L6976:  jsr     L68BE
        bit     $BF
        bvs     L69B4
        ldax    $C3
        jsr     do_measure_text
        stax    $82
        lda     $BF
        and     #$03
        bne     L6997
        lda     $C1
        bne     L6997
        lda     L6820
        bne     L699A
L6997:  lda     L6821
L699A:  clc
        adc     $82
        sta     $82
        bcc     L69A3
        inc     $83
L69A3:  sec
        sbc     $C5
        lda     $83
        sbc     $C6
        bmi     L69B4
        copy16  $82, $C5
L69B4:  ldx     scan_y
        inx
        cpx     $AA
        bne     L6976
        lda     $AA
        tax
        ldy     L6822
        iny
        iny
        iny
        jsr     ndbm_calc_off
        pha

        copy16  $C5, fixed_div::dividend
        copy16  #7, fixed_div::divisor
        jsr     fixed_div

        ldy     $A1
        iny
        iny
        pla
        tax
        jsr     ndbm_calc_off
        sta     L6924
        sty     L6925
        sec
        sbc     L633D
        tya
        sbc     L633E
        bmi     L6A00
        copy16  L6924, L633D
L6A00:  add16_8 $BB, $C5, $BD
        jsr     L68A9
        ldax    $B1
        jsr     draw_text
        jsr     L6A5C
        ldax    current_penloc_x
        clc
        adc     #$08
        bcc     L6A24
        inx
L6A24:  stax    $B9
        jsr     L68A9
        ldax    #12
        jsr     adjust_xpos
        ldx     $A7
        inx
        cpx     $A8
        beq     L6A3C
        jmp     L6957

L6A3C:  lda     #0
        sta     menu_index
        sta     menu_item_index
        jsr     L6553
        sec
        lda     L633B
        sbc     L633D
        lda     L633C
        sbc     L633E
        bpl     L6A5B
        exit_call $9C

L6A5B:  rts

L6A5C:  ldx     $A7
        jsr     L6878
        ldx     $A9
        jmp     L68BE

        ;; Fills rect (params at X,A) then inverts border
.proc fill_and_frame_rect
        stax    fill_params
        stax    draw_params
        lda     #0
        jsr     set_fill_mode
        MGTK_CALL MGTK::PaintRect, 0, fill_params
        lda     #4
        jsr     set_fill_mode
        MGTK_CALL MGTK::FrameRect, 0, draw_params
        rts
.endproc

L6A89:  jsr     L6A94
        bne     L6A93
        exit_call $9A

L6A93:  rts

L6A94:  lda     #$00
L6A96:  sta     $C6
        jsr     get_menu_count
        ldx     #$00
L6A9D:  jsr     L6878
        bit     $C6
        bvs     L6ACA
        bmi     L6AAE
        lda     $AF
        cmp     $C7
        bne     L6ACF
        beq     L6AD9
L6AAE:  ldax    set_pos_params::xcoord
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
        return  #$00

L6AD9:  return  $AF

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
L6AF0:  lda     menu_item_y_table,x
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
L6B16:  cpx     $AA
        bne     L6ADE
        ldx     #$00
L6B1C:  rts

;;; ============================================================
;;; HiliteMenu

;;; 2 bytes of params, copied to $C7

HiliteMenuImpl:
        lda     $C7
        bne     L6B26
        lda     L6BD9
        sta     $C7
L6B26:  jsr     L6A89
L6B29:  jsr     L653C
        jsr     L657E
        jsr     L6B35
        jmp     L6553

        ;; Highlight/Unhighlight top level menu item
.proc L6B35
        ldx     #$01
loop:   lda     $B7,x
        sta     fill_rect_params2::left,x
        lda     $B9,x
        sta     fill_rect_params2::width,x
        lda     $BB,x
        sta     test_rect_params2::left,x
        sta     fill_rect_params4::left,x
        lda     $BD,x
        sta     test_rect_params2::right,x
        sta     fill_rect_params4::right,x
        dex
        bpl     loop
        lda     #$02
        jsr     set_fill_mode
        MGTK_CALL MGTK::PaintRect, fill_rect_params2
        rts
.endproc

;;; ============================================================
;;; MenuKey

;;; 4 bytes of params, copied to $C7

MenuKeyImpl:
        lda     $C9
        cmp     #$1B            ; Menu height?
        bne     L6B70
        lda     $CA
        bne     L6B70
        jsr     KeyboardMouse
        jmp     MenuSelectImpl

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
        sta     (params_addr),y
        iny
        txa
        sta     (params_addr),y
        bne     L6B29
        rts

L6B96:  jsr     L6A89
        jsr     L6ADC
        cpx     #$00
L6B9E:  rts

L6B9F:  jsr     L6B96
        bne     L6B9E
        exit_call $9B

;;; ============================================================
;;; DisableItem

;;; 3 bytes of params, copied to $C7

DisableItemImpl:
        jsr     L6B9F
        asl     $BF
        ror     $C9
        ror     $BF
        jmp     L68DF

;;; ============================================================
;;; CheckItem

;;; 3 bytes of params, copied to $C7

CheckItemImpl:
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

;;; ============================================================
;;; DisableMenu

;;; 2 bytes of params, copied to $C7

DisableMenuImpl:
        jsr     L6A89
        asl     $B0
        ror     $C8
        ror     $B0
        ldx     $A7
        jmp     L68A9

;;; ============================================================
;;; MenuSelect

L6BD9:  .byte   0
L6BDA:  .byte   0

MenuSelectImpl:
        jsr     L7ECD
        jsr     get_menu_count
        jsr     L653F
        jsr     L657E
        bit     kbd_mouse_state
        bpl     L6BF2
        jsr     L7FE1
        jmp     L6C23

L6BF2:  lda     #0
        sta     L6BD9
        sta     L6BDA
        jsr     L691B
L6BFD:  bit     L7D81
        bpl     L6C05
        jmp     L8149

L6C05:  MGTK_CALL MGTK::MoveTo, $83
        MGTK_CALL MGTK::InRect, test_rect_params
        bne     L6C58
        lda     L6BD9
        beq     L6C23
        MGTK_CALL MGTK::InRect, test_rect_params2
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

L6C37:  jsr     HideCursorImpl
        jsr     L657E
        jsr     L6CF4
L6C40:  jsr     L6556
        lda     #$00
        ldx     L6BDA
        beq     L6C55
        lda     L6BD9
        ldy     $A7             ; ???
        sty     menu_index
        stx     menu_item_index
L6C55:  jmp     store_xa_at_params

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
        lda     div7_table,x
        sta     $82
        lda     $BE
        lsr     a
        lda     $BD
        ror     a
        tax
        lda     div7_table,x
        sec
        sbc     $82
        sta     $90
        copy16  L6835, $8E
        ldy     $AA
        ldx     menu_item_y_table,y ; ???
        inx
        stx     $83
        stx     fill_rect_params4::bottom
        stx     test_rect_params2::bottom
        ldx     L6822
        inx
        inx
        inx
        stx     fill_rect_params4::top
        stx     test_rect_params2::top
        rts

L6CD8:  lda     hires_table_lo,x
        clc
        adc     $82
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
        sta     HISCR
        ldy     $90
L6CFF:  lda     ($8E),y
        sta     ($84),y
        dey
        bpl     L6CFF
        jsr     L6CE8
        sta     LOWSCR
        ldy     $90
L6D0E:  lda     ($8E),y
        sta     ($84),y
        dey
        bpl     L6D0E
        jsr     L6CE8
        inx
        cpx     $83
        bcc     L6CF7
        beq     L6CF7
        jmp     ShowCursorImpl

L6D22:  rts

L6D23:  clc
        bcc     L6D27
L6D26:  sec
L6D27:  lda     L6BD9
        beq     L6D22
        php
        sta     $C7
        jsr     L6A94
        jsr     HideCursorImpl
        jsr     L6B35
        plp
        bcc     L6CF4
        jsr     L6C98
L6D3E:  jsr     L6CD8
        sta     HISCR
        ldy     $90
L6D46:  lda     ($84),y
        sta     ($8E),y
        dey
        bpl     L6D46
        jsr     L6CE8
        sta     LOWSCR
        ldy     $90
L6D55:  lda     ($84),y
        sta     ($8E),y
        dey
        bpl     L6D55
        jsr     L6CE8
        inx
        cpx     $83
        bcc     L6D3E
        beq     L6D3E
        jsr     L657E
        ldax    L6861
        jsr     fill_and_frame_rect
        inc16   fill_rect_params4::left
        lda     fill_rect_params4::right
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
L6DB1:  ldax    L6863
        jsr     draw_text
        jsr     L6A5C
L6DBD:  lda     L681E
        jsr     L6E25
        ldax    $C3
        jsr     draw_text
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
        ldax    L6865
        jsr     draw_text
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

L6E22:  jmp     ShowCursorImpl

L6E25:  ldx     $A9
        ldy     menu_item_y_table+1,x ; ???
        dey
        ldx     $BC
        clc
        adc     $BB
        bcc     L6E33
        inx
L6E33:  jmp     L68EA

L6E36:  ldx     $A9
        lda     menu_item_y_table,x
        sta     fill_rect_params3_top
        inc     fill_rect_params3_top
        lda     menu_item_y_table+1,x
        sta     fill_rect_params3_bottom
        add16lc $BB, #5, fill_rect_params3_left
        sub16lc $BD, #5, fill_rect_params3_right
        MGTK_CALL MGTK::SetPattern, light_speckle_pattern
        lda     #$01
        jsr     set_fill_mode
        MGTK_CALL MGTK::PaintRect, fill_rect_params3
        MGTK_CALL MGTK::SetPattern, standard_port::penpattern
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

.proc fill_rect_params3
left:   .word   0
top:    .word   0
right:  .word   0
bottom: .word   0
.endproc
        fill_rect_params3_left := fill_rect_params3::left
        fill_rect_params3_top := fill_rect_params3::top
        fill_rect_params3_right := fill_rect_params3::right
        fill_rect_params3_bottom := fill_rect_params3::bottom

L6E92:  sta     $82
        ldax    $BD
        sec
        sbc     $82
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
        ldy     menu_item_y_table,x
        sty     fill_rect_params4::bottom
        jsr     HideCursorImpl
        lda     #$02
        jsr     set_fill_mode
        MGTK_CALL MGTK::PaintRect, fill_rect_params4
        jmp     ShowCursorImpl

;;; ============================================================
;;; InitMenu

;;; 4 bytes of params, copied to $82

.proc InitMenuImpl
        params := $82

        ldx     #3
loop:   lda     params,x
        sta     L6856,x
        dex
        bpl     loop

        copy16  standard_port::textfont, params
        ldy     #0
        lda     ($82),y
        bmi     :+

        copy16  #$0902, L681D
        copy16  #$0910, L681F
        lda     #$1E
        sta     L6821
        bne     end

:       copy16  #$1002, L681D
        copy16  #$101E, L681F
        lda     #$33
        sta     L6821
end:    rts
.endproc

;;; ============================================================
;;; SetMark

;;; 4 bytes of params, copied to $C7

SetMarkImpl:
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

.proc up_scroll_params
        .byte   $00,$00
incr:   .byte   $00,$00
        .byte   $13,$0A
        .addr   up_scroll_bitmap
.endproc

.proc down_scroll_params
        .byte   $00,$00
unk1:   .byte   $00
unk2:   .byte   $00
        .byte   $13,$0A
        .addr   down_scroll_bitmap
.endproc

.proc left_scroll_params
        .byte   $00,$00,$00,$00
        .byte   $14,$09
        .addr   left_scroll_bitmap
.endproc

.proc right_scroll_params
        .byte   $00
        .byte   $00,$00,$00
        .byte   $12,$09
        .addr   right_scroll_bitmap
.endproc

.proc resize_box_params
        .byte   $00,$00,$00,$00
        .byte   $14,$0A
        .addr   resize_box_bitmap
.endproc

        ;;  Up Scroll
up_scroll_bitmap:
        .byte   px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001100),px(%0000000)
        .byte   px(%0000000),px(%0110011),px(%0000000)
        .byte   px(%0000001),px(%1000000),px(%1100000)
        .byte   px(%0000110),px(%0000000),px(%0011000)
        .byte   px(%0011111),px(%1000000),px(%1111110)
        .byte   px(%0000001),px(%1000000),px(%1100000)
        .byte   px(%0000001),px(%1000000),px(%1100000)
        .byte   px(%0000001),px(%1111111),px(%1100000)
        .byte   px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0111111),px(%1111111),px(%1111111)

        ;; Down Scroll
down_scroll_bitmap:
        .byte   px(%0111111),px(%1111111),px(%1111111)
        .byte   px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000001),px(%1111111),px(%1100000)
        .byte   px(%0000001),px(%1000000),px(%1100000)
        .byte   px(%0000001),px(%1000000),px(%1100000)
        .byte   px(%0011111),px(%1000000),px(%1111110)
        .byte   px(%0000110),px(%0000000),px(%0011000)
        .byte   px(%0000001),px(%1000000),px(%1100000)
        .byte   px(%0000000),px(%0110011),px(%0000000)
        .byte   px(%0000000),px(%0001100),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000)

        ;;  Left Scroll
left_scroll_bitmap:
        .byte   px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0001100),px(%0000001)
        .byte   px(%0000000),px(%0111100),px(%0000001)
        .byte   px(%0000001),px(%1001111),px(%1111001)
        .byte   px(%0000110),px(%0000000),px(%0011001)
        .byte   px(%0011000),px(%0000000),px(%0011001)
        .byte   px(%0000110),px(%0000000),px(%0011001)
        .byte   px(%0000001),px(%1001111),px(%1111001)
        .byte   px(%0000000),px(%0111100),px(%0000001)
        .byte   px(%0000000),px(%0001100),px(%0000001)

        ;; Right Scroll
right_scroll_bitmap:
        .byte   px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%1000000),px(%0011000),px(%0000000)
        .byte   px(%1000000),px(%0011110),px(%0000000)
        .byte   px(%1001111),px(%1111001),px(%1000000)
        .byte   px(%1001100),px(%0000000),px(%0110000)
        .byte   px(%1001100),px(%0000000),px(%0001100)
        .byte   px(%1001100),px(%0000000),px(%0110000)
        .byte   px(%1001111),px(%1111001),px(%1000000)
        .byte   px(%1000000),px(%0011110),px(%0000000)
        .byte   px(%1000000),px(%0011000),px(%0000000)

L6FDF:  .byte   0

        ;; Resize Box
resize_box_bitmap:
        .byte   px(%1111111),px(%1111111),px(%1111111)
        .byte   px(%1000000),px(%0000000),px(%0000001)
        .byte   px(%1001111),px(%1111110),px(%0000001)
        .byte   px(%1001100),px(%0000111),px(%1111001)
        .byte   px(%1001100),px(%0000110),px(%0011001)
        .byte   px(%1001100),px(%0000110),px(%0011001)
        .byte   px(%1001111),px(%1111110),px(%0011001)
        .byte   px(%1000011),px(%0000000),px(%0011001)
        .byte   px(%1000011),px(%1111111),px(%1111001)
        .byte   px(%1000000),px(%0000000),px(%0000001)
        .byte   px(%1111111),px(%1111111),px(%1111111)

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

L700B:  .byte   $00
L700C:  .byte   $00
L700D:  .byte   $00
L700E:  .word   0
L7010:  .byte   $00

L7011:  .addr   $6FD3

        ;; Start window enumeration at top ???
.proc top_window
        copy16  L7011, $A7
        ldax    L700B
        bne     next_window_L7038
end:    rts
.endproc

        ;; Look up next window in chain. $A9/$AA will point at
        ;; winfo (also returned in X,A).
.proc next_window
        copy16  $A9, $A7
        ldy     #MGTK::winfo_offset_nextwinfo+1
        lda     ($A9),y
        beq     top_window::end  ; if high byte is 0, end of chain
        tax
        dey
        lda     ($A9),y
L7038:  stax    L700E
L703E:  ldax    L700E
L7044:  stax    $A9
        ldy     #$0B            ; copy first 12 bytes of window defintion to
L704A:  lda     ($A9),y         ; to $AB
        sta     $AB,y
        dey
        bpl     L704A
        ldy     #MGTK::grafport_size-1
L7054:  lda     ($A9),y
        sta     $A3,y
        dey
        cpy     #$13
        bne     L7054
L705E:  ldax    $A9
        rts
.endproc
        next_window_L7038 := next_window::L7038

        ;; Look up window state by id (in $82); $A9/$AA will point at
        ;; winfo (also X,A).
.proc window_by_id
        jsr     top_window
        beq     end
loop:   lda     $AB
        cmp     $82
        beq     next_window::L705E
        jsr     next_window
        bne     loop
end:    rts
.endproc

        ;; Look up window state by id (in $82); $A9/$AA will point at
        ;; winfo (also X,A).
        ;; This will exit the MGTK call directly (restoring stack, etc)
        ;; if the window is not found.
.proc window_by_id_or_exit
        jsr     window_by_id
        beq     nope
        rts
nope:   exit_call MGTK::error_window_not_found
.endproc

L707F:  MGTK_CALL MGTK::FrameRect, $C7
        rts

L7086:  MGTK_CALL MGTK::InRect, $C7
        rts

L708D:  ldx     #$03
L708F:  lda     $B7,x
        sta     $C7,x
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
        adc     $C7,x
        sta     $CB,x
        pla
        adc     $C8,x
        sta     $CC,x
        dex
        dex
        bpl     L7098
L70B2:  ldax    #$C7
        rts

L70B7:  jsr     L708D
        lda     $C7
        bne     L70C0
        dec     $C8
L70C0:  dec     $C7
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
L70F5:  sta     $82
        lda     $C9
        sec
        sbc     $82
        sta     $C9
        bcs     L70B2
        dec     $CA
        bcc     L70B2
L7104:  jsr     L70B7
        ldax    $CB
        sec
        sbc     #$14
        bcs     L7111
        dex
L7111:  stax    $C7
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
L712C:  ldax    $CD
        sec
        sbc     #$0A
        bcs     L7136
        dex
L7136:  stax    $C9
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
        ldax    $C7
        clc
        adc     #$0C
        bcc     L7164
        inx
L7164:  stax    $C7
        clc
        adc     #$0E
        bcc     L716E
        inx
L716E:  stax    $CB
        ldax    $C9
        clc
        adc     #$02
        bcc     L717C
        inx
L717C:  stax    $C9
        clc
        adc     L78CB
        bcc     L7187
        inx
L7187:  stax    $CD
        jmp     L70B2

L718E:  jsr     L70B7
        jsr     fill_and_frame_rect
        lda     $AC
        and     #$01
        bne     L71AA
        jsr     L7143
        jsr     fill_and_frame_rect
        jsr     L73BF
        ldax    $AD
        jsr     draw_text
L71AA:  jsr     next_window::L703E
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
L71D3:  jsr     next_window::L703E
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
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111
        .byte   %00000000
        .byte   %11111111

L71EE:  jsr     L7157
        lda     $C9
        and     #$01
        beq     L71FE
        MGTK_CALL MGTK::SetPattern, stripes_pattern
        rts

L71FE:  MGTK_CALL MGTK::SetPattern, stripes_pattern_alt
        rts

L7205:  ldax    #$0001
        beq     L720F
L720B:  ldax    #$0103
L720F:  stx     L71E4
        jsr     set_fill_mode
        lda     $AC
        and     #$02
        beq     L7255
        lda     $AC
        and     #$01
        bne     L7255
        jsr     L7157
        jsr     L707F
        jsr     L71EE
        ldax    $C7
        sec
        sbc     #$09
        bcs     L7234
        dex
L7234:  stax    $92
        clc
        adc     #$06
        bcc     L723E
        inx
L723E:  stax    $96
        copy16  $C9, $94
        copy16  $CD, $98
        jsr     PaintRectImpl  ; draws title bar stripes to left of close box
L7255:  lda     $AC
        and     #$01
        bne     L72C9
        jsr     L7143
        jsr     L73BF
        jsr     L5907
        jsr     L71EE
        ldax    $CB
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
        stax    $92
        lda     $96
        sec
        sbc     #$0A
        sta     $96
        bcs     L72A0
        dec     $97
L72A0:  jsr     PaintRectImpl  ; Draw title bar stripes between close box and title
        add16   $CB, #10, $92
        jsr     L7143
        sub16   $CB, #3, $96
        jsr     PaintRectImpl  ; Draw title bar stripes to right of title
        MGTK_CALL MGTK::SetPattern, standard_port::penpattern
L72C9:  jsr     next_window::L703E
        bit     $B0
        bpl     L7319
        jsr     L7104
        ldx     #$03
L72D5:  lda     $C7,x
        sta     up_scroll_params,x
        sta     down_scroll_params,x
        dex
        bpl     L72D5
        inc     up_scroll_params::incr
        ldax    $CD
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
        stax    down_scroll_params::unk1
        ldax    down_scroll_addr
        jsr     L791C
        ldax    up_scroll_addr
        jsr     L791C
L7319:  bit     $AF
        bpl     L7363
        jsr     L7129
        ldx     #$03
L7322:  lda     $C7,x
        sta     left_scroll_params,x
        sta     right_scroll_params,x
        dex
        bpl     L7322
        ldax    $CB
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
        stax    right_scroll_params
        ldax    right_scroll_addr
        jsr     L791C
        ldax    left_scroll_addr
        jsr     L791C
L7363:  lda     #$00
        jsr     set_fill_mode
        lda     $B0
        and     #$01
        beq     L737B
        lda     #$80
        sta     $8C
        lda     L71E4
        jsr     L79A0
        jsr     next_window::L703E
L737B:  lda     $AF
        and     #$01
        beq     L738E
        lda     #$00
        sta     $8C
        lda     L71E4
        jsr     L79A0
        jsr     next_window::L703E
L738E:  lda     $AC
        and     #$04
        beq     L73BE
        jsr     L713D
        lda     L71E4
        bne     L73A6
        ldax    #$C7
        jsr     fill_and_frame_rect
        jmp     L73BE

        ;; Draw resize box
L73A6:  ldx     #$03
L73A8:  lda     $C7,x
        sta     resize_box_params,x
        dex
        bpl     L73A8
        lda     #$04
        jsr     set_fill_mode
        ldax    resize_box_addr
        jsr     L791C
L73BE:  rts

L73BF:  ldax    $AD
        jsr     do_measure_text
        stax    $82
        lda     $C7
        clc
        adc     $CB
        tay
        lda     $C8
        adc     $CC
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
        ldax    $CD
        sec
        sbc     #$02
        bcs     L73F0
        dex
L73F0:  stax    current_penloc_y
        ldax    $82
        rts

;;; ============================================================

;;; 4 bytes of params, copied to current_penloc

FindWindowImpl:
        jsr     L653F
        MGTK_CALL MGTK::InRect, test_rect_params
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
        jmp     store_xa_at_y

L7416:  lda     #$00
        sta     L747A
        jsr     top_window
        beq     L7430
L7420:  jsr     L70B7
        jsr     L7086
        bne     L7434
        jsr     next_window
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

;;; ============================================================

L747A:  .byte   0
OpenWindowImpl:
        copy16  params_addr, $A9
        ldy     #$00
        lda     ($A9),y
        bne     L748E
        exit_call MGTK::error_window_id_required

L748E:  sta     $82
        jsr     window_by_id
        beq     L749A
        exit_call MGTK::error_window_already_exists

L749A:  copy16  params_addr, $A9
        ldy     #$0A
        lda     ($A9),y
        ora     #$80
        sta     ($A9),y
        bmi     L74BD

;;; ============================================================
;;; SelectWindow

;;; 1 byte of params, copied to $82

SelectWindowImpl:
        jsr     window_by_id_or_exit
        cmp     L700B
        bne     L74BA
        cpx     L700C
        bne     L74BA
        rts

L74BA:  jsr     L74F4
L74BD:  ldy     #MGTK::winfo_offset_nextwinfo ; Called from elsewhere
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
        jsr     top_window
        beq     L74DE
        jsr     L7205
L74DE:  pla
        sta     L700C
        pla
        sta     L700B
        jsr     top_window
        lda     $AB
        sta     L700D
        jsr     L718E
        jmp     L6553

L74F4:  ldy     #MGTK::winfo_offset_nextwinfo ; Called from elsewhere
        lda     ($A9),y
        sta     ($A7),y
        iny
        lda     ($A9),y
        sta     ($A7),y
        rts

;;; ============================================================
;;; GetWinPtr

;;; 1 byte of params, copied to $C7

.proc GetWinPtrImpl
        ptr := $A9
        jsr     window_by_id_or_exit
        ldax    ptr
        ldy     #1
        jmp     store_xa_at_y
.endproc

;;; ============================================================
;;; BeginUpdate

;;; 1 byte of params, copied to $82

L750C:  .res    38,0

.proc BeginUpdateImpl
        jsr     window_by_id_or_exit
        lda     $AB
        cmp     L7010
        bne     :+
        inc     L7871

:       jsr     L653C
        jsr     L6588
        lda     L7871
        bne     :+
        MGTK_CALL MGTK::SetPortBits, set_port_params
:       jsr     L718E
        jsr     L6588
        lda     L7871
        bne     :+
        MGTK_CALL MGTK::SetPortBits, set_port_params
:       jsr     next_window::L703E
        copy16  active_port, L750C
        jsr     L75C6
        php
        ldax    L758A
        jsr     assign_and_prepare_port
        asl     preserve_zp_flag
        plp
        bcc     :+
        rts
:       jsr     EndUpdateImpl
        ;; fall through
.endproc

L7585:  exit_call $A3

;;; ============================================================
;;; EndUpdate

;;; 1 byte of params, copied to $82

L758A:  .addr   L750C + 2

EndUpdateImpl:
        jsr     ShowCursorImpl
        ldax    L750C
        stax    active_port
        jmp     L6567

;;; ============================================================
;;; GetWinPort

;;; 3 bytes of params, copied to $82

GetWinPortImpl:
        jsr     apply_port_to_active_port
        jsr     window_by_id_or_exit
        copy16  $83, params_addr
        ldx     #$07
L75AC:  lda     fill_rect_params,x
        sta     $D8,x
        dex
        bpl     L75AC
        jsr     L75C6
        bcc     L7585
        ldy     #MGTK::grafport_size-1
L75BB:  lda     current_grafport,y
        sta     (params_addr),y
        dey
        bpl     L75BB
        jmp     apply_active_port_to_port

L75C6:  jsr     L708D
        ldx     #$07
L75CB:  lda     #$00
        sta     $9B,x
        lda     $C7,x
        sta     $92,x
        dex
        bpl     L75CB
        jsr     clip_rect
        bcs     L75DC
        rts

L75DC:  ldy     #$14
L75DE:  lda     ($A9),y
        sta     $BC,y
        iny
        cpy     #$38
        bne     L75DE
        ldx     #$02
L75EA:  copy16  $92,x, $D0,x

        sub16   $96,x, $92,x, $82,x
        sub16   $D8,x, $9B,x, $D8,x
        add16   $D8,x, $82,x, $DC,x

        dex
        dex
        bpl     L75EA
        sec
        rts

;;; ============================================================
;;; SetWinPort

;;; 2 bytes of params, copied to $82

        ;; This updates win grafport from params ???
        ;; The math is weird; $82 is the window id so
        ;; how does ($82),y do anything useful - is
        ;; this buggy ???

        ;; It seems like it's trying to update a fraction
        ;; of the drawing port (from |pattern| to |font|)

.proc SetWinPortImpl
        ptr := $A9

        jsr     window_by_id_or_exit
        lda     ptr
        clc
        adc     #MGTK::winfo_offset_port
        sta     ptr
        bcc     :+
        inc     ptr+1
:       ldy     #MGTK::grafport_size-1
loop:   lda     ($82),y
        sta     ($A9),y
        dey
        cpy     #$10
        bcs     loop
        rts
.endproc

;;; ============================================================
;;; FrontWindow

.proc FrontWindowImpl
        jsr     top_window
        beq     nope
        lda     $AB
        bne     :+
nope:   lda     #0
:       ldy     #0
        sta     (params_addr),y
        rts
.endproc

;;; ============================================================
;;; TrackGoAway

in_close_box:  .byte   0

.proc TrackGoAwayImpl
        jsr     top_window
        beq     end
        jsr     L7157
        jsr     L653F
        jsr     L6588
        lda     #$80
toggle: sta     in_close_box
        lda     #$02
        jsr     set_fill_mode
        jsr     HideCursorImpl
        MGTK_CALL MGTK::PaintRect, $C7
        jsr     ShowCursorImpl
loop:   jsr     L691B
        cmp     #$02
        beq     L768B
        MGTK_CALL MGTK::MoveTo, set_pos_params
        jsr     L7086
        eor     in_close_box
        bpl     loop
        lda     in_close_box
        eor     #$80
        jmp     toggle

L768B:  jsr     L6556
        ldy     #$00
        lda     in_close_box
        beq     end
        lda     #$01
end:    sta     (params_addr),y
        rts
.endproc

;;; ============================================================

        .byte   $00
L769B:  .byte   $00
L769C:  .byte   $00
L769D:  .word   0
L769F:  .byte   $00
L76A0:  .byte   $00,$00,$00
L76A3:  .byte   $00
L76A4:  .byte   $00,$00,$00

        ;; High bit set if window is being resized, clear if moved.
drag_resize_flag:
        .byte   0

;;; ============================================================

;;; 5 bytes of params, copied to $82

GrowWindowImpl:
        lda     #$80
        bmi     L76AE

;;; ============================================================

;;; 5 bytes of params, copied to $82

DragWindowImpl:
        lda     #$00

L76AE:  sta     drag_resize_flag
        jsr     L7ECD
        ldx     #$03
L76B6:  lda     $83,x
        sta     L769B,x
        sta     L769F,x
        lda     #$00
        sta     L76A3,x
        dex
        bpl     L76B6
        jsr     window_by_id_or_exit
        bit     kbd_mouse_state
        bpl     L76D1
        jsr     L817C
L76D1:  jsr     L653C
        jsr     L784C
        lda     #$02
        jsr     set_fill_mode
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
L76E2:  jsr     next_window::L703E
        jsr     L7749
        jsr     L70B7
        jsr     L707F
        jsr     ShowCursorImpl
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
        sta     (params_addr),y
        rts

L7714:  ldy     #$14
L7716:  lda     $A3,y
        sta     ($A9),y
        iny
        cpy     #$24
        bne     L7716
        jsr     HideCursorImpl
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
        jsr     HideCursorImpl
        jsr     L707F
        jmp     L76E2

L7749:  ldy     #$13
L774B:  lda     ($A9),y
        sta     $BB,y
        dey
        cpy     #$0B
        bne     L774B
        ldx     #$00
        stx     set_input_unk
        bit     drag_resize_flag
        bmi     L777D
L775F:  add16   $B7,x, L76A3,x, $B7,x
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
L7782:  add16lc $C3,x, L76A3,x, $C3,x
        sub16lc $C3,x, $BF,x, $82

        sec
        lda     $82
        sbc     $C7,x
        lda     $83
        sbc     $C8,x
        bpl     L77BC

        add16lc $C7,x, $BF,x, $C3,x
        jsr     L83F6
        jmp     L77D7

L77BC:  sec
        lda     $CB,x
        sbc     $82
        lda     $CC,x
        sbc     $83
        bpl     L77D7
        add16lc $CB,x, $BF,x, $C3,x
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
L77EC:  lda     $83,x
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
        lda     set_input_unk
L7814:  rts

;;; ============================================================
;;; CloseWindow

;;; 1 byte of params, copied to $82

.proc CloseWindowImpl
        jsr     window_by_id_or_exit
        jsr     L653C
        jsr     L784C
        jsr     L74F4
        ldy     #$0A
        lda     ($A9),y
        and     #$7F
        sta     ($A9),y
        jsr     top_window
        lda     $AB
        sta     L700D
        lda     #$00
        jmp     L7872
.endproc

;;; ============================================================
;;; CloseAll

CloseAllImpl:
        jsr     top_window
        beq     L7849
        ldy     #$0A
        lda     ($A9),y
        and     #$7F
        sta     ($A9),y
        jsr     L74F4
        jmp     CloseAllImpl

L7849:  jmp     L6454

L784C:  jsr     L6588
        jsr     L70B7
        ldx     #$07
L7854:  lda     $C7,x
        sta     $92,x
        dex
        bpl     L7854
        jsr     clip_rect
        ldx     #$03
L7860:  lda     $92,x
        sta     set_port_maprect,x
        sta     set_port_params,x
        lda     $96,x
        sta     set_port_size,x
        dex
        bpl     L7860
        rts

        ;; Erases window after destruction
L7871:  .byte   0
L7872:  sta     L7010
        lda     #$00
        sta     L7871
        MGTK_CALL MGTK::SetPortBits, set_port_params
        lda     #$00
        jsr     set_fill_mode
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::PaintRect, set_port_maprect
        jsr     L6553
        jsr     top_window
        beq     L78CA
        php
        sei
        jsr     FlushEventsImpl
L789E:  jsr     next_window
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
        sta     $82
        jsr     window_by_id
        ldax    $A7
        jsr     next_window::L7044
        jmp     L78A3

L78C9:  plp
L78CA:  rts

L78CB:  .byte   $08,$00
L78CD:  .byte   $0C,$00
L78CF:  .byte   $0D,$00

.proc set_port_params
left:           .word   0
top:            .word   $D
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
hoffset:        .word   0
voffset:        .word   0
width:          .word   0
height:         .word   0
.endproc
        set_port_top  := set_port_params::top
        set_port_size := set_port_params::width
        set_port_maprect  := set_port_params::hoffset ; Re-used since h/voff are 0

;;; ============================================================
;;; WindowToScreen

        ;; $83/$84 += $B7/$B8
        ;; $85/$86 += $B9/$BA

.proc WindowToScreenImpl
        jsr     window_by_id_or_exit
        ldx     #2
loop:   add16   $83,x, $B7,x, $83,x
        dex
        dex
        bpl     loop
        bmi     L790F
.endproc

;;; ============================================================
;;; ScreenToWindow

;;; 5 bytes of params, copied to $82

ScreenToWindowImpl:
        jsr     window_by_id_or_exit
        ldx     #$02
L78FE:  sub16   $83,x, $B7,x, $83,x
        dex
        dex
        bpl     L78FE
L790F:  ldy     #$05
L7911:  lda     $7E,y
        sta     (params_addr),y
        iny
        cpy     #$09
        bne     L7911
        rts

        ;; Used to draw scrollbar arrows
L791C:  stax    $82
        ldy     #$03
L7922:  lda     #$00
        sta     $8A,y
        lda     ($82),y
        sta     $92,y
        dey
        bpl     L7922
        iny
        sty     $91
        ldy     #$04
        lda     ($82),y
        tax
        lda     div7_table+7,x
        sta     $90
        txa
        ldx     $93
        clc
        adc     $92
        bcc     L7945
        inx
L7945:  stax    $96
        iny
        lda     ($82),y
        ldx     $95
        clc
        adc     $94
        bcc     L7954
        inx
L7954:  stax    $98
        iny
        lda     ($82),y
        sta     $8E
        iny
        lda     ($82),y
        sta     $8F
        jmp     BitBltImpl

;;; ============================================================
;;; ActivateCtl

;;; 2 bytes of params, copied to $8C

ActivateCtlImpl:
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
        jsr     top_window
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
        MGTK_CALL MGTK::PaintRect, $C7
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
        MGTK_CALL MGTK::SetPattern, light_speckles_pattern
        MGTK_CALL MGTK::PaintRect, $C7
        MGTK_CALL MGTK::SetPattern, standard_port::penpattern
        bit     $8C
        bmi     L79DD
        bit     $AF
        bvs     L79E1
L79DC:  rts

L79DD:  bit     $B0
        bvc     L79DC
L79E1:  jsr     L7A73
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
L7A23:  inc16   $C7
        lda     $CB
        bne     L7A2F
        dec     $CC
L7A2F:  dec     $CB
        jmp     L7A70

L7A34:  jsr     L7129
        lda     $C7
        clc
        adc     #$15
        sta     $C7
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
L7A62:  inc16   $C9
        lda     $CD
        bne     L7A6E
        dec     $CE
L7A6E:  dec     $CD
L7A70:  jmp     L70B2

L7A73:  jsr     L79F1
        jsr     L7CE3
        jsr     fixed_div
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
L7A94:  sta     $82
        sty     $83
        ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L7AA4
        ldx     #$02
        lda     #$0C
L7AA4:  pha
        add16   $C7,x, $82, $C7,x
        pla
        clc
        adc     $C7,x
        sta     $CB,x
        lda     $C8,x
        adc     #$00
        sta     $CC,x
        jmp     L70B2

;;; ============================================================
;;; FindControl

;;; 4 bytes of params, copied to current_penloc

FindControlImpl:
        jsr     L653F
        jsr     top_window
        bne     L7ACE
        exit_call MGTK::error_no_active_window

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
        lda     current_penloc_y
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
        lda     current_penloc_x+1
        cmp     $C8
        bcc     L7B60
        bne     L7B5F
        lda     current_penloc_x
        cmp     $C7
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

;;; ============================================================
;;; SetCtlMax

;;; 3 bytes of params, copied to $82

SetCtlMaxImpl:
        lda     $82
        cmp     #$01
        bne     L7B81
        lda     #$80
        sta     $82
        bne     L7B90
L7B81:  cmp     #$02
        bne     L7B8B
        lda     #$00
        sta     $82
        beq     L7B90
L7B8B:  exit_call $A4

L7B90:  jsr     top_window
        bne     L7B9A
        exit_call MGTK::error_no_active_window

L7B9A:  ldy     #$06
        bit     $82
        bpl     L7BA2
        ldy     #$08
L7BA2:  lda     $83
        sta     ($A9),y
        sta     $AB,y
        rts

;;; ============================================================
;;; TrackThumb

;;; 5 bytes of params, copied to $82

TrackThumbImpl:
        lda     $82
        cmp     #$01
        bne     L7BB6
        lda     #$80
        sta     $82
        bne     L7BC5
L7BB6:  cmp     #$02
        bne     L7BC0
        lda     #$00
        sta     $82
        beq     L7BC5
L7BC0:  exit_call $A4

L7BC5:  lda     $82
        sta     $8C
        ldx     #$03
L7BCB:  lda     $83,x
        sta     L769B,x
        sta     L769F,x
        dex
        bpl     L7BCB
        jsr     top_window
        bne     L7BE0
        exit_call MGTK::error_no_active_window

L7BE0:  jsr     L7A73
        jsr     L653F
        jsr     L6588
        lda     #$02
        jsr     set_fill_mode
        MGTK_CALL MGTK::SetPattern, light_speckles_pattern
        jsr     HideCursorImpl
L7BF7:  jsr     L707F
        jsr     ShowCursorImpl
L7BFD:  jsr     L691B
        cmp     #$02
        beq     L7C66
        jsr     L77E0
        beq     L7BFD
        jsr     HideCursorImpl
        jsr     L707F
        jsr     top_window
        jsr     L7A73
        ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L7C21
        ldx     #$02
        lda     #$0C
L7C21:  sta     $82
        lda     $C7,x
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
        sta     $C7,x
        clc
        adc     $82
        sta     $CB,x
        lda     $C8,x
        adc     #$00
        sta     $CC,x
        jmp     L7BF7

L7C66:  jsr     HideCursorImpl
        jsr     L707F
        jsr     L6553
        jsr     L7CBA
        jsr     fixed_div
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
        jmp     store_xa_at_y

L7C93:  sta     $82
        sty     $83
        lda     #$80
        sta     $84
        ldy     #$00
        sty     $85
        txa
        beq     L7CB5
L7CA2:  add16   $82, $84, $84
        bcc     L7CB2
        iny
L7CB2:  dex
        bne     L7CA2
L7CB5:  rts

L7CB6:  .byte   0
L7CB7:  .byte   0
L7CB8:  .byte   0
L7CB9:  .byte   0

L7CBA:  sub16   L7CB6, L7CB8, fixed_div::divisor
        ldx     #$00
        bit     $8C
        bpl     L7CD3
        ldx     #2
L7CD3:  sub16   $C7,x, L7CB8, fixed_div::dividend
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
L7D07:  sta     $82
        lda     $C7,x
        ldy     $C8,x
        sta     L7CB8
        sty     L7CB9
        lda     $CB,x
        ldy     $CC,x
        sec
        sbc     $82
        bcs     L7D1D
        dey
L7D1D:  sta     L7CB6
        sty     L7CB7
        rts

;;; ============================================================
;;; UpdateThumb

;;; 3 bytes of params, copied to $8C

.proc UpdateThumbImpl
        lda     $8C
        cmp     #MGTK::ctl_vertical_scroll_bar
        bne     :+
        lda     #$80
        sta     $8C
        bne     check_win

:       cmp     #MGTK::ctl_horizontal_scroll_bar
        bne     bad_ctl
        lda     #$00
        sta     $8C
        beq     check_win

bad_ctl:
        exit_call $A4

check_win:
        jsr     top_window
        bne     :+
        exit_call MGTK::error_no_active_window

:       ldy     #$07
        bit     $8C
        bpl     :+
        ldy     #$09
:       lda     $8D
        sta     ($A9),y
        jsr     L653C
        jsr     L657E
        jsr     L79A0
        jmp     L6553
.endproc

;;; ============================================================
;;; KeyboardMouse

;;; 1 byte of params, copied to $82

KeyboardMouse:
        lda     #$80
        sta     kbd_mouse_state
        jmp     FlushEventsImpl

;;; ============================================================

;;; $4E IMPL

;;; 2 bytes of params, copied to $82

.proc SetMenuSelectionImpl
        params := $82

        lda     params+0
        sta     menu_index

        lda     params+1
        sta     menu_item_index

        rts
.endproc

;;; ============================================================

        ;; Set to $80 by KeyboardMouse call; also set to $04,
        ;; $01 elsewhere.
kbd_mouse_state:
        .byte   0

kbd_mouse_x:  .word     0
kbd_mouse_y:  .word     0

L7D79:  .byte   $00

        ;; Currently selected menu/menu item. Note that menu is index,
        ;; not ID from menu definition.
menu_index:
        .byte   0
menu_item_index:
        .byte   0

saved_mouse_pos:
saved_mouse_x:  .word   0
saved_mouse_y:  .byte   0

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

L7D99:  .res    128, 0

;;; ============================================================
;;; X = xlo, Y = xhi, A = y


.proc set_mouse_pos
        bit     mouse_hooked_flag
        bmi     no_firmware
        bit     no_mouse_flag
        bmi     no_firmware
        pha
        txa
        sec
        jsr     L7E75
        ldx     mouse_firmware_hi
        sta     MOUSE_X_LO,x
        tya
        sta     MOUSE_X_HI,x
        pla
        ldy     #$00
        clc
        jsr     L7E75
        ldx     mouse_firmware_hi
        sta     MOUSE_Y_LO,x
        tya
        sta     MOUSE_Y_HI,x
        ldy     #POSMOUSE
        jmp     call_mouse

no_firmware:
        stx     mouse_x
        sty     mouse_x+1
        sta     mouse_y
        bit     mouse_hooked_flag
        bpl     not_hooked
        ldy     #POSMOUSE
        jmp     call_mouse

not_hooked:
        rts
.endproc

;;; ============================================================

.proc restore_mouse_pos
        ldx     saved_mouse_x
        ldy     saved_mouse_x+1
        lda     saved_mouse_y
        jmp     set_mouse_pos
.endproc

.proc set_mouse_pos_from_kbd_mouse
        ldx     kbd_mouse_x
        ldy     kbd_mouse_x+1
        lda     kbd_mouse_y
        jmp     set_mouse_pos
.endproc

L7E75:  bcc     L7E7D
        ldx     mouse_scale_x
        bne     L7E82
L7E7C:  rts

L7E7D:  ldx     mouse_scale_y
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
L7E8E:  lda     kbd_mouse_x,x
        sta     mouse_x,x
        dex
        bpl     L7E8E
        rts

L7E98:  jsr     L7E8C
        jmp     set_mouse_pos_from_kbd_mouse

.proc save_mouse_pos
        jsr     read_mouse_pos
        ldx     #2
:       lda     mouse_x,x
        sta     saved_mouse_pos,x
        dex
        bpl     :-
        rts
.endproc

L7EAD:  jsr     stash_addr
        copy16  L7F2E, params_addr
        jsr     SetCursorImpl
        jsr     restore_addr
        lda     #$00
        sta     kbd_mouse_state
        lda     #$40
        sta     mouse_status
        jmp     restore_mouse_pos

L7ECD:  lda     #$00
        sta     L7D81
        sta     set_input_unk
        rts

        ;; Look at buttons (apple keys), compute modifiers in A
        ;; (bit = button 0 / open apple, bit 1 = button 1 / solid apple)
.proc compute_modifiers
        lda     BUTN1
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        rts
.endproc

L7EE2:  jsr     compute_modifiers
        sta     set_input_modifiers
L7EE8:  clc
        lda     KBD
        bpl     L7EF4
        stx     KBDSTRB
        and     #$7F
        sec
L7EF4:  rts

L7EF5:  lda     kbd_mouse_state
        bne     L7EFB
        rts

L7EFB:  cmp     #$04
        beq     L7F48
        jsr     L7FB4
        lda     kbd_mouse_state
        cmp     #$01
        bne     L7F0C
        jmp     L804D

L7F0C:  jmp     L825F

L7F0F:  jsr     stash_addr
        copy16  active_cursor, L7F2E
        copy16  L6065, params_addr
        jsr     SetCursorImpl
        jmp     restore_addr

L7F2E:  .byte   0
L7F2F:  .byte   0

stash_addr:
        copy16  params_addr, stashed_addr
        rts

restore_addr:
        copy16  stashed_addr, params_addr
        rts

stashed_addr:  .addr     0

L7F48:  jsr     compute_modifiers
        ror     a
        ror     a
        ror     L7D82
        lda     L7D82
        sta     mouse_status
        lda     #0
        sta     input::modifiers
        jsr     L7EE8
        bcc     L7F63
        jmp     L8292

L7F63:  jmp     L7E98

L7F66:  pha
        lda     kbd_mouse_state
        bne     L7FA3
        pla
        cmp     #$03
        bne     L7FA2
        bit     mouse_status
        bmi     L7FA2
        lda     #$04
        sta     kbd_mouse_state
        ldx     #$0A
L7F7D:  lda     SPKR            ; Beep?
        ldy     #$00
L7F82:  dey
        bne     L7F82
        dex
        bpl     L7F7D
L7F88:  jsr     compute_modifiers
        cmp     #3
        beq     L7F88
        sta     input::modifiers
        lda     #$00
        sta     L7D82
        ldx     #$02
L7F99:  lda     set_pos_params,x
        sta     kbd_mouse_x,x
        dex
        bpl     L7F99
L7FA2:  rts

L7FA3:  cmp     #$04
        bne     L7FB2
        pla
        and     #$01
        bne     L7FB1
        lda     #$00
        sta     kbd_mouse_state
L7FB1:  rts

L7FB2:  pla
        rts

L7FB4:  bit     mouse_status
        bpl     L7FC1
        lda     #0
        sta     kbd_mouse_state
        jmp     set_mouse_pos_from_kbd_mouse

L7FC1:  lda     mouse_status
        pha
        lda     #$C0
        sta     mouse_status
        pla
        and     #$20
        beq     L7FDE
        ldx     #$02
L7FD1:  lda     mouse_x,x
        sta     kbd_mouse_x,x
        dex
        bpl     L7FD1
        stx     L7D79
        rts

L7FDE:  jmp     L7E8C

L7FE1:  php
        sei
        jsr     save_mouse_pos
        lda     #$01
        sta     kbd_mouse_state
        jsr     L800F
        lda     #$80
        sta     mouse_status
        jsr     L7F0F
        ldx     menu_index
        jsr     L6878
        lda     $AF
        sta     L6BD9
        jsr     L6D26
        lda     menu_item_index
        sta     L6BDA
        jsr     L6EAA
        plp
        rts

L800F:  ldx     menu_index
        jsr     L6878

        add16lc $B7, #5, kbd_mouse_x

        ldy     menu_item_index
        lda     menu_item_y_table,y
        sta     kbd_mouse_y
        lda     #$C0
        sta     mouse_status
        jmp     L7E98

L8035:  bit     L7D79
        bpl     L804C
        lda     L6BDA
        sta     menu_item_index
        ldx     L6BD9
        dex
        stx     menu_index
        lda     #$00
        sta     L7D79
L804C:  rts

L804D:  jsr     L7D83
        jsr     L8056
        jmp     L7D8E

L8056:  jsr     L7EE2
        bcs     handle_menu_key
        rts


        ;; Keyboard navigation of menu
.proc handle_menu_key
        pha
        jsr     L8035
        pla
        cmp     #CHAR_ESCAPE
        bne     try_return
        lda     #0
        sta     L7D80
        sta     L7D7F
        lda     #$80
        sta     L7D81
        rts

try_return:
        cmp     #CHAR_RETURN
        bne     try_up
        jsr     L7E8C
        jmp     L7EAD

try_up:
        cmp     #CHAR_UP
        bne     try_down
L8081:  dec     menu_item_index
        bpl     L8091
        ldx     menu_index
        jsr     L6878
        ldx     $AA
        stx     menu_item_index
L8091:  ldx     menu_item_index
        beq     L80A0
        dex
        jsr     L68BE
        lda     $BF
        and     #$C0
        bne     L8081
L80A0:  jmp     L800F

try_down:
        cmp     #CHAR_DOWN
        bne     try_right
L80A7:  inc     menu_item_index
        ldx     menu_index
        jsr     L6878
        lda     menu_item_index
        cmp     $AA
        bcc     L80BE
        beq     L80BE
        lda     #0
        sta     menu_item_index
L80BE:  ldx     menu_item_index
        beq     L80CD
        dex
        jsr     L68BE
        lda     $BF
        and     #$C0
        bne     L80A7
L80CD:  jmp     L800F

try_right:
        cmp     #CHAR_RIGHT
        bne     try_left
        lda     #0
        sta     menu_item_index
        inc     menu_index
        lda     menu_index
        cmp     $A8
        bcc     L80E8
        lda     #$00
        sta     menu_index
L80E8:  jmp     L800F

try_left:
        cmp     #CHAR_LEFT
        bne     nope
        lda     #0
        sta     menu_item_index
        dec     menu_index
        bmi     L80FC
        jmp     L800F

L80FC:  ldx     $A8
        dex
        stx     menu_index
        jmp     L800F

nope:   jsr     L8110
        bcc     L810F
        lda     #$80
        sta     L7D81
L810F:  rts
.endproc

L8110:  sta     $C9
        lda     set_input_modifiers
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
        sta     $C7
        rts

L8149:  php
        sei
        jsr     L6D23
        jsr     L7EAD
        lda     L7D7F
        sta     $C7
        sta     L6BD9
        lda     L7D80
        sta     $C8
        sta     L6BDA
        jsr     L6556
        lda     L7D7F
        beq     L816F
        jsr     HiliteMenuImpl
        lda     L7D7F
L816F:  sta     L6BD9
        ldx     L7D80
        stx     L6BDA
        plp
        jmp     store_xa_at_params

L817C:  php
        sei
        jsr     save_mouse_pos
        lda     #$80
        sta     mouse_status
        jsr     L70B7
        bit     drag_resize_flag
        bpl     L81E4
        lda     $AC
        and     #$04
        beq     L81D9
        ldx     #$00
L8196:  sec
        lda     $CB,x
        sbc     #$04
        sta     kbd_mouse_x,x
        sta     L769B,x
        sta     L769F,x
        lda     $CC,x
        sbc     #$00
        sta     kbd_mouse_x+1,x
        sta     L769C,x
        sta     L76A0,x
        inx
        inx
        cpx     #$04
        bcc     L8196
        sec
        lda     #<(screen_width-1)
        sbc     L769B
        lda     #>(screen_width-1)
        sbc     L769B+1
        bmi     L81D9
        sec
        lda     #<(screen_height-1)
        sbc     L769D
        lda     #>(screen_height-1)
        sbc     L769D+1
        bmi     L81D9
        jsr     L7E98
        jsr     L7F0F
        plp
        rts

L81D9:  lda     #$00
        sta     kbd_mouse_state
        lda     #$A2
        plp
        jmp     exit_with_a

L81E4:  lda     $AC
        and     #$01
        beq     L81F4
        lda     #$00
        sta     kbd_mouse_state
        exit_call $A1

L81F4:  ldx     #$00
L81F6:  clc
        lda     $C7,x
        cpx     #$02
        beq     L8202
        adc     #$23
        jmp     L8204

L8202:  adc     #$05
L8204:  sta     kbd_mouse_x,x
        sta     L769B,x
        sta     L769F,x
        lda     $C8,x
        adc     #$00
        sta     kbd_mouse_x+1,x
        sta     L769C,x
        sta     L76A0,x
        inx
        inx
        cpx     #$04
        bcc     L81F6
        bit     kbd_mouse_x+1
        bpl     L8235
        ldx     #$01
        lda     #$00
L8229:  sta     kbd_mouse_x,x
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
        adc     kbd_mouse_y
        sta     kbd_mouse_y
        plp
        bpl     L8254
        cmp     #$C0
        bcc     L8251
        lda     #$00
        sta     kbd_mouse_y
L8251:  jmp     L7E98

L8254:  cmp     #$C0
        bcc     L8251
        lda     #$BF
        sta     kbd_mouse_y
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
        lda     set_input_modifiers
        beq     L828C
        ora     #$80
        sta     set_input_modifiers
L828C:  pla
        ldx     #$C0
        stx     mouse_status
L8292:  cmp     #$0B
        bne     L82A2
        lda     #$F8
        bit     set_input_modifiers
        bpl     L829F
        lda     #$D0
L829F:  jmp     L823D

L82A2:  cmp     #$0A
        bne     L82B2
        lda     #$08
        bit     set_input_modifiers
        bpl     L82AF
        lda     #$30
L82AF:  jmp     L823D

L82B2:  cmp     #$15
        bne     L82ED
        jsr     L839A
        bcc     L82EA
        clc
        lda     #$08
        bit     set_input_modifiers
        bpl     L82C5
        lda     #$40
L82C5:  adc     kbd_mouse_x
        sta     kbd_mouse_x
        lda     kbd_mouse_x+1
        adc     #$00
        sta     kbd_mouse_x+1
        sec
        lda     kbd_mouse_x
        sbc     #$2F
        lda     kbd_mouse_x+1
        sbc     #$02
        bmi     L82EA
        lda     #$02
        sta     kbd_mouse_x+1
        lda     #$2F
        sta     kbd_mouse_x
L82EA:  jmp     L7E98

L82ED:  cmp     #$08
        bne     L831D
        jsr     L8352
        bcc     L831A
        lda     kbd_mouse_x
        bit     set_input_modifiers
        bpl     L8303
        sbc     #$40
        jmp     L8305

L8303:  sbc     #$08
L8305:  sta     kbd_mouse_x
        lda     kbd_mouse_x+1
        sbc     #$00
        sta     kbd_mouse_x+1
        bpl     L831A
        lda     #$00
        sta     kbd_mouse_x
        sta     kbd_mouse_x+1
L831A:  jmp     L7E98

L831D:  sta     set_input_key
        ldx     #MGTK::grafport_size-1
L8322:  lda     $A7,x
        sta     $0600,x
        dex
        bpl     L8322
        lda     set_input_key
        jsr     L8110
        php
        ldx     #MGTK::grafport_size-1
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

L8347:  MGTK_CALL MGTK::PostEvent, set_input_params
        rts

.proc set_input_params          ; 1 byte shorter than normal, since KEY
state:  .byte   MGTK::event_kind_key_down
key:    .byte   0
modifiers:
        .byte   0
unk:    .byte   0
.endproc
        set_input_key := set_input_params::key
        set_input_modifiers := set_input_params::modifiers
        set_input_unk := set_input_params::unk

L8352:  lda     kbd_mouse_state
        cmp     #$04
        beq     L8368
        lda     kbd_mouse_x
        bne     L8368
        lda     kbd_mouse_x+1
        bne     L8368
        bit     drag_resize_flag
        bpl     L836A
L8368:  sec
        rts

L836A:  jsr     L70B7
        lda     $CC
        bne     L8380
        lda     #$09
        bit     set_input_params::modifiers
        bpl     L837A
        lda     #$41
L837A:  cmp     $CB
        bcc     L8380
        clc
        rts

L8380:  inc     set_input_params::unk
        clc
        lda     #$08
        bit     set_input_params::modifiers
        bpl     L838D
        lda     #$40
L838D:  adc     L769B
        sta     L769B
        bcc     L8398
        inc     L769C
L8398:  clc
        rts

L839A:  lda     kbd_mouse_state
        cmp     #$04
        beq     L83B3
        bit     drag_resize_flag
        bmi     L83B3
        lda     kbd_mouse_x
        sbc     #<(screen_width-1)
        lda     kbd_mouse_x+1
        sbc     #>(screen_width-1)
        beq     L83B5
        sec
L83B3:  sec
        rts

L83B5:  jsr     L70B7
        sec
        lda     #$2F
        sbc     $C7
        tax
        lda     #$02
        sbc     $C8
        beq     L83C6
        ldx     #$FF
L83C6:  bit     set_input_modifiers
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
L83F0:  inc     set_input_unk
        clc
        rts

L83F5:  .byte   0
L83F6:  lda     #$80
        sta     L83F5
L83FB:  rts

L83FC:  bit     kbd_mouse_state
        bpl     L83FB
        bit     L83F5
        bpl     L83FB
        jsr     L70B7
        php
        sei
        ldx     #$00
L840D:  sub16lc $CB,x, #4, kbd_mouse_x,x
        inx
        inx
        cpx     #$04
        bcc     L840D
        jsr     L7E98
        plp
        rts

;;; ============================================================
;;; ScaleMouse

;;; Sets up mouse clamping

;;; 2 bytes of params, copied to $82
;;; byte 1 controls x clamp, 2 controls y clamp
;;; clamp is to fractions of screen (0 = full, 1 = 1/2, 2 = 1/4, 3 = 1/8) (why???)

.proc ScaleMouseImpl
        params := $82
        lda     params+0
        sta     mouse_scale_x
        lda     params+1
        sta     mouse_scale_y

L8431:  bit     no_mouse_flag   ; called after INITMOUSE
        bmi     end

        lda     mouse_scale_x
        asl     a
        tay
        lda     #0
        sta     mouse_x
        sta     mouse_x+1
        bit     mouse_hooked_flag
        bmi     :+

        sta     CLAMP_MIN_LO
        sta     CLAMP_MIN_HI

:       lda     clamp_x_table,y
        sta     mouse_y
        bit     mouse_hooked_flag
        bmi     :+

        sta     CLAMP_MAX_LO

:       lda     clamp_x_table+1,y
        sta     mouse_y+1
        bit     mouse_hooked_flag
        bmi     :+
        sta     CLAMP_MAX_HI
:       lda     #CLAMP_X
        ldy     #CLAMPMOUSE
        jsr     call_mouse

        lda     mouse_scale_y
        asl     a
        tay
        lda     #0
        sta     mouse_x
        sta     mouse_x+1
        bit     mouse_hooked_flag
        bmi     :+
        sta     CLAMP_MIN_LO
        sta     CLAMP_MIN_HI
:       lda     clamp_y_table,y
        sta     mouse_y
        bit     mouse_hooked_flag
        bmi     :+
        sta     CLAMP_MAX_LO
:       lda     clamp_y_table+1,y
        sta     mouse_y+1
        bit     mouse_hooked_flag
        bmi     :+
        sta     CLAMP_MAX_HI
:       lda     #CLAMP_Y
        ldy     #CLAMPMOUSE
        jsr     call_mouse
end:    rts

clamp_x_table:  .word   screen_width-1, screen_width/2-1, screen_width/4-1, screen_width/8-1
clamp_y_table:  .word   screen_height-1, screen_height/2-1, screen_height/4-1, screen_height/8-1

.endproc

;;; ============================================================
;;; Locate Mouse Slot


        ;; If X's high bit is set, only slot in low bits is tested.
        ;; Otherwise all slots are scanned.

.proc find_mouse
        txa
        and     #$7F
        beq     scan
        jsr     check_mouse_in_a
        sta     no_mouse_flag
        beq     found
        ldx     #0
        rts

        ;; Scan for mouse starting at slot 7
scan:   ldx     #7
loop:   txa
        jsr     check_mouse_in_a
        sta     no_mouse_flag
        beq     found
        dex
        bpl     loop
        ldx     #0              ; no mouse found
        rts

found:  ldy     #INITMOUSE
        jsr     call_mouse
        jsr     ScaleMouseImpl::L8431
        ldy     #HOMEMOUSE
        jsr     call_mouse
        lda     mouse_firmware_hi
        and     #$0F
        tax                     ; return with mouse slot in X
        rts

        ;; Check for mouse in slot A
.proc check_mouse_in_a
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
        return  #$00

nope:   return  #$80
.endproc
.endproc

no_mouse_flag:               ; high bit set if no mouse present
        .byte   0
mouse_firmware_hi:           ; e.g. if mouse is in slot 4, this is $C4
        .byte   0
mouse_operand:               ; e.g. if mouse is in slot 4, this is $40
        .byte   0

.endproc  ; mgtk
