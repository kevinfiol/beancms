local inspect = require 'lib.inspect'

f = require 'lib.f-strings'

p = function (t)
  Log(kLogDebug, inspect(t))
end