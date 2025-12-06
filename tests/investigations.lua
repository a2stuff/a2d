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
end)


test.Step(
  "Ejecting floppy goes sideways",
  function()
    emu.wait(20)
    local drive = apple2.GetDiskIIS6D1()
    local current = drive.filename
    drive:unload()

    a2d.OpenPath("/FLOPPY1")
    a2dtest.ExpectAlertShown()
    apple2.EscapeKey()

    --[[
      we seem to hang here somehow?

      can't reproduce it on the console though!

      maybe we're accessing the disk when it is yanked? Do something
      modal perhaps?

      CPU seems to still be chugging along, albeit in $C8xx space
    ]]--

    a2dtest.ExpectAlertNotShown()
    emu.wait(60)
    test.Snap("Waited a long time")
    apple2.Type("TRASH")
    test.Snap("typed some shit")
    a2d.InMouseKeysMode(function(m)
        m.MoveByApproximately(apple2.SCREEN_WIDTH,apple2.SCREEN_HEIGHT)
        m.MoveByApproximately(-apple2.SCREEN_WIDTH,-apple2.SCREEN_HEIGHT)
        m.MoveByApproximately(apple2.SCREEN_WIDTH,apple2.SCREEN_HEIGHT)
        m.MoveByApproximately(-apple2.SCREEN_WIDTH,-apple2.SCREEN_HEIGHT)
        m.MoveByApproximately(apple2.SCREEN_WIDTH,apple2.SCREEN_HEIGHT)
        m.MoveByApproximately(-apple2.SCREEN_WIDTH,-apple2.SCREEN_HEIGHT)
        m.MoveByApproximately(apple2.SCREEN_WIDTH,apple2.SCREEN_HEIGHT)
        m.MoveByApproximately(-apple2.SCREEN_WIDTH,-apple2.SCREEN_HEIGHT)
    end)
    -- This seems to make us hang or crash?
    drive:load(current)

    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    a2d.WaitForRestart()
end)
