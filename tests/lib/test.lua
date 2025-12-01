--[[============================================================

  Test Utilities

  ============================================================]]--

local test = {}

local test_name = emu.subst_env("$TEST_NAME")
test.count = 0

local snapnum = -1

function snap(message)
  manager.machine.video:snapshot()
  snapnum = snapnum + 1
  if message ~= nil then
    print(string.format("[snap: %04d] %s", snapnum, message))
  end
end

--------------------------------------------------

-- test.Step("do a thing", function() ... end)
function test.Step(title, func)
  if test_name ~= "" and test_name ~= title then
    return
  end
  test.count = test.count+1

  print("-- " .. title)
  local status, err = pcall(func)
  if not status then
    test.Failure(err)
  end
end

-- test.Variants({"v1", "v2"}, function(idx) ... end}
function test.Variants(t, func)
  for idx, name in pairs(t) do
    test.Step(name, function() return func(idx) end)
  end
end

function test.Failure(message)
  print(message)
  os.exit(1)
end

function test.Snap(opt_title)
  snap(opt_title)
end

function test.MultiSnap(frames, opt_title)
  for i=1,frames do
    snap(opt_title)
    emu.wait(1/60)
  end
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

function test.ExpectLessThan(a, b, message)
  test.Expect(a < b, message .. " - " .. a .. " should be < " .. b)
end

function test.ExpectLessThanOrEqual(a, b, message)
  test.Expect(a <= b, message .. " - " .. a .. " should be <= " .. b)
end

--------------------------------------------------

return test
