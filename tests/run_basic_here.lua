--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--


--[[============================================================

  "Run Basic Here" tests

  ============================================================]]--

test.Step(
  "/RAM exists",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    apple2.TypeLine("CAT /RAM")
    emu.wait(1)
    test.Expect(apple2.GrabTextScreen():match("BLOCKS FREE"), "/RAM should exist")
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()
    a2d.CloseAllWindows()
end)

test.Step(
  "PREFIX set correctly",
  function()
    a2d.OpenPath("/TESTS")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    apple2.TypeLine("PREFIX")
    emu.wait(1)
    test.Expect(apple2.GrabTextScreen():match("/TESTS/"), "Prefix should be /TESTS/")
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()
    a2d.CloseAllWindows()
end)

test.Step(
  "Copied to RAMCard",
  function()
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.Restart()

    a2d.OpenPath("/TESTS")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    test.Expect(apple2.GrabTextScreen():match("PRODOS BASIC"), "BASIC should start")
end)

