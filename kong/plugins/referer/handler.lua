local LRU_SIZE = 1000   -- size of referer cache


local ngx_get_headers = ngx.req.get_headers
local responses = require "kong.tools.responses"
local lrucache = require "resty.lrucache"


local plugin = require("kong.plugins.base_plugin"):extend()


local function testReferer(refererConf, refererToTest)
  if refererConf == refererToTest then
    return true
  end

  local test = refererToTest:match(refererConf)
  if test == refererToTest then
    return true
  end
  return false
end


local function testListReferer(listReferer, refererToTest)
  local refererDomain = refererToTest:match("^https?://([^/]+)")
  if refererDomain == nil then
    return false
  end

  for _, value in ipairs(listReferer) do
    if testReferer(value, refererDomain) == true then
      return true
    end
  end

  return false
end


local function doTestReferer(conf)
  local header = ngx_get_headers()["Referer"]

  if type(header) == "string" then
    -- first check our cache
    local refererOk = conf.lru:get(header)
    if refererOk == nil then
      -- no result in our cache yet, so go match the string patterns
      refererOk = testListReferer(conf.referers, header)
      conf.lru:set(header, refererOk)
    end
    if refererOk then
      return true
    end
  end

  return false, {status = 403, message = "Invalid referer"}
end


-- We do not want to build patterns on each call, so build the patterns
-- once here, and reuse them.
-- Also add an LRU cache to not do string matching on each request
local config_cache
do
  local function prepareConfig(plugin_conf)
    local conf = {
      lru =  lrucache.new(LRU_SIZE),-- cache to bypass string matching on each request
      referers = {},                -- same referer list, but as string matching patterns
    }
    for i, referer in ipairs(plugin_conf.referers) do
      if referer == "*" then
        referer = "^.+$"
      else
        referer = referer:gsub("%.", "%%.")
        referer = referer:gsub("%-", "%%-")
        referer = referer:gsub("*", "[^.]+")
      end
      conf.referers[i] = referer
    end
    return conf
  end

  config_cache = setmetatable({}, {
    __mode = "k",
    __index = function(self, plugin_conf)
      -- we do not yet have a prepared plugin config, go create it
      self[plugin_conf] = prepareConfig(plugin_conf)
      return self[plugin_conf]
    end,
  })
end

-- constructor
function plugin:new()
  plugin.super.new(self, "referer")
end


-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  plugin.super.access(self)

  plugin_conf = config_cache[plugin_conf]

  local ok, err = doTestReferer(plugin_conf)
  if not ok then
    return responses.send(err.status, err.message)
  end

end


-- set the plugin priority, which determines plugin execution order
-- since this plugin is cheap, run it before auth plugins
plugin.PRIORITY = 1500

if _G._TEST then
  -- only export if we're testing
  plugin._testListReferer = testListReferer
  plugin._config_cache = config_cache
end

-- return our plugin object
return plugin
