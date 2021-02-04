;;; ============================================================
;;; Build Configuration
;;;
;;; Must be included by all targets
;;; ============================================================

;;; Build configuration
        .setcpu "6502"
        .feature string_escapes


;;; Localization - applies language suffix to filename
        .define LANG "en"
.macro RESOURCE_FILE basename
        .include .concat(basename, ".", LANG)
.endmacro
