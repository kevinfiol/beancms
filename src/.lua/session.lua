local lru = require 'lib.lru'

local MAX_LENGTH = 1000
local cache = lru.new(MAX_LENGTH)

return {
  new = function (max_age)
    max_age = max_age or 31536000 -- 1 year
    local token = UuidV4()
    local current_time_seconds = unix.clock_gettime()

    cache:set(token, { expiry = current_time_seconds + max_age })
    return token
  end,

  delete = function (token)
    if cache:get(token) == nil then
      LogWarn(f'Session token does not exist: {token}')
    else
      cache:delete(token)
    end
  end,

  get = function (token)
    local session = cache:get(token)

    if session ~= nil then
      local expiry = session.expiry
      local current_time_seconds = unix.clock_gettime()
      if current_time_seconds > expiry then
        cache:delete(token)
        return nil
      end
    end

    return session
  end,

  all = function ()
    local sessions = {}
    for k, v in cache:pairs() do
      sessions[k] = v
    end

    return sessions
  end
}