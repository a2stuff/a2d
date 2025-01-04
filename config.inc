;;; ============================================================
;;; Build Configuration
;;;
;;; Must be included by all targets
;;; ============================================================

;;; Build configuration

        .setcpu "6502"
        .feature string_escapes
        .feature line_continuations

;;; Product Info

.define kDeskTopProductName "Apple II DeskTop"
kDeskTopVersionMajor = 1
kDeskTopVersionMinor = 5
.define kDeskTopVersionSuffix "-alpha1"
.define kBuildDate "November 16, 2024"
kBuildYYYY = 2024
kBuildYY = 24
kBuildMM = 11
kBuildDD = 16

;;; Localization - applies language suffix to filename

        .define kBuildLang "en"
        .define RESOURCE_FILE(basename) .include .concat("res/", basename, ".", kBuildLang)
