# `SELECTOR.LIST` File Format

Data length is 1922 bytes. The file is 2048 bytes, with padding making
up the difference.

There are two lists ("run list", "other run list"), which can have up
to 8 or 16 entries respectively. If an entry is deleted, later entries
within each list are shifted down.


## Header

Header is two bytes.

+000: NumRunListEntries (byte)

   Number of entries (0-8) in the "run list". The are the entries
   shown in DeskTop's Selector menu, and the first 8 entries shown in
   DeskTop's "Run an Entry..." dialog and Selector's dialog.

+001: NumOtherRunListEntries (byte)

   Number of entries (0-16) in the "other run list". These entries are
   only shown in DeskTop's "Run an Entry..." dialog and Selector's
   dialog.


## Entries List

Offset +002. There are always 24 entries. Each entry is 16 bytes.

The first 8 entries are for the "run list", regardless of
NumRunListEntries.

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

The first 8 entries are for the "run list", regardless of
NumRunListEntries.
