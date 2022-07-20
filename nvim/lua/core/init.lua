local autocmd = vim.api.nvim_create_autocmd
local api = vim.api

local last_buffer

local blacklist_buffers = {
  ["non-listed"] = function(buffer_num)
    return vim.fn.buflisted(buffer_num) == 0
  end,
  ["last-buffer"] = function(buffer_num)
    return buffer_num == last_buffer
  end,
}

local M = {}

autocmd("BufLeave", {
  callback = function()
    local buffer_num = vim.api.nvim_buf_get_number(0)

    for _, is_blacklisted in pairs(blacklist_buffers) do
      if is_blacklisted(buffer_num) then
        return
      end
    end

    last_buffer = buffer_num
  end,
})

M.goToLastBuffer = function()
  if not last_buffer then
    return
  end

  api.nvim_command('buffer ' .. last_buffer)
end

api.nvim_create_user_command("BufferSwap", M.goToLastBuffer, {})

return M
