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
