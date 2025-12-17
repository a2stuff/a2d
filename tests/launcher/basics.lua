a2d.ConfigureRepaintTime(0.25)

-- Speed up the rest of these tests
a2d.DeletePath("/A2.DESKTOP/SAMPLE.MEDIA")
emu.wait(10)

--[[
  Without starting DeskTop, launch `BASIC.SYSTEM`. Set a prefix (e.g.
  `PREFIX /RAM`). Invoke `DESKTOP.SYSTEM` with an absolute path (e.g.
  `-/A2.DESKTOP/DESKTOP.SYSTEM`). Verify that it starts correctly.
]]
test.Step(
  "launch with PREFIX set",
  function()
    a2d.Quit()
    apple2.BitsyInvokeFile("/EXTRAS")
    apple2.BitsyInvokeFile("BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("PREFIX /RAM")
    apple2.TypeLine("-/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()
    a2dtest.ExpectNotHanging()
end)

--[[
  Move DeskTop into a subdirectory of a volume (e.g. `/VOL/A2D`).
  Without starting DeskTop, launch `BASIC.SYSTEM`. Set a prefix to a
  parent directory of desktop (e.g. `PREFIX /VOL`). Invoke
  `DESKTOP.SYSTEM` with a relative path (e.g. `-A2D/DESKTOP.SYSTEM`).
  Verify that it starts correctly.
]]
test.Step(
  "Running with a prefix and relative path works",
  function()
    a2d.ToggleOptionCopyToRAMCard()
    a2d.CopyPath("/A2.DESKTOP", "/RAM1")
    emu.wait(30) -- slow copy
    a2d.Quit()
    apple2.WaitForBitsy()
    apple2.BitsySelectSlotDrive("S1,D1")
    apple2.BitsyInvokeFile("/A2.DESKTOP")
    apple2.BitsyInvokeFile("/EXTRAS")
    apple2.BitsyInvokeFile("BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("PREFIX /RAM1")
    apple2.TypeLine("-A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a system with a RAMCard, and ensure DeskTop is configured
  to copy to RAMCard on startup. Configure a shortcut to copy to
  RAMCard "at boot". Launch DeskTop. While the shortcut's files are
  copying to RAMCard, press Esc. Verify that when the DeskTop appears
  the Apple menu is not activated.
]]
test.Step(
  "Esc to abort gets cleared from input buffer",
  function()
    a2d.ToggleOptionCopyToRAMCard()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    a2d.CloseAllWindows()
    a2d.Reboot()
    util.WaitFor(
      "shortcut copying", function()
        return apple2.GrabTextScreen():upper():match("/EXTRAS/")
    end)
    apple2.EscapeKey()

    a2d.WaitForDesktopReady()
    test.Snap("verify menu not showing")

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch `BASIC.SYSTEM`. Save a file to `/RAM`. Invoke
  `DESKTOP.SYSTEM`. Verify that a warning is shown about `/RAM` not
  being empty. Press Esc. Verify that the ProDOS launcher is
  re-invoked. Verify that the file is still present in `/RAM`.
]]
test.Step(
  "/RAM not empty warning",
  function()
    a2d.Quit()
    apple2.WaitForBitsy()
    apple2.BitsyInvokeFile("/EXTRAS")
    apple2.BitsyInvokeFile("BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 PRINT \"HELLO WORLD\"")
    apple2.TypeLine("SAVE /RAM/HELLO")
    apple2.TypeLine("-/A2.DESKTOP/DESKTOP.SYSTEM")

    util.WaitFor(
      "warning", function()
        return apple2.GrabTextScreen():match("Esc to cancel")
    end)
    apple2.EscapeKey()

    apple2.WaitForBitsy()
    apple2.EscapeKey() -- pop up to root
    apple2.BitsyInvokeFile("/EXTRAS")
    apple2.BitsyInvokeFile("BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CAT /RAM")
    emu.wait(5)
    test.Expect(apple2.GrabTextScreen():match("HELLO"), "file should be present")
    apple2.TypeLine("DELETE /RAM/HELLO")
    apple2.TypeLine("-/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a system with a RAMCard, and ensure DeskTop is configured
  to copy to RAMCard on startup, but hasn't yet. Manually copy all
  DeskTop files to the RAMCard. Launch the copy of `DESKTOP.SYSTEM` on
  the RAMCard. Verify that it doesn't try to copy itself to that
  RAMCard.
]]
test.Step(
  "Manual copy to ramcard doesn't cause badness",
  function()
    a2d.ToggleOptionCopyToRAMCard()
    a2d.CopyPath("/A2.DESKTOP", "/RAM1")
    emu.wait(30) -- slow copy
    a2d.Quit()
    apple2.WaitForBitsy()
    apple2.BitsySelectSlotDrive("S1,D1")
    apple2.BitsyInvokeFile("/A2.DESKTOP")
    apple2.BitsyInvokeFile("DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    for i,icon in ipairs(a2d.GetSelectedIcons()) do
      test.ExpectNotEquals(icon.name:upper(), "DESKTOP", "should not be copied")
    end
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM1")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
