local helpers = require "spec.helpers"

local PLUGIN_NAME = "referer"

for _, strategy in helpers.each_strategy() do
  describe("Referer plugin (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      do -- create a route with referer plugin
        local route1 = bp.routes:insert({
          hosts = { "test1.com" },
        })

        bp.plugins:insert {
          name = PLUGIN_NAME,
          route = { id = route1.id },
          config = {
            referers = { "*.kong.com", "hello.mashape.com" },
          },
        }
      end

      do -- create a route with referer plugin, with wildcard only
        local route2 = bp.routes:insert({
          hosts = { "test2.com" },
        })

        bp.plugins:insert {
          name = PLUGIN_NAME,
          route = { id = route2.id },
          config = {
            referers = { "*" } ,
          },
        }
      end

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database = strategy,
        -- -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- set the config item to make sure our plugin gets loaded
        plugins = "bundled,referer",         -- since Kong CE 0.14
        -- custom_plugins = "referer",          -- pre Kong CE 0.14
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)


    describe("request", function()

      it("succeeds with valid referer header, wildcard", function()
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test1.com",
            referer = "http://hello.kong.com",  -- *.kong.com
          }
        })
        assert.response(r).has.status(200)
      end)


      it("fails with invalid referer header, wildcard", function()
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test1.com",
            referer = "http://another.hello.kong.com",  -- *.kong.com
          }
        })
        assert.response(r).has.status(403)
      end)


      it("succeeds with valid referer header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test1.com",
            referer = "http://hello.mashape.com",  -- hello.mashape.com
          }
        })
        assert.response(r).has.status(200)
      end)

    end)


    describe("pattern '*' request", function()
      it("succeeds with valid referer header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test2.com",
            referer = "http://my.domain.com",
          }
        })
        assert.response(r).has.status(200)
      end)


      it("fails with multiple referer headers", function()
        -- first validate that a single will pass
        local referer = "http://first.kong.com"
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test2.com",
            referer = referer,
          }
        })
        assert.response(r).has.status(200)

        -- now use the same referrer twice
        r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test2.com",
            referer = { referer, referer },
          }
        })
        assert.response(r).has.status(403)
      end)


      it("fails with empty referer header", function()
        local referer = ""
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test2.com",
            referer = referer,
          }
        })
        assert.response(r).has.status(403)
      end)


      it("fails with no referer header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test2.com",
            referer = nil,  -- for explicitness
          }
        })
        assert.response(r).has.status(403)
      end)

      it("succeeds with no referer header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/",
          headers = {
            host = "test2.com",
            referer = nil,  -- for explicitness
          }
        })
        assert.response(r).has.status(403)
      end)

    end)

  end)

end
