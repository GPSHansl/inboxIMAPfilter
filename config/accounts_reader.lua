local csv_helpers = require('csv_helpers')
local string_helpers = require('string_helpers')
local trim = string_helpers.trim

local function parse_csv_line(line)
  return csv_helpers.parse_csv_line(line)
end

local function load_csv_rows(path)
  return csv_helpers.load_csv_rows(path)
end

local function load_accounts()
  local rows = load_csv_rows('/etc/imapfilter/accounts.csv')
  if #rows <= 1 then
    return {}
  end

  local header = parse_csv_line(rows[1])
  local result = {}

  for i = 2, #rows do
    local values = parse_csv_line(rows[i])
    local entry = {}
    for idx, name in ipairs(header) do
      local key = trim(name):gsub('%s+', '_'):lower()
      local raw_value = values[idx] or ''
      entry[key] = trim(raw_value)
    end
    table.insert(result, entry)
  end

  return result
end

return {
  load_accounts = load_accounts,
}
