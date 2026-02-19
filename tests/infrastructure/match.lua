a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Case-sensitive",
  function()
    test.ExpectMatch("foo", "foo", "simple strings should match")
    test.ExpectMatch("foo", ".*o%S", "patterns should match")
    test.ExpectNotMatch("foo", "bar",  "should not match different strings")
    test.ExpectNotMatch("foo", "FOO",  "should not match different case")

    test.ExpectError(
      "Expectation failure", function()
        test.ExpectNotMatch("foo", "foo", "simple strings should match") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectNotMatch("foo", ".*o%S", "patterns should match") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectMatch("foo", "bar",  "should not match different strings") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectMatch("foo", "FOO",  "should not match different case") end,
      "negated match")
end)

test.Step(
  "Case-insensitive",
  function()
    test.ExpectIMatch("foo", "foo", "simple strings should match")
    test.ExpectIMatch("FOO", "FOO", "simple strings should match")
    test.ExpectIMatch("foo", ".*O%S", "patterns should match")
    test.ExpectNotIMatch("foo", "BAR",  "should not match different strings")
    test.ExpectIMatch("foo", "FOO",  "should match different case")
    test.ExpectIMatch("FOO", "foo",  "should match different case")

    test.ExpectError(
      "Expectation failure", function()
        test.ExpectNotIMatch("foo", "foo", "simple strings should match") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectNotIMatch("FOO", "FOO", "simple strings should match") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectNotIMatch("foo", ".*O%S", "patterns should match") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectIMatch("foo", "BAR",  "should not match different strings") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectNotIMatch("foo", "FOO",  "should not match different case") end,
      "negated match")
    test.ExpectError(
      "Expectation failure", function()
        test.ExpectNotIMatch("FOO", "foo",  "should not match different case") end,
      "negated match")
end)
