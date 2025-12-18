--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

--[[============================================================

  Miscellaneous investigations

  ============================================================]]

a2d.ConfigureRepaintTime(0.25)


test.Step(
  "clicking title bar in inactive window treated as drag",
  function()
    a2d.AddShortcut("/A2.DESKTOP")
    function OpenVolumeWindow() a2d.OAShortcut("1") end

    a2d.OpenPath("/RAM1")
    local ram_id = a2dtest.GetFrontWindowID()

    OpenVolumeWindow()
    a2d.MoveWindowBy(0, 100)

    local x,y = a2dtest.GetWindowDragCoords(ram_id)
    -- click title bar of inactive window

    a2d.EnterMouseKeysMode()
    a2d.MouseKeysMoveToApproximately(x, y)
    -- This is being interpreted as a drag.
    -- Can't repro manually as it is too timing-sensitive.
    a2d.MouseKeysClick()
    a2d.ExitMouseKeysMode()
    emu.wait(10/60) -- This is from the `a2d.InMouseKeysMode` wrapper

    a2d.EnterMouseKeysMode()
    a2d.MouseKeysMoveByApproximately(100, 100)
    a2d.ExitMouseKeysMode()
    emu.wait(10/60) -- This is from the `a2d.InMouseKeysMode` wrapper

    test.Snap("should not be dragging")
end)

test.Step(
  "Verify keyboard shortcuts option doesn't get enabled by reset (in MAME)",
  function()
    --[[
      If MGTK can't find the mouse, DeskTop turns on keyboard
      shortcuts (to be helpful) So this is a signal that after a
      hard reset (Control-OA-Reset), MAME sometimes is in a state
      where MGKT can't find the mouse. Is this an emulator issue or
      real bug? Is there some firmware banking that needs fixing?
    ]]

    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    test.Snap("keyboard shortcuts should not be enabled")
    a2d.DialogCancel()
end)
