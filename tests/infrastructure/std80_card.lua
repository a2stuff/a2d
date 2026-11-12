--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-aux std80"
DISKARGS="-flop1 ProDOS_2_4_3.po"
WAITFORDESKTOP="false"

======================================== ENDCONFIG ]]

test.Step(
  "Grab 80 col screen with std80 card",
  function()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/PRODOS.2.4.3/BASIC.SYSTEM")
    apple2.WaitForBasicSystem();
    apple2.TypeLine("PR#3");
    apple2.TypeLine("CATALOG");
    emu.wait(5);
    print(apple2.GrabTextScreen());
end)
