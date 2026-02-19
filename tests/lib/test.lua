--[[============================================================

  Test Utilities

  ============================================================]]

local util = require("util")

local test = {}

local skip_count = emu.subst_env("$SKIP_COUNT")
if skip_count == "" then
  skip_count = 0
else
  skip_count = tonumber(skip_count)
end
local run_count = emu.subst_env("$RUN_COUNT")
if run_count == "" then
  run_count = nil
else
  run_count = tonumber(run_count)
end

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
local in_step_flag = false
function test.Step(title, func)
  if in_step_flag then
    error("test.Step() called within test.Step() - did you mean test.Snap()?", 2)
  end

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
  if skip_count > 0 then
    skip_count = skip_count - 1
    return
  end


  function handler(arg)
    if not arg:match("Expectation failure:") then
      --[[
        If this was not an expectation failure but another exception
        it represents either a bug in the test or a bug in one of the
        libraries. Append a full stack trace.
      ]]
      local traceback = debug.traceback(nil, 2)
      local fn1, st1 = traceback:match("\t%[C%]: in function '(.-)'(.-)\n\t%[C%]: in function '(.-)'")
      if fn1 and st1 then
        arg = arg .. "\ntraceback:" .. st1
      end
    end
    return arg
  end

  in_step_flag = true
  print("-- " .. title)
  local status, err = xpcall(func, handler)
  if not status then
    test.Failure(err)
  end
  in_step_flag = false

  if run_count then
    run_count = run_count - 1
    if run_count == 0 then
      os.exit(0)
    end
  end
end

-- test.Variants({"v1", "v2"}, function(idx) ... end}
function test.Variants(t, func)
  for idx, value in pairs(t) do
    if type(value) == "table" then
      test.Step(value[1], function() return func(idx, table.unpack(value)) end)
    elseif type(value) == "string" then
      test.Step(value, function() return func(idx, value) end)
    else
      error("Pass name or table (starting with name) to test.Variants")
    end
  end
end

function test.Failure(message)
  io.stderr:write(message .. "\n")
 os.exit(1)
end

-- For disabling a test while maintaining count/skip behavior
function test.DISABLED_Step(title, reason, func)
  test.Step(
    title,
    function()
      io.stderr:write(string.format("DISABLED: %s\n", reason))
  end)
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

function test.ExpectMatch(actual, pattern, message, options, level)
  test.Expect(actual:match(pattern), message .. " - actual " .. format(actual) .. " should match " .. format(pattern), options, inc(level))
end

function test.ExpectNotMatch(actual, pattern, message, options, level)
  test.Expect(not actual:match(pattern), message .. " - actual " .. format(actual) .. " should not match " .. format(pattern), options, inc(level))
end

function test.ExpectIMatch(actual, pattern, message, options, level)
  test.Expect(actual:match(util.CaseInsensitivePattern(pattern)), message .. " - actual " .. format(actual) .. " should match " .. format(pattern), options, inc(level))
end

function test.ExpectNotIMatch(actual, pattern, message, options, level)
  test.Expect(not actual:match(util.CaseInsensitivePattern(pattern)), message .. " - actual " .. format(actual) .. " should not match " .. format(pattern), options, inc(level))
end

function test.ExpectError(pattern, func, message, options, level)
  local status, err = pcall(func)
  test.Expect(not status, "saw no error; " .. message, options, inc(level))
  test.Expect(string.match(err, pattern), message .. ", error was: " .. err, options, inc(level))
end

function test.ExpectBinaryEquals(a, b, message, options, level)
  if a == b then
    return
  end
  test.Expect(#a == #b, message .. string.format(" - sizes differ %d vs. %d", #a, #b), options, inc(level))
  for i = 1, #a do
    local ba, bb = a:sub(i,i):byte(), b.sub(i,i):byte()
    test.Expect(ba == bb, message .. string.format(" - bytes differ at index %d - 0x%02X vs. 0x%02X", i, ba, bb))
  end
end

--------------------------------------------------

return test
