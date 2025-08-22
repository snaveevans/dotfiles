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

-- VSCode-specific keymaps
if vim.g.vscode then
    local vscode = require("vscode-neovim")

    -- File operations
    map("n", "<leader>ff", function() vscode.call("workbench.action.quickOpen") end, { desc = "Find Files" })
    map("n", "<leader>fg", function() vscode.call("workbench.action.findInFiles") end, { desc = "Find in Files" })
    map("n", "<leader>fb", function() vscode.call("workbench.action.showAllEditors") end, { desc = "Find Buffers" })
    map("n", "<leader>fc", function() vscode.call("workbench.action.showCommands") end, { desc = "Command Palette" })

    -- Window management
    map("n", "<leader>w", function() vscode.call("workbench.action.closeActiveEditor") end, { desc = "Close Window" })
    map("n", "<leader>wv", function() vscode.call("workbench.action.splitEditor") end, { desc = "Split Vertical" })
    map("n", "<leader>ws", function() vscode.call("workbench.action.splitEditorOrthogonal") end,
        { desc = "Split Horizontal" })

    -- Navigation
    map("n", "<leader>e", function() vscode.call("workbench.action.toggleSidebarVisibility") end,
        { desc = "Toggle Explorer" })
    map("n", "gt", function() vscode.call("workbench.action.nextEditor") end, { desc = "Next Tab" })
    map("n", "gT", function() vscode.call("workbench.action.previousEditor") end, { desc = "Previous Tab" })

    -- Code actions
    map("n", "<leader>ca", function() vscode.call("editor.action.quickFix") end, { desc = "Code Actions" })
    map("n", "<leader>cr", function() vscode.call("editor.action.rename") end, { desc = "Rename" })
    map("n", "gd", function() vscode.call("editor.action.revealDefinition") end, { desc = "Go to Definition" })
    map("n", "gr", function() vscode.call("editor.action.goToReferences") end, { desc = "Go to References" })
    map("n", "K", function() vscode.call("editor.action.showHover") end, { desc = "Hover" })

    -- Diagnostics navigation
    map("n", "]d", function() vscode.call("editor.action.marker.nextInFiles") end, { desc = "Next Diagnostic" })
    map("n", "[d", function() vscode.call("editor.action.marker.prevInFiles") end, { desc = "Previous Diagnostic" })
    map("n", "<leader>cd", function() vscode.call("workbench.actions.view.problems") end, { desc = "Show Diagnostics" })

    -- Formatting
    map("n", "<leader>cf", function() vscode.call("editor.action.formatDocument") end, { desc = "Format Document" })
    map("v", "<leader>cf", function() vscode.call("editor.action.formatSelection") end, { desc = "Format Selection" })

    -- Comments (use VSCode's comment toggle)
    map("n", "gcc", function() vscode.call("editor.action.commentLine") end, { desc = "Comment Line" })
    map("v", "gc", function() vscode.call("editor.action.commentLine") end, { desc = "Comment Selection" })

    -- Line movement (Alt+j/k) - VSCode specific
    map("n", "<A-j>", function() vscode.call("editor.action.moveLinesDownAction") end, { desc = "Move Line Down" })
    map("n", "<A-k>", function() vscode.call("editor.action.moveLinesUpAction") end, { desc = "Move Line Up" })
    map("v", "<A-j>", function() vscode.call("editor.action.moveLinesDownAction") end, { desc = "Move Lines Down" })
    map("v", "<A-k>", function() vscode.call("editor.action.moveLinesUpAction") end, { desc = "Move Lines Up" })

    -- Also support M-j/k as aliases for Alt+j/k
    map("n", "<M-j>", function() vscode.call("editor.action.moveLinesDownAction") end, { desc = "Move Line Down" })
    map("n", "<M-k>", function() vscode.call("editor.action.moveLinesUpAction") end, { desc = "Move Line Up" })
    map("v", "<M-j>", function() vscode.call("editor.action.moveLinesDownAction") end, { desc = "Move Lines Down" })
    map("v", "<M-k>", function() vscode.call("editor.action.moveLinesUpAction") end, { desc = "Move Lines Up" })
else
    -- Regular Neovim keymaps (existing ones)
    -- Normal --
    map("n", "<leader><cr>", ":noh<cr>", merge({ desc = "No highlight" }, cmd_opts))
    map("n", "<leader>fn", ':edit <c-r>=expand("%:.:h")<cr>/', merge({ desc = "New file" }, cmd_opts))
    map("n", "<leader>fv", ':vsplit <c-r>=expand("%:.:h")<cr>/', merge({ desc = "New file (split)" }, cmd_opts))

    -- Line movement for regular Neovim (Alt+j/k and M-j/k)
    map("n", "<A-j>", ":m .+1<CR>==", opts)
    map("n", "<A-k>", ":m .-2<CR>==", opts)
    map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
    map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)
    map("n", "<M-j>", ":m .+1<CR>==", opts)
    map("n", "<M-k>", ":m .-2<CR>==", opts)
    map("v", "<M-j>", ":m '>+1<CR>gv=gv", opts)
    map("v", "<M-k>", ":m '<-2<CR>gv=gv", opts)
end

-- Common keymaps for both VSCode and regular Neovim
map("n", "<C-j>", "<C-d>", opts)
map("n", "<C-k>", "<C-u>", opts)

-- Only delete default keymaps in regular Neovim
if not vim.g.vscode then
    vim.keymap.del("n", "H") -- revert back to line count from top
    vim.keymap.del("n", "L") -- revert back to line count from bottom
end

-- Visual --
-- Stay in indent mode
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

if not vim.g.vscode then
    map("v", "<leader>fr", ":<C-u>call VisualSelection('', '')<CR>:%s/<C-R>=@/<CR>/", opts)
end
