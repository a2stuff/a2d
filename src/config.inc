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
.define kDeskTopVersionSuffix "-alpha4"
.define kBuildDate "July 31, 2025"
kBuildYYYY = 2025
kBuildYY = 25
kBuildMM = 7
kBuildDD = 31

;;; Localization - applies language suffix to filename

.define kBuildLang "en"
.define RESOURCE_FILE(basename) .include .concat("res/", basename, ".", kBuildLang)
.define kBuildSupportsLowercase 1
