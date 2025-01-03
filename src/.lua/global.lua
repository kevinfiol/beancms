local inspect = require 'lib.inspect'

f = require 'lib.f-strings'

local log = function (level)
  return function (message) Log(level, inspect(message)) end
end

LogDebug = log(kLogDebug)
LogWarn = log(kLogWarn)
LogError = log(kLogError)
LogFatal = log(kLogFatal)
p = LogDebug