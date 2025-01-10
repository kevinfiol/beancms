require 'global'
local _ = require 'lib.lume'
local moon = require 'lib.fullmoon'
local db = require 'db'
local constant = require 'constants'
local session = require 'session'

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

moon.get('/:_username/:post_title(/)', function (r)
  local username = _.trim(r.params._username)
  local post_title = _.trim(r.params.post_title)
  p({ username = username, post_title = post_title })

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access
  
  local ok, result = db.getPost(username, post_title)
  if not ok then
    -- post does not exist
    -- if not authorized, return 404
    if not has_user_access then
      moon.setStatus(404)
      return 'Post does not exist'
    end

    -- else show the editor
    return moon.serveContent('editor')
  end

  -- otherwise, we can render the post content
  return moon.serveContent('post', {
    post_content = result.content
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

moon.run()

-- app.post('/login', async (c) => {
--   const form = await c.req.formData();

--   const password = form.get('password') as string;
--   const { data: hashed } = database.getHashedPassword();
--   const isValid = verify(password, hashed);

--   if (!isValid) {
--     const html = Login({ error: 'Invalid password' });
--     c.status(500);
--     return c.html(html);
--   }

--   // store token in memory
--   const sessionToken = crypto.randomUUID();
--   SESSION.set(sessionToken, true);

--   // set cookie
--   await setSignedCookie(c, ACCESS_TOKEN_NAME, sessionToken, SESSION_SECRET, {
--     secure: true,
--     httpOnly: true,
--     sameSite: 'Strict',
--     expires: new Date(Date.now() + SESSION_MAX_AGE),
--   });

--   return c.redirect('/');
-- });

-- app.post('/init', async (c) => {
--   const form = await c.req.formData();

--   const password = form.get('password') as string;
--   const confirm = form.get('confirm') as string;

--   if (password !== confirm) {
--     return c.redirect('/?init=confirm_error', 302);
--   }

--   const hashed = hash(password);
--   const { error } = database.createUser(hashed);

--   if (error) {
--     console.error(error);
--     return c.redirect('/?init=init_error', 302);
--   }

--   // store token in memory
--   const sessionToken = crypto.randomUUID();
--   SESSION.set(sessionToken, true);

--   // set cookie
--   await setSignedCookie(c, ACCESS_TOKEN_NAME, sessionToken, SESSION_SECRET, {
--     secure: true,
--     httpOnly: true,
--     sameSite: 'Strict',
--     expires: new Date(Date.now() + SESSION_MAX_AGE),
--   });

--   // set init flag
--   database.initialize();

--   // set cookie with session token
--   return c.redirect('/');
-- });

-- app.on(
--   ['GET', 'POST'],
--   ['/', '/add', '/delete/*', '/api/*'],
--   async (c, next) => {
--     const token = await getSignedCookie(c, SESSION_SECRET, ACCESS_TOKEN_NAME);
--     const isValidToken = token && SESSION.get(token) && v4.validate(token);

--     if (isValidToken) {
--       return next();
--     } else if (token) {
--       SESSION.delete(token);
--     }

--     deleteCookie(c, ACCESS_TOKEN_NAME);

--     if (c.req.method === 'GET') {
--       const { data: isInit } = database.checkInitialized();
--       if (isInit) return c.redirect('/login');

--       const query = c.req.query('init');
--       const error = query === 'confirm_error'
--         ? 'Passwords do not match.'
--         : query === 'init_error'
--         ? 'Could not initialize user. Check system logs.'
--         : '';

--       const html = Initialize({ error });
--       return c.html(html);
--     }

--     c.status(401);
--     return c.text('Unauthorized');
--   },
-- );