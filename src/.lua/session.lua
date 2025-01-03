local constant = require 'constants'

local sessions = {}

return {
  new = function (max_age)
    max_age = max_age or constant.SESSION_MAX_AGE
    local token = UuidV4()
    local current_time_seconds = unix.clock_gettime()
    sessions[token] = { expiry = current_time_seconds + max_age }
    return token
  end,

  delete = function (token)
    if sessions[token] == nil then
      LogWarn(f'Session token does not exist: {token}')
    end

    sessions[token] = nil
  end,

  get = function (token)
    if sessions[token] ~= nil then
      local expiry = sessions[token].expiry
      local current_time_seconds = unix.clock_gettime()
      if current_time_seconds > expiry then
        sessions[token] = nil
      end
    end

    return sessions[token]
  end,

  entries = function ()
    return sessions
  end
}