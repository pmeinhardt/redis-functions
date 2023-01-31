local test = require "test"
local fcall = test.fcall

describe("hello", function ()
  setup(function ()
    test.load("hello.lua")
  end)

  teardown(function ()
    test.unload("hello")
  end)

  it("greets the world", function ()
    assert.are.equal("Hello, World!", fcall("hello", 0))
  end)

  it("greets the given name", function ()
    assert.are.equal("Hello, Redis!", fcall("hello", 0, "Redis"))
  end)
end)
