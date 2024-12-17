local fm = require 'fullmoon'

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

fm.run()