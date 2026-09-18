--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Repeat the following for these permutations:

  * DeskTop (1) copied to RAMCard and (2) not copied to RAMCard.

  * Renaming (1) the volume that DeskTop loaded from, and renaming (2)
    the DeskTop folder itself. (For #2, move all DeskTop files to a
    subfolder.)
]]
function RenameTest(name, proc)
  test.Variants(
    {
      {name .. " - Not copied to RAMCard, rename load volume", false,
       function() -- setup
         desktop.RenamePath("/A2.DESKTOP", "NEWNAME")
         return "/NEWNAME"
       end,
       function() -- cleanup
         desktop.RenamePath("/NEWNAME", "A2.DESKTOP")
       end,
      },

      {name .. " - Copied to RAMCard, rename load volume", true,
       function() -- setup
         desktop.RenamePath("/RAM1", "NEWNAME")
         return "/NEWNAME/DESKTOP"
       end,
       function() -- cleanup
         desktop.RenamePath("/NEWNAME", "RAM1")
         desktop.EraseVolume("RAM1")
       end,
      },

      {name .. " - Copied to RAMCard, rename load folder", true,
       function() -- setup
         desktop.RenamePath("/RAM1/DESKTOP", "NEWNAME")
         return "/RAM1/NEWNAME"
       end,
       function() -- cleanup
         desktop.EraseVolume("RAM1")
       end,
      },

      {name .. " - Not copied to RAMCard, rename load folder", false,
       function() -- setup
         -- Copy to /RAM1
         desktop.SelectPath("/A2.DESKTOP")
         desktop.CopySelectionTo("/RAM1", true)
         a2dtest.WaitForSystemTask()
         -- Switch to copy
         desktop.InvokePath("/RAM1/A2.DESKTOP/DESKTOP.SYSTEM", {no_wait=true})
         a2d.WaitForDesktopReady()

         desktop.RenamePath("/RAM1/A2.DESKTOP", "NEWNAME")
         return "/RAM1/NEWNAME"
       end,
       function() -- cleanup
         desktop.EraseVolume("RAM1")
       end,
      },
    },
    function(idx, name, copied, setup, cleanup)

      -- configure
      if copied then
        desktop.ToggleOptionCopyToRAMCard()
        desktop.CloseAllWindows()
        desktop.Reboot()
        a2d.WaitForDesktopReady()
      end

      -- setup
      local dtpath = setup()

      desktop.CloseAllWindows()
      desktop.ClearSelection()

      proc(dtpath)

      desktop.CloseAllWindows()
      desktop.ClearSelection()

      -- cleanup
      cleanup()
      desktop.DeletePath("/A2.DESKTOP/LOCAL")
      desktop.Reboot()
      a2d.WaitForDesktopReady()
  end)
end

--[[
  File > Copy To... (overlays)
]]
RenameTest(
  "overlays",
  function(dtpath)
    -- File > Copy To...
    desktop.SelectPath(dtpath.."/DESKTOP.SYSTEM")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_COPY_TO)
    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "window and dialog+listbox should be open")
    a2d.DialogCancel()
end)

--[[
  Special > Copy Disk (and that File > Quit returns to DeskTop)
  (overlay + quit handler)
]]
RenameTest(
  "overlay + quit handler",
  function(dtpath)
    -- Special > Copy Disk
    desktop.CloseAllWindows()
    desktop.CopyDisk()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "dialog+listbox should be open")
    -- File > Quit returns to DeskTop
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
end)

--[[
  Apple Menu > Calculator (desk accessories)
]]
RenameTest(
  "desk accessories",
  function(dtpath)
    -- Apple Menu > Calculator
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CALCULATOR)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "Calc", "Calculator should have run")
    desktop.CloseWindow()
end)

--[[
  Apple Menu > Control Panels (relative folders)
]]
RenameTest(
  "relative folders",
  function(dtpath)
    -- Apple Menu > Control Panels
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CONTROL_PANELS)
    a2dtest.WaitForSystemTask()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "CONTROL.PANELS", "Control Panels should have run")
    desktop.CloseWindow()

end)

--[[
  Control Panel, change desktop pattern, close, quit, restart
  (settings)
]]
RenameTest(
  "settings",
  function(dtpath)
    -- Control Panel, change desktop pattern, close, quit, restart
    desktop.InvokePath(dtpath.."/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.LeftArrowKey()
    apple2.ControlKey("D")
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()

    desktop.InvokePath(dtpath.."/DESKTOP.SYSTEM", {no_wait=true})
    a2d.WaitForCopyToRAMCard()

    test.Snap("verify desktop pattern changed")
end)

--[[
  Windows are saved on exit/restored on restart (configuration)
]]
RenameTest(
  "configuration",
  function(dtpath)
    -- Windows are saved on exit/restored on restart
    desktop.SelectPath(dtpath.."/DESKTOP.SYSTEM")
    local count = a2dtest.GetWindowCount()
    desktop.OpenSelection({no_wait=true})
    a2d.WaitForDesktopReady()
    test.ExpectEquals(a2dtest.GetWindowCount(), count, "windows should be restored")
end)

--[[
  Invoking another application (e.g. `BASIC.SYSTEM`), then quitting
  back to DeskTop (quit handler)
]]
RenameTest(
  "quit handler",
  function(dtpath)
    -- Invoking another application (e.g. `BASIC.SYSTEM`)
    -- then quitting back to DeskTop (quit handler)
    desktop.InvokePath(dtpath.."/EXTRAS/BASIC.SYSTEM", {no_wait=true})
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
end)

--[[
  Modifying shortcuts (selector)
]]
RenameTest(
  "selector file",
  function(dtpath)
    -- Modifying shortcuts (selector)
    desktop.SelectPath(dtpath.."/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, desktop.SHORTCUTS_ADD_A_SHORTCUT)
    a2dtest.WaitForSystemTask()
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    desktop.InvokePath(dtpath.."/DESKTOP.SYSTEM", {no_wait=true})
    a2d.WaitForCopyToRAMCard()

    a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, desktop.SHORTCUTS_RUN_A_SHORTCUT)
    a2dtest.WaitForSystemTask()
    test.Snap("verify shortcut persisted")
    a2d.DialogCancel()
    a2dtest.WaitForSystemTask()
end)
