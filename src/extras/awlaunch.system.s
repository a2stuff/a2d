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
;;; *          *  ASSUMPTIONS MADE BY AW51Launcher  *          *
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

        ;; Continue in relocated code
        jmp     RELOC_TARGET

;;; ============================================================

.proc reloc
        .org ::RELOC_TARGET

        jmp     ConstructPath
;;; ============================================================

;;; ============================================================

str_aplworks_path:
        PASCAL_STRING   "AW5/APLWORKS.SYSTEM"

        DEFINE_OPEN_PARAMS open_params, SYS_PATH, IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, PRODOS_SYS_START, $FFFF
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_PREFIX_PARAMS prefix_params, PATHBUF2
        DEFINE_QUIT_PARAMS quit_params

;;; ============================================================

        ;; * Construct a target path for AppleWorks.
        ;; * Try to load it. If we fail, just QUIT.
        ;; * If we were passed a path:
        ;;   * Construct an absolute path using PREFIX.
        ;;   * Split it into dir path and filename.
        ;;   * Patch the macro block with it.
        ;;   * Copy the macro block into AW.
        ;;   * Poke AW to load the macro block.
        ;; * Invoke AppleWorks.

        ;; --------------------------------------------------
        ;; Construct a target path for APLWORKS.SYSTEM at $280

ConstructPath:
        ;; Append this system file's volume name
        ldx     #0
        ldy     #0
:       iny
        inx
        lda     SYS_PATH,y
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
        bcs     quit
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        pha
        MLI_CALL CLOSE, close_params
        pla
        bcc     CheckPath

quit:   MLI_CALL QUIT, quit_params
        brk


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
        bcc     :+
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
        ;; Patch `PATHBUF` and `FILENAME` into macros

        ;; Patch `PATHBUF` into macros
        lda     #'"'           ; " string end delimiter
        ldy     PATHBUF
        sta     PassedPath,y
:       lda     PATHBUF,y
        sta     PassedPath-1,y
        dey
        bne     :-

        ;; Patch `FILENAME` into macros
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
        bit     ROMIN           ; Read ROM; write RAM
        bit     ROMIN

        copy16  #macros, STARTLO
        copy16  #macros+sizeof_macros-1, ENDLO
        copy16  #$EF00, DESTINATIONLO
        ldy     #0
        jsr     MOVE

        sta     ALTZPOFF
        bit     ROMIN2          ; Read ROM; no write
.endscope ; move_macros

        ;; --------------------------------------------------
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
        .incbin "awlaunch_task.bin"
.endproc ; macros
        sizeof_macros = .sizeof(macros)
        PassedPath := macros + $1A1 ; index of second " in 2nd empty string
        PassedName := macros + $1E6 ; index of second " in 3rd empty string
.endproc ; reloc
        sizeof_reloc = .sizeof(reloc)
