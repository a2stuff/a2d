;;; ============================================================
;;;
;;; More Apple II Symbols
;;;
;;; ============================================================

;;; Zero Page

COUT_HOOK       := $36

;;; Other Pages

IN              := $200


;;; ============================================================
;;; Vectors
;;; ============================================================

NMI             := $3FB
IRQLOC          := $3FE

VECTORS         := $FFFA
NMI_VECTOR      := $FFFA        ; on NMI
RESET_VECTOR    := $FFFC        ; on RESET
IRQ_VECTOR      := $FFFE        ; on IRQ or BRK

kIntVectorsSize = 6             ; 3 vectors, 2 bytes each


;;; ============================================================
;;; Monitor ROM
;;; ============================================================

;;; ROM locations

IDBYTELASER128  := $FB1E        ; $AC = Laser 128
INIT            := $FB2F        ; Initialize text screen.
SETPWRC         := $FB6F        ; Create power-up byte.
VERSION         := $FBB3        ; Monitor ROM ID byte. $06 = IIe or later
ZIDBYTE2        := $FBBF        ; * IIc ROM version ($05 = IIc+)
ZIDBYTE         := $FBC0        ; * $EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+
IDBYTEMACIIE    := $FBDD        ; * $02 = Mac IIe Card
BELL1           := $FBDD        ; Generate tone.
VTAB            := $FC22        ; Vertical tab. Uses value at CV.
VTABZ           := $FC24        ; Vertical tab (alternate entry). Uses A.
HOME            := $FC58        ; Home cursor and clear to end of page.
CROUT           := $FD8E        ; Issue a carriage return.
PRBYTE          := $FDDA        ; Print a hexadecimal byte.
COUT            := $FDED        ; Output a character.
IDROUTINE       := $FE1F        ; RTS ($60) on pre-IIgs, clears carry on IIgs
MOVE            := $FE2C        ; Original Monitor Move routine.
SETKBD          := $FE89        ; Reset input to keyboard.
SETVID          := $FE93        ; Reset output to screen.
MONZ            := $FF69        ; Standard Monitor entry point.

;;; Constants

F8VERSION       := $06


;;; ============================================================
;;; Applesoft Basic ROM
;;; ============================================================

;;; Zero Page

LINNUM          := $50          ; Line number, unsigned word
ERRFLG          := $D8
CHRGET          := $B1          ; Routine called by ROM
TXTPTR          := $B8
FAC             := $9D
FAC_SIGN        := $A2
SHIFT_SIGN_EXT  := $A4          ; Zero before using FP ops
ARG             := $A5
ARG_SIGN        := $AA
SGNCPR          := $AB          ; FAC_SIGN xor ARG_SIGN

;;; Entry Points

GIVAYF          := $E2F2        ; FAC from signed integer in (Y,A)
CONINT          := $E6FB        ; FAC = X as unsigned byte
GETADR          := $E752        ; FAC to unsigned integer in LINNUM
FADDH           := $E7A0        ; Add 0.5 to FAC
FSUB            := $E7A7        ; FAC = (Y,A) - FAC
FSUBT           := $E7AA        ; FAC = ARG - FAC
FADD            := $E7BE        ; FAC = (Y,A) + FAC
FADDT           := $E7C1        ; FAC = ARG + FAC
ZERO_FAC        := $E84E        ; FAC = 0
LOG             := $E941        ; FAC = LOG(FAC)
FMULT           := $E97F        ; FAC = (Y,A) * FAC
FMULTT          := $E982        ; FAC = ARG * FAC
LOAD_ARG        := $E9E3        ; ARG = (Y,A)
DIV10           := $EA55        ; FAC = FAC / 10
FDIV            := $EA66        ; FAC = (Y,A) / FAC
FDIVT           := $EA69        ; FAC = ARG / FAC
MOVFM           := $EAF9        ; FAC = (Y,A)
LOAD_FAC        := $EAF9        ; FAC = (Y,A)
MOVMF           := $EB2B        ; (Y,X) = FAC
ROUND           := $EB2B        ; Round FAC, store at (Y,X)
ARG_TO_FAC      := $EB53        ; FAC = ARG
FAC_TO_ARG_R    := $EB63        ; ARG = FAC, rounded
SGN             := $EB90        ; FAC = SGN(FAC)
FLOAT           := $EB93        ; FAC = A as signed byte
FLOAT1          := $EB9B        ; FAC from unsigned integer in FAC+1,2 eX
FLOAT2          := $EBA0        ; FAC from unsigned integer in FAC+1,2 eX, carry set = positive
ABS             := $EBAF        ; FAC = ABS(FAC)
FCOMP           := $EBB2        ; FAC <=> (Y,A), result in A
QINT            := $EBF2        ; FAC to signed integer in FAC+1...FAC+4 (e < 32)
INT             := $EC23        ; FAC = INT(FAC)
FIN             := $EC4A        ; Parse TEXTPTR to FAC (first char in A, C set if digit)
FOUT            := $ED34        ; FAC as string to FBUFFR (trashes FAC)
SQR             := $EE8D        ; FAC = SQR(FAC)
FPWRT           := $EE97        ; FAC = ARG ^ FAC
NEGOP           := $EED0        ; FAC = -FAC
EXP             := $EF09        ; FAC = EXP(FAC)
RND             := $EFAE        ; FAC = RND(FAC)
COS             := $EFEA        ; FAC = COS(FAC)
SIN             := $EFF1        ; FAC = SIN(FAC)
TAN             := $F03A        ; FAC = TAN(FAC)
ATN             := $F09E        ; FAC = ATN(FAC)

;;; Constants in ROM

CON_ONE         := $E913        ; 1
CON_SQR_HALF    := $E92D        ; SQR(1/2)
CON_SQR_TWO     := $E932        ; SQR(2)
CON_NEG_HALF    := $E937        ; -1/2
CON_LOG_TWO     := $E93C        ; LOG(2)
CON_TEN         := $EA50        ; 10
CON_1E8M1       := $ED0A        ; 1E8 - 1
CON_1E9M1       := $ED0F        ; 1E9 - 1
CON_BILLION     := $ED14        ; 1E9
CON_HALF        := $EE64        ; 1/2
CON_LOG2_E      := $EEDB        ; Log(E) base 2
CON_HALF_PI     := $F066        ; pi/2
CON_TWO_PI      := $F06B        ; pi/*2
CON_QUARTER     := $F070        ; 1/4

;;; Other

FBUFFR          := $100
MSLOT           := $7F8         ; Slot in use, in case of IRQ


;;; ============================================================
;;; Softswitches
;;; ============================================================

CLR80STORE      := $C000        ; (W) restore normal PAGE2 control
SET80STORE      := $C001        ; (W) cause PAGE2 to bank display memory

RAMRDOFF        := $C002        ; (W) Read from main 48K RAM ($200-$BFFF)
RAMRDON         := $C003        ; (W) Read from auxiliary 48K RAM ($200-$BFFF)
RAMWRTOFF       := $C004        ; (W) Write to main 48K RAM ($200-$BFFF)
RAMWRTON        := $C005        ; (W) Write to auxiliary 48K RAM ($200-$BFFF)
ALTZPOFF        := $C008        ; (W) Use main zero page/stack/LC
ALTZPON         := $C009        ; (W) Use auxiliary zero page/stack/LC

CLR80VID        := $C00C        ; (W) Disable 80-column hardware
SET80VID        := $C00D        ; (W) Enable 80-column hardware
RDBNK2          := $C011        ; (R7) bit 7=1 if LCBANK2 enabled
RDALTZP         := $C016        ; (R7) bit 7=1 if auxiliary ZP/stack/LC enabled
RD80STORE       := $C018        ; (R7) bit 7=1 if 80STORE enabled
RDPAGE2         := $C01C        ; (R7) bit 7=1 if PAGE2 on
RDALTCHAR       := $C01E        ; (R7) bit 7=1 if ALTCHAR on

MONOCOLOR       := $C021        ; IIgs - bit 7=1 switches composite to mono
TBCOLOR         := $C022        ; IIgs - text foreground/background colors

KEYMODREG       := $C025        ; IIgs - keyboard modifiers
        ;; bit 7= Open Apple key active
        ;; bit 6= Closed Apple key active
        ;; bit 5= Updated modifier latch without keypress
        ;; bit 4= Keypad key active
        ;; bit 3= Repeat active
        ;; bit 2= Caps lock active
        ;; bit 1= Control key active
        ;; bit 0= Shift key active

NEWVIDEO        := $C029        ; IIgs - new video modes
        ;; Bit 7 = 1 = Enable Super-Hi-Res
        ;; Bit 6 = 1 = Linearize SHR
        ;; Bit 5 = 0 = Color DHR, 1 = B/W DHR
        ;; Bits 4-1 must be 0
        ;; Bit 0 = Enable bank 1 latch to allow long instructions
        ;;         to access bank 1 directly; set by Monitor
        ;;         only; a programmer must not change this bit.

MACIIE          := $C02B        ; Macintosh IIe Option Card
        ;; Tech Note: Apple IIe #10: The Apple IIe Card for the Macintosh LC
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/aiie/tn.aiie.10.html
        ;; Bit 2 = Speed (1.9 MHz if set, 1 MHz if clear)

SPKR            := $C030
CLOCKCTL        := $C034        ; IIgs - bit 0-3 border color, 5-7 clock I/O
SHADOW          := $C035        ; IIgs - inhibit shadowing

;;; Video mode
PAGE2OFF        := $C054
PAGE2ON         := $C055
HIRESOFF        := $C056
HIRESON         := $C057

AN3_OFF         := $C05E
AN3_ON          := $C05F

STATEREG        := $C068        ; Mega II chip (IIgs, etc)
        ;; bit7 = ALTZP
        ;; bit6 = PAGE2
        ;; bit5 = RAMRD
        ;; bit4 = RAMWRT
        ;; bit3 = RDROM
        ;; bit2 = BANK2
        ;; bit1 = ROMBANK
        ;; bit0 = INTCXROM

RAMWORKS_BANK   := $C073
LASER128EX_CFG  := $C074        ; high two bits control speed

ROMIN2          := $C082        ; (W) Read ROM; no write

;;; Le Chat Mauve Eve registers
HR1_OFF         := $C0B2
HR1_ON          := $C0B3
HR2_OFF         := $C0B4
HR2_ON          := $C0B5
HR3_OFF         := $C0B6
HR3_ON          := $C0B7
TEXT16_OFF      := $C0B8
TEXT16_ON       := $C0B9


;;; ============================================================
;;; Aux Memory / Extended 80 Column Card
;;; ============================================================

;;; Routines
SLOT3ENTRY      := $C300
AUXMOVE         := $C311        ; carry set main>aux, carry clear aux>main
XFER            := $C314

;;; Zero Page Locations
STARTLO         := $3C
STARTHI         := $3D
ENDLO           := $3E
ENDHI           := $3F
DESTINATIONLO   := $42
DESTINATIONHI   := $43

;;; Other Locations
XFERSTARTLO     := $03ED
XFERSTARTHI     := $03EE
FW80MODE        := $04FB        ; 80 Col firmware mode ($FF = inactive)
.ifndef OURCH
OURCH           := $057B        ; 80 Col horizontal position
.endif
.ifndef OURCV
OURCV           := $05FB        ; 80 Col vertical position
.endif


;;; ============================================================
;;; Super Serial Card
;;; ============================================================

;;; Pascal 1.1 Entry Points
;;; Offset from $Cs00 to actual entry point in $CsXX space
;;; On entry, X=$Cs, Y=$s0
.enum SSC
        PInit   = $0D
        PRead   = $0E
        PWrite  = $0F
        PStatus = $10
.endenum


;;; ============================================================
;;; Disk II / IWM I/O locations
;;; ============================================================

;;; $C0nX, n = slot + 8 -- c/o http://archive.li/ewHUL
PHASE0  := $C080                ; Stepper motor phase 0
PHASE1  := $C082                ; Stepper motor phase 1
PHASE2  := $C084                ; Stepper motor phase 2
PHASE3  := $C086                ; Stepper motor phase 3
DISABLE := $C088                ; Turn disk drive off
ENABLE  := $C089                ; Turn disk drive on
SELECT  := $C08A                ; Select drive 1 or 2
SELECT1 := $C08A                ; Select drive 1
SELECT2 := $C08B                ; Select drive 2
XMIT    := $C08C                ; Get/set bits to/from disk
TESTWP  := $C08D                ; Test WP mode (then WPRES has result)
DATA    := $C08D                ; Write data to buffer (then XMIT to send)
WPRES   := $C08E                ; WP mode test result
RDMODE  := $C08E                ; Turn off write mode
WRMODE  := $C08F                ; Turn on write mode


;;; ============================================================
;;; Mouse Peripheral Card
;;; ============================================================

;;; Firmware Routines

SETMOUSE        = $12
SERVEMOUSE      = $13
READMOUSE       = $14
CLEARMOUSE      = $15
POSMOUSE        = $16
CLAMPMOUSE      = $17
HOMEMOUSE       = $18
INITMOUSE       = $19

;;; Constants

CLAMP_X         = 0
CLAMP_Y         = 1

MOUSE_MODE_OFF  = $00
MOUSE_MODE_TRANS= $01
MOUSE_MODE_INT  = $03
MOUSE_MODE_BTN  = $05

;;; RAM Locations (scratch areas)

CLAMP_MIN_LO    := $478
CLAMP_MAX_LO    := $4F8
CLAMP_MIN_HI    := $578
CLAMP_MAX_HI    := $5F8

;;; RAM Locations (screen holes, add $0n where n is slot)

MOUSE_X_LO      := $478
MOUSE_Y_LO      := $4F8
MOUSE_X_HI      := $578
MOUSE_Y_HI      := $5F8
MOUSE_STATUS    := $778
MOUSE_MODE      := $7F8


;;; ============================================================
;;; ZIP CHIP
;;; ============================================================

;;; From ZIP Chip Manual v1 1987
ZC_REG_LOCK     := $C05A
;;; Write:
;;; $A5 Locks the ZIP CHIP.
;;; 4 consecutive $5A writes unlock ZIP CHIP.
;;; While unlocked, any write other than $A5 or
;;; $5A will initiate an indefinate syncronous [sic]
;;; sequence.
kZCLock         = $A5
kZCUnlock       = $5A

ZC_REG_ENABLE   := $C05B
;;; Write - Any hex byte written will enable ZIP CHIP
;;
;;; Read - Read the current status of the following:
;;; bit 0 & 1 - Ramsize where
;;;   RAMSIZE1 RAMSIZE0 SIZE
;;;    0        0        8K
;;;    0        1       16K
;;;    1        0       32K
;;;    1        1       64K
;;; bit 2 - unused
;;; bit 3 - Delay (for memory)
;;;   0 = Fast Mode - Delay not in effect
;;;   1 = Sync Mode - Delay in effect
;;; bit 4 - Disabled/enabled
;;;   0 = Chip Enabled
;;;   1 = Chip Disabled
;;; bit 5 - Paddle fast/normal
;;;   0 = Fast Mode
;;;   1 = Synchronous Mode (Normal)
;;; bit 6 = Cache Updated by data read
;;;   0 = No update
;;;   1 = Yes cache updated
;;; bit 7 = Clock Pulse - 1.0035 milliseconds
;;;   Edges occur at .50175 milliseconds

ZC_REG_SLOTSPKR := $C05C
;;; Read/Write - Slow/Speaker set and read
;;;   0 = Set slot/speaker Fast
;;;   1 = Set slot/speaker Normal
;;; bit 0 - Speaker      bit 4 - Slot 4
;;; bit 1 - Slot 1       bit 5 - Slot 5
;;; bit 2 - Slot 2       bit 6 - Slot 6
;;; bit 3 - Slot 3       bit 7 - Slot 7

ZC_REG_SYSSPEED := $C05D
;;; Write - Set System Speed
;;; bit 0 - unused       bit 4 - Clk4/5
;;; bit 1 - unused       bit 5 - Clk5/6
;;; bit 2 - Clk2/3       bit 6 - Clk/2
;;; bit 3 - Clk3/4       bit 7 - Clk/4
;;; NOTE: bit 6 and bit 7 yield Clk/3

ZC_REG_SYNCOP   := $C05E
;;; Write - Enable/Disable Synchronous Operation
;;; for I/O Devices
;;; bit 0 through bit 6 - Not Used
;;; bit 7 - Enable/Disable Delay
;;;   0 = Enable Delay
;;;   1 = Disable and Reset Delay

ZC_REG_SOFTSW   := $C05E
;;; Read - Read Apple softswitches
;;;   0 = False
;;;   1 = True
;;; bit 0 - ROMRD        bit 4 - 80STORE
;;; bit 1 - RAMBNK       bit 5 - MWR
;;; bit 2 - PAGE2        bit 6 - MRD
;;; bit 3 - HIRES        bit 7 - ALTZP

ZC_REG_PDLBSLC  := $C05F
;;; Write - Paddle Speed, Bank Switch Language Card
;;; bit 0 through bit 5 - Not Used
;;; bit 6 - Paddle Set
;;;   0 = Disable Paddle Delay
;;;   1 = Enable Paddle Delay
;;; bit 7 - Language Card Enable/Disable
;;;   0 = Enable Cache of Language Card Memory
;;;   1 = Disable Cache of Language Card Memory


;;; ============================================================
;;; ASCII Character Constants
;;; ============================================================

CHAR_MASK       = $7F
CASE_MASK       = $DF

CHAR_CTRL_C     = $03
CHAR_CTRL_D     = $04
CHAR_CTRL_F     = $06
CHAR_LEFT       = $08           ; Ctrl+H
CHAR_TAB        = $09           ; Ctrl+I
CHAR_DOWN       = $0A           ; Ctrl+J
CHAR_UP         = $0B           ; Ctrl+K
CHAR_CTRL_L     = $0C
CHAR_RETURN     = $0D           ; Ctrl+M
CHAR_CTRL_O     = $0F
CHAR_RIGHT      = $15           ; CtrL+U
CHAR_CTRL_W     = $17
CHAR_CLEAR      = $18           ; Ctrl+X
CHAR_ESCAPE     = $1B           ; Ctrl+[
CHAR_DELETE     = $7F
