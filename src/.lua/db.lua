local sql = require 'sqlite.cms'
local constant = require 'constant'
local uid = require 'lib.uid'
local _ = require 'lib.lume'

local DEFAULT_UID_LENGTH = 10

local function normalizePostId(s)
  s = s or ''
  s = string.gsub(s, "[^%w]", '') -- remove non-alphanumerics
  s = string.sub(s, 1, 10) -- trim to 11 characters
  local len = string.len(s)
  if len < 11 then
    s = s .. (uid(DEFAULT_UID_LENGTH - len))
  end

  return s
end

return {
  getDBCurrentTime = function()
    local current_time = ''
    local row, err = sql:fetchOne(
      [[
        select strftime('%Y-%m-%dT%H:%M:%SZ', CURRENT_TIMESTAMP) as current_time
      ]]
    )

    if not err then
      current_time = row.current_time 
    end

    return current_time, err
  end,

  createUser = function(username, hashed, salt)
    username = string.sub(username or '', 1, 35)

    local err = nil
    local ok, result = pcall(function ()
      return sql:execute(
        [[
          insert into user (username, hashed, salt)
          values(?, ?, ?)
        ]],
        username, hashed, salt
      )
    end)

    if result ~= 1 then
      ok = false
      err = 'Unable to create new user'
    end

    return ok, err
  end,

  updateUser = function(username, intro, custom_css, custom_title, max_display_posts, enable_toc, theme)
    custom_css = string.sub(custom_css or '', 1, 80000) -- 80000 char limit
    intro = string.sub(intro or '', 1, 500) -- 500 char limit
    custom_title = string.sub(custom_title or '', 1, 50) -- 50 char limit
    max_display_posts = math.max(math.min(100, max_display_posts or 50), 1) -- clamp from 1-100
    enable_toc = math.max(math.min(1, enable_toc or 0), 0)

    local err = nil
    local ok, result = pcall(function ()
      return sql:execute(
        [[
          update user set
            intro = :intro,
            custom_css = :custom_css,
            custom_title = :custom_title,
            max_display_posts = :max_display_posts,
            enable_toc = :enable_toc,
            theme = :theme
          where username = :username
        ]],
        {
          username = username,
          intro = intro,
          custom_css = custom_css,
          custom_title = custom_title,
          max_display_posts = max_display_posts,
          enable_toc = enable_toc,
          theme = theme
        }
      )
    end)

    if not ok then
      err = result
    end

    return ok, err
  end,

  validateUser = function(username, password)
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

  getUser = function(username)
    local user, err = sql:fetchOne(
      [[
        select
          username,
          user_id,
          intro,
          custom_css,
          custom_title,
          max_display_posts,
          enable_toc,
          theme,
          stale_feed,
          atom_feed,
          atom_feed_size
        from user
        where username = ?
      ]],
      username
    )

    if user.user_id == nil then
      err = constant.USER_DOES_NOT_EXIST
    end

    return user, err
  end,

  deleteUser = function(user_id)
    local err = nil
    local ok, result = pcall(function ()
      return sql:execute(
        [[
          begin immediate transaction;

          delete from user
          where user_id = :user_id;

          delete from post
          where user_id = :user_id;

          commit;
        ]],
        {
          user_id = user_id
        }
      )
    end)


    if not ok then
      err = result
    end

    return ok, err
  end,

  getUsersStats = function()
    local users, err = sql:fetchAll(
      [[
        select
          username,
          user_id,
          strftime('%Y-%m-%dT%H:%M:%SZ', created_time) as created_time
        from user
      ]]
    )

    if err then
      return {}, err
    end

    return users, nil
  end,

  getPostId = function(slug)
    local err = nil
    local post_id = normalizePostId(slug)

    local retry = true
    local retries = 0
    local uid_increment = 0
    local exists = true

    while exists and retry do
      local row = sql:fetchOne(
        [[ select rowid from post where post_id = ? ]],
        post_id
      )

      if row and row.rowid ~= nil then
        if retries > 10 then
          retry = false
          err = 'Unable to generate post ID; ran out of retries'
        else
          if retries % 2 == 0 then
            uid_increment = uid_increment + 1
          end

          retries = retries + 1
        end

        post_id = uid(DEFAULT_UID_LENGTH + uid_increment)
      else
        exists = false
      end
    end

    return post_id, err
  end,

  getPost = function(username, slug)
    local post, err = sql:fetchOne(
      [[
        select
          p.rowid,
          p.*,
          strftime('%s', p.modified_time) as unix_modified_time,
          strftime('%Y-%m-%d', p.created_time) as created_time
        from post p
        join user u on p.user_id = u.user_id
        where u.username = :username
        and (p.slug = :slug or p.post_id = :slug)
      ]],
      { username = username, slug = slug }
    )

    if err then
      return {}, err
    elseif post == nil or (post and post.rowid == nil) then
      return {}, constant.POST_DOES_NOT_EXIST
    end

    post.content = Inflate(post.content, post.content_size)
    post.unix_modified_time = tonumber(post.unix_modified_time)
    return post, err
  end,

  getPosts = function(username, max)
    max = max or 50

    local posts, err = sql:fetchAll(
      [[
        select
          p.title,
          p.post_id,
          p.slug,
          strftime('%Y-%m-%d', p.created_time) as created_time,
          strftime('%Y-%m-%d', p.modified_time) as modified_time
        from post p
        join user u on p.user_id = u.user_id
        where u.username = ?
        order by
          p.created_time desc
        limit ?
      ]],
      username,
      max
    )

    if err then
      return {}, err
    elseif posts == nil then
      return {}, 'Could not retrieve rows'
    end

    return posts, err
  end,

  getFeedPosts = function(username, max)
    max = max or 20

    local posts, err = sql:fetchAll(
      [[
        select
          p.post_id as id,
          p.title as title,
          strftime('%Y-%m-%dT%H:%M:%SZ', p.modified_time) as updated_iso,
          strftime('%Y-%m-%dT%H:%M:%SZ', p.created_time) as published_iso,
          p.content as content,
          p.content_size as content_size,
          p.slug as slug,
          u.username as name
        from post p
        join user u on p.user_id = u.user_id
        where u.username = ?
        order by
          p.created_time desc
        limit ?
      ]],
      username,
      max
    )

    if err then
      return {}, err
    elseif posts == nil then
      return {}, 'Could not retrieve feed posts'
    end

    -- decompress post content
    for _, post in ipairs(posts) do
      post.content = Inflate(post.content, post.content_size)
      post.content_size = nil
    end

    return posts, err
  end,

  updateUserFeed = function(username, feed)
    local err = nil
    local feed_size = #feed

    local ok, result = pcall(function()
      return sql:execute(
        [[
          update user
          set
            stale_feed = 0,
            atom_feed = :atom_feed,
            atom_feed_size = :atom_feed_size
          where username = :username
        ]],
        {
          atom_feed = Deflate(feed, 4),
          atom_feed_size = feed_size,
          username = username
        }
      )
    end)

    if not ok then
      err = result
    end

    return ok, err
  end,

  createPost = function(post_id, title, slug, username, content)
    content =  string.sub(content or '', 1, 80000) -- 80000 char limit

    local err = nil
    local content_size = #content

    if _.find(constant.RESERVED_SLUGS, slug) then
      slug = slug .. '-' .. post_id
    end

    local ok, result = pcall(function ()
      return sql:execute(
        [[
          begin immediate transaction;

          insert into post
            (user_id, post_id, title, slug, content, content_size)
          select
            user.user_id, :post_id, :title, :slug, :content, :content_size
          from user
          where
            user.username = :username
          on conflict(post_id) do update set
            title = excluded.title,
            slug = excluded.slug,
            content = excluded.content,
            content_size = :content_size,
            modified_time = CURRENT_TIMESTAMP;

          update user
          set stale_feed = 1
          where username = :username;

          commit;
        ]],
        {
          post_id = post_id,
          title = title,
          slug = slug,
          content = Deflate(content, 4),
          content_size = content_size,
          username = username
        }
      )
    end)

    if not ok then
      err = result
    end

    return ok, err
  end,

  deletePost = function(post_id, slug, username)
    local err = nil
    local ok, result = pcall(function ()
      return sql:execute(
        [[
          delete from post
          where (post_id = :post_id or slug = :slug)
          and user_id = (
            select user_id from user
            where username = :username
          )
        ]],
        { post_id = post_id, slug = slug, username = username }
      )
    end)

    if not ok then
      err = result
    end

    return ok, err
  end
}
