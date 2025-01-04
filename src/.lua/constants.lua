return {
  USER_DOES_NOT_EXIST = 'user_does_not_exist',
  USER_EXISTS = 'user_exists',
  PASSWORD_MISMATCH = 'password_mismatch',
  WRONG_PASSWORD = 'wrong_password',
  INVALID_USERNAME = 'invalid_username',
  SESSION_TOKEN_NAME = '$$beanblogsession',
  SESSION_MAX_AGE = 31536000, -- 1 year
  RESERVED_USERNAMES = { 'login', 'logout', 'register' }
}