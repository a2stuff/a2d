;;; ============================================================
;;;
;;; Passport MIDI Card -
;;;
;;; ============================================================

;;; Based on the MIDI Interface User's Manual

;;; Motorola MC6840 Programmable Timer Module (PTM)

;;; CR#n = Control Register (1..3)
;;; MSB Buffer = a shared write register to hold MSB
;;; LSB Buffer = a shared read register to hold LSB
;;;
;;; To write to a timer: write to MSB Buffer then Timer LSB
;;; To read a timer: read Timer MSB then LSB Buffer

;;; I/O Addresses (n = slot + 8, e.g. $C0A0 = slot 2)
;;;
;;; Address  Write               Read
;;; -------  ------------------  ----------
;;; $C0n0    CR#2=0: write CR#3  No-op
;;; $C0n0    CR#2=1: write CR#1  No-op
;;; $C0n1    write CR#2          read Status Register
;;; $C0n2    write MSB Buffer    read Timer 1 MSB
;;; $C0n3    write Timer 1 LSB   read LSB Buffer
;;; $C0n4    write MSB Buffer    read Timer 2 MSB
;;; $C0n5    write Timer 2 LSB   read LSB Buffer
;;; $C0n6    write MSB Buffer    read Timer 3 MSB
;;; $C0n7    write Timer 3 LSB   read LSB Buffer

kOffsetWriteCR13       = 0      ; CR#2 bit 0 selects
kOffsetWriteCR2        = 1
kOffsetWriteMSBBuffer  = 2      ; or 4 or 6
kOffsetWriteTimer1LSB  = 3
kOffsetWriteTimer2LSB  = 5
kOffsetWriteTimer3LSB  = 7

kOffsetReadSR          = 1
kOffsetReadTimer1MSB   = 2
kOffsetReadLSBBuffer   = 3      ; or 5 or 7
kOffsetReadTimer2MSB   = 4
kOffsetReadTimer3MSB   = 6

;;; Control Registers
;;;
;;; bit 0:
;;;  Register 1: 0 = timers operate; 1 = timers hold (reset)
;;;  Register 2: 0 = control register #3; 1 = control register #1
;;;  Register 3: 0 = timer 3 not prescaled; 1 = prescaled (div by 8)
;;;
;;;                       %76543210
kExternalClock         = %00000000 ; bit 1 = 0: external clock src
kInternalClock         = %00000010 ; bit 1 = 1: internal clock src
kCounterSingle16Bit    = %00000000 ; bit 2 = 0: 16-bit mode
kCounterDual8Bit       = %00000100 ; bit 2 = 1: dual 8-bit mode
kModeContinuous        = %00000000 ; bits 3-5
kModeSingleShot        = %00100000
kModeFrequencyCompare  = %00001000
kModePulseWidthCompare = %00011000
kInterruptsDisabled    = %00000000 ; bit 6 = 0: interrupts disabled
kInterruptsEnabled     = %01000000 ; bit 6 = 1: interrupts enabled
;;; bit 7: unused

;;; Status Register
;;;
;;; bit 0 = Timer 1 interrupt flag
;;; bit 1 = Timer 2 interrupt flag
;;; bit 2 = Timer 3 interrupt flag
;;; bits 3-6 unused
;;; bit 7 = Any interrupt flag set (and interrupts enabled)
