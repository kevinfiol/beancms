local sql = require 'sqlite'

return {
  createUser = function (username, hashed)
    sql:execute(
      [[
        insert into user (username, hashed)
        values(?, ?)
      ]],
      username, hashed
    )
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