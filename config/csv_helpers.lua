local string_helpers = require('string_helpers')
local trim = string_helpers.trim

local function parse_csv_line(line)
  local out = {}
  local field = ''
  local in_quotes = false

  for i = 1, #line do
    local ch = line:sub(i, i)
    if ch == '"' then
      if in_quotes and i < #line and line:sub(i + 1, i + 1) == '"' then
        field = field .. '"'
        i = i + 1
      else
        in_quotes = not in_quotes
      end
    elseif ch == ',' and not in_quotes then
      table.insert(out, field)
      field = ''
    else
      field = field .. ch
    end
  end

  table.insert(out, field)
  return out
end

local function load_csv_rows(path)
  local fh = io.open(path, 'r')
  if not fh then
    print('[imapfilter] missing file: ' .. path)
    return {}
  end

  local rows = {}
  for line in fh:lines() do
    if line:match('%S') then
      table.insert(rows, line)
    end
  end
  fh:close()

  return rows
end

function load_accounts()
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
      entry[key] = values[idx] or ''
    end
    table.insert(result, entry)
  end

  return result
end

function load_csv_values(path)
  local rows = load_csv_rows(path)
  local values = {}
  for _, row in ipairs(rows) do
    local value = trim(row)
    if value ~= '' and value ~= 'pattern' then
      table.insert(values, value)
    end
  end
  return values
end

return {
  trim = trim,
  parse_csv_line = parse_csv_line,
  load_csv_rows = load_csv_rows,
  load_accounts = load_accounts,
  load_csv_values = load_csv_values,
}
