-- Luacheck: https://luacheck.readthedocs.io/en/stable/

std = "redis" -- stds.redis is defined below

ignore = {
  "212/args", -- passed to registered Redis functions
  "212/keys", -- passed to registered Redis functions
}

files["modules/*.test.lua"].std = "+lua51+busted"
files["modules/test/*.lua"].std = "+lua51+busted"

exclude_files = {".luarocks/"}

-- Redis Lua API: https://redis.io/docs/manual/programmability/lua-api/
-- Redis Functions: https://redis.io/docs/manual/programmability/functions-intro/

local defined = {}
local lua51 = stds.lua51.read_globals

stds.redis = {
  read_globals = {
    setmetatable = lua51.setmetatable,
    type = lua51.type,
    unpack = lua51.unpack,

    string = lua51.string,
    table = lua51.table,
    math = lua51.math,

    bit = {
      fields = {
        arshift = defined,
        band = defined,
        bnot = defined,
        bor = defined,
        bswap = defined,
        bxor = defined,
        lshift = defined,
        rol = defined,
        ror = defined,
        rshift = defined,
        tobit = defined,
        tohex = defined,
      },
    },

    cjson = {
      fields = {
        decode = defined,
        encode = defined,
      },
    },

    cmsgpack = {
      fields = {
        pack = defined,
        unpack = defined,
      },
    },

    struct = {
      fields = {
        pack = defined,
        size = defined,
        unpack = defined,
      },
    },

    redis = {
      fields = {
        REDIS_VERSION = defined,
        REDIS_VERSION_NUM = defined,
        acl_check_cmd = defined,
        breakpoint = defined,
        call = defined,
        debug = defined,
        error_reply = defined,
        log = defined,
        pcall = defined,
        register_function = defined,
        set_repl = defined,
        setresp = defined,
        sha1hex = defined,
        status_reply = defined,
      },
    },
  },
}
