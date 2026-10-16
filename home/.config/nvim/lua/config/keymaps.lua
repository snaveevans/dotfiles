-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local opts = { noremap = true, silent = true }

local cmd_opts = { noremap = true }

local map = vim.keymap.set

local merge = require("util").merge

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
map("n", "<leader><cr>", ":noh<cr>", merge({ desc = "No highlight" }, cmd_opts))
map("n", "<leader>fn", ':edit <c-r>=expand("%:.:h")<cr>/', merge({ desc = "New file" }, cmd_opts))
map("n", "<leader>fv", ':vsplit <c-r>=expand("%:.:h")<cr>/', merge({ desc = "New file (split)" }, cmd_opts))

-- Git changed files with fzf
map("n", "<leader>i", "<cmd>FzfLua git_status<cr>", merge({ desc = "Git changed files (fzf)" }, opts))

-- Line movement (Alt+j/k and M-j/k)
map("n", "<A-j>", ":m .+1<CR>==", opts)
map("n", "<A-k>", ":m .-2<CR>==", opts)
map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)
map("n", "<M-j>", ":m .+1<CR>==", opts)
map("n", "<M-k>", ":m .-2<CR>==", opts)
map("v", "<M-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<M-k>", ":m '<-2<CR>gv=gv", opts)

map("n", "<C-j>", "<C-d>", opts)
map("n", "<C-k>", "<C-u>", opts)

vim.keymap.del("n", "H") -- revert back to line count from top
vim.keymap.del("n", "L") -- revert back to line count from bottom

-- Custom Commands
-- GStash: Stash the current file
vim.api.nvim_create_user_command("Gstash", function()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file to stash", vim.log.levels.WARN)
    return
  end

  -- Save the file first if it has unsaved changes
  if vim.bo.modified then
    vim.cmd("write")
  end

  -- Run git stash push with the specific file
  local result = vim.fn.system(
    string.format("git stash push -m 'Stash %s' -- %s", vim.fn.expand("%:t"), vim.fn.shellescape(filepath))
  )

  if vim.v.shell_error == 0 then
    vim.notify("File stashed successfully", vim.log.levels.INFO)
    -- Reload the buffer to show the unstashed version
    vim.cmd("edit!")
  else
    vim.notify("Failed to stash file: " .. result, vim.log.levels.ERROR)
  end
end, {
  desc = "Stash the current file",
})

-- GRead: Discard all changes to the current file (restore from git)
vim.api.nvim_create_user_command("Gread", function()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file to restore", vim.log.levels.WARN)
    return
  end

  -- Get the relative path from git root
  local git_path = vim.fn.system("git ls-files --full-name " .. vim.fn.shellescape(filepath)):gsub("\n", "")

  if vim.v.shell_error ~= 0 or git_path == "" then
    vim.notify("File is not tracked by git", vim.log.levels.WARN)
    return
  end

  -- Discard changes using git checkout
  local result = vim.fn.system("git checkout -- " .. vim.fn.shellescape(filepath))

  if vim.v.shell_error == 0 then
    vim.notify("Changes discarded, file restored from git", vim.log.levels.INFO)
    -- Reload the buffer to show the restored version
    vim.cmd("edit!")
    -- Clear the modified flag
    vim.bo.modified = false
  else
    vim.notify("Failed to restore file: " .. result, vim.log.levels.ERROR)
  end
end, {
  desc = "Discard changes and restore file from git",
})

-- Visual --
-- Stay in indent mode
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)
