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
.define kDeskTopVersionSuffix "-alpha7"
.define kBuildDate "March 1, 2024"
kBuildYYYY = 2024
kBuildYY = 24
kBuildMM = 3
kBuildDD = 1

;;; Localization - applies language suffix to filename

        .define kBuildLang "en"
        .define RESOURCE_FILE(basename) .include .concat("res/", basename, ".", kBuildLang)
