local constant = require 'constant'

-- create required directories
unix.makedirs(constant.DATA_DIR)
unix.makedirs(constant.IMG_DIR)

-- set max payload size for images
ProgramMaxPayloadSize(constant.MAX_IMAGE_SIZE)

require 'global'
local _ = require 'lib.lume'
local moon = require 'lib.fullmoon'
local db = require 'db'
local session = require 'session'
local djot = require 'lib.djot'

-- schedule daily cleanup of session every 12 hours
moon.setSchedule("0 */12 * * *", function()
  local pruned, err = session.prune()

  if err then
    LogError(err)
  else
    LogDebug('Pruned sessions: ' .. pruned)
  end
end)

-- helper functions
moon.get = function(route, handler)
  return moon.setRoute({ route, method = 'GET' }, handler)
end

moon.post = function(route, handler)
  return moon.setRoute({ route, method = 'POST' }, handler)
end

local function checkSession(r, username)
  local token = r.cookies[constant.SESSION_TOKEN_NAME]
  local user_session = nil

  if token then
    user_session = session.get(token)
  end

  local result = { is_valid = false, user_access = false }
  result.is_valid = user_session and user_session.token
  result.user_access = user_session and user_session.username == username

  if result.is_valid then
    session.set(username, token) -- extend session

    r.cookies[constant.SESSION_TOKEN_NAME] = {
      token,
      path = '/',
      secure = true,
      httponly = true,
      maxage = constant.SESSION_MAX_AGE,
      samesite = 'Strict',
    }

    return result, nil
  elseif token then
    session.delete(token)
  end

  -- invalidate user's expired token
  r.cookies[constant.SESSION_TOKEN_NAME] = false
  r.session.token = nil
  return result, 'Unauthorized'
end

local function setSessionCookie(r, username)
  -- create session and set cookie
  local token = UuidV4()

  session.set(username, token)
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

local function buildNestedList(headings, level)
  local html = '<ul>'

  while #headings > 0 and headings[#headings].level == level do
    local last = table.remove(headings)
    if last ~= nil then
      html = html ..
        string.format('<li><a href="%s" title="%s">%s</a></li>',
          EscapeHtml(last.destination),
          EscapeHtml(last.title),
          EscapeHtml(last.title)
        )
    end
  end

  while #headings > 0 and headings[#headings].level > level do
    html = html .. buildNestedList(headings, level + 1)
  end

  return html .. '</ul>'
end

local function generateTOC(references, start_level)
  start_level = start_level or 1
  local html = ''

  -- build flat array of headings
  local headings = {}
  for k, v in pairs(references) do
    table.insert(headings, _.merge(v, { title = k }))
  end

  -- filter out non-heading references
  headings = _.filter(headings, function (a) return a.level ~= nil and a.order ~= nil end)
  -- sort in reverse order
  headings = _.sort(headings, function (a, b) return a.order > b.order end)
  -- filter based on start level
  headings = _.filter(headings, function (a) return a.level >= start_level end)

  while #headings > 0 do
    html = html .. buildNestedList(headings, start_level)
  end

  return html
end

-- set templates and static asset paths
moon.setTemplate({ '/view/', tmpl = 'fmt' })
moon.get('/static/*', moon.serveAsset)
moon.get('/favicon.ico', moon.serveAsset)

-- serve user uploaded images
moon.get('/data/img/:filename', moon.serveAsset)

-- set secure headers for all dynamic routes below
moon.setRoute({ '*', method = {'GET', 'POST'} }, function(r)
  for k, v in pairs(constant.DEFAULT_HEADERS) do
    r.headers[k] = v
  end
end)

moon.get('/', function(r)
  local user_session = checkSession(r)
  return moon.serveContent('home', { logged_in = user_session.is_valid })
end)

moon.get('/a/login', function(r)
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

moon.get('/a/logout', function(r)
  local token = r.cookies[constant.SESSION_TOKEN_NAME]

  if token then
    r.cookies[constant.SESSION_TOKEN_NAME] = false
    session.delete(token)
  end

  return moon.serveRedirect(302, '/')
end)

moon.get('/a/register', function(r)
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

moon.get('/:_username(/)', function(r)
  local username = _.trim(r.params._username)
  local user, err = db.getUser(username)
  local new_post_id = ''

  if err then
    LogError(err)
    moon.setStatus(404)
    return 'User does not exist'
  end

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access
  local posts, err = db.getPosts(username, user.max_display_posts)

  if err then
    LogError(err)
    moon.setStatus(500)
    return 'Error retrieving user posts'
  end

  if has_user_access then
    local post_id, err = db.getPostId()

    if err then
      LogError(err)
      moon.setStatus(500)
      return 'An error occurred'
    end

    new_post_id = post_id
  end

  local parsed_md = djot.parse(user.intro)
  local intro_html = djot.render_html(parsed_md)

  if has_user_access then
    r.headers.CacheControl = 'private, no-store'
  else
    r.headers.CacheControl = 'public, max-age=3600, must-revalidate'
  end

  return moon.serveContent('user', {
    username = user.username,
    new_post_id = new_post_id,
    has_user_access = has_user_access,
    posts = posts,
    intro = intro_html,
    intro_raw = user.intro,
    custom_css = user.custom_css,
    custom_title = user.custom_title,
    max_display_posts = user.max_display_posts,
    enable_toc = user.enable_toc,
    theme = user.theme,
    themes = constant.THEME
  })
end)

moon.get('/:_username/:slug(/)', function(r)
  local username = _.trim(r.params._username)
  local slug = _.trim(r.params.slug)

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access

  local post, err = db.getPost(username, slug)
  if err then
    LogError(err)

    -- post does not exist
    -- if not authorized, return 404
    if not has_user_access then
      moon.setStatus(404)
      return 'Post does not exist'
    end

    -- else redirect user to edit route
    return moon.serveRedirect(302, f'/{username}/{slug}/edit')
  end

  -- get custom css
  local custom_css = ''
  local user, err = db.getUser(username)
  if not err then
    custom_css = user.custom_css
  end

  local parsed_md = djot.parse(post.content)
  local content_html = djot.render_html(parsed_md)

  local toc_html = user.enable_toc == 1
    and generateTOC(parsed_md.references, 2)
    or nil

  if has_user_access then
    r.headers.CacheControl = 'private, no-store'
  else
    r.headers.CacheControl = 'public, max-age=3600, must-revalidate'
  end

  return moon.serveContent('post', {
    slug = slug,
    username = username,
    has_user_access = has_user_access,
    content = content_html,
    toc = toc_html,
    custom_css = custom_css,
    theme = user.theme,
    themes = constant.THEME
  })
end)

moon.get('/:_username/:slug/edit(/)', function(r)
  local username = _.trim(r.params._username)
  local slug = _.trim(r.params.slug)

  local post_id, err = db.getPostId(slug)
  local content = ''

  if err then
    LogError(err)
    moon.setStatus(500)
    return 'An error occurred'
  end

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access

  if not has_user_access then
    return moon.serveRedirect(303, f'/{username}/{slug}')
  end

  local post, err = db.getPost(username, slug)
  if not err then
    post_id = post.post_id
    content = post.content
  end

  return moon.serveContent('editor', {
    username = username,
    slug = slug,
    title = post.title,
    post_id = post_id,
    content = content
  })
end)

moon.get('/:_username/:slug/raw(/)', function(r)
  local username = _.trim(r.params._username)
  local slug = _.trim(r.params.slug)
  r.headers.ContentType = 'text/plain'

  local post, err = db.getPost(username, slug)

  if err then
    LogError(err)
    moon.setStatus(404)
    return 'Post does not exist'
  end

  return post.content
end)

moon.post('/a/login', function(r)
  local username = _.trim(r.params.username)
  local password = r.params.password
  local ok, err = db.validateUser(username, password)

  if not ok then
    return moon.serveRedirect(303, f'/a/login?error={err}')
  end

  setSessionCookie(r, username)
  return moon.serveRedirect(302, f'/{username}')
end)

moon.post('/a/register', function(r)
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
  if err then
    LogError(f'Could not register user: {username}')
    LogError(err)
    return moon.serveRedirect(303, f'/a/register?error={user_exists}')
  end

  setSessionCookie(r, username)
  return moon.serveRedirect(302, f'/{username}')
end)

moon.post('/a/upload', function(r)
  local image = r.params.multipart.image.data
  local filename = r.params.multipart.image.filename
  local content_type = r.params.multipart.image.headers['content-type']

  local is_image = _.split(content_type, '/')[1] == 'image'
  if not is_image then
    moon.setStatus(500)
    return 'Invalid content type for image'
  end

  local image_hash = EncodeHex(Md5(image))
  local ext = _.split(filename, '.')[2]
  local relative_path = path.join('data/img', image_hash) .. '.' .. ext
  local file_system_path = path.join(constant.BIN_DIR, relative_path)

  if not path.exists(file_system_path) then
    -- save image to filesystem
    local WRITE_FLAGS = unix.O_CREAT | unix.O_WRONLY
    local PERMISSIONS = 0644
    local fd = unix.open(file_system_path, WRITE_FLAGS, PERMISSIONS)
    unix.write(fd, image)
    unix.close(fd)
  end

  return relative_path
end)

moon.post('/a/update/:_username', function(r)
  local username = _.trim(r.params._username)
  local intro = _.trim(r.params.intro)
  local custom_css = _.trim(r.params.custom_css)
  local custom_title = _.trim(r.params.custom_title)
  local max_display_posts = tonumber(r.params.max_display_posts)
  local enable_toc = r.params.enable_toc == 'on' and 1 or 0
  local theme = _.trim(r.params.theme)

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access

  if not has_user_access then
    return moon.serveRedirect(302, f'/{username}')
  end

  p(intro)

  local ok, err = db.updateUser(
    username,
    intro,
    custom_css,
    custom_title,
    max_display_posts,
    enable_toc,
    theme
  )

  if err then
    LogError(f'Error: could not update user: {username}')
    LogError(err)
    return moon.serveRedirect(303, f'/{username}')
  end

  return moon.serveRedirect(302, f'/{username}')
end)

moon.post('/:_username/:post_id', function(r)
  local username = _.trim(r.params._username)
  local post_id = _.trim(r.params.post_id)
  local body = DecodeJson(r.body)

  local content = body.content
  local title = body.title
  local slug = body.slug

  local user_session = checkSession(r, username)
  local has_user_access = user_session.is_valid and user_session.user_access

  if not has_user_access then
    moon.setStatus(401)
    return 'Unauthorized'
  end

  local ok = true
  local err = nil

  if _.trim(content) ~= '' then
    -- create or update
    ok, err = db.createPost(post_id, title, slug, username, content)
  else
    -- delete
    ok, err = db.deletePost(post_id, slug, username)
  end

  if err then
    moon.setStatus(500)
    LogError(err)
    return 'ERROR'
  end

  return 'OK'
end)

moon.run()
