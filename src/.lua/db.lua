local sql = require 'sqlite'

return {
  createUser = function (username, hashed, salt)
    return sql:execute(
      [[
        insert into user (username, hashed, salt)
        values(?, ?, ?)
      ]],
      username, hashed, salt
    )
  end,

  validateUser = function (username, password)
    local result = sql:fetchOne(
      [[
        select hashed
        from user
        where username = ?
      ]],
      username
    )

    return argon2.verify(result.hashed, password)
  end
}


-- export function createUser(hashed: string) {
--   let ok = true;
--   let error = undefined;

--   try {
--     const insert = db.prepare(`
--       insert into user (hashed)
--       values(:hashed)
--     `);

--     const changes = insert.run({ hashed });
--     if (changes !== 1) throw Error('Unable to create user');
--   } catch (e) {
--     error = e;
--     ok = false;
--   }

--   return { ok, error };
-- }

-- function risky_function()
--     error("Something went wrong!")
-- end

-- local status, err = pcall(risky_function)
-- if not status then
--     print("Error: " .. err)
-- end