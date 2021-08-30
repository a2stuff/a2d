;;; ============================================================
;;; Adjust filename case, using GS/OS bits or heuristics
;;; Per Technical Note: GS/OS #8: Filenames With More Than CAPS and Numerals
;;; http://www.1000bit.it/support/manuali/apple/technotes/gsos/tn.gsos.08.html

;;; AdjustFileEntryCase:
;;; Input: A,X points at FileEntry structure.

;;; AdjustVolumeNameCase:
;;; Input: A,X points at ON_LINE result (e.g. 'MY.DISK', length + 15 chars)

.proc AdjustCaseImpl

        volpath := ADJUSTCASE_VOLPATH
        volbuf  := ADJUSTCASE_VOLBUF
        DEFINE_OPEN_PARAMS volname_open_params, volpath, ADJUSTCASE_IO_BUFFER
        DEFINE_READ_PARAMS volname_read_params, volbuf, .sizeof(VolumeDirectoryHeader)
        DEFINE_CLOSE_PARAMS volname_close_params

        ptr := $A

;;; --------------------------------------------------
;;; Called with volume name. Convert to path, load
;;; VolumeDirectoryHeader, use bytes $1A/$1B
vol_name:
        stax    ptr

        ;; Convert volume name to a path
        ldy     #0
        lda     (ptr),y
        sta     volpath
        tay
:       lda     (ptr),y
        sta     volpath+1,y
        dey
        bne     :-
        lda     #'/'
        sta     volpath+1
        inc     volpath

        LIB_MLI_CALL OPEN, volname_open_params
        bne     fallback
        lda     volname_open_params::ref_num
        sta     volname_read_params::ref_num
        sta     volname_close_params::ref_num
        LIB_MLI_CALL READ, volname_read_params
        bne     fallback
        LIB_MLI_CALL CLOSE, volname_close_params

        copy16  volbuf + $1A, version_bytes
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

        ldy     #FileEntry::version
        copy16in (ptr),y, version_bytes
        ;; fall through

common:
        asl16   version_bytes
        bcs     apply_bits      ; High bit set = GS/OS case bits present

;;; --------------------------------------------------
;;; GS/OS bits are not present; apply heuristics

fallback:
        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        beq     done

        ;; Walk backwards through string. At char N, check char N-1
        ;; to see if it is a '.'. If it isn't, and char N is a letter,
        ;; lower-case it.
        tay

loop:   dey
        beq     done
        bpl     :+
done:   rts

:       lda     (ptr),y
        cmp     #'.'
        bne     check_alpha
        dey
        bpl     loop            ; always

check_alpha:
        iny
        lda     (ptr),y
        cmp     #'A'
        bcc     :+
        ora     #AS_BYTE(~CASE_MASK)
        sta     (ptr),y
:       dey
        bpl     loop            ; always

;;; --------------------------------------------------
;;; GS/OS bits are present - apply to recase string.
;;; Per Technical Note: GS/OS #8: Filenames With More Than CAPS and Numerals
;;; http://www.1000bit.it/support/manuali/apple/technotes/gsos/tn.gsos.08.html
;;;
;;; "If version is read as a word value, bit 7 of min_version would be the
;;; highest bit (bit 15) of the word. If that bit is set, the remaining 15
;;; bits of the word are interpreted as flags that indicate whether the
;;; corresponding character in the filename is uppercase or lowercase, with
;;; set indicating lowercase."

apply_bits:
        ldy     #1
@bloop: asl16   version_bytes   ; NOTE: Shift out high byte first
        bcc     :+
        lda     (ptr),y
        ora     #AS_BYTE(~CASE_MASK)
        sta     (ptr),y
:       iny
        cpy     #16             ; bits
        bcc     @bloop
        rts

;;; --------------------------------------------------
;;; AppleWorks
;;; Per File Type Notes: File Type $19 (25) All Auxiliary Types
;;; http://www.1000bit.it/support/manuali/apple/technotes/ftyp/ftn.19.xxxx.html
;;; Per File Type Notes: File Type $1A (26) All Auxiliary Types
;;; http://www.1000bit.it/support/manuali/apple/technotes/ftyp/ftn.1A.xxxx.html
;;; Per File Type Notes: File Type $1B (27) All Auxiliary Types
;;; http://www.1000bit.it/support/manuali/apple/technotes/ftyp/ftn.1B.xxxx.html
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
        sta     version_bytes+1
        iny
        lda     (ptr),y
        sta     version_bytes
        jmp     apply_bits

;;; --------------------------------------------------

version_bytes:
        .word   0
.endproc

AdjustFileEntryCase     := AdjustCaseImpl::file_entry
AdjustVolumeNameCase    := AdjustCaseImpl::vol_name
