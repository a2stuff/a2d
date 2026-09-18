--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -aux ''"
DISKARGS="-flop1 ProDOS_2_4_3.po -flop2 $FLOP1IMG"
WAITFORDESKTOP="false"
CHECKAUXMEMORY="false"

======================================== ENDCONFIG ]]

--[[
  Configure an Apple IIe system with no card in the Aux slot. Invoke
  `DESKTOP.SYSTEM` from a launcher (e.g. Bitsy Bye). Verify the
  launcher is restarted and does not crash or hang.
]]
test.Step(
  "Running with nothing in the Aux slot",
  function()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP.1/DESKTOP.SYSTEM")
    util.WaitFor(
      "prompt", function()
        return apple2.GrabTextScreen():match("PRESS A KEY TO QUIT")
      end, {wait=0.25})
    apple2.Type("A") -- too literal?
    apple2.WaitForBitsy()
end)
