;;; These symbols must be defined:
;;; * `IconType` (enum) including `IconType::generic`
;;; * `file_type` (in, byte) type of the file
;;; * `aux_type` (in, word) auxtype of the file
;;; * `blocks_used` (in, word) size of the file in blocks
;;; * Zero Page locations:
;;;   * `ptr_table` - (in, word) first of `ICTRecord` records (ends with `kICTSentinel`)
;;;   * `ptr_filename` - (in, word) must point at length-prefixed file name
;;;   * `ptr_suffix` - (word) pointer (used to walk the record suffix)
;;;   * `ict_record` - scratch space for copy of `ICTRecord`

;;; Output: A is `IconType` of matched record, or `IconType::generic` if none

.proc DetermineIconTypeImpl
    REPEAT
        ;; Copy somewhere handy
        ldy     #.sizeof(ICTRecord)-1
      DO
        copy8   (ptr_table),y, ict_record,y
      WHILE dey : POS

        ;; Sentinel?
        ASSERT_EQUALS ICTRecord::mask, 0
        IF A = #kICTSentinel \
          RETURN A=#IconType::generic

        ;; Check type (with mask)
        and     file_type       ; A = type & mask
        IF A <> ict_record+ICTRecord::filetype \
          GOTO next

        flags := ict_record + ICTRecord::flags

        ;; Does Aux Type matter, and if so does it match?
        ASSERT_EQUALS ::ICT_FLAGS_AUX, ::N_FLAG_MASK
      IF bit flags : NS         ; bit 7 = compare aux
        IF u16 aux_type <> ict_record+ICTRecord::auxtype \
          GOTO next
      END_IF

        ;; Does masked Aux Type matter, and if so does it match?
      IF lda flags : and #ICT_FLAGS_AUXMASK : NOT ZERO
        IF lda aux_type : and ict_record+ICTRecord::auxmask : A <> ict_record+ICTRecord::auxtype \
          GOTO next
        IF lda aux_type+1 : and ict_record+ICTRecord::auxmask+1 : A <> ict_record+ICTRecord::auxtype+1 \
          GOTO next
      END_IF

        ;; Does Block Count matter, and if so does it match?
        ASSERT_EQUALS ::ICT_FLAGS_BLOCKS, ::V_FLAG_MASK
      IF bit flags : VS         ; bit 6 = compare blocks
        IF u16 blocks_used <> ict_record+ICTRecord::blocks \
          GOTO next
      END_IF

        ;; Filename suffix?
      IF lda flags : and #ICT_FLAGS_SUFFIX : NOT_ZERO
        ;; Set up pointers to suffix and filename
        copy16  ict_record+ICTRecord::suffix, ptr_suffix

        ;; Start at the end of the strings
        ldy     #0
        copy8   (ptr_suffix),y, suffix_pos
        copy8   (ptr_filename),y, filename_pos

        ;; Case-insensitive compare each character
       DO
        filename_pos := *+1
        ldy     #SELF_MODIFIED_BYTE
        lda     (ptr_filename),y
        jsr     ToUpperCase
        suffix_pos := *+1
        ldy     #SELF_MODIFIED_BYTE
        cmp     (ptr_suffix),y  ; already uppercase
        bne     next            ; no match

        ;; Move to previous characters
        dec     suffix_pos
        BREAK_IF ZERO           ; if we ran out of suffix, it's a match
        dec     filename_pos
        beq     next            ; but if we ran out of filename, it's not
       WHILE NOT_ZERO           ; otherwise, keep going
      END_IF

        ;; Have a match
        RETURN A=ict_record+ICTRecord::icontype

        ;; Next entry
next:   add16_8 ptr_table, #.sizeof(ICTRecord)
    FOREVER
.endproc ; DetermineIconTypeImpl
