--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG -flop3 disk_a.2mg"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":fdc:2:35dd"]

a2d.ConfigureRepaintTime(0.25)


--[[
  On a IIgs, launch DeskTop. Verify that it appears in monochrome.
  Quit DeskTop and launch another graphical ProDOS-8 program. Verify
  that it appears in color.
]]
test.Step(
  "Mono in DeskTop, color outside",
  function()
    test.Expect(apple2.IsMono(), "DeskTop should run in monochrome")
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 HGR2")
    apple2.TypeLine("20 FOR C = 0 to 7")
    apple2.TypeLine("30 HCOLOR= C")
    apple2.TypeLine("40 HPLOT C * 35, 0 to 279 - C * 35, 191")
    apple2.TypeLine("50 NEXT")
    apple2.TypeLine("RUN")
    emu.wait(5)
    test.Expect(apple2.IsColor(), "Apps should run in color")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
end)

--[[
  On an IIgs, go to Control Panel, check RGB Color. Verify that the
  display shows in color. Enter the IIgs control panel
  (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop
  remains in color.
]]
test.Step(
  "RGB Color vs. IIgs Control Panel",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- check RGB Color
    a2d.CloseWindow()
    test.Expect(apple2.IsColor(), "desktop should be in color")

    apple2.PressOA()
    apple2.PressControl()
    apple2.PressShift()
    apple2.EscapeKey()
    apple2.ReleaseShift()
    apple2.ReleaseControl()
    apple2.ReleaseOA()
    emu.wait(5)
    apple2.EscapeKey() -- to Quit
    apple2.ReturnKey()
    emu.wait(5)

    test.Expect(apple2.IsColor(), "desktop should be in color")
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- uncheck RGB Color
    a2d.CloseWindow()
end)

--[[
  On an IIgs, go to Control Panel, uncheck RGB Color. Verify that the
  display shows in monochrome. Enter the IIgs control panel
  (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop resets
  to monochrome.
]]
test.Step(
  "RGB Monochrome vs. IIgs Control Panel",
  function()
    test.Expect(apple2.IsMono(), "desktop should be in monochrome")

    apple2.PressOA()
    apple2.PressControl()
    apple2.PressShift()
    apple2.EscapeKey()
    apple2.ReleaseShift()
    apple2.ReleaseControl()
    apple2.ReleaseOA()
    emu.wait(5)
    apple2.EscapeKey() -- to Quit
    apple2.ReturnKey()
    emu.wait(5)

    test.Expect(apple2.IsMono(), "desktop should be in monochrome")
end)

--[[
  Configure a IIgs system with ejectable disks. Launch DeskTop. Select
  the ejectable volume. Special > Eject Disk. Verify that an alert is
  not shown.
]]
test.Step(
  "Ejecting disks",
  function()
    local drive = s5d1
    local image = drive.filename

    a2d.SelectPath("/A")
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_EJECT_DISK)
    emu.wait(5)
    a2dtest.ExpectAlertNotShowing()

    -- cleanup
    drive:load(image)
    a2d.CheckAllDrives()
end)

--[[
  Configure a IIgs via the system control panel to have a RAM disk:
  * Launch DeskTop. Verify that the `RAM5` volume is shown with a RAMDisk icon.
  * Configure DeskTop to copy to RAMCard on startup, and restart. Verify it is copied to `/RAM5`.
]]
test.Step(
  "IIgs RAM5 ramdisk",
  function()
    -- Enter Control Panel - Ctrl+Shift+OA+Esc
    apple2.PressOA()
    apple2.PressControl()
    apple2.PressShift()
    apple2.EscapeKey()
    apple2.ReleaseShift()
    apple2.ReleaseControl()
    apple2.ReleaseOA()
    emu.wait(1)

    -- Navigate to Control Panel / RAM Disk
    while not apple2.GrabInverseText():match("Control Panel") do
      apple2.UpArrowKey()
    end
    apple2.ReturnKey()

    while not apple2.GrabInverseText():match("RAM Disk") do
      apple2.UpArrowKey()
    end
    apple2.ReturnKey()

    test.ExpectMatch(apple2.GrabInverseText(), "Minimum RAM Disk Size:", "Minimum RAM Disk size should be focused")
    local TARGET_SIZE = 4096 -- K
    for i = 1, TARGET_SIZE/32 do
      apple2.RightArrowKey()
    end

    -- Save
    apple2.ReturnKey()

    -- Exit out of Control Panel
    apple2.EscapeKey() -- to Quit
    apple2.ReturnKey()
    apple2.EscapeKey() -- to Quit
    apple2.ReturnKey()

    -- Reboot so RAMDisk gets initialized
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()

    a2d.OpenPath("/RAM5")
    test.Snap("RAM5 has a RAMCard icon")

    a2d.ToggleOptionCopyToRAMCard()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.SelectPath("/RAM5/DESKTOP/DESKTOP.SYSTEM")
end)
