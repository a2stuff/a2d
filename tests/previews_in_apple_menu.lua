--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

test.Step(
  "SHOW.IMAGE.FILE in Apple Menu",
  function()
    a2d.CopyPath("/A2.DESKTOP/MODULES/SHOW.IMAGE.FILE", "/A2.DESKTOP/APPLE.MENU")
    a2d.CloseAllWindows()
    a2d.Reboot()

    -- no icon
    a2d.ClearSelection()
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    a2d.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- image file
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    a2d.CloseWindow()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.IMAGE.FILE")
end)

test.Step(
  "SHOW.TEXT.FILE in Apple Menu",
  function()
    a2d.CopyPath("/A2.DESKTOP/MODULES/SHOW.TEXT.FILE", "/A2.DESKTOP/APPLE.MENU")
    a2d.CloseAllWindows()
    a2d.Reboot()

    -- no icon
    a2d.ClearSelection()
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    a2d.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- text file
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    a2d.CloseWindow()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.TEXT.FILE")
end)

test.Step(
  "SHOW.FONT.FILE in Apple Menu",
  function()
    a2d.CopyPath("/A2.DESKTOP/MODULES/SHOW.FONT.FILE", "/A2.DESKTOP/APPLE.MENU")
    a2d.CloseAllWindows()
    a2d.Reboot()

    -- no icon
    a2d.ClearSelection()
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    a2d.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- font file
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS/ATHENS")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    a2d.CloseWindow()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.FONT.FILE")
end)


test.Step(
  "SHOW.DUET.FILE in Apple Menu",
  function()
    a2d.CopyPath("/A2.DESKTOP/MODULES/SHOW.DUET.FILE", "/A2.DESKTOP/APPLE.MENU")
    a2d.CloseAllWindows()
    a2d.Reboot()

    -- no icon
    a2d.ClearSelection()
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    a2d.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingHappened(function()
        a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    end)

    -- duet file
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/JESU.JOY")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    apple2.EscapeKey()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.DUET.FILE")
end)

