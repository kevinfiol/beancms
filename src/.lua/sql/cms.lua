local moon = require 'lib.fullmoon'
local constant = require 'constants'

local SCHEMA = [[
  create table if not exists user (
    user_id integer primary key,
    username text not null unique,
    hashed text not null,
    salt text not null,
    intro text default '',
    custom_css text default '',
    custom_title text default '',
    theme text default '',
    max_display_posts integer default 50,
    enable_toc integer default 1
  ) strict;

  create table if not exists post (
    post_id text primary key,
    user_id integer not null,
    title text default '',
    slug text default '',
    content text,
    content_size integer,
    created_time text not null default CURRENT_TIMESTAMP,
    modified_time text not null default CURRENT_TIMESTAMP,
    foreign key (user_id) references user(user_id)
  ) strict;
]]

local BASE_PATH = path.join(constant.BIN_DIR, constant.DATA_DIR)

-- create data folder if not exists
unix.makedirs(BASE_PATH)

-- open db and set pragmas
local db_path = path.join(BASE_PATH, 'cms.sqlite')
local sql = moon.makeStorage(db_path, SCHEMA)

sql:execute[[ pragma journal_mode = WAL; ]]
sql:execute[[ pragma foreign_keys = true; ]]
sql:execute[[ pragma temp_store = memory; ]]

-- handle migrations
local changes, error = sql:upgrade()
if error then
  moon.logWarn("Migrated DB with errors resolved: " .. error)
end

if #changes > 0 then
  moon.logWarn("Migrated cms DB to v%s\n%s",
    sql:fetchOne("PRAGMA user_version").user_version,
    table.concat(changes, ";\n")
  )
end

return sql
