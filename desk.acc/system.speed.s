;;; ============================================================
;;; SYSTEM.SPEED - Desk Accessory
;;;
;;; Allows toggling the machine's accelerator (if present)
;;; between normal and fast speed.
;;;
;;; Based on NORMFAST by "Roger" et. al. on comp.sys.apple2
;;; 3b74ddcf-190c-4591-bced-17e165ece668@googlegroups.com
;;; https://groups.google.com/d/topic/comp.sys.apple2/e-2Lx-CR1dM/discussion
;;;
;;; Should support:
;;; * Apple IIgs, IIc+, Macintosh IIe Option Card, Laser 128EX
;;; * FASTChip, Zip Chip, TransWarp I, UltraWarp
;;; ============================================================

        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        .org DA_LOAD_ADDRESS

start:
;;; ============================================================

        jmp     copy2aux


stash_stack:  .byte   $00

;;; ============================================================

.proc copy2aux

        end   := last

        tsx
        stx     stash_stack

        copy16  #start, STARTLO
        copy16  #end, ENDLO
        copy16  #start, DESTINATIONLO
        sec
        jsr     AUXMOVE

        ;; Run from Aux
        sta     RAMRDON
        sta     RAMWRTON

        jsr     run_da

        ;; Back to main
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     stash_stack
        txs
        rts
.endproc

;;; ============================================================
;;; Param blocks

kDAWindowId     = 100
kDAWidth        = 290
kDAHeight       = 70
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

kButtonInsetX   = 25

        DEFINE_BUTTON norm, {"Normal         N"}, kButtonInsetX, 28
        DEFINE_BUTTON fast, {"Fast           F"}, kDAWidth - kButtonWidth - kButtonInsetX, 28
        DEFINE_BUTTON ok,   {"OK            ",kGlyphReturn}, kDAWidth - kButtonWidth - kButtonInsetX, 52

title_pos:
        DEFINE_POINT (kDAWidth - 70)/ 2, 18
title_label:
        PASCAL_STRING "System Speed"

;;; ============================================================

event_params := *
event_kind := event_params + 0
        ;; if kind is key_down
event_key := event_params + 1
event_modifiers := event_params + 2
        ;; if kind is no_event, button_down/up, drag, or apple_key:
event_coords := event_params + 1
event_xcoord := event_params + 1
event_ycoord := event_params + 3
        ;; if kind is update:
event_window_id := event_params + 1

screentowindow_params := *
screentowindow_window_id := screentowindow_params + 0
screentowindow_screenx := screentowindow_params + 1
screentowindow_screeny := screentowindow_params + 3
screentowindow_windowx := screentowindow_params + 5
screentowindow_windowy := screentowindow_params + 7
        .assert screentowindow_screenx = event_xcoord, error, "param mismatch"
        .assert screentowindow_screeny = event_ycoord, error, "param mismatch"

findwindow_params := * + 1    ; offset to x/y overlap event_params x/y
findwindow_mousex := findwindow_params + 0
findwindow_mousey := findwindow_params + 2
findwindow_which_area := findwindow_params + 4
findwindow_window_id := findwindow_params + 5
        .assert findwindow_mousex = event_xcoord, error, "param mismatch"
        .assert findwindow_mousey = event_ycoord, error, "param mismatch"

;;; Union of above params
        .res    10, 0

;;; ============================================================

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

pencopy:        .byte   0
penOR:          .byte   1
penXOR:         .byte   2
penBIC:         .byte   3
notpencopy:     .byte   4
notpenOR:       .byte   5
notpenXOR:      .byte   6
notpenBIC:      .byte   7

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
mincontlength:  .word   100
maxcontwidth:   .word   500
maxcontlength:  .word   500
port:
viewloc:        DEFINE_POINT kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
cliprect:       DEFINE_RECT 0, 0, kDAWidth, kDAHeight
pattern:        .res    8,$FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

frame_rect1:
        DEFINE_RECT_INSET 4,2,kDAWidth,kDAHeight
frame_rect2:
        DEFINE_RECT_INSET 5,3,kDAWidth,kDAHeight


.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   grafport
.endparams

grafport:       .tag MGTK::GrafPort


;;; ============================================================
;;; Initialize window, unpack the date.

.proc run_da
        MGTK_CALL MGTK::OpenWindow, winfo

        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::SetPenMode, penXOR

        MGTK_CALL MGTK::FrameRect, frame_rect1
        MGTK_CALL MGTK::FrameRect, frame_rect2

        MGTK_CALL MGTK::MoveTo, title_pos
        addr_call DrawString, title_label

        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        addr_call DrawString, ok_button_label

        MGTK_CALL MGTK::FrameRect, norm_button_rect
        MGTK_CALL MGTK::MoveTo, norm_button_pos
        addr_call DrawString, norm_button_label

        MGTK_CALL MGTK::FrameRect, fast_button_rect
        MGTK_CALL MGTK::MoveTo, fast_button_pos
        addr_call DrawString, fast_button_label

        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

;;; ============================================================
;;; Input loop

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        jeq     on_click

        cmp     #MGTK::EventKind::key_down
        bne     input_loop
.endproc

.proc on_key
        lda     event_modifiers
        bne     input_loop
        lda     event_key

        cmp     #CHAR_RETURN
        beq     on_key_ok

        cmp     #CHAR_ESCAPE
        beq     on_key_ok

        cmp     #'N'
        beq     on_key_norm

        cmp     #'F'
        beq     on_key_fast

        jmp     input_loop
.endproc

.proc on_key_ok
        lda     winfo::window_id
        jsr     get_window_port
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect

        jmp     close_window
.endproc

.proc on_key_norm
        lda     winfo::window_id
        jsr     get_window_port
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, norm_button_rect
        MGTK_CALL MGTK::PaintRect, norm_button_rect

        jsr     do_norm
        jmp     input_loop
.endproc

.proc on_key_fast
        lda     winfo::window_id
        jsr     get_window_port
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, fast_button_rect
        MGTK_CALL MGTK::PaintRect, fast_button_rect

        jsr     do_fast
        jmp     input_loop
.endproc

;;; ============================================================

.proc get_window_port
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc


;;; ============================================================

.proc on_click
        MGTK_CALL MGTK::FindWindow, findwindow_params

        lda     findwindow_window_id
        cmp     #kDAWindowId
        bne     miss

        lda     findwindow_which_area
        cmp     #MGTK::Area::content
        beq     hit

miss:   jmp     input_loop

hit:    lda     winfo::window_id
        jsr     get_window_port
        lda     winfo::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx

        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        jeq     on_click_ok

        MGTK_CALL MGTK::InRect, norm_button_rect
        cmp     #MGTK::inrect_inside
        jeq     on_click_norm

        MGTK_CALL MGTK::InRect, fast_button_rect
        cmp     #MGTK::inrect_inside
        jeq     on_click_fast

        jmp     input_loop
.endproc

;;; ============================================================

.proc on_click_ok
        yax_call button_event_loop, kDAWindowId, ok_button_rect
        jeq     close_window
        jmp     input_loop
.endproc

;;; ============================================================

.proc on_click_norm
        yax_call button_event_loop, kDAWindowId, norm_button_rect
        bne     :+
        jsr     do_norm
:       jmp     input_loop
.endproc

;;; ============================================================

.proc on_click_fast
        yax_call button_event_loop, kDAWindowId, fast_button_rect
        bne     :+
        jsr     do_fast
:       jmp     input_loop
.endproc

;;; ============================================================

.proc do_norm
        ;; Run NORMFAST with "normal" banks
        sta     RAMRDOFF
        sta     RAMWRTOFF
        sta     ALTZPOFF
        lda     ROMIN2

        jsr     NORMFAST_norm

        sta     RAMRDON
        sta     RAMWRTON
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        rts
.endproc

;;; ============================================================

.proc do_fast
        ;; Run NORMFAST with "normal" banks
        sta     RAMRDOFF
        sta     RAMWRTOFF
        sta     ALTZPOFF
        lda     ROMIN2

        jsr     NORMFAST_fast

        sta     RAMRDON
        sta     RAMWRTON
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        rts
.endproc

;;; ============================================================

.proc close_window
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        rts
.endproc


;;; ============================================================
;;; Event loop during button press - initial invert and
;;; inverting as mouse is dragged in/out.
;;; Input: A,X = rect address, Y = window_id
;;; Output: A=0/N=0/Z=1 = click, A=$80/N=1/Z=0 = cancel

.proc button_event_loop
        sty     window_id
        stax    rect_addr1
        stax    rect_addr2

        ;; Initial state
        copy    #0, down_flag

        ;; Do initial inversion
        MGTK_CALL MGTK::SetPenMode, penXOR
        jsr     invert

        ;; Event loop
loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     exit
        lda     window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, dummy0000, rect_addr1

        cmp     #MGTK::inrect_inside
        beq     inside
        lda     down_flag       ; outside but was inside?
        beq     toggle
        jmp     loop

inside: lda     down_flag       ; already depressed?
        bne     toggle
        jmp     loop

toggle: jsr     invert
        lda     down_flag
        eor     #$80
        sta     down_flag
        jmp     loop

exit:   lda     down_flag       ; was depressed?
        bne     :+
        jsr     invert
:       lda     down_flag
        rts

        ;; --------------------------------------------------

invert: MGTK_CALL MGTK::PaintRect, dummy0000, rect_addr2
        rts

        ;; --------------------------------------------------

down_flag:
        .byte   0

window_id:
        .byte   0
.endproc

;;; ============================================================
;;; Draw Pascal String
;;; Input: A,X = string address

.proc DrawString
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        sta     $08
        inc16   ptr
        MGTK_CALL MGTK::DrawText, params
        rts
.endproc

;;; ============================================================

.scope NORMFAST

;;; ------------------------------------------------------------
;;; Code from:
;;; 3b74ddcf-190c-4591-bced-17e165ece668@googlegroups.com
;;; https://groups.google.com/d/topic/comp.sys.apple2/e-2Lx-CR1dM/discussion
;;; * Converted to ca65 syntax (:=/= instead of .equ)
;;; * .org removed
;;; * 65c02 usage restricted to one opcode
;;; ------------------------------------------------------------

;;; NORMFAST Disable/enable Apple II compatible accelerator
;;;
;;; Release 6 2017-10-05 Fix Mac IIe card check
;;;
;;; Release 5 2017-09-27 Add Macintosh IIe Card. Addon
;;; accelerators are now set blindly, so will access
;;; annunciators/IIc locations and may trigger the
;;; paddle timer.
;;; No plans for the Saturn Systems Accelerator which would
;;; require a slot search.
;;;
;;; Release 4 2017-09-06 Add Laser 128EX, TransWarp I, UW
;;;
;;; Release 3 2017-08-29 Change FASTChip partially back to
;;; release 1, which seems to work the way release 2 was
;;; intended?!
;;;
;;; Release 2 2017-08-27 change enable entry point, add Zip
;;; Chip, change setting FASTChip speed to disable/enable
;;;
;;; Release 1 2017-08-25 IIGS, //c+ and FASTChip
;;;
;;; WARNING: The memory location to set the accelerator
;;; speed may overlap existing locations such as:
;;;   annuciators or Apple //c specific hardware
;;;   paddle trigger
;;;
;;; Known to work: IIGS, //c+
;;; Theoretically: FASTChip, Laser 128EX, Mac IIe Card,
;;;   TransWarp I, trademarked German product, Zip Chip
;;;
;;; BRUN NORMFAST or CALL 768 to disable the accelerator.
;;; CALL 771 to enable the accelerator.
;;; Enabling an older accelerator may set maximum speed.
;;; Accelerators such as the FASTChip or Zip Chip can run
;;; slower than 1Mhz when enabled.
;;;
;;; NORMFAST is position independent and can be loaded most
;;; anywhere in the first 48K of memory.
;;; The ROMs must be enabled to identify the model of the
;;; computer.
;;;
;;; This was originally for the //c+ which is normally
;;; difficult to set to 1Mhz speed.
;;; The other expected use is to set the speed in a program.
;;;
;;; Written for Andrew Jacobs' Java based dev65 assembler at
;;; http://sourceforge.net/projects/dev65 but has portability
;;; in mind.

;;; 6502 opcodes are preferred to be friendly to the old
;;; monitor disassemblers

;;; addresses are lowercase, constant values are in CAPS

RELEASE         =       6       ; our version

romid           :=      $FBB3
;;; $38=][, $EA=][+, $06=//e compatible
ROMID_IIECOMPAT =       6
romid_ec        :=      $FBC0
;;; $EA=//e original, $E0=//e enhanced, $E1=//e EDM, $00=//c
;;; Laser 128s are $E0
romid_c         :=      $FBBF
;;; $FF=original, $00=Unidisk 3.5 ... $05=//c+
ROMID_CPLUS     =       5
romid_maciie_2  :=      $FBDD   ; 2

;;; IIGS
idroutine       :=      $FE1F   ; SEC, JSR $FE1F, BCS notgs
gsspeed         :=      $C036
GS_FAST         =       $80     ; mask

;;; //c+ Cache Glue Gate Array (accelerator)
cgga            :=      $C7C7   ; entry point
CGGA_ENABLE     =       1       ; fast
CGGA_DISABLE    =       2       ; normal
CGGA_LOCK       =       3
CGGA_UNLOCK     =       4       ; required to make a change

;;; Macintosh IIe Card
maciie          :=      $C02B
MACIIE_FAST     =       4       ; mask

l128irqpage     =       $C4
;;; From the 4.2, 4.5 and EX2 ROM dumps at the Apple II
;;; Documentation Project, the Laser 128 IRQ handlers are
;;; in the $C4 page.
;;; A comp.sys.apple2 post says the 6.0 ROM for the 128 and
;;; 128EX are identical, so there may not be an easy way to
;;; tell a plain 128 from an (accelerated) 128EX.
irq             :=      $FFFE   ; 6502 IRQ vector

;;; may overlap with paddle trigger
ex_cfg          :=      $C074   ; bits 7 & 6 for speed
EX_NOTSPEED     =       $3F
EX_1MHZMASK     =       $0
EX_2MHZMASK     =       $80     ; 2.3Mhz
EX_3MHZMASK     =       $C0     ; 3.6Mhz

;;; FASTChip
fc_lock         :=      $C06A
FC_UNLOCK       =       $6A     ; write 4 times
FC_LOCK         =       $A6
fc_enable       :=      $C06B
fc_speed        :=      $C06D
FC_1MHZ         =       9
FC_ON           =       40      ; doco says 16.6Mhz

;;; TransWarp I
;;; may overlap with paddle trigger
tw1_speed       :=      $C074
TW1_1MHZ        =       1
TW1_MAX         =       0

;;; Trademarked German accelerator
;;; overlaps annunciator 2 & //c mouse interrupts
uw_fast         :=      $C05C
uw_1mhz         :=      $C05D

;;; Zip Chip
;;; overlaps annunciator 1 & //c vertical blank
zc_lock         :=      $C05A
ZC_UNLOCK       =       $5A     ; write 4 times
ZC_LOCK         =       $A5
zc_enable       :=      $C05B

iobase          :=      $C000   ; easily confused with kbd

        ;; .org    $300

        ; disable accelerator
norm:   lda     #1
        .byte   $2C     ; BIT <ABSOLUTE>, hide next lda #

        ; enable accelerator
fast:   lda     #0

        ldx     #RELEASE ; our release number

        ;; first check built-in accelerators

        ldx     romid
        cpx     #ROMID_IIECOMPAT
        bne     addon   ; not a //e

        ldx     romid_ec
        beq     iic     ; //c family

        ; not worth the bytes for enhanced //e check
        ldx     irq+1
        cpx     #l128irqpage
        bne     gscheck

        ; a Laser 128, hopefully harmless on a non EX

        ldy     #EX_3MHZMASK ; phew, all needed bits set
        ldx     #<ex_cfg

;;; setspeed - set 1Mhz with AND and fast with OR
;;;
;;; A = lsb set for normal speed
;;; X = low byte address of speed location
;;; Y = OR mask for fast

setspeed:
        lsr
        tya
        bcs     setnorm
        ora     iobase,x
        bne     setsta  ; always

setnorm:
        eor     #$FF
        and     iobase,x
setsta:
        sta     iobase,x
        rts

gscheck:
        pha
        sec
        jsr     idroutine
        pla
        bcs     maccheck ; not a gs

        ; set IIGS speed

        ldy     #GS_FAST
        ldx     #<gsspeed
        bne     setspeed ; always

maccheck:
        ldx     romid_maciie_2
        cpx     #2
        bne     addon   ; no built-in accelerator

        ; the IIe Card in a Mac

        ldy     #MACIIE_FAST
        ldx     #<maciie
        bne     setspeed ; always

iic:
        ldx     romid_c
        cpx     #ROMID_CPLUS
        bne     addon   ; not a //c+, eventually hit Zip

;;; Set //c+ speed. Uses the horrible firmware in case other
;;; code works "by the book", that is can check and set
;;; whether the accelerator is enabled.
;;; The //c+ is otherwise Zip compatible.

        .pushcpu
        .setcpu "65C02"
        inc     a       ; 65C02 $1A
        .popcpu

        ; cgga calls save X and Y regs but sets $0 to 0
        ; (this will get a laugh from C programmers)
        ldx     $0
        php
        sei             ; timing sensitive
        pha             ; action after CGGA_UNLOCK

        lda     #CGGA_UNLOCK  ; unlock to change
        pha
        jsr     cgga

        jsr     cgga    ; disable/enable

        lda     #CGGA_LOCK    ; should lock after a change
        pha
        jsr     cgga

        plp             ; restore interrupt state
        stx     $0
        rts

;;; At this point, the computer does not have a built-in
;;; accelerator
;;;
;;; Previous versions had tested fc_enable, which was not
;;; enough. Running low on space so just set blindly.

addon:
        ; TransWarp I

        sta     tw1_speed

        ; Zip Chip

        tay
        eor     #1
        tax
        lda     #ZC_UNLOCK
        php
        sei             ; timing sensitive
        sta     zc_lock
        sta     zc_lock
        sta     zc_lock
        sta     zc_lock
        lsr             ; not ZC_LOCK or ZC_UNLOCK
        sta     zc_lock,x  ; disable/enable
        lda     #ZC_LOCK
        sta     zc_lock

        ;; current products are subject to change so do
        ;; these last

        ; trademarked accelerator from Germany

        sta     uw_fast,y ; value does not matter

        ; FASTChip

        ldx     #FC_1MHZ
        tya
        bne     fcset
        ldx     #FC_ON  ; enable set speed?
fcset:
        lda     #FC_UNLOCK
        sta     fc_lock
        sta     fc_lock
        sta     fc_lock
        sta     fc_lock
        sta     fc_enable
        stx     fc_speed
        lda     #FC_LOCK
        sta     fc_lock
        plp             ; restore interrupt state
        rts

.endscope
        NORMFAST_norm := NORMFAST::norm
        NORMFAST_fast := NORMFAST::fast

;;; ============================================================

last := *
