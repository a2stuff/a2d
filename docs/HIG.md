# Human Interface Guidelines

## Useful Resources

Note that these are for inspiration, not to be dutifully followed.

* [Apple II Human Interface Guidelines](https://archive.org/details/Apple2HIG1985), Draft, March 1985.
* [Apple Human Interface Guidelines](https://www.brutaldeluxe.fr/documentation/cortland/v1_06_HumanInterfaceGuidelines.pdf), Second Beta Draft, July 1986.
* [Human Interface Guidelines: the Apple Desktop Interface](https://archive.org/details/human-interface-guidelines), Final Draft, December 1986.
* [Human Interface Guidelines: The Apple Desktop Interface _For any Macintosh or Apple II computer_](https://archive.org/details/applehumaninterf00appl), 1987.
* [Macintosh Human Interface Guidelines](https://archive.org/details/macintoshhumanin0000unse), 1992.
* [Cortland (IIgs) Finder Specification](http://www.brutaldeluxe.fr/documentation/cortland/v2_08_FinderIconsAndDisksOhMy.pdf), July 1986.

## Font

* Default font is 9 pixels tall, proportional spaced.

## Modal Dialogs

* Interior border
  * 2x4 pixels thick.
  * Offset 2x4 pixels from the window frame.
  * Drawn with solid black pen (not XOR).

## Buttons

* Default size for buttons with text labels is 101px x 12px, counting the border.
  * This gives 1px padding above the text, 0px below (counting descenders).
* Border is 1x1 pixels thick, drawn with XOR pen to give subtly rounded corners.
* Horizontal text inset is 5px.
* Vertical text position is 10px (just above bottom border).
* Displaying keyboard shortcuts is controlled with a user preference.
  * If disabled:
    * Label should be aligned centered.
  * If enabled:
    * Label should be aligned left.
    * Keyboard shortcut should be aligned right.
    * Indicate default action with carriage return glyph ⏎.
    * Indicate cancel action with Esc.
* Arrow buttons to increment or decrement values can be non-default height.
* When clicking, the internal area is inverted, but not the border.

## Check Boxes and Radio Buttons

* Clicking on the text label should be equivalent to clicking on the control.
* Displaying keyboard shortcuts is controlled with a user preference.
  * If enabled, the shortcut should follow the text label in parentheses.

## Line Edit (Text Input) Controls

* Height is 12px, counting the border. Internal size is 10px
  * This gives 1px padding above the text, 0px below (counting descenders).
* Border is 1x1 pixels thick, drawn with solid pen black pen (not XOR).
* Horizontal text inset is 5px.
* Vertical text position is 10px (just above bottom border).
* Caret (a.k.a. insertion point) is the full height of field, XOR-drawn between text glyphs. Moving the caret does not cause the string to change.
* The following keyboard shortcuts are supported:
  * Left Arrow - move caret one character left.
  * Right Arrow - move caret one character right.
  * Apple+Left Arrow - move caret to start of text.
  * Apple+Right Arrow - move caret to end of string.
  * Delete - erase character to the left of the caret.
  * Control+F - erase character to the right of the caret.
  * Control+X - erase all text

## List Box Controls

* Item height is 10 pixels.
  * This gives 1px margin above the text, 0px below (counting descenders).
* The following keyboard shortcuts are supported:
  * Up/Down Arrow - move selection by one line.
  * Apple+Up/Down Arrow - scroll by one page.
  * Open-Apple+Solid-Apple+Up/Down Arrow - move selection to start/end.

## Choice Dialogs

* Item height is 10 pixels.
  * This gives 1px margin above the text, 0px below (counting descenders).
* Left/Right Arrow keys should wrap selection to the previous/next row.
* Up/Down Arrow keys should wrap selection to the previous/next column.

## Progress Bars

* Total height is 10 pixels, including a 1px border.
* Pattern is 75% light / 25% dark when empty, and fills with 75% dark / 25% light.

## Keyboard

* For Apple+letter combinations, Open-Apple or Solid-Apple should be equivalent.

* Apple+M is reserved for: move the active window with the keyboard.
* Apple+X is reserved for: scroll the active window with the keyboard.
* Apple+G is reserved for: grow the active window with the keyboard.

* In modal dialogs with only a single action, Return and Escape should both dismiss.
