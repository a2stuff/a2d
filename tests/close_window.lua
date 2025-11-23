--[[============================================================

  "Close Window" tests

  ============================================================]]--

test.Step(
  "Close box normally closes only one window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("EXTRAS")
    a2d.InMouseKeysMode(function(m)
        m.GoToApproximately(40, 26)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify only one window closed")
end)
