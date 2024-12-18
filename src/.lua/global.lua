local inspect = require 'lib.inspect'

p = function (t)
  Log(kLogDebug, inspect(t))
end