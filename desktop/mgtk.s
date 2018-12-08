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
        COPY_BYTES $80, $80, zp_saved
        COPY_BYTES $C, active_saved, active_port
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

        COPY_BYTES $C, active_port, active_saved
        COPY_BYTES $80, zp_saved, $80

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
        ldy     #.sizeof(MGTK::GrafPort)-1
:       lda     (active_port),y
        sta     current_grafport,y
        dey
        bpl     :-
        rts
.endproc

.proc apply_port_to_active_port
        ldy     #.sizeof(MGTK::GrafPort)-1
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
        PARAM_DEFN 16, $8A, 0                ; $4D BitBlt
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

        top                  := $94        ; top/starting/current y-coordinate
        bottom               := $98        ; bottom/ending/maximum y-coordinate
        left                 := $92
        right                := $96

        fixed_div_dividend   := $A1        ; parameters used by fixed_div proc
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

:
load_addr       := *+1
        lda     $FFFF,y                 ; off-screen BMP will be patched here
        and     #$7F
        sta     bitmap_buffer,y
        dey
        bpl     :-
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
        jsr     mult_x_y

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

mult_x_y:
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


mult_x_y := ndbm_calc_dest::mult_x_y


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
        jsr     draw_line
        ldy     frect_ctr
        dey
        bpl     rloop
        COPY_BYTES 4, left, current_penloc
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
:       exit_call MGTK::inrect_inside           ; success!

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
        exit_call MGTK::Error::empty_object
.endproc


;;; ============================================================

;;; 16 bytes of params, copied to $8A

src_width_bytes:
        .res    1          ; width of source data in chars

unused_width:
        .res    1          ; holds the width of data, but is not used ???

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
        ;; fall through to BitBlt
.endproc

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
:       sta     unused_width
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
        lda     left_mod14

        sec
        sbc     #7
        bcc     :+
        sta     left_mod14
        dex
:       stx     dhgr_shift_line::offset1_addr
        inx
        stx     dhgr_shift_line::offset2_addr

        lda     left_mod14
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
        exit_call MGTK::Error::bad_object
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
        jsr     DRAW_LINE_ABS_IMPL_do_draw_line

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
        jsr     DRAW_LINE_ABS_IMPL_do_draw_line

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
        DRAW_LINE_ABS_IMPL_do_draw_line := LineToImpl::do_draw_line

;;; ============================================================
;;; SetFont

.define max_font_height 16

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

        cmp     #max_font_height+1       ; if height >= 17, skip this next bit
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

end:    exit_call MGTK::Error::font_too_big
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

        ;; Turn the current penloc into left, right, top, and bottom.
        ;;
        ;; Inputs:
        ;;    A = width
        ;;    $FF = height
        ;;
.proc penloc_to_bounds
        sec
        sbc     #1
        bcs     :+
        dex
:       clc
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
        clc
        adc     #1
        bcc     :+
        inx
:       sec
        sbc     glyph_height_p
        bcs     :+
        dex
:       stax    top
        rts
.endproc

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
        jsr     measure_text
        stax    text_width

        ldy     #0
        sty     text_index
        sty     $A0
        sty     clipped_left
        sty     clipped_top
        jsr     penloc_to_bounds
        jsr     clip_rect
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
        jsr     set_up_fill_mode
        jsr     set_dest

        lda     left_mod14
        clc
        adc     clipped_left
        bpl     :+
        inc     width_bytes
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
        jmp     adjust_xpos


do_draw:
        lda     bottom
        sec
        sbc     top
        asl     a
        tax

        ;; Calculate offsets to the draw and blit routines so that they draw
        ;; the exact number of needed lines.
        lda     shifted_draw_line_table,x
        sta     shifted_draw_jmp_addr
        lda     shifted_draw_line_table+1,x
        sta     shifted_draw_jmp_addr+1

        lda     unshifted_draw_line_table,x
        sta     unshifted_draw_jmp_addr
        lda     unshifted_draw_line_table+1,x
        sta     unshifted_draw_jmp_addr+1

        lda     unmasked_blit_line_table,x
        sta     unmasked_blit_jmp_addr
        lda     unmasked_blit_line_table+1,x
        sta     unmasked_blit_jmp_addr+1

        lda     masked_blit_line_table,x
        sta     masked_blit_jmp_addr
        lda     masked_blit_line_table+1,x
        sta     masked_blit_jmp_addr+1

        txa
        lsr     a
        tax
        sec
        stx     $80
        stx     $81
        lda     #0
        sbc     clipped_top
        sta     clipped_top
        tay

        ldx     #(max_font_height-1)*shifted_draw_line_size
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
        ldx     #(max_font_height-1)*unshifted_draw_line_size
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


        ;; Unrolled loop from max_font_height-1 down to 0
unshifted_draw_linemax:
        .repeat max_font_height, line
        .ident (.sprintf ("unshifted_draw_line_%d", max_font_height-line-1)):
:       lda     $FFFF,x
        sta     text_bits_buf+max_font_height-line-1

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
        tya
        asl     a
        tay
        copy16  shift_table_aux,y, shift_aux_ptr
        copy16  shift_table_main,y, shift_main_ptr

shifted_draw_jmp_addr := *+1
        jmp     shifted_draw_linemax      ; patched to jump into following block


        ;; Unrolled loop from max_font_height-1 down to 0
shifted_draw_linemax:
        .repeat max_font_height, line
        .ident (.sprintf ("shifted_draw_line_%d", max_font_height-line-1)):

:       ldy     $FFFF,x             ; All of these $FFFFs are modified
        lda     (shift_main_ptr),y
        sta     text_bits_buf+16+max_font_height-line-1
        lda     (shift_aux_ptr),y
        ora     text_bits_buf+max_font_height-line-1
        sta     text_bits_buf+max_font_height-line-1

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
        jmp     last_blit

advance_byte:
        sbc     #7
        sta     left_mod14

        ldy     $A0
        bne     :+
        jmp     first_blit

:       bmi     next_byte
        dec     width_bytes
        bne     unmasked_blit
        jmp     last_blit

unmasked_blit:
unmasked_blit_jmp_addr := *+1
        jmp     unmasked_blit_linemax        ; patched to jump into block below


;;; Per JB: "looks like the quickdraw fast-path draw unclipped pattern slab"

        ;; Unrolled loop from max_font_height-1 down to 0
unmasked_blit_linemax:
        .repeat max_font_height, line
        .ident (.sprintf ("unmasked_blit_line_%d", max_font_height-line-1)):
:       lda     text_bits_buf+max_font_height-line-1
        eor     current_textback
        sta     (vid_addrs_table + 2*(max_font_height-line-1)),y

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

        ;; Unrolled loop from max_font_height-1 down to 0
masked_blit_linemax:
        .repeat max_font_height, line
        .ident (.sprintf ("masked_blit_line_%d", max_font_height-line-1)):
:       lda     text_bits_buf+max_font_height-line-1
        eor     current_textback
        eor     (vid_addrs_table + 2*(max_font_height-line-1)),y
        and     blit_mask
        eor     (vid_addrs_table + 2*(max_font_height-line-1)),y
        sta     (vid_addrs_table + 2*(max_font_height-line-1)),y

        .ifndef masked_blit_line_size
        masked_blit_line_size := * - :-
        .else
        .assert masked_blit_line_size = * - :-, error, "masked_blit_line_size inconsistent"
        .endif

        .endrepeat

        rts


shifted_draw_line_table:
        .repeat max_font_height, line
        .addr   .ident (.sprintf ("shifted_draw_line_%d", line))
        .endrepeat

unshifted_draw_line_table:
        .repeat max_font_height, line
        .addr   .ident (.sprintf ("unshifted_draw_line_%d", line))
        .endrepeat

unmasked_blit_line_table:
        .repeat max_font_height, line
        .addr   .ident (.sprintf ("unmasked_blit_line_%d", line))
        .endrepeat

masked_blit_line_table:
        .repeat max_font_height, line
        .addr   .ident (.sprintf ("masked_blit_line_%d", line))
        .endrepeat

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
        ldx     #.sizeof(MGTK::GrafPort)-1
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
        PARAM_BLOCK params, $82
switches:       .res 1
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
        ldy     #.sizeof(MGTK::GrafPort)-1 ; Store 36 bytes at params
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
        PARAM_BLOCK params, $82
flag:   .res 1
        END_PARAM_BLOCK

        lda     params::flag
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
        PARAM_BLOCK params, $82
flag:   .res 1
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
        .res    4                               ; Saved values of cursor_char..cursor_y2.

pointer_cursor:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0100000),px(%0000000)
        .byte   px(%0110000),px(%0000000)
        .byte   px(%0111000),px(%0000000)
        .byte   px(%0111100),px(%0000000)
        .byte   px(%0111110),px(%0000000)
        .byte   px(%0111111),px(%0000000)
        .byte   px(%0101100),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000011),px(%0000000)

        .byte   px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000)
        .byte   px(%1110000),px(%0000000)
        .byte   px(%1111000),px(%0000000)
        .byte   px(%1111100),px(%0000000)
        .byte   px(%1111110),px(%0000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%1111111),px(%1000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0000111),px(%1000000)
        .byte   px(%0000111),px(%1000000)

        .byte   1,1

pointer_cursor_addr:
        .addr   pointer_cursor

.proc set_pointer_cursor
        lda     #$FF
        sta     cursor_count
        lda     #0
        sta     cursor_flag
        lda     pointer_cursor_addr
        sta     params_addr
        lda     pointer_cursor_addr+1
        sta     params_addr+1
        ;; fall through
.endproc

;;; ============================================================
;;; SetCursor


.proc SetCursorImpl
        php
        sei
        ldax    params_addr
        stax    active_cursor
        clc
        adc     #MGTK::Cursor::mask
        bcc     :+
        inx
:       stax    active_cursor_mask

        ldy     #MGTK::Cursor::hotspot
        lda     (params_addr),y
        sta     cursor_hotspot_x
        iny
        lda     (params_addr),y
        sta     cursor_hotspot_y
        jsr     restore_cursor_background
        jsr     draw_cursor
        plp
.endproc
srts:   rts


        cursor_bytes      := $82
        cursor_softswitch := $83
        cursor_y1         := $84
        cursor_y2         := $85

        vid_ptr           := $88

.proc update_cursor
        lda     cursor_count           ; hidden? if so, skip
        bne     srts
        bit     cursor_flag
        bmi     srts
        ;; Fall-through
.endproc

.proc draw_cursor
        lda     #0
        sta     cursor_count
        sta     cursor_flag

        lda     set_pos_params::ycoord
        clc
        sbc     cursor_hotspot_y
        sta     cursor_y1
        clc
        adc     #MGTK::cursor_height
        sta     cursor_y2

        lda     set_pos_params::xcoord
        sec
        sbc     cursor_hotspot_x
        tax
        lda     set_pos_params::xcoord+1
        sbc     #0
        bpl     :+

        txa                            ; X-coord is negative: X-reg = X-coord + 256
        ror     a                      ; Will shift in zero:  X-reg = X-coord/2 + 128
        tax                            ; Negative mod7 table starts at 252 (since 252%7 = 0), and goes backwards
        ldy     mod7_table+252-128,x   ; Index (X-coord / 2 = X-reg - 128) relative to mod7_table+252
        lda     #$FF                   ; Char index = -1
        bmi     set_divmod

:       jsr     divmod7
set_divmod:
        sta     cursor_bytes            ; char index in line

        tya
        rol     a
        cmp     #7
        bcc     :+
        sbc     #7
:       tay

        lda     #<LOWSCR/2
        rol     a                      ; if mod >= 7, then will be HISCR, else LOWSCR
        eor     #1
        sta     cursor_softswitch      ; $C0xx softswitch index

        sty     cursor_mod7
        tya
        asl     a
        tay
        copy16  shift_table_main,y, cursor_shift_main_addr
        copy16  shift_table_aux,y, cursor_shift_aux_addr

        ldx     #3
:       lda     cursor_bytes,x
        sta     cursor_data,x
        dex
        bpl     :-

        ldx     #$17
        stx     left_bytes
        ldx     #$23
        ldy     cursor_y2
dloop:  cpy     #192
        bcc     :+
        jmp     drnext

:       lda     hires_table_lo,y
        sta     vid_ptr
        lda     hires_table_hi,y
        ora     #$20
        sta     vid_ptr+1
        sty     cursor_y2
        stx     left_mod14

        ldy     left_bytes
        ldx     #$01
:
active_cursor           := * + 1
        lda     $FFFF,y
        sta     cursor_bits,x
active_cursor_mask      := * + 1
        lda     $FFFF,y
        sta     cursor_mask,x
        dey
        dex
        bpl     :-
        lda     #0
        sta     cursor_bits+2
        sta     cursor_mask+2

        ldy     cursor_mod7
        beq     no_shift

        ldy     #5
:       ldx     cursor_bits-1,y

cursor_shift_main_addr           := * + 1
        ora     $FF80,x
        sta     cursor_bits,y

cursor_shift_aux_addr           := * + 1
        lda     $FF00,x
        dey
        bne     :-
        sta     cursor_bits

no_shift:
        ldx     left_mod14
        ldy     cursor_bytes
        lda     cursor_softswitch
        jsr     set_switch
        bcs     :+

        lda     (vid_ptr),y
        sta     cursor_savebits,x

        lda     cursor_mask
        ora     (vid_ptr),y
        eor     cursor_bits
        sta     (vid_ptr),y
        dex
:
        jsr     switch_page
        bcs     :+

        lda     (vid_ptr),y
        sta     cursor_savebits,x
        lda     cursor_mask+1

        ora     (vid_ptr),y
        eor     cursor_bits+1
        sta     (vid_ptr),y
        dex
:
        jsr     switch_page
        bcs     :+

        lda     (vid_ptr),y
        sta     cursor_savebits,x

        lda     cursor_mask+2
        ora     (vid_ptr),y
        eor     cursor_bits+2
        sta     (vid_ptr),y
        dex
:
        ldy     cursor_y2
drnext:
        dec     left_bytes
        dec     left_bytes
        dey
        cpy     cursor_y1
        beq     lowscr_rts
        jmp     dloop
.endproc
drts:   rts

active_cursor        := draw_cursor::active_cursor
active_cursor_mask   := draw_cursor::active_cursor_mask


.proc restore_cursor_background
        lda     cursor_count           ; already hidden?
        bne     drts
        bit     cursor_flag
        bmi     drts

        COPY_BYTES 4, cursor_data, cursor_bytes

        ldx     #$23
        ldy     cursor_y2
cloop:  cpy     #192
        bcs     cnext

        lda     hires_table_lo,y
        sta     vid_ptr
        lda     hires_table_hi,y
        ora     #$20
        sta     vid_ptr+1
        sty     cursor_y2

        ldy     cursor_bytes
        lda     cursor_softswitch
        jsr     set_switch
        bcs     :+
        lda     cursor_savebits,x
        sta     (vid_ptr),y
        dex
:
        jsr     switch_page
        bcs     :+
        lda     cursor_savebits,x
        sta     (vid_ptr),y
        dex
:
        jsr     switch_page
        bcs     :+
        lda     cursor_savebits,x
        sta     (vid_ptr),y
        dex
:
        ldy     cursor_y2
cnext:  dey
        cpy     cursor_y1
        bne     cloop
.endproc
lowscr_rts:
        sta     LOWSCR
        rts


.proc switch_page
        lda     set_switch_sta_addr
        eor     #1
        cmp     #<LOWSCR
        beq     set_switch
        iny
        ;; Fall through
.endproc

.proc set_switch
        sta     switch_sta_addr
switch_sta_addr := *+1
        sta     $C0FF
        cpy     #$28
        rts
.endproc

set_switch_sta_addr := set_switch::switch_sta_addr


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

.proc HideCursorImpl
        php
        sei
        jsr     restore_cursor_background
        dec     cursor_count
        plp
.endproc
mrts:   rts

;;; ============================================================

cursor_throttle:
        .byte   0

.proc move_cursor
        bit     use_interrupts
        bpl     :+

        lda     kbd_mouse_state
        bne     :+
        dec     cursor_throttle
        lda     cursor_throttle
        bpl     mrts
        lda     #2
        sta     cursor_throttle

:       ldx     #2
:       lda     mouse_x,x
        cmp     set_pos_params,x
        bne     mouse_moved
        dex
        bpl     :-
        bmi     no_move

mouse_moved:
        jsr     restore_cursor_background
        ldx     #2
        stx     cursor_flag
:       lda     mouse_x,x
        sta     set_pos_params,x
        dex
        bpl     :-
        jsr     update_cursor

no_move:
        bit     no_mouse_flag
        bmi     :+
        jsr     read_mouse_pos

:       bit     no_mouse_flag
        bpl     :+
        lda     #0
        sta     mouse_status

:       lda     kbd_mouse_state
        beq     rts4
        jsr     handle_keyboard_mouse
.endproc
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
.endproc


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
machine:    .res 1
subid:      .res 1
op_sys:     .res 1
slot_num:   .res 1
use_irq:    .res 1
sysfontptr: .res 2
savearea:   .res 2
savesize:   .res 2
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

        jsr     set_irq_mode
        jsr     set_op_sys

        ldy     #MGTK::Font::height
        lda     (params::sysfontptr),y
        tax
        stx     sysfont_height
        dex
        stx     goaway_height                 ; goaway height = font height - 1
        inx
        inx
        inx
        stx     fill_rect_params2_height      ; menu bar height = font height + 2

        inx
        stx     wintitle_height               ; win title height = font height + 3

        stx     test_rect_bottom
        stx     test_rect_params2_top
        stx     fill_rect_params4_top

        inx                                   ; font height + 4: top of desktop area
        stx     set_port_top
        stx     winframe_top
        stx     desktop_port_y
        stx     fill_rect_top

        dex
        stx     menu_item_y_table

        clc
        ldy     #$00
:       txa
        adc     menu_item_y_table,y
        iny
        sta     menu_item_y_table,y
        cpy     #menu_item_y_table_end - menu_item_y_table-1
        bcc     :-

        lda     #1
        sta     mouse_scale_x
        lda     #0
        sta     mouse_scale_y

        bit     subid
        bvs     :+

        lda     #2                       ; default scaling for IIc/IIc+
        sta     mouse_scale_x
        lda     #1
        sta     mouse_scale_y
:
        ldx     slot_num
        jsr     find_mouse

        bit     slot_num
        bpl     found_mouse
        cpx     #0
        bne     :+
        exit_call MGTK::Error::no_mouse

:       lda     slot_num
        and     #$7F
        beq     found_mouse
        cpx     slot_num
        beq     found_mouse
        exit_call $91

found_mouse:
        stx     slot_num

        lda     #$80
        sta     desktop_initialized_flag

        lda     slot_num
        bne     no_mouse
        bit     use_interrupts
        bpl     no_mouse
        lda     #0
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

no_irq: lda     VERSION
        pha

        lda     #F8VERSION           ; F8 ROM IIe ID byte
        sta     VERSION

        ldy     #SETMOUSE
        lda     #1

        bit     use_interrupts
        bpl     :+
        cli
        ora     #8
:       jsr     call_mouse

        pla
        sta     VERSION

        jsr     InitGrafImpl
        jsr     set_pointer_cursor
        jsr     FlushEventsImpl

        lda     #0
        sta     current_window+1

reset_desktop:
        jsr     save_params_and_stack
        jsr     set_desktop_port

        ;; Fills the desktop background on startup (menu left black)
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::PaintRect, fill_rect_params
        jmp     restore_params_active_port
.endproc

        DEFINE_ALLOC_INTERRUPT_PARAMS alloc_interrupt_params, interrupt_handler
        DEFINE_DEALLOC_INTERRUPT_PARAMS dealloc_interrupt_params


.proc set_irq_mode
        lda     #0
        sta     always_handle_irq

        lda     use_interrupts
        beq     irts

        cmp     #1
        beq     irq_on
        cmp     #3
        bne     irq_err

        lda     #$80
        sta     always_handle_irq
irq_on:
        lda     #$80
        sta     use_interrupts
irts:   rts

irq_err:
        exit_call MGTK::Error::invalid_irq_setting
.endproc

.proc set_op_sys
        lda     op_sys
        beq     is_prodos
        cmp     #1
        beq     is_pascal

        exit_call MGTK::Error::invalid_op_sys

is_prodos:
        lda     #$80
        sta     op_sys
is_pascal:
        rts
.endproc

;;; ============================================================
;;; StopDeskTop

.proc StopDeskTopImpl
        ldy     #SETMOUSE
        lda     #MOUSE_MODE_OFF
        jsr     call_mouse
        ldy     #SERVEMOUSE
        jsr     call_mouse
        bit     use_interrupts

        bpl     :+
        bit     op_sys
        bpl     :+
        lda     alloc_interrupt_params::int_num
        sta     dealloc_interrupt_params::int_num
        MLI_CALL DEALLOC_INTERRUPT, dealloc_interrupt_params
:
        lda     save_p_reg
        pha
        plp
        lda     #0
        sta     desktop_initialized_flag
        rts
.endproc

;;; ============================================================
;;; SetUserHook

;;; 3 bytes of params, copied to $82

.proc SetUserHookImpl
        PARAM_BLOCK params, $82
hook_id:        .res 1
routine_ptr:    .res 2
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
        exit_call MGTK::Error::invalid_hook
.endproc


.proc call_before_events_hook
        lda     before_events_hook+1
        beq     :+
        jsr     save_params_and_stack

        jsr     before_events_hook_jmp
        php
        jsr     restore_params_active_port
        plp
:       rts

before_events_hook_jmp:
        jmp     (before_events_hook)
.endproc


before_events_hook:
        .res    2


.proc call_after_events_hook
        lda     after_events_hook+1
        beq     :+
        jsr     save_params_and_stack

        jsr     after_events_hook_jmp
        php
        jsr     restore_params_active_port
        plp
:       rts

after_events_hook_jmp:
        jmp     (after_events_hook)
.endproc


after_events_hook:
        .res    2


params_addr_save:
        .res    2

stack_ptr_save:
        .res    1


.proc hide_cursor_save_params
        jsr     HideCursorImpl
        ;; Fall-through
.endproc

.proc save_params_and_stack
        copy16  params_addr, params_addr_save
        lda     stack_ptr_stash
        sta     stack_ptr_save
        lsr     preserve_zp_flag
        rts
.endproc


.proc show_cursor_and_restore
        jsr     ShowCursorImpl
        ;; Fall-through
.endproc

.proc restore_params_active_port
        asl     preserve_zp_flag
        copy16  params_addr_save, params_addr
        ldax    active_port
        ;; Fall-through
.endproc

.proc set_and_prepare_port
        stax    $82
        lda     stack_ptr_save
        sta     stack_ptr_stash

        ldy     #.sizeof(MGTK::GrafPort)-1
:       lda     ($82),y
        sta     current_grafport,y
        dey
        bpl     :-
        jmp     prepare_port
.endproc


.proc set_standard_port
        ldax    standard_port_addr
        bne     set_and_prepare_port                  ; always
.endproc

standard_port_addr:
        .addr   standard_port


.proc set_desktop_port
        jsr     set_standard_port
        MGTK_CALL MGTK::SetPortBits, desktop_port_bits
        rts

desktop_port_bits:
        .word   0               ; viewloc x
port_y:
        .word   13              ; viewloc y = font height + 4
        .word   $2000           ; mapbits
        .byte   $80             ; mapwidth
        .res    1               ; reserved
.endproc

desktop_port_y := set_desktop_port::port_y


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
        PARAM_BLOCK params, $82
hook:        .res 2
mouse_state: .res 2
        END_PARAM_BLOCK

        bit     desktop_initialized_flag
        bmi     fail

        copy16  params::hook, mouse_hook

        ldax    mouse_state_addr
        ldy     #2
        jmp     store_xa_at_y

fail:   exit_call MGTK::Error::desktop_already_initialized

mouse_state_addr:
        .addr   mouse_state
.endproc

;;; ============================================================
;;; PeekEvent

.proc PeekEventImpl
        clc
        bcc     GetEventImpl_peek_entry
.endproc


;;; ============================================================
;;; GetEvent

.proc GetEventImpl
        sec
peek_entry:
        php
        bit     use_interrupts
        bpl     :+
        sei
        bmi     no_check

:       jsr     CheckEventsImpl

no_check:
        jsr     next_event
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
        jsr     return_move_event

ret:    plp
        bit     use_interrupts
        bpl     :+
        cli
:       rts
.endproc

GetEventImpl_peek_entry := GetEventImpl::peek_entry


;;; ============================================================

;;; 5 bytes of params, copied to $82

.proc PostEventImpl
        PARAM_BLOCK params, $82
kind:   .byte    0
xcoord: .word    0           ; also used for key/modifiers/window id
ycoord: .word    0
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
        jsr     set_mouse_pos

event_ok:
        jsr     put_event
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
.endproc


        ;; Return a no_event (if mouse up) or drag event (if mouse down)
        ;; and report the current mouse position.
.proc return_move_event
        lda     #MGTK::EventKind::no_event

        bit     mouse_status
        bpl     :+
        lda     #MGTK::EventKind::drag

:       ldy     #0
        sta     (params_addr),y         ; Store 5 bytes at params
        iny
:       lda     set_pos_params-1,y
        sta     (params_addr),y
        iny
        cpy     #MGTK::event_size
        bne     :-
        rts
.endproc


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
        bit     use_interrupts
        bpl     irq_entry
        exit_call MGTK::Error::irq_in_use

irq_entry:
        sec                     ; called from interrupt handler
        jsr     call_before_events_hook
        bcc     end

        lda     BUTN1           ; Look at buttons (apple keys), compute modifiers
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        sta     input::modifiers

        jsr     activate_keyboard_mouse    ; check if keyboard mouse should be started
        jsr     move_cursor
        lda     mouse_status    ; bit 7 = is down, bit 6 = was down, still down
        asl     a
        eor     mouse_status
        bmi     :+              ; minus = (is down & !was down)

        bit     mouse_status
        bmi     end             ; minus = is down
        bit     check_kbd_flag
        bpl     :+
        lda     kbd_mouse_state
        bne     :+

        lda     KBD
        bpl     end             ; no key
        and     #CHAR_MASK
        sta     input::key
        bit     KBDSTRB         ; clear strobe

        lda     input::modifiers
        sta     input::kmods
        lda     #MGTK::EventKind::key_down
        sta     input::state
        bne     put_key_event   ; always

:       bcc     up
        lda     input::modifiers
        beq     :+
        lda     #MGTK::EventKind::apple_key
        bne     set_state

:       lda     #MGTK::EventKind::button_down
        bne     set_state

up:     lda     #MGTK::EventKind::button_up

set_state:
        sta     input::state

        COPY_BYTES 3, set_pos_params, input::key

put_key_event:
        jsr     put_event
        tax
        ldy     #0
:       lda     input,y
        sta     eventbuf,x
        inx
        iny
        cpy     #MGTK::short_event_size
        bne     :-

end:    jmp     call_after_events_hook
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

        COPY_BYTES 9, $82, int_stash_zp ; preserve 9 bytes of ZP

        ldy     #SERVEMOUSE
        jsr     call_mouse
        bcs     :+
        jsr     CheckEventsImpl::irq_entry
        clc
:       bit     always_handle_irq
        bpl     :+
        clc                     ; carry clear if interrupt handled

:       COPY_BYTES 9, int_stash_zp, $82 ; restore ZP

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
        ldax    int_handler_addr
        jmp     store_xa_at_params

int_handler_addr:
        .addr   interrupt_handler::body
.endproc

;;; ============================================================
;;; FlushEvents

;;; This is called during init by the DAs, just before
;;; entering the input loop.

eventbuf_tail:  .byte   0
eventbuf_head:  .byte   0

        eventbuf_size := 33             ; max # of events in queue

eventbuf:
        .scope  eventbuf
        kind      := *
        key       := *+1
        modifiers := *+2
        window_id := *+1
        .endscope

        .res    eventbuf_size*MGTK::short_event_size


.proc FlushEventsImpl
        php
        sei
        lda     #0
        sta     eventbuf_tail
        sta     eventbuf_head
        plp
        rts
.endproc
        ;; called during PostEvent and a few other places
.proc put_event
        lda     eventbuf_head
        cmp     #(eventbuf_size-1)*MGTK::short_event_size
        bne     :+                      ; if head is not at end, advance
        lda     #0                      ; otherwise reset to 0
        bcs     compare
:       clc
        adc     #MGTK::short_event_size

compare:
        cmp     eventbuf_tail           ; did head catch up with tail?
        beq     rts_with_carry_set
        sta     eventbuf_head           ; nope, maybe next time
        clc
        rts
.endproc

rts_with_carry_set:
        sec
        rts

        ;; called during GetEvent
.proc next_event
        lda     eventbuf_tail           ; equal?
        cmp     eventbuf_head
        beq     rts_with_carry_set
        cmp     #$80
        bne     :+
        lda     #0
        bcs     ret                     ; always

:       clc
        adc     #MGTK::short_event_size
ret:    clc
        rts
.endproc


;;; ============================================================
;;; SetKeyEvent

;;; 1 byte of params, copied to $82

check_kbd_flag:  .byte   $80

.proc SetKeyEventImpl
        PARAM_BLOCK params, $82
handle_keys:    .res    1
        END_PARAM_BLOCK

        asl     check_kbd_flag
        ror     params::handle_keys
        ror     check_kbd_flag
        rts
.endproc

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

savebehind_buffer:
        .word   0

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
menu_item_y_table_end:

menu_glyphs:
solid_apple_glyph:
        .byte   $1E
open_apple_glyph:
        .byte   $1F
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

test_rect_params_addr:
        .addr   test_rect_params

test_rect_params2_addr:
        .addr   test_rect_params2

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
menu_id:    .byte  0
disabled:   .byte  0
title:      .addr  0
menu_items: .addr  0

        ;; Reserved area in menu
x_penloc:  .word   0
x_min:     .word   0
x_max:     .word   0
        END_PARAM_BLOCK


        PARAM_BLOCK curmenuinfo, $BB
        ;; Reserved area before first menu item
x_min:     .word   0
x_max:     .word   0
        END_PARAM_BLOCK


        PARAM_BLOCK curmenuitem, $BF
        ;; Public members
options:   .byte   0
mark_char: .byte   0
shortcut1: .byte   0
shortcut2: .byte   0
name:      .addr   0
        END_PARAM_BLOCK


.proc get_menu_count
        copy16  active_menu, $82
        ldy     #0
        lda     ($82),y
        sta     menu_count
        rts
.endproc


.proc get_menu
        stx     menu_index
        lda     #2
        clc
:       dex
        bmi     :+
        adc     #12
        bne     :-

:       adc     active_menu
        sta     menu_ptr
        lda     active_menu+1
        adc     #0
        sta     menu_ptr+1

        ldy     #.sizeof(MGTK::MenuBarItem)-1
:       lda     (menu_ptr),y
        sta     curmenu,y
        dey
        bpl     :-

        ldy     #.sizeof(MGTK::MenuItem)-1
:       lda     (curmenu::menu_items),y
        sta     curmenuinfo-1,y
        dey
        bne     :-

        lda     (curmenu::menu_items),y
        sta     menu_item_count
        rts
.endproc


.proc put_menu
        ldy     #.sizeof(MGTK::MenuBarItem)-1
:       lda     curmenu,y
        sta     (menu_ptr),y
        dey
        bpl     :-

        ldy     #.sizeof(MGTK::MenuItem)-1
:       lda     curmenuinfo-1,y
        sta     (curmenu::menu_items),y
        dey
        bne     :-
        rts
.endproc


.proc get_menu_item
        stx     menu_item_index
        lda     #.sizeof(MGTK::MenuItem)
        clc
:       dex
        bmi     :+
        adc     #.sizeof(MGTK::MenuItem)
        bne     :-
:
        adc     curmenu::menu_items
        sta     menu_item_ptr
        lda     curmenu::menu_items+1
        adc     #0
        sta     menu_item_ptr+1

        ldy     #.sizeof(MGTK::MenuItem)-1
:       lda     (menu_item_ptr),y
        sta     curmenuitem,y
        dey
        bpl     :-
        rts
.endproc


.proc put_menu_item
        ldy     #.sizeof(MGTK::MenuItem)-1
:       lda     curmenuitem,y
        sta     (menu_item_ptr),y
        dey
        bpl     :-
        rts
.endproc


        ;; Set penloc to X=AX, Y=Y
.proc set_penloc
        sty     current_penloc_y
        ldy     #0
        sty     current_penloc_y+1
set_x:  stax    current_penloc_x
        rts
.endproc

        ;; Set fill mode to A
.proc set_fill_mode
        sta     current_penmode
        jmp     SetPenModeImpl
.endproc

.proc do_measure_text
        jsr     prepare_text_params
        jmp     measure_text
.endproc

.proc draw_text
        jsr     prepare_text_params
        jmp     DrawTextImpl
.endproc

        ;; Prepare $A1,$A2 as params for TextWidth/DrawText call
        ;; ($A3 is length)
.proc prepare_text_params
        temp_ptr := $82

        stax    temp_ptr
        clc
        adc     #1
        bcc     :+
        inx
:       stax    measure_text::data
        ldy     #0
        lda     (temp_ptr),y
        sta     measure_text::length
        rts
.endproc

.proc get_and_return_event
        PARAM_BLOCK event, $82
kind:      .byte   0
mouse_pos:
mouse_x:   .word  0
mouse_y:   .word  0
        END_PARAM_BLOCK

        MGTK_CALL MGTK::GetEvent, event
        return  event
.endproc


;;; ============================================================
;;; SetMenu

need_savebehind:
        .res    2

.proc SetMenuImpl
        temp      := $82
        max_width := $C5

        lda     #0
        sta     savebehind_usage
        sta     savebehind_usage+1
        copy16  params_addr, active_menu

        jsr     get_menu_count  ; into menu_count
        jsr     hide_cursor_save_params
        jsr     set_standard_port

        ldax    test_rect_params_addr
        jsr     fill_and_frame_rect

        ldax    #12
        ldy     sysfont_height
        iny
        jsr     set_penloc

        ldx     #0
menuloop:
        jsr     get_menu
        ldax    current_penloc_x
        stax    curmenu::x_penloc

        sec
        sbc     #8
        bcs     :+
        dex
:       stax    curmenu::x_min
        stax    curmenuinfo::x_min

        ldx     #0
        stx     max_width
        stx     max_width+1

itemloop:
        jsr     get_menu_item
        bit     curmenuitem::options
        bvs     filler                  ; bit 6 - is filler

        ldax    curmenuitem::name
        jsr     do_measure_text
        stax    temp

        lda     curmenuitem::options
        and     #3                      ; OA+SA
        bne     :+
        lda     curmenuitem::shortcut1
        bne     :+
        lda     shortcut_x_adj
        bne     has_shortcut

:       lda     non_shortcut_x_adj
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
        bmi     :+
        copy16  temp, max_width          ; calculate max width
:
filler: ldx     menu_item_index
        inx
        cpx     menu_item_count
        bne     itemloop

        lda     menu_item_count
        tax
        ldy     sysfont_height
        iny
        iny
        iny
        jsr     mult_x_y                ; num items * (sysfont_height+3)
        pha

        copy16  max_width, fixed_div::dividend
        copy16  #7, fixed_div::divisor
        jsr     fixed_div               ; max width / 7

        ldy     fixed_div::quotient+2
        iny
        iny
        pla
        tax
        jsr     mult_x_y                ; total height * ((max width / 7)+2)

        sta     need_savebehind
        sty     need_savebehind+1
        sec
        sbc     savebehind_usage
        tya
        sbc     savebehind_usage+1
        bmi     :+
        copy16  need_savebehind, savebehind_usage     ; calculate max savebehind data needed

:       add16_8 curmenuinfo::x_min, max_width, curmenuinfo::x_max

        jsr     put_menu

        ldax    curmenu::title
        jsr     draw_text
        jsr     get_menu_and_menu_item

        ldax    current_penloc_x
        clc
        adc     #8
        bcc     :+
        inx
:       stax    curmenu::x_max

        jsr     put_menu

        ldax    #12
        jsr     adjust_xpos

        ldx     menu_index
        inx
        cpx     menu_count
        beq     :+
        jmp     menuloop

:       lda     #0
        sta     sel_menu_index
        sta     sel_menu_item_index

        jsr     show_cursor_and_restore
        sec
        lda     savebehind_size
        sbc     savebehind_usage
        lda     savebehind_size+1
        sbc     savebehind_usage+1
        bpl     :+
        exit_call MGTK::Error::insufficient_savebehind_area

:       rts
.endproc


.proc get_menu_and_menu_item
        ldx     menu_index
        jsr     get_menu

        ldx     menu_item_index
        jmp     get_menu_item
.endproc


        ;; Fills rect (params at X,A) then inverts border
.proc fill_and_frame_rect
        stax    fill_params
        stax    draw_params
        lda     #MGTK::pencopy
        jsr     set_fill_mode
        MGTK_CALL MGTK::PaintRect, 0, fill_params
        lda     #MGTK::notpencopy
        jsr     set_fill_mode
        MGTK_CALL MGTK::FrameRect, 0, draw_params
        rts
.endproc


.proc find_menu_by_id_or_fail
        jsr     find_menu_by_id
        bne     :+
        exit_call MGTK::Error::menu_not_found
:       rts
.endproc


        find_mode             := $C6

        find_mode_by_id       := $00        ; find menu/menu item by id
        find_menu_id          := $C7
        find_menu_item_id     := $C8

        find_mode_by_coord    := $80        ; find menu by x-coord/menu item by y-coord
                                            ; coordinate is in set_pos_params

        find_mode_by_shortcut := $C0        ; find menu and menu item by shortcut key
        find_shortcut         := $C9
        find_options          := $CA


.proc find_menu_by_id
        lda     #find_mode_by_id
find_menu:
        sta     find_mode

        jsr     get_menu_count
        ldx     #0
loop:   jsr     get_menu
        bit     find_mode
        bvs     find_menu_item_mode
        bmi     :+

        lda     curmenu::menu_id          ; search by menu id
        cmp     find_menu_id
        bne     next
        beq     found

:       ldax    set_pos_params::xcoord    ; search by x coordinate bounds
        cpx     curmenu::x_min+1
        bcc     next
        bne     :+
        cmp     curmenu::x_min
        bcc     next
:       cpx     curmenu::x_max+1
        bcc     found
        bne     next
        cmp     curmenu::x_max
        bcc     found
        bcs     next

find_menu_item_mode:
        jsr     find_menu_item
        bne     found

next:   ldx     menu_index
        inx
        cpx     menu_count
        bne     loop
        return  #0

found:  return  curmenu::menu_id
.endproc

find_menu := find_menu_by_id::find_menu


.proc find_menu_item
        ldx     #0
loop:   jsr     get_menu_item
        ldx     menu_item_index
        inx
        bit     find_mode
        bvs     find_by_shortcut
        bmi     :+

        cpx     find_menu_item_id
        bne     next
        beq     found

:       lda     menu_item_y_table,x
        cmp     set_pos_params::ycoord
        bcs     found
        bcc     next

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
.endproc


;;; ============================================================
;;; HiliteMenu

;;; 2 bytes of params, copied to $C7

.proc HiliteMenuImpl
        menu_param := $C7

        lda     menu_param
        bne     :+
        lda     cur_open_menu
        sta     menu_param

:       jsr     find_menu_by_id_or_fail

do_hilite:
        jsr     hide_cursor_save_params
        jsr     set_standard_port
        jsr     hilite_menu
        jmp     show_cursor_and_restore
.endproc

        ;; Highlight/Unhighlight top level menu item
.proc hilite_menu
        ldx     #1
loop:   lda     curmenu::x_min,x
        sta     fill_rect_params2::left,x
        lda     curmenu::x_max,x
        sta     fill_rect_params2::width,x

        lda     curmenuinfo::x_min,x
        sta     test_rect_params2::left,x
        sta     fill_rect_params4::left,x

        lda     curmenuinfo::x_max,x
        sta     test_rect_params2::right,x
        sta     fill_rect_params4::right,x

        dex
        bpl     loop

        lda     #MGTK::penXOR
        jsr     set_fill_mode
        MGTK_CALL MGTK::PaintRect, fill_rect_params2
        rts
.endproc

;;; ============================================================
;;; MenuKey

;;; 4 bytes of params, copied to $C7

.proc MenuKeyImpl
        PARAM_BLOCK params, $C7
menu_id:   .byte   0
menu_item: .byte   0
which_key: .byte   0
key_mods:  .byte   0
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
        sta     cur_open_menu
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
.endproc


.proc find_menu_and_menu_item
        jsr     find_menu_by_id_or_fail
        jsr     find_menu_item
        cpx     #0
.endproc
rrts:   rts

.proc find_menu_item_or_fail
        jsr     find_menu_and_menu_item
        bne     rrts
        exit_call MGTK::Error::menu_item_not_found
.endproc


;;; ============================================================
;;; DisableItem

;;; 3 bytes of params, copied to $C7

.proc DisableItemImpl
        PARAM_BLOCK params, $C7
menu_id:   .byte   0
menu_item: .byte   0
disable:   .byte   0
        END_PARAM_BLOCK


        jsr     find_menu_item_or_fail

        asl     curmenuitem::options
        ror     params::disable
        ror     curmenuitem::options

        jmp     put_menu_item
.endproc

;;; ============================================================
;;; CheckItem

;;; 3 bytes of params, copied to $C7

.proc CheckItemImpl
        PARAM_BLOCK params, $C7
menu_id:   .byte   0
menu_item: .byte   0
check:     .byte   0
        END_PARAM_BLOCK


        jsr     find_menu_item_or_fail

        lda     params::check
        beq     :+
        lda     #MGTK::MenuOpt::item_is_checked
        ora     curmenuitem::options
        bne     set_options            ; always

:       lda     #$FF^MGTK::MenuOpt::item_is_checked
        and     curmenuitem::options
set_options:
        sta     curmenuitem::options
        jmp     put_menu_item
.endproc

;;; ============================================================
;;; DisableMenu

;;; 2 bytes of params, copied to $C7

.proc DisableMenuImpl
        PARAM_BLOCK params, $C7
menu_id:   .byte   0
disable:   .byte   0
        END_PARAM_BLOCK


        jsr     find_menu_by_id_or_fail

        asl     curmenu::disabled
        ror     params::disable
        ror     curmenu::disabled

        ldx     menu_index
        jmp     put_menu
.endproc

;;; ============================================================
;;; MenuSelect

cur_open_menu:
        .byte   0

cur_hilited_menu_item:
        .byte   0

.proc MenuSelectImpl
        PARAM_BLOCK params, $C7
menu_id:   .byte   0
menu_item: .byte   0
        END_PARAM_BLOCK


        jsr     kbd_mouse_init_tracking

        jsr     get_menu_count
        jsr     save_params_and_stack
        jsr     set_standard_port

        bit     kbd_mouse_state
        bpl     :+
        jsr     kbd_menu_select
        jmp     in_menu

:       lda     #0
        sta     cur_open_menu
        sta     cur_hilited_menu_item
        jsr     get_and_return_event
event_loop:
        bit     movement_cancel
        bpl     :+
        jmp     kbd_menu_return

:       MGTK_CALL MGTK::MoveTo, get_and_return_event::event::mouse_pos
        MGTK_CALL MGTK::InRect, test_rect_params      ; test in menu bar
        bne     in_menu_bar
        lda     cur_open_menu
        beq     in_menu

        MGTK_CALL MGTK::InRect, test_rect_params2     ; test in menu
        bne     in_menu_item
        jsr     unhilite_cur_menu_item

in_menu:jsr     get_and_return_event
        beq     :+
        cmp     #MGTK::EventKind::button_up
        bne     event_loop

:       lda     cur_hilited_menu_item
        bne     :+
        jsr     hide_menu
        jmp     restore

:       jsr     HideCursorImpl
        jsr     set_standard_port
        jsr     restore_menu_savebehind

restore:jsr     restore_params_active_port
        lda     #0

        ldx     cur_hilited_menu_item
        beq     :+

        lda     cur_open_menu
        ldy     menu_index             ; ???
        sty     sel_menu_index
        stx     sel_menu_item_index

:       jmp     store_xa_at_params


in_menu_bar:
        jsr     unhilite_cur_menu_item

        lda     #find_mode_by_coord
        jsr     find_menu

        cmp     cur_open_menu
        beq     in_menu
        pha
        jsr     hide_menu
        pla
        sta     cur_open_menu

        jsr     draw_menu
        jmp     in_menu


in_menu_item:
        lda     #find_mode_by_coord
        sta     find_mode
        jsr     find_menu_item
        cpx     cur_hilited_menu_item
        beq     in_menu

        lda     curmenu::disabled
        ora     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
        beq     :+

        ldx     #0
:       txa
        pha
        jsr     hilite_menu_item
        pla
        sta     cur_hilited_menu_item
        jsr     hilite_menu_item

        jmp     in_menu
.endproc


        savebehind_left_bytes := $82
        savebehind_bottom := $83

        savebehind_buf_addr := $8E
        savebehind_vid_addr := $84
        savebehind_mapwidth := $90


.proc set_up_savebehind
        lda     curmenuinfo::x_min+1
        lsr     a
        lda     curmenuinfo::x_min
        ror     a
        tax
        lda     div7_table,x
        sta     savebehind_left_bytes

        lda     curmenuinfo::x_max+1
        lsr     a
        lda     curmenuinfo::x_max
        ror     a
        tax
        lda     div7_table,x
        sec
        sbc     savebehind_left_bytes
        sta     savebehind_mapwidth

        copy16  savebehind_buffer, savebehind_buf_addr

        ldy     menu_item_count
        ldx     menu_item_y_table,y ; ???
        inx
        stx     savebehind_bottom
        stx     fill_rect_params4::bottom
        stx     test_rect_params2::bottom

        ldx     sysfont_height
        inx
        inx
        inx
        stx     fill_rect_params4::top
        stx     test_rect_params2::top
        rts
.endproc


.proc savebehind_get_vidaddr
        lda     hires_table_lo,x
        clc
        adc     savebehind_left_bytes
        sta     savebehind_vid_addr
        lda     hires_table_hi,x
        ora     #$20
        sta     savebehind_vid_addr+1
        rts
.endproc


.proc savebehind_next_line
        lda     savebehind_buf_addr
        sec
        adc     savebehind_mapwidth
        sta     savebehind_buf_addr
        bcc     :+
        inc     savebehind_buf_addr+1
:       rts
.endproc


.proc restore_menu_savebehind
        jsr     set_up_savebehind
loop:   jsr     savebehind_get_vidaddr
        sta     HISCR

        ldy     savebehind_mapwidth
:       lda     (savebehind_buf_addr),y
        sta     (savebehind_vid_addr),y
        dey
        bpl     :-
        jsr     savebehind_next_line
        sta     LOWSCR

        ldy     savebehind_mapwidth
:       lda     (savebehind_buf_addr),y
        sta     (savebehind_vid_addr),y
        dey
        bpl     :-
        jsr     savebehind_next_line

        inx
        cpx     savebehind_bottom
        bcc     loop
        beq     loop
        jmp     ShowCursorImpl
.endproc


dmrts:  rts


.proc hide_menu
        clc
        bcc     draw_menu_draw_or_hide
.endproc


.proc draw_menu
        sec
draw_or_hide:
        lda     cur_open_menu
        beq     dmrts
        php

        sta     find_menu_id
        jsr     find_menu_by_id
        jsr     HideCursorImpl
        jsr     hilite_menu

        plp
        bcc     restore_menu_savebehind

        jsr     set_up_savebehind
saveloop:
        jsr     savebehind_get_vidaddr
        sta     HISCR

        ldy     savebehind_mapwidth
:       lda     (savebehind_vid_addr),y
        sta     (savebehind_buf_addr),y
        dey
        bpl     :-
        jsr     savebehind_next_line
        sta     LOWSCR

        ldy     savebehind_mapwidth
:       lda     (savebehind_vid_addr),y
        sta     (savebehind_buf_addr),y
        dey
        bpl     :-
        jsr     savebehind_next_line

        inx
        cpx     savebehind_bottom
        bcc     saveloop
        beq     saveloop

        jsr     set_standard_port

        ldax    test_rect_params2_addr
        jsr     fill_and_frame_rect
        inc16   fill_rect_params4::left
        lda     fill_rect_params4::right
        bne     :+
        dec     fill_rect_params4::right+1
:       dec     fill_rect_params4::right

        jsr     get_menu_and_menu_item

        ldx     #0
loop:   jsr     get_menu_item
        bit     curmenuitem::options
        bvc     :+
        jmp     next

:       lda     curmenuitem::options
        and     #MGTK::MenuOpt::item_is_checked
        beq     no_mark

        lda     offset_checkmark
        jsr     moveto_menuitem

        lda     checkmark_glyph
        sta     mark_text+1

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::item_has_mark
        beq     :+
        lda     curmenuitem::mark_char
        sta     mark_text+1

:       ldax    mark_text_addr
        jsr     draw_text
        jsr     get_menu_and_menu_item

no_mark:
        lda     offset_text
        jsr     moveto_menuitem

        ldax    curmenuitem::name
        jsr     draw_text

        jsr     get_menu_and_menu_item
        lda     curmenuitem::options
        and     #MGTK::MenuOpt::open_apple | MGTK::MenuOpt::solid_apple
        bne     oa_sa

        lda     curmenuitem::shortcut1
        beq     no_shortcut

        lda     controlkey_glyph
        sta     shortcut_text+1
        jmp     no_shortcut

oa_sa:  cmp     #MGTK::MenuOpt::open_apple
        bne     :+
        lda     open_apple_glyph
        sta     shortcut_text+1
        jmp     shortcut

:       lda     solid_apple_glyph
        sta     shortcut_text+1

shortcut:
        lda     curmenuitem::shortcut1
        sta     shortcut_text+2

        lda     offset_shortcut
        jsr     moveto_fromright

        ldax    shortcut_text_addr
        jsr     draw_text
        jsr     get_menu_and_menu_item

no_shortcut:
        bit     curmenu::disabled
        bmi     :+
        bit     curmenuitem::options
        bpl     next

:       jsr     dim_menuitem
        jmp     next                   ; useless jmp ???

next:   ldx     menu_item_index
        inx
        cpx     menu_item_count
        beq     :+
        jmp     loop
:       jmp     ShowCursorImpl
.endproc


.proc moveto_menuitem
        ldx     menu_item_index
        ldy     menu_item_y_table+1,x ; ???
        dey
        ldx     curmenuinfo::x_min+1
        clc
        adc     curmenuinfo::x_min
        bcc     :+
        inx
:       jmp     set_penloc
.endproc


.proc dim_menuitem
        ldx     menu_item_index
        lda     menu_item_y_table,x
        sta     fill_rect_params3_top
        inc     fill_rect_params3_top
        lda     menu_item_y_table+1,x
        sta     fill_rect_params3_bottom

        add16lc curmenuinfo::x_min, #5, fill_rect_params3_left
        sub16lc curmenuinfo::x_max, #5, fill_rect_params3_right

        MGTK_CALL MGTK::SetPattern, light_speckle_pattern

        lda     #MGTK::penOR
        jsr     set_fill_mode

        MGTK_CALL MGTK::PaintRect, fill_rect_params3
        MGTK_CALL MGTK::SetPattern, standard_port::penpattern

        lda     #MGTK::penXOR
        jsr     set_fill_mode
        rts
.endproc

draw_menu_draw_or_hide := draw_menu::draw_or_hide


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


        ;; Move to the given distance from the right side of the menu.
.proc moveto_fromright
        sta     $82
        ldax    curmenuinfo::x_max
        sec
        sbc     $82
        bcs     :+
        dex
:       jmp     set_penloc::set_x
.endproc

.proc unhilite_cur_menu_item
        jsr     hilite_menu_item
        lda     #0
        sta     cur_hilited_menu_item
.endproc
hmrts:  rts

.proc hilite_menu_item
        ldx     cur_hilited_menu_item
        beq     hmrts
        ldy     menu_item_y_table-1,x
        iny
        sty     fill_rect_params4::top
        ldy     menu_item_y_table,x
        sty     fill_rect_params4::bottom
        jsr     HideCursorImpl

        lda     #MGTK::penXOR
        jsr     set_fill_mode
        MGTK_CALL MGTK::PaintRect, fill_rect_params4
        jmp     ShowCursorImpl
.endproc

;;; ============================================================
;;; InitMenu

;;; 4 bytes of params, copied to $82

.proc InitMenuImpl
        PARAM_BLOCK params, $82
solid_char:     .res    1
open_char:      .res    1
check_char:     .res    1
control_char:   .res    1
        END_PARAM_BLOCK

        COPY_BYTES 4, params, menu_glyphs

        copy16  standard_port::textfont, params
        ldy     #0
        lda     (params),y
        bmi     :+                    ; branch if double-width font

        lda     #2
        sta     offset_checkmark
        lda     #9
        sta     offset_text
        lda     #16
        sta     offset_shortcut
        lda     #9
        sta     shortcut_x_adj
        lda     #30
        sta     non_shortcut_x_adj
        bne     end

:       lda     #2
        sta     offset_checkmark
        lda     #16
        sta     offset_text
        lda     #30
        sta     offset_shortcut
        lda     #16
        sta     shortcut_x_adj
        lda     #51
        sta     non_shortcut_x_adj
end:    rts
.endproc

;;; ============================================================
;;; SetMark

;;; 4 bytes of params, copied to $C7

.proc SetMarkImpl
        PARAM_BLOCK params, $C7
menu_id:   .byte   0
menu_item: .byte   0
set_char:  .byte   0
mark_char: .byte   0
        END_PARAM_BLOCK


        jsr     find_menu_item_or_fail

        lda     params::set_char
        beq     :+

        lda     #MGTK::MenuOpt::item_has_mark
        ora     curmenuitem::options
        sta     curmenuitem::options

        lda     params::mark_char
        sta     curmenuitem::mark_char
        jmp     put_menu_item

:       lda     #$FF^MGTK::MenuOpt::item_has_mark
        and     curmenuitem::options
        sta     curmenuitem::options
        jmp     put_menu_item
.endproc


icon_offset_pos    := 0
icon_offset_width  := 4
icon_offset_height := 5
icon_offset_bits   := 6


.proc up_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   19,10
        .addr   up_scroll_bitmap
.endproc

.proc down_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   19,10
        .addr   down_scroll_bitmap
.endproc

.proc left_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   20,9
        .addr   left_scroll_bitmap
.endproc

.proc right_scroll_params
xcoord: .res    2
ycoord: .res    2
        .byte   18,9
        .addr   right_scroll_bitmap
.endproc

.proc resize_box_params
xcoord: .res    2
ycoord: .res    2
        .byte   20,10
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

        .byte   0         ; unreferenced ???

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
id:        .byte   0
options:   .byte   0
title:     .addr   0
hscroll:   .byte   0
vscroll:   .byte   0
hthumbmax: .byte   0
hthumbpos: .byte   0
vthumbmax: .byte   0
vthumbpos: .byte   0
status:    .byte   0
reserved:  .byte   0
        END_PARAM_BLOCK


        ;; First 16 bytes of win's grafport only
        PARAM_BLOCK current_winport, $B7
.proc viewloc
xcoord:    .word   0
ycoord:    .word   0
.endproc

mapbits:   .addr   0
mapwidth:  .byte   0
           .byte   0

.proc maprect
x1:        .word   0
y1:        .word   0
x2:        .word   0
y2:        .word   0
.endproc
        END_PARAM_BLOCK


        PARAM_BLOCK winrect, $C7
x1:        .word   0
y1:        .word   0
x2:        .word   0
y2:        .word   0
        END_PARAM_BLOCK


        ;; Start window enumeration at top ???
.proc top_window
        copy16  root_window_addr, previous_window
        ldax    current_window
        bne     set_found_window
end:    rts
.endproc

        ;; Look up next window in chain. $A9/$AA will point at
        ;; window params block (also returned in X,A).
.proc next_window
        copy16  window, previous_window
        ldy     #MGTK::Winfo::nextwinfo+1
        lda     (window),y
        beq     top_window::end  ; if high byte is 0, end of chain
        tax
        dey
        lda     (window),y
set_found_window:
        stax    found_window
        ;; Fall-through
.endproc

        ;; Load/refresh the ZP window data areas at $AB and $B7.
.proc get_window
        ldax    found_window
get_from_ax:
        stax    window

        ldy     #11             ; copy first 12 bytes of window defintion to
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
        ldax    window
        rts
.endproc
        set_found_window := next_window::set_found_window


        ;; Look up window state by id (in $82); $A9/$AA will point at
        ;; winfo (also X,A).
.proc window_by_id
        jsr     top_window
        beq     end
loop:   lda     current_winfo::id
        cmp     $82
        beq     get_window::return_window
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
nope:   exit_call MGTK::Error::window_not_found
.endproc


frame_winrect:
        MGTK_CALL MGTK::FrameRect, winrect
        rts

in_winrect:
        MGTK_CALL MGTK::InRect, winrect
        rts

        ;; Retrieve the rectangle of the current window and put it in winrect.
        ;;
        ;; The rectangle is defined by placing the top-left corner at the viewloc
        ;; of the window and setting the width and height matching the width
        ;; and height of the maprect of the window's port.
        ;;
.proc get_winrect
        COPY_BLOCK current_winport::viewloc, winrect ; copy viewloc to left/top of winrect

        ldx     #2
:       lda     current_winport::maprect::x2,x ; x2/y2
        sec
        sbc     current_winport::maprect::x1,x ; x1/y1
        tay
        lda     current_winport::maprect::x2+1,x
        sbc     current_winport::maprect::x1+1,x
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
        ;; Fall-through
.endproc
return_winrect:
        ldax    #winrect
        rts


        ;; Return the window's rect including framing: title bar and scroll
        ;; bars.
.proc get_winframerect
        jsr     get_winrect
        lda     winrect
        bne     :+
        dec     winrect+1
:       dec     winrect

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
.endproc


.proc get_win_vertscrollrect
        jsr     get_winframerect
        ldax    winrect::x2
        sec
        sbc     #$14
        bcs     :+
        dex
:       stax    winrect::x1

        lda     current_winfo::options
        and     #MGTK::Option::dialog_box
        bne     return_winrect

        lda     winrect::y1
        clc
        adc     wintitle_height
        sta     winrect::y1
        bcc     return_winrect
        inc     winrect::y1+1
        bcs     return_winrect
.endproc


.proc get_win_horizscrollrect
        jsr     get_winframerect
get_rect:
        ldax    winrect::y2
        sec
        sbc     #$0A
        bcs     :+
        dex
:       stax    winrect::y1
        jmp     return_winrect
.endproc


.proc get_win_growboxrect
        jsr     get_win_vertscrollrect
        jmp     get_win_horizscrollrect::get_rect
.endproc


.proc get_wintitlebar_rect
        jsr     get_winframerect

        lda     winrect::y1
        clc
        adc     wintitle_height
        sta     winrect::y2
        lda     winrect::y1+1
        adc     #0
        sta     winrect::y2+1

        jmp     return_winrect
.endproc


.proc get_wingoaway_rect
        jsr     get_wintitlebar_rect

        ldax    winrect::x1
        clc
        adc     #12
        bcc     :+
        inx
:       stax    winrect::x1
        clc
        adc     #14
        bcc     :+
        inx
:       stax    winrect::x2

        ldax    winrect::y1
        clc
        adc     #2
        bcc     :+
        inx
:       stax    winrect::y1
        clc
        adc     goaway_height
        bcc     :+
        inx
:       stax    winrect::y2

        jmp     return_winrect
.endproc


.proc draw_window
        jsr     get_winframerect
        jsr     fill_and_frame_rect

        lda     current_winfo::options
        and     #MGTK::Option::dialog_box
        bne     no_titlebar

        jsr     get_wintitlebar_rect
        jsr     fill_and_frame_rect
        jsr     center_title_text

        ldax    current_winfo::title
        jsr     draw_text

no_titlebar:
        jsr     get_window

        bit     current_winfo::vscroll
        bpl     no_vert_scroll

        jsr     get_win_vertscrollrect
        jsr     frame_winrect

no_vert_scroll:
        bit     current_winfo::hscroll
        bpl     :+

        jsr     get_win_horizscrollrect
        jsr     frame_winrect

:       lda     current_winfo::options
        and     #MGTK::Option::grow_box
        beq     :+

        jsr     get_win_growboxrect
        jsr     frame_winrect
        jsr     get_win_vertscrollrect
        jsr     frame_winrect

:       jsr     get_window

        lda     current_winfo::id
        cmp     sel_window_id
        bne     :+

        jsr     set_desktop_port
        jmp     draw_winframe
:       rts
.endproc

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


.proc set_stripes_pattern
        jsr     get_wingoaway_rect
        lda     winrect::y1
        and     #1
        beq     :+
        MGTK_CALL MGTK::SetPattern, stripes_pattern
        rts

:       MGTK_CALL MGTK::SetPattern, stripes_pattern_alt
        rts
.endproc


.proc erase_winframe
        lda     #MGTK::penOR
        ldx     #0
        beq     :+
.endproc

.proc draw_winframe
        lda     #MGTK::penBIC
        ldx     #1

:       stx     draw_erase_mode
        jsr     set_fill_mode

        lda     current_winfo::options
        and     #MGTK::Option::go_away_box
        beq     no_goaway

        lda     current_winfo::options
        and     #MGTK::Option::dialog_box
        bne     no_goaway

        jsr     get_wingoaway_rect
        jsr     frame_winrect
        jsr     set_stripes_pattern

        ldax    winrect::x1
        sec
        sbc     #9
        bcs     :+
        dex
:       stax    left

        clc
        adc     #6
        bcc     :+
        inx
:       stax    right

        copy16  winrect::y1, top
        copy16  winrect::y2, bottom

        jsr     PaintRectImpl  ; draws title bar stripes to left of close box

no_goaway:
        lda     current_winfo::options
        and     #MGTK::Option::dialog_box
        bne     no_titlebar

        jsr     get_wintitlebar_rect
        jsr     center_title_text
        jsr     penloc_to_bounds
        jsr     set_stripes_pattern

        ldax    winrect::x2
        clc
        adc     #3
        bcc     :+
        inx
:       tay

        lda     current_winfo::options
        and     #MGTK::Option::go_away_box
        bne     has_goaway

        tya
        sec
        sbc     #$1A
        bcs     :+
        dex
:       tay

has_goaway:
        tya
        ldy     right
        sty     winrect::x2
        ldy     right+1
        sty     winrect::x2+1

        ldy     left
        sty     right
        ldy     left+1
        sty     right+1

        stax    left

        lda     right
        sec
        sbc     #10
        sta     right
        bcs     :+
        dec     right+1

:       jsr     PaintRectImpl  ; Draw title bar stripes between close box and title
        add16   winrect::x2, #10, left

        jsr     get_wintitlebar_rect
        sub16   winrect::x2, #3, right

        jsr     PaintRectImpl  ; Draw title bar stripes to right of title
        MGTK_CALL MGTK::SetPattern, standard_port::penpattern

no_titlebar:
        jsr     get_window

        bit     current_winfo::vscroll
        bpl     no_vscroll

        jsr     get_win_vertscrollrect
        ldx     #3
:       lda     winrect,x
        sta     up_scroll_params,x
        sta     down_scroll_params,x
        dex
        bpl     :-

        inc     up_scroll_params::ycoord
        ldax    winrect::y2
        sec
        sbc     #$0A
        bcs     :+
        dex
:
        pha
        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::hscroll
        bpl     no_hscroll

:       pla
        sec
        sbc     #$0B
        bcs     :+
        dex
:       pha

no_hscroll:
        pla
        stax    down_scroll_params::ycoord

        ldax    down_scroll_addr
        jsr     draw_icon

        ldax    up_scroll_addr
        jsr     draw_icon

no_vscroll:
        bit     current_winfo::hscroll
        bpl     no_hscrollbar

        jsr     get_win_horizscrollrect
        ldx     #3
:       lda     winrect,x
        sta     left_scroll_params,x
        sta     right_scroll_params,x
        dex
        bpl     :-

        ldax    winrect::x2
        sec
        sbc     #$14
        bcs     :+
        dex
:
        pha
        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::vscroll
        bpl     no_vscroll2

:       pla
        sec
        sbc     #$15
        bcs     :+
        dex
:       pha

no_vscroll2:
        pla
        stax    right_scroll_params

        ldax    right_scroll_addr
        jsr     draw_icon

        ldax    left_scroll_addr
        jsr     draw_icon

no_hscrollbar:
        lda     #MGTK::pencopy
        jsr     set_fill_mode

        lda     current_winfo::vscroll
        and     #$01
        beq     :+

        lda     #which_control_vert
        sta     which_control
        lda     draw_erase_mode
        jsr     draw_or_erase_scrollbar
        jsr     get_window

:       lda     current_winfo::hscroll
        and     #$01
        beq     :+

        lda     #which_control_horiz
        sta     which_control
        lda     draw_erase_mode
        jsr     draw_or_erase_scrollbar
        jsr     get_window

:       lda     current_winfo::options
        and     #MGTK::Option::grow_box
        beq     ret

        jsr     get_win_growboxrect
        lda     draw_erase_mode
        bne     draw_resize
        ldax    #winrect
        jsr     fill_and_frame_rect
        jmp     ret

        ;; Draw resize box
draw_resize:
        ldx     #3
:       lda     winrect,x
        sta     resize_box_params,x
        dex
        bpl     :-

        lda     #MGTK::notpencopy
        jsr     set_fill_mode
        ldax    resize_box_addr
        jsr     draw_icon
ret:    rts
.endproc


.proc center_title_text
        ldax    current_winfo::title
        jsr     do_measure_text
        stax    $82

        lda     winrect::x1
        clc
        adc     winrect::x2
        tay

        lda     winrect::x1+1
        adc     winrect::x2+1
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

        ldax    winrect::y2
        sec
        sbc     #2
        bcs     :+
        dex
:       stax    current_penloc_y

        ldax    $82
        rts
.endproc

;;; ============================================================

;;; 4 bytes of params, copied to current_penloc

.proc FindWindowImpl
        PARAM_BLOCK params, $EA
mousex:     .word   0
mousey:     .word   0
which_area: .byte   0
window_id:  .byte   0
        END_PARAM_BLOCK

        jsr     save_params_and_stack

        MGTK_CALL MGTK::InRect, test_rect_params ; check if in menubar
        beq     not_menubar

        lda     #MGTK::Area::menubar
return_no_window:
        ldx     #0
return_result:
        pha
        txa
        pha
        jsr     restore_params_active_port
        pla
        tax
        pla
        ldy     #params::which_area - params
        jmp     store_xa_at_y

not_menubar:
        lda     #0              ; first window we see is the selected one
        sta     not_selected

        jsr     top_window
        beq     no_windows

loop:   jsr     get_winframerect
        jsr     in_winrect
        bne     in_window

        jsr     next_window
        stx     not_selected    ; set to non-zero for subsequent windows
        bne     loop

no_windows:
        lda     #MGTK::Area::desktop
        beq     return_no_window

in_window:
        lda     current_winfo::options
        and     #MGTK::Option::dialog_box
        bne     in_content

        jsr     get_wintitlebar_rect
        jsr     in_winrect
        beq     in_content

        lda     not_selected
        bne     :+

        lda     current_winfo::options
        and     #MGTK::Option::go_away_box
        beq     :+

        jsr     get_wingoaway_rect
        jsr     in_winrect
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

        jsr     get_win_growboxrect
        jsr     in_winrect
        beq     :+
        lda     #MGTK::Area::grow_box
return_window:
        ldx     current_winfo::id
        bne     return_result

:       lda     #MGTK::Area::content
        bne     return_window

not_selected:
        .byte   0

.endproc

;;; ============================================================
;;; OpenWindow

;;; params points to a winfo structure

.proc OpenWindowImpl
        win_id := $82

        copy16  params_addr, window

        ldy     #MGTK::Winfo::window_id
        lda     (window),y
        bne     :+
        exit_call MGTK::Error::window_id_required

:       sta     win_id
        jsr     window_by_id
        beq     :+
        exit_call MGTK::Error::window_already_exists

:       copy16  params_addr, window

        ldy     #MGTK::Winfo::status
        lda     (window),y
        ora     #$80
        sta     (window),y
        bmi     do_select_win
.endproc


;;; ============================================================
;;; SelectWindow

;;; 1 byte of params, copied to $82

.proc SelectWindowImpl
        jsr     window_by_id_or_exit
        cmp     current_window
        bne     :+
        cpx     current_window+1
        bne     :+
        rts

:       jsr     link_window
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
        jsr     hide_cursor_save_params
        jsr     set_desktop_port

        jsr     top_window
        beq     :+
        jsr     erase_winframe
:       pla
        sta     current_window+1
        pla
        sta     current_window

        jsr     top_window
        lda     current_winfo::id
        sta     sel_window_id

        jsr     draw_window
        jmp     show_cursor_and_restore
.endproc

do_select_win   := SelectWindowImpl::do_select_win


.proc link_window
        ldy     #MGTK::Winfo::nextwinfo
        lda     (window),y
        sta     (previous_window),y
        iny
        lda     (window),y
        sta     (previous_window),y
        rts
.endproc


;;; ============================================================
;;; GetWinPtr

;;; 1 byte of params, copied to $82

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

previous_port:
        .res    2

update_port:
        .res    .sizeof(MGTK::GrafPort)

.proc BeginUpdateImpl
        jsr     window_by_id_or_exit

        lda     current_winfo::id
        cmp     target_window_id
        bne     :+
        inc     matched_target

:       jsr     hide_cursor_save_params
        jsr     set_desktop_port
        lda     matched_target
        bne     :+
        MGTK_CALL MGTK::SetPortBits, set_port_params

:       jsr     draw_window
        jsr     set_desktop_port
        lda     matched_target
        bne     :+
        MGTK_CALL MGTK::SetPortBits, set_port_params

:       jsr     get_window
        copy16  active_port, previous_port

        jsr     prepare_winport
        php
        ldax    update_port_addr
        jsr     assign_and_prepare_port

        asl     preserve_zp_flag
        plp
        bcc     :+
        rts
:       jsr     EndUpdateImpl
        ;; fall through
.endproc

err_obscured:
        exit_call MGTK::Error::window_obscured

;;; ============================================================
;;; EndUpdate

;;; 1 byte of params, copied to $82

update_port_addr:
        .addr   update_port

.proc EndUpdateImpl
        jsr     ShowCursorImpl

        ldax    previous_port
        stax    active_port
        jmp     set_and_prepare_port
.endproc

;;; ============================================================
;;; GetWinPort

;;; 3 bytes of params, copied to $82

.proc GetWinPortImpl
        PARAM_BLOCK params, $82
win_id:   .byte   0
win_port: .addr   0
        END_PARAM_BLOCK


        jsr     apply_port_to_active_port

        jsr     window_by_id_or_exit
        copy16  params::win_port, params_addr

        COPY_STRUCT MGTK::Rect, fill_rect_params, current_maprect_x1

        jsr     prepare_winport
        bcc     err_obscured

        ldy     #.sizeof(MGTK::GrafPort)-1
:       lda     current_grafport,y
        sta     (params_addr),y
        dey
        bpl     :-

        jmp     apply_active_port_to_port
.endproc


.proc prepare_winport
        jsr     get_winrect

        ldx     #7
:       lda     #0
        sta     clipped_left,x
        lda     winrect,x
        sta     left,x
        dex
        bpl     :-

        jsr     clip_rect
        bcs     :+
        rts

        ;; Load window's grafport into current_grafport.
:       ldy     #MGTK::Winfo::port
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
        sec
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
        sec
        rts
.endproc

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
        ptr := window

        jsr     window_by_id_or_exit
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
.endproc

;;; ============================================================
;;; FrontWindow

.proc FrontWindowImpl
        jsr     top_window
        beq     nope
        lda     current_winfo::id
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

        jsr     get_wingoaway_rect
        jsr     save_params_and_stack
        jsr     set_desktop_port

        lda     #$80
toggle: sta     in_close_box

        lda     #MGTK::penXOR
        jsr     set_fill_mode

        jsr     HideCursorImpl
        MGTK_CALL MGTK::PaintRect, winrect
        jsr     ShowCursorImpl

loop:   jsr     get_and_return_event
        cmp     #MGTK::EventKind::button_up
        beq     :+

        MGTK_CALL MGTK::MoveTo, set_pos_params
        jsr     in_winrect
        eor     in_close_box
        bpl     loop
        lda     in_close_box
        eor     #$80
        jmp     toggle

:       jsr     restore_params_active_port
        ldy     #0
        lda     in_close_box
        beq     end
        lda     #1
end:    sta     (params_addr),y
        rts
.endproc

;;; ============================================================

        .byte   $00

.proc drag_initialpos
xcoord: .res    2
ycoord: .res    2
.endproc

.proc drag_curpos
xcoord: .res    2
ycoord: .res    2
.endproc

.proc drag_delta
xdelta: .res    2
ydelta: .res    2
.endproc

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
window_id: .byte   0
dragx:     .word   0
dragy:     .word   0
moved:     .byte   0
        END_PARAM_BLOCK

        lda     #0
drag_or_grow:
        sta     drag_resize_flag
        jsr     kbd_mouse_init_tracking

        ldx     #3
:       lda     params::dragx,x
        sta     drag_initialpos,x
        sta     drag_curpos,x
        lda     #0
        sta     drag_delta,x
        dex
        bpl     :-

        jsr     window_by_id_or_exit

        bit     kbd_mouse_state
        bpl     :+
        jsr     kbd_win_drag_or_grow

:       jsr     hide_cursor_save_params
        jsr     winframe_to_set_port

        lda     #MGTK::penXOR
        jsr     set_fill_mode
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern

loop:   jsr     get_window
        jsr     update_win_for_drag

        jsr     get_winframerect
        jsr     frame_winrect
        jsr     ShowCursorImpl

no_change:
        jsr     get_and_return_event
        cmp     #MGTK::EventKind::button_up
        bne     dragging

        jsr     frame_winrect

        bit     movement_cancel
        bmi     cancelled

        ldx     #3
:       lda     drag_delta,x
        bne     changed
        dex
        bpl     :-

cancelled:
        jsr     show_cursor_and_restore
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
        jsr     erase_window
        jsr     hide_cursor_save_params

        bit     movement_cancel
        bvc     :+
        jsr     set_input

:       jsr     show_cursor_and_restore
        lda     #$80
        jmp     return_moved

dragging:
        jsr     check_if_changed
        beq     no_change

        jsr     HideCursorImpl
        jsr     frame_winrect
        jmp     loop
.endproc


.proc update_win_for_drag
        win_width := $82

        PARAM_BLOCK content, $C7
minwidth:  .word  0
minheight: .word  0
maxwidth:  .word  0
maxheight: .word  0
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

:       add16   current_winport::viewloc::xcoord,x, drag_delta,x, current_winport::viewloc::xcoord,x
        inx
        inx
        cpx     #4
        bne     :-

        lda     #$12
        cmp     current_winport::viewloc::ycoord
        bcc     :+
        sta     current_winport::viewloc::ycoord
:       rts

grow:   lda     #0
        sta     grew_flag
loop:   add16lc current_winport::maprect::x2,x, drag_delta,x, current_winport::maprect::x2,x
        sub16lc current_winport::maprect::x2,x, current_winport::maprect::x1,x, win_width

        sec
        lda     win_width
        sbc     content::minwidth,x
        lda     win_width+1
        sbc     content::minwidth+1,x
        bpl     :+

        add16lc content::minwidth,x, current_winport::maprect::x1,x, current_winport::maprect::x2,x
        jsr     set_grew_flag
        jmp     next

:       sec
        lda     content::maxwidth,x
        sbc     win_width
        lda     content::maxwidth+1,x
        sbc     win_width+1
        bpl     next

        add16lc content::maxwidth,x, current_winport::maprect::x1,x, current_winport::maprect::x2,x
        jsr     set_grew_flag

next:   inx
        inx
        cpx     #4
        bne     loop
        jmp     finish_grow
.endproc


        ;; Return with Z=1 if the drag position was not changed, or Z=0
        ;; if the drag position was changed or force_tracking_change is set.
.proc check_if_changed
        ldx     #2
        ldy     #0

loop:   lda     get_and_return_event::event::mouse_pos+1,x
        cmp     drag_curpos+1,x
        bne     :+
        iny
:
        lda     get_and_return_event::event::mouse_pos,x
        cmp     drag_curpos,x
        bne     :+
        iny
:       sta     drag_curpos,x

        sec
        sbc     drag_initialpos,x
        sta     drag_delta,x

        lda     get_and_return_event::event::mouse_pos+1,x
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
.endproc

DragWindowImpl_drag_or_grow := DragWindowImpl::drag_or_grow


;;; ============================================================
;;; CloseWindow

;;; 1 byte of params, copied to $82

.proc CloseWindowImpl
        jsr     window_by_id_or_exit

        jsr     hide_cursor_save_params

        jsr     winframe_to_set_port
        jsr     link_window

        ldy     #MGTK::Winfo::status
        lda     (window),y
        and     #$7F
        sta     (window),y

        jsr     top_window
        lda     current_winfo::id
        sta     sel_window_id
        lda     #0
        jmp     erase_window
.endproc

;;; ============================================================
;;; CloseAll

.proc CloseAllImpl
        jsr     top_window
        beq     :+

        ldy     #MGTK::Winfo::status
        lda     (window),y
        and     #$7F
        sta     (window),y
        jsr     link_window

        jmp     CloseAllImpl
:       jmp     StartDeskTopImpl::reset_desktop
.endproc


.proc winframe_to_set_port
        jsr     set_desktop_port
        jsr     get_winframerect

        COPY_BLOCK winrect, left
        jsr     clip_rect

        ldx     #3
:       lda     left,x
        sta     set_port_maprect,x
        sta     set_port_params,x
        lda     right,x
        sta     set_port_size,x
        dex
        bpl     :-

        rts
.endproc


matched_target:
        .byte   0

        ;; Erases window after destruction
.proc erase_window
        sta     target_window_id
        lda     #0
        sta     matched_target
        MGTK_CALL MGTK::SetPortBits, set_port_params

        lda     #MGTK::pencopy
        jsr     set_fill_mode

        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::PaintRect, set_port_maprect

        jsr     show_cursor_and_restore
        jsr     top_window
        beq     ret

        php
        sei
        jsr     FlushEventsImpl

:       jsr     next_window
        bne     :-

loop:   jsr     put_event
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
        jsr     window_by_id

        ldax    previous_window
        jsr     get_window::get_from_ax
        jmp     loop

plp_ret:
        plp
ret:    rts
.endproc


goaway_height:  .word   8       ; font height - 1
wintitle_height:.word  12       ; font height + 3
winframe_top:   .word  13       ; font height + 4

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
        PARAM_BLOCK params, $82
window_id:      .byte   0
windowx:        .word   0
windowy:        .word   0
screenx:        .word   0       ; out
screeny:        .word   0       ; out
        END_PARAM_BLOCK

        jsr     window_by_id_or_exit

        ldx     #2
loop:   add16   params::windowx,x, current_winport::viewloc,x, params::windowx,x
        dex
        dex
        bpl     loop
        bmi     copy_map_results                  ; always
.endproc

;;; ============================================================
;;; ScreenToWindow

;;; 5 bytes of params, copied to $82

.proc ScreenToWindowImpl
        PARAM_BLOCK params, $82
window_id:      .byte   0
screenx:        .word   0
screeny:        .word   0
windowx:        .word   0       ; out
windowy:        .word   0       ; out
        END_PARAM_BLOCK

        jsr     window_by_id_or_exit

        ldx     #2
:       sub16   params::screenx,x, current_winport::viewloc,x, params::screenx,x
        dex
        dex
        bpl     :-
        ;; fall through
.endproc

.proc copy_map_results
        ldy     #ScreenToWindowImpl::params::windowx - ScreenToWindowImpl::params
:       lda     ScreenToWindowImpl::params + (ScreenToWindowImpl::params::screenx - ScreenToWindowImpl::params::windowx),y
        sta     (params_addr),y
        iny
        cpy     #ScreenToWindowImpl::params::size      ; results are 2 words (x, y) at params_addr+5
        bne     :-
        rts
.endproc

;;; ============================================================


        ;; Used to draw scrollbar arrows and resize box
.proc draw_icon
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

        ldy     #icon_offset_width
        lda     (icon_ptr),y
        tax
        lda     div7_table+7,x
        sta     src_mapwidth

        txa
        ldx     left+1
        clc
        adc     left
        bcc     :+
        inx
:       stax    right

        iny
        lda     (icon_ptr),y    ; height
        ldx     top+1
        clc
        adc     top
        bcc     :+
        inx
:       stax    bottom

        iny
        lda     (icon_ptr),y
        sta     bits_addr
        iny
        lda     (icon_ptr),y
        sta     bits_addr+1
        jmp     BitBltImpl
.endproc

;;; ============================================================
;;; ActivateCtl

;;; 2 bytes of params, copied to $8C

.proc ActivateCtlImpl
        PARAM_BLOCK params, $8C
which_ctl: .byte   0
activate:  .byte   0
        END_PARAM_BLOCK


        lda     which_control
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+

        lda     #which_control_vert
        sta     which_control
        bne     activate

:       cmp     #MGTK::Ctl::horizontal_scroll_bar
        bne     ret

        lda     #which_control_horiz
        sta     which_control
        beq     activate
ret:    rts

activate:
        jsr     hide_cursor_save_params
        jsr     top_window

        bit     which_control
        bpl     :+

        lda     current_winfo::vscroll
        ldy     #MGTK::Winfo::vscroll
        bne     toggle

:       lda     current_winfo::hscroll
        ldy     #MGTK::Winfo::hscroll

toggle: eor     params::activate
        and     #1
        eor     (window),y
        sta     (window),y

        lda     params::activate
        jsr     draw_or_erase_scrollbar
        jmp     show_cursor_and_restore
.endproc


.proc draw_or_erase_scrollbar
        bne     do_draw

        jsr     get_scrollbar_scroll_area
        jsr     set_standard_port
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
        jsr     set_standard_port
        jsr     get_scrollbar_scroll_area

        MGTK_CALL MGTK::SetPattern, light_speckles_pattern
        MGTK_CALL MGTK::PaintRect, winrect
        MGTK_CALL MGTK::SetPattern, standard_port::penpattern

        bit     which_control
        bmi     vert_thumb

        bit     current_winfo::hscroll
        bvs     has_thumb
ret2:   rts

vert_thumb:
        bit     current_winfo::vscroll
        bvc     ret2
has_thumb:
        jsr     get_thumb_rect
        jmp     fill_and_frame_rect
.endproc


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


.proc get_scrollbar_scroll_area
        bit     which_control
        bpl     horiz

        jsr     get_win_vertscrollrect
        lda     winrect::y1
        clc
        adc     #$0C
        sta     winrect::y1
        bcc     :+
        inc     winrect::y1+1
:
        lda     winrect::y2
        sec
        sbc     #$0B
        sta     winrect::y2
        bcs     :+
        dec     winrect::y2+1
:
        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::hscroll
        bpl     v_noscroll

:       lda     winrect::y2
        sec
        sbc     #$0B
        sta     winrect::y2
        bcs     :+
        dec     winrect::y2+1
:
v_noscroll:
        inc16   winrect::x1
        lda     winrect::x2
        bne     :+
        dec     winrect::x2+1
:       dec     winrect::x2
        jmp     return_winrect_jmp


horiz:  jsr     get_win_horizscrollrect
        lda     winrect::x1
        clc
        adc     #$15
        sta     winrect::x1
        bcc     :+
        inc     winrect::x1+1
:
        lda     winrect::x2
        sec
        sbc     #$15
        sta     winrect::x2
        bcs     :+
        dec     winrect::x2+1
:
        lda     current_winfo::options
        and     #MGTK::Option::grow_box
        bne     :+

        bit     current_winfo::vscroll
        bpl     h_novscroll

:       lda     winrect::x2
        sec
        sbc     #$15
        sta     winrect::x2
        bcs     h_novscroll
        dec     winrect::x2+1

h_novscroll:
        inc16   winrect::y1

        lda     winrect::y2
        bne     :+
        dec     winrect::y2+1
:       dec     winrect::y2

return_winrect_jmp:
        jmp     return_winrect
.endproc


        thumb_max := $A3
        thumb_pos := $A1

        xthumb_width := 20
        ythumb_height := 12


.proc get_thumb_rect
        thumb_coord := $82

        jsr     get_scrollbar_scroll_area

        jsr     get_thumb_vals
        jsr     fixed_div

        lda     fixed_div_quotient+2    ; 8.0 integral part
        pha
        jsr     calc_ctl_bounds
        jsr     set_up_thumb_division
        pla
        tax

        lda     thumb_max
        ldy     thumb_max+1

        cpx     #1              ; 100%
        beq     :+

        ldx     fixed_div_quotient+1    ; 0.8 fractional part
        jsr     get_thumb_coord

:       sta     thumb_coord
        sty     thumb_coord+1

        ldx     #0              ; x-coords
        lda     #xthumb_width

        bit     which_control
        bpl     :+

        ldx     #2              ; y-coords
        lda     #ythumb_height
:       pha
        add16   winrect,x, thumb_coord, winrect,x
        pla
        clc
        adc     winrect::x1,x
        sta     winrect::x2,x
        lda     winrect::x1+1,x
        adc     #0
        sta     winrect::x2+1,x
        jmp     return_winrect
.endproc

;;; ============================================================
;;; FindControl

;;; 4 bytes of params, copied to current_penloc

.proc FindControlImpl
        jsr     save_params_and_stack

        jsr     top_window
        bne     :+
        exit_call MGTK::Error::no_active_window

:       bit     current_winfo::vscroll
        bpl     no_vscroll

        jsr     get_win_vertscrollrect
        jsr     in_winrect
        beq     no_vscroll

        ldx     #0
        lda     current_winfo::vscroll
        and     #$01
        beq     vscrollbar

        lda     #which_control_vert
        sta     which_control

        jsr     get_scrollbar_scroll_area
        jsr     in_winrect
        beq     in_arrows

        bit     current_winfo::vscroll
        bcs     return_dead_zone ; never ???

        jsr     get_thumb_rect
        jsr     in_winrect
        beq     no_thumb

        ldx     #MGTK::Part::thumb
        bne     vscrollbar

in_arrows:
        lda     #MGTK::Part::up_arrow
        bne     :+

no_thumb:
        lda     #MGTK::Part::page_up
:       pha
        jsr     get_thumb_rect
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

        jsr     get_win_horizscrollrect
        jsr     in_winrect
        beq     no_hscroll

        ldx     #0
        lda     current_winfo::hscroll
        and     #$01
        beq     hscrollbar

        lda     #which_control_horiz
        sta     which_control

        jsr     get_scrollbar_scroll_area
        jsr     in_winrect
        beq     in_harrows

        bit     current_winfo::hscroll
        bvc     return_dead_zone

        jsr     get_thumb_rect
        jsr     in_winrect
        beq     no_hthumb

        ldx     #MGTK::Part::thumb
        bne     hscrollbar

in_harrows:
        lda     #MGTK::Part::left_arrow
        bne     :+

no_hthumb:
        lda     #MGTK::Part::page_left
:       pha
        jsr     get_thumb_rect
        pla
        tax
        lda     current_penloc_x+1
        cmp     winrect::x1+1
        bcc     hscrollbar
        bne     :+
        lda     current_penloc_x
        cmp     winrect::x1
        bcc     hscrollbar
:       inx

hscrollbar:
        lda     #MGTK::Ctl::horizontal_scroll_bar
        bne     return_result

no_hscroll:
        jsr     get_winrect
        jsr     in_winrect
        beq     return_dead_zone

        lda     #MGTK::Ctl::not_a_control
        beq     return_result

return_dead_zone:
        lda     #MGTK::Ctl::dead_zone
return_result:
        jmp     FindWindowImpl::return_result
.endproc


;;; ============================================================
;;; SetCtlMax

;;; 3 bytes of params, copied to $82

.proc SetCtlMaxImpl
        PARAM_BLOCK params, $82
which_ctl: .byte  0
ctlmax:    .byte  0
        END_PARAM_BLOCK

        lda     params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+
        lda     #$80
        sta     params::which_ctl
        bne     got_ctl        ; always

:       cmp     #MGTK::Ctl::horizontal_scroll_bar
        bne     :+
        lda     #$00
        sta     params::which_ctl
        beq     got_ctl        ; always

:       exit_call MGTK::Error::control_not_found

got_ctl:
        jsr     top_window
        bne     :+

        exit_call MGTK::Error::no_active_window

:       ldy     #MGTK::Winfo::hthumbmax
        bit     params::which_ctl
        bpl     :+

        ldy     #MGTK::Winfo::vthumbmax
:       lda     params::ctlmax
        sta     (window),y
        sta     current_winfo,y
        rts
.endproc

;;; ============================================================
;;; TrackThumb

;;; 5 bytes of params, copied to $82

.proc TrackThumbImpl
        PARAM_BLOCK params, $82
which_ctl:  .byte   0
mouse_pos:
mousex:     .word   0
mousey:     .word   0
thumbpos:   .byte   0
thumbmoved: .byte   0
        END_PARAM_BLOCK

        thumb_dim := $82


        lda     params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+

        lda     #which_control_vert
        sta     params::which_ctl
        bne     got_ctl                    ; always

:       cmp     #MGTK::Ctl::horizontal_scroll_bar
        bne     :+

        lda     #which_control_horiz
        sta     params::which_ctl
        beq     got_ctl                    ; always

:       exit_call MGTK::Error::control_not_found

got_ctl:lda     params::which_ctl
        sta     which_control

        ldx     #3
:       lda     params::mouse_pos,x
        sta     drag_initialpos,x
        sta     drag_curpos,x
        dex
        bpl     :-

        jsr     top_window
        bne     :+
        exit_call MGTK::Error::no_active_window

:       jsr     get_thumb_rect
        jsr     save_params_and_stack
        jsr     set_desktop_port

        lda     #MGTK::penXOR
        jsr     set_fill_mode
        MGTK_CALL MGTK::SetPattern, light_speckles_pattern

        jsr     HideCursorImpl
drag_loop:
        jsr     frame_winrect
        jsr     ShowCursorImpl

no_change:
        jsr     get_and_return_event
        cmp     #MGTK::EventKind::button_up
        beq     drag_done

        jsr     check_if_changed
        beq     no_change

        jsr     HideCursorImpl
        jsr     frame_winrect

        jsr     top_window
        jsr     get_thumb_rect

        ldx     #0
        lda     #xthumb_width

        bit     which_control
        bpl     :+

        ldx     #2
        lda     #ythumb_height

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
        jmp     drag_loop

drag_done:
        jsr     HideCursorImpl
        jsr     frame_winrect
        jsr     show_cursor_and_restore

        jsr     set_up_thumb_division

        jsr     fixed_div
        ldx     fixed_div::quotient+2    ; 8.0 integral part

        jsr     get_thumb_vals

        lda     fixed_div::divisor
        ldy     #0
        cpx     #1
        bcs     :+

        ldx     fixed_div_quotient+1     ; 0.8 fractional part
        jsr     get_thumb_coord

:       ldx     #1
        cmp     fixed_div_quotient+2
        bne     :+
        dex

:       ldy     #params::thumbpos - params
        jmp     store_xa_at_y
.endproc


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
.proc get_thumb_coord
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
.endproc


ctl_bound2:
        .res 2
ctl_bound1:
        .res 2


        ;; Set fixed_div::divisor and fixed_div::dividend up for the
        ;; proportion calculation for the control in which_control.
.proc set_up_thumb_division
        sub16   ctl_bound2, ctl_bound1, fixed_div::divisor
        ldx     #0
        bit     which_control
        bpl     :+

        ldx     #2
:       sub16   winrect,x, ctl_bound1, fixed_div::dividend
        rts
.endproc


        ;; Set thumb_max and thumb_pos according to the control indicated
        ;; in which_control.
.proc get_thumb_vals
        ldy     #MGTK::Winfo::hthumbmax

        bit     which_control
        bpl     is_horiz

        ldy     #MGTK::Winfo::vthumbmax
is_horiz:
        lda     (window),y
        sta     thumb_max
        iny
        lda     (window),y
        sta     thumb_pos

        lda     #0
        sta     thumb_pos+1
        sta     thumb_max+1
        rts
.endproc


.proc calc_ctl_bounds
        offset := $82

        ldx     #0
        lda     #xthumb_width

        bit     which_control
        bpl     :+

        ldx     #2
        lda     #ythumb_height
:
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
.endproc


;;; ============================================================
;;; UpdateThumb

;;; 3 bytes of params, copied to $8C

.proc UpdateThumbImpl
        PARAM_BLOCK params, $8C
which_ctl:  .byte   0
thumbpos:   .byte   0
        END_PARAM_BLOCK


        lda     which_control
        cmp     #MGTK::Ctl::vertical_scroll_bar
        bne     :+
        lda     #which_control_vert
        sta     which_control
        bne     check_win

:       cmp     #MGTK::Ctl::horizontal_scroll_bar
        bne     bad_ctl
        lda     #which_control_horiz
        sta     which_control
        beq     check_win

bad_ctl:
        exit_call MGTK::Error::control_not_found

check_win:
        jsr     top_window
        bne     :+
        exit_call MGTK::Error::no_active_window

:       ldy     #MGTK::Winfo::hthumbpos
        bit     which_control
        bpl     :+

        ldy     #MGTK::Winfo::vthumbpos
:       lda     params::thumbpos
        sta     (window),y

        jsr     hide_cursor_save_params
        jsr     set_standard_port
        jsr     draw_or_erase_scrollbar
        jmp     show_cursor_and_restore
.endproc

;;; ============================================================
;;; KeyboardMouse

;;; 1 byte of params, copied to $82

.proc KeyboardMouse
        lda     #$80
        sta     kbd_mouse_state
        jmp     FlushEventsImpl
.endproc

;;; ============================================================

;;; $4E SetMenuSelection

;;; 2 bytes of params, copied to $82

.proc SetMenuSelectionImpl
        PARAM_BLOCK params, $82
menu_index:             .res 1
menu_item_index:        .res 1
        END_PARAM_BLOCK

        lda     params::menu_index
        sta     sel_menu_index

        lda     params::menu_item_index
        sta     sel_menu_item_index

        rts
.endproc

;;; ============================================================

        ;; Set to $80 by KeyboardMouse call; also set to $04,
        ;; $01 elsewhere.
kbd_mouse_state:
        .byte   0

kbd_mouse_state_menu := 1
kbd_mouse_state_mousekeys := 4


kbd_mouse_x:  .word     0
kbd_mouse_y:  .word     0

kbd_menu_select_flag:
        .byte   0

        ;; Currently selected menu/menu item. Note that menu is index,
        ;; not ID from menu definition.
sel_menu_index:
        .byte   0
sel_menu_item_index:
        .byte   0

saved_mouse_pos:
saved_mouse_x:  .word   0
saved_mouse_y:  .byte   0

kbd_menu:  .byte   $00
kbd_menu_item:  .byte   $00
movement_cancel:  .byte   $00
kbd_mouse_status:  .byte   $00

.proc kbd_mouse_save_zp
        COPY_BYTES $80, $80, kbd_mouse_zp_stash
        rts
.endproc


.proc kbd_mouse_restore_zp
        COPY_BYTES $80, kbd_mouse_zp_stash,$80
        rts
.endproc


kbd_mouse_zp_stash:
        .res    128


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
        jsr     scale_mouse_coord

        ldx     mouse_firmware_hi
        sta     MOUSE_X_LO,x
        tya
        sta     MOUSE_X_HI,x

        pla
        ldy     #$00
        clc
        jsr     scale_mouse_coord

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


.proc scale_mouse_coord
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
.endproc


.proc kbd_mouse_to_mouse
        COPY_BYTES 3, kbd_mouse_x, mouse_x
        rts
.endproc

.proc position_kbd_mouse
        jsr     kbd_mouse_to_mouse
        jmp     set_mouse_pos_from_kbd_mouse
.endproc


.proc save_mouse_pos
        jsr     read_mouse_pos
        COPY_BYTES 3, mouse_x, saved_mouse_pos
        rts
.endproc

.proc restore_cursor
        jsr     stash_addr
        copy16  kbd_mouse_cursor_stash, params_addr
        jsr     SetCursorImpl
        jsr     restore_addr

        lda     #0
        sta     kbd_mouse_state
        lda     #$40
        sta     mouse_status
        jmp     restore_mouse_pos
.endproc

.proc kbd_mouse_init_tracking
        lda     #0
        sta     movement_cancel
        sta     force_tracking_change
        rts
.endproc

        ;; Look at buttons (apple keys), compute modifiers in A
        ;; (bit 0 = button 0 / open apple, bit 1 = button 1 / solid apple)
.proc compute_modifiers
        lda     BUTN1
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        rts
.endproc


.proc get_key
        jsr     compute_modifiers
        sta     set_input_modifiers
no_modifiers:
        clc
        lda     KBD
        bpl     :+
        stx     KBDSTRB
        and     #CHAR_MASK
        sec
:       rts
.endproc


.proc handle_keyboard_mouse
        lda     kbd_mouse_state
        bne     :+
        rts

:       cmp     #kbd_mouse_state_mousekeys
        beq     kbd_mouse_mousekeys

        jsr     kbd_mouse_sync_cursor

        lda     kbd_mouse_state
        cmp     #kbd_mouse_state_menu
        bne     :+
        jmp     kbd_mouse_do_menu

:       jmp     kbd_mouse_do_window
.endproc


.proc stash_cursor
        jsr     stash_addr
        copy16  active_cursor, kbd_mouse_cursor_stash
        copy16  pointer_cursor_addr, params_addr
        jsr     SetCursorImpl
        jmp     restore_addr
.endproc

kbd_mouse_cursor_stash:
        .res    2

stash_addr:
        copy16  params_addr, stashed_addr
        rts

restore_addr:
        copy16  stashed_addr, params_addr
        rts

stashed_addr:  .addr     0


.proc kbd_mouse_mousekeys
        jsr     compute_modifiers ; C=_ A=____ __SO
        ror     a                 ; C=O A=____ ___S
        ror     a                 ; C=S A=O___ ____
        ror     kbd_mouse_status  ; shift solid apple into bit 7 of kbd_mouse_status
        lda     kbd_mouse_status  ; becomes mouse button
        sta     mouse_status
        lda     #0
        sta     input::modifiers

        jsr     get_key::no_modifiers
        bcc     :+
        jmp     mousekeys_input

:       jmp     position_kbd_mouse
.endproc


.proc activate_keyboard_mouse
        pha                     ; save modifiers
        lda     kbd_mouse_state
        bne     in_kbd_mouse    ; branch away if keyboard mouse is active
        pla
        cmp     #3              ; open apple+solid apple
        bne     ret
        bit     mouse_status
        bmi     ret             ; branch away if button is down

        lda     #4
        sta     kbd_mouse_state

        ldx     #10
beeploop:
        lda     SPKR            ; Beep
        ldy     #0
:       dey
        bne     :-
        dex
        bpl     beeploop

waitloop:
        jsr     compute_modifiers
        cmp     #3
        beq     waitloop        ; wait for user to release OA+SA
        sta     input::modifiers

        lda     #0
        sta     kbd_mouse_status ; reset mouse button status
        COPY_BYTES 3, set_pos_params, kbd_mouse_x
ret:    rts

in_kbd_mouse:
        cmp     #kbd_mouse_state_mousekeys
        bne     pla_ret
        pla
        and     #1              ; modifiers
        bne     :+
        lda     #0
        sta     kbd_mouse_state
:       rts

pla_ret:
        pla
        rts
.endproc


.proc kbd_mouse_sync_cursor
        bit     mouse_status
        bpl     :+

        lda     #0
        sta     kbd_mouse_state
        jmp     set_mouse_pos_from_kbd_mouse

:       lda     mouse_status
        pha
        lda     #$C0
        sta     mouse_status
        pla
        and     #$20
        beq     kbd_mouse_to_mouse_jmp

        COPY_BYTES 3, mouse_x, kbd_mouse_x

        stx     kbd_menu_select_flag           ; =$ff
        rts

kbd_mouse_to_mouse_jmp:
        jmp     kbd_mouse_to_mouse
.endproc


.proc kbd_menu_select
        php
        sei
        jsr     save_mouse_pos

        lda     #kbd_mouse_state_menu
        sta     kbd_mouse_state

        jsr     position_menu_item

        lda     #$80
        sta     mouse_status
        jsr     stash_cursor
        ldx     sel_menu_index
        jsr     get_menu

        lda     curmenu::menu_id
        sta     cur_open_menu
        jsr     draw_menu

        lda     sel_menu_item_index
        sta     cur_hilited_menu_item
        jsr     hilite_menu_item
        plp
        rts

position_menu_item:
        ldx     sel_menu_index
        jsr     get_menu

        add16lc curmenu::x_min, #5, kbd_mouse_x

        ldy     sel_menu_item_index
        lda     menu_item_y_table,y
        sta     kbd_mouse_y
        lda     #$C0
        sta     mouse_status
        jmp     position_kbd_mouse
.endproc


.proc kbd_menu_select_item
        bit     kbd_menu_select_flag
        bpl     :+

        lda     cur_hilited_menu_item
        sta     sel_menu_item_index
        ldx     cur_open_menu
        dex
        stx     sel_menu_index

        lda     #0
        sta     kbd_menu_select_flag
:       rts
.endproc


.proc kbd_mouse_do_menu
        jsr     kbd_mouse_save_zp
        jsr     :+
        jmp     kbd_mouse_restore_zp

:       jsr     get_key
        bcs     handle_menu_key
        rts
.endproc

        ;; Keyboard navigation of menu
.proc handle_menu_key
        pha
        jsr     kbd_menu_select_item
        pla
        cmp     #CHAR_ESCAPE
        bne     try_return

        lda     #0
        sta     kbd_menu_item
        sta     kbd_menu
        lda     #$80
        sta     movement_cancel
        rts

try_return:
        cmp     #CHAR_RETURN
        bne     try_up
        jsr     kbd_mouse_to_mouse
        jmp     restore_cursor

try_up:
        cmp     #CHAR_UP
        bne     try_down

uploop: dec     sel_menu_item_index
        bpl     :+

        ldx     sel_menu_index
        jsr     get_menu
        ldx     menu_item_count
        stx     sel_menu_item_index

:       ldx     sel_menu_item_index
        beq     :+
        dex
        jsr     get_menu_item

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
        bne     uploop

:       jmp     kbd_menu_select::position_menu_item

try_down:
        cmp     #CHAR_DOWN
        bne     try_right

downloop:
        inc     sel_menu_item_index

        ldx     sel_menu_index
        jsr     get_menu
        lda     sel_menu_item_index
        cmp     menu_item_count
        bcc     :+
        beq     :+

        lda     #0
        sta     sel_menu_item_index
:       ldx     sel_menu_item_index
        beq     :+
        dex
        jsr     get_menu_item
        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
        bne     downloop

:       jmp     kbd_menu_select::position_menu_item

try_right:
        cmp     #CHAR_RIGHT
        bne     try_left

        lda     #0
        sta     sel_menu_item_index
        inc     sel_menu_index

        lda     sel_menu_index
        cmp     menu_count
        bcc     :+

        lda     #0
        sta     sel_menu_index
:       jmp     kbd_menu_select::position_menu_item

try_left:
        cmp     #CHAR_LEFT
        bne     nope

        lda     #0
        sta     sel_menu_item_index
        dec     sel_menu_index
        bmi     :+
        jmp     kbd_menu_select::position_menu_item

:       ldx     menu_count
        dex
        stx     sel_menu_index
        jmp     kbd_menu_select::position_menu_item

nope:   jsr     kbd_menu_by_shortcut
        bcc     :+

        lda     #$80
        sta     movement_cancel
:       rts
.endproc

.proc kbd_menu_by_shortcut
        sta     find_shortcut
        lda     set_input_modifiers
        and     #3
        sta     find_options

        lda     cur_open_menu
        pha
        lda     cur_hilited_menu_item
        pha

        lda     #find_mode_by_shortcut
        jsr     find_menu
        beq     fail

        stx     kbd_menu_item
        lda     curmenu::disabled
        bmi     fail

        lda     curmenuitem::options
        and     #MGTK::MenuOpt::disable_flag | MGTK::MenuOpt::item_is_filler
        bne     fail

        lda     curmenu::menu_id
        sta     kbd_menu
        sec
        bcs     :+

fail:   clc
:       pla
        sta     cur_hilited_menu_item
        pla
        sta     cur_open_menu
        sta     find_menu_id
        rts
.endproc


.proc kbd_menu_return
        php
        sei
        jsr     hide_menu
        jsr     restore_cursor

        lda     kbd_menu
        sta     MenuSelectImpl::params::menu_id
        sta     cur_open_menu

        lda     kbd_menu_item
        sta     MenuSelectImpl::params::menu_item
        sta     cur_hilited_menu_item

        jsr     restore_params_active_port
        lda     kbd_menu
        beq     :+
        jsr     HiliteMenuImpl

        lda     kbd_menu
:       sta     cur_open_menu
        ldx     kbd_menu_item
        stx     cur_hilited_menu_item
        plp
        jmp     store_xa_at_params
.endproc


.proc kbd_win_drag_or_grow
        php
        sei
        jsr     save_mouse_pos
        lda     #$80
        sta     mouse_status

        jsr     get_winframerect
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
        lda     #<(screen_width-1)
        sbc     drag_initialpos::xcoord
        lda     #>(screen_width-1)
        sbc     drag_initialpos::xcoord+1
        bmi     no_grow

        sec
        lda     #<(screen_height-1)
        sbc     drag_initialpos::ycoord
        lda     #>(screen_height-1)
        sbc     drag_initialpos::ycoord+1
        bmi     no_grow
        jsr     position_kbd_mouse
        jsr     stash_cursor
        plp
        rts

no_grow:
        lda     #0
        sta     kbd_mouse_state
        lda     #MGTK::Error::window_not_resizable
        plp
        jmp     exit_with_a

do_drag:
        lda     current_winfo::options
        and     #MGTK::Option::dialog_box
        beq     no_dialog

        lda     #0
        sta     kbd_mouse_state
        exit_call MGTK::Error::window_not_draggable

no_dialog:
        ldx     #0
dragloop:
        clc
        lda     winrect::x1,x
        cpx     #2
        beq     is_y
        adc     #$23
        jmp     :+

is_y:   adc     #5
:       sta     kbd_mouse_x,x
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
        jsr     position_kbd_mouse
        jsr     stash_cursor
        plp
        rts
.endproc


.proc kbd_mouse_add_to_y
        php
        clc
        adc     kbd_mouse_y
        sta     kbd_mouse_y
        plp
        bpl     yclamp
        cmp     #<screen_height
        bcc     :+
        lda     #0
        sta     kbd_mouse_y
:       jmp     position_kbd_mouse

yclamp: cmp     #<screen_height
        bcc     :-
        lda     #<(screen_height-1)
        sta     kbd_mouse_y
        bne     :-                  ; always
.endproc


.proc kbd_mouse_do_window
        jsr     kbd_mouse_save_zp
        jsr     :+
        jmp     kbd_mouse_restore_zp

:       jsr     get_key
        bcs     :+
        rts

:       cmp     #CHAR_ESCAPE
        bne     :+

        lda     #$80
        sta     movement_cancel
        jmp     restore_cursor

:       cmp     #CHAR_RETURN
        bne     :+
        jmp     restore_cursor

:       pha
        lda     set_input_modifiers
        beq     :+
        ora     #$80
        sta     set_input_modifiers
:       pla
        ldx     #$C0
        stx     mouse_status
        ;; Fall-through
.endproc

.proc mousekeys_input
        cmp     #CHAR_UP
        bne     not_up

        lda     #256-8
        bit     set_input_modifiers
        bpl     :+
        lda     #256-48
:       jmp     kbd_mouse_add_to_y

not_up:
        cmp     #CHAR_DOWN
        bne     not_down

        lda     #8
        bit     set_input_modifiers
        bpl     :+
        lda     #48
:       jmp     kbd_mouse_add_to_y

not_down:
        cmp     #CHAR_RIGHT
        bne     not_right

        jsr     kbd_mouse_check_xmax
        bcc     out_of_bounds

        clc
        lda     #8
        bit     set_input_modifiers
        bpl     :+
        lda     #64

:       adc     kbd_mouse_x
        sta     kbd_mouse_x
        lda     kbd_mouse_x+1
        adc     #0
        sta     kbd_mouse_x+1
        sec
        lda     kbd_mouse_x
        sbc     #<(screen_width-1)
        lda     kbd_mouse_x+1
        sbc     #>(screen_width-1)
        bmi     out_of_bounds

        lda     #>(screen_width-1)
        sta     kbd_mouse_x+1
        lda     #<(screen_width-1)
        sta     kbd_mouse_x
out_of_bounds:
        jmp     position_kbd_mouse

not_right:
        cmp     #CHAR_LEFT
        bne     not_left

        jsr     kbd_mouse_check_xmin
        bcc     out_of_boundsl

        lda     kbd_mouse_x
        bit     set_input_modifiers
        bpl     :+
        sbc     #64
        jmp     move_left

:       sbc     #8
move_left:
        sta     kbd_mouse_x
        lda     kbd_mouse_x+1
        sbc     #0
        sta     kbd_mouse_x+1
        bpl     out_of_boundsl

        lda     #0
        sta     kbd_mouse_x
        sta     kbd_mouse_x+1
out_of_boundsl:
        jmp     position_kbd_mouse

not_left:
        sta     set_input_key

        COPY_STRUCT MGTK::GrafPort, $A7, $0600

        lda     set_input_key
        jsr     kbd_menu_by_shortcut
        php

        COPY_STRUCT MGTK::GrafPort, $0600, $A7

        plp
        bcc     :+

        lda     #$40
        sta     movement_cancel
        jmp     restore_cursor

:       rts
.endproc


.proc set_input
        MGTK_CALL MGTK::PostEvent, set_input_params
        rts
.endproc

.proc set_input_params          ; 1 byte shorter than normal, since KEY
state:  .byte   MGTK::EventKind::key_down
key:    .byte   0
modifiers:
        .byte   0
.endproc
        set_input_key := set_input_params::key
        set_input_modifiers := set_input_params::modifiers

        ;; Set to true to force the return value of check_if_changed to true
        ;; during a tracking operation.
force_tracking_change:
        .byte   0


.proc kbd_mouse_check_xmin
        lda     kbd_mouse_state
        cmp     #kbd_mouse_state_mousekeys
        beq     ret_ok

        lda     kbd_mouse_x
        bne     ret_ok
        lda     kbd_mouse_x+1
        bne     ret_ok

        bit     drag_resize_flag
        bpl     :+
ret_ok: sec
        rts

:       jsr     get_winframerect
        lda     winrect::x2+1
        bne     min_ok
        lda     #9
        bit     set_input_params::modifiers
        bpl     :+

        lda     #65
:       cmp     winrect::x2
        bcc     min_ok
        clc
        rts

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
:       clc
        rts
.endproc


.proc kbd_mouse_check_xmax
        lda     kbd_mouse_state
        cmp     #kbd_mouse_state_mousekeys
        beq     :+

        bit     drag_resize_flag
        bmi     :+

        lda     kbd_mouse_x
        sbc     #<(screen_width-1)
        lda     kbd_mouse_x+1
        sbc     #>(screen_width-1)
        beq     is_max
        sec

:       sec
        rts

is_max: jsr     get_winframerect
        sec
        lda     #<(screen_width-1)
        sbc     winrect::x1
        tax
        lda     #>(screen_width-1)
        sbc     winrect::x1+1
        beq     :+

        ldx     #256-1
:       bit     set_input_modifiers
        bpl     :+

        cpx     #100
        bcc     clc_rts
        bcs     ge_100

:       cpx     #44
        bcc     clc_rts
        bcs     in_range

clc_rts:
        clc
        rts

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
        clc
        rts
.endproc


grew_flag:
        .byte   0

.proc set_grew_flag
        lda     #$80
        sta     grew_flag
grts:   rts
.endproc


.proc finish_grow
        bit     kbd_mouse_state
        bpl     set_grew_flag::grts

        bit     grew_flag
        bpl     set_grew_flag::grts

        jsr     get_winframerect
        php
        sei
        ldx     #0
:       sub16lc winrect::x2,x, #4, kbd_mouse_x,x
        inx
        inx
        cpx     #4
        bcc     :-

        jsr     position_kbd_mouse
        plp
        rts
.endproc

;;; ============================================================
;;; ScaleMouse

;;; Sets up mouse clamping

;;; 2 bytes of params, copied to $82
;;; byte 1 controls x clamp, 2 controls y clamp
;;; clamp is to fractions of screen (0 = full, 1 = 1/2, 2 = 1/4, 3 = 1/8) (why???)

.proc ScaleMouseImpl
        PARAM_BLOCK params, $82
x_exponent:     .res 1
y_exponent:     .res 1
        END_PARAM_BLOCK

        lda     params::x_exponent
        sta     mouse_scale_x
        lda     params::y_exponent
        sta     mouse_scale_y

set_clamps:
        bit     no_mouse_flag   ; called after INITMOUSE
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
        jsr     ScaleMouseImpl::set_clamps
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
