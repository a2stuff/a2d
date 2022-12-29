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
.define kDeskTopVersionSuffix ""
.define kBuildDate "December 28, 2022"
kBuildYYYY = 2022
kBuildYY = 22
kBuildMM = 12
kBuildDD = 28

;;; Localization - applies language suffix to filename

        .define kBuildLang "en"
        .define RESOURCE_FILE(basename) .include .concat("res/", basename, ".", kBuildLang)
