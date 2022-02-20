# Human Interface Guidelines

## Useful Resources

Note that these are for inspiration, not to be dutifully followed.

* [Apple II Human Interface Guidelines](https://archive.org/details/Apple2HIG1985), Draft, 1985.
* [Human Interface Guidelines: The Apple Desktop Interface](https://archive.org/details/applehumaninterf00appl) _For any Macintosh or Apple II computer_, 1987.

## Font

* Default font is 9 pixels tall, proportional spaced.

## Modal Dialogs

* Interior border
  * 2x4 pixels thick.
  * Offset 2x4 pixels from the window frame.
  * Drawn with solid black pen (not XOR)

## Buttons

* Default size for buttons with text labels is 100x11.
* Border is 1x1 pixels thick, drawn with XOR pen to give subtly rounded corners.
* Indicate keyboard shortcut support for default action with carriage return glyph ⏎.
* Indicate keyboard shortcut support for cancel action with Esc.
* Arrow buttons to increment or decrement values can be non-default height.

## Check Boxes and Radio Buttons

* Clicking on the text label should be equivalent to clicking on the control.

## Text Input Boxes

* Height is 11 pixels.
* Text baseline is 5x10 pixels from top left corner of rect.

## Keyboard

* For Apple+letter combinations, Open Apple or Solid Apple should be equivalent.

* Apple+M is reserved for: move the active window with the keyboard.
* Apple+X is reserved for: scroll the active window with the keyboard.
* Apple+G is reserved for: grow the active window with the keyboard.

* In scrollable regions:
  * Apple+Up and Apple+Down should be treated as Page Up and Page Down.
  * Apple+Left and Apple+Right should be treated as Home and End.

* In modal dialogs with only a single action, Return and Escape should both dismiss.
