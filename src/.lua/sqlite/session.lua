local util = require 'sqlite.util'

local SCHEMA = [[
  create table if not exists session (
    token text primary key,
    expires_at integer not null,
    username text not null
  ) strict;
]]

local sql = util.openDatabase(SCHEMA, 'session.sqlite')

return sql
