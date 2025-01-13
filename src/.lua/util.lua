local uid = require 'lib.uid'

return {
  normalizePostId = function (s)
    s = s or ''
    s = string.gsub(s, "[^%w]", '') -- remove non-alphanumerics
    s = string.sub(s, 1, 10) -- trim to 11 characters
    if #s < 11 then
      s = s .. (uid(10 - #s))
    end

    return s
  end
}