--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-ramsize 8M"
DISKARGS="-flop3 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]--

emu.wait(20) -- slow boot from floppy

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
