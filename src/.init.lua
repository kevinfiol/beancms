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

moon.post('/login', function (r)
  local username = r.params.username
  local password = r.params.password
  db.createUser(username, password)
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