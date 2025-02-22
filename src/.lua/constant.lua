local function stripTrailingDots(path)
  return path:match("^(.-)%.*$") or path
end

local BIN_DIR = stripTrailingDots(path.dirname(path.join(unix.getcwd(), arg[-1])))
local DATA_DIR = path.join(BIN_DIR, 'data')
local IMG_DIR = path.join(DATA_DIR, 'img')

return {
  BIN_DIR = BIN_DIR,
  DATA_DIR = DATA_DIR,
  IMG_DIR = IMG_DIR,
  USER_DOES_NOT_EXIST = 'user_does_not_exist',
  USER_EXISTS = 'user_exists',
  PASSWORD_MISMATCH = 'password_mismatch',
  WRONG_PASSWORD = 'wrong_password',
  INVALID_USERNAME = 'invalid_username',
  POST_DOES_NOT_EXIST = 'post_does_not_exist',
  WRONG_CHALLENGE_ANSWER = 'wrong_challenge_answer',
  SESSION_TOKEN_NAME = 'beancms',
  SESSION_MAX_AGE = 604800, -- 7 days,
  MAX_IMAGE_SIZE = 8000000, -- 8MB
  RESERVED_USERNAMES = { 'login', 'logout', 'register' },
  RESERVED_SLUGS = { 'feed', 'archive' },
  SECURE_HEADERS = {
    -- https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html
    ['X-Frame-Options'] = 'SAMEORIGIN',
    ['X-Content-Type-Options'] = 'nosniff',
    ['Referrer-Policy'] = 'strict-origin-when-cross-origin',
    ['Cross-Origin-Embedder-Policy'] = 'credentialless',
    ['Cross-Origin-Resource-Policy'] = 'cross-origin',
    ['Cross-Origin-Opener-Policy'] = 'same-origin',
    ['Strict-Transport-Security'] = 'max-age=63072000; includeSubDomains; preload',
    ['X-DNS-Prefetch-Control'] = 'off',
    ['X-Download-Options'] = 'noopen',
    ['X-Permitted-Cross-Domain-Policies'] = 'none',
    ['X-XSS-Protection'] = '0',
    ['Content-Security-Policy'] = {
      ['default-src'] = "'self'",
      ['script-src'] = "'self'",
      ['style-src'] = "'self' 'unsafe-inline' https://fonts.googleapis.com https://fonts.xz.style",
      ['img-src'] = "'self' https: data:",
      ['font-src'] = "'self' https://fonts.gstatic.com https://fonts.xz.style",
      ['connect-src'] = "'self'",
      ['media-src'] = "'self'",
      ['frame-src'] = "'none'",
      ['object-src'] = "'none'",
      ['base-uri'] = "'self'",
      ['form-action'] = "'self'"
    }
  },
  THEME = {
    CONCRETE = 'concrete',
    MAGICK = 'magick',
    MATCHA = 'matcha',
    MERCURY = 'mercury',
    NEW = 'new',
    RETRO = 'retro',
    SAKURA_DARK = 'sakura-dark',
    SAKURA_EARTHLY = 'sakura-earthly',
    SAKURA_VADER = 'sakura-vader',
    SAKURA = 'sakura',
    SPCSS = 'spcss',
    TACIT = 'tacit',
    TERMINAL = 'terminal',
    TINY_BRUTALISM = 'tiny-brutalism',
    TINY = 'tiny',
    TUFTE = 'tufte',
    WATER = 'water'
  }
}
