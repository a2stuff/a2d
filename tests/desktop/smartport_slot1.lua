--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl1 cffa2 -sl6 '' -sl7 cffa2"
DISKARGS="-hard1 disk_a.2mg -hard3 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a SmartPort controller in slot 1 and one
  drive. Launch DeskTop. Special > Format Disk. Select the drive in
  slot 1. Verify that the format succeeds. Repeat for slots 2, 4, 5, 6
  and 7.
]]
test.Step(
  "SmartPort controller in slot 1",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/A")
    desktop.CloseAllWindows()
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2)
    desktop.FormatEraseSelectSlotDrive(1, 1)
    apple2.Type("A") -- same name
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    desktop.OpenWindow("/A")
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "volume should have formatted")
end)
