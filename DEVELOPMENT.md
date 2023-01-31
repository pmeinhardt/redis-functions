# Development

**Prerequisites**

- [Lua](https://www.lua.org/) 5.4 (other versions might work)
- [Luacheck](https://github.com/lunarmodules/luacheck) 1.1 or later
- [LuaRocks](https://luarocks.org/) 3.9 or later

You can install these using your preferred installation method.

In case you are using [Homebrew](https://github.com/Homebrew/brew):

```sh
brew install lua luacheck luarocks
```

For development, we have these convenience scripts:

```sh
script/setup  # install dependencies
script/test   # run the tests
script/run …  # invoke commands with luarocks env setup
```

Have fun.
