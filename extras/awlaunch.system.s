;;; ************************************************************
;;; *                                                          *
;;; *      *  AW51Launcher - An AppleWorks File Loader  *      *
;;; *                                                          *
;;; *        (For Use with BASIS.SYSTEM by John Brooks)        *
;;; *                                                          *
;;; *        Version 1.0 (for AppleWorks Version 5.1)          *
;;; *                   by Hugh Hood (2018)                    *
;;; *   [Based on prior works by Douglas Gum and Tom Hoover]   *
;;; *                                                          *
;;; *            - A SYSTEM File that Provides -               *
;;; *                                                          *
;;; *    1. Receives the path and file name of a selected      *
;;; *        ADB ($19) / AWP ($1A) / ASP ($1B) / TXT ($04)     *
;;; *        file from BASIS.SYSTEM                            *
;;; *                                                          *
;;; *    2. Moves the passed path and file name to within      *
;;; *        an UltraMacros Task File compiled macro table     *
;;; *                                                          *
;;; *    3. Moves the modified compiled macro table into       *
;;; *        place at $01/EF00 in Aux Memory for use by        *
;;; *        AppleWorks 5.1                                    *
;;; *                                                          *
;;; *    4. Launches APLWORKS.SYSTEM and instructs it use      *
;;; *        the compiled macro table previously moved         *
;;; *        into place instead of the default macro set       *
;;; *                                                          *
;;; *    5. Upon starting AppleWorks, the UltraMacros code     *
;;; *        instructs AppleWorks to load the selected         *
;;; *        file to the AppleWorks Desktop, to leave the      *
;;; *        user in the file, and then to start the user's    *
;;; *        default macro set                                 *
;;; *                                                          *
;;; *                     **************                       *
;;; *                                                          *
;;; *          *  ASSUMPTIONS MADE BY AW51Laucher  *           *
;;; *            (See ProDOS 8 Technical Reference             *
;;; *                 Manual, Section 5.1.5.1)                 *
;;; *                                                          *
;;; *     A. The full pathname to the selected file is         *
;;; *         passed at $2006+, per the startup protocol       *
;;; *                                                          *
;;; *     B. The full (or partial) pathname to this            *
;;; *         AW51Launcher system program is stored            *
;;; *         at $280                                          *
;;; *                                                          *
;;; *     C. This AW51Launcher system program is located       *
;;; *         in the same directory as APLWORKS.SYSTEM         *
;;; *                                                          *
;;; ************************************************************

;;; ============================================================
;;; Apple II DeskTop Integration
;;;
;;; * Conversion to ca65 syntax and A2D coding style
;;; * Bitsy Bye launch protocol (sys path at $380)
;;; * Looks on current vol in /<vol>/AW5/APLWORKS.SYSTEM
;;; * For further discussion, see:
;;;    https://groups.google.com/g/comp.sys.apple2/c/lFRfyX0llhI

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"

        .include "../common.inc"

        MLIEntry := MLI

;;; ProDOS 2.4's Bitsy Bye invokes BASIS.SYSTEM with:
;;; * ProDOS prefix set to directory containing file.
;;; * Path buffer in BASIS.SYSTEM ($2006) set to filename.
;;; * $280 set to name of root volume (e.g. "/VOL")
;;; * $380 set to path of launched SYS (e.g. "/VOL/BASIS.SYSTEM")
BITSY_SYS_PATH  :=  $380

;;; AppleWorks
TaskStrup       = $11B1+$1000   ; flag to NOT load default

;;; ============================================================
;;; Memory usage:

SYS_PATH        :=  $280        ; populate for AppleWorks startup
IO_BUFFER       :=  $800        ; used to load APLWORKS.SYSTEM
RELOC_TARGET    := $1000        ; this code relocates here to run

PATHBUF         := $1F00        ; populated with target path
PATHBUF2        := $1F80        ; temporary PREFIX
FILENAME        := $1FF0        ; filename is stripped off

;;; ============================================================

        .org PRODOS_SYS_START

;;; ============================================================

        jmp     Start
        .byte   $EE             ; Protocol ID Byte #1
        .byte   $EE             ; Protocol ID Byte #2
        .byte   $41             ; Buffer Length
path:   .res    $41,0

;;; ============================================================

Start:
        ;; Relocate down out of the way of the next system file
        copy16  #reloc, STARTLO
        copy16  #reloc+sizeof_reloc-1, ENDLO
        copy16  #RELOC_TARGET, DESTINATIONLO
        ldy     #0
        jsr     MOVE

        ;; Stash path somewhere safe
        ldx     path
:       lda     path,x
        and     #$7F            ; clear high bit (c/o Bitsy Bye)
        sta     PATHBUF,x
        dex
        bpl     :-

        ;; Contnue in relocated code
        jmp     RELOC_TARGET

;;; ============================================================

.proc reloc
        .org ::RELOC_TARGET

;;; ============================================================

        ;; * Construct a target path for AppleWorks.
        ;; * Place it at $280
        ;; * Try to load it. If we fail, just QUIT.
        ;; * If we were passed a path:
        ;;   * Construct an absolute path using PREFIX
        ;;   * Split it into dir path and filename
        ;;   * Patch the macro block with it
        ;;   * Copy the macro block into AW
        ;;   * Poke AW to load the macro block
        ;; * Invoke AppleWorks

        ;; --------------------------------------------------
        ;; Construct a target path for APLWORKS.SYSTEM at $280

        ;; Append this system file's volume name
        ldx     #0
        ldy     #0
:       iny
        inx
        lda     BITSY_SYS_PATH,y
        and     #$7F             ; clear high bit (c/o Bitsy Bye)
        sta     SYS_PATH,x
        cmp     #'/'
        bne     :-
        cpy     #2
        bcc     :-
        ;; Append the relative path
        ldy     #0
:       iny
        inx
        lda     str_aplworks_path,y
        sta     SYS_PATH,x
        cpy     str_aplworks_path
        bne     :-
        stx     SYS_PATH

        ;; TODO: Consider GET_FILE_INFO call and checking file_type

        ;; --------------------------------------------------
        ;; Try to load APLWORKS.SYSTEM file

        MLI_CALL OPEN, open_params
        bne     quit
        lda     open_ref_num
        sta     read_ref_num
        sta     close_ref_num
        MLI_CALL READ, read_params
        pha
        MLI_CALL CLOSE, close_params
        pla
        beq     CheckPath

quit:   MLI_CALL QUIT, quit_params
        brk

;;; ============================================================

str_aplworks_path:
        PASCAL_STRING   "AW5/APLWORKS.SYSTEM"

;;; OPEN
open_params:
open_param_count:       .byte   3         ; in
open_pathname:          .addr   SYS_PATH  ; in
open_io_buffer:         .addr   IO_BUFFER ; in
open_ref_num:           .byte   0         ; out

;;; READ
read_params:
read_param_count:       .byte   4 ; in
read_ref_num:           .byte   0 ; in, populated at runtime
read_data_buffer:       .addr   PRODOS_SYS_START ; in
read_request_count:     .word   $FFFF            ; in
read_trans_count:       .word   0                ; out

;;; CLOSE
close_params:
close_param_count:      .byte   1 ; in
close_ref_num:          .byte   0 ; in, populated at runtime

;;; GET/SET_PREFIX
prefix_params:
prefix_param_count:     .byte   1        ; in
prefix_pathname:        .addr   PATHBUF2 ; in

;;; QUIT
quit_params:
quit_param_count:       .byte   4 ; in
quit_type:              .byte   0 ; in
quit_res1:              .word   0 ; reserved
quit_res2:              .byte   0 ; reserved
quit_res3:              .word   0 ; reserved

;;; ============================================================
;;; Check to see if we were passed a path. If so:
;;; * Construct an absolute path using PREFIX
;;; * Split it into dir path and filename
;;; * Patch the macro block with it
;;; * Copy the macro block into AW

CheckPath:
        lda     PATHBUF
        bne     :+
        jmp     LaunchAppleWorks ; no path, just launch as-is
:
        ;; Is `PATHBUF` absolute?
        lda     PATHBUF+1
        cmp     #'/'
        beq     SplitPath       ; yes

        ;; Relative - make `PATHBUF` absolute using PREFIX
        MLI_CALL GET_PREFIX, prefix_params
        beq     :+
        jmp     LaunchAppleWorks ; TODO: or QUIT?
:
        ldx     PATHBUF2        ; `PATHBUF2` is PREFIX
        ldy     #0              ; Append `PATHBUF`
:       iny
        inx
        lda     PATHBUF,y
        sta     PATHBUF2,x
        cpy     PATHBUF
        bne     :-
        stx     PATHBUF2

:       lda     PATHBUF2,x      ; Copy it into `PATHBUF`
        sta     PATHBUF,x
        dex
        bpl     :-

        ;; --------------------------------------------------
        ;; Split `FILENAME` off of `PATHBUF`
SplitPath:
        ;; Find last '/'
        ldx     PATHBUF
:       lda     PATHBUF,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-              ; always
:       txa
        pha                     ; index of last '/'

        ;; Copy filename out
        ldy     #0
:       inx
        iny
        lda     PATHBUF,x
        sta     FILENAME,y
        cpx     PATHBUF
        bne     :-
        sty     FILENAME

        ;; Update path length
        pla                     ; index of last '/'
        tax
        dex
        stx     PATHBUF         ; new length

        ;; --------------------------------------------------
        ;; TODO: Patch `PATHBUF` and `FILENAME` into macros

        ;; Patch `PATHBUF` into macros
        lda     #'"'           ; " string end delimiter
        ldy     PATHBUF
        sta     PassedPath,y
:       lda     PATHBUF,y
        sta     PassedPath-1,y
        dey
        bne     :-

        lda     #'"'           ; " string end delimiter
        ldy     FILENAME
        sta     PassedName,y
:       lda     FILENAME,y
        sta     PassedName-1,y
        dey
        bne     :-

        ;; --------------------------------------------------
        ;; Move macros to $EF00
.scope move_macros
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        move_src := macros
        move_end := macros+sizeof_macros-1
        move_dst := $EF00

        src := *+1
loop:   lda     move_src
        dst := *+1
        sta     move_dst

        lda     src
        cmp     #<move_end
        bne     :+
        lda     src+1
        cmp     #>move_end
        beq     done
:
        inc     src
        bne     :+
        inc     src+1
:
        inc     dst
        bne     loop
        inc     dst+1
        bne     loop            ; always
done:
        sta     ALTZPOFF
        bit     ROMIN2
.endscope ; move_macros

        ;; Set flag in SEG.UM to NOT load default macros.
        lda     #$01
        sta     TaskStrup
        .assert * = LaunchAppleWorks, error, "fall through"

;;; ============================================================

LaunchAppleWorks:
        jmp     PRODOS_SYS_START


;;; ============================================================
;;; NOTE: This Macro Table Gets Moved to $01/EF00 (UM4.x)
;;; ============================================================

;;; This is a block of UltraMacro macros by Hugh Hood that
;;; load the specified file, passed in as a directory path
;;; and filename.
;;;
;;; Hugh Hood writes:
;;; > Also (for anyone following along at home), in the source code
;;; > within the .shk file I linked I painstakingly de-constructed
;;; > the compiled macro table by using the Merlin DB pseudo opcode
;;; > over and over, line after line. I did that for illustrative
;;; > purposes only.
;;; >
;;; > In normal practice doing this type of thing, I use the
;;; > Merlin32 PUTBIN directive to just place the entire compiled
;;; > task file in memory, and then only copy the macro table ($1000
;;; > bytes), which begins at offset $200 in the file, to $01/EF00.
;;; > Not only is it much simpler to do it that way, it also makes
;;; > revisions to the macros easy to implement.
;;;
;;; In other words, don't try to modify or understand this too much.
;;; The important thing is that there are two "-delimited strings
;;; in there that get patched at runtime.

.proc macros
        SOM := *
        PASCAL_STRING "AW51Launcher" ; Task File name
        .byte   $00
        .byte   $00
        .byte   $00
;;; **--------------------------------------------------------------
        .byte   $E7             ;LockByte1 ($EF10)
;;; **--------------------------------------------------------------
        .byte   $00
        .byte   $00
        .word   $F0EF           ;End of Table + 1
        .byte   $00
        .byte   $02
        .byte   $07
        .byte   $01
        .byte   $00
        .byte   "MJ"            ; Brandt ID Markers
        .byte   $30
        .byte   $FF
;;; **--------------------------------------------------------------
        .byte   $20             ; ($EF1E)
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $D6
        .byte   $D7
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $D6
        .byte   $D7
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
;;; **--------------------------------------------------------------
        .byte   $18             ; LockByte2 ($EF6F)
;;; **--------------------------------------------------------------
;;; *Begin compiled macros ($01/EF70)
;;; **--------------------------------------------------------------
        .byte   $DD             ; <ba-]>
        .byte   $FF             ; all
;;; **--------------------------------------------------------------
        .byte   $9A             ; poke $11ac, 0
        .byte   $03
        .byte   $AC
        .byte   $11
        .byte   $80
;;; **--------------------------------------------------------------
        .byte   $99
        .byte   $30
        .byte   $81
        .byte   $3D
        .byte   $9F
        .byte   $A4
        .byte   $81
        .byte   $89
        .byte   $82
        .byte   $30
        .byte   $81
        .byte   $3D
        .byte   "\"MAIN MENU\""
        .byte   $84
        .byte   $0D
        .byte   $92
        .byte   $03
        .byte   $71
        .byte   $EF
        .byte   $F2
        .byte   $05
        .byte   $99
        .byte   $58
        .byte   $80
        .byte   $3D
        .byte   $26
        .byte   $03
        .byte   $60
        .byte   $B5
        .byte   $86
        .byte   $58
        .byte   $80
        .byte   $3D
        .byte   $80
        .byte   $87
        .byte   $9A
        .byte   $03
        .byte   $70
        .byte   $EF
        .byte   $9E
        .byte   $9A
        .byte   $03
        .byte   $A2
        .byte   $11
        .byte   $80
        .byte   $D1
        .byte   $D3
        .byte   $35
        .byte   $E3
        .byte   $A4
        .byte   $02
;;; **--------------------------------------------------------------
        .byte   "' You must activate Inits and reboot to use UltraMacros '"
;;; **--------------------------------------------------------------
        .byte   $3A
        .byte   $9E
        .byte   $F2
        .byte   $05
        .byte   $9C
        .byte   $41             ; <sa-A>
;;; **--------------------------------------------------------------
        .byte   $00             ; Next Macro
;;; **--------------------------------------------------------------
        .byte   $DB             ; <ba-[>
        .byte   $FF             ; all
;;; **--------------------------------------------------------------
        .byte   $A4             ; msg
        .byte   $02
;;; **--------------------------------------------------------------
        .byte   "' This Task file is to be launched from a program selector only '"
;;; **--------------------------------------------------------------
        .byte   $3A             ; .spacebar
        .byte   $F5
        .byte   $2B
        .byte   $88
        .byte   $99
        .byte   $5A             ; z(1) = z
        .byte   $81
        .byte   $3D
        .byte   $5A
        .byte   $80
;;; **--------------------------------------------------------------
        .byte   $9C
        .byte   $CC             ; <ba-L>
;;; **--------------------------------------------------------------
        .byte   $00             ; Next Macro
;;; **--------------------------------------------------------------
        .byte   $41             ; <sa-A>
        .byte   $04             ; <asr>
;;; **--------------------------------------------------------------
        .byte   $9C
        .byte   $44             ; <sa-D>
        .byte   $86
        .byte   $30
        .byte   $82             ; if $2 = ""
        .byte   $3D
        .byte   $22
        .byte   $22
        .byte   $A8             ; then
        .byte   $9C
        .byte   $CC             ; <ba-L>
        .byte   $F2
        .byte   $05             ; .SetDisk $1
        .byte   $F5
        .byte   $0C
        .byte   $89
        .byte   $30
        .byte   $81
        .byte   $E3
        .byte   $8D
        .byte   $9C
        .byte   $90
        .byte   $02
        .byte   $30
        .byte   $82
        .byte   $3A
        .byte   $0D
        .byte   $99
        .byte   $4C
        .byte   $81
        .byte   $3D
        .byte   $19
        .byte   $03
        .byte   $86
        .byte   $0E
        .byte   $82
        .byte   $4C
        .byte   $81
        .byte   $3D
        .byte   $80
        .byte   $A8
        .byte   $D1
        .byte   $1B
        .byte   $F2
        .byte   $05
        .byte   $9C
        .byte   $CC             ; <ba-L>
;;; **--------------------------------------------------------------
        .byte   $00
;;; **--------------------------------------------------------------
        .byte   $44             ; <sa-D>
        .byte   $04             ; <asr>
;;; **--------------------------------------------------------------
        .byte   $99             ; $1 = ""
        .byte   $30
        .byte   $81
        .byte   $3D
        .byte   $22
;;; **--------------------------------------------------------------
;;; **--------------------------------------------------------------
PassedPath:
        .byte   $22             ; space for passed prefix
        .res    63, $A8         ; use dummy 'then' tokens as place holders

;;; **--------------------------------------------------------------
        .byte   $99             ; $2 = ""
        .byte   $30
        .byte   $82
        .byte   $3D
        .byte   $22
;;; **--------------------------------------------------------------
PassedName:
        .byte   $22             ; space for passed file name
        .res    21, $A8         ; use dummy 'then' tokens as place holders
;;; **--------------------------------------------------------------
        .byte   $00
;;; **--------------------------------------------------------------
        .byte   $CC             ;< ba-L>
        .byte   $FF             ; <all>
;;; **--------------------------------------------------------------
        .byte   $9A             ; poke $11ac, $9B
        .byte   $03
        .byte   $AC
        .byte   $11
        .byte   $01
        .byte   $9B
        .byte   $EC             ; launch
        .byte   $02
        .byte   "\"seg.um\""
        .byte   $3A
;;; **--------------------------------------------------------------
        .byte   $00             ; End of Macro Table
;;; **--------------------------------------------------------------
        .byte   $1E
        .res    $300 - (* - SOM)
.endproc ; macros
        sizeof_macros = .sizeof(macros)
        PassedPath := macros::PassedPath
        PassedName := macros::PassedName
.endproc ; reloc
        sizeof_reloc = .sizeof(reloc)
