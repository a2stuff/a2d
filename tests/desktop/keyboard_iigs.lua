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
    "cycle - OA + shift-tab",
    "cycle - SA + shift-tab",
  },
  function(idx)
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
      if idx < 5 then
        apple2.PressOA()
      else
        apple2.PressSA()
      end

      if idx == 1 or idx == 5 then
        apple2.TabKey()
      elseif idx == 2 or idx == 6 then
        apple2.Type("`")
      elseif idx == 3 or idx == 7 then
        apple2.Type("~")
      elseif idx == 4 or idx == 8 then
        apple2.PressShift()
        apple2.TabKey()
        apple2.ReleaseShift()
      end

      a2d.WaitForRepaint()

      if idx < 5 then
        apple2.ReleaseOA()
      else
        apple2.ReleaseSA()
      end

      sequence = sequence .. a2dtest.GetFrontWindowTitle()
    end

    if idx == 1 or idx == 2 or idx == 5 or idx == 6 then
      test.ExpectEquals(sequence, "ABCABC", "should cycle forwards")
    else
      test.ExpectEquals(sequence, "BACBAC", "should cycle backwards")
    end

    a2d.DeletePath("/A2.DESKTOP/TMP")
end)
