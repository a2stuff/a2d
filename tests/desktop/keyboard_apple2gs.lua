--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Repeat the following cases with these modifiers: Open-Apple, Solid-Apple:

  * On a IIgs: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier
    and press Shift+Tab repeatedly. Verify that windows are activated
    cycle in reverse order (B, A, C, B, A, C, ...).
]]
test.Variants(
  {
    {"cycle - OA + shift-tab", apple2.PressOA, apple2.ReleaseOA},
    {"cycle - SA + shift-tab", apple2.PressSA, apple2.ReleaseSA},
  },
  function(idx, name, press, release)
    a2d.CreateFolder("/A2.DESKTOP/TMP")
    a2d.OpenPath("/A2.DESKTOP/TMP")
    a2d.CreateFolder("A")
    a2d.CreateFolder("B")
    a2d.CreateFolder("C")
    a2d.SelectAll()
    a2d.OpenSelectionAndCloseCurrent()
    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "A, B, C should be open")

    local sequence = ""
    for i = 1, 6 do
      press()

      apple2.PressShift()
      apple2.TabKey()
      apple2.ReleaseShift()

      a2d.WaitForRepaint()

      release()

      sequence = sequence .. a2dtest.GetFrontWindowTitle()
    end

    test.ExpectEquals(sequence, "BACBAC", "should cycle backwards")

    a2d.DeletePath("/A2.DESKTOP/TMP")
end)
