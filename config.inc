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
.define kDeskTopVersionSuffix "-alpha28"
.define kBuildDate "April 3, 2021"
kBuildYY = 21
kBuildMM = 4
kBuildDD = 3

;;; Localization - applies language suffix to filename

        .define kBuildLang "en"
.macro RESOURCE_FILE basename
        .include .concat("res/", basename, ".", kBuildLang)
.endmacro
