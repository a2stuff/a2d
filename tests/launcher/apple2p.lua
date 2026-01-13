--[[ BEGINCONFIG ========================================

MODEL="apple2p"
MODELARGS="-sl2 mouse"
DISKARGS="-flop1 ProDOS_2_4_3.po -flop2 $FLOP1IMG"
WAITFORDESKTOP="false"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure an Apple II+ system. Invoke `DESKTOP.SYSTEM` from a
  launcher (e.g. Bitsy Bye). Verify the launcher is restarted and does
  not crash or hang.
]]
test.Step(
  "Apple II+",
  function()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP.1/DESKTOP.SYSTEM")
    while not apple2.GrabTextScreen():match("PRESS A KEY TO QUIT") do
      emu.wait(0.25)
    end
    apple2.Type("A") -- too literal?
    apple2.WaitForBitsy()
end)

