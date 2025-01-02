require 'global'
local moon = require 'lib.fullmoon'
local db = require 'db'

-- helper functions
moon.get = function (route, handler)
  return moon.setRoute({route, method = 'GET'}, handler)
end

moon.post = function (route, handler)
  return moon.setRoute({route, method = 'POST'}, handler)
end

moon.setTemplate({ '/view/', tmpl = 'fmt' })

moon.get('/static/*', moon.serveAsset)
moon.get('/', moon.serveContent('home'))
moon.get('/login', moon.serveContent('login'))
moon.get('/register', moon.serveContent('register'))

moon.post('/login', function (r)
  local username = r.params.username
  local password = r.params.password
  local ok, err = db.validateUser(username, password)
  p({ok, err})
  -- db.createUser(username, password)
  return 'hello'
end)

moon.post('/register', function (r)
  local username = r.params.username
  local password = r.params.password
  local confirm = r.params.confirm

  if password ~= confirm then
    -- redirect back to register page with error
    return moon.serveRedirect(303, '/register?error=password_mismatch')
  end

  local salt = GetRandomBytes(16)
  local hashed = argon2.hash_encoded(password, salt, { m_cost = 65536 })

  local ok, err = db.createUser(username, hashed, salt)

  p({ ok, err })

  if not ok then
    LogError(f"Could not register user {username}")
    LogError(err)
  end

  return 'hello'
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