a2d.ConfigureRepaintTime(0.25)

--[[
  Create a Startup.Items folder, verify items execute sequentially.
]]
test.Step(
  "Startup.Items execute sequentially",
  function()
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "/A2.DESKTOP/STARTUP.ITEMS")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/SHAKESPEARE", "/A2.DESKTOP/STARTUP.ITEMS")

    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    util.WaitFor(
      "expected Lorem Ipsum text showing", function()
        return a2dtest.OCRScreen():match("Lorem ipsum dolor sit amet")
    end)


    a2d.CloseWindow()

    util.WaitFor(
      "expected Hamlet text showing", function()
        return a2dtest.OCRScreen():match("To be, or not to be, that is the question")
    end)

    a2d.CloseWindow()

    -- cleanup
    a2d.OpenPath("/A2.DESKTOP/STARTUP.ITEMS")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
end)

--[[
  Non-folder Startup.Items is ignored.
]]
test.Step(
  "Startup.Items must be a folder",
  function()
    a2d.DeletePath("/A2.DESKTOP/STARTUP.ITEMS")
    a2d.DuplicatePath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "STARTUP.ITEMS")
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/STARTUP.ITEMS", "/A2.DESKTOP")

    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/STARTUP.ITEMS")
    a2d.CreateFolder("/A2.DESKTOP/STARTUP.ITEMS")
    a2d.CloseAllWindows()
end)

--[[
  OA+SA skips Startup Items
]]
test.Step(
  "Holding OA+SA skips Startup.Items",
  function()
    a2d.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "/A2.DESKTOP/STARTUP.ITEMS")

    a2d.CloseAllWindows()
    a2d.Reboot()
    apple2.PressOA()
    apple2.PressSA()
    a2d.WaitForDesktopReady()
    apple2.ReleaseSA()
    apple2.ReleaseOA()

    test.ExpectNotMatch(a2dtest.OCRScreen(), "Lorem ipsum dolor sit amet", "Text preview should not be showing")

    -- cleanup
    a2d.OpenPath("/A2.DESKTOP/STARTUP.ITEMS")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
end)
