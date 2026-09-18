--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

desktop.ToggleOptionCopyToRAMCard()
desktop.Reboot()
a2d.WaitForDesktopReady()

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`.
  While DeskTop is being copied to RAMCard, press Escape to cancel.
  Verify that none of the program's files were copied to the RAMCard.
  Once DeskTop starts, invoke the shortcut. Verify that the program
  starts correctly.
]]
test.Step(
  "aborted copy of Desktop to RAMCard does not leave shortcut files copied",
  function()
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    desktop.EraseVolume("RAM1")
    desktop.Reboot({no_wait=true})
    util.WaitFor(
      "Copying to RAMCard on boot", function()
        return apple2.GrabTextScreen():match("Esc to cancel")
      end, {wait=0.25})
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()

    desktop.CreateFolder("/RAM1/EXTRAS")
    a2dtest.ExpectAlertNotShowing()

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`.
  While the program's files are being copied to RAMCard, press Escape
  to cancel. Verify that not all of the files were copied to the
  RAMCard. Once DeskTop starts, invoke the shortcut. Verify that the
  program starts correctly.
]]
test.Step(
  "aborted copy of shortcut on boot does not prevent it from running",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    a2dtest.WaitForSystemTask()
    desktop.SelectAll()
    local count = #desktop.GetSelectedIcons()
    desktop.CloseAllWindows()

    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    desktop.Reboot({no_wait=true})
    util.WaitFor(
      "EXTRAS to be copying", function()
        return apple2.GrabTextScreen():upper():match("EXTRAS")
      end, {wait=0.25})
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()

    desktop.OpenWindow("/RAM1/EXTRAS")
    desktop.SelectAll()
    test.ExpectLessThan(#desktop.GetSelectedIcons(), count, "not all files should have been copied")
    desktop.CloseAllWindows()
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at first use". Invoke the shortcut. While the
  program's files are being copied to RAMCard, press Escape to cancel.
  Verify that not all of the files were copied to the RAMCard. Delete
  the folder from the RAMCard. Invoke the shortcut again. Verify that
  the files are copied to the RAMCard and that the program starts
  correctly.
]]
test.Step(
  "aborted copy of shortcut on use does not prevent it from running",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    a2dtest.WaitForSystemTask()
    desktop.SelectAll()
    local count = #desktop.GetSelectedIcons()
    desktop.CloseAllWindows()

    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    desktop.CloseAllWindows()

    a2d.OAShortcut("1")
    util.WaitFor(
      "mid-copying", function()
        return a2dtest.OCRFrontWindowContent():match("Files remaining")
    end)
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1/EXTRAS")
    desktop.SelectAll()
    test.ExpectLessThan(#desktop.GetSelectedIcons(), count, "not all files should have been copied")
    desktop.CloseAllWindows()

    desktop.DeletePath("/RAM1/EXTRAS")
    desktop.CloseAllWindows()

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.OpenWindow("/RAM1/EXTRAS")
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "all files should have been copied")
    desktop.CloseAllWindows()

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at first use". Open a window for the RAMCard
  volume. Invoke the shortcut. During the initial count of the
  program's files are being counted, press Escape to cancel. Verify
  that the volume window contents do not not refresh.
]]
test.Step(
  "shortcut copy aborted during enumeration doesn't refresh RAMCard windows",
  function()
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    desktop.CloseAllWindows()

    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(0, 100)

    a2dtest.DHRDarkness()

    a2d.OAShortcut("1", {no_wait=true})
    util.WaitFor(
      "copying", function()
        return a2dtest.OCRFrontWindowContent():match("Copying")
    end)
    test.ExpectNotMatch(a2dtest.OCRScreen(), "Files remaining:", "should still be enumerating")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()

    test.Snap("verify RAM1 window did not refresh")

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at first use". Open a window for the RAMCard
  volume. Invoke the shortcut. After the initial count of the files is
  complete and the actual copy has started, press Escape to cancel.
  Verify that the volume window contents do refresh.
]]
test.Step(
  "shortcut copy aborted after enumeration does refresh RAMCard windows",
  function()
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    desktop.CloseAllWindows()

    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(0, 100)

    a2dtest.DHRDarkness()

    a2d.OAShortcut("1", {no_wait=true})
    util.WaitFor(
      "copying to start", function()
        return a2dtest.OCRFrontWindowContent():match("Files remaining")
    end)
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()

    test.Snap("verify RAM1 window did refresh")

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure DeskTop to copy to RAMCard on start. Add a shortcut for an
  application file that can be launched from DeskTop in the root of a
  disk named with mixed case using GS/OS, and configure it to copy to
  RAMCard "on first use". Invoke the shortcut. Exit back to DeskTop.
  Verify that the folder name on the RAMCard has the same mixed case
  as the original disk.
]]
test.Step(
  "Folder in RAMCard should match original GS/OS case",
  function()
    desktop.CreateFolder("/RAM1/TMP")
    desktop.CreateFolder("/RAM1/TMP/lower.UPPER.MiX")
    desktop.CopyPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", "/RAM1/TMP/LOWER.UPPER.MIX")
    desktop.AddShortcut("/RAM1/TMP/LOWER.UPPER.MIX/BASIC.SYSTEM", {copy="use"})

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "lower.UPPER.MiX", "case should match")

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
* Repeat the following:
  * For these permutations:
    * Shortcut in (1) menu and list, and (2) list only.
    * Shortcut set to copy to RAMCard (1) on boot, (2) on first use, (3) never.
    * DeskTop set to (1) Copy to RAMCard, (2) not copying to RAMCard.
  * Launch DeskTop. Configure the shortcut. Restart. Launch DeskTop. Run the shortcut. Verify that it executes correctly.
]]

-- Implicitly here we're set to copy to RAMCard
test.Variants(
  {
    {"permutations: copy enabled - menu and list - on boot", false, "boot"},
    {"permutations: copy enabled - menu and list - on use", false, "use"},
    {"permutations: copy enabled - menu and list - never", false, nil},
    {"permutations: copy enabled - list only - on boot", true, "boot"},
    {"permutations: copy enabled - list only - on use", true, "use"},
    {"permutations: copy enabled - list only - never", true, nil},
  },
  function(idx, name, list_only, copy)
    local options = {list_only=list_only, copy=copy}

    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", options)
    desktop.CloseAllWindows()

    if idx < 4 then
      a2d.OAShortcut("1")
    else
      a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, desktop.SHORTCUTS_RUN_A_SHORTCUT)
      a2dtest.WaitForSystemTask()
      apple2.RightArrowKey()
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
    end

    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

-- Flip option back off
desktop.ToggleOptionCopyToRAMCard()
desktop.Reboot()
a2d.WaitForDesktopReady()

test.Variants(
  {
    {"permutations: copy disabled - menu and list - on boot", false, "boot"},
    {"permutations: copy disabled - menu and list - on use", false, "use"},
    {"permutations: copy disabled - menu and list - never", false, nil},
    {"permutations: copy disabled - list only - on boot", true, "boot"},
    {"permutations: copy disabled - list only - on use", true, "use"},
    {"permutations: copy disabled - list only - never", true, nil},
  },
  function(idx, name, list_only, copy)
    local options = {list_only=list_only, copy=copy}

    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", options)
    desktop.CloseAllWindows()

    if idx < 4 then
      a2d.OAShortcut("1")
    else
      a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, desktop.SHORTCUTS_RUN_A_SHORTCUT)
      a2dtest.WaitForSystemTask()
      apple2.RightArrowKey()
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
    end

    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.EraseVolume("RAM1")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
