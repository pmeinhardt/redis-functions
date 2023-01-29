# Redis Functions

A collection of modules to extend [Redis](https://redis.io/) with additional functions.

## Usage

To load functions bundled in a module, run:

```sh
cat module.lua | redis-cli -x FUNCTION LOAD REPLACE
```

To list available functions:

```sh
redis-cli FUNCTION LIST [LIBRARYNAME library-name-pattern]
```

To invoke a function:

```sh
redis-cli FCALL function-name number-of-keys [key ...] [arg ...]
```

Example:

```sh
cat hello.lua | redis-cli -x FUNCTION LOAD REPLACE

redis-cli FCALL hello 0
# "Hello, World!"

redis-cli FCALL hello 0 Redis
# "Hello, Redis!"
```

For more information on function-related commands, check out the official Redis [docs](https://redis.io/commands/?group=scripting).

## Background

Redis supports persisted and replicated custom [functions](https://redis.io/docs/manual/programmability/functions-intro/) in versions 7.0 and newer. Functions are useful for maintaining a consistent view onto your data through a logical schema. They are (at present) written in [Lua](https://www.lua.org/), using Redis’ [Lua API](https://redis.io/docs/manual/programmability/lua-api/).

If you are tied to an older version of Redis, you might still be able to re-use code from these modules via Redis [scripting](https://redis.io/docs/manual/programmability/eval-intro/).

If you need low-level access or more fine-grained control, take a look at the Redis [Modules API](https://redis.io/docs/reference/modules/).
