;;; ------------------------------
;;; Mouse Peripheral Card
;;; ------------------------------

;;; Firmware Routines

SETMOUSE        := $12
SERVEMOUSE      := $13
READMOUSE       := $14
CLEARMOUSE      := $15
POSMOUSE        := $16
CLAMPMOUSE      := $17
HOMEMOUSE       := $18
INITMOUSE       := $19

;;; Constants

CLAMP_X         := 0
CLAMP_Y         := 1

MOUSE_MODE_OFF  := $00
MOUSE_MODE_TRANS:= $01
MOUSE_MODE_INT  := $03
MOUSE_MODE_BTN  := $05


;;; RAM Locations

CLAMP_MIN_LO    := $478
CLAMP_MIN_HI    := $578
CLAMP_MAX_LO    := $4F8
CLAMP_MAX_HI    := $5F8

;;; RAM Locations
;;; (Add $Cn where n is slot to these)

MOUSE_X_LO      := $03B8
MOUSE_X_HI      := $04B8
MOUSE_Y_LO      := $0438
MOUSE_Y_HI      := $0538
MOUSE_STATUS    := $06B8
MOUSE_MODE      := $0738
