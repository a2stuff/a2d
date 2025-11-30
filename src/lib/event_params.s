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
;;; `findcontrolex_params` (with x/y matching event x/y)
;;; `findicon_params` (with x/y matching event x/y)
;;; `beginupdate_params` (with matching event window_id)
;;; ============================================================

PARAM_BLOCK event_params, *
kind    .byte
.union
;;; if `kind` is key_down
  .struct
    key             .byte
    modifiers       .byte
  .endstruct
;;; if `kind` is no_event, button_down/up, drag, or apple_key:
  .struct
    coords           .tag MGTK::Point
  .endstruct
  .struct
    xcoord          .word
    ycoord          .word
  .endstruct
;;; if `kind` is update:
  .struct
    window_id       .byte
  .endstruct
.endunion
END_PARAM_BLOCK

PARAM_BLOCK setctlmax_params, *
which_ctl       .byte
ctlmax          .byte
END_PARAM_BLOCK

PARAM_BLOCK activatectl_params, *
which_ctl       .byte
activate        .byte
END_PARAM_BLOCK

PARAM_BLOCK updatethumb_params, *
which_ctl       .byte
thumbpos        .byte
END_PARAM_BLOCK

PARAM_BLOCK trackthumb_params, *
which_ctl       .byte
mousex          .word
mousey          .word
thumbpos        .byte
thumbmoved      .byte
END_PARAM_BLOCK
ASSERT_EQUALS trackthumb_params::mousex, event_params::xcoord
ASSERT_EQUALS trackthumb_params::mousey, event_params::ycoord

ASSERT_EQUALS setctlmax_params::which_ctl, activatectl_params::which_ctl
ASSERT_EQUALS trackthumb_params::which_ctl, activatectl_params::which_ctl
ASSERT_EQUALS updatethumb_params::which_ctl, activatectl_params::which_ctl

PARAM_BLOCK screentowindow_params, *
window_id       .byte
.union
   screen       .tag MGTK::Point
   .struct
     screenx    .word
     screeny    .word
   .endstruct
.endunion
.union
   window       .tag MGTK::Point
   .struct
     windowx    .word
     windowy    .word
   .endstruct
.endunion
END_PARAM_BLOCK
ASSERT_EQUALS screentowindow_params::screenx, event_params::xcoord
ASSERT_EQUALS screentowindow_params::screeny, event_params::ycoord

PARAM_BLOCK dragwindow_params, *
window_id       .byte
dragx           .word
dragy           .word
moved           .byte
END_PARAM_BLOCK
ASSERT_EQUALS dragwindow_params::dragx, event_params::xcoord
ASSERT_EQUALS dragwindow_params::dragy, event_params::ycoord

PARAM_BLOCK growwindow_params, *
window_id       .byte
dragx           .word
dragy           .word
moved           .byte
END_PARAM_BLOCK
ASSERT_EQUALS growwindow_params::dragx, event_params::xcoord
ASSERT_EQUALS growwindow_params::dragy, event_params::ycoord

;;; --------------------------------------------------

;;; The following are offset so x/y overlap event_params x/y

PARAM_BLOCK findwindow_params, *+1
mousex          .word
mousey          .word
which_area      .byte
window_id       .byte
END_PARAM_BLOCK
ASSERT_EQUALS findwindow_params::mousex, event_params::xcoord
ASSERT_EQUALS findwindow_params::mousey, event_params::ycoord

PARAM_BLOCK findcontrol_params, *+1
mousex          .word
mousey          .word
which_ctl       .byte
which_part      .byte
END_PARAM_BLOCK
ASSERT_EQUALS findcontrol_params::mousex, event_params::xcoord
ASSERT_EQUALS findcontrol_params::mousey, event_params::ycoord

PARAM_BLOCK findcontrolex_params, *+1
mousex          .word
mousey          .word
which_ctl       .byte
which_part      .byte
window_id       .byte
END_PARAM_BLOCK
ASSERT_EQUALS findcontrolex_params::mousex, event_params::xcoord
ASSERT_EQUALS findcontrolex_params::mousey, event_params::ycoord

PARAM_BLOCK findicon_params, *+1
mousex          .word
mousey          .word
which_icon      .byte
window_id       .byte
END_PARAM_BLOCK
ASSERT_EQUALS findicon_params::mousex, event_params::xcoord
ASSERT_EQUALS findicon_params::mousey, event_params::ycoord

PARAM_BLOCK beginupdate_params, *+1
window_id       .byte
END_PARAM_BLOCK
ASSERT_EQUALS beginupdate_params::window_id, event_params::window_id

;;; Union of preceding param blocks
        .res    10, 0
