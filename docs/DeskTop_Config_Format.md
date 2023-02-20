# `DESKTOP.CONFIG` File Format

This file captures settings. Control Panel DAs write out this file
when a setting has been modified.

The file length is 129 bytes.

## Header

Header is one byte.

|  Offset  |  Length    | Description      |
|---------:|:----------:|:-----------------|
|  +$0000  |  byte (1)  | FileVersion      |

* **FileVersion**

   This is compared against `kDeskTopSettingsFileVersion` on load. If
   different, the file is ignored. (This is used to handle version
   skew.)

   The current version documented here is $03.

## Settings

File offset +$0001. The remaining 128 bytes the file are defined by the
`DeskTopSettings` struct in `../common.inc`.

|  Offset  |  Length    | Description          |
|---------:|:----------:|:----------------------|
|  +$0000  |  8         | pattern              |
|  +$0008  |  word (2)  | dblclick speed       |
|  +$000A  |  word (2)  | IP blink speed       |
|  +$000C  |  byte (1)  | clock 24hours flag   |
|  +$000D  |  byte (1)  | RGB color flag       |
|  +$000E  |  byte (1)  | mouse tracking speed |
|  +$000F  |  byte (1)  | options              |
|  +$0010  |  byte (1)  | date separator       |
|  +$0011  |  byte (1)  | time separator       |
|  +$0012  |  byte (1)  | thousands separator  |
|  +$0013  |  byte (1)  | decimal separator    |
|  +$0014  |  byte (1)  | date order           |
|  +$0015  |  107       | reserved             |

* **pattern**

   The desktop background pattern. An 8x8 pixel bitmap.

* **dblclick speed**

   Maximum time to wait for a second click to be considered a
   double-click. The number is in iterations of the event loop.

* **IP blink speed**

   Speed at which the insertion point in text entry fields blinks. The
   number is in iterations of the event loop.

* **clock 24hours flag**

   Determines how times are displayed.

   | Value | Meaning        |
   |------:|:---------------|
   | $00   | 12-hour        |
   | $80   | 24-hour        |

* **RGB color flag**

   On systems with RGB/monochrome control (e.g. IIgs), this
   determines if UI is presented in monochrome or color. The
   default is monochrome.

   | Value | Meaning        |
   |------:|:---------------|
   | $00   | monochrome     |
   | $80   | color          |

* **mouse tracking speed**

   | Value | Meaning        |
   |------:|:---------------|
   | $00   | normal (1x)    |
   | $01   | fast (2x)      |

* **options**

   This controls various options.

   | Bit   | Meaning if clear                                                  | Meaning if set                          |
   |------:|:------------------------------------------------------------------|:----------------------------------------|
   | 0     | At startup, if RAMCard present, copy DeskTop and shortcuts to it  | Skip copying to RAMCard                 |
   | 1     | At startup, if shortcuts defined, run Selector instead of DeskTop | Skip showing Selector                   |
   | 2     | Do not show keyboard shortcuts for buttons in dialogs             | Show button shortcuts in dialogs        |

* **date separator**

   The separator used in dates, e.g. 1/2/34.

* **time separator**

   The separator used in times, e.g. 12:34

* **thousands separator**

   The separator used in thousand groups, e.g. 1,234

* **decimal separator**

   The separator used for decimals, e.g. 3.14

* **date order**

   | Value | Meaning            |
   |------:|:-------------------|
   | $00   | Month / Day / Year |
   | $01   | Day / Month / Year |

* **reserved**

   Bytes must be 0. If possible, future settings will be added with 0
   bytes denoting the default behavior. This will allow upgrades
   without requiring a change to the file version and a loss of
   previous settings.
