# A2D

Work-in-Progress disassembly of Apple II Desktop (a.k.a. A2.Desktop)

## Background

A2.Desktop started its life as "Mousedesk" by Version Soft, as a mouse-driven
Mac-like "Finder" GUI application for 8-bit Apples with 128k of memory
(Enhanced Apple //e, Apple //c) using double-hires monochrome graphics
(560x192) and the ProDOS operating system.

Although the history is sketchy, it appears that Apple Computer licensed
(or acquired) the software, and released it - rebranded as Apple II Desktop -
as the initial system software for the Apple IIgs before 16-bit GS/OS
replaced it. The rebranded version still functions on 8-bit Apples.

Overview: http://toastytech.com/guis/a2desk.html

Manual: [Apple IIgs System Disk User’s Guide (1986)](ftp://ftp.apple.asimov.net/pub/apple_II/documentation/misc/Apple%20IIgs%20System%20Disk%20Users%20Guide%20(1986).pdf) - Chapter 2 “The DeskTop”

A more thorough pieced-together history, details of versions, bug reports and feature requests: https://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Misc/mousedesk.info

Disks can be found at:
ftp://ftp.apple.asimov.net/pub/apple_II/images/masters/other_os/gui/

Other GUI environments exist for the 8-bit Apples, including GEOS (which includes
productivity applications) and Quark Catalyst. While A2.Desktop is more limited -
serving only as a file manager and application launcher - it is (subjectively)
more visually appealing and better integrated with ProDOS.

## Goal

The goal of this project is to disassemble/reverse-engineer the suite
with an eye towards understanding how it functions, and eventually fixing
bugs and adding functionality.

## Tools

The [cc65](http://cc65.github.io/cc65/) tool chain will be used; source files will
target the ca65 macro assembler. Cross-development on modern systems will be assumed.
(Sorry, Merlin purists! We still love you.)

## Code of Conduct

Discussions should be polite, respectful and inclusive, and focus on the code.
Harassment will not be tolerated. Keep comments constructive.
