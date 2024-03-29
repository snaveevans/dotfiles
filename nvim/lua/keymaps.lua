local opts = { noremap = true, silent = true }

local cmd_opts = { noremap = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
keymap("n", "<leader><cr>", ":noh<cr>", opts)
keymap("n", "<leader>tn", ':tabedit <c-r>=expand("%:.:h")<cr>/', cmd_opts)
keymap("n", "<leader>n", ':edit <c-r>=expand("%:.:h")<cr>/', cmd_opts)
keymap("n", "<leader>v", ':vsplit <c-r>=expand("%:.:h")<cr>/', cmd_opts)
keymap("n", "<C-j>", "<C-d>", opts)
keymap("n", "<C-k>", "<C-u>", opts)
keymap("n", "<leader>z", ":suspend<cr>", opts)
keymap("n", "<leader>dc", ":Vexplore<cr>", opts)
keymap("n", "<leader>fr", ':%s/<C-r>=expand("<cword>")<CR>/', cmd_opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)
keymap("v", "<leader>fr", ":<C-u>call VisualSelection('', '')<CR>:%s/<C-R>=@/<CR>/", opts)

-- Move text up and down
keymap("n", "<M-j>", ":m .+1<CR>==", opts)
keymap("n", "<M-k>", ":m .-2<CR>==", opts)
keymap("v", "<M-j>", ":m '>+1<CR>gv=gv", opts)
keymap("v", "<M-k>", ":m '<-2<CR>gv=gv", opts)

-- ??
keymap("v", "p", '"_dP', opts)
