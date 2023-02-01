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

  it("ranks members", function ()
    assert.are.equal(4, fcall("rkincrby", 1, key, 4, "a"))
    assert.are.equal(3, fcall("rkincrby", 1, key, 3, "b"))
    assert.are.equal(2, fcall("rkincrby", 1, key, 2, "c"))
    assert.are.equal(0, fcall("rkrank", 1, key, "a"))
    assert.are.equal(1, fcall("rkrank", 1, key, "b"))
    assert.are.equal(2, fcall("rkrank", 1, key, "c"))
  end)

  it("lists members", function ()
    assert.are.equal(5, fcall("rkincrby", 1, key, 5, "a"))
    assert.are.equal(4, fcall("rkincrby", 1, key, 4, "b"))
    assert.are.equal(3, fcall("rkincrby", 1, key, 3, "c"))
    assert.are.same({"a", 5, "b", 4, "c", 3}, fcall("rkrange", 1, key, 0, -1))
  end)
end)

local mod = require "ranking"

describe("ranking.exports", function ()
  local decode, encode = mod.decode, mod.encode
  local smax, smin = mod.smax, mod.smin
  local tmax, tmin = mod.tmax, mod.tmin
  local tinc = mod.tinc

  local now = os.time() * 1000000

  it("encodes so higher scores produce higher values", function ()
    assert.is_true(encode(1, now) > encode(0, now))
  end)

  it("encodes so higher timestamps produce lower values", function ()
    assert.are.equal(encode(0, now + tinc), encode(0, now) - 1)
  end)

  it("encodes and decodes simple values", function ()
    for _, o in ipairs({0, 1, 17, 91, 131, 2000000}) do
      local v = smin + o
      assert.are.equal(v, decode(encode(v, tmin)))
      assert.are.equal(v, decode(encode(v, now)))
      assert.are.equal(v, decode(encode(v, tmax)))
    end
  end)

  it("encodes and decodes high values", function ()
    local v = smin + ((smax - smin) / 2) - 1

    assert.are.equal(v, decode(encode(v, tmin)))
    assert.are.equal(v, decode(encode(v, now)))
    assert.are.equal(v, decode(encode(v, tmax)))

    -- if assertions above succeed, but those below break,
    -- we are only getting half the promised score range

    v = v + 1

    assert.are.equal(v, decode(encode(v, tmin)))
    assert.are.equal(v, decode(encode(v, now)))
    assert.are.equal(v, decode(encode(v, tmax)))
  end)

  it("encodes and decodes values near the bottom edge", function ()
    for _, v in ipairs({smin, smin + 1}) do
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

  it("encodes with full time resolution within the boundaries", function ()
    for _, v in ipairs({smin, smax}) do
      assert.are.equal(encode(v, tmin + 2 * tinc), encode(v, tmin + tinc) - 1)
      assert.are.equal(encode(v, tmax - 2 * tinc), encode(v, tmax - tinc) + 1)
      assert.are.equal(encode(v, tmin + tinc), encode(v, tmin) - 1)
      assert.are.equal(encode(v, tmax - tinc), encode(v, tmax) + 1)
    end
  end)

  it("prevents out-of-range timestamp values from changing scores", function ()
    assert.are.equal(smin, decode(encode(smin, tmin - 1)))
    assert.are.equal(smin, decode(encode(smin, tmax + 1)))
    assert.are.equal(smin, decode(encode(smin, tmin - tinc)))
    assert.are.equal(smin, decode(encode(smin, tmax + tinc)))
    assert.are.equal(smin, decode(encode(smin, tmin - 2 * tinc)))
    assert.are.equal(smin, decode(encode(smin, tmax + 2 * tinc)))
  end)
end)
