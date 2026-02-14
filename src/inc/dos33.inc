;;; DOS 3.3 details c/o Beneath Apple DOS by Don Worth and Pieter Lechner

.scope dos33

VTOCTrack       = 17
VTOCSector      = 0
MaxFilenameLen  = 30

DefaultFirstCatalogSector  = $F ; TODO: Use data in VTOC instead

;;; Volume Table Of Contents (VTOC) Format
;;; TODO: This should be a struct but the offsets would be weird
.scope VTOC
FirstCatTrack   = $01 ; +$01 Track number of first catalog sector (usually $11)
FirstCatSector  = $02 ; +$02 Secto number of first catalog sector (usually $F)
;;;                     +$04-$05 Not used
VolumeNumber    = $06 ; +$06 Diskette volume number (1-254)
;;;                     +$07-$26 Not used
MaxTSPairs      = $27 ; +$27 Maximum number of track/sector pairs per sector (normally 122)
;;;                     +$28-$2F Not used
LastTrackAlloc  = $30 ; +$30 Last track where sectors were allocated
TrackAllocDir   = $31 ; +$31 Direction of track allocation (+1 or -1)
;;;                     +$32-$33 Not used
NumTracks       = $34 ; +$34 Number of tracks per diskette (normally 35)
NumSectors      = $35 ; +$35 Number of sectors per track (13 or 16)
BytesPerSector  = $36 ; +$36 Number of bytes per sector (LO/HI format)
BitMap          = $38 ; +$38 Bit map of free sectors (4 bytes per track)
BitMapTrack0    = $38 ; +$38...$3B for track 0
BitMapTrack1    = $3C ; +$3C...$3F for track 1 ...
BitMapTrack34   = $C0 ; +$C0...$C3 for track 34
.endscope ; VTOC

;;; Catalog Sector Format
NextCatSectorTrack      = $01 ; Track number of next catalog sector (usually $11)
NextCatSectorSector     = $02 ; Sector number of next catalog sector
FirstFileOffset         = $0B ; First file descriptive entry

;;; File Descriptive Entry Format
.struct FileEntry
Track           .byte  ; +$00 Track of first track/sector list sector
Sector          .byte  ; +$01 Sector of first track/sector list sector
TypeFlags       .byte  ; +$02 File type and flags
Name            .res dos33::MaxFilenameLen ; +$03-$20 File name (30 characters)
Length          .word  ; +$21-$22 Length of file in sectors (LO/HI)
.endstruct

;;; File Track/Sector List Format
;;; TODO: This should be a struct but the offsets would be weird
.scope TSList
Unused          = $00   ; Not used
NextTrack       = $01   ; Track number of next T/S List sector (or 0)
NextSector      = $02   ; Sector number of next T/S List sector (or 0)
FirstDataT      = $0C   ; Track of first data sector (or 0)
FirstDataS      = $0D   ; Sector of first data sector
.endscope ; TSList

;;; File types
FileTypeText            = $00
FileTypeInteger         = $01
FileTypeApplesoft       = $02
FileTypeBinary          = $04
FileTypeS               = $08
FileTypeRelocatable     = $10
FileTypeA               = $20
FileTypeB               = $40

.endscope ; dos33
