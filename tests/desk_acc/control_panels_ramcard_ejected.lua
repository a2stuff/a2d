--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl4 ramfactor -sl7 superdrive -aux ext80"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2) -- slow with floppies
local s7d1 = manager.machine.images[":sl7:superdrive:fdc:0:35hd"]

--[[
  Repeat the following cases with the Options. International, and
  Control Panel DAs, and the Date and Time DA (on a system without a
  real-time clock):

  * Launch DeskTop, ensure it copies itself to RAMCard. Launch the DA
    and modify a setting. Verify that no prompt is shown. Power cycle
    and launch DeskTop. Verify that the modifications are present.

  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the
    startup disk. Launch the DA and Modify a setting. Verify that a
    prompt is shown asking about saving the changes. Insert the system
    disk, and click OK. Verify that no further prompt is shown. Power
    cycle and launch DeskTop. Verify that the modifications are
    present.

  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the
    startup disk. Launch the DA and modify a setting. Verify that a
    prompt is shown asking about saving the changes. Click OK. Verify
    that another prompt is shown asking to insert the system disk.
    Insert the system disk, and click OK. Verify that no further
    prompt is shown. Power cycle and launch DeskTop. Verify that the
    modifications are present.
]]
test.Variants(
  {
    { "No prompt - Options", "OPTIONS"},
    { "No prompt - International", "INTERNATIONAL"},
    { "No prompt - Control Panel", "CONTROL.PANEL"},
    { "Prompt to save - Options", "OPTIONS"},
    { "Prompt to save - International", "INTERNATIONAL"},
    { "Prompt to save - Control Panel", "CONTROL.PANEL"},
    { "Prompt to insert startup disk - Options", "OPTIONS"},
    { "Prompt to insert startup disk - International", "INTERNATIONAL"},
      { "Prompt to insert startup disk - Control Panel", "CONTROL.PANEL"},
  },
  function(idx, name, da)
    --setup
    a2d.ToggleOptionCopyToRAMCard() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    local drive, current
    if idx > 3 then
      -- Ensure prompt for saving appears
      drive = s7d1
      current = drive.filename
      drive:unload()
    end

    a2d.OpenPath("/RAM4/DESKTOP/APPLE.MENU/CONTROL.PANELS/" .. da)
    a2d.OAShortcut("1")
    a2d.OAShortcut("1")
    a2d.CloseWindow()

    if idx > 3 then
      a2dtest.WaitForAlert() -- prompt to save

      if idx > 6 then
        a2d.DialogOK()
        a2dtest.WaitForAlert() -- prompt to insert system disk
      end

      drive:load(current)
      a2d.DialogOK()
    end


    a2dtest.ExpectAlertNotShowing()

    -- TODO: Verify that changes were saved

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
