;;; ============================================================
;;; SCREENSHOT - Desk Accessory
;;;
;;; Saves the contents of the graphics screen to a file.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_MAIN_SEGMENT

;;; ============================================================

        jmp     start

;;; ============================================================

        kBlockSize = $200
        BLOCK_BUFFER := DA_IO_BUFFER - kBlockSize
        .assert .lobyte(BLOCK_BUFFER) = 0, error, "page align"

        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, FT_GRAPHICS, $2000
        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS write_block_params, BLOCK_BUFFER, kBlockSize
        DEFINE_READWRITE_PARAMS write_screen_params, $2000, $2000
        DEFINE_CLOSE_PARAMS close_params


filename:
        PASCAL_STRING "Screenshot"


;;; ============================================================

start:  JUMP_TABLE_MGTK_CALL MGTK::HideCursor
        jsr     JUMP_TABLE_HILITE_MENU

        JUMP_TABLE_MLI_CALL CREATE, create_params
    IF CS
        cmp     #ERR_DUPLICATE_FILENAME
        bne     done
    END_IF

        JUMP_TABLE_MLI_CALL OPEN, open_params
        bcs     done
        lda     open_params::ref_num
        sta     write_block_params::ref_num
        sta     write_screen_params::ref_num
        sta     close_params::ref_num

        ;; ----------------------------------------
        ;; Aux Segment

        ;; Mark Graphics file as "560 x 192 Black & White"
        ;; See File Type Note $08
        sta     SET80STORE
        sta     PAGE2ON
        lda     #2
        sta     $2000+$78
        sta     PAGE2OFF
        sta     CLR80STORE

        ;; Can't write it with 80STORE on since banking not guaranteed
        ;; during ProDOS I/O (e.g. aux RAM disks), so do it block by
        ;; block.
        ptr := $06
        copy16  #$2000, ptr
        ldy     #$00

    DO
        sta     SET80STORE
        sta     PAGE2ON

      DO
        lda     (ptr),y
        sta     BLOCK_BUFFER,y
        iny
      WHILE NOT_ZERO
        inc     ptr+1

      DO
        lda     (ptr),y
        sta     BLOCK_BUFFER+$100,y
        iny
      WHILE NOT_ZERO
        inc     ptr+1

        sta     PAGE2OFF
        sta     CLR80STORE

        JUMP_TABLE_MLI_CALL WRITE, write_block_params

        lda     ptr+1
    WHILE A <> #$40

        ;; ----------------------------------------
        ;; Write main segment

        ;; Just write directly
        JUMP_TABLE_MLI_CALL WRITE, write_screen_params

close:  JUMP_TABLE_MLI_CALL CLOSE, close_params

done:   jsr     JUMP_TABLE_HILITE_MENU
        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        rts


;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
