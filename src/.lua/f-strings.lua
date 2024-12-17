-- https://github.com/hishamhm/f-strings/blob/master/LICENSE
-- The MIT License (MIT)

-- Copyright (c) 2016 Hisham Muhammad

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local F = {}

local load = load

if _VERSION == "Lua 5.1" then
   load = function(code, name, _, env)
      local fn, err = loadstring(code, name)
      if fn then
         setfenv(fn, env)
         return fn
      end
      return nil, err
   end
end

local function scan_using(scanner, arg, searched)
   local i = 1
   repeat
      local name, value = scanner(arg, i)
      if name == searched then
         return true, value
      end
      i = i + 1
   until name == nil
   return false
end

local function snd(_, b) return b end

local function format(_, str)
   local outer_env = _ENV and (snd(scan_using(debug.getlocal, 3, "_ENV")) or snd(scan_using(debug.getupvalue, debug.getinfo(2, "f").func, "_ENV")) or _ENV) or getfenv(2)
   return (str:gsub("%b{}", function(block)
      local code, fmt = block:match("{(.*):(%%.*)}")
      code = code or block:match("{(.*)}")
      local exp_env = {}
      setmetatable(exp_env, { __index = function(_, k)
         local level = 6
         while true do
            local funcInfo = debug.getinfo(level, "f")
            if not funcInfo then break end
            local ok, value = scan_using(debug.getupvalue, funcInfo.func, k)
            if ok then return value end
            ok, value = scan_using(debug.getlocal, level + 1, k)
            if ok then return value end
            level = level + 1
         end
         return rawget(outer_env, k)
      end })
      local fn, err = load("return "..code, "expression `"..code.."`", "t", exp_env)
      if fn then
         return fmt and string.format(fmt, fn()) or tostring(fn())
      else
         error(err, 0)
      end         
   end))
end

setmetatable(F, {
   __call = format
})

return F