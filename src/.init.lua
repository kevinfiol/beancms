require 'global'
local _ = require 'lib.lume'
local moon = require 'lib.fullmoon'
local db = require 'db'
local constant = require 'constants'
local session = require 'session'
local markdown = require 'lib.markdown'

-- helper functions
moon.get = function (route, handler)
  return moon.setRoute({route, method = 'GET'}, handler)
end

moon.post = function (route, handler)
  return moon.setRoute({route, method = 'POST'}, handler)
end

-- set templates and static asset paths
moon.setTemplate({ '/view/', tmpl = 'fmt' })
moon.get('/static/*', moon.serveAsset)
moon.get("/favicon.ico", moon.serveAsset)

local function checkSession (r, username)
  local token = r.cookies[constant.SESSION_TOKEN_NAME]
  local user_session = session.get(token)

  local result = { is_valid = false, user_access = false }
  result.is_valid = user_session ~= nil
  result.user_access = user_session and user_session.username == username

  if result.is_valid then
    return result, nil
  elseif token then
    session.delete(token)
  end

  -- invalidate user's expired token
  r.cookies[constant.SESSION_TOKEN_NAME] = false
  return result, 'Unauthorized'
end

local function setSessionCookie (r, username)
  -- create session and set cookie
  local token = session.new(username, constant.SESSION_MAX_AGE)

  r.cookies[constant.SESSION_TOKEN_NAME] = {
    token,
    path = '/',
    secure = true,
    httponly = true,
    maxage = constant.SESSION_MAX_AGE,
    samesite = 'Strict',
  }

  return r
end

moon.get('/', function (r)
  local user_session = checkSession(r)
  return moon.serveContent('home', { logged_in = user_session.is_valid })
end)

moon.get('/a/login', function (r)
  local user_session = checkSession(r)

  if user_session.is_valid then
    -- already active session, so redirect
    return moon.serveRedirect(303, '/')
  end

  local error = r.params.error or nil
  local error_message = nil

  if error == constant.WRONG_PASSWORD then
    moon.setStatus(401)
    error_message = 'Invalid Password'
  elseif error == constant.USER_DOES_NOT_EXIST then
    moon.setStatus(401)
    error_message = 'User does not exist'
  end

  return moon.serveContent('login', { error_message = error_message })
end)

moon.get('/a/logout', function (r)
  local token = r.cookies[constant.SESSION_TOKEN_NAME]

  if token then
    r.cookies[constant.SESSION_TOKEN_NAME] = false
    session.delete(token)
  end

  return moon.serveRedirect(302, '/')
end)

moon.get('/a/register', function (r)
  local user_session = checkSession(r)
  if user_session.is_valid then
    -- already active session, so redirect
    return moon.serveRedirect(303, '/')
  end

  local error = r.params.error or nil
  local error_message = nil

  if error == constant.USER_EXISTS then
    moon.setStatus(401)
    error_message = 'User already exists'
  elseif error == constant.PASSWORD_MISMATCH then
    moon.setStatus(401)
    error_message = 'Passwords must match'
  elseif error == constant.INVALID_USERNAME then
    moon.setStatus(401)
    error_message = 'Invalid or reserved username'
  end

  return moon.serveContent('register', { error_message = error_message })
end)

moon.get('/a/test', function (r)
  local id = 'wahfosdfjaosdf'
  local ok, result = db.createPost(id, id, 'kevin', 'hooheeehaahaa')

  if ok then
    p('successfully created post')
  end

  return 'test'
end)

moon.get('/:_username(/)', function (r)
  local username = _.trim(r.params._username)
  local ok, user = db.getUser(username)
  local new_post_id = ''

  if not ok then
    moon.setStatus(404)
    return 'User does not exist'
  end

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access
  local ok, posts = db.getPosts(username)

  if has_user_access then
    local ok, result = db.getPostId()

    if not ok then
      LogError(result)
      moon.setStatus(500)
      return 'An error occurred'
    end

    new_post_id = result
  end

  return moon.serveContent('user', {
    username = user.username,
    new_post_id = new_post_id,
    has_user_access = has_user_access,
    posts = posts
  })
end)

moon.get('/:_username/:slug(/)', function (r)
  local username = _.trim(r.params._username)
  local slug = _.trim(r.params.slug)

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access

  local ok, result = db.getPost(username, slug)
  if not ok then
    -- post does not exist
    -- if not authorized, return 404
    if not has_user_access then
      moon.setStatus(404)
      return 'Post does not exist'
    end

    -- else redirect user to edit route
    return moon.serveRedirect(302, f'/{username}/{slug}/edit')
  end

  -- otherwise, we can render the post content
  return moon.serveContent('post', {
    slug = slug,
    username = username,
    has_user_access = has_user_access,
    content = markdown(EscapeHtml(result.content))
  })
end)

moon.get('/:_username/:slug/edit(/)', function (r)
  local username = _.trim(r.params._username)
  local slug = _.trim(r.params.slug)

  local ok, post_id = db.getPostId(slug)
  local content = ''

  if not ok then
    LogError(post_id)
    moon.setStatus(500)
    return 'An error occurred'
  end

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access

  -- if not has_user_access then
  --   return moon.serveRedirect(303, f'/{username}/{slug}')
  -- end

  local ok, result = db.getPost(username, slug)
  if ok then
    post_id = result.post_id
    content = result.content
  end

  return moon.serveContent('editor', {
    username = username,
    slug = slug,
    title = result.title,
    post_id = post_id,
    content = content
  })
end)

moon.post('/a/login', function (r)
  local username = _.trim(r.params.username)
  local password = r.params.password
  local ok, err = db.validateUser(username, password)

  if not ok then
    return moon.serveRedirect(303, f'/a/login?error={err}')
  end

  setSessionCookie(r, username)
  return moon.serveRedirect(302, f'/{username}')
end)

moon.post('/a/register', function (r)
  local username = _.trim(r.params.username)
  local password = r.params.password
  local confirm = r.params.confirm

  local password_mismatch = constant.PASSWORD_MISMATCH
  local user_exists = constant.USER_EXISTS
  local invalid_username = constant.INVALID_USERNAME

  if password ~= confirm then
    return moon.serveRedirect(303, f'/a/register?error={password_mismatch}')
  elseif _.find(constant.RESERVED_USERNAMES, username) then
    return moon.serveRedirect(303, f'/a/register?error={invalid_username}')
  end

  local salt = GetRandomBytes(16)
  local hashed = argon2.hash_encoded(password, salt, { m_cost = 65536 })

  local ok, err = db.createUser(username, hashed, salt)
  if not ok then
    LogError(f'Could not register user: {username}')
    LogError(err)
    return moon.serveRedirect(303, f'/a/register?error={user_exists}')
  end

  setSessionCookie(r, username)
  return moon.serveRedirect(302, f'/{username}')
end)

moon.post('/:_username/:post_id', function (r)
  local username = _.trim(r.params._username)
  local post_id = _.trim(r.params.post_id)
  local body = DecodeJson(r.body)

  local content = body.content
  local title = body.title
  local slug = body.slug

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access

  -- if not has_user_access then
  --   moon.setStatus(401)
  --   return 'Unauthorized'
  -- end

  local ok = true
  local result = nil

  if _.trim(content) ~= '' then
    -- create or update
    ok, result = db.createPost(post_id, title, slug, username, content)
  else
    -- delete
    ok, result = db.deletePost(post_id, slug, username)
  end

  if not ok then
    moon.setStatus(500)
    return 'ERROR'
  end

  return 'OK'
end)

moon.run()
