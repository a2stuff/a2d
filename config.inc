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
.define kDeskTopVersionSuffix "-alpha39"
.define kBuildDate " 24, 2021"
kBuildYY = 21
kBuildMM = 11
kBuildDD = 24

;;; Localization - applies language suffix to filename

        .define kBuildLang "en"
        .define RESOURCE_FILE(basename) .include .concat("res/", basename, ".", kBuildLang)
