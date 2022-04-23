# Human Interface Guidelines

## Useful Resources

Note that these are for inspiration, not to be dutifully followed.

* [Apple II Human Interface Guidelines](https://archive.org/details/Apple2HIG1985), Draft, March 1985.
* [Apple Human Interface Guidelines](https://www.brutaldeluxe.fr/documentation/cortland/v1_06_HumanInterfaceGuidelines.pdf), Second Beta Draft, July 1986.
* [Human Interface Guidelines: the Apple Desktop Interface](https://archive.org/details/human-interface-guidelines), Final Draft, December 1986.
* [Human Interface Guidelines: The Apple Desktop Interface _For any Macintosh or Apple II computer_](https://archive.org/details/applehumaninterf00appl), 1987.

## Font

* Default font is 9 pixels tall, proportional spaced.

## Modal Dialogs

* Interior border
  * 2x4 pixels thick.
  * Offset 2x4 pixels from the window frame.
  * Drawn with solid black pen (not XOR).

## Buttons

* Default size for buttons with text labels is 100x11.
* Border is 1x1 pixels thick, drawn with XOR pen to give subtly rounded corners.
* Indicate keyboard shortcut support for default action with carriage return glyph ⏎.
* Indicate keyboard shortcut support for cancel action with Esc.
* Arrow buttons to increment or decrement values can be non-default height.

## Check Boxes and Radio Buttons

* Clicking on the text label should be equivalent to clicking on the control.

## Line Edit (Text Input) Controls

* Height is 12 pixels, counting the border.
* Border is 1x1 pixels thick, drawn with solid pen black pen (not XOR).
* Text baseline is 5x10 pixels from top left corner of border.
* Insertion point (a.k.a. text caret) is the full height of field, XOR-drawn between text glyphs. Moving the insertion point does not cause the string to change.
* The following keyboard shortcuts are supported:
  * Left Arrow - move IP one character left.
  * Right Arrow - move IP one character right.
  * Apple+Left Arrow - move IP to start of text.
  * Apple+Right Arrow - move IP to end of string.
  * Delete - erase character to the left of the IP.
  * Control+F - erase character to the right of the IP.
  * Control+X - erase all text

## List Box Controls

* The following keyboard shortcuts are supported:
  * Up/Down Arrow - move selection or scroll by one line.
  * Apple+Up/Down - scroll by one page.
  * Open-Apple+Solid-Apple+Up/Downshould - move selection or scroll to start/end.
* Item height is 10 pixels.
  * NOTE: Currently only 9 in most list boxes.

## Keyboard

* For Apple+letter combinations, Open Apple or Solid Apple should be equivalent.

* Apple+M is reserved for: move the active window with the keyboard.
* Apple+X is reserved for: scroll the active window with the keyboard.
* Apple+G is reserved for: grow the active window with the keyboard.

* In modal dialogs with only a single action, Return and Escape should both dismiss.
