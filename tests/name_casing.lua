--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/gsos_floppy.dsk"

======================================== ENDCONFIG ]]--

-- Helpers, since we can only toggle the flag
local preserve_flag = true -- default state in config
function EnablePreserve()
  if not preserve_flag then
    a2d.ToggleOptionPreserveCase()
    preserve_flag = not preserve_flag
  end
end
function DisablePreserve()
  if preserve_flag then
    a2d.ToggleOptionPreserveCase()
    preserve_flag = not preserve_flag
  end
end

test.Step(
  "GS/OS volume name cases show correctly",
  function()
    a2d.OpenPath("/GS.OS.MIXED")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "GS.OS.mixed", "case should be shown")
end)

test.Step(
  "GS/OS file name cases show correctly",
  function()
    a2d.OpenPath("/TESTS/PROPERTIES/GS.OS.NAMES")
    test.Snap("verify name cases are correct")
end)

test.Step(
  "AppleWorks file name cases show correctly",
  function()
    a2d.OpenPath("/TESTS/PROPERTIES/AW.NAMES")
    test.Snap("verify name cases are correct")
end)

test.Variants(
  {
    "AppleWorks files rename with case preservation - preserve off",
    "AppleWorks files rename with case preservation - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end

    a2d.CopyPath("/TESTS/PROPERTIES/AW.NAMES/LOWER.UPPER.SS", "/RAM1")
    a2d.RenamePath("/RAM1/LOWER.UPPER.SS", "UP.lo.MiXeD")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/UP.LO.MIXED")
    test.Snap("verify selected file is 'UP.lo.MiXeD'")

    -- Note that behavior is the same regardless of flag state; this
    -- is because AppleWorks files have case bits stored in auxtype
    -- which is not optional, unlike GS/OS case bits.

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

test.Variants(
  {
    "AppleWorks files duplicate with case preservation - preserve off",
    "AppleWorks files duplicate with case preservation - preserve on",
  },
  function()
    if idx == 1 then DisablePreserve() else EnablePreserve() end

    a2d.CopyPath("/TESTS/PROPERTIES/AW.NAMES/LOWER.UPPER.SS", "/RAM1")
    a2d.DuplicatePath("/RAM1/LOWER.UPPER.SS", "UP.lo.MiXeD")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/UP.LO.MIXED")
    test.Snap("verify selected file is 'UP.lo.MiXeD'")

    -- Note that behavior is the same regardless of flag state; this
    -- is because AppleWorks files have case bits stored in auxtype
    -- which is not optional, unlike GS/OS case bits.

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

test.Variants(
  {
    "File > New Folder - preserve off",
    "File > New Folder - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.OpenPath("/RAM1")
    a2d.OAShortcut("N") -- File > New Folder
    apple2.ControlKey("X") -- clear
    apple2.Type("lower.UPPER.MiX")
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.Snap("verify selected file is '"..expected.."'")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.Snap("verify selected file is '"..expected.."'")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

test.Variants(
  {
    "File > Rename - preserve off",
    "File > Rename - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.RenamePath("/RAM1/READ.ME", "lower.UPPER.MiX")
    test.Snap("verify selected file is '"..expected.."'")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.Snap("verify selected file is '"..expected.."'")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

test.Variants(
  {
    "File > Duplicate - preserve off",
    "File > Duplicate - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.DuplicatePath("/RAM1/READ.ME", "lower.UPPER.MiX")
    test.Snap("verify selected file is '"..expected.."'")
    a2d.CloseAllWindows()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    test.Snap("verify selected file is '"..expected.."'")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

test.Variants(
  {
    "Format - preserve off",
    "Format - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.FormatVolume("RAM1", "lower.UPPER.MiX")
    a2d.OpenPath("/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), expected, "volume name should be " .. expected)

    -- cleanup
    a2d.EraseVolume("LOWER.UPPER.MIX", "RAM1")
end)

test.Variants(
  {
    "Erase - preserve off",
    "Erase - preserve on",
  },
  function(idx)
    if idx == 1 then DisablePreserve() else EnablePreserve() end
    local expected
    if idx == 1 then
      expected = "Lower.Upper.Mix"
    else
      expected = "lower.UPPER.MiX"
    end

    a2d.EraseVolume("RAM1", "lower.UPPER.MiX")
    a2d.OpenPath("/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), expected, "volume name should be " .. expected)

    -- cleanup
    a2d.EraseVolume("LOWER.UPPER.MIX", "RAM1")
end)

test.Step(
  "Canceled rename",
  function()
    EnablePreserve()
    a2d.OpenPath("/RAM1")
    a2d.OAShortcut("N") -- File > New Folder
    apple2.ControlKey("X") -- Clear
    apple2.Type("lower.UPPER.MiX")
    apple2.ReturnKey()
    DisablePreserve()
    a2d.SelectPath("/RAM1/LOWER.UPPER.MIX")
    apple2.ReturnKey() -- File > Rename
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0,0)
        m.Click()
    end)
    a2d.WaitForRepaint()

    a2d.OpenPath("/RAM1/LOWER.UPPER.MIX")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "Lower.Upper.Mix", "rename should use heuristic case")

    a2d.EraseVolume("RAM1")
end)

local kVolIconDeltaY = 29
local vol_icon1_x, vol_icon1_y = 520, 25 -- A2.DESKTOP
local vol_icon2_x, vol_icon2_y = vol_icon1_x, vol_icon1_y + kVolIconDeltaY*1 -- TESTS
local vol_icon3_x, vol_icon3_y = vol_icon1_x, vol_icon1_y + kVolIconDeltaY*2 -- RAM1
local vol_icon4_x, vol_icon4_y = vol_icon1_x, vol_icon1_y + kVolIconDeltaY*3 -- GS.OS.MIXED

test.Variants(
  {
    "drag - copy to another volume",
    "drag - move on same volume",
    "drag - move to another volume", -- Uses "real" mouse, too imprecise
    "drag - copy to same volume", -- Uses "real" mouse, too imprecise
  },
  function(idx)
    EnablePreserve()
    a2d.OpenPath("/RAM1")
    a2d.OAShortcut("N") -- File > New Folder
    apple2.ControlKey("X") -- Clear
    apple2.Type("lower.UPPER.MiX")
    apple2.ReturnKey()

    local window_x, window_y = a2dtest.GetFrontWindowContentRect()
    local path
    if idx == 1 then
      -- Copy to another volume
      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(window_x + 35, window_y + 23)
          m.ButtonDown()
          m.MoveToApproximately(vol_icon4_x, vol_icon4_y)
          m.ButtonUp()
      end)
      a2d.WaitForRepaint()

      path = "/GS.OS.MIXED/LOWER.UPPER.MIX"
    elseif idx == 2  then
      -- Move on same volume
      a2d.OpenPath("/RAM1")
      a2d.OAShortcut("N") -- File > New Folder
      apple2.ControlKey("X") -- Clear
      apple2.Type("ANOTHER.FOLDER")
      apple2.ReturnKey()

      a2d.InMouseKeysMode(function(m)
          m.MoveToApproximately(window_x + 45, window_y + 23)
          m.ButtonDown()
          m.MoveByApproximately(80, 0)
          m.ButtonUp()
      end)
      a2d.WaitForRepaint()

      path = "/RAM1/ANOTHER.FOLDER/LOWER.UPPER.MIX"
    elseif idx == 3 then
      -- Move to another volume

      a2d.InMouseKeysMode(function(m)
          apple2.PressSA()
          m.MoveToApproximately(window_x + 35, window_y + 23)
          m.ButtonDown()
          m.MoveToApproximately(vol_icon4_x, vol_icon4_y)
          m.ButtonUp()
          apple2.ReleaseSA()
      end)
      a2d.WaitForRepaint()

      path = "/GS.OS.MIXED/LOWER.UPPER.MIX"
    elseif idx == 4 then
      -- Copy on same volume
      a2d.OpenPath("/RAM1")
      a2d.OAShortcut("N") -- File > New Folder
      apple2.ControlKey("X") -- Clear
      apple2.Type("ANOTHER.FOLDER")
      apple2.ReturnKey()

      a2d.InMouseKeysMode(function(m)
          apple2.PressSA()
          m.MoveToApproximately(window_x + 45, window_y + 23)
          m.ButtonDown()
          m.MoveByApproximately(80, 0)
          m.ButtonUp()
          apple2.ReleaseSA()
      end)
      a2d.WaitForRepaint()

      path = "/RAM1/ANOTHER.FOLDER/LOWER.UPPER.MIX"
    end

    a2d.OpenPath(path)
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "lower.UPPER.MiX", "move should retain case")
    a2d.DeletePath(path)
    a2d.EraseVolume("RAM1")
end)

test.Step(
  "Copy one volume to another",
  function()
    EnablePreserve()
    a2d.RenamePath("/GS.OS.MIXED", "vol1.MIXED")
    a2d.RenamePath("/RAM1", "VOL2.mixed")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon4_x, vol_icon4_y)
        m.ButtonDown()
        m.MoveToApproximately(vol_icon3_x, vol_icon3_y)
        m.ButtonUp()
    end)
    a2d.WaitForRestart() -- let copy from floppy complete

    a2d.OpenPath("/VOL2.MIXED/VOL1.MIXED")
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "vol1.MIXED", "vol copy should retain case")
end)

