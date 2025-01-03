require 'global'
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

-- middleware
-- moon.setRoute({'/', '/login', '/register', method = 'GET'}, function (r)
--   p('HAAAAAAAA YOU PASSED THROUGH HERE FIRST')
--   return false
-- end)

moon.get('/', moon.serveContent('home'))

moon.get('/login', function (r)
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

moon.get('/register', function (r)
  local error = r.params.error or nil
  local error_message = nil

  if error == constant.USER_EXISTS then
    moon.setStatus(401)
    error_message = 'User already exists'
  elseif error == constant.PASSWORD_MISMATCH then
    moon.setStatus(401)
    error_message = 'Passwords must match'
  end

  return moon.serveContent('register', { error_message = error_message })
end)

moon.post('/login', function (r)
  local username = r.params.username
  local password = r.params.password
  local ok, err = db.validateUser(username, password)

  if not ok then
    return moon.serveRedirect(303, f'/login?error={err}')
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

moon.post('/register', function (r)
  local username = r.params.username
  local password = r.params.password
  local confirm = r.params.confirm

  local password_mismatch = constant.PASSWORD_MISMATCH
  local user_exists = constant.USER_EXISTS

  if password ~= confirm then
    -- redirect back to register page with error
    return moon.serveRedirect(303, f'/register?error={password_mismatch}')
  end

  local salt = GetRandomBytes(16)
  local hashed = argon2.hash_encoded(password, salt, { m_cost = 65536 })

  local ok, err = db.createUser(username, hashed, salt)
  if not ok then
    LogError(f'Could not register user: {username}')
    LogError(err)
    return moon.serveRedirect(303, f'/register?error={user_exists}')
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