describe("Referer plugin (unit)", function()
  local handler

  setup(function()
    _G._TEST = true
    handler = require("kong.plugins.referer.handler")
  end)


  teardown(function()
    _G._TEST = nil
  end)


  it("validates a list of domains", function()
    function test(conf, referer)
      conf = handler._config_cache[{referers = conf}]  -- make sure to do pattern conversion
      return handler._testListReferer(conf.referers, referer)
    end

    assert.is_true(test({"example", }, "http://example/plan"))
    assert.is_true(test({"example.com", }, "http://example.com/lolll"))
    assert.is_true(test({"www.example.com"}, "http://www.example.com"))
    assert.is_false(test({"example.com"}, "http://www.example.com"))
    assert.is_false(test({"www.example.com"}, "http://ws.example.com"))
    assert.is_false(test({"example.com"}, "http://exampleXcom"))
    assert.is_false(test({"example.com"}, ""))

    assert.is_true(test({"example", }, "https://example/plan"))
    assert.is_true(test({"example.com", }, "https://example.com/lolll"))
    assert.is_true(test({"www.example.com"}, "https://www.example.com"))
    assert.is_false(test({"example.com"}, "https://www.example.com"))
    assert.is_false(test({"www.example.com"}, "https://ws.example.com"))
    assert.is_false(test({"example.com"}, "https://exampleXcom"))
  end)


  it("validates a list of wildcards", function()
    function test(conf, referer)
      conf = handler._config_cache[{referers = conf}]  -- make sure to do pattern conversion
      return handler._testListReferer(conf.referers, referer)
    end

    assert.is_true(test({"*"}, "http://ws.example.com"))
    assert.is_true(test({"*.example.com"}, "http://ws.example.com"))
    assert.is_true(test({"*.example.com"}, "http://ws.example.com/with/path"))
    assert.is_false(test({"*.example.com"}, "http://example.com"))
    assert.is_false(test({"*.example.com"}, "http://a.b.example.com"))
    assert.is_false(test({"*.example.com"},   "http://a.example.com.evil.com"))
    assert.is_true(test({"a.*.example.com"}, "http://a.bc.example.com"))
    assert.is_false(test({"a.*.example.com"}, "http://b.bc.example.com"))
    assert.is_false(test({"a.*.example.com"}, "http://a..example.com"))
    assert.is_false(test({"*"}, ""))
    assert.is_false(test({"*.example.com"}, ""))

    assert.is_true(test({"*"}, "https://ws.example.com"))
    assert.is_true(test({"*.example.com"}, "https://ws.example.com"))
    assert.is_true(test({"*.example.com"}, "https://ws.example.com/with/path"))
    assert.is_false(test({"*.example.com"}, "https://example.com"))
    assert.is_false(test({"*.example.com"}, "https://a.b.example.com"))
    assert.is_false(test({"*.example.com"},   "https://a.example.com.evil.com"))
    assert.is_true(test({"a.*.example.com"}, "https://a.bc.example.com"))
    assert.is_false(test({"a.*.example.com"}, "https://b.bc.example.com"))
    assert.is_false(test({"a.*.example.com"}, "https://a..example.com"))
  end)

end)



