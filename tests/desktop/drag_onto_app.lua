--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")

test.Step(
  "drag text file onto application SYS file",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    desktop.GrowWindowBy(-600,-200)
    desktop.MoveWindowBy(300, 100)
    desktop.Select("TTS.SYSTEM")
    local app_x, app_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.GrowWindowBy(-600,-200)
    desktop.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x+5, file_y+10)
        m.ButtonDown()
        m.MoveToApproximately(app_x+5, app_y)
        a2d.WaitForRepaint() -- during drag operation
        test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "TTS.SYSTEM", "app icon should be highlighted")
        m.ButtonUp()
    end)

    util.WaitFor(
      "TTS player",
      function()
        return apple2.GrabTextScreen():match("Software Automatic Mouth")
      end, {wait=1})

    -- cleanup
    a2dtest.WaitForSystemTask()
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()
    desktop.CloseAllWindows()
end)

test.Step(
  "drag text file onto application SYS file - list view",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.GrowWindowBy(-600,-200)
    desktop.MoveWindowBy(300, 100)
    desktop.Select("TTS.SYSTEM")
    local app_x, app_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.GrowWindowBy(-600,-200)
    desktop.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x+25, file_y+15)
        m.ButtonDown()
        m.MoveToApproximately(app_x, app_y)
        a2d.WaitForRepaint() -- during drag operation
        test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "TTS.SYSTEM", "app icon should be highlighted")
        m.ButtonUp()
    end)

    util.WaitFor(
      "TTS player",
      function()
        return apple2.GrabTextScreen():match("Software Automatic Mouth")
      end, {wait=1})

    -- cleanup
    a2dtest.WaitForSystemTask()
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()
    desktop.CloseAllWindows()
end)

test.Step(
  "drag text file onto non-application SYS file",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.GrowWindowBy(-600,-200)
    desktop.MoveWindowBy(300, 100)
    desktop.Select("PRODOS")
    local app_x, app_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.GrowWindowBy(-600,-200)
    desktop.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x+5, file_y+10)
        m.ButtonDown()
        m.MoveToApproximately(app_x+5, app_y)
        test.ExpectNotIMatch(a2dtest.OCRScreen({invert=true}), "PRODOS", "system icon should not be highlighted")
        m.ButtonUp()
    end)

    -- Error because it tries to copy READ.ME onto /A2.DESKTOP
    a2dtest.WaitForAlert({match="file already exists"})
    a2d.DialogCancel()

    -- cleanup
    desktop.CloseAllWindows()
end)

test.Step(
  "drag text file onto application SYS file that isn't an interpreter",
  function()
    desktop.RenamePath("/A2.DESKTOP/PRODOS", "PRODOS.SYSTEM")

    --[[
      Note that this test renames but then refreshes the window,
      so the icon is recreated from scratch.
    ]]
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.GrowWindowBy(-600,-200)
    desktop.MoveWindowBy(300, 100)
    desktop.Select("PRODOS.SYSTEM")
    local app_x, app_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.GrowWindowBy(-600,-200)
    desktop.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x+5, file_y+10)
        m.ButtonDown()
        m.MoveToApproximately(app_x+5, app_y)
        a2d.WaitForRepaint() -- during drag operation
        test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "PRODOS%.SYSTEM", "app icon should be highlighted")
        m.ButtonUp()
    end)

    a2dtest.WaitForAlert({match="Unsupported file type"})
    a2d.DialogCancel()

    -- cleanup
    desktop.RenamePath("/A2.DESKTOP/PRODOS.SYSTEM", "PRODOS")
    desktop.CloseAllWindows()
end)

test.Step(
  "drag text file onto SYS file after renaming with .SYSTEM suffix",
  function()
    --[[
      Note that this test renames but does not refresh the window;
      this exercises rename updating the properties of the icon.
    ]]
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.GrowWindowBy(-600,-200)
    desktop.MoveWindowBy(300, 100)
    desktop.Select("PRODOS")
    desktop.RenameSelection("PRODOS.SYSTEM")
    desktop.Select("PRODOS.SYSTEM")
    local app_x, app_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.GrowWindowBy(-600,-200)
    desktop.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x+5, file_y+10)
        m.ButtonDown()
        m.MoveToApproximately(app_x+5, app_y)
        a2d.WaitForRepaint() -- during drag operation
        test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "PRODOS%.SYSTEM", "app icon should be highlighted")
        m.ButtonUp()
    end)

    a2dtest.WaitForAlert({match="Unsupported file type"})
    a2d.DialogCancel()

    -- cleanup
    desktop.RenamePath("/A2.DESKTOP/PRODOS.SYSTEM", "PRODOS")
    desktop.CloseAllWindows()
end)

test.Step(
  "drag text file onto SYS file after renaming with .SYSTEM suffix - list view",
  function()
    --[[
      Note that this test renames but does not refresh the window;
      this exercises rename updating the properties of the icon.
    ]]
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.GrowWindowBy(-600,-200)
    desktop.MoveWindowBy(300, 100)
    desktop.Select("PRODOS")
    desktop.RenameSelection("PRODOS.SYSTEM")
    desktop.Select("PRODOS.SYSTEM")
    local app_x, app_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.GrowWindowBy(-600,-200)
    desktop.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x+25, file_y+15)
        m.ButtonDown()
        m.MoveToApproximately(app_x, app_y)
        a2d.WaitForRepaint() -- during drag operation
        test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "PRODOS%.SYSTEM", "app icon should be highlighted")
        m.ButtonUp()
    end)

    a2dtest.WaitForAlert({match="Unsupported file type"})
    a2d.DialogCancel()

    -- cleanup
    desktop.RenamePath("/A2.DESKTOP/PRODOS.SYSTEM", "PRODOS")
    desktop.CloseAllWindows()
end)

test.Step(
  "drag multiple files onto application SYS file",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    desktop.GrowWindowBy(-600,-200)
    desktop.MoveWindowBy(300, 100)
    desktop.Select("TTS.SYSTEM")
    local app_x, app_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/A2.DESKTOP", {keep_windows=true})
    desktop.GrowWindowBy(-600,-200)
    desktop.SelectAll()
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x+5, file_y+10)
        m.ButtonDown()
        m.MoveToApproximately(app_x+5, app_y)
        m.ButtonUp()
    end)

    a2dtest.WaitForAlert({match="Unsupported file type"})
    a2d.DialogCancel()

    -- cleanup
    desktop.CloseAllWindows()
end)
