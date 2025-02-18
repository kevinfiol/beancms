local moon = require 'lib.fullmoon'
local constant = require 'constant'

return {
  openDatabase = function(schema, filename)
    local BASE_PATH = path.join(constant.BIN_DIR, constant.DATA_DIR)

    -- create data folder if not exists
    unix.makedirs(BASE_PATH)
    
    -- open db and set pragmas
    local db_path = path.join(BASE_PATH, filename)
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
      moon.logWarn("Migrated " .. filename .. " DB to v%s\n%s",
        sql:fetchOne("PRAGMA user_version").user_version,
        table.concat(changes, ";\n")
      )
    end
    
    return sql
  end
}