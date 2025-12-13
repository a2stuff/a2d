--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

--[[
  File > Get Info a non-folder file. Verify that the size shows as
  "_size_K".
]]--
test.Step(
  "non-folder file",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.OAShortcut("I")
    test.Snap("verify size is in K")
    a2d.DialogOK()
end)

--[[
  File > Get Info a folder containing 0 files. Verify that the size
  shows as "_size_K for 1 item".
]]--
test.Step(
  "empty folder",
  function()
    a2d.SelectPath("/TESTS/VIEW/BY.NAME/EMPTY")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 1 item")
    a2d.DialogOK()
end)

--[[
  File > Get Info a folder containing 1 file. Verify that the size
  shows as "_size_K for 2 items".
]]-
test.Step(
  "one item in folder",
  function()
    a2d.SelectPath("/TESTS/VIEW/BY.NAME/ONE.FILE")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 2 items")
    a2d.DialogOK()
end)

--[[
  File > Get Info a folder containing 2 or more files. Verify that the
  size shows as "_size_K for _count_ items", including the folder
  itself.
]]--
test.Step(
  "many items in folder",
  function()
    a2d.SelectPath("/TESTS/VIEW/BY.NAME/A1.B1.A.B")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 5 items")
    a2d.DialogOK()
end)

--[[
  File > Get Info a volume containing 0 files. Verify that the size
  shows as "_size_K for 0 items / _total_K".

  Launch DeskTop. Select a volume icon, where the volume contains no
  files. File > Get Info. Verify that numbers are shown for number of
  files (0) and space used (a few K).
]]--
test.Step(
  "empty volume",
  function()
    a2d.SelectPath("/RAM1")
    a2d.OAShortcut("I")
    test.Snap("verify size is _K for 0 items / _K")
    test.Snap("verify size used is small (a few K)")
    a2d.DialogOK()
end)

--[[
  File > Get Info a volume containing 1 file. Verify that the size
  shows as "_size_K for 1 item / _total_K".
]]--
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

--[[
  File > Get Info a volume containing 2 or more files. Verify that the
  size shows as "_size_K for _count_ items / _total_K".
]]--
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

--[[
  Open folder with new files. Use File > Get Info; verify dates after
  1999 show correctly.
]]--
test.Step(
  "new file dates",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/IIGS.50")
    a2d.OAShortcut("I")
    test.Snap("verify date after 1999 shows correctly")
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Select a 32MB volume. File > Get Info. Verify total
  size shows as 32,768K not 0K.
]]--
test.Step(
  "32MB volume",
  function()
    a2d.SelectPath("/TESTS")
    a2d.OAShortcut("I")
    emu.wait(30) -- slow
    test.Snap("verify total size is 32,768K, not 0K")
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Select a file icon. File > Get Info. Verify that the
  size shown is correct. Select a directory. File > Get Info, and
  dismiss. Now select the original file icon again, and File > Get
  Info. Verify that the size shown is still correct.
]]--
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

--[[
  Use real hardware, not an emulator. Launch DeskTop. Select a volume
  icon. File > Get Info. Verify that a "The specified path name is
  invalid." alert is not shown.

  TODO: See if we can repro the inspiration for this one in an emulator.
]]--


--[[
  Launch DeskTop. Select a volume with more than 255 files in a folder
  (e.g. Total Replay). File > Get Info. Verify that the count
  finishes.
]]--
test.Step(
  "more than 255 files",
  function()
    a2d.SelectPath("/TESTS/RAMCARD/SHORTCUT/HAS.256.FILES")
    a2d.OAShortcut("I")
    a2d.WaitForRestart() -- slow
    test.Snap("verify count is greater than 255")
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Select `/TESTS/PROPERTIES/KNOWN.SIZE`. File > Get
  Info. Verify that "Size" is "17K for 2 items".
]]--
test.Step(
  "known size",
  function()
    a2d.SelectPath("/TESTS/PROPERTIES/KNOWN.SIZE")
    a2d.OAShortcut("I")
    test.Snap("verify size is 17K for 2 items")
    a2d.DialogOK()
end)

--[[
  Select a volume or folder containing multiple files. File > Get
  Info. During the count of the files, press Escape. Verify that the
  count is canceled.
]]--
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

--[[
  Open `/TESTS/FILE.TYPES`. Select `PACKED.FOT`. File > Get Info.
  Verify that the AuxType displays as `$4001`. Click OK. View > by
  Name. View > as Icons. File > Get Info. Verify that the AuxType
  still displays correctly.
]]--
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

--[[
  Open a volume window containing a folder. Select the folder. File >
  Get Info. Check Locked. Click OK. Close the volume window. Re-open
  the volume window. Verify that the folder is still a folder.
]]-
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

