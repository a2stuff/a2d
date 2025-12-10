--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

test.Step(
  "non-folder file",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.OAShortcut("I")
    test.Snap("verify size is in K")
    a2d.DialogOK()
end)

test.Step(
  "empty folder",
  function()
    a2d.SelectPath("/TESTS/VIEW/BY.NAME/EMPTY")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 1 item")
    a2d.DialogOK()
end)

test.Step(
  "one item in folder",
  function()
    a2d.SelectPath("/TESTS/VIEW/BY.NAME/ONE.FILE")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 2 items")
    a2d.DialogOK()
end)

test.Step(
  "many items in folder",
  function()
    a2d.SelectPath("/TESTS/VIEW/BY.NAME/A1.B1.A.B")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 5 items")
    a2d.DialogOK()
end)

test.Step(
  "empty volume",
  function()
    a2d.SelectPath("/RAM1")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 0 items / _K")
    test.Snap("verify size used is small (a few K)")
    a2d.DialogOK()
end)

test.Step(
  "volume with 1 file",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.SelectPath("/RAM1")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 1 item / _K")
    a2d.DialogOK()
    a2d.EraseVolume("RAM1")
end)

test.Step(
  "volume with 2 or more files",
  function()
    a2d.CopyPath("/TESTS/VIEW/BY.NAME/A1.B1.A.B", "/RAM1")
    a2d.SelectPath("/RAM1")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 5 items / _K")
    a2d.DialogOK()
    a2d.EraseVolume("RAM1")
end)

test.Step(
  "new file dates",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/IIGS.50")
    a2d.OAShortcut("I")
    test.Snap("verify date after 1999 shows correctly")
    a2d.DialogOK()
end)

test.Step(
  "32MB volume",
  function()
    a2d.SelectPath("/TESTS")
    a2d.OAShortcut("I")
    emu.wait(30) -- slow
    test.Snap("verify total size is 32,768K, not 0K")
    a2d.DialogOK()
end)

test.Step(
  "file, folder, file",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
    a2d.OAShortcut("I")
    a2dtest.ExpectNothingChanged(function()
        a2d.DialogOK()
        a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS")
        a2d.OAShortcut("I")
        a2d.DialogOK()
        a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
        a2d.OAShortcut("I")
    end)
    a2d.DialogOK()
end)

test.Step(
  "more than 255 files",
  function()
    a2d.SelectPath("/TESTS/RAMCARD/SHORTCUT/HAS.256.FILES")
    a2d.OAShortcut("I")
    a2d.WaitForRestart() -- slow
    test.Snap("verify count is greater than 255")
    a2d.DialogOK()
end)

test.Step(
  "known size",
  function()
    a2d.SelectPath("/TESTS/PROPERTIES/KNOWN.SIZE")
    a2d.OAShortcut("I")
    test.Snap("verify size is 17K for 2 items")
    a2d.DialogOK()
end)

test.Step(
  "cancel enumeration",
  function()
    a2d.SelectPath("/TESTS")
    a2d.OAShortcut("I", {no_wait=true})
    emu.wait(1)
    apple2.EscapeKey()
    test.Snap("verify count is canceled (less than 100 items)")
    a2d.DialogOK()
end)

test.Step(
  "auxtype",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/PACKED.FOT")
    a2d.OAShortcut("I")
    a2dtest.ExpectNothingChanged(function()
        a2d.DialogOK()
        a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
        a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
        a2d.OAShortcut("I")
    end)
    a2d.DialogOK()
end)

test.Step(
  "locking folder",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/FOLDER")
    a2dtest.ExpectNothingChanged(function()
        a2d.OAShortcut("I")
        apple2.ControlKey("L") -- Toggle Locked
        a2d.DialogOK()
        a2d.SelectPath("/TESTS/FILE.TYPES/FOLDER")
    end)
end)

