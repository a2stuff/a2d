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
