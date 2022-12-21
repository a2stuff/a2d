;;; ============================================================
;;;
;;; SmartPort
;;;
;;; ============================================================

;;; References:
;;; * Apple IIGS Firmware Reference
;;; * Apple IIc Technical Reference Manual, Second Edition
;;; * TechNotes: http://www.1000bit.it/support/manuali/apple/technotes/tn.0.html#smpt

.enum SPCall                    ; CMDNUM for SmartPort calls
        Status          = $00
        ReadBlock       = $01
        WriteBlock      = $02
        Format          = $03
        Control         = $04
        Init            = $05
        ;; For character devices:
        Open            = $06
        Close           = $07
        Read            = $08
        Write           = $09
.endenum

.struct SPDIB
        .union
Number_Devices          .byte   ; if unit_num == 0 && status_code == 0
Device_Statbyte1        .byte
        ;;  bit 7:  0 = character device, 1 = block device
        ;;  bit 6:  1 = write allowed
        ;;  bit 5:  1 = read allowed
        ;;  bit 4:  1 = device on line or disk in drive
        ;;  bit 3:  0 = format allowed
        ;;  bit 2:  0 = medium write protected (block devices only)
        ;;  bit 1:  1 = device currently interrupting
        ;;  bit 0:  1 = device currently open (character devices only)
        .endunion
        .union
Interrupt_Status        .byte   ; if unit_num == 0 && status_code == 0
Device_Size_Lo          .byte
        .endunion
Device_Size_Med         .byte
Device_Size_Hi          .byte
ID_String_Length        .byte
Device_Name             .res    16
Device_Type_Code        .byte
        ;; SPDeviceType
Device_Subtype_Code     .byte
Version                 .word
.endstruct

.enum SPDeviceType
        MemoryExpansionCard     = $00
        Disk35                  = $01
        ProFile                 = $02
        GenericSCSI             = $03
        ROMdisk                 = $04
        SCSICDROM               = $05
        SCSITape                = $06
        SCSIHardDisk            = $07
        Reserved                = $08
        SCSIPrinter             = $09
        Disk525                 = $0A
        Reserved2               = $0B
        Reserved3               = $0C
        Printer                 = $0D
        Clock                   = $0E
        Modem                   = $0F
.endenum
