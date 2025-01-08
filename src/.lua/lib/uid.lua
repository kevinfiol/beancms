-- this is a Lua port of lukeed's uid https://github.com/lukeed/uid
-- MIT License
-- Copyright (c) Luke Edwards <luke.edwards05@gmail.com> (lukeed.com)
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local IDX = 256
local HEX = {}
local SIZE = 256
local BUFFER = nil

math.randomseed(Rdseed())

for i = 0, IDX - 1 do
  HEX[i] = string.format('%02x', i)
end

IDX = -1

local function uid(len)
  len = len or 10
  local tmp = len
  local i = 0

  -- generate new buffer if depleted
  if not BUFFER or (IDX + tmp) > (SIZE * 2) then
    BUFFER = ''
    IDX = 0

    for _ = 1, SIZE do
      local random_idx = math.floor(math.random() * 256)
      BUFFER = BUFFER .. HEX[random_idx]
    end
  end

  -- extract substring
  local result = BUFFER:sub(IDX + 1, (IDX) + tmp)
  -- shift index by one
  IDX = IDX + 1

  return result
end
