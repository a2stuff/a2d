;;; From https://github.com/fadden/fhpack
;;; Converted to ca65 format by @inexorabletash
;;; Modifications noted with `A2D`

A2D = 1

;;; Code is covered by Apache License 2.0
;;; http://www.apache.org/licenses/LICENSE-2.0

;;; ********************************
;;; *                              *
;;; * LZ4FH uncompression for 6502 *
;;; * By Andy McFadden             *
;;; * Version 1.0.1, August 2015   *
;;; *                              *
;;; * Refactored for size & speed  *
;;; * by Peter Ferrie.             *
;;; *                              *
;;; * Developed with Merlin-16     *
;;; *                              *
;;; ********************************

;;;
;;; Constants
;;;
lz4fh_magic :=  $66       ;ascii 'f'
tok_empty :=   253
tok_eod  :=    254

overrun_check = 0

;;;
;;; Variable storage
;;;
srcptr   :=    $3c        ;2b a1l
dstptr   :=    $3e        ;2b a1h
copyptr  :=    $00        ;2b
savmix   :=    $02        ;1b
savlen   :=    $03        ;1b

;;;
;;; ROM routines
;;;
.if !A2D ; Unused
bell     :=    $ff3a
monitor  :=    $ff69
.endif

;;;
;;; Parameters, stashed at the top of the text input
;;; buffer.  We use this, rather than just having them
;;; poked directly into the code, so that the 6502 and
;;; 65816 implementations work the same way without
;;; either getting weird.
;;;
.if A2D
in_src   :=    $06        ;2b
in_dst   :=    $08        ;2b
.else
in_src   :=    $2fc       ;2b
in_dst   :=    $2fe       ;2b
.endif

entry:
         lda   in_src     ;copy source address to zero page
         sta   srcptr
         lda   in_src+1
         sta   srcptr+1
         lda   in_dst     ;copy destination address to zero page
         sta   dstptr
         lda   in_dst+1
         sta   dstptr+1
         sta   _desthi+1

         ldy   #$00
         lda   (srcptr),y
         cmp   #lz4fh_magic ;does magic match?
         beq   goodmagic

.if A2D ; just return to caller Z=1 on success, Z=0 on error
        rts
.else
fail:
         jsr   bell
         jmp   monitor
.endif

;;; These stubs increment the high byte and then jump
;;; back.  This saves a cycle because branch-not-taken
;;; becomes the common case.  We assume that we're not
;;; unpacking data at $FFxx, so BNE is branch-always.
hi2:
         inc   srcptr+1
         bne   nohi2

hi3:
         inc   srcptr+1
         clc
         bcc   nohi3

hi4:
         inc   dstptr+1
         bne   nohi4

notempty:
         cmp   #tok_eod
.if !A2D ; just return to caller Z=1 on success, Z=0 on error
         bne   fail
.endif
         rts              ;success!

;;; handle "special" match values (value in A)
specialmatch:
         cmp   #tok_empty
         bne   notempty

         tya              ;empty match, advance srcptr
         adc   srcptr     ; past and jump to main loop
         sta   srcptr
         bcc   mainloop
         inc   srcptr+1
         bne   mainloop

hi5:
         inc   srcptr+1
         clc
         bcc   nohi5

goodmagic:
         inc   srcptr
         bne   mainloop
         inc   srcptr+1

mainloop:
;;; Get the mixed-length byte and handle the literal.
         ldy   #$00
         lda   (srcptr),y ;get mixed-length byte
         sta   savmix
         lsr   A          ;get the literal length
         lsr   A
         lsr   A
         lsr   A
         beq   noliteral
         cmp   #$0f       ;sets carry for >= 15
         bne   shortlit

         inc   srcptr
         beq   hi2
nohi2:
         lda   (srcptr),y ;get length extension
         adc   #14        ;(carry set) add 15 - will not exceed 255

;;; At this point, srcptr holds the address of the "mix"
;;; word or the length extension, and dstptr holds the
;;; address of the next output location.  So we want to
;;; read from (srcptr),y+1 and write to (dstptr),y.
;;; We can do this by sticking the DEY between the LDA
;;; and STA.
;;;
;;; We could save a couple of cycles by substituting
;;; addr,y in place of (dp),y, but the added setup cost
;;; would only benefit longer literal strings.
shortlit:       tax
         tay
@litloop:
         lda   (srcptr),y ;5
         dey              ;2  if len is 255, copy 0-254
         sta   (dstptr),y ;6
         bne   @litloop   ;3 -> 16 cycles/byte

;;; Advance srcptr by savlen+1, and dstptr by savlen
         txa
         sec              ;this gets us the +1
         adc   srcptr
         sta   srcptr
         bcs   hi3
nohi3:                    ;carry cleared by hi3
         txa
         adc   dstptr
         sta   dstptr
         bcs   hi4
nohi4:
         dey              ;Y=0; DEY so next INY goes to 0

;;; Handle match.  Y holds an offset into srcptr such
;;; that we need to increment it once to get the next
;;; interesting byte.
noliteral:
         lda   savmix
         and   #$0f
         cmp   #$0f
         bcc   @shortmatch

         iny
         lda   (srcptr),y ;get length extension
         cmp   #237       ;"normal" values are 0-236
         bcs   specialmatch
         adc   #15        ;will not exceed 255

;;; Put the destination address into copyptr.
@shortmatch:
         adc   #4         ;min match; won't exceed 255
         sta   savlen     ;save match len for later
         tax              ;and keep it in X
         iny
         lda   (srcptr),y ;match offset, lo
         sta   copyptr
         iny
         lda   (srcptr),y ;match offset, hi
_desthi: ora   #$00       ;OR in hi-res page
         sta   copyptr+1

;;; Advance srcptr past the encoded match while we still
;;; remember how many bytes it took to encode.  Y is
;;; indexing the last value used, so we want to go
;;; advance srcptr by Y+1.

         tya
         sec
         adc   srcptr
         sta   srcptr
         bcs   hi5
nohi5:                    ;hi5 clears carry

;;; Copy the match.  The length is in X.  Note this
;;; must be a forward copy so overlapped data works.
;;;
;;; We know the match is at least 4 bytes long, so
;;; we could save a few cycles by not doing the
;;; ADC #4 earlier, and unrolling the first 4
;;; load/store operations here.
         ldy   #$00
@copyloop:
         lda   (copyptr),y ;5
         sta   (dstptr),y ;6
         iny              ;2
         dex              ;2
         bne   @copyloop  ;3 -> 18 cycles/byte

;;; advance dstptr past copied data
         lda   dstptr
         adc   savlen     ;carry is clear
         sta   dstptr
         bcc   mainloop
         inc   dstptr+1

.if A2D
        ;; Decoding to $2000
        lda     dstptr+1
        cmp     #$40
        bcc     mainloop
        lda     #$FF            ; Z=0 signals failure
        rts
.else
.if    overrun_check
         LDA   dstptr+1
         CMP   #$60
         bcc   mainloop
         BRK
         BRK
.else
         bne   mainloop   ;always (not unpacking at $FFxx)
.endif
.endif
