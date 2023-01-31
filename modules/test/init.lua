local json = require "dkjson"

local test = {}

test.load = function (path)
  assert(os.execute("cat '" .. path .. "' | redis-cli -x FUNCTION LOAD REPLACE > /dev/null"))
end

test.unload = function (name)
  assert(os.execute("redis-cli FUNCTION DELETE '" .. name .. "' > /dev/null"))
end

test.fcall = function (fname, nkeys, ...)
  local args = table.concat({fname, nkeys, ...}, " ")
  local proc = io.popen("redis-cli --json FCALL " .. args)
  local out = proc:read("*all")
  assert(proc:close())
  return json.decode(out)
end

return test
