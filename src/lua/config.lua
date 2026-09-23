-- imapfilter configuration
-- Rules:
-- 1. Ignore all senders matching @example.com.
-- 2. Match suspicious bot senders like first_last12345@example.net / example.org.
-- 3. Move only unseen suspicious messages to the configured spam folder.
-- 4. Read accounts from accounts.csv. One row per account, one mailbox per account.

package.path = '/var/lib/imapfilter/?.lua;' .. package.path

options.timeout = 120
options.create = true

local csv = require('csv_helpers')
local accounts_reader = require('accounts_reader')

local accounts = accounts_reader.load_accounts()
local whitelist_patterns = csv.load_csv_values('/etc/imapfilter/whitelist.csv')
local suspicious_patterns = csv.load_csv_values('/etc/imapfilter/suspicious.csv')

local function process_account(cfg)
  local host = cfg.host or ''
  local port = tonumber(cfg.port or '993') or 993
  local username = cfg.username or ''
  local password = cfg.password or ''
  local ssl_value = tostring(cfg.ssl or 'true')
  local ssl_enabled = (ssl_value:lower() == 'true') or (ssl_value == '1') or (ssl_value:lower() == 'yes')
  local ssl_setting = ssl_enabled and 'tls1.2' or nil
  local source_folder = cfg.source_folder or cfg.mailbox or cfg.mailboxes or ''
  local spam_folder = cfg.spam_folder or ''
  local name = cfg.name or (username ~= '' and host ~= '' and (username .. '|' .. host .. ':' .. tostring(port)) or 'imap-account')

  if host == '' or username == '' or password == '' then
    print('[imapfilter] skipping account ' .. name .. ' because host/username/password are incomplete')
    return
  end

  if source_folder == '' then
    print('[imapfilter] skipping account ' .. name .. ' because no source_folder configured')
    return
  end

  if spam_folder == '' then
    print('[imapfilter] skipping account ' .. name .. ' because no spam_folder configured')
    return
  end

  local account = IMAP {
    server = host,
    port = port,
    username = username,
    password = password,
    ssl = ssl_setting,
  }

  if account[spam_folder] == nil then
    print('[imapfilter] aborting account ' .. name .. ' because spam folder does not exist: ' .. spam_folder)
    return
  end

  local mailbox = account[source_folder]
  if mailbox ~= nil then
    local unseen = mailbox:is_unseen()
    local whitelist_result = nil
    local suspicious_result = nil

    for _, pattern in ipairs(whitelist_patterns) do
      local partial = unseen:match_from(pattern)
      if partial ~= nil and #partial > 0 then
        if whitelist_result == nil then
          whitelist_result = partial
        else
          whitelist_result = whitelist_result + partial
        end
      end
    end

    for _, pattern in ipairs(suspicious_patterns) do
      local partial = unseen:match_from(pattern)
      if partial ~= nil and #partial > 0 then
        if suspicious_result == nil then
          suspicious_result = partial
        else
          suspicious_result = suspicious_result + partial
        end
      end
    end

    if suspicious_result ~= nil and #suspicious_result > 0 then
      local candidates = suspicious_result
      if whitelist_result ~= nil and #whitelist_result > 0 then
        candidates = suspicious_result - whitelist_result
      end

      if candidates ~= nil and #candidates > 0 then
        print('[imapfilter] moving suspicious senders from ' .. name .. '/' .. source_folder .. ' to ' .. spam_folder)
        candidates:move_messages(account[spam_folder])
      end
    end
  end
end

if #accounts == 0 then
  print('[imapfilter] no accounts found in accounts.csv; skipping all mailboxes')
else
  for _, cfg in ipairs(accounts) do
    process_account(cfg)
  end
end
