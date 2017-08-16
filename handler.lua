local ngx_get_headers = ngx.req.get_headers

local plugin = require("kong.plugins.base_plugin"):extend()

local function testReferer(refererConf, refererToTest)
  if refererConf == refererToTest then
    return true
  end

  local authorizedReferer = string.gsub(refererConf, "%.", "%%.")
  authorizedReferer = string.gsub(authorizedReferer, "*", "[^.]*")

  local test = string.match(refererToTest, authorizedReferer)
  if test == refererToTest then
    return true
  else
    return false
  end
end


local function testListReferer(listReferer, refererToTest)
  if refererToTest == "" or refererToTest == nil then
    return false
  end

  local domainRefererToTest = string.match(refererToTest, "^[https?]*[://]*([^/]+)")

  if domainRefererToTest == nil then
    return false
  end



  for index, valeur in ipairs(listReferer) do
    if valeur == "*" then
      return true
    end

    if testReferer(valeur, domainRefererToTest) == true then
      return true
    end
  end

  return false
end

local function doTestReferer(conf)
  local headers = ngx_get_headers()
  local refererOk = testListReferer(conf.referers, headers["Referer"])

  if not refererOk then
    return false, {status = 403, message = "Invalid referer"}
  end

  return true
end

-- constructor
function plugin:new()
  plugin.super.new(self, "referer")

end


---[[ runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  plugin.super.access(self)

  local ok, err = doTestReferer(conf)

  if not ok then
    return responses.send(err.status, err.message)
  end

end --]]


-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 1000

-- return our plugin object
return plugin
