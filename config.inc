;;; ============================================================
;;; Build Configuration
;;;
;;; Must be included by all targets
;;; ============================================================

;;; Build configuration

        .setcpu "6502"
        .feature string_escapes

;;; Product Info

.define kDeskTopProductName "Apple II DeskTop"
kDeskTopVersionMajor = 1
kDeskTopVersionMinor = 2
.define kDeskTopVersionSuffix "-alpha27"
.define kBuildDate "March 6, 2021"
kBuildYY = 21
kBuildMM = 3
kBuildDD = 6

;;; Localization - applies language suffix to filename

        .define LANG "en"
.macro RESOURCE_FILE basename
        .include .concat(basename, ".", LANG)
.endmacro
