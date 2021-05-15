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
.define kDeskTopVersionSuffix "-alpha29"
.define kBuildDate "May 14, 2021"
kBuildYY = 21
kBuildMM = 5
kBuildDD = 14

;;; Localization - applies language suffix to filename

        .define kBuildLang "en"

;;; Broken by cc65 b9a3c7888822732a0de92741cfe1a3e1b6bb272f
;;; https://github.com/cc65/cc65/issues/1503
;;; .macro RESOURCE_FILE basename
;;;         .include .concat("res/", basename, ".", kBuildLang)
;;; .endmacro
