local autocmd = vim.api.nvim_create_autocmd
local api = vim.api

local buffer_num, buffer_name
local ignore_buffer = "term"

local blacklist_buffers = {
  ["term"] = function(name, num)
    if string.sub(name, 1, string.len(ignore_buffer)) == ignore_buffer then
      return true
    end
    return false
  end,
  ["empty"] = function(name, num)
  end
}

local M = {}

autocmd("BufLeave", {
  callback = function()
    local name = vim.api.nvim_buf_get_name(0)
    local num = vim.api.nvim_buf_get_number(0)
    local is_listed = vim.buffers == 1
    if not listed then
      print('not listed')
      return
    end
    print('listed')

    buffer_name = name
    buffer_num = buffer
  end,
})

M.bufferInfo = function()
  if not buffer_num or not buffer_name then
    return
  end
  print('name: ' .. buffer_name .. ', num: ' .. buffer_num)
end

M.goToLastBuffer = function()
  if not buffer_num then
    return
  end

  api.nvim_command('buffer ' .. buffer_num)
end

api.nvim_create_user_command("BufferSwap", M.goToLastBuffer, {})
api.nvim_create_user_command("BufferInfo", M.bufferInfo, {})

return M
