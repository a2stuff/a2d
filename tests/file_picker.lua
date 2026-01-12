--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl4 ramfactor -sl5 ramfactor -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/disk_b.2mg -flop2 res/disk_a.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]
local s6d2 = manager.machine.images[":sl6:superdrive:fdc:1:35hd"]

--[[

This covers:

* Shortcuts: File > Run a Program...
* DeskTop: File > Copy To...
* DeskTop: Shortcuts > Add a Shortcut...
* DeskTop: Shortcuts > Edit a Shortcut...

]]

a2d.AddShortcut("/A2.DESKTOP/READ.ME")

function FilePickerTest(
    name,
    options,
    activation_func,
    cleanup_func)

  function NavigateTo(path)
    apple2.ControlKey("D") -- Drives
    emu.wait(2)
    for segment in path:gmatch("([^/]+)") do
      apple2.PressOA()
      apple2.Type(segment)
      apple2.ReleaseOA()
      apple2.ControlKey("O") -- Open
      a2d.WaitForRepaint()
    end
  end

  --------------------------------------------------
  -- Typing
  --------------------------------------------------

  --[[
    Browse to a directory containing multiple files. Hold an Apple key
    and start typing a filename. Verify that a prefix-matching file or
    the subsequent file is selected, or the last file. For example, if
    the files "Alfa", "November" and "Whiskey" are present, typing "A"
    selects "Alfa", typing "AB" selects "Alfa", typing "AL" selects
    "Alfa", typing "ALFAA" selects "November", typing "B" selects
    "November", typing "Z" selects "Whiskey". Repeat including
    filenames with numbers and periods.
  ]]
  test.Step(
    name .. " - type-down order",
    function()
      activation_func()

      NavigateTo("/TESTS/TYPING.SELECT/ORDER.DIRS")

      apple2.PressOA()
      apple2.Type("A")
      apple2.ReleaseOA()
      test.Snap("verify ALFA selected")
      apple2.ControlKey("@") -- reset

      apple2.PressOA()
      apple2.Type("AB")
      apple2.ReleaseOA()
      test.Snap("verify ALFA selected")
      apple2.ControlKey("@") -- reset

      apple2.PressOA()
      apple2.Type("AL")
      apple2.ReleaseOA()
      test.Snap("verify ALFA selected")
      apple2.ControlKey("@") -- reset

      apple2.PressOA()
      apple2.Type("ALFAA")
      apple2.ReleaseOA()
      test.Snap("verify NOVEMBER selected")
      apple2.ControlKey("@") -- reset

      apple2.PressOA()
      apple2.Type("B")
      apple2.ReleaseOA()
      test.Snap("verify NOVEMBER selected")
      apple2.ControlKey("@") -- reset

      apple2.PressOA()
      apple2.Type("Z")
      apple2.ReleaseOA()
      test.Snap("verify WHISKEY selected")
      apple2.ControlKey("@") -- reset

      cleanup_func()
  end)

  --[[
    Browse to a directory containing multiple files. Hold an Apple key
    and start typing a filename. Move the mouse, or press a key
    without holding Apple. Hold an Apple key and start typing another
    filename. Verify that the matching is reset.
  ]]
  test.Step(
    name .. " - type-down reset",
    function()
      activation_func()

      NavigateTo("/TESTS/TYPING.SELECT/ORDER.DIRS")

      apple2.PressOA()
      apple2.Type("B")
      apple2.ReleaseOA()
      test.Snap("verify NOVEMBER selected")

      a2d.InMouseKeysMode(function(m)
          m.MoveByApproximately(10, 10)
          m.MoveByApproximately(-10, -10)
      end)

      apple2.PressOA()
      apple2.Type("A")
      apple2.ReleaseOA()
      test.Snap("verify ALFA selected")

      cleanup_func()
  end)

  --[[
    Browse to a directory containing no files. Hold an Apple key and
    start typing a filename. Verify nothing happens.
  ]]
  test.Step(
    name .. " - type-down in empty directory",
    function()
      activation_func()

      NavigateTo("/RAM4")

      apple2.PressOA()
      apple2.Type("ALFA")
      apple2.ReleaseOA()
      test.Snap("verify nothing happened")

      cleanup_func()
  end)


  --[[
    Browse to a directory containing one or more files with starting
    with mixed case (AppleWorks or GS/OS). Verify the filenames appear
    with correct case.

    Browse to a directory containing one or more files starting with
    lowercase letters (AppleWorks or GS/OS). Verify the files appear
    with correct names. Press Apple+letter. Verify that the first file
    starting with that letter is selected.
  ]]
  if not options.dirs_only then
    test.Step(
      name .. " - type-down with lowercase names",
      function()
        activation_func()

        NavigateTo("/TESTS/PROPERTIES/GS.OS.NAMES")

        test.Snap("verify filenames have correct cases")

        apple2.PressOA()
        apple2.Type("M")
        apple2.ReleaseOA()
        test.Snap("verify 'mIxEd.CaSe' selected")
        apple2.ControlKey("@") -- reset

        apple2.PressOA()
        apple2.Type("L")
        apple2.ReleaseOA()
        test.Snap("verify 'lower' selected")
        apple2.ControlKey("@") -- reset

        apple2.PressOA()
        apple2.Type("u")
        apple2.ReleaseOA()
        test.Snap("verify 'UPPER' selected")
        apple2.ControlKey("@") -- reset

        cleanup_func()
    end)
  end

  --------------------------------------------------
  -- Scrollbars
  --------------------------------------------------

  --[[
    Browse to a directory containing 7 files. Verify that the
    scrollbar is inactive.

    Browse to a directory containing 8 files. Verify that the
    scrollbar is active. Press Apple+Down. Verify that the scrollbar
    thumb moves to the bottom of the track.
  ]]
  test.Step(
    name .. " - scrollbars",
    function()
      activation_func()

      NavigateTo("/TESTS/PROPERTIES/SEVEN")
      local _, vopt = a2dtest.GetFrontWindowScrollOptions()
      test.Expect((vopt & mgtk.scroll.option_active) == 0, "scrollbar should be inactive")

      NavigateTo("/TESTS/PROPERTIES/EIGHT")
      local _, vopt = a2dtest.GetFrontWindowScrollOptions()
      test.Expect((vopt & mgtk.scroll.option_active) ~= 0, "scrollbar should be active")

      cleanup_func()
  end)

  --------------------------------------------------
  -- Display
  --------------------------------------------------

  --[[
    Browse to `/TESTS/SORTING`. Verify that "A" sorts before "A.B".
  ]]
  if not options.dirs_only then
    test.Step(
      name .. " - sort order",
      function()
        activation_func()

        NavigateTo("/TESTS/SORTING")
        test.Snap("verify that A sorts before A.B")

        cleanup_func()
    end)
  end

  --[[
    Use DeskTop's Options Control Panel and enable "Show invisible
    files". Use the file picker to browse to
    `/TESTS/PROPERTIES/VISIBLE.HIDDEN`. Verify that `INVISIBLE`
    appears in the list. Disable the option. Use the file picker
    again, and verify that `INVISIBLE` does not appear in the list.
  ]]
  if not options.dirs_only then
    test.Step(
      name .. " - invisible files",
      function()
        a2d.ToggleOptionShowInvisible() -- enable

        activation_func()
        NavigateTo("/TESTS/PROPERTIES/VISIBLE.HIDDEN")
        test.Snap("verify INVISIBLE is in list")
        cleanup_func()

        a2d.ToggleOptionShowInvisible() -- disable

        activation_func()
        NavigateTo("/TESTS/PROPERTIES/VISIBLE.HIDDEN")
        test.Snap("verify INVISIBLE is not in list")
        cleanup_func()
    end)
  end

  --------------------------------------------------
  -- Drives
  --------------------------------------------------

  --[[
    Click the Drives button. Verify that on-line volumes are listed in
    alphabetical order.

    Click the Drives button. Manually eject a disk. Click the Drives
    button again. Verify that the ejected disk is removed from the
    list.
  ]]
  test.Step(
    name .. " - disks",
    function()
      activation_func()

      apple2.ControlKey("D")
      emu.wait(2)
      test.Snap("verify drives are in alphabetical order")

      local image = s6d2.filename
      s6d2:unload()

      apple2.ControlKey("D")
      emu.wait(2)
      test.Snap("verify A is no longer present")

      s6d2:load(image)

      apple2.ControlKey("D")
      emu.wait(2)
      test.Snap("verify A is back")

      cleanup_func()
  end)

  --------------------------------------------------
  -- Button states
  --------------------------------------------------

  --[[
    Select a folder in the list box. Verify that the Open button is
    not dimmed.

    Select a non-folder in the list box. Verify that the Open button
    is dimmed.

    Navigate to the root directory of a disk. Verify that the Close
    button is not dimmed.

    Open a folder. Verify that the Close button is not dimmed, that
    there is no selection, and that Open is dimmed. Hit Close until at
    the root. Verify that Close is dimmed.

    Click the Drives button. Verify that the Close button is dimmed.

    Click the Drives button. Verify that the OK button is dimmed.

    Verify that dimmed buttons don't respond to clicks.

    Verify that dimmed buttons don't respond to keyboard shortcuts
    (Return for OK, Control+O for Open, Control+C for Close).

    For DeskTop's File > Copy To... file picker:
    * Open a volume or folder. Clear selection. Verify that the OK
      button is not dimmed.
    * Click the Drives button. Verify that the OK button is dimmed.
    * Click the Drives button. Select a volume icon. Verify that the
      OK button is not dimmed. Click OK. Verify that the file is
      copied into the selected volume's root directory.

    For DeskTop's Shortcut > Edit a Shortcut... file picker:
    * Clear selection. Verify that the OK button is dimmed.
    * Click the Drives button. Verify that the OK button is dimmed.
    * Click the Drives button. Select a volume. Verify that the OK
      button is not dimmed.
    * Select a folder. Verify that the OK button is not dimmed.

    For Shortcuts's File > Run a Program... file picker:
    * Navigate to an empty volume. Verify that OK is disabled.
    * Clear selection. Verify that the OK button is dimmed.
    * Click the Drives button. Select a volume. Verify that the OK
      button is dimmed.
    * Select a folder. Verify that the OK button is dimmed.
  ]]

  test.Step(
    name .. " - button states",
    function()
      activation_func()

      NavigateTo("/A2.DESKTOP")
      test.Snap("verify Open button is dimmed")

      apple2.PressOA()
      apple2.Type("EXTRAS")
      apple2.ReleaseOA()
      a2d.WaitForRepaint()
      test.Snap("verify Open button is not dimmed")

      if not options.dirs_only then
        apple2.PressOA()
        apple2.Type("@") -- reset
        apple2.Type("READ.ME")
        apple2.ReleaseOA()
        a2d.WaitForRepaint()
        test.Snap("verify Open button is dimmed")
      end

      NavigateTo("/A2.DESKTOP")
      test.Snap("verify Close button is not dimmed")

      NavigateTo("/A2.DESKTOP/EXTRAS")
      test.Snap("verify Close button is not dimmed")
      test.Snap("verify Open button is dimmed")
      apple2.ControlKey("O") -- Open
      test.Snap("verify nothing happened")
      test.Snap("verify no selection")

      apple2.ControlKey("D") -- Drives
      emu.wait(2)
      test.Snap("verify Close button is dimmed")
      apple2.ControlKey("C") -- Close
      test.Snap("verify nothing happened")
      test.Snap("verify OK button is dimmed")
      apple2.ReturnKey() -- OK
      test.Snap("verify nothing happened")

      apple2.DownArrowKey()
      a2d.WaitForRepaint()
      if options.vol_ok then
        test.Snap("verify OK button is not dimmed")
      else
        test.Snap("verify OK button is dimmed")
      end

      NavigateTo("/A2.DESKTOP")
      if options.no_sel_ok then
        test.Snap("verify OK button is not dimmed")
      else
        test.Snap("verify OK button is dimmed")
      end
      apple2.PressOA()
      apple2.Type("EXTRAS")
      apple2.ReleaseOA()
      a2d.WaitForRepaint()
      if options.folder_ok then
        test.Snap("verify OK button is not dimmed")
      else
        test.Snap("verify OK button is dimmed")
      end

      NavigateTo("/RAM1")
      if options.no_sel_ok then
        test.Snap("verify OK button is not dimmed")
      else
        test.Snap("verify OK button is dimmed")
      end

      -- TODO: Test clicks on OK, Open, Close

      cleanup_func()
  end)

  --------------------------------------------------
  -- Double Clicks
  --------------------------------------------------

  --[[
    Move the mouse cursor over a folder in the list, and click to
    select it. Move the mouse cursor away from the click location but
    over the same item. Double-click. Verify that the folder opens
    with only the two clicks.

    Move the mouse cursor over a folder in the list that is not
    selected. Double-click. Verify that the folder opens with only the
    two clicks.
  ]]

  test.Step(
    name .. " - double-clicks",
    function()
      activation_func()

      NavigateTo("/TESTS/PROPERTIES/SEVEN")
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x + w / 2, y + 5)
          m.Click()
          m.MoveByApproximately(20, 0)
          m.DoubleClick()
      end)
      emu.wait(5)
      test.Snap("verify in F1")

      NavigateTo("/TESTS/PROPERTIES/SEVEN")
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()
      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x + w / 2, y + 5)
          m.DoubleClick()
      end)
      emu.wait(5)
      test.Snap("verify in F1")

      cleanup_func()
  end)

end

FilePickerTest(
  "Add a Shortcut",
  {
    vol_ok = true,
    folder_ok = true,
  },
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
  end,
  function()
    a2d.DialogCancel()
  end
)

FilePickerTest(
  "Copy To",
  {
    dirs_only=true,
    vol_ok = true,
    folder_ok = true,
    no_sel_ok = true,
  },
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
  end,
  function()
    a2d.DialogCancel()
  end
)

FilePickerTest(
  "Shortcuts - Run a Program",
  {
  },
  function()
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2dtest.SetBankOffsetForSelectorModule()
    a2d.WaitForDesktopReady()

    a2d.OAShortcut("R")
  end,
  function()
    a2d.DialogCancel()

    apple2.Type("D")
    a2dtest.SetBankOffsetForDeskTopModule()
    a2d.WaitForDesktopReady()
    a2d.ToggleOptionShowShortcutsOnStartup()
  end
)

--[[
  For DeskTop's Shortcut > Edit a Shortcut... file picker:

  Create a shortcut not on the startup disk. Edit the shortcut. Verify
  that the file picker shows the shortcut target volume and file
  selected.
]]
test.Step(
  "Edit a Shortcut - navigates to shorcut target",
  function()
    a2d.AddShortcut("/TESTS/FILE.TYPES/ROOM.A2FC")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify volume is TESTS")
    test.Snap("verify folder is FILE.TYPES")
    test.Snap("verify selection is ROOM.A2FC")
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
end)

--[[
  For DeskTop's Shortcut > Edit a Shortcut... file picker:

  Create a shortcut on a removable volume. Eject the volume. Edit the
  shortcut. Verify that the file picker initializes to the drives
  list, and does not crash or show corrupted results.
]]
test.Step(
  "Edit a Shortcut - ejected volume",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/A")
    a2d.AddShortcut("/A/READ.ME")

    local image = s6d2.filename
    s6d2:unload()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify dialog shows drives list")
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)

    s6d2:load(image)
end)

--[[
  The Directory and Disk names (above the list box and buttons
  respectively) should be empty when the path is empty.
]]
test.Step(
  "Dir and Disk names when path is empty",
  function()
    -- Navigated to empty path
    a2d.AddShortcut("/RAM1")

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.UpArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify showing drives list and dir/disk names empty")
    apple2.PressOA()
    apple2.Type("A2.DESKTOP")
    apple2.ReleaseOA()
    apple2.ControlKey("O") -- open
    emu.wait(5)
    apple2.ControlKey("D") -- drives
    emu.wait(5)
    test.Snap("verify showing drives list and dir/disk names empty")

    -- cleanup
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.UpArrowKey()
    a2d.DialogOK()
    emu.wait(5)
end)


--[[
* Launch DeskTop. Special > Format Disk.... Select a drive with no disk, let the format fail and cancel. File > Copy To.... Verify that the file list is populated.
]]

-- This is all covered in tests/line_edit.lua
--[[
* In Shortcuts > Add/Edit a Shortcut... name field:
  * Type a non-path, non-control character. Verify that it is accepted.
  * Type a control character that is not an alias for an Arrow key (so not Control+H, J, K, or U), editing key (so not Control+F, Control+X), Return (Control+M), Escape (Control+[), or a button shortcut (so not Control+D, O, or C) e.g. Control+Q. Verify that it is ignored.
  * Move the cursor over the text field. Verify that the cursor changes to an I-beam.
  * Move the cursor off the text field. Verify that the cursor changes to a pointer.
]]

-- This is all covered in tests/desktop/shortcuts.lua
--[[
  * Launch DeskTop. Shortcuts > Add a Shortcut.... Press Apple+1 through Apple+5. Verify that the radio buttons on the right are selected.
]]

