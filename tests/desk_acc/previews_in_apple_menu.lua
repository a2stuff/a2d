--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Put `SHOW.IMAGE.FILE` in `APPLE.MENU`, start DeskTop.

  * Select no icon, select DA from Apple menu. Verify nothing happens
    other than open/close animation and screen refresh.

  * Select volume icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation and screen refresh.

  * Select folder icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation and screen refresh.

  * Select image file icon, select DA from Apple menu. Verify image is
    shown.
]]
test.Step(
  "SHOW.IMAGE.FILE in Apple Menu",
  function()
    desktop.CopyPath("/A2.DESKTOP/MODULES/SHOW.IMAGE.FILE", "/A2.DESKTOP/APPLE.MENU")
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- no icon
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    desktop.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    desktop.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- image file
    desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    desktop.CloseWindow()

    desktop.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.IMAGE.FILE")
end)

--[[
  Put `SHOW.TEXT.FILE` in `APPLE.MENU`, start DeskTop.

  * Select no icon, select DA from Apple menu. Verify nothing happens
    other than open/close animation.

  * Select volume icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation.

  * Select folder icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation.

  * Select text file icon, select DA from Apple menu. Verify text is
    shown.
]]
test.Step(
  "SHOW.TEXT.FILE in Apple Menu",
  function()
    desktop.CopyPath("/A2.DESKTOP/MODULES/SHOW.TEXT.FILE", "/A2.DESKTOP/APPLE.MENU")
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- no icon
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    desktop.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    desktop.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- text file
    desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    desktop.CloseWindow()

    desktop.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.TEXT.FILE")
end)

--[[
  Put `SHOW.FONT.FILE` in `APPLE.MENU`, start DeskTop.

  * Select no icon, select DA from Apple menu. Verify nothing happens
    other than open/close animation.

  * Select volume icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation.

  * Select folder icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation.

  * Select font file icon, select DA from Apple menu. Verify font is
    shown.
]]
test.Step(
  "SHOW.FONT.FILE in Apple Menu",
  function()
    desktop.CopyPath("/A2.DESKTOP/MODULES/SHOW.FONT.FILE", "/A2.DESKTOP/APPLE.MENU")
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- no icon
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    desktop.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    desktop.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- font file
    desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS/ATHENS")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    desktop.CloseWindow()

    desktop.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.FONT.FILE")
end)

--[[
  Put `SHOW.DUET.FILE` in `APPLE.MENU`, start DeskTop.

  * Select no icon, select DA from Apple menu. Verify nothing happens
    other than open/close animation.

  * Select volume icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation.

  * Select folder icon, select DA from Apple menu. Verify nothing
    happens other than open/close animation.

  * Select Electric Duet file icon, select DA from Apple menu. Verify
    music is played.
]]
test.Step(
  "SHOW.DUET.FILE in Apple Menu",
  function()
    desktop.CopyPath("/A2.DESKTOP/MODULES/SHOW.DUET.FILE", "/A2.DESKTOP/APPLE.MENU")
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- no icon
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- volume icon
    desktop.SelectPath("/A2.DESKTOP")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- file icon
    desktop.SelectPath("/A2.DESKTOP/APPLE.MENU")
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    end)

    -- duet file
    desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/JESU.JOY")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.APPLE_EMPTY_SLOT)
    test.Snap("verify preview shown")
    apple2.EscapeKey()

    desktop.DeletePath("/A2.DESKTOP/APPLE.MENU/SHOW.DUET.FILE")
end)

