local function stripTrailingDots(path)
  return path:match("^(.-)%.*$") or path
end

return {
  BIN_DIR = stripTrailingDots(path.dirname(path.join(unix.getcwd(), arg[-1]))),
  DATA_DIR = 'data',
  IMG_DIR = 'data/img',
  USER_DOES_NOT_EXIST = 'user_does_not_exist',
  USER_EXISTS = 'user_exists',
  PASSWORD_MISMATCH = 'password_mismatch',
  WRONG_PASSWORD = 'wrong_password',
  INVALID_USERNAME = 'invalid_username',
  POST_DOES_NOT_EXIST = 'post_does_not_exist',
  SESSION_TOKEN_NAME = 'beancms',
  -- SESSION_MAX_AGE = 2592000, -- 30 days
  SESSION_MAX_AGE = 30, -- 30 days
  RESERVED_USERNAMES = { 'login', 'logout', 'register' },
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
