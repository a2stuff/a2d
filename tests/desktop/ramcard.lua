--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

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
         a2d.RenamePath("/A2.DESKTOP", "NEWNAME")
         return "/NEWNAME"
       end,
       function() -- cleanup
         a2d.RenamePath("/NEWNAME", "A2.DESKTOP")
       end,
      },

      {name .. " - Copied to RAMCard, rename load volume", true,
       function() -- setup
         a2d.RenamePath("/RAM1", "NEWNAME")
         return "/NEWNAME/DESKTOP"
       end,
       function() -- cleanup
         a2d.RenamePath("/NEWNAME", "RAM1")
         a2d.EraseVolume("RAM1")
       end,
      },

      {name .. " - Copied to RAMCard, rename load folder", true,
       function() -- setup
         a2d.RenamePath("/RAM1/DESKTOP", "NEWNAME")
         return "/RAM1/NEWNAME"
       end,
       function() -- cleanup
         a2d.EraseVolume("RAM1")
       end,
      },

      {name .. " - Not copied to RAMCard, rename load folder", false,
       function() -- setup
         -- Copy to /RAM1
         a2d.SelectPath("/A2.DESKTOP")
         a2d.CopySelectionTo("/RAM1", true)
         emu.wait(80) -- copy is slow
         -- Switch to copy
         a2d.OpenPath("/RAM1/A2.DESKTOP/DESKTOP.SYSTEM")
         a2d.WaitForDesktopReady()

         a2d.RenamePath("/RAM1/A2.DESKTOP", "NEWNAME")
         return "/RAM1/NEWNAME"
       end,
       function() -- cleanup
         a2d.EraseVolume("RAM1")
       end,
      },
    },
    function(idx, name, copied, setup, cleanup)

      -- configure
      if copied then
        a2d.ToggleOptionCopyToRAMCard()
        a2d.CloseAllWindows()
        a2d.Reboot()
        a2d.WaitForDesktopReady()
      end

      -- setup
      local dtpath = setup()

      a2d.CloseAllWindows()
      a2d.ClearSelection()

      proc(dtpath)

      a2d.CloseAllWindows()
      a2d.ClearSelection()

      -- cleanup
      cleanup()
      a2d.DeletePath("/A2.DESKTOP/LOCAL")
      a2d.Reboot()
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
    a2d.SelectPath(dtpath.."/DESKTOP.SYSTEM")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
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
    a2d.CloseAllWindows()
    a2d.CopyDisk()
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
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CALCULATOR)
    emu.wait(2)
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "Calc", "Calculator should have run")
    a2d.CloseWindow()
end)

--[[
  Apple Menu > Control Panels (relative folders)
]]
RenameTest(
  "relative folders",
  function(dtpath)
    -- Apple Menu > Control Panels
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    emu.wait(2)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "CONTROL.PANELS", "Control Panels should have run")
    a2d.CloseWindow()

end)

--[[
  Control Panel, change desktop pattern, close, quit, restart
  (settings)
]]
RenameTest(
  "settings",
  function(dtpath)
    -- Control Panel, change desktop pattern, close, quit, restart
    a2d.OpenPath(dtpath.."/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.LeftArrowKey()
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    a2d.CloseWindow()

    a2d.OpenPath(dtpath.."/DESKTOP.SYSTEM")
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
    a2d.SelectPath(dtpath.."/DESKTOP.SYSTEM")
    local count = a2dtest.GetWindowCount()
    a2d.OpenSelection()
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
    a2d.OpenPath(dtpath.."/EXTRAS/BASIC.SYSTEM")
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
    a2d.SelectPath(dtpath.."/EXTRAS/BASIC.SYSTEM")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.WaitForRepaint()
    a2d.DialogOK()
    a2d.WaitForRepaint()

    a2d.OpenPath(dtpath.."/DESKTOP.SYSTEM")
    a2d.WaitForCopyToRAMCard()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    a2d.WaitForRepaint()
    test.Snap("verify shortcut persisted")
    a2d.DialogCancel()
    a2d.WaitForRepaint()
end)
