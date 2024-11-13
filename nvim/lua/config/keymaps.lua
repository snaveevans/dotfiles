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
map("n", "<C-j>", "<C-d>", opts)
map("n", "<C-k>", "<C-u>", opts)
vim.keymap.del("n", "H") -- revert back to line count from top
vim.keymap.del("n", "L") -- revert back to line count from bottom

-- Visual --
-- Stay in indent mode
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)
map("v", "<leader>fr", ":<C-u>call VisualSelection('', '')<CR>:%s/<C-R>=@/<CR>/", opts)

-- Move text up and down
map("n", "<M-j>", ":m .+1<CR>==", opts)
map("n", "<M-k>", ":m .-2<CR>==", opts)
map("v", "<M-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<M-k>", ":m '<-2<CR>gv=gv", opts)
