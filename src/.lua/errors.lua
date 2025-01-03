local constant = require 'constants'

return {
  [constant.USER_DOES_NOT_EXIST] = 'User does not exist',
  [constant.USER_EXISTS] = 'User already exists, try another username',
  [constant.PASSWORD_MISMATCH] = 'Passwords must match',
  [constant.WRONG_PASSWORD] = 'Invalid Password'
}