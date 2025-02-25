-- string formatter/interpolation
f = require 'lib.f-strings'

-- logging helpers
local inspect = require 'lib.inspect'

local function log(level)
  return function (message)
    local info = debug.getinfo(2, 'Sl')
    local source = info.short_src:match("/zip/(.*)") or info.short_src
    local prefix = level == kLogDebug and '___' or ''
    Log(level, prefix .. '[/' .. source .. ':' .. info.currentline .. ']: ' .. inspect(message))
  end
end

LogDebug = log(kLogDebug)
LogWarn = log(kLogWarn)
LogError = log(kLogError)
LogFatal = log(kLogFatal)
p = LogDebug

-- shortcut helpers for fullmoon
local moon = require 'lib.fullmoon'

for _, method in ipairs({ 'get', 'post', 'delete', 'put', 'options', 'patch' }) do
  moon[method] = function(route, opts, handler)
    handler = type(opts) == 'function' and opts or handler
    opts = type(opts) == 'table' and opts or {}

    local route_opts = { route, method = string.upper(method) }
    for k, v in pairs(opts) do route_opts[k] = v end
    return moon.setRoute(route_opts, handler)
  end
end

-- load environment variables
ENV = {}

local function trim(s)
  s = s:match('^%s*(.-)%s*$')

  -- Check if surrounded by double quotes
  if s:sub(1, 1) == '"' and s:sub(-1, -1) == '"' then
    s = s:sub(2, -2):gsub('\\"', '"')
  end

  -- Check if the value is surrounded by single quotes
  if s:sub(1, 1) == "'" and s:sub(-1, -1) == "'" then
    s = s:sub(2, -2)
  end

  return s
end

local function setEnv(line)
  local key, value = line:match('([^=]+)=(.*)') -- split line by first '='
  value = trim(value)
  ENV[trim(key)] = value ~= '' and value or nil
end

-- load from system first
local env_vars = unix.environ()
for _, v in ipairs(env_vars) do
  setEnv(v)
end

-- load from env file
local env_file_path = path.join(unix.getcwd(), '.env')
local fd = unix.open(env_file_path, unix.O_RDONLY)
local env_file = nil
local env_file_err = nil

if fd then
  env_file, env_file_err = unix.read(fd)
end

if env_file and not env_file_err then
  for line in env_file:gmatch("[^\n]+") do
    -- ignore commented out lines (aka lines that start with a #)
    if not line:match("^%s*#") then
      setEnv(line)
    end
  end
end

LogDebug(ENV)
