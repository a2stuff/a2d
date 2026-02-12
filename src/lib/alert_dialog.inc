;;; ============================================================
;;; Alert library options. See `lib/alert_dialog.s`
;;; ============================================================

.ifndef ALERT_DIALOG_INC
ALERT_DIALOG_INC = 1

;;; Button options
;;; $C0 (%11xxxxxx) = Cancel + OK
;;; $81 (%10xxxxx1) = Cancel + Yes + No + All
;;; $80 (%10xx0000) = Cancel + Try Again
;;; $00 (%0xxxxxxx) = OK
;;; Note: Other values reserved for wrapper APIs to use, e.g. $01 for
;;; "use default options for that id", etc.
.enum AlertButtonOptions
        OKCancel       = $C0
        YesNoAllCancel = $81
        TryAgainCancel = $80
        OK             = $00
.endenum

.enum AlertOptions
        Beep       = %10000000  ; N = play beep sound
        SaveBack   = %01000000  ; V = save/restore background
.endenum

kAlertResultTryAgain    = 0
kAlertResultCancel      = 1
kAlertResultOK          = 2
kAlertResultYes         = 3
kAlertResultNo          = 4
kAlertResultAll         = 5

.struct AlertParams
        text           .addr
        buttons        .byte    ; AlertButtonOptions
        options        .byte    ; AlertOptions flags
.endstruct

;;; NOTE: See the Rename code in DeskTop for a use case for having
;;; TryAgain and OK differ. In that example, the error code determines
;;; the options (OK vs. Try Again / Cancel), and OK after a failure is
;;; the same as Cancel (give up), not Try Again.

.endif ; ALERT_DIALOG_INC
