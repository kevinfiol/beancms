local moon = require 'lib.fullmoon'

local SCHEMA = [[
  create table if not exists user (
    username text not null unique,
    hashed text not null,
    salt text not null
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
