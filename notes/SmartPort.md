
# SmartPort unmapping

## Problem statement

Given a ProDOS-8 Slot/Drive assignment (i.e. a unit number in `DEVLST`), identify the SmartPort dispatch vector address and unit to request information and issue commands for functionality that ProDOS-8 does not expose.

> Why? Apple II DeskTop is a ProDOS-8 application aimed at ProDOS-8 users. It relies on the ProDOS-8 API for nearly all operations[^1], and assumes the user things of volumes in terms of both paths (e.g. `/MY.DISK`) and Slot/Drive assignments (`CAT,S6,D1`).

Currently this is done by inspecting internal ProDOS tables. That is done by looking at the ProDOS driver addresses and using a mapping table from driver address to the internal dispatch vector lo, dispatch vector hi, and unit tables.

This is incredibly fragile, and supporting this risks hindering ProDOS-8 development.

## SmartPort Uses in Apple II DeskTop

These are all of the places where the application relies on being able to make a direct SmartPort call given a ProDOS-8 unit number as input:

* **Launcher** (a.k.a. `DeskTop.system`)
  * Enumerate `DEVLST` to identify a RAMDisk - `SPCall::Status`/`SPStatusRequest::DIB`
* **DeskTop** (the Finder-like module)
  * At startup:
    * Enumerate `DEVLST` to identify device type (for volume icon) & name (for Format/Erase dialog) - `SPCall::Status`/`SPStatusRequest::DIB`
    * Enumerate `DEVLST` to identify drives to poll - `SPCall::Status`/`SPStatusRequest::DIB`
  * After startup:
    * Special > Eject command (or drag volume to trash)
      * Determine if ejectable - `SPCall::Status`/`SPStatusRequest::DIB`
      * Do the eject -  `SPCall::Control`/`SPControlRequest::Eject`
* **Disk Copy** (a dedicated module with 60K free)
  * At the start of a copy: Is this device ejectable? `SPCall::Status`/`SPSTatusRequest::DIB`
  * During a copy: Auto-eject when swapping disks `SPCall::Control`/`SPControlRequest::Eject`

> NOTE: the **About This Apple II** and **CD Remote** accessories also make direct SmartPort calls, but these have no dependencies on ProDOS-8 slot/drive mapping.

## Fix?

Some approaches have been suggested but rejected (pending further data):

* Do a ProDOS ON_LINE call, then enumerate all SmartPort devices request Block 2 to build a mapping by comparing volume names. The problem is that this doesn't handle empty devices / unformatted disks, which are a use case.
  * Total Replay builds map by reading/comparing blocks using ProDOS vs. SmartPort. But it doesn't care about empty/unformatted disks.
* Abandon the ProDOS-8 Slot/Drive notion entirely. That's... basically a complete rewrite.

Other ideas that haven't been ruled out but require collaboration w/ the ProDOS maintainers:
* Add a new [ProDOS-8 MLI API](https://prodos8.com/docs/techref/calls-to-the-mli/#4.3) call to map a unit to SP dispatch/unit
* Add 2 new [ProDOS-8 MLI API](https://prodos8.com/docs/techref/calls-to-the-mli/#4.3) calls to do a Status request for DIB and Status request for Eject.
* Add support to the [ProDOS-8 Driver API](https://prodos8.com/docs/techref/adding-routines-to-prodos/#6.3)  for:
  * `SPCall::Status`+DIB - _need parameter to request this_
  * `SPCall::Control`+eject - _need new command + parameter to request this_
  * ... and a way to probe for support
* A blend of the above, e.g. new MLI call to request DIB; if that is supported, then CONTROL can be issued to driver.
* Any other more maintainable way to get from the driver address in `DEVADR` to the mapping tables
  * e.g. "if driver starts with `CLV` then..."

Other thoughts:

* Instead of reverse-engineering the mapping, can we make the existing ProDOS driver do it for us?
  * i.e. call into [`remap_sp`](https://github.com/A2osX/A2osX/blob/14e31234426a6f62c761c90192857c5c346718c2/ProDOS.203/ProDOS.S.XDOS.F.txt#L524) by using the `DEVADR` entry for that Slot/Drive, and issue a driver `STATUS` call (which directly maps to `SPCall::Status`) with different parameters to request a DIB, or pass 4 which is `SPCall::Control`.
  * From code inspection, looks like...
    * `SPCall::Status`/`SPStatusRequest::DIB` - no, code is forced to 0
    * `SPCall::Control`/`SPControlRequest::Eject` - looks like it might work? Pass `CONTROL`=4 (not currently a valid driver command) and specify 4 as block number, and it might get smuggled through okay?
      * But unless we know the drive is ejectable, this is not safe to issue.
* Idea: at runtime, search within the ProDOS driver for the logic:
  ```
    4A       LSR
    4A       LSR
    4A       LSR
    4A       LSR
    AA       TAX
    ...
    BD xx xx LDA spunit-1,x       ; obtain spunit
    ...
    BD xx xx LDA spvectlo-1,x     ; obtain spvectlo
    ...
    BD xx xx LDA spvecthi-1,x     ; obtain spvecthi
  ```

## Also

* Unrelated: is slot 5 remapping (for non-SP but block devices) handled? Should it be?
  * $Cn07 != 0 means generic block device (not SmartPort), $CnFE bits 4-5 = DevCnt (etc)
  * Calls driver directly (does it???)


[^1]: DeskTop works around other limitations in ProDOS-8 in a small number of ways:
  * Formatting disks in Disk ][ drives - uses a code library and talks directly to the hardware
  * Reading/writing GS/OS "case bits" for files and volumes - uses `READ_BLOCK`/`WRITE_BLOCK`
  * Moving files within a volume - done by (a) using `CREATE` to create a file at the destination path, (b) swapping directory entries using directory iteration and `READ_BLOCK`/`WRITE_BLOCK`, and finally (c) using `DESTROY` on the source path
