#!lua name=hello

-- Hello, World!
--
-- Say hi:
--
--   FCALL hello 0 [name=World]
--

local function hello (keys, args)
  local name = args[1] or "World"
  return  "Hello, " .. name .. "!"
end

redis.register_function("hello", hello)
