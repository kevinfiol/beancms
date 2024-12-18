require 'global'
local fm = require 'lib.fullmoon'

-- helper functions
fm.get = function (route, handler)
  return fm.setRoute({route, method = 'GET'}, handler)
end

fm.post = function (route, handler)
  return fm.setRoute({route, method = 'POST'}, handler)
end

fm.setTemplate({ '/view/', tmpl = 'fmt' })

fm.get('/static/*', fm.serveAsset)
fm.get('/', fm.serveContent('home'))
fm.get('/login', fm.serveContent('login'))

fm.post('/login', function (r)
  p(r.body)
  return 'hello'
end)

fm.run()

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