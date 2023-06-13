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
kDeskTopVersionMinor = 4
.define kDeskTopVersionSuffix "-alpha0"
.define kBuildDate "June 1, 2023"
kBuildYYYY = 2023
kBuildYY = 23
kBuildMM = 6
kBuildDD = 1

;;; Localization - applies language suffix to filename

        .define kBuildLang "en"
        .define RESOURCE_FILE(basename) .include .concat("res/", basename, ".", kBuildLang)
