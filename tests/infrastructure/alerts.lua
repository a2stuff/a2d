
test.Step(
  "waiting for alert",
  function()
    test.ExpectError(
      "Timeout %(60s%) waiting for alert",
      function()
        a2dtest.WaitForAlert()
      end,
      "alert should timeout")
    test.ExpectError(
      "Timeout %(5s%) waiting for alert",
      function()
        a2dtest.WaitForAlert({timeout=5})
      end,
      "alert should timeout")
end)
