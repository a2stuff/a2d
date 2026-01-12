--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 '' -sl2 mouse -sl6 '' -sl7 superdrive"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)
local s7d2 = manager.machine.images[":sl7:superdrive:fdc:1:35hd"]

--[[
  Launch DeskTop. Insert a non-formatted disk into a SmartPort drive
  (e.g. Virtual ][ OmniDisk). Verify that a prompt is shown to format
  the disk. Click OK. Enter a name, and click OK. Verify that the
  correct slot and drive are shown in the confirmation prompt.
]]
test.Step(
  "Prompt to format inserted disk",
  function()
    s7d2:load(emu.subst_env("$UNFORMATTED_IMG"))
    a2dtest.WaitForAlert()

    -- respond to alert
    a2d.DialogOK()

    -- name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    a2dtest.WaitForAlert()
    test.Snap("verify prompt shows slot 7, drive 2")
    a2d.DialogOK()

    util.WaitFor(
      "selection",
      function() return
          #a2d.GetSelectedIcons() == 1 and
          a2dtest.GetSelectedIconName():upper() == "NEW.NAME" end,
      {timeout=120})
end)
