--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]--


--[[============================================================

  Miscellaneous investigations

  ============================================================]]--

test.Step(
  "Verify keyboard shortcuts option doesn't get enabled by reset (in MAME)",
  function()
    --[[
      If MGTK can't find the mouse, DeskTop turns on keyboard
      shortcuts (to be helpful) So this is a signal that after a
      hard reset (Control-OA-Reset), MAME sometimes is in a state
      where MGKT can't find the mouse. Is this an emulator issue or
      real bug? Is there some firmware banking that needs fixing?
    ]]--

    apple2.ControlOAReset()
    a2d.WaitForRestart()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    test.Snap("keyboard shortcuts should not be enabled")
    a2d.DialogCancel()
end)

test.Step(
  "OA+SA+Down hangs if disk was ejected",
  function()
    emu.wait(20)
    local drive = apple2.GetDiskIIS6D1()
    local current = drive.filename
    drive:unload()

    -- OpenPath implicitly uses OA+SA+Down
    a2d.OpenPath("/FLOPPY1")
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
    a2dtest.ExpectNotHanging()

    -- Does not hang if OA+O is used instead of OA+SA+Down
end)
