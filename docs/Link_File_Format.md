# Link File Format

This file type represents a link to another file in the filesystem. It
is roughly analogous to a Windows Shortcut file (Shell Link/.LNK), a
macOS Alias file, or a POSIX symbolic link.

File Type: $E1 `LNK` ("link")
Aux Type: $0001

The file length is variable; at least 6 bytes.

Note that it is considered valid for a file be padded with extra
space. For example, implementations may always write out a file with
room for a 64-byte path. Extra bytes must be ignored. Future file
version specifications must take this behavior into account.

## Header

Header is 3 bytes.

|  Offset  |  Length    | Description      |
|---------:|:----------:|:-----------------|
|  +$0000  |  byte (2)  | Signature        |
|  +$0002  |  byte (1)  | FileVersion      |

* **Signature**

   The signature are the bytes $C2 $CD. ("BM" with high bits set).

* **FileVersion**

   This is compared against `kLinkFileVersion` on load. If different,
   an error is shown.

   The current version documented here is $00.

## Path

File offset +$0003.

|  Offset  |  Length    | Description      |
|---------:|:----------:|:-----------------|
|  +$0000  |  byte (1)  | PathLength       |
|  +$0001  |  variable  | PathName         |

* **PathLength** and **PathName**

   This is the ProDOS path of the target. The `PathLength` is always
   greater than 1, and at most 64 ($40). The `PathName` is an absolute
   path, e.g. "/HD/AW5/APLWORKS.SYSTEM"
