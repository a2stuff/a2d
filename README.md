# Apple II DeskTop

[![Build Status](https://travis-ci.org/inexorabletash/a2d.svg?branch=master)](https://travis-ci.org/inexorabletash/a2d)

Work-in-Progress disassembly and enhancements for Apple II Desktop (a.k.a. MouseDesk)

💾 Disk images can be found on the [Releases](https://github.com/inexorabletash/a2d/releases) page 💾

## Background

This application started its life as **MouseDesk** by Version Soft. It
is a mouse-driven Mac-like "Finder" GUI application for 8-bit Apples
and clones with 128k of memory, utilizing double-hires monochrome graphics
(560x192), an optional mouse, and the ProDOS operating system.

Apple Computer acquired the software and released it - rebranded as
**Apple II DeskTop** - as the initial
[system software for the Apple IIgs](](http://www.whatisthe2gs.apple2.org.za/system-applications))
before 16-bit GS/OS replaced it. The rebranded version still functions
on 8-bit Apples, including the Apple IIe, Apple IIc, Apple IIc Plus,
Apple IIe Option Card for Macintosh, and the Laser 128 family.

* [History of MouseDesk/Apple II DeskTop versions, by Jay Edwards](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info)
* Overviews: [GUI Gallery](http://toastytech.com/guis/a2desk.html) &mdash; [GUIdebook](https://guidebookgallery.org/guis/apple2/mousedesk)
* Manual: [Apple IIgs System Disk User’s Guide (1986)](https://mirrors.apple2.org.za/ftp.apple.asimov.net/documentation/misc/Apple%20IIgs%20System%20Disk%20Users%20Guide%20%281986%29.pdf) - Chapter 2 “The DeskTop”
* [Disk Images](https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/masters/other_os/gui/) for MouseDesk and Apple II DeskTop

Other GUI environments exist for the 8-bit Apples, including
[GEOS](http://toastytech.com/guis/a2geos.html) (which includes productivity applications) and
[Quark Catalyst](http://toastytech.com/guis/qcat.html).
While Apple II DeskTop is more limited -
serving only as a file manager and application launcher - it is (subjectively)
more visually appealing and better integrated with ProDOS.

## This Project

The goal of this project is to disassemble/reverse-engineer the suite
with an eye towards understanding how it functions, fixing bugs, and
adding functionality.

See the [Release Notes](RELEASE-NOTES.md) for a list of enhancements and fixes so far.

[![Alt text](https://img.youtube.com/vi/zbElPj5zaBs/0.jpg)](https://www.youtube.com/watch?v=zbElPj5zaBs)
<br>
_KansasFest 2018 presentation by @mgcaret_

Additional help is welcome! See the guide for [Contributing](CONTRIBUTING.md).

## Tools

The [cc65](http://cc65.github.io/cc65/) tool chain will be used; source files will
target the ca65 macro assembler. Cross-development on modern systems will be assumed.
(Sorry, Merlin purists! We still love you.)

Fetch the code, then build/install with: `make ca65 ld65 avail`.

## Code of Conduct

Discussions should be polite, respectful and inclusive, and focus on the code.
Harassment will not be tolerated. Keep comments constructive.
Please read the full [Code of Conduct](CODE_OF_CONDUCT.md).
