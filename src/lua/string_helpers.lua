local function trim(str)
  if str == nil then
    return ''
  end
  return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

return {
  trim = trim,
}
