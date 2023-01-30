-- Luacheck: https://luacheck.readthedocs.io/en/stable/index.html
-- Redis Lua API: https://redis.io/docs/manual/programmability/lua-api/
-- Redis Functions: https://redis.io/docs/manual/programmability/functions-intro/

std = "none"

read_globals = {
  "bit",
  "cjson",
  "cmsgpack",
  "math",
  "redis",
  "string",
  "struct",
  "table",
}

ignore = {
  "212/args",
  "212/keys",
}
