local moon = require 'lib.fullmoon'

local SCHEMA = [[
  create table if not exists user (
    user_id integer primary key,
    username text not null unique,
    hashed text not null,
    salt text not null,
    intro text default '',
    custom_css text default ''
  );

  create table if not exists post (
    post_id text primary key,
    user_id integer not null,
    title text default '',
    slug text default '',
    content blob,
    content_size number,
    created_time text not null default CURRENT_TIMESTAMP,
    modified_time text not null default CURRENT_TIMESTAMP,
    foreign key (user_id) references user(user_id)
  );
]]

-- open db and enable wal mode
local sql = moon.makeStorage('bin/cms.db', SCHEMA)
sql:execute[[ pragma journal_mode = WAL ]]

-- handle migrations
local changes, error = sql:upgrade()
if error then
  moon.logWarn("Migrated DB with errors resolved: " .. error)
end

if #changes > 0 then
  moon.logWarn("Migrated DB to v%s\n%s",
    sql:fetchOne("PRAGMA user_version").user_version,
    table.concat(changes, ";\n")
  )
end

return sql
