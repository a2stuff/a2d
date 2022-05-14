;;; ============================================================
;;; Consolidated event params
;;;
;;; Reserves 10 bytes of space, and provides event params with
;;; overlapping structs for:
;;; `event_params`
;;; `activatectl_params`
;;; `trackthumb_params` (with x/y matching event x/y)
;;; `updatethumb_params`
;;; `screentowindow_params` (with screen x/y matching event x/y)
;;; `findwindow_params` (with x/y matching event x/y)
;;; `findcontrol_params` (with x/y matching event x/y)
;;; `findicon_params` (with x/y matching event x/y)
;;; ============================================================

.params event_params
kind := * + 0
        ;; if `kind` is key_down
key := * + 1
modifiers := * + 2
        ;; if `kind` is no_event, button_down/up, drag, or apple_key:
coords := * + 1
xcoord := * + 1
ycoord := * + 3
        ;; if `kind` is update:
window_id := * + 1
.endparams
event_kind := event_params::kind
event_coords := event_params::coords

.params setctlmax_params
which_ctl := * + 0
ctlmax    := * + 1
.endparams

.params activatectl_params
which_ctl := * + 0
activate  := * + 1
.endparams

.params trackthumb_params
which_ctl := * + 0
mousex := * + 1
mousey := * + 3
thumbpos := * + 5
thumbmoved := * + 6
        .assert mousex = event_params::xcoord, error, "param mismatch"
        .assert mousey = event_params::ycoord, error, "param mismatch"
.endparams

.params updatethumb_params
which_ctl := * + 0
thumbpos := * + 1
stash := * + 5 ; not part of struct
.endproc

.params screentowindow_params
window_id := * + 0
screen  := * + 1
screenx := * + 1
screeny := * + 3
window  := * + 5
windowx := * + 5
windowy := * + 7
        .assert screenx = event_params::xcoord, error, "param mismatch"
        .assert screeny = event_params::ycoord, error, "param mismatch"
.endproc
;;; Needed for case where this file appears after code:
screentowindow_window_id := screentowindow_params::window_id
screentowindow_windowx := screentowindow_params::windowx

.params dragwindow_params
window_id      := *
dragx   := * + 1
dragy   := * + 3
moved   := * + 5
        .assert dragx = event_params::xcoord, error, "param mismatch"
        .assert dragy = event_params::ycoord, error, "param mismatch"
.endparams

;;; --------------------------------------------------

;;; The following are offset so x/y overlap event_params x/y
.pushorg *+1

.params findwindow_params
mousex := * + 0
mousey := * + 2
which_area := * + 4
window_id := * + 5
        .assert mousex = event_params::xcoord, error, "param mismatch"
        .assert mousey = event_params::ycoord, error, "param mismatch"
.endparams

.params findcontrol_params
mousex := * + 0
mousey := * + 2
which_ctl := * + 4
which_part := * + 5
        .assert mousex = event_params::xcoord, error, "param mismatch"
        .assert mousey = event_params::ycoord, error, "param mismatch"
.endparams

.params findicon_params
mousex := * + 0
mousey := * + 2
which_icon := * + 4
window_id := * + 5
        .assert mousex = event_params::xcoord, error, "param mismatch"
        .assert mousey = event_params::ycoord, error, "param mismatch"
.endparams

.params beginupdate_params
window_id := * + 0
        .assert window_id = event_params::window_id, error, "param mismatch"
.endparams

.poporg

;;; --------------------------------------------------

;;; Union of preceding param blocks
        .res    10, 0
