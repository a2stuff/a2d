--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl4 ramfactor -sl5 ramfactor -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 dos33_floppy.dsk"

======================================== ENDCONFIG ]]

-- Multiple ramfactors just to flesh out drives list. Not actually used.

a2d.ConfigureRepaintTime(0.25)

--[[
This covers:
* File Pickers
* Disk Copy
* Sounds DA
* Find Files DA
* DOS 3.3 Import DA
]]

function ListBoxTest(
    name,
    options,
    activation_func,
    cleanup_func,
    repopulate_active_func,
    repopulate_inactive_func,
    double_click_func)

  --------------------------------------------------
  -- Keyboard input
  --------------------------------------------------

  --[[
    * If the scrollbar is not enabled, the view should not scroll.
    * Up Arrow
      * If there is no selection, selects the last item and scrolls it
        into view.
      * Otherwise, selects the previous item and scrolls it into view.
    * Down Arrow
      * If there is no selection, selects the first item and scrolls
        it into view.
      * Otherwise, selects the next item and scrolls it into view.
    * Apple+Up Arrow
      * Scrolls one page up.
      * Selection is not changed.
    * Apple+Down Arrow
      * Scrolls one down up.
      * Selection is not changed.
    * Open-Apple+Solid-Apple+Up Arrow
      * Scrolls the view so that the first item is visible.
      * Selects the first item.
    * Open-Apple+Solid-Apple+Down Arrow
      * Scrolls the view so that the last item is visible.
      * Selects the last item.
  ]]

  test.Step(
    name .. " - keyboard input",
    function()

      -- Up Arrow
      activation_func()

      -- Need for later
      local _, vopt = a2dtest.GetFrontWindowScrollOptions()

      if not options.starts_with_selection then
        apple2.UpArrowKey()
        a2d.WaitForRepaint()
        test.Snap("verify last item selected")
        apple2.UpArrowKey()
        a2d.WaitForRepaint()
        test.Snap("verify next-to-last item selected")
      else
        apple2.UpArrowKey()
        a2d.WaitForRepaint()
        test.Snap("verify first item still selected")
      end
      cleanup_func()

      -- Down Arrow
      activation_func()
      if not options.starts_with_selection then
        apple2.DownArrowKey()
        a2d.WaitForRepaint()
        test.Snap("verify first item selected")
      end
      apple2.DownArrowKey()
      a2d.WaitForRepaint()
      test.Snap("verify second item selected")
      cleanup_func()

      if (vopt & mgtk.scroll.option_active) ~= 0 then
        -- scroll bar active

        -- Apple+Up Arrow
        -- Apple+Down Arrow
        activation_func()
        a2d.OADown()
        a2d.WaitForRepaint()
        if not options.starts_with_selection then
          test.Snap("verify scrolled down a page, no selection")
        else
          test.Snap("verify first item still selected")
        end
        a2d.OAUp()
        a2d.WaitForRepaint()
        if not options.starts_with_selection then
          test.Snap("verify scrolled up a page, no selection")
        else
          test.Snap("verify first item still selected")
        end
        cleanup_func()

        activation_func()
        if not options.starts_with_selection then
          apple2.DownArrowKey()
        end
        a2d.OADown()
        a2d.WaitForRepaint()
        test.Snap("verify scrolled down a page, first item selected (not visible)")
        a2d.OAUp()
        a2d.WaitForRepaint()
        test.Snap("verify scrolled up a page, first item selected")
        cleanup_func()

        -- OA+SA+Up Arrow
        -- OA+SA+Down Arrow
        activation_func()
        a2d.OASADown()
        a2d.WaitForRepaint()
        test.Snap("verify last item selected and scrolled to bottom")
        a2d.OASAUp()
        a2d.WaitForRepaint()
        test.Snap("verify first item selected and scrolled to top")
        cleanup_func()

      else
        -- scroll bar inactive

        -- Apple+Up Arrow
        -- Apple+Down Arrow
        activation_func()
        a2d.OADown()
        a2d.OAUp()
        if not options.starts_with_selection then
          test.Snap("verify no selection, no scroll")
        else
          test.Snap("verify no scroll")
        end

        if not options.starts_with_selection then
          apple2.DownArrowKey()
        end
        a2d.OADown()
        a2d.OAUp()

        test.Snap("verify first item selected, no scroll")
        cleanup_func()

        -- OA+SA+Up Arrow
        -- OA+SA+Down Arrow
        activation_func()
        a2d.OASADown()
        a2d.WaitForRepaint()
        test.Snap("verify last item selected")
        a2d.OASAUp()
        a2d.WaitForRepaint()
        test.Snap("verify first item selected")
        cleanup_func()
      end
  end)

  --------------------------------------------------
  -- Mouse input
  --------------------------------------------------

  --[[
    * Hold down the mouse button on the scrollbar's up arrow or down
      arrow; verify that the scrolling continues as long as the button
      is held down.
    * Click on an item. Verify it is selected. Click on white space
      below the items (if possible). Verify that selection is cleared.
  ]]

  test.Step(
    name .. " - mouse input",
    function()
      activation_func()

      local _, vopt = a2dtest.GetFrontWindowScrollOptions()
      local x, y, w, h = a2dtest.GetFrontWindowContentRect()

      if (vopt & mgtk.scroll.option_active) ~= 0 then
        -- scroll bar active

        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w + 5, y + h - 5)
            m.ButtonDown()
            emu.wait(10)
            m.ButtonUp()
        end)
        test.Snap("verify scrolled to bottom")

        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w + 5, y + 5)
            m.ButtonDown()
            emu.wait(10)
            m.ButtonUp()
        end)
        test.Snap("verify scrolled to top")

      else
        -- scroll bar inactive

        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w + 5, y + h - 5)
            m.Click()
        end)
        test.Snap("verify nothing happened")

        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w + 5, y + 5)
            m.Click()
        end)
        test.Snap("verify nothing happened")

      end

      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(x + w / 2, y + 5)
          m.Click()
      end)
      test.Snap("verify first item selected")

      if (vopt & mgtk.scroll.option_active) == 0 then
        -- scroll bar inactive
        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w / 2, y + h - 5)
            m.Click()
        end)
        test.Snap("verify selection cleared or last item selected")
      end


      cleanup_func()
  end)

  --------------------------------------------------
  -- Repopulating
  --------------------------------------------------

--[[

  Repeat for each list box where the contents are dynamic:

  * Populate the list so that the scrollbar is active. Scroll down by
    one row. Repopulate the list box so that the scrollbar is
    inactive. Verify that all expected items are shown, and hitting
    the Up Arrow key selects the last item.

  * Populate the list so that the scrollbar is active, and scrolled to
    the top. Repopulate the list so that the scrollbar is still
    active. Verify that the scrollbar doesn't repaint/flicker. (This
    is easiest in the Shortcuts > Add a Shortcut File Picker.)

]]

  if repopulate_inactive_func then
    test.Step(
      name .. " - repopulating inactive",
      function()
        activation_func()
        local _, vopt = a2dtest.GetFrontWindowScrollOptions()
        test.Expect(vopt & mgtk.scroll.option_active ~= 0, "scrollbar should be active")

        -- click last item
        local x, y, w, h = a2dtest.GetFrontWindowContentRect()
        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w / 2, y + h - 5)
            m.Click()
        end)
        -- scroll down by one row
        apple2.DownArrowKey()
        a2d.WaitForRepaint()

        repopulate_inactive_func()

        local _, vopt = a2dtest.GetFrontWindowScrollOptions()
        test.Expect(vopt & mgtk.scroll.option_active == 0, "scrollbar should be inactive")
        apple2.UpArrowKey()
        test.Snap("verify last item selected")

        cleanup_func()
    end)
  end

  if repopulate_active_func then
    test.Step(
      name .. " - repopulating active",
      function()
        activation_func()
        local _, vopt = a2dtest.GetFrontWindowScrollOptions()
        test.Expect(vopt & mgtk.scroll.option_active ~= 0, "scrollbar should be active")

        a2dtest.DHRDarkness()

        repopulate_active_func()

        test.Snap("verify scrollbar did not repaint")
        -- BUG: They do seem to be repainting!

        cleanup_func()
        a2d.Reboot()
        a2d.WaitForDesktopReady()
    end)
  end

  --------------------------------------------------
  -- Double-Click
  --------------------------------------------------

  --[[
    If the list box supports double-click:

    * Double-click an item. Verify that the corresponding action
      button flashes.
  ]]

  if double_click_func then
    test.Step(
      name .. " - double-click",
      function()
        activation_func()
        -- double-click first item
        local x, y, w, h = a2dtest.GetFrontWindowContentRect()
        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w / 2, y + 5)
            m.DoubleClick()
            test.Snap("verify action button flashes")
        end)

        double_click_func()
    end)
  end

end

ListBoxTest(
  "File Picker - many items",
  {},
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
  end,
  function()
    -- repopulate_active_func
    apple2.PressOA()
    apple2.Type("SAMPLE.MEDIA")
    apple2.ReleaseOA()
    apple2.ControlKey("O")
    emu.wait(10)
  end,
  function()
    -- repopulate_inactive_func
    apple2.ControlKey("D") -- Drives
    emu.wait(5)
  end
  -- no double_click_func, redundant & hard to get predictable item first
)

ListBoxTest(
  "File Picker - few items",
  {},
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    apple2.ControlKey("D") -- Drives
    emu.wait(5)
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
  end,
  nil, -- no repopulate_active proc, redundant
  nil, -- no repopulate_inactive proc, redundant
  function()
    -- double_click_func
    emu.wait(5)
    a2d.DialogCancel()
    emu.wait(5)
  end
)

ListBoxTest(
  "Disk Copy",
  {},
  function()
    a2d.CopyDisk()
    a2dtest.ConfigureForDiskCopy()
    emu.wait(10)
  end,
  function()
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
  end,
  nil, -- no repopulate_active proc, tricky
  nil, -- no repopulate_inactive proc, tricky
  function()
    -- double_click_func
    a2d.OAShortcut("Q")
    a2dtest.ConfigureForDeskTop()
    a2d.WaitForDesktopReady()
  end
)

ListBoxTest(
  "Sounds DA",
  {
    starts_with_selection = true
  },
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SOUNDS")
  end,
  function()
    a2d.DialogCancel()
  end
)

ListBoxTest(
  "Find Files DA - many items",
  {},
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("*")
    a2d.DialogOK()
    emu.wait(10)
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
  end,
  function()
    -- repopulate_active_func
    apple2.Type("*")
    a2d.DialogOK()
    emu.wait(10)
  end,
  function()
    -- repopulate_inactive_func
    apple2.Type("CA*")
    a2d.DialogOK()
    emu.wait(10)
  end
  -- no double_click_proc since it doesn't flash a button
)

ListBoxTest(
  "Find Files DA - few items",
  {},
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("CA*")
    a2d.DialogOK()
    emu.wait(10)
  end,
  function()
    a2d.DialogCancel()
    emu.wait(5)
  end
  -- no repopulate_active proc, redundant
  -- no repopulate_inactive proc, redundant
  -- no double_click_proc, redundant
)

ListBoxTest(
  "DOS 3.3 Import DA - Drives",
  {},
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/DOS33.IMPORT")
    emu.wait(5)
  end,
  function()
    a2d.DialogCancel()
  end,
  nil, -- no repopulate_active proc, tricky
  nil, -- no repopulate_inactive proc, tricky
  function()
    -- double_click_func
    emu.wait(5)
    a2d.DialogCancel()
  end
)

ListBoxTest(
  "DOS 3.3 Import DA - Catalog",
  {},
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/DOS33.IMPORT")
    emu.wait(5)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
  end,
  function()
    a2d.DialogCancel()
  end,
  nil, -- no repopulate_active proc, tricky
  nil, -- no repopulate_inactive proc, tricky
  function()
    -- double_click_func
    a2d.DialogCancel()
  end
)
