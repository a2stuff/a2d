;;; ============================================================
;;;
;;; SmartPort
;;;
;;; ============================================================

;;; References:
;;; * Apple IIGS Firmware Reference
;;; * Apple IIc Technical Reference Manual, Second Edition
;;; * TechNotes: https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/tn.0.html#smpt

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

;; Request codes for STATUS calls
.enum SPStatusRequest
        DeviceStatus    = $00   ; Return device status
        DCB             = $01   ; Return device control block (DCB)
        NewlineStatus   = $02   ; Return newline status (character devices only)
        DIB             = $03   ; Return device information block (DIB)
        UniDisk35       = $05   ; Return UniDisk 3.5 status
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

.macro DEFINE_SP_STATUS_PARAMS name, un, lp, sc
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   3
unit_num:       .byte   un
list_ptr:       .addr   lp
status_code:    .byte   sc
        .refto param_count
        .refto unit_num
        .refto list_ptr
        .refto status_code
.endparams
.endmacro

;;; Request codes for CONTROL calls
.enum SPControlRequest
        Reset                   = $00
        SetDCB                  = $01
        SetNewlineStatus        = $02
        ServiceDeviceInterrupt  = $03
        Eject                   = $04
.endenum

.macro DEFINE_SP_CONTROL_PARAMS name, un, cl, cc
        WARN_IF_SHADOWING name
.params name
param_count:    .byte   3
unit_number:    .byte   un
control_list:   .addr   cl
control_code:   .byte   cc
        .refto param_count
        .refto unit_number
        .refto control_list
        .refto control_code
.endparams
.endmacro

;;; SmartPort control codes for early Apple SCSI cards. Documented in
;;; the Apple II SCSI Card Technical Reference Manual.
.enum SPControlSCSIAudio
        AudioSearch = $20
        AudioPlay = $21
        AudioPause = $22
        AudioStop = $23
        AudioStatus = $24
        AudioScan = $25
        Eject = $26
        ReadTOC = $27
        ReadQSubcode = $28
.endenum
