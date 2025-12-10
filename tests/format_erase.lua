--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/dos33_floppy.dsk"

======================================== ENDCONFIG ]]--

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
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()

    -- error
    a2d.WaitForRestart()
    a2dtest.ExpectAlertNotShowing()
    test.Snap("verify RAM Card was formatted")
    a2d.RenamePath("/NEW.NAME", "RAM1")
end)

------------------------------------------------------------
-- Duplicate Volume Names
------------------------------------------------------------

FormatEraseTest(
  "Unique name entered",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)
    apple2.Type("UNIQUE.NAME")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    test.Snap("verify prompt confirms overwrite, not a duplicate name")
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Duplicate name entered",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)
    apple2.Type("A2.DESKTOP")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    test.Snap("verify prompt says the name is in use")
    a2d.DialogCancel()
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Same name entered",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)
    apple2.Type("RAM1")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    test.Snap("verify prompt confirms overwrite, not a duplicate name")
    a2d.DialogCancel()
end)

------------------------------------------------------------
-- Miscellaneous
------------------------------------------------------------

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
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
    a2d.WaitForRestart()
    test.Snap("Verify whole name was used")
    a2d.RenamePath("/WHOLE.NAME.USED", "RAM1")
end)

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
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()

    -- error
    a2d.WaitForRestart()
    a2dtest.ExpectAlertShowing()
    a2d.DialogCancel()
end)


FormatEraseTest(
  "Icon updated - selection",
  function(invoke)
    a2d.SelectPath("/RAM1")
    invoke(true)

    -- name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- confirmation prompt
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()

    -- successful
    a2d.WaitForRestart()
    a2dtest.ExpectAlertNotShowing()
    test.Snap("verify icon updated with NEW.NAME")
    a2d.RenamePath("/NEW.NAME", "RAM1")
end)

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
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()

    -- successful
    a2d.WaitForRestart()
    a2dtest.ExpectAlertNotShowing()
    test.Snap("verify icon updated with NEW.NAME")
    a2d.RenamePath("/NEW.NAME", "RAM1")
end)

------------------------------------------------------------
-- Different Selections
------------------------------------------------------------

FormatEraseTest(
  "No selection",
  function(invoke)
    invoke(false)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Single file selected",
  function(invoke)
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    invoke(false)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Trash selected",
  function(invoke)
    a2d.SelectPath("/Trash")
    invoke(false)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Multiple volumes selected",
  function(invoke)
    a2d.SelectAll()
    invoke(true)
    test.Snap("verify prompted for device")
    a2d.DialogCancel()
end)

FormatEraseTest(
  "Single volume selected",
  function(invoke)
    a2d.SelectPath("/A2.DESKTOP")
    invoke(true)
    test.Snap("verify prompted for new name")

    apple2.Type("NEW.NAME")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    test.Snap("verify prompt names selected volume")

    a2d.DialogCancel()
end)

------------------------------------------------------------
-- Button Staes
------------------------------------------------------------

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
