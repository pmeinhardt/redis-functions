local json = require "dkjson"

local test = {}

test.load = function (path)
  assert(os.execute("cat '" .. path .. "' | redis-cli -x FUNCTION LOAD REPLACE > /dev/null"))
end

test.unload = function (name)
  assert(os.execute("redis-cli FUNCTION DELETE '" .. name .. "' > /dev/null"))
end

test.invoke = function (...)
  -- note: we're not quoting arguments or escaping whitespace
  local command = table.concat({"redis-cli", "-e", ...}, " ")

  local process = io.popen(command .. " 2>&1")
  local output = process:read("*all")
  local ok, reason, code = process:close()

  assert(ok, string.format("(%q, %q) %s", reason, code, output))

  return output
end

test.fcall = function (fname, nkeys, ...)
  local out = test.invoke("--json", "FCALL", fname, nkeys, ...)

  if string.sub(out, 1, 6) == "error:" then
    error(string.sub(out, 7))
  end

  return json.decode(out)
end

return test
