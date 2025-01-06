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

local function checkSession (r)
  local token = r.cookies[constant.SESSION_TOKEN_NAME]
  local is_valid_session = token ~= nil and (session.get(token) ~= nil)

  if is_valid_session then
    return true, nil
  elseif token then
    session.delete(token)
  end

  -- invalidate user's expired token
  r.cookies[constant.SESSION_TOKEN_NAME] = false

  return false, 'Unauthorized'
end

moon.get('/', function (r)
  local is_valid_session = checkSession(r)
  return moon.serveContent('home', { logged_in = is_valid_session })
end)

moon.get('/a/login', function (r)
  local is_valid_session = checkSession(r)
  if is_valid_session then
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
  local is_valid_session = checkSession(r)
  if is_valid_session then
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

moon.get('/:username', function (r)
  local username = r.params.username
  return 'hello ' .. username
end)

moon.post('/a/login', function (r)
  local username = r.params.username
  local password = r.params.password
  local ok, err = db.validateUser(username, password)

  if not ok then
    return moon.serveRedirect(303, f'/a/login?error={err}')
  end

  -- create session and set cookie
  local token = session.new()
  r.cookies[constant.SESSION_TOKEN_NAME] = {
    token,
    secure = true,
    httponly = true,
    maxage = constant.SESSION_MAX_AGE,
    samesite = 'Strict',
  }

  return moon.serveRedirect(302, '/')
end)

moon.post('/a/register', function (r)
  local username = _.trim(r.params.username)
  local password = r.params.password
  local confirm = r.params.confirm

  p({ username = username })

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

  return moon.serveRedirect(302, '/')
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