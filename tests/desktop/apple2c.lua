--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Run DeskTop on a IIc (or IIc+). Start `BASIC.SYSTEM`. Run `POKE
  1275,0`. `BYE` to return to DeskTop. Verify that the progress bar
  has a gray background, not "VWVWVW..."
]]
test.Step(
  "80-col firmware mode byte is reset on startup",
  function()
    desktop.InvokePath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {no_wait=true})
    apple2.WaitForBasicSystem()
    apple2.TypeLine("POKE 1275,0") -- mess up screen hole
    apple2.TypeLine("BYE")
    util.WaitFor(
      "starting", function()
        return apple2.GrabTextScreen():match("Starting Apple II DeskTop")
      end, {wait=0.25})
    test.Expect(apple2.ReadSSW("RDALTCHAR") > 127, "ALTCHAR should be enabled")
end)

