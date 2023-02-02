local test = require "test"
local fcall = test.fcall

describe("colors", function ()
  local key = "colors-key"

  setup(function ()
    test.invoke("DEL", key)
    test.load("colors.lua")
  end)

  teardown(function ()
    test.unload("colors")
  end)

  after_each(function ()
    test.invoke("DEL", key)
  end)

  it("sets/gets rgba colors", function ()
    assert.are.equal("OK", fcall("csetrgba", 1, key, 255, 12, 127, 255))
    assert.are.same({255, 12, 127, 255}, fcall("cgetrgba", 1, key))
  end)

  it("sets rgba colors with defaults", function ()
    assert.are.equal("OK", fcall("csetrgba", 1, key))
    assert.are.same({0, 0, 0, 255}, fcall("cgetrgba", 1, key))
  end)

  it("sets/gets rgb colors", function ()
    assert.are.equal("OK", fcall("csetrgba", 1, key, 48, 24, 12))
    assert.are.same({48, 24, 12}, fcall("cgetrgb", 1, key))
  end)

  it("sets rgb colors with defaults", function ()
    assert.are.equal("OK", fcall("csetrgb", 1, key))
    assert.are.same({0, 0, 0}, fcall("cgetrgb", 1, key))
  end)
end)
