# `SELECTOR.LIST` File Format

This defines the shortcut menu entries present in DeskTop, as well as
the entries shown in the optional Selector application.

Data length is 1922 bytes. The file is 2048 bytes, with padding making
up the difference.

There are two separate lists (primary and secondary), which can have up
to 8 or 16 entries respectively. If an entry is deleted, later entries
within each list are shifted down.


## Header

Header is two bytes.

+000: NumPrimaryRunListEntries (byte)

   Number of entries (0-8) in the primary list. The are the entries
   shown in DeskTop's Shortcuts menu, and the first 8 entries shown in
   DeskTop's "Run a Shortcut..." dialog and Selector's dialog.

+001: NumSecondaryRunListEntries (byte)

   Number of entries (0-16) in the secondary list. These entries are
   only shown in DeskTop's "Run a Shortcut..." dialog and Selector's
   dialog.


## Entries List

Offset +002. There are always 24 entries. Each entry is 16 bytes.

The first 8 entries are for the primary list, regardless of
NumPrimaryListEntries.

+000: LabelLength (byte)

   Length of the entry label. 0-14.

+001: Label (14 bytes)

   Label, encoded as ASCII bytes.

+015: CopyFlags (byte)

   $00 = copy to RAM disk on first boot
   $80 = copy to RAM disk on first use
   $C0 = never copy


## Path List

Offset +386. There are always 24 entries. Each entry is a 64 byte,
length-prefixed pathname.

The first 8 entries are for the primary list, regardless of
NumPrimaryListEntries.
