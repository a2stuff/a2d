;;; ============================================================
;;; Adjust filename case, using GS/OS bits or heuristics
;;; Per Technical Note: GS/OS #8: Filenames With More Than CAPS and Numerals
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/gsos/tn.gsos.08.html

;;; AdjustFileEntryCase:
;;; Input: A,X points at `FileEntry` structure.
;;; Output: `FileEntry`'s filename case is adjusted

;;; AdjustOnLineEntryCase:
;;; Input: A,X points at `ON_LINE` entry (i.e. unit num / length, 15 chars)
;;; Output: entry starts with just length, and case adjusted

;;; `ADJUSTCASE_BLOCK_BUFFER` must be defined; used for volume names

.if !kBuildSupportsLowercase

;;; Some encodings preclude lowercase ASCII, so no case adjust

AdjustOnLineEntryCase:
AdjustFileEntryCase:
        ptr := $A
        stax    ptr
        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sta     (ptr),y
AdjustFileNameCase:
        rts
.else
.scope adjustfilecase_impl
        DEFINE_READWRITE_BLOCK_PARAMS volname_block_params, ADJUSTCASE_BLOCK_BUFFER, kVolumeDirKeyBlock

        ptr := $A

;;; --------------------------------------------------
;;; Called with volume name. Convert to path, load
;;; VolumeDirectoryHeader, use bytes $1A/$1B
online_entry:
        stax    ptr

        ldy     #0
        lda     (ptr),y
        pha
        and     #UNIT_NUM_MASK
        sta     volname_block_params::unit_num
        pla
        and     #NAME_LENGTH_MASK
        sta     (ptr),y

        MLI_CALL READ_BLOCK, volname_block_params
        bcs     fallback

        copy16  ADJUSTCASE_BLOCK_BUFFER + VolumeDirectoryHeader::case_bits, case_bits
        jmp     common

;;; --------------------------------------------------
;;; Called with FileEntry. Copy version bytes directly.
file_entry:
        stax    ptr

        .assert FileEntry::file_name = 1, error, "bad assumptions in structure"

        ;; AppleWorks?
        ldy     #FileEntry::file_type
        lda     (ptr),y
        cmp     #FT_ADB
        beq     appleworks
        cmp     #FT_AWP
        beq     appleworks
        cmp     #FT_ASP
        beq     appleworks

        ldy     #FileEntry::case_bits
        copy16in (ptr),y, case_bits
        FALL_THROUGH_TO common

common:
        asl16   case_bits
        bcs     apply_bits      ; High bit set = GS/OS case bits present

;;; --------------------------------------------------
;;; GS/OS bits are not present; apply heuristics

fallback:
        .include "wordcase.s"

;;; --------------------------------------------------
;;; GS/OS bits are present - apply to recase string.
;;; Per Technical Note: GS/OS #8: Filenames With More Than CAPS and Numerals
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/gsos/tn.gsos.08.html
;;;
;;; "If version is read as a word value, bit 7 of min_version would be the
;;; highest bit (bit 15) of the word. If that bit is set, the remaining 15
;;; bits of the word are interpreted as flags that indicate whether the
;;; corresponding character in the filename is uppercase or lowercase, with
;;; set indicating lowercase."

apply_bits:
        ldy     #1
@bloop: asl16   case_bits   ; NOTE: Shift out high byte first
        bcc     :+
        lda     (ptr),y
        ora     #AS_BYTE(~CASE_MASK) ; guarded by `kBuildSupportsLowercase`
        sta     (ptr),y
:       iny
        cpy     #16             ; bits
        bcc     @bloop
        rts

;;; --------------------------------------------------
;;; AppleWorks
;;; Per File Type Notes: File Type $19 (25) All Auxiliary Types
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/ftyp/ftn.19.xxxx.html
;;; Per File Type Notes: File Type $1A (26) All Auxiliary Types
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/ftyp/ftn.1A.xxxx.html
;;; Per File Type Notes: File Type $1B (27) All Auxiliary Types
;;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/ftyp/ftn.1B.xxxx.html
;;;
;;; "The volume or subdirectory auxiliary type word for this file type is
;;; defined to control uppercase and lowercase display of filenames. The
;;; highest bit of the least significant byte corresponds to the first
;;; character of the filename, the next highest bit of the least significant
;;; byte corresponds to the second character, etc., through the second bit
;;; of the most significant byte, which corresponds to the fifteenth
;;; character of the filename."
;;;
;;; Same logic as GS/OS, just a different field and byte-swapped.
appleworks:
        ldy     #FileEntry::aux_type
        lda     (ptr),y
        sta     case_bits+1
        iny
        lda     (ptr),y
        sta     case_bits
        jmp     apply_bits

;;; --------------------------------------------------
;;; File name (max 15 characters)

file_name:
        stax    ptr
        jmp     fallback

;;; --------------------------------------------------

case_bits:
        .word   0
.endscope ; adjustfilecase_impl

;;; Exports
AdjustFileNameCase      := adjustfilecase_impl::file_name
AdjustFileEntryCase     := adjustfilecase_impl::file_entry
AdjustOnLineEntryCase   := adjustfilecase_impl::online_entry
.endif
