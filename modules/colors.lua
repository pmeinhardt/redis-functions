#!lua name=colors

local errors = {
  nargs = "ERR wrong number of arguments",
  nkeys = "ERR wrong number of keys",
}

local function rgba2n (r, g, b, a)
  return bit.bor(bit.lshift(r, 24), bit.lshift(g, 16), bit.lshift(b, 8), a)
end

local function n2rgba (n)
  local r = bit.rshift(bit.band(n, 0xff000000), 24)
  local g = bit.rshift(bit.band(n, 0x00ff0000), 16)
  local b = bit.rshift(bit.band(n, 0x0000ff00), 8)
  local a = bit.band(n, 0x000000ff)
  return r, g, b, a
end

local function rgb2n (r, g, b)
  return rgba2n(r, g, b, 255)
end

local function n2rgb (n)
  local r, g, b, _ = n2rgba(n)
  return r, g, b
end

local function setrgba (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args > 4 then return redis.error_reply(errors.nargs) end
  local r, g, b, a = args[1] or 0, args[2] or 0, args[3] or 0, args[4] or 255
  return redis.call("SET", keys[1], rgba2n(r, g, b, a))
end

local function getrgba (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args > 0 then return redis.error_reply(errors.nargs) end
  local n = redis.call("GET", keys[1])
  if not n then return nil end
  return {n2rgba(n)}
end

local function setrgb (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args > 3 then return redis.error_reply(errors.nargs) end
  local r, g, b = args[1] or 0, args[2] or 0, args[3] or 0
  return redis.call("SET", keys[1], rgb2n(r, g, b))
end

local function getrgb (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args > 0 then return redis.error_reply(errors.nargs) end
  local n = redis.call("GET", keys[1])
  if not n then return nil end
  return {n2rgb(n)}
end

-- More ideas:
--
-- Validate input value range 0-255
--
-- Add h* variants for storing color values in Redis hashes
--
-- Getting and setting via other color spaces (HSL, HSV, …)
--
-- Support CSS color formats:
-- https://developer.mozilla.org/en-US/docs/Web/CSS/color
--
-- #rgb, #rrggbb, #rgba, #rrggbbaa, rgb(…), …, named colors
-- (https://developer.mozilla.org/en-US/docs/Web/CSS/named-color)
--
-- Retrieve with a format specifier? #, #a, rgb(), rgba(), hsl(), hsla(), …
--
-- Support color manipulation: darken, lighten, adjust opacity, …, shift

local prefix = "c"

redis.register_function(prefix .. "setrgba", setrgba)
redis.register_function(prefix .. "getrgba", getrgba)
redis.register_function(prefix .. "setrgb", setrgb)
redis.register_function(prefix .. "getrgb", getrgb)
