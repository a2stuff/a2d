;;; ============================================================
;;; Mapping from file info to icon type
;;; ============================================================

;;; An `ICTRecord` allows matching file info (name, type, auxtype, size)
;;; to determine what icon to use.

;;; Note: This doesn't define `IconType` - that's up to clients.

.struct ICTRecord             ; Offset
        mask            .byte ; 0     incoming file type masked before comparison ($FF for exact, $00 for anything)
        filetype        .byte ; 1     file type for the record (must match)
        flags           .byte ; 2     combination of `ICT_FLAGS_*` values
.union                        ; 3     depends on `flags`:
        auxtype         .word ;       * if `ICT_FLAGS_AUX` or `ICT_FLAGS_AUXMASK`
        suffix          .addr ;       * if `ICT_FLAGS_SUFFIX`
.endunion
.union                        ; 5     depends on `flags`:
        blocks          .word ;       * if `ICT_FLAGS_BLOCKS`
        auxmask         .word ;       * if `ICT_FLAGS_AUXMASK`
.endunion
        icontype        .byte ; 7     `IconType`
.endstruct

;;; The logic is as follows. At each step, if the comparison fails, the record is not a match.
;;; * Mask file's filetype with `mask` and compare with `filetype`.
;;; * If `ICT_FLAGS_AUX`: compare file's auxtype (unmasked) with `auxtype`
;;; * If `ICT_FLAGS_AUXMASK`: mask file's auxtype with `auxmask` and compare with `auxtype`
;;; * If `ICT_FLAGS_SUFFIX`: compare file's name with `suffix`
;;; * If `ICT_FLAGS_BLOCKS`: compare file's block cont with `blocks`

;;; Records are matched in order. Therefore, the table order should generally be as follows:
;;; * Records for file types that much definitively match, regardless of later heuristics
;;;   e.g. type = `FT_DIRECTORY` is always a directory
;;; * Records where filename suffix definitively matches, overriding type or auxtype
;;;   e.g. suffix = `".A2FC"` is DHR image
;;; * Records where heuristics refine a generic type
;;;   e.g. type = `FT_BINARY`, auxtype = `$2000`, blocks = `33` is DHR image
;;; * Records for specific types, with optional refinements
;;;   e.g. type = `FT_SYSTEM`, suffix = `".SYSTEM"` is Application
;;;   e.g. type = `FT_PNT`, auxtype = `$0001` is IIgs Packed SHR
;;;   e.g. type = `FT_ENTERTAINMENT`, auxtype = `$C800`, auxmask = `$FF00` is CHIP-8
;;; * Records for type ranges
;;;   e.g. type = `$50`, mask = `$F0` is general IIgs file

kICTSentinel = $01     ; not $00, because $00 as a mask is useful

.macro DEFINE_ICTRECORD mask, filetype, flags, aux_suf, blocks_auxmask, icontype
        .assert mask <> kICTSentinel, error, "Can't use sentinel value as a mask"
        .byte   mask
        .byte   filetype
        .byte   flags
        .word   aux_suf         ; `auxtype` or `suffix`
        .word   blocks_auxmask  ; `blocks` or `auxmask`
        .byte   icontype

        .assert !(((flags) & ICT_FLAGS_AUX) && ((flags) & ICT_FLAGS_SUFFIX)), error, \
          "Incompatible flags can't have both ICT_FLAGS_AUX and ICT_FLAGS_SUFFIX"
        .assert !(((flags) & ICT_FLAGS_AUX) && ((flags) & ICT_FLAGS_AUXMASK)), error, \
          "Incompatible flags can't have both ICT_FLAGS_AUX and ICT_FLAGS_AUXMASK"
        .assert !(((flags) & ICT_FLAGS_BLOCKS) && ((flags) & ICT_FLAGS_AUXMASK)), error, \
          "Incompatible flags - can't have both ICT_FLAGS_BLOCKS and ICT_FLAGS_AUXMASK"

.endmacro

        ;; Using `ICT_FLAGS_AUX` and `ICT_FLAGS_BLOCKS` together is
        ;; supported, but other combinations are not since they
        ;; overload the fields.

        ICT_FLAGS_NONE    = %00000000
        ICT_FLAGS_AUX     = %10000000 ; exclusive with ICT_FLAGS_SUFFIX / ICT_FLAGS_AUXMASK
        ICT_FLAGS_BLOCKS  = %01000000 ; exclusive with ICT_FLAGS_AUXMASK
        ICT_FLAGS_SUFFIX  = %00100000 ; exclusive with ICT_FLAGS_AUX
        ICT_FLAGS_AUXMASK = %00010000 ; exclusive with ICT_FLAGS_BLOCKS
