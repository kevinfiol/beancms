local sql = require 'sqlite'
local constant = require 'constants'
local uid = require 'lib.uid'

return {
  createUser = function (username, hashed, salt)
    local ok, result = pcall(function ()
      return sql:execute(
        [[
          insert into user (username, hashed, salt)
          values(?, ?, ?)
        ]],
        username, hashed, salt
      )
    end)

    return ok, result
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

    if result.hashed == nil then
      -- user doesn't exist
      return false, constant.USER_DOES_NOT_EXIST
    end

    local ok, err = argon2.verify(result.hashed, password)
    return ok, (ok and nil or constant.WRONG_PASSWORD)
  end,

  createPost = function (username, content)
    local post_id = uid()
    local retry = true
    local retries = 0
    local exists = true

    while exists and retry do
      local row = sql:fetchOne([[ select rowid from post where post_id = ? ]], post_id)

      if row and row.rowid ~= nil then
        if retries > 10 then
          retry = false
        else
          retries = retries + 1
        end

        post_id = uid()
        p('exists... making new id')
      else
        exists = false
      end
    end

    local ok, result = pcall(function ()
      return sql:execute(
        [[
          with user_info as (
            select user_id
            from user
            where username = ?
          )
          insert into post (post_id, user_id, content)
          select ?, user_id, ? from user_info
        ]],
        username, post_id, content
      )
    end)

    return ok, result
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