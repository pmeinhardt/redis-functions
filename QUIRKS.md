# Redis Lua Runtime Quirks

- At the time of writing, Redis embeds a Lua 5.1 interpreter (as stated in the Redis [docs](https://redis.io/docs/manual/programmability/lua-api/)).
- Be sure to use the appropriate version of the Lua docs for reference: [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/manual.html).
- The runtime libraries `string`, `table`, `math`, … and functions such as `type`, `setmetatable`, … are not available during module initialization. Trying to access them outside the runtime execution context will result in an error: `Script attempted to access nonexistent global variable '…'`
