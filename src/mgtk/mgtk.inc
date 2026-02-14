;;; ============================================================
;;; MouseGraphics ToolKit (w/ Graphics Primitives)
;;; ============================================================

.scope MGTK

;;; ============================================================
;;; Graphics Primitives
;;; ============================================================

.struct Point
        xcoord  .word
        ycoord  .word
.endstruct

.struct Rect
        .union
        topleft .tag Point
        .struct
        x1      .word
        y1      .word
        .endstruct
        .endunion

        .union
        bottomright .tag Point
        .struct
        x2      .word
        y2      .word
        .endstruct
        .endunion
.endstruct

.struct Pattern
        row0    .byte
        row1    .byte
        row2    .byte
        row3    .byte
        row4    .byte
        row5    .byte
        row6    .byte
        row7    .byte
.endstruct

.struct MapInfo
        viewloc         .tag Point
        mapbits         .word   ; screen_mapbits=$2000 for windows, or bitmap bits
        mapwidth        .byte   ; screen_mapwidth=$80 for windows, or stride for bitmap
        reserved        .byte
        maprect         .tag Rect ; a.k.a. cliprect
.endstruct

.struct GrafPort
        ;; MapInfo
        viewloc         .tag Point   ; 0
        mapbits         .addr        ; 4
        mapwidth        .byte        ; 6
        reserved        .byte        ; 7
        maprect         .tag Rect    ; 8

        pattern         .tag Pattern ; 16
        colormasks      .byte 2      ; 24 colormask_and, colormask_or
        penloc          .tag Point   ; 26
        penwidth        .byte        ; 30 horizontal pen thickness
        penheight       .byte        ; 31 vertical pen thickness
        penmode         .byte        ; 32
        textback        .byte        ; 33 text background
        textfont        .addr        ; 34
.endstruct

;;; PolyList record:

;;; .byte       count           number of vertices in this polygon
;;; .byte       last            high bit set if there are more polygons
;;; Point       vertex1
;;; Point       vertex2
;;; ...

.struct Font
        fonttype        .byte   ; 0=regular, $80=double-width
        lastchar        .byte   ; char code of last character (usually $7F)
        height          .byte   ; pixels (1-16)
        charwidth       .byte   ; pixels, for each char
        ;; kRow0        .res N    bits
        ;; row0right    .res N    bits (double-width only)
.endstruct

NoOp            = $00           ; No-op
;;; (no parameters)

;;; --------------------------------------------------
;;; Initialization Commands

InitGraf        = $01
;;; (no parameters)

SetSwitches     = $02           ; Configure display switches
;;; .byte       flags           bit 0=hires, 1=page2, 2=mixed, 3=text

;;; --------------------------------------------------
;;; GrafPort Commands

InitPort        = $03           ; Initialize GrafPort to standard values
;;; (input is address of GrafPort record)

SetPort         = $04           ; Set current port as specified
;;; (input is address of GrafPort record)

GetPort         = $05           ; Get pointer to current port
;;; .addr       port            (out)

SetPortBits     = $06           ; Set just the mapinfo (viewloc, mapbits)
;;; (input is address of MapInfo record)

SetPenMode      = $07           ; Set the current pen mode
;;; .byte       mode            pen*/notpen*

SetPattern      = $08           ; Set the current pattern
;;; .res 8      pattern         8x8 pixel pattern for PaintRect calls

SetColorMasks   = $09           ; Set the current color masks
;;; .byte       and_mask
;;; .byte       or_mask

SetPenSize      = $0A           ; Set the current pen size
;;; .byte       penwidth        horizontal pen thickness
;;; .byte       penheight       vertical pen thickness

SetFont         = $0B           ; Set the current font
;;; .addr       textfont        font definition

SetTextBG       = $0C           ; Set the current text background
;;; .byte       backcolor       0=black, $7F=white

;;; --------------------------------------------------
;;; Drawing Commands

Move            = $0D           ; Set current pen location (relative)
;;; .word       xdelta
;;; .word       ydelta

MoveTo          = $0E           ; Set current pen location (absolute)
;;; Point        pos

Line            = $0F           ; Draw line from current pen location (relative)
;;; .word       xdelta
;;; .word       ydelta

LineTo          = $10           ; Draw line from current pen location (absolute)
;;; Point       pos

PaintRect       = $11           ; Fill rectangle with selected simple pattern/thickness
;;; Rect        rect

FrameRect       = $12           ; Draw rectangle with selected simple pattern/thickness
;;; Rect        rect

InRect          = $13           ; Is current position in bounds? A=$80 true, 0 false
;;; Rect        rect

PaintBits       = $14           ; Draw pattern
;;; (input is address of MapInfo record)

PaintPoly       = $15
;;; (input is address of PolyList record)

FramePoly       = $16           ; Draw multiple closed polygons
;;; (input is address of PolyList record)

InPoly          = $17           ; Is current position in bounds? A=$80 true, 0 false
;;; (input is address of PolyList record)


;;; --------------------------------------------------
;;; Text Commands

TextWidth       = $18           ; Measure the width of a string in pixels
;;; .addr       data
;;; .byte       length
;;; .word       width           (out) result in pixels
.struct TextWidthParams
data    .addr
length  .byte
width   .word
.endstruct

DrawText        = $19           ; Drawn at penpos as left, baseline
;;; .addr       data
;;; .byte       length

;;; --------------------------------------------------
;;; Utility Commands

SetZP1          = $1A           ; Configure usage of upper ZP ($80-$FF) (speed vs. convenience)
SetZP2          = $1B           ; Configure usage of lower ZP ($00-$43) (speed vs. convenience)
;;; .byte       preserve        $00=stash/no auto restore; $80=restore now and onward

Version         = $1C           ; Get toolkit version
;;; .byte       (out) major
;;; .byte       (out) minor
;;; .byte       (out) patch
;;; .byte       (out) status
;;; .word       (out) number

;;; ============================================================
;;; MouseGraphics ToolKit Calls
;;; ============================================================

;;; --------------------------------------------------
;;; Initialization Calls

StartDeskTop    = $1D           ; Inits state, registers interrupt handler, draws desktop
;;; .byte       machine         ROM FBB3 ($06 = IIe or later)
;;; .byte       subid           ROM FBC0 ($EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+)
;;; .byte       op_sys          0=ProDOS, 1=Pascal
;;; .byte       slot_num        Mouse slot, 0 = search (will be filled in)
;;; .byte       use_interrupts  0=passive, 1=interrupt
;;; .addr       sysfontptr
;;; .addr       savearea        buffer for saving screen data (e.g. behind menus)
;;; .word       savesize        bytes

StopDeskTop     = $1E           ; Deallocates interrupt, hides cursor
;;; (no parameters)

SetUserHook     = $1F
;;; .byte       hook_id         0=before, 1=after event checking
;;; .addr       routine_ptr     0=remove hook_id

AttachDriver    = $20           ; Install pointer driver; A=0 on success, $95 if mouse disabled
;;; .addr       hook            Mouse hook routine to install
;;; .addr       mouse_state     (out) Address of mouse state (.word x, y; .byte status)

ScaleMouse      = $21           ; Set mouse/screen scaling
;;; .byte       x_exponent      x-scale factor for mouse, 0...3
;;; .byte       y_exponent      y-scale factor for mouse, 0...3

KeyboardMouse   = $22           ; Next kOperation will be performed by keyboard
;;; (no parameters)

GetIntHandler   = $23           ; Get address of interrupt handler
;;; .addr       handler         (out) Address of interrupt handler (after cld)

;;; --------------------------------------------------
;;; Cursor Manager Calls

;;; Cursor record:
;;;

cursor_height                   = 12
cursor_width                    = 2

.struct Cursor
        bits    .byte   24      ; 2x12 byte bitmap (XOR'd after mask)
        mask    .byte   24      ; 2x12 byte mask (OR'd with screen)
        hotspot .byte   2       ; x, y - hotspot coords (pixels)
.endstruct

;;; A SystemCursor can be passed instead of an address to use
;;; one of the standard system cursors.
.enum SystemCursor
        pointer         = 1
        ibeam           = 2
        watch           = 3
.endenum

SetCursor       = $24           ; Set cursor definition
;;; (input is address of Cursor record)

ShowCursor      = $25           ; Return cursor to visibility
;;; (no parameters)

HideCursor      = $26           ; Cursor hidden until ShowCursor call
;;; (no parameters)

ObscureCursor   = $27           ; Cursor hidden until moved
;;; (no parameters)

GetCursorAdr    = $28           ; Get cursor definition
;;; .addr definition            (out) Address of cursor record

;;; --------------------------------------------------
;;; Event Manager Calls

.struct Event
        kind    .byte           ; EventKind::*
    .union
      .struct                   ; EventKind::down
        key     .byte           ; ASCII code; high bit clear
        modifiers .byte         ; 0=none, 1=open-apple, 2=solid-apple, 3=both
      .endstruct

      .struct                   ; EventKind::update
        window_id .byte
      .endstruct

      .union                    ; otherwise
        coords  .word 2
      .struct
        xcoord  .word
        ycoord  .word
      .endstruct
      .endunion
    .endunion
.endstruct

CheckEvents     = $29           ; Process mouse/kbd if GetEvent will be delayed.
;;; (no parameters)

GetEvent        = $2A
;;; (parameter is address of Event record)

FlushEvents     = $2B
;;; (no parameters)

PeekEvent       = $2C
;;; (parameter is address of Event record)

PostEvent       = $2D           ; Post event to queue
;;; (parameter is address of Event record)

SetKeyEvent     = $2E           ; If set, keypresses are ignored by Tool Kit
;;; .byte       handle_keys     high bit set = ignore keyboard, otherwise check

;;; --------------------------------------------------
;;; Menu Manager Calls

;;; Since 0 is a valid ASCII code (Ctrl+Shift+2 produces ^@ a.k.a.
;;; NUL), an arbitrary value with the high bit set should be used to
;;; signify "no shortuct".
no_shortcut = $FF

;;; Menu Bar record:
;;;
;;; .word       count           Number of menu bar items
;;; (array of...)

.struct MenuBarItem
        menu_id         .byte   ; Menu identifier
        disabled        .byte   ; Flag
        title           .addr   ; Address of length-prefixed string
        menu            .addr   ; Address of Menu record
        reserved        .res 6  ; Reserved
.endstruct


;;; Menu record:
;;;
;;; .byte       count           Number of items in menu
;;; .res  5     reserved        Reserved
;;; (array of...)

.struct MenuItem
        options         .byte ; bit 0=OA, 1=SA, 2=mark, 5=check, 6=filler, 7=disabled
        mark_char       .byte ; Custom mark character if mark option set
        char1           .byte ; ASCII code of shortcut #1 (e.g. uppercase B); or no_shortcut
        char2           .byte ; ASCII code of shortcut #2 (e.g. lowercase b, or same); or no_shortcut
        name            .addr ; Address of length-prefixed string
.endstruct

InitMenu        = $2F
;;; .byte       solid_char      char code to use for solid apple glyph
;;; .byte       open_char       char code to use for open apple glyph
;;; .byte       check_char      char code to use for checkmark glyph
;;; .byte       control_char    char code to use for control key glyph

SetMenu         = $30           ; Configure (and draw) menu
;;; (input is address of Menu Bar record)

MenuSelect      = $31           ; Enter modal loop for handling mouse-down on menu bar
;;; .byte       menu_id         (out) Top level menu identifier, or 0 if none
;;; .byte       menu_item       (out) Index (1-based) of item in menu, or 0 if none

MenuKey         = $32           ; Find menu item corresponding to keypress
;;; .byte       menu_id         (out)
;;; .byte       menu_item       (out)
;;; .byte       which_key
;;; .byte       key_mods        bit 0=OA, bit 1=SA

HiliteMenu      = $33           ; Toggle highlight state of menu
;;; .byte       menu_id

DisableMenu     = $34
;;; .byte       menu_id
;;; .byte       disable         0=enable, 1=disable

DisableItem     = $35
;;; .byte       menu_id
;;; .byte       menu_item
;;; .byte       disable         0=enable, 1=disable

CheckItem       = $36
;;; .byte       menu_id
;;; .byte       menu_item
;;; .byte       check           0=unchecked, 1=checked

SetMark         = $37
;;; .byte       menu_id
;;; .byte       menu_item
;;; .byte       set_char        0=use checkmark, 1=use mark_char
;;; .byte       mark_char       char code to use for mark

;;; --------------------------------------------------
;;; Window Manager Calls

.struct Winfo
        window_id          .byte ; 0
        options            .byte ; 1 Option::*
        title              .addr ; 2
        hscroll            .byte ; 4 Scroll::option_*
        vscroll            .byte ; 5 Scroll::option_*
        hthumbmax          .byte ; 6
        hthumbpos          .byte ; 7
        vthumbmax          .byte ; 8
        vthumbpos          .byte ; 9
        status             .byte ; 10
        reserved           .byte ; 11
        mincontwidth       .word ; 12 minimum content size (horizontal)
        mincontheight      .word ; 14 minimum content size (vertical)
        maxcontwidth       .word ; 16 maximum content size (horizontal)
        maxcontheight      .word ; 18 maximum content size (vertical)
        port               .tag GrafPort ; 20
        nextwinfo          .addr ; 54 address of next lower window in stack
.endstruct

OpenWindow      = $38
;;; (input is address of Winfo record)

CloseWindow     = $39
;;; .byte window_id

CloseAll        = $3A
;;; (no parameters)

GetWinPtr       = $3B           ; Get pointer to window params by id; A=0 on success
;;; .byte       window_id
;;; .addr       window_ptr      (out) winfo address

GetWinPort      = $3C           ; Get drawing state of window (possibly clipped)
;;; .byte       window_id
;;; .addr       port            address of grafport to populate

SetWinPort      = $3D           ; Update port of window
;;; .byte       window_id
;;; .addr       port            GrafPort to copy from

BeginUpdate     = $3E           ; Respond to update event for window
;;; .byte       window_id

EndUpdate       = $3F
;;; (no parameters)

FindWindow      = $40
;;; .word       mousex          screen coordinates
;;; .word       mousey
;;; .byte       which_area      (out) Area::*
;;; .byte       window_id       (out) of window
.struct FindWindowParams
mousex          .word
mousey          .word
which_area      .byte
window_id       .byte
.endstruct

FrontWindow     = $41           ; Get id of top window
;;; .byte       window_id       (out) window, or 0 if none

SelectWindow    = $42           ; Make window topmost
;;; .byte       window_id

TrackGoAway     = $43
;;; .byte       clicked         (out) 0 = canceled, 1 = close

DragWindow      = $44
;;; .byte       window_id
;;; .word       dragx           mouse coords
;;; .word       dragy
;;; .byte       moved           high bit set if moved, clear if not

GrowWindow      = $45
;;; .byte       window_id
;;; .word       mousex
;;; .word       mousey
;;; .byte       itgrew          (out) 0 = no change, 1 = moved

ScreenToWindow  = $46           ; Map screen coords to content coords
;;; .byte       window_id
;;; .word       screenx
;;; .word       screeny
;;; .word       windowx         (out)
;;; .word       windowy         (out)
.struct ScreenToWindowParams
window_id       .byte
.union
screen          .tag MGTK::Point
.struct
screenx         .word
screeny         .word
.endstruct
.endunion
.union
window          .tag MGTK::Point
.struct
windowx         .word
windowy         .word
.endstruct
.endunion
.endstruct

WindowToScreen  = $47           ; Map content coords to screen coords
;;; .byte       window_id
;;; .word       windowx
;;; .word       windowy
;;; .word       screenx         (out)
;;; .word       screeny         (out)
.struct WindowToScreenParams
window_id       .byte
.union
window          .tag MGTK::Point
.struct
windowx         .word
windowy         .word
.endstruct
.endunion
.union
screen          .tag MGTK::Point
.struct
screenx         .word
screeny         .word
.endstruct
.endunion
.endstruct

;;; --------------------------------------------------
;;; Control Manager Calls

FindControl     = $48
;;; .word       mousex
;;; .word       mousey
;;; .byte       which_ctl       (out) Ctl::*
;;; .byte       which_part      (out) Part::*

SetCtlMax       = $49
;;; .byte       which_ctl       Ctl::*_scroll_bar
;;; .byte       ctlmax          maximum value

TrackThumb      = $4A
;;; .byte       which_ctl       Ctl::*_scroll_bar
;;; .word       mousex
;;; .word       mousey
;;; .byte       thumbpos        (out) 0...255
;;; .byte       thumbmoved      (out) 0 = no change, 1 = moved

UpdateThumb     = $4B
;;; .byte       which_ctl       Ctl::*_scroll_bar
;;; .byte       thumbpos        new position 0...250

ActivateCtl     = $4C           ; Activate/deactivate scroll bar
;;; .byte       which_ctl       Ctl::*_scroll_bar
;;; .byte       activate        0=deactivate, 1=activate

;;; --------------------------------------------------
;;; Extra Calls

BitBlt          = $4D
;;; (input length: 16 bytes)

GetDeskPat      = $4E
;;; .addr       pattern         (out) Address of desktop pattern

SetDeskPat      = $4F
;;; .res 8      pattern         8x8 pixel pattern to use for desktop

DrawMenuBar     = $50           ; Redraw menu bar
;;; (no parameters)

GetWinFrameRect = $51           ; Get outer frame rect of window
;;; .byte window_id
;;; Rect        rect            (out)

RedrawDeskTop   = $52           ; Redraw desktop, post updates for desktop and all windows
;;; (no parameters)

FindControlEx   = $53           ; Like FindControl, but works on non-topmost windows
;;; .word       mousex
;;; .word       mousey
;;; .byte       which_ctl       (out) Ctl::*
;;; .byte       which_part      (out) Part::*
;;; .byte       window_id

FlashMenuBar    = $54           ; Inverts menu bar (e.g. for silent alerts)
;;; (no parameters)

SaveScreenRect        = $55
;;; Rect        rect

RestoreScreenRect     = $56
;;; Rect        rect

InflateRect           = $57
;;; .addr       rect            Address of MGTK::Rect
;;; .word       xdelta
;;; .word       ydelta

UnionRects            = $58
;;; .addr       rect1           Address of MGTK::Rect
;;; .addr       rect2           Address of MGTK::Rect

MulDiv                = $59
;;; .word       number
;;; .word       numerator
;;; .word       denominator
;;; .word       result
;;; .word       remainder

ShieldCursor          = $5A     ; Hide cursor if intersects rect
;;; Rect        rect

UnshieldCursor        = $5B
;;; (no parameters)

StringWidth           = $5C
;;; .addr       str             Address of Pascal string
;;; .word       width           (out) result in pixels

DrawString            = $5D
;;; .addr       str             Address of Pascal string

WaitVBL               = $5E
;;; (no parameters)

;;; ============================================================
;;; Graphics Primitives Constants

;;; Used in GetWinPort / SetPortBits
screen_mapbits  = $2000         ; Screen address
screen_mapwidth = $80           ; Stride in bytes

;;; Used in SetPenMode
pencopy         = 0
penOR           = 1
penXOR          = 2
penBIC          = 3
notpencopy      = 4
notpenOR        = 5
notpenXOR       = 6
notpenBIC       = 7

;;; Used in SetZP1/SetZP2
zp_overwrite       = 0
zp_preserve        = 1<<7

;;; Used in GrafPorts
colormask_and      = $FF
colormask_or       = $00
textbg_black       = $00
textbg_white       = $7F

;;; ============================================================
;;; MouseGraphics ToolKit Constants

;;; Used in GetEvent
.enum EventKind
        no_event        = 0     ; No mouse or keypress
        button_down     = 1     ; Mouse button was depressed
        button_up       = 2     ; Mouse button was released
        key_down        = 3     ; Key was pressed
        drag            = 4     ; Mouse button still down
        apple_key       = 5     ; Mouse button was depressed, modifier key down
        update          = 6     ; Window update needed
.endenum

event_modifier_open_apple  = 1 << 0
event_modifier_solid_apple = 1 << 1

;;; Used in FindWindow
.enum Area
        desktop         = 0
        menubar         = 1
        content         = 2             ; Includes scroll bars
        dragbar         = 3
        grow_box        = 4
        close_box       = 5
.endenum

;;; Used in FindControl, TrackThumb, UpdateThumb
.enum Ctl
        not_a_control           = 0
        vertical_scroll_bar     = 1
        horizontal_scroll_bar   = 2
        dead_zone               = 3
.endenum

;;; Used in FindControl
.enum Part
        inactive        = 0
        up_arrow        = 1
        left_arrow      = 1
        down_arrow      = 2
        right_arrow     = 2
        page_up         = 3
        page_left       = 3
        page_down       = 4
        page_right      = 4
        thumb           = 5
.endenum

;;; Used in OpenWindow
.enum Option
        dialog_box       = 1 << 0
        go_away_box      = 1 << 1
        grow_box         = 1 << 2
.endenum

.enum Scroll
        option_none      = 0
        option_present   = 1 << 7
        option_thumb     = 1 << 6
        option_active    = 1 << 0
        option_normal    = Scroll::option_present | Scroll::option_thumb | Scroll::option_active
.endenum

;;; Used in menu structs
.enum MenuOpt
        open_apple      = 1 << 0
        solid_apple     = 1 << 1
        item_has_mark   = 1 << 2
        item_is_checked = 1 << 5
        item_is_filler  = 1 << 6
        disable_flag    = 1 << 7
.endenum

max_menu_items          = 16

disablemenu_enable      = 0
disablemenu_disable     = 1
disableitem_enable      = 0
disableitem_disable     = 1

checkitem_uncheck       = 0
checkitem_check         = 1

;;; Used in ActivateCtl
activatectl_deactivate  = 0
activatectl_activate    = 1

;;; Response from InRect/InPoly
inrect_inside           = $80
inrect_outside          = $00
inpoly_inside           = $80
inpoly_outside          = $00

;;; ============================================================
;;; Offsets

short_event_size                = 4        ; events that don't have mouse coordinates
event_size                      = 5        ; any kind of event

;;; ============================================================
;;; Errors

.enum Error
        empty_object    = $81
        bad_object      = $82
        font_too_big    = $83

        invalid_op_sys          = $90
        no_mouse                = $92
        invalid_irq_setting     = $93
        invalid_hook            = $94
        desktop_already_initialized     = $95
        irq_in_use              = $97
        invalid_event           = $98
        event_queue_full        = $99
        menu_not_found          = $9A
        menu_item_not_found     = $9B
        insufficient_savebehind_area    = $9C
        window_already_exists   = $9D
        window_id_required      = $9E
        window_not_found        = $9F
        no_active_window        = $A0
        window_not_draggable    = $A1
        window_not_resizable    = $A2
        window_obscured         = $A3
        control_not_found       = $A4
.endenum

.endscope ; MGTK

;;; ============================================================
;;; Macros

;;; Call an MGTK entry point:
;;;     MGTK_CALL n                      - params is $0000
;;;     MGTK_CALL n, params_addr
;;;     MGTK_CALL m, params_addr, label  - params_addr is labeled for modifying
;;; Callers must define MGTKEntry as the entry point.

.macro  MGTK_CALL    op, addr, label
        jsr MGTKEntry
        .byte op

.if .paramcount > 2
        label := *
.endif

.if .paramcount > 1
        .addr addr
.else
        .addr 0
.endif
.endmacro

;;; ------------------------------------

;;; Rect definition.
;;;    DEFINE_RECT ident,0,0,20,30
.macro DEFINE_RECT ident, left, top, right, bottom
        ;; A .struct is used here so that .sizeof(topleft) (etc) works
PARAM_BLOCK ident, *
.union
topleft .word 2
.struct
x1      .word
y1      .word
.endstruct
.endunion
.union
bottomright .word 2
.struct
x2      .word
y2      .word
.endstruct
.endunion
END_PARAM_BLOCK
        .refto ident::topleft
        .refto ident::x1
        .refto ident::y1
        .refto ident::bottomright
        .refto ident::x2
        .refto ident::y2
        .word AS_WORD(left), AS_WORD(top), AS_WORD(right), AS_WORD(bottom)
.endmacro

;;; Define a rect by size (right = left + width, bottom = top + height)
.macro DEFINE_RECT_SZ ident, left, top, width, height
        DEFINE_RECT ident, (left), (top), (left) + (width), (top) + (height)
.endmacro

;;; Define an inset rect rect by size
.macro DEFINE_RECT_INSET ident, left, top, width, height
        DEFINE_RECT ident, (left), (top), (width) - (left), (height) - (top)
.endmacro

;;; Point definition.
;;;    DEFINE_POINT ident,10,20
.macro DEFINE_POINT ident, left, top
        WARN_IF_SHADOWING ident
        ident := *
.scope ident
xcoord: .word   AS_WORD(left)
ycoord: .word   AS_WORD(top)
        .refto xcoord
        .refto ycoord
.endscope ; ident
.endmacro

;;; Menus (common cases; other options are possible)

.macro DEFINE_MENU_BAR ident, count
        WARN_IF_SHADOWING ident
        ident := *
        .byte   count           ; num menus
        .byte   0               ; reserved
.endmacro

.macro DEFINE_MENU_BAR_ITEM id, label, menu
        .byte   id              ; menu id
        .byte   0               ; disable flag
        .addr   label           ; title pointer
        .addr   menu            ; pointer to menu
        .res    6, 0            ; 6 reserved bytes
.endmacro

.macro DEFINE_MENU ident, count
        WARN_IF_SHADOWING ident
        ident := *
        .byte   count           ; num items
        .res    5, 0            ; 5 reserved bytes
.endmacro

;;; For menu items with open-apple modifier shortcuts, or no shortcuts
;;; NOTE: If shortcut is A-Z, char2 is to_lower(char1)
.macro DEFINE_MENU_ITEM saddr, shortcut
    .ifnblank shortcut

        .byte   MGTK::MenuOpt::open_apple|MGTK::MenuOpt::solid_apple ; option byte
        .byte   0               ; mark_char
        .byte   shortcut        ; char1

      .if kBuildSupportsLowercase && 'A' <= shortcut && shortcut <= 'Z'
        .byte   TO_LOWER(shortcut) ; char2
      .else
        .byte   MGTK::no_shortcut
      .endif
        .addr   saddr           ; item_str_pointer

    .else

        .byte   0               ; option byte
        .byte   0               ; mark_char
        .byte   MGTK::no_shortcut ; char1
        .byte   MGTK::no_shortcut ; char2
        .addr   saddr           ; item_str_pointer

    .endif
.endmacro

;;; For menu items with control keys (e.g. CHAR_RETURN), requiring no modifiers
.macro DEFINE_MENU_ITEM_NOMOD saddr, shortcut1, shortcut2
        .byte   0               ; option byte
        .byte   0               ; mark_char
        .byte   shortcut1       ; char1
    .ifnblank shortcut2
        .byte   shortcut2       ; char2
    .else
        .byte   MGTK::no_shortcut
    .endif
        .addr   saddr           ; item_str_pointer
.endmacro

.macro DEFINE_MENU_SEPARATOR
        .byte   MGTK::MenuOpt::item_is_filler ; option byte
        .byte   0                       ; mark_char
        .byte   19                      ; char1 - Ctrl+S for separator ???
        .byte   0                       ; char2
        .addr   0                       ; item_str_pointer
.endmacro

;;; ------------------------------------

;;; Suppress "Warning: Sumbol 'xxx' is defined but never used"
;;; when using a param block to define a Winfo structure.
;;; (Note: Not seen in the default warning level for builds.)
.macro REF_WINFO_MEMBERS
        .refto window_id
        .refto options
        .refto title
        .refto hscroll
        .refto vscroll
        .refto hthumbpos
        .refto vthumbpos
        .refto hthumbmax
        .refto vthumbmax
        .refto status
        .refto reserved
        .refto mincontwidth
        .refto mincontheight
        .refto maxcontwidth
        .refto maxcontheight
        .refto port
        .refto viewloc
        .refto mapbits
        .refto mapwidth
        .refto reserved2
        .refto maprect
        .refto pattern
        .refto colormasks
        .refto penloc
        .refto penwidth
        .refto penheight
        .refto penmode
        .refto textback
        .refto textfont
        .refto nextwinfo
.endmacro

.macro REF_GRAFPORT_MEMBERS
        .refto viewloc
        .refto mapbits
        .refto mapwidth
        .refto reserved
        .refto maprect
        .refto pattern
        .refto colormasks
        .refto penloc
        .refto penwidth
        .refto penheight
        .refto penmode
        .refto textback
        .refto textfont
.endmacro

.macro REF_MAPINFO_MEMBERS
        .refto viewloc
        .refto mapbits
        .refto mapwidth
        .refto reserved
        .refto maprect
.endmacro

.macro REF_MULDIV_MEMBERS
        .refto number
        .refto numerator
        .refto denominator
        .refto result
        .refto remainder
.endmacro

;;; ------------------------------------

;;; Define pattern for PaintBits as a string
;;; * '#' is a 1 bit, anything else is a 0
;;; * must be a multiple of 7 pixels wide.
;;; e.g. PXS "..##############....."
.macro PIXELS str, dummy
        .if .paramcount < 2

        ;; Pad out with 0 bits
        PIXELS .concat(str, "......"), 1234

        .else

        ;; Process each 7 characters into a byte.
        .repeat .strlen(str) / 7, idx
        __pixel__ .set idx * 7
        .byte ((.strat(str, __pixel__+0) = '#') << 0) | ((.strat(str, __pixel__+1) = '#') << 1) | ((.strat(str, __pixel__+2) = '#') << 2) | ((.strat(str, __pixel__+3) = '#') << 3) | ((.strat(str, __pixel__+4) = '#') << 4) | ((.strat(str, __pixel__+5) = '#') << 5) | ((.strat(str, __pixel__+6) = '#') << 6)
        .endrepeat

        .endif
.endmacro
