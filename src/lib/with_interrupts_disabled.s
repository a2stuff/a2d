;;; ============================================================
;;; Wrapper for calling procs with interrupts disabled.
;;; Inputs: A,X = proc to call
;;; Outputs: A,X,Y registers and C flag return from proc unscathed.
;;; Other flags will be trashed.
;;; ============================================================

.proc WithInterruptsDisabled
        stax    addr

        ;; Disable interrupts
        php
        sei

        addr := *+1
        jsr     SELF_MODIFIED

        ;; Restore interrupts, while stashing/restoring C
        rol     tmp
        plp
        ror     tmp

        rts

tmp:    .byte   0
.endproc ; WithInterruptsDisabled
