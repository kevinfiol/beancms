local sql = require 'sqlite'
local constant = require 'constants'
local uid = require 'lib.uid'

return {
  createUser = function (username, hashed, salt)
    local ok, result = pcall(function ()
      return sql:execute(
        [[
          insert into user (username, hashed, salt)
          values(?, ?, ?)
        ]],
        username, hashed, salt
      )
    end)

    return ok, result
  end,

  validateUser = function (username, password)
    local result, err = sql:fetchOne(
      [[
        select hashed
        from user
        where username = ?
      ]],
      username
    )

    if err then
      return false, err
    elseif result.hashed == nil then
      -- user doesn't exist
      return false, constant.USER_DOES_NOT_EXIST
    end

    local ok, err = argon2.verify(result.hashed, password)
    return ok, (ok and nil or constant.WRONG_PASSWORD)
  end,

  getUser = function (username)
    local result, err = sql:fetchOne(
      [[
        select username, user_id
        from user
        where username = ?
      ]],
      username
    )

    if err then
      return false, err
    elseif result.user_id == nil then
      return false, constant.USER_DOES_NOT_EXIST
    end

    return true, result
  end,

  getPostId = function ()
    local ok = true
    local post_id = uid()
    local retry = true
    local retries = 0
    local exists = true

    while exists and retry do
      local row = sql:fetchOne(
        [[ select rowid from post where post_id = ? ]],
        post_id
      )

      if row and row.rowid ~= nil then
        if retries > 10 then
          retry = false
          ok = false
        else
          retries = retries + 1
        end

        post_id = uid()
      else
        exists = false
      end
    end

    return ok, ok and post_id or 'Could not generate post id'
  end,

  getPost = function (username, post_title)
    local result, err = sql:fetchOne(
      [[
        select p.rowid, p.*
        from post p
        join user u on p.user_id = u.user_id
        where u.username = ? and p.title = ?
      ]],
      username, post_title
    )

    if err then
      return false, err
    elseif result == nil or (result and result.rowid == nil) then
      return false, constant.POST_DOES_NOT_EXIST
    end

    p({ content_before_inflate = result.content })
    result.content = Inflate(result.content, result.content_size)
    p({ content_after_inflate = result.content })
    return true, result
  end,

  getPosts = function (username)
    local result, err = sql:fetchAll(
      [[
        select p.title, p.post_id
        from post p
        join user u on p.user_id = u.user_id
        where u.username = ?
      ]],
      username
    )

    if err then
      return false, err
    elseif result == nil then
      return false, 'Could not retrieve rows'
    end

    return true, result
  end,

  createPost = function (post_id, title, username, content)
    local content_size = #content

    local ok, result = pcall(function ()
      return sql:execute(
        [[
          insert into post (user_id, post_id, title, content, content_size)
          select user.user_id, ?, ?, ?, ?
          from user
          where user.username = ?
          on conflict(post_id) do update set
            title = excluded.title,
            content = excluded.content,
            content_size = ?
        ]],
        post_id, title, Deflate(content, 4), content_size, username, content_size
      )
    end)

    if result ~= 1 then
      ok = false
      result = 'Post creation/update failed. No rows inserted/updated'
    end

    return ok, result
  end
}
