local _ = require 'lib.lume'

local function buildNestedList(headings, level)
  local html = '<ul>'

  while #headings > 0 and headings[#headings].level == level do
    local last = table.remove(headings)
    if last ~= nil then
      html = html ..
        string.format('<li><a href="%s" title="%s">%s</a></li>',
          EscapeHtml(last.destination),
          EscapeHtml(last.title),
          EscapeHtml(last.title)
        )
    end
  end

  while #headings > 0 and headings[#headings].level > level do
    html = html .. buildNestedList(headings, level + 1)
  end

  return html .. '</ul>'
end

return {
  generateTOC = function(references, start_level)
    start_level = start_level or 1
    local html = ''
  
    -- build flat array of headings
    local headings = {}
    for k, v in pairs(references) do
      table.insert(headings, _.merge(v, { title = k }))
    end
  
    -- filter out non-heading references
    headings = _.filter(headings, function (a) return a.level ~= nil and a.order ~= nil end)
    -- sort in reverse order
    headings = _.sort(headings, function (a, b) return a.order > b.order end)
    -- filter based on start level
    headings = _.filter(headings, function (a) return a.level >= start_level end)
  
    while #headings > 0 do
      html = html .. buildNestedList(headings, start_level)
    end
  
    return html
  end,

  -- converts a table such as the one defined for 'Content-Security-Policy' in constant.lua to a CSP string
  -- ex: { ['default-src'] = "'self'", ['style-src'] = "'self' 'unsafe-inline'" } -> default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';
  tableToCSP = function(t)
    local parts = {}

    for directive, value in pairs(t) do
      table.insert(parts, directive .. ' ' .. value)
    end

    return table.concat(parts, '; ') .. ';'
  end,

  generateNonce = function()
    return EncodeBase64(GetRandomBytes(16))
  end
}