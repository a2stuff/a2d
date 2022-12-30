# Desk Accessory API

Desk Accessories for DeskTop have general access to the Mouse Graphics
Tool Kit MLI, ProDOS MLI, and DeskTop APIs. Special considerations for
DAs are documented here.

## File Format & Loading

Desk Accessories have a 4-byte header that define the size of Aux
memory (16-bit, little endian) and Main memory (16-bit, little-endian)
segments respectively.

* If non-zero in size, the Aux memory segment is loaded to Aux $800
* The Main memory segment (required) is loaded to Main $800

Since MGTK resides in Aux memory, resources (e.g. bitmaps) and
structs (e.g. Winfos and GrafPorts) must reside in Aux, so it is
typical to place these in the Aux segment.

Each segment can extend from $800 - $1C00, so $1400 bytes each.

Use these macros to help define the file structure:

```asm
    ;; Instantiate the file header
    DA_HEADER

    ;; Optional:
    DA_START_AUX_SEGMENT
    ;; Code and resources to load starting at $800 Aux
    DA_END_AUX_SEGMENT

    ;; Required:
    DA_START_MAIN_SEGMENT
    ;; Code and resources to load starting at $800 Main
    DA_END_MAIN_SEGMENT
```

It may be helpful to bound the Aux and Main segments with scopes
e.g. `.scope aux ... .endscope` to make cross-segment references
clearer. This is not done universally since ca65 limitations
with forward references to scopes make it awkward.

## Desk Accessory Execution Environment

After loading, the entry point at $800 Main is invoked. Once running,
memory from $800 to $2000 in both Main and Aux is available for use.

Remember that:

* Toolkit calls must reference params and resources in Aux (or the ZP)
* ProDOS MLI calls must reference params and buffers in Main

Simple DAs that operate on files with no UI (e.g. Sort Directory, Run
Basic Here) can reside entirely in Main memory and not use Aux at all.
DAs that do not operate on files can run almost entirely from Aux.
More complex DAs will typically do a mix of both.

DAs can use these macros to make cross-bank subroutine calls:

* `JSR_TO_MAIN addr` - call aux to main; A,X trashed, Y preserved
* `JSR_TO_AUX addr` - call aux to main; A,X trashed, Y preserved

Calls can be into the "other" segment of a Desk Accessory or
into the

Memory can be transferred using the standard `AUXMOVE` routine.

DeskTop and hence Desk Accessories execute with Aux ZP/Stack/LC banked
in. This bank state is required for any DeskTop or Toolkit call, and
at exit.

On exit, a DA should `RTS` back to the caller from Main memory.

### Execution from Main Memory

DAs can make MGTK calls using the `JUMP_TABLE_MGTK_CALL` macro, which
takes care of the required banking. Note that the referenced
parameters must reside in Aux memory. For static data or opaque
structures (e.g. bitmap, Winfos, GrafPorts, etc.) the code can simply
pass the address of the data in Aux memory. For data modified at
runtime (e.g. strings, events, etc.) it is necessary to copy the data
Main to Aux before and/or Aux to Main after the call using `AUXMOVE`.

Calls into other tookits (Button TK, Line Edit TK) are not currently
supported. (But this is straightforward to add, if needed.)

DAs can make ProDOS MLI calls using `JUMP_TABLE_MLI_CALL` macro. This
is required because DeskTop operates with Aux ZP/Stack/LC banked in,
and ProDOS requires Main ZP/ROM banked in. $1C00-$2000 is a good place
for an I/O buffer.

### Execution from Aux Memory

DAs can make toolkit calls directly by defining an entry point and
using macros:

* MGTK: define `MGTKEntry := MGTKAuxEntry` and use `MGTK_CALL`
* Button TK: define `BTKEntry := BTKAuxEntry` and use `BTK_CALL`
* LineEdit TK: define `LETKEntry := LETKAuxEntry` and use `LETK_CALL`

ProDOS MLI calls directly from Aux memory are _not supported_. DAs
running from Aux memory need to implement helper methods in Main which
they can call to do file operations, and any loaded data needs to
be proxied back to Aux memory using `AUXMOVE`.

## UI Lifecycle

See [Creating Applications and DeskTop Desk Accessories](../mgtk/MGTK.md#creating-applications-and-desktop-desk-accessories) for full details about the lifecycle of an MGTK-based application or desk accessory. In summary, though:

* Create window (`OpenWindow`)
* Draw everything
* Flush event queue (`FlushEvents`)
* Run an event Loop (`GetEvent`, and subsequent processing, per MGTK)
  * Call `JUMP_TABLE_YIELD_LOOP` in the loop so DeskTop can update the clock, etc.
  * Normal event processing per MGTK
  * Following a window drag/resize, a DeskTop call must be made:
    * `JUMP_TABLE_CLEAR_UPDATES` - redraw needed parts of windows and desktop (volume) icons.
* Destroy window (`CloseWindow`)
   * Call `JUMP_TABLE_CLEAR_UPDATES` to let DeskTop know it needs to redraw.


To perform the `JUMP_TABLE_XYZ` calls from Aux memory, use the `JSR_TO_MAIN` macro.

## Accessing Files

As a convenience, DAs are launched with the full path to the first
selected file at $220 Main. This applies to both Preview DAs (executed
automatically when a text/image/etc file is opened) and to DAs invoked
from the menu. If no file is selected, $220 is set to 0.

For more elaborate operations, e.g. on directories or multiple files,
the following DeskTop calls can be used:

* `JUMP_TABLE_GET_SEL_COUNT` - returns the number of selected icons in A
* `JUMP_TABLE_GET_SEL_WIN` - returns the window id holding the selection (0 if desktop) in A
* `JUMP_TABLE_GET_WIN_PATH` - called with window id in A, returns the path (in Aux LC1) in A,X
* `JUMP_TABLE_GET_SEL_ICON` - called with selection index in A, returns IconEntry (in Aux LC1) in A,X
