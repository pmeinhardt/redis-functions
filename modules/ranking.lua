#!lua name=ranking

-- Ranking with time-based tie-breaking
--
-- Members with equal scores are ordered by the time of when the score was last
-- updated, with members who achieved the score earlier being listed first.
--
-- Functions
--
--   FCALL rkincrby 1 key increment member
--   FCALL rkscore  1 key member
--   FCALL rkrank   1 key member
--   FCALL rkrange  1 key start stop
--
-- Complexity
--
--   rkincrby   O(log(N))
--   rkscore    O(1)
--   rkrank     O(log(N))
--   rkrange    O(log(N)+M)
--
--   N being the number of elements in the sorted set
--   M the number of elements returned
--
-- Underlying storage
--
--   Score and time values are encoded into Redis score values such that the
--   user score is encoded in the most significant digits while the time is
--   stored in the least significant digits, serving as a tie-breaker for
--   entries with equal user scores.
--
--   See `encode` and `decode`.
--
-- Limits
--
--   Time values:
--
--   minimum = params.time.min
--   maximum = minimum + (2^params.time.nbits - 1) / 10^params.time.scale
--
--   for the default parameters (with nbits=32, scale=0):
--
--   minimum = 1672531200 = 2023-01-01 00:00:00 UTC (as configured)
--   maximum = 5967498495 = 2159-02-07 06:28:15 UTC
--
--   Score values:
--
--   Redis stores sorted set scores as "double-precision" 64-bit floating point
--   values, represented as IEEE 754 floating point numbers on all their
--   supported architectures.
--
--   With this, integer values up to 2^53 (and down to -2^53) can be
--   represented accurately. Between 2^53 and 2^54, everything is multiplied by
--   2, so the representable numbers are the even ones.
--
--   https://en.wikipedia.org/wiki/Double-precision_floating-point_format
--
--   As a consequence, score + time values encoded to numbers less than -2^53
--   or greater than 2^53 have their time resolution reduced by a factor of 2
--   first, then 4 for even larger values… i.e. 2^53 == 2^53 + 1.
--
--   The limits for score values with full time resolution are:
--
--   minimum = params.score.min
--   maximum = minimum +
--             math.floor(2^(54 - params.time.nbits) / 10^params.score.scale)
--
--   for the default parameters (with scale=0, integer score values):
--
--   minimum = 0
--   maximum = 4194304
--
-- Trade-offs
--
--   Resolution of the timestamps used for tie-breaking is seconds by default.
--   You can choose to increase it up to microseconds resolution (see `TIME`),
--   setting params.time.scale and trading increased timestamp resolution for:
--
--   1. a reduced time range (if you keep params.time.nbits the same)
--   2. a reduced score value range (if you increase params.time.nbits)
--
--   Conversely, you can reduce timestamp resolution for:
--
--   1. a wider time range (keeping params.time.nbits unchanged)
--   2. a wider score range (reducing params.time.nbits)
--
--   You can shift the range of scores in which tie-breaking works with full
--   time resolution by adjusting params.score.min. If this range is too narrow
--   for you, you may choose to increase the minimum value, sacrificing time
--   resolution for those entries at the bottom of the ranking below the
--   minimum value, but gaining room at the top end. Or you may set a negative
--   scale if you know your scores are always mutliples of 10, 100, ….
--

local errors = {
  nargs = "ERR wrong number of arguments",
  nkeys = "ERR wrong number of keys",
}

local params = {
  time = {
    nbits = 32, -- number of bits to use for time information
    scale = 0, -- decimal digits in the fractional part, 0=1s, 1=0.1s, 2=0.01s…
    min = 1672531200, -- min. expected unix time: 2023-01-01 00:00:00 UTC
  },
  score = {
    scale = 0, -- decimal digits in the fractional part of score values
    min = 0, -- min. expected score
  },
}

local tbits = params.time.nbits
local step = 2^tbits

local maxsafe = 2^53
local anchor = step / 2 - maxsafe

local tinc = 10^(6 - params.time.scale)
local tmin = params.time.min * 1000000
local tmax = tmin + (2^tbits - 1) * tinc

local sinc = 10^params.time.scale
local smin = params.score.min
local smax = smin + 2^(53 + 1 - tbits) / 10^params.score.scale - 2

local function round (value)
  return math.floor(value + 0.5)
end

local function clamp (value, min, max)
  return math.min(math.max(value, min), max)
end

local function encode (score, timestamp)
  local left = round((score - smin) / sinc) * step
  local time = clamp(round((timestamp - tmin) / tinc), 0, step - 1)
  local right = step / 2 - 1 - time
  return anchor + left + right
end

local function decode (value)
  -- We never use the stored timestamp, so we don't bother extracting it
  return (round((value - step / 2) / step) + 2^(53 - tbits)) * sinc + smin
end

local function incrby (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args ~= 2 then return redis.error_reply(errors.nargs) end

  local key = keys[1]
  local increment, member = args[1], args[2]

  local value = redis.call("ZSCORE", key, member)
  local score

  if value then
    score = decode(value)
  else
    score = 0
  end

  score = score + increment

  local seconds, microseconds = unpack(redis.call("TIME"))
  local timestamp = seconds * 1000000 + microseconds

  value = encode(score, timestamp)

  redis.call("ZADD", key, value, member)

  return score
end

local function score (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args ~= 1 then return redis.error_reply(errors.nargs) end
  local value = redis.call("ZSCORE", keys[1], args[1])
  if value == nil then return nil end
  return decode(value)
end

local function rank (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args ~= 1 then return redis.error_reply(errors.nargs) end
  return redis.call("ZREVRANK", keys[1], args[1])
end

local function range (keys, args)
  if #keys ~= 1 then return redis.error_reply(errors.nkeys) end
  if #args ~= 2 then return redis.error_reply(errors.nargs) end

  local start, stop = args[1], args[2]

  local rng = redis.call("ZRANGE", keys[1], start, stop, "REV", "WITHSCORES")
  local res = {}

  for i=1,#rng,2 do
    res[i], res[i + 1] = rng[i], decode(rng[i + 1])
  end

  return res
end

if redis then
  local prefix = "rk"

  redis.register_function(prefix .. "incrby", incrby)
  redis.register_function(prefix .. "score", score)
  redis.register_function(prefix .. "rank", rank)
  redis.register_function(prefix .. "range", range)
end

local exports = {
  decode = decode,
  encode = encode,
  tmin = tmin,
  tmax = tmax,
  tinc = tinc,
  smin = smin,
  smax = smax,
}

return exports
