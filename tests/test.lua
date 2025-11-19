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
  local status, err = pcall(func)
  if not status then
    test.Failure(err)
  end
end

function test.Failure(message)
  print(message)
  manager.machine.video:snapshot()
  os.exit(1)
end

function test.Snap(opt_title)
  if opt_title ~= nil then
    print("--- " .. opt_title)
  end
  manager.machine.video:snapshot()
end

function test.Expect(expr, message)
  if not expr then
    error("Expectation failure: " .. message)
  end
end

function test.ExpectEquals(actual, expected, message)
  test.Expect(actual == expected, message .. " - " .. actual .. " should equal " .. expected)
end

function test.ExpectNotEquals(actual, expected, message)
  test.Expect(actual ~= expected, message .. " - " .. actual .. " should not equal " .. expected)
end

--------------------------------------------------

return test
