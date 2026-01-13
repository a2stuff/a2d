--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 dos33_floppy.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

-- Callback called with func to invoke menu item; pass false if
-- no volumes selected, true if volumes selected (affects menu item)
function FormatEraseTest(name, func)
  test.Variants(
    {
      name .. " - Format",
      name .. " - Erase",
    },
    function(idx)
      a2d.CloseAllWindows()
      a2d.ClearSelection()
      func(
        function(vol_selected)
          if vol_selected then
            a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK+idx-1)
          else
            a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2+idx-1)
          end
      end)
  end)
end

--[[
 Launch DeskTop. Run the command. Verify that the device order shown
 matches the order of volumes shown on the DeskTop (boot device first,
 etc). Select a device and proceed with the operation. Verify the
 correct device was formatted or erased.
]]
FormatEraseTest(
  "Correct device formatted",
  function(invoke)
    invoke(false)

    -- device selection
    apple2.DownArrowKey() -- S7D1
    apple2.DownArrowKey() -- S1D1
    a2d.DialogOK()

    -- name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- confirmation prompt
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- command
    emu.wait(5) -- slow
    a2dtest.ExpectAlertNotShowing()
    test.Snap("verify RAM Card was formatted")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.NAME", "volume should be selected")

    -- cleanup
    a2d.RenamePath("/NEW.NAME", "RAM1")
end)

------------------------------------------------------------
-- Duplicate Volume Names
------------------------------------------------------------

--[[
  Launch DeskTop. Run the command. For the new name, enter a volume
  name not currently in use. Verify that you are not prompted for a
  new name.
]]
FormatEraseTest(
  "Unique name entered",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)
    apple2.Type("UNIQUE.NAME")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    test.Snap("verify prompt confirms overwrite, not a duplicate name")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Run the command. For the new name, enter the name of
  a volume in a different slot/drive. Verify that an alert shows,
  indicating that the name is in use.
]]
FormatEraseTest(
  "Duplicate name entered",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)
    apple2.Type("A2.DESKTOP")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    test.Snap("verify prompt says the name is in use")
    a2d.DialogCancel()
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Run the command. For the new name, enter the name of
  the current disk in that slot/drive. Verify that you are not
  prompted for a new name.
]]
FormatEraseTest(
  "Same name entered",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)
    apple2.Type("RAM1")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    test.Snap("verify prompt confirms overwrite, not a duplicate name")
    a2d.DialogCancel()
end)

------------------------------------------------------------
-- Miscellaneous
------------------------------------------------------------

--[[
  Launch DeskTop. Run the command. Select a disk (other than the
  startup disk) and click OK. Enter a name, but place the caret in the
  middle of the name (e.g. "exam|ple"). Click OK. Verify that the full
  name is used.
]]
FormatEraseTest(
  "Caret in middle of name",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)
    apple2.Type("WHOLE.NAME.USED")
    for i = 1,7 do
      apple2.LeftArrowKey()
    end
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(5) -- slow

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "WHOLE.NAME.USED", "volume should be selected")

    -- cleanup
    a2d.RenamePath("/WHOLE.NAME.USED", "RAM1")
end)

--[[
  Launch DeskTop. Run the command. Select an empty drive. Let the
  operation continue until it fails. Verify that an error message is
  shown.
]]
FormatEraseTest(
  "Empty drive",
  function(invoke)
    invoke(false)

    -- device selection
    apple2.DownArrowKey() -- S7D1
    apple2.DownArrowKey() -- S1D1
    apple2.DownArrowKey() -- S6D1
    apple2.DownArrowKey() -- S6D2
    a2d.DialogOK()

    -- name
    apple2.Type("DUMMY.NAME")
    a2d.DialogOK()

    -- confirmation prompt
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- command
    a2dtest.WaitForAlert()
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Select a volume icon. Run the command. Enter a new
  name and click OK. Click OK to confirm the operation. Verify that
  the icon for the volume is updated with the new name.
]]
FormatEraseTest(
  "Icon updated - selection",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)

    -- name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- confirmation prompt
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- successful
    emu.wait(5) -- slow
    a2dtest.ExpectAlertNotShowing()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.NAME", "volume should be selected")

    -- cleanup
    a2d.RenamePath("/NEW.NAME", "RAM1")
end)

--[[
  Launch DeskTop. Run the command. Select a slot/drive containing an
  existing volume. Enter a new name and click OK. Click OK to confirm
  the operation. Verify that the icon for the volume is updated with
  the new name.
]]
FormatEraseTest(
  "Icon updated - no selection",
  function(invoke)
    invoke(false)

    -- device selection
    apple2.DownArrowKey() -- S7D1
    apple2.DownArrowKey() -- S1D1
    a2d.DialogOK()

    -- name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()
    a2d.WaitForRepaint()

    -- confirmation prompt
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- successful
    emu.wait(5) -- slow
    a2dtest.ExpectAlertNotShowing()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.NAME", "volume should be selected")

    -- cleanup
    a2d.RenamePath("/NEW.NAME", "RAM1")
end)

------------------------------------------------------------
-- Different Selections
------------------------------------------------------------

--[[
  Repeat the following case with: no selection, Trash selected,
  multiple volume icons selected, a single file selected, and multiple
  files selected:
]]

--[[
  Launch DeskTop. Set selection as specified. Run the command. Verify
  that the device selector is not skipped.
]]
FormatEraseTest(
  "No selection",
  function(invoke)
    invoke(false)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Set selection as specified. Run the command. Verify
  that the device selector is not skipped.
]]
FormatEraseTest(
  "Single file selected",
  function(invoke)
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    invoke(false)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Set selection as specified. Run the command. Verify
  that the device selector is not skipped.
]]
FormatEraseTest(
  "Trash selected",
  function(invoke)
    a2d.SelectPath("/Trash")
    invoke(false)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Set selection as specified. Run the command. Verify
  that the device selector is not skipped.
]]
FormatEraseTest(
  "Multiple volumes selected",
  function(invoke)
    a2d.SelectAll()
    invoke(true)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Select a volume icon. Run the command. Verify that
  the device selector is skipped. Enter a new volume name. Verify that
  the confirmation prompt refers to the selected volume
]]
FormatEraseTest(
  "Single volume selected",
  function(invoke)
    a2d.SelectPath("/A2.DESKTOP")
    invoke(true)
    test.Snap("verify prompted for new name")

    apple2.Type("NEW.NAME")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    test.Snap("verify prompt names selected volume")

    a2d.DialogCancel()
end)

------------------------------------------------------------
-- Button Staes
------------------------------------------------------------

--[[
  Launch DeskTop. Make sure no volume icon is selected. Run the
  command. Verify the OK button is disabled. Click on an item. Verify
  the OK button becomes enabled. Click on a blank option. Verify the
  OK button becomes disabled. Use the arrow keys to move selection.
  Verify that the OK button becomes enabled.

  Launch DeskTop. Make sure no volume icon is selected. Run the
  command. Click an item, then click OK. Verify that the device
  location is shown, and that the OK button becomes disabled. Enter
  text. Verify that the OK button is enabled. Delete all of the text.
  Verify that the OK button becomes disabled. Enter text. Verify that
  the OK button becomes enabled.
]]
FormatEraseTest(
  "OK button states - no initial selection",
  function(invoke)
    invoke(false)

    -- device selection
    test.Snap("verify OK button disabled")
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + 20, dialog_y + 40)
        m.Click()
    end)
    test.Snap("verify OK button enabled")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + 200, dialog_y + 40)
        m.Click()
    end)
    test.Snap("verify OK button disabled")
    apple2.DownArrowKey()
    test.Snap("verify OK button enabled")
    a2d.DialogOK()

    -- name
    test.Snap("verify device location shown")
    test.Snap("verify OK button disabled")
    apple2.Type("NEW.NAME")
    test.Snap("verify OK button enabled")
    a2d.ClearTextField()
    test.Snap("verify OK button disabled")
    apple2.Type("ANOTHER.NAME")
    test.Snap("verify OK button enabled")

    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Select a volume icon. Run the command. Verify that
  the OK button is disabled. Enter text. Verify that the device
  location is shown, and that the OK button is enabled. Delete all of
  the text. Verify that the OK button becomes disabled. Enter text.
  Verify that the OK button becomes enabled.
]]
FormatEraseTest(
  "OK button states - initial selection",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)

    -- name
    test.Snap("verify device location shown")
    test.Snap("verify OK button disabled")
    apple2.Type("NEW.NAME")
    test.Snap("verify OK button enabled")
    a2d.ClearTextField()
    test.Snap("verify OK button disabled")
    apple2.Type("ANOTHER.NAME")
    test.Snap("verify OK button enabled")

    a2d.DialogCancel()
end)
