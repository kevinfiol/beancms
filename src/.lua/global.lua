-- string formatter/interpolation
f = require 'lib.f-strings'

-- logging helpers
local inspect = require 'lib.inspect'

local function log(level)
  return function (message) Log(level, inspect(message)) end
end

LogDebug = log(kLogDebug)
LogWarn = log(kLogWarn)
LogError = log(kLogError)
LogFatal = log(kLogFatal)
p = LogDebug

-- load environment variables
ENV = {}
local env_vars = unix.environ()

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
  ENV[trim(key)] = trim(value)
end

for _, v in ipairs(env_vars) do
  setEnv(v)
end
