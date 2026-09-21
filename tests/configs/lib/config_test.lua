
apple2 = require("apple2")
a2d = require("a2d")
desktop = require("desktop")
test = require("test")
a2dtest = require("a2dtest")

function ConfigTest()
  test.Step(
    "Apple > About This Apple II",
    function()
      a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
      a2dtest.WaitForSystemTask()
      test.Snap(manager.machine.system.name)
      desktop.CloseWindow()

      a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.KEY_CAPS)
      apple2.ReturnKey()
      apple2.DeleteKey()
      apple2.EscapeKey()
      apple2.TabKey()
      apple2.UpArrowKey()
      apple2.LeftArrowKey()
      apple2.RightArrowKey()
      apple2.DownArrowKey()

      apple2.PressControl()
      apple2.ReleaseControl()
      apple2.PressShift()
      apple2.ReleaseShift()

      if manager.machine.system.name:match("^prav8c") then
        -- TODO: Figure out Caps Lock on the Pravetz 8C
        print("Caps Lock not supported on Pravetz 8C")
      else
        apple2.CapsLockOff()
        test.Expect(not apple2.IsCapsLockOn(), "caps lock should be off")
        apple2.CapsLockOn()
        test.Expect(apple2.IsCapsLockOn(), "caps lock should be on")
        apple2.CapsLockOff()
      end

      apple2.PressOA()
      test.Expect(apple2.ReadSSW("BUTN0") > 127, "BUTN0 should be down")
      apple2.ReleaseOA()

      apple2.PressSA()
      test.Expect(apple2.ReadSSW("BUTN1") > 127, "BUTN0 should be down")
      apple2.ReleaseSA()

      desktop.CloseWindow()
  end)
end
