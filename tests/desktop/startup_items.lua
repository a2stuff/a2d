--[[
  Create a Startup.Items folder, verify items execute sequentially.
]]
test.Step(
  "Startup.Items execute sequentially",
  function()
    desktop.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "/A2.DESKTOP/STARTUP.ITEMS")
    desktop.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/SHAKESPEARE", "/A2.DESKTOP/STARTUP.ITEMS")

    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    util.WaitFor(
      "expected Lorem Ipsum text showing", function()
        return a2dtest.HasOpenWindow() and a2dtest.OCRFrontWindowContent():match("Lorem ipsum dolor sit amet")
      end, {wait=1})
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()

    util.WaitFor(
      "expected Hamlet text showing", function()
        return a2dtest.HasOpenWindow() and a2dtest.OCRFrontWindowContent():match("To be, or not to be, that is the question")
      end, {wait=1})
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()

    -- cleanup
    desktop.OpenWindow("/A2.DESKTOP/STARTUP.ITEMS")
    desktop.SelectAll()
    desktop.DeleteSelection()
    desktop.CloseAllWindows()
end)

--[[
  Non-folder Startup.Items is ignored.
]]
test.Step(
  "Startup.Items must be a folder",
  function()
    desktop.DeletePath("/A2.DESKTOP/STARTUP.ITEMS")
    desktop.DuplicatePath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "STARTUP.ITEMS")
    desktop.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/STARTUP.ITEMS", "/A2.DESKTOP")

    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- cleanup
    desktop.DeletePath("/A2.DESKTOP/STARTUP.ITEMS")
    desktop.CreateFolder("/A2.DESKTOP/STARTUP.ITEMS")
    desktop.CloseAllWindows()
end)

--[[
  OA+SA skips Startup Items
]]
test.Step(
  "Holding OA+SA skips Startup.Items",
  function()
    desktop.CopyPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM", "/A2.DESKTOP/STARTUP.ITEMS")

    desktop.CloseAllWindows()
    desktop.Reboot({no_wait=true})
    apple2.PressOA()
    apple2.PressSA()
    a2d.WaitForDesktopReady()
    apple2.ReleaseSA()
    apple2.ReleaseOA()

    test.ExpectNotMatch(a2dtest.OCRScreen(), "Lorem ipsum dolor sit amet", "Text preview should not be showing")

    -- cleanup
    desktop.OpenWindow("/A2.DESKTOP/STARTUP.ITEMS")
    desktop.SelectAll()
    desktop.DeleteSelection()
    desktop.CloseAllWindows()
end)
