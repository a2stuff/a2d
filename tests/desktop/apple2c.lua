--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

--[[
  Run DeskTop on a IIc (or IIc+). Start `BASIC.SYSTEM`. Run `POKE
  1275,0`. `BYE` to return to DeskTop. Verify that the progress bar
  has a gray background, not "VWVWVW..."
]]
test.Step(
  "80-col firmware mode byte is reset on startup",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("POKE 1275,0") -- mess up screen hole
    apple2.TypeLine("BYE")
    while not apple2.GrabTextScreen():match("Starting Apple II DeskTop") do
      emu.wait(0.25)
    end
    test.Expect(apple2.ReadSSW("RDALTCHAR") > 127, "ALTCHAR should be enabled")
end)

