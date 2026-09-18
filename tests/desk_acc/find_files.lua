--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop. Close all windows. Apple Menu > Find Files. Type
  `PRODOS` and click Search. Verify that all volumes are searched
  recursively.
]]
test.Step(
  "Search all volumes",
  function()
    desktop.CloseAllWindows()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("PRODOS")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    test.Snap("verify all volumes searched")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Open a volume window. Apple Menu > Find Files. Type
  `PRODOS` and click Search. Verify that only that volume's contents
  are searched recursively.
]]
test.Step(
  "Search open volume",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("PRODOS")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    test.Snap("verify only open volume searched")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder window. Apple
  Menu > Find Files. Type `PRODOS` and click Search. Verify that only
  that folder's contents are searched recursively.
]]
test.Step(
  "Search open volume",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("PRODOS")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    test.Snap("verify only open folder searched")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Open a window. Apple Menu > Find Files. Type `*` and
  click Search. Select a file in the list. Press Open-Apple+O. Verify
  that the Find Files window closes, that a window containing the file
  opens, and that the file icon is selected.
]]
test.Step(
  "OA+O on selection",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("CAL*")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    apple2.DownArrowKey() -- select first result
    a2d.OAShortcut("O")
    a2dtest.WaitForSystemTask()
    test.Snap("verify window opened and file selected")
end)

--[[
  Launch DeskTop. Open a window. Apple Menu > Find Files. Type `*` and
  click Search. Select a file in the list. Press Solid-Apple+O. Verify
  that the Find Files window closes, that a window containing the file
  opens, and that the file icon is selected.
]]
test.Step(
  "SA+O on selection",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("CAL*")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    apple2.DownArrowKey() -- select first result
    a2d.SAShortcut("O")
    a2dtest.WaitForSystemTask()
    test.Snap("verify window opened and file selected")
end)

--[[
  Launch DeskTop. Open a window. Apple Menu > Find Files. Type `*` and
  click Search. Double-click a file in the list. Verify that the Find
  Files window closes, that a window containing the file opens, and
  that the file icon is selected.

  Launch DeskTop. Open a volume window. Open a folder window. Activate
  the volume window. Apple Menu > Find Files. Type `*` and click
  Search. Double-click a file in the list that's inside the folder.
  Verify that the Find Files window closes, and that the file icon is
  selected.
]]
test.Step(
  "Double-click on selection in inactive window",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU", {leave_parent=true})
    desktop.CycleWindows() -- put volume in foreground
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("CAL*")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+23, dialog_y+2)
        m.DoubleClick()
    end)
    a2dtest.WaitForSystemTask()
    test.Snap("verify window activated and file selected")
end)


--[[
  Open `/TESTS/FIND.FILES`. Apple Menu > Find Files. Type `*` and
  click Search. Verify that the DA doesn't crash. (But the deeply
  nested `NOT.FOUND` file will not be found.)
]]
test.Step(
  "Deeply nested",
  function()
    desktop.OpenWindow("/TESTS/FIND.FILES")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("*")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    test.Snap("verify no crash")
    desktop.CloseWindow()
end)

--[[
  Rename `/TESTS` to `/ABCDEF123456789`. Open the volume. Apple Menu >
  Find Files. Type *. Verify that the DA doesn't crash.
]]
test.Step(
  "Long pathnames",
  function()
    desktop.RenamePath("/TESTS", "ABCDEF123456789")
    desktop.OpenWindow("/ABCDEF123456789")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("*")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    test.Snap("verify no crash")
    desktop.CloseWindow()
    desktop.RenamePath("/ABCDEF123456789", "TESTS")
end)

--[[
  Open `/TESTS/FOLDER/`. Apple Menu > Find Files. Type `*` and click
  Search. Press Down Arrow once. Type Return. Press Down Arrow again.
  Verify that only one entry in the list appears highlighted.
]]
test.Step(
  "Selection",
  function()
    desktop.OpenWindow("/TESTS/FOLDER")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.FIND_FILES)
    a2dtest.WaitForSystemTask()
    apple2.Type("*")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    apple2.DownArrowKey()
    apple2.ReturnKey()
    a2dtest.WaitForSystemTask()
    apple2.DownArrowKey()
    test.Snap("verify only one entry appears highlighted")
end)



