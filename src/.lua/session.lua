local sql = require 'sqlite.session'
local constant = require 'constant'

local delete = function(token)
  local err = nil
  local ok, result = pcall(function()
    return sql:execute(
      [[
        delete from session
        where token = :token
      ]],
      { token = token }
    )
  end)

  if not ok then
    err = result
  end

  return ok, err
end

return {
  delete = delete,

  set = function(username, token)
    local err = nil
    local ok, result = pcall(function()
      return sql:execute(
        [[
          insert into session (token, expires_at, username)
          values(:token, unixepoch('now') + :max_age, :username)
          on conflict(token) do update set
            expires_at = unixepoch('now') + :max_age
        ]],
        {
          token = token,
          username = username,
          max_age = constant.SESSION_MAX_AGE
        }
      )
    end)

    if not ok then
      err = result
    end

    return ok, err
  end,

  get = function(token)
    local session, err = sql:fetchOne(
      [[
        select
          *,
          unixepoch('now') as now
        from session
        where token = :token
      ]],
      { token = token }
    )

    if err then
      return {}, err
    elseif session == nil or (session and session.token == nil) then
      return {}, 'Session token does not exist: ' .. token
    end

    if session.now > session.expires_at then
      -- session expired; remove from table
      local _, deletion_err = delete(token)

      if deletion_err then
        return {}, deletion_err
      end

      return {}, 'Session token has expired: ' .. token
    end

    return session, err
  end,

  prune = function()
    local pruned = 0
    local err = nil
    local ok, result = pcall(function()
      return sql:execute(
        [[
          delete from session
          where unixepoch('now') > expires_at
        ]]
      )
    end)

    if not ok then
      err = result
    else
      pruned = result
    end

    return pruned, err
  end,

  all = function()
    local sessions, err = sql:fetchAll(
      [[
        select
          *,
          strftime('%Y-%m-%dT%H:%M:%SZ', expires_at, 'unixepoch') as expires_at
        from session
      ]]
    )

    if err then
      return {}, err
    end

    return sessions, nil
  end
}
