--[[============================================================

  Test Utilities

  ============================================================]]--

local test = {
  PASS = 1,
  FAIL = 0,
}

local test_name = emu.subst_env("$TEST_NAME")

--------------------------------------------------

-- TODO: Add assertion stuff here

-- test.Step("do a thing", function() ... end)
function test.Step(title, func)
  if test_name ~= "" and test_name ~= title then
    return
  end

  print("-- " .. title)
  if not func() then
    test.Failure("test \"" .. title .. "\" did not return success")
  end
end

function test.Failure(message)
  print("FAIL: " .. message)
  os.exit(1)
end

function test.Snap(opt_title)
  if opt_title ~= nil then
    print("--- " .. opt_title)
  end
  manager.machine.video:snapshot()
end

--------------------------------------------------

return test
