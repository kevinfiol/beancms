-- string formatter/interpolation
f = require 'lib.f-strings'

-- logging helpers
local inspect = require 'lib.inspect'

local function log(level)
  return function (message)
    local info = debug.getinfo(2, 'Sl')
    local source = info.short_src:match("/zip/(.*)") or info.short_src
    Log(level, '[/' .. source .. ':' .. info.currentline .. ']: ' .. inspect(message))
  end
end

LogDebug = log(kLogDebug)
LogWarn = log(kLogWarn)
LogError = log(kLogError)
LogFatal = log(kLogFatal)
p = LogDebug

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
