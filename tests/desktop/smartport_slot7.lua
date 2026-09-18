--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl1 cffa2 -sl6 '' -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard3 disk_a.2mg"
WAITFORDESKTOP="false"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a SmartPort controller in slot 1 and one
  drive. Launch DeskTop. Special > Format Disk. Select the drive in
  slot 1. Verify that the format succeeds. Repeat for slots 2, 4, 5, 6
  and 7.
]]
test.Step(
  "SmartPort controller in slot 7",
  function()
    util.WaitFor(
      "error", function()
        return apple2.GrabTextScreen():match("UNABLE TO LOAD PRODOS")
      end, {wait=1})
    apple2.ControlReset()
    apple2.TypeLine("PR#1")
    a2d.WaitForDesktopReady()

    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/A")
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
    a2d.FormatEraseSelectSlotDrive(7, 1)
    apple2.Type("A") -- same name
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    a2d.OpenWindow("/A")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "volume should have formatted")
end)
