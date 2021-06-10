# Apple II DeskTop

[![Build Status](https://travis-ci.com/a2stuff/a2d.svg?branch=main)](https://travis-ci.com/a2stuff/a2d)

Disassembly and enhancements for Apple II DeskTop (a.k.a. MouseDesk), a "Finder"-like GUI application for 8-bit Apples and clones with 128k of memory, utilizing double hi-res monochrome graphics (560x192), an optional mouse, and the ProDOS 8 operating system.

💾 Download [Disk Images](https://github.com/a2stuff/a2d/releases)

📖 Read the [Documentation](https://a2desktop.com/docs)

📝 Check the [Release Notes](https://github.com/a2stuff/a2d/blob/main/RELEASE-NOTES.md)

## Background

The application started its life as **MouseDesk** by Version Soft. Apple Computer licensed the software and released it, at first as MouseDesk 2.0, then rebranded **Apple II DeskTop** as the initial [system software for the Apple IIgs](http://www.whatisthe2gs.apple2.org.za/system-applications) before 16-bit GS/OS replaced it. It still functions on 8-bit Apples, including the Apple IIe, Apple IIc, Apple IIc Plus, Apple IIe Option Card for Macintosh, and the Laser 128 family.

* [History of MouseDesk/Apple II DeskTop Versions](https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info), by Jay Edwards
* Overviews: [GUI Gallery](http://toastytech.com/guis/a2desk.html) &mdash; [GUIdebook](https://guidebookgallery.org/guis/apple2/mousedesk)
* Manual: [Apple IIgs System Disk User’s Guide (1986)](https://mirrors.apple2.org.za/ftp.apple.asimov.net/documentation/misc/Apple%20IIgs%20System%20Disk%20Users%20Guide%20%281986%29.pdf) - Chapter 2 “The DeskTop”
* [Disk Images for MouseDesk and Apple II DeskTop](https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/masters/other_os/gui/)

Other GUI environments exist for the 8-bit Apples, including [GEOS](http://toastytech.com/guis/a2geos.html) (which includes productivity applications) and [Quark Catalyst](http://toastytech.com/guis/qcat.html). While Apple II DeskTop is more limited then GEOS, serving only as a file manager and application launcher, it follows more common interface paradigms and is better integrated with ProDOS.

## This Project

The goal of this project is to disassemble/reverse-engineer the suite with an eye towards understanding how it functions, fixing bugs, and adding functionality.

See the [Release Notes](RELEASE-NOTES.md) for a list of enhancements and fixes so far.

End-user documentation is at the companion web site: https://a2desktop.com

[![Alt Text](https://img.youtube.com/vi/zbElPj5zaBs/0.jpg)](https://www.youtube.com/watch?v=zbElPj5zaBs)
<br>
_KansasFest 2018 presentation by @mgcaret_

Additional help is welcome! See the guide for [Contributing](CONTRIBUTING.md).

## Tools

The [cc65](http://cc65.github.io/cc65/) tool chain is used; source files target the ca65 macro assembler. Cross-development on modern systems is assumed. (Sorry, Merlin purists! We still love you.) See the [Coding Style](docs/Coding_Style.md) for more.

See [Building And Running](docs/Building_And_Running.md) instructions.

## Code of Conduct

Discussions should be polite, respectful and inclusive, and focus on the code. Harassment will not be tolerated. Keep comments constructive. Please read the full [Code of Conduct](CODE_OF_CONDUCT.md).
