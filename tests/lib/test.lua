--[[============================================================

  Test Utilities

  ============================================================]]--

local test = {}

local test_name = emu.subst_env("$TEST_NAME")
-- Convert from "wildcard" pattern (with * and ?) to Lua pattern
local test_patterns = {}
for chunk in test_name:gmatch("([^|]+)") do
  local pattern  = "^" ..
  string.gsub(
    chunk, "([%^$()%%.%[%]*+%-?])", -- pattern special characters
    function(s)
      if s == "*" then
        return ".*"
      elseif s == "?" then
        return "."
      else
        return "%" .. s
      end
  end) .. "$"
  table.insert(test_patterns, pattern)
end

test.count = 0

local snapnum = -1

local function snap(message)
  manager.machine.video:snapshot()
  snapnum = snapnum + 1
  if message ~= nil then
    print(string.format("[snap: %04d] %s", snapnum, message))
  end
end

--------------------------------------------------

-- test.Step("do a thing", function() ... end)
function test.Step(title, func)
  if #test_patterns > 0 then
    local match = false
    for i,pattern in ipairs(test_patterns) do
      if string.match(title, pattern) then
        match = true
        break
      end
    end
    if not match then
      return
    end
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
    test.Step(name, function() return func(idx, name) end)
  end
end

function test.Failure(message)
  print(message)
  os.exit(1)
end

--------------------------------------------------
-- Snapshots
--------------------------------------------------

function test.Snap(opt_title)
  snap(opt_title)
end

--------------------------------------------------
-- Expectations
--------------------------------------------------

local function inc(level)
  if level then
    return level + 1
  else
    return 1
  end
end


function test.Expect(expr, message, options, level)
  if not expr then
    if options and options.snap then
      test.Snap("FAILURE - " .. message)
    end
    error("Expectation failure: " .. message, inc(inc(level)))
  end
end

local function format(value)
  if type(value) == "string" then
    return string.format("%q", value)
  elseif type(value) == "boolean" then
    return value and "true" or "false"
  else
    return value
  end
end

function test.ExpectEquals(actual, expected, message, options, level)
  test.Expect(actual == expected, message .. " - actual " .. format(actual) .. " should equal " .. format(expected), options, inc(level))
end

function test.ExpectEqualsIgnoreCase(actual, expected, message, options, level)
  test.Expect(actual:lower() == expected:lower(), message .. " - actual " .. format(actual) .. " should equal " .. format(expected), options, inc(level))
end

function test.ExpectNotEquals(actual, expected, message, options, level)
  test.Expect(actual ~= expected, message .. " - actual " .. format(actual) .. " should not equal " .. format(expected), options, inc(level))
end

function test.ExpectLessThan(a, b, message, options, level)
  test.Expect(a < b, message .. " - actual " .. format(a) .. " should be < " .. format(b), options, inc(level))
end

function test.ExpectLessThanOrEqual(a, b, message, options, level)
  test.Expect(a <= b, message .. " - actual " .. format(a) .. " should be <= " .. format(b), options, inc(level))
end

function test.ExpectGreaterThan(a, b, message, options, level)
  test.Expect(a > b, message .. " - actual " .. format(a) .. " should be > " .. format(b), options, inc(level))
end

function test.ExpectGreaterThanOrEqual(a, b, message, options, level)
  test.Expect(a >= b, message .. " - actual " .. format(a) .. " should be >= " .. format(b), options, inc(level))
end

function test.ExpectError(pattern, func, message, options, level)
  local status, err = pcall(func)
  test.Expect(not status, "saw no error; " .. message, options, inc(level))
  test.Expect(string.match(err, pattern), message .. ", error was: " .. err, options, inc(level))
end

--------------------------------------------------

return test
