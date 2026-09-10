# API Overview

DeskTop is an application built on top of ProDOS, MGTK, and several custom libraries. Enhancing DeskTop involves understanding these libraries. This document serves as a roadmap.


## ProDOS

ProDOS is an operating system for the Apple II created by Apple Computer. It is thoroughly documented in the [ProDOS 8 Technical Reference Manual](https://prodos8.com/docs/techref/). Nearly all file and disk operations are done using ProDOS. The exceptions are (1) formatting Disk II devices and (2) direct SmartPort access to identify device types and eject disks.

The primary ProDOS API is the "MLI" (machine language interface) and is invoked by a JSR to a known entry point address, with a command byte and pointer to parameter block following the JSR. ProDOS is external to DeskTop.

Commands include housekeeping (create, destroy, rename, get/set info), filing (reading/writing), and direct block read/write access.


## MouseGraphics ToolKit (MGTK)

[MGTK Documentation](../src/mgtk/MGTK.md)

This is a complex API library written by Apple circa 1985. It consists of two layers:

* Graphics Primitives - screen management, lines, rects, polys, text, patterns, pens
* Mouse Graphics - windows, menus, events, cursors

The Mouse Graphics layer is implemented on top of the Graphics Primitives layer. All graphics and windowing operations in DeskTop are implemented using this library.

Mac/IIgs Developers: You can think of the Graphics Primitives layer as analogous to the "QuickDraw" toolset, and you can think of the Mouse Graphics layer as analogous to the "Dialog Manager", "Event Manager", and "Menu Manager" toolsets.

The interface is similar to the ProDOS MLI, with JSR to a known address, with a command byte and pointer to parameter block following the JSR. The MGTK library is built into DeskTop, the entry point address can move but is fixed at build-time.


## Icon ToolKit (IconTK)

[IconTK Documentation](../src/toolkits/IconTK.md)

This library was written specifically for DeskTop, but is isolated from the rest of the application logic, depending only on MGTK. It is used to manage, draw, and perform actions like drag and drop on file/volume icons.

The interface is similar to the ProDOS MLI, with JSR to a known address, with a command byte and pointer to parameter block following the JSR. The library is built into DeskTop, the entry point address can move but is fixed at build-time.


## Button ToolKit (BTK)

[BTK Documentation](../src/toolkits/BTK.md)

This library was written specifically for DeskTop, but is isolated from the rest of the application logic, depending only on MGTK. It provides operations to draw and interact with button controls, including push buttons, radio buttons, and check boxes.

Mac/IIgs Developers: You can think of this as analogous to the "Control Manager" toolset.

The interface is similar to the ProDOS MLI, with JSR to a known address, with a command byte and pointer to parameter block following the JSR. The library is built into DeskTop, the entry point address can move but is fixed at build-time.


## LineEdit ToolKit (LETK)

[LETK Documentation](../src/toolkits/LETK.md)

This library was written specifically for DeskTop, but is isolated from the rest of the application logic, depending only on MGTK. It provides operations to draw and interact with "line edit" (text entry) controls.

Mac/IIgs Developers: You can think of this as analogous to the "Line Edit" toolset.

The interface is similar to the ProDOS MLI, with JSR to a known address, with a command byte and pointer to parameter block following the JSR. The library is built into DeskTop, the entry point address can move but is fixed at build-time.


## ListBox ToolKit (LBTK)

[LBTK Documentation](../src/toolkits/LBTK.md)

This library was written specifically for DeskTop, but is isolated from the rest of the application logic, depending only on MGTK. It provides operations to draw and interact with list box controls.

Mac/IIgs Developers: You can think of this as analogous to the "List Manager" toolset.

The interface is similar to the ProDOS MLI, with JSR to a known address, with a command byte and pointer to parameter block following the JSR. The library is built into DeskTop, the entry point address can move but is fixed at build-time.

## Option Picker ToolKit (OPTK)

[OPTK Documentation](../src/toolkits/OPTK.md)

This library was written specifically for DeskTop, but is isolated from the rest of the application logic, depending only on MGTK. It provides operations to draw and interact with a controls that present a 2-D grid of options.

The interface is similar to the ProDOS MLI, with JSR to a known address, with a command byte and pointer to parameter block following the JSR. The library is built into DeskTop, the entry point address can move but is fixed at build-time.


## Libraries

A handful of re-usable libraries that don't have fancy MLI-style interfaces are provided in the [`lib`](../src/lib) directory. Ones that are important to understand for building DeskTop and other applications are:

* [Alert Dialog](../src/lib/alert_dialog.s) - simple error and prompt dialogs
* [File Dialog](../src/lib/file_dialog.s) - file open / save
* [Get Next Event](../src/lib/get_next_event.s) - helper to detect no-ops and moves
* [Detect Double Click](../src/lib/doubleclick.s) - helper to detect double clicks
* [Read/Write Settings](../src/lib/readwrite_settings.s) - access/modify options


## Desk Accessories

* [Desk Accessory APIs](../src/desk_acc/API.md)
* [DeskTop APIs](../src/desktop/APIs.md)

Desk Accessories are small applications that run within DeskTop. They are constructed using the above APIs/libraries, and integrate into the hosting application using APIs specific to DeskTop - provided as jump table entries.
