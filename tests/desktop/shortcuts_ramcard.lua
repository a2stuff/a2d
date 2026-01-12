--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)
a2d.ToggleOptionCopyToRAMCard()
a2d.Reboot()
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
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    while not apple2.GrabTextScreen():match("Esc to cancel") do
      emu.wait(0.25)
    end
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()

    a2d.CreateFolder("/RAM1/EXTRAS")
    a2dtest.ExpectAlertNotShowing()

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
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
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    emu.wait(1)
    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.CloseAllWindows()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    a2d.Reboot()
    while not apple2.GrabTextScreen():upper():match("EXTRAS") do
      emu.wait(0.25)
    end
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()

    a2d.OpenPath("/RAM1/EXTRAS")
    a2d.SelectAll()
    test.ExpectLessThan(#a2d.GetSelectedIcons(), count, "not all files should have been copied")
    a2d.CloseAllWindows()
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
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
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    emu.wait(1)
    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.CloseAllWindows()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.CloseAllWindows()

    a2d.OAShortcut("1")
    emu.wait(1)
    apple2.EscapeKey()
    a2d.WaitForRepaint()

    a2d.OpenPath("/RAM1/EXTRAS")
    a2d.SelectAll()
    test.ExpectLessThan(#a2d.GetSelectedIcons(), count, "not all files should have been copied")
    a2d.CloseAllWindows()

    a2d.DeletePath("/RAM1/EXTRAS")
    a2d.CloseAllWindows()

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.OpenPath("/RAM1/EXTRAS")
    a2d.SelectAll()
    test.ExpectLessThan(#a2d.GetSelectedIcons(), count, "not all files should have been copied")
    a2d.CloseAllWindows()

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
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
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.CloseAllWindows()

    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 100)

    a2dtest.DHRDarkness()

    a2d.OAShortcut("1", {no_wait=true})
    emu.wait(0.1)
    test.Snap("copy dialog should still be enumerating, no progress bar")
    apple2.EscapeKey()
    a2d.WaitForRepaint()

    test.Snap("verify RAM1 window did not refresh")

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
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
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.CloseAllWindows()

    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 100)

    a2dtest.DHRDarkness()

    a2d.OAShortcut("1", {no_wait=true})
    emu.wait(0.5)
    test.Snap("copy dialog should by copying, with progress bar")
    apple2.EscapeKey()
    emu.wait(5)

    test.Snap("verify RAM1 window did refresh")

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
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
    a2d.CreateFolder("/RAM1/TMP")
    a2d.CreateFolder("/RAM1/TMP/lower.UPPER.MiX")
    a2d.CopyPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", "/RAM1/TMP/LOWER.UPPER.MIX")
    a2d.AddShortcut("/RAM1/TMP/LOWER.UPPER.MIX/BASIC.SYSTEM", {copy="use"})

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "lower.UPPER.MiX", "case should match")

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
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

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", options)
    a2d.CloseAllWindows()

    if idx < 4 then
      a2d.OAShortcut("1")
    else
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
      apple2.RightArrowKey()
      a2d.DialogOK()
    end

    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

-- Flip option back off
a2d.ToggleOptionCopyToRAMCard()
a2d.Reboot()
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

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", options)
    a2d.CloseAllWindows()

    if idx < 4 then
      a2d.OAShortcut("1")
    else
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
      apple2.RightArrowKey()
      a2d.DialogOK()
    end

    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
