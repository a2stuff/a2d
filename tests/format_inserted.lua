--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-ramsize 8M"
DISKARGS="-flop3 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]--

emu.wait(20) -- slow boot from floppy

--[[
  Launch DeskTop. Insert a non-formatted disk into a SmartPort drive
  (e.g. Virtual ][ OmniDisk). Verify that a prompt is shown to format
  the disk. Click OK. Enter a name, and click OK. Verify that the
  correct slot and drive are shown in the confirmation prompt.
]]--
test.Step(
  "Prompt to format inserted disk",
  function()
    apple2.Get35Drive2():load(emu.subst_env("$UNFORMATTED_IMG"))
    a2dtest.WaitForAlert()

    -- respond to alert
    a2d.DialogOK()

    -- name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    test.Snap("verify prompt shows slot 5, drive 2")
end)
