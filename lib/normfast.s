.scope NORMFAST

;;; ------------------------------------------------------------
;;; Code from:
;;; 3b74ddcf-190c-4591-bced-17e165ece668@googlegroups.com
;;; https://groups.google.com/d/topic/comp.sys.apple2/e-2Lx-CR1dM/discussion
;;; * Converted to ca65 syntax (:=/= instead of .equ)
;;; * .org removed
;;; * 65c02 usage restricted to one opcode
;;; * For Laser 128EX: tweak $7FE to persist speed change
;;; ------------------------------------------------------------

;;; NORMFAST Disable/enable Apple II compatible accelerator
;;;
;;; Release 6 2017-10-05 Fix Mac IIe card check
;;;
;;; Release 5 2017-09-27 Add Macintosh IIe Card. Addon
;;; accelerators are now set blindly, so will access
;;; annunciators/IIc locations and may trigger the
;;; paddle timer.
;;; No plans for the Saturn Systems Accelerator which would
;;; require a slot search.
;;;
;;; Release 4 2017-09-06 Add Laser 128EX, TransWarp I, UW
;;;
;;; Release 3 2017-08-29 Change FASTChip partially back to
;;; release 1, which seems to work the way release 2 was
;;; intended?!
;;;
;;; Release 2 2017-08-27 change enable entry point, add Zip
;;; Chip, change setting FASTChip speed to disable/enable
;;;
;;; Release 1 2017-08-25 IIGS, //c+ and FASTChip
;;;
;;; WARNING: The memory location to set the accelerator
;;; speed may overlap existing locations such as:
;;;   annunciators or Apple //c specific hardware
;;;   paddle trigger
;;;
;;; Known to work: IIGS, //c+
;;; Theoretically: FASTChip, Laser 128EX, Mac IIe Card,
;;;   TransWarp I, trademarked German product, Zip Chip
;;;
;;; BRUN NORMFAST or CALL 768 to disable the accelerator.
;;; CALL 771 to enable the accelerator.
;;; Enabling an older accelerator may set maximum speed.
;;; Accelerators such as the FASTChip or Zip Chip can run
;;; slower than 1Mhz when enabled.
;;;
;;; NORMFAST is position independent and can be loaded most
;;; anywhere in the first 48K of memory.
;;; The ROMs must be enabled to identify the model of the
;;; computer.
;;;
;;; This was originally for the //c+ which is normally
;;; difficult to set to 1Mhz speed.
;;; The other expected use is to set the speed in a program.
;;;
;;; Written for Andrew Jacobs' Java based dev65 assembler at
;;; http://sourceforge.net/projects/dev65 but has portability
;;; in mind.

;;; 6502 opcodes are preferred to be friendly to the old
;;; monitor disassemblers

;;; addresses are lowercase, constant values are in CAPS

RELEASE         =       6       ; our version

romid           :=      $FBB3
;;; $38=][, $EA=][+, $06=//e compatible
ROMID_IIECOMPAT =       6
romid_ec        :=      $FBC0
;;; $EA=//e original, $E0=//e enhanced, $E1=//e EDM, $00=//c
;;; Laser 128s are $E0
romid_c         :=      $FBBF
;;; $FF=original, $00=Unidisk 3.5 ... $05=//c+
ROMID_CPLUS     =       5
romid_maciie_2  :=      $FBDD   ; 2

;;; IIGS
idroutine       :=      $FE1F   ; SEC, JSR $FE1F, BCS notgs
gsspeed         :=      $C036
GS_FAST         =       $80     ; mask

;;; //c+ Cache Glue Gate Array (accelerator)
cgga            :=      $C7C7   ; entry point
CGGA_ENABLE     =       1       ; fast
CGGA_DISABLE    =       2       ; normal
CGGA_LOCK       =       3
CGGA_UNLOCK     =       4       ; required to make a change

;;; Macintosh IIe Card
maciie          :=      $C02B
MACIIE_FAST     =       4       ; mask

l128irqpage     =       $C4
;;; From the 4.2, 4.5 and EX2 ROM dumps at the Apple II
;;; Documentation Project, the Laser 128 IRQ handlers are
;;; in the $C4 page.
;;; A comp.sys.apple2 post says the 6.0 ROM for the 128 and
;;; 128EX are identical, so there may not be an easy way to
;;; tell a plain 128 from an (accelerated) 128EX.
irq             :=      $FFFE   ; 6502 IRQ vector

;;; may overlap with paddle trigger
ex_cfg          :=      $C074   ; bits 7 & 6 for speed
EX_NOTSPEED     =       $3F
EX_1MHZMASK     =       $0
EX_2MHZMASK     =       $80     ; 2.3Mhz
EX_3MHZMASK     =       $C0     ; 3.6Mhz

;;; FASTChip
fc_lock         :=      $C06A
FC_UNLOCK       =       $6A     ; write 4 times
FC_LOCK         =       $A6
fc_enable       :=      $C06B
fc_speed        :=      $C06D
FC_1MHZ         =       9
FC_ON           =       40      ; doco says 16.6Mhz

;;; TransWarp I
;;; may overlap with paddle trigger
tw1_speed       :=      $C074
TW1_1MHZ        =       1
TW1_MAX         =       0

;;; Trademarked German accelerator
;;; overlaps annunciator 2 & //c mouse interrupts
uw_fast         :=      $C05C
uw_1mhz         :=      $C05D

;;; Zip Chip
;;; overlaps annunciator 1 & //c vertical blank
zc_lock         :=      $C05A
ZC_UNLOCK       =       $5A     ; write 4 times
ZC_LOCK         =       $A5
zc_enable       :=      $C05B

iobase          :=      $C000   ; easily confused with kbd

        ;; .org    $300

        ; disable accelerator
norm:   lda     #1
        .byte   $2C     ; BIT <ABSOLUTE>, hide next lda #

        ; enable accelerator
fast:   lda     #0

        ldx     #RELEASE ; our release number

        ;; first check built-in accelerators

        ldx     romid
        cpx     #ROMID_IIECOMPAT
        bne     addon   ; not a //e

        ldx     romid_ec
        beq     iic     ; //c family

        ; not worth the bytes for enhanced //e check
        ldx     irq+1
        cpx     #l128irqpage
        bne     gscheck

        ; a Laser 128, hopefully harmless on a non EX

        ;; Need to store $56 (slow) or $D6 (fast) to $7FE
        ;; for speed change to persist.
        pha                     ; A=1 for slow
        lsr                     ; C=1 for slow
        ror                     ; A=$80 for slow
        eor     #$D6            ; $56 for slow
        sta     $7FE            ; modify screen hole
        pla                     ; A=1 for slow

        ldy     #EX_3MHZMASK ; phew, all needed bits set
        ldx     #<ex_cfg

;;; setspeed - set 1Mhz with AND and fast with OR
;;;
;;; A = lsb set for normal speed
;;; X = low byte address of speed location
;;; Y = OR mask for fast

setspeed:
        lsr
        tya
        bcs     setnorm
        ora     iobase,x
        bne     setsta  ; always

setnorm:
        eor     #$FF
        and     iobase,x
setsta:
        sta     iobase,x
        rts

gscheck:
        pha
        sec
        jsr     idroutine
        pla
        bcs     maccheck ; not a gs

        ; set IIGS speed

        ldy     #GS_FAST
        ldx     #<gsspeed
        bne     setspeed ; always

maccheck:
        ldx     romid_maciie_2
        cpx     #2
        bne     addon   ; no built-in accelerator

        ; the IIe Card in a Mac

        ldy     #MACIIE_FAST
        ldx     #<maciie
        bne     setspeed ; always

iic:
        ldx     romid_c
        cpx     #ROMID_CPLUS
        bne     addon   ; not a //c+, eventually hit Zip

;;; Set //c+ speed. Uses the horrible firmware in case other
;;; code works "by the book", that is can check and set
;;; whether the accelerator is enabled.
;;; The //c+ is otherwise Zip compatible.

        .pushcpu
        .setcpu "65C02"
        inc     a       ; 65C02 $1A
        .popcpu

        ; cgga calls save X and Y regs but sets $0 to 0
        ; (this will get a laugh from C programmers)
        ldx     $0
        php
        sei             ; timing sensitive
        pha             ; action after CGGA_UNLOCK

        lda     #CGGA_UNLOCK  ; unlock to change
        pha
        jsr     cgga

        jsr     cgga    ; disable/enable

        lda     #CGGA_LOCK    ; should lock after a change
        pha
        jsr     cgga

        plp             ; restore interrupt state
        stx     $0
        rts

;;; At this point, the computer does not have a built-in
;;; accelerator
;;;
;;; Previous versions had tested fc_enable, which was not
;;; enough. Running low on space so just set blindly.

addon:
        ; TransWarp I

        sta     tw1_speed

        ; Zip Chip

        tay
        eor     #1
        tax
        lda     #ZC_UNLOCK
        php
        sei             ; timing sensitive
        sta     zc_lock
        sta     zc_lock
        sta     zc_lock
        sta     zc_lock
        lsr             ; not ZC_LOCK or ZC_UNLOCK
        sta     zc_lock,x  ; disable/enable
        lda     #ZC_LOCK
        sta     zc_lock

        ;; current products are subject to change so do
        ;; these last

        ; trademarked accelerator from Germany

        lda     romid_ec        ; Skip on //c
        beq     skipuw

        sta     uw_fast,y ; value does not matter
skipuw:

        ; FASTChip

        lda     romid_ec        ; Skip on //c
        beq     skipfc

        ldx     #FC_1MHZ
        tya
        bne     fcset
        ldx     #FC_ON  ; enable set speed?
fcset:
        lda     #FC_UNLOCK
        sta     fc_lock
        sta     fc_lock
        sta     fc_lock
        sta     fc_lock
        sta     fc_enable
        stx     fc_speed
        lda     #FC_LOCK
        sta     fc_lock
skipfc:

        ;; ZipChip poking may twiddle annunciators, kicking
        ;; out of DHIRES mode. Force it back on unconditionally.
        lda     DHIRESON

        plp             ; restore interrupt state
        rts

.endscope ; NORMFAST
        NORMFAST_norm := NORMFAST::norm
        NORMFAST_fast := NORMFAST::fast

;;; ============================================================
