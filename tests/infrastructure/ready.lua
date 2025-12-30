a2d.ConfigureRepaintTime(0.25)

test.Step(
  "desktop showing",
  function()
    a2d.WaitForDesktopShowing()

    a2d.Quit()

    test.ExpectError(
      "Timeout %(60s%) waiting for desktop",
      a2d.WaitForDesktopShowing,
      "should timeout")

    test.ExpectError(
      "Timeout %(5s%) waiting for desktop",
      function()
        a2d.WaitForDesktopShowing({timeout=5})
      end,
      "should timeout")

    apple2.BitsyInvokePath("/A2.DESKTOP/PRODOS")
    a2d.WaitForDesktopReady()
end)

test.Step(
  "desktop ready",
  function()
    a2d.WaitForDesktopReady()

    a2d.Quit()

    test.ExpectError(
      "Timeout %(60s%) waiting for desktop",
      a2d.WaitForDesktopReady,
      "should timeout")

    test.ExpectError(
      "Timeout %(5s%) waiting for desktop",
      function()
        a2d.WaitForDesktopReady({timeout=5})
      end,
      "should timeout")

    apple2.BitsyInvokePath("/A2.DESKTOP/PRODOS")
    a2d.WaitForDesktopReady()
end)

