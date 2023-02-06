local test = require "test"
local fcall = test.fcall

describe("ranking", function ()
  local key = "ranking-key"

  setup(function ()
    test.invoke("DEL", key)
    test.load("ranking.lua")
  end)

  teardown(function ()
    test.unload("ranking")
  end)

  after_each(function ()
    test.invoke("DEL", key)
  end)

  it("sets/gets ranking entries", function ()
    for i=0,6 do
      local score, member = 10^i, "m:" .. i
      assert.are.equal(score, fcall("rkincrby", 1, key, score, member))
      assert.are.equal(score, fcall("rkscore", 1, key, member))
    end
  end)

  it("updates ranking entries", function ()
    local member = "member-key"
    assert.are.equal(1000, fcall("rkincrby", 1, key, 1000, member))
    assert.are.equal(1001, fcall("rkincrby", 1, key, 1, member))
    assert.are.equal(1001, fcall("rkscore", 1, key, member))
  end)

  it("ranks members based on score", function ()
    assert.are.equal(4, fcall("rkincrby", 1, key, 4, "a"))
    assert.are.equal(3, fcall("rkincrby", 1, key, 3, "b"))
    assert.are.equal(2, fcall("rkincrby", 1, key, 2, "c"))
    assert.are.equal(0, fcall("rkrank", 1, key, "a"))
    assert.are.equal(1, fcall("rkrank", 1, key, "b"))
    assert.are.equal(2, fcall("rkrank", 1, key, "c"))
  end)

  it("lists members ordered by rank", function ()
    assert.are.equal(5, fcall("rkincrby", 1, key, 5, "a"))
    assert.are.equal(4, fcall("rkincrby", 1, key, 4, "b"))
    assert.are.equal(3, fcall("rkincrby", 1, key, 3, "c"))
    assert.are.same({"a", 5, "b", 4, "c", 3}, fcall("rkrange", 1, key, 0, -1))
  end)
end)

local mod = require "ranking"

describe("ranking codec", function ()
  local defaults = mod.defaults

  local maxsafe = 2^53
  local now = os.time() * 1000000

  for _, tbits in ipairs({32, 34}) do
    for _, smin in ipairs({0, -2^53 + 2^(54 - tbits) - 1, 2^53 - 2^(54 - tbits)}) do
      for _, tscale in ipairs({0, 3, 6}) do -- s, ms, μs
        local t = it

        local function it (description, ...)
          local fmt = "%s {time.nbits = %g, time.scale = %g, score.min = %g}"
          return t(string.format(fmt, description, tbits, tscale, smin), ...)
        end

        local params = {
          score = { min = smin },
          time = {
            min = defaults.time.min,
            nbits = tbits,
            scale = tscale,
          },
        }

        local c = mod.new(params)

        local decode = function (...) return c:decode(...) end
        local encode = function (...) return c:encode(...) end

        local smax = c.smax
        local tmax, tmin, tinc = c.tmax, c.tmin, c.tinc

        local step = 2^tbits

        it("encodes so higher scores produce higher values", function ()
          assert.is_true(encode(smin + 1, now) > encode(smin, now))
        end)

        it("encodes so higher timestamps produce lower values", function ()
          assert.are.equal(encode(smin, now + tinc), encode(smin, now) - 1)
        end)

        it("encodes expected values into the safe range", function ()
          assert.are.equal(-maxsafe, encode(smin, tmax))
          assert.are.equal(-maxsafe + 1, encode(smin, tmax - tinc))
          assert.are.equal(-maxsafe + step - 1, encode(smin, tmin))
          assert.are.equal(-maxsafe + step, encode(smin + 1, tmax))

          assert.are.equal(maxsafe - step - 1, encode(smax - 1, tmin))
          assert.are.equal(maxsafe - step, encode(smax, tmax))
          assert.are.equal(maxsafe - step + 1, encode(smax, tmax - tinc))
          assert.are.equal(maxsafe - 1, encode(smax, tmin))
        end)

        it("encodes and decodes simple values", function ()
          for _, v in ipairs({-13, 0, 1, 17, 97, 131, 1019}) do
            assert.are.equal(v, decode(encode(v, tmin)))
            assert.are.equal(v, decode(encode(v, now)))
            assert.are.equal(v, decode(encode(v, tmax)))
          end
        end)

        it("encodes and decodes high values", function ()
          local base = math.ceil(smin + (smax - smin) / 2)
          for _, v in ipairs({base - 1, base, base + 1}) do
            assert.are.equal(v, decode(encode(v, tmin)))
            assert.are.equal(v, decode(encode(v, now)))
            assert.are.equal(v, decode(encode(v, tmax)))
          end
        end)

        it("encodes and decodes values near the bottom edge", function ()
          for _, v in ipairs({smin + 1, smin}) do
            assert.are.equal(v, decode(encode(v, tmin)))
            assert.are.equal(v, decode(encode(v, now)))
            assert.are.equal(v, decode(encode(v, tmax)))
          end
        end)

        it("encodes and decodes values near the top edge", function ()
          for _, v in ipairs({smax - 1, smax}) do
            assert.are.equal(v, decode(encode(v, tmin)))
            assert.are.equal(v, decode(encode(v, now)))
            assert.are.equal(v, decode(encode(v, tmax)))
          end
        end)

        it("encodes and decodes values beyond the edges", function ()
          local vs = {
            smin - 1, smin - 2, 2 * smin - 1, 4 * smin - 1,
            smax + 1, smax + 2, 2 * smax + 1, 4 * smax + 1,
          }

          for _, v in ipairs(vs) do
            assert.are.equal(v, decode(encode(v, tmin)))
            assert.are.equal(v, decode(encode(v, now)))
            assert.are.equal(v, decode(encode(v, tmax)))
          end
        end)

        it("encodes with full time resolution within the range", function ()
          for _, v in ipairs({smin, smax}) do
            assert.are.equal(encode(v, tmin + tinc), encode(v, tmin) - 1)
            assert.are.equal(encode(v, tmax - tinc), encode(v, tmax) + 1)
          end
        end)

        it("ensures out-of-range timestamps do not leak into scores", function ()
          assert.are.equal(smin, decode(encode(smin, tmin - tinc)))
          assert.are.equal(smin, decode(encode(smin, tmax + tinc)))
        end)
      end
    end
  end
end)
