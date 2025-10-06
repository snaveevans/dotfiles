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
    local vscode = require("vscode")

    -- File operations
    map("n", "<leader>ff", function() vscode.action("workbench.action.quickOpen") end, { desc = "Find Files" })
    map("n", "<leader>fg", function()
        vscode.action("workbench.action.findInFiles", {
            args = { query = vim.fn.expand('<cword>') }
        })
    end, { desc = "Find in Files (word under cursor)" })
    map("n", "<leader>fG", function() vscode.action("workbench.action.findInFiles") end, { desc = "Find in Files" })
    map("n", "<leader>fb", function() vscode.action("workbench.action.showAllEditors") end, { desc = "Find Buffers" })
    map("n", "<leader>fc", function() vscode.action("workbench.action.showCommands") end, { desc = "Command Palette" })
    map("n", "<leader>fs", function() vscode.action("workbench.action.gotoSymbol") end, { desc = "Go to Symbol" })
    map("n", "<leader>fS", function() vscode.action("workbench.action.showAllSymbols") end,
        { desc = "Go to Symbol (Workspace)" })

    -- File/Buffer management
    map("n", "<leader>w", function() vscode.action("workbench.action.closeActiveEditor") end, { desc = "Close Window" })
    map("n", "<leader>q", function() vscode.action("workbench.action.closeActiveEditor") end, { desc = "Close Window" })
    map("n", "<leader>bd", function() vscode.action("workbench.action.closeActiveEditor") end, { desc = "Delete Buffer" })

    -- Window splits
    map("n", "<leader>wv", function() vscode.action("workbench.action.splitEditor") end, { desc = "Split Vertical" })
    map("n", "<leader>ws", function() vscode.action("workbench.action.splitEditorOrthogonal") end,
        { desc = "Split Horizontal" })
    map("n", "<leader>ww", function() vscode.action("workbench.action.focusNextGroup") end,
        { desc = "Focus Next Window" })
    map("n", "<leader>wo", function() vscode.action("workbench.action.joinAllGroups") end,
        { desc = "Close Other Windows" })

    -- Window navigation with Ctrl+hjkl
    map("n", "<C-h>", function() vscode.action("workbench.action.navigateLeft") end, { desc = "Window Left" })
    map("n", "<C-l>", function() vscode.action("workbench.action.navigateRight") end, { desc = "Window Right" })

    -- Window resizing
    local function manageEditorSize(count, direction)
        for _ = 1, (count > 0 and count or 1) do
            if direction == 'increase' then
                vscode.action("workbench.action.increaseViewSize")
            else
                vscode.action("workbench.action.decreaseViewSize")
            end
        end
    end
    map("n", "<C-w>>", function() manageEditorSize(vim.v.count, 'increase') end, { desc = "Increase Window Width" })
    map("n", "<C-w><", function() manageEditorSize(vim.v.count, 'decrease') end, { desc = "Decrease Window Width" })
    map("n", "<C-w>+", function() manageEditorSize(vim.v.count, 'increase') end, { desc = "Increase Window Height" })
    map("n", "<C-w>-", function() manageEditorSize(vim.v.count, 'decrease') end, { desc = "Decrease Window Height" })

    -- Navigation
    map("n", "<leader>e", function() vscode.action("workbench.action.toggleSidebarVisibility") end,
        { desc = "Toggle Explorer" })
    map("n", "<leader>E", function() vscode.action("workbench.files.action.focusFilesExplorer") end,
        { desc = "Focus Explorer" })
    map("n", "gt", function() vscode.action("workbench.action.nextEditor") end, { desc = "Next Tab" })
    map("n", "gT", function() vscode.action("workbench.action.previousEditor") end, { desc = "Previous Tab" })
    map("n", "<leader><tab>", function() vscode.action("workbench.action.quickOpenPreviousRecentlyUsedEditor") end,
        { desc = "Last Buffer" })

    -- Code actions
    map({ "n", "x" }, "<leader>ca", function()
        vscode.with_insert(function()
            vscode.action("editor.action.quickFix")
        end)
    end, { desc = "Code Actions" })
    map({ "n", "x" }, "<leader>cr", function()
        vscode.with_insert(function()
            vscode.action("editor.action.rename")
        end)
    end, { desc = "Rename" })
    map("n", "<leader>cA", function() vscode.action("editor.action.sourceAction") end, { desc = "Source Actions" })
    map("n", "gd", function() vscode.action("editor.action.revealDefinition") end, { desc = "Go to Definition" })
    map("n", "gD", function() vscode.action("editor.action.revealDeclaration") end, { desc = "Go to Declaration" })
    map("n", "gy", function() vscode.action("editor.action.goToTypeDefinition") end, { desc = "Go to Type Definition" })
    map("n", "gi", function() vscode.action("editor.action.goToImplementation") end, { desc = "Go to Implementation" })
    map("n", "gr", function() vscode.action("editor.action.goToReferences") end, { desc = "Go to References" })
    map("n", "K", function() vscode.action("editor.action.showHover") end, { desc = "Hover" })
    map("n", "gK", function() vscode.action("editor.action.showDefinitionPreviewHover") end,
        { desc = "Hover (Definition Preview)" })

    -- Diagnostics navigation
    map("n", "]d", function() vscode.action("editor.action.marker.nextInFiles") end, { desc = "Next Diagnostic" })
    map("n", "[d", function() vscode.action("editor.action.marker.prevInFiles") end, { desc = "Previous Diagnostic" })
    map("n", "<leader>cd", function() vscode.action("workbench.actions.view.problems") end, { desc = "Show Diagnostics" })
    map("n", "<leader>xx", function() vscode.action("workbench.actions.view.problems") end,
        { desc = "Diagnostics (Problems)" })

    -- Formatting
    map("n", "<leader>cf", function() vscode.action("editor.action.formatDocument") end, { desc = "Format Document" })
    map("x", "<leader>cf", function() vscode.action("editor.action.formatSelection") end, { desc = "Format Selection" })
    map({ "n", "x" }, "=", function()
        vscode.call("editor.action.formatSelection")
    end, { desc = "Format" })

    -- Comments (use VSCode's comment toggle)
    map("n", "gcc", function() vscode.action("editor.action.commentLine") end, { desc = "Comment Line" })
    map("x", "gc", function() vscode.action("editor.action.commentLine") end, { desc = "Comment Selection" })

    -- Multi-cursor support (like VSCode's Ctrl+D)
    map({ "n", "x", "i" }, "<C-d>", function()
        vscode.with_insert(function()
            vscode.action("editor.action.addSelectionToNextFindMatch")
        end)
    end, { desc = "Add Selection to Next Find Match" })

    -- Line movement (Alt+j/k) - VSCode specific
    map("n", "<A-j>", function() vscode.action("editor.action.moveLinesDownAction") end, { desc = "Move Line Down" })
    map("n", "<A-k>", function() vscode.action("editor.action.moveLinesUpAction") end, { desc = "Move Line Up" })
    map("x", "<A-j>", function() vscode.action("editor.action.moveLinesDownAction") end, { desc = "Move Lines Down" })
    map("x", "<A-k>", function() vscode.action("editor.action.moveLinesUpAction") end, { desc = "Move Lines Up" })

    -- Also support M-j/k as aliases for Alt+j/k
    map("n", "<M-j>", function() vscode.action("editor.action.moveLinesDownAction") end, { desc = "Move Line Down" })
    map("n", "<M-k>", function() vscode.action("editor.action.moveLinesUpAction") end, { desc = "Move Line Up" })
    map("x", "<M-j>", function() vscode.action("editor.action.moveLinesDownAction") end, { desc = "Move Lines Down" })
    map("x", "<M-k>", function() vscode.action("editor.action.moveLinesUpAction") end, { desc = "Move Lines Up" })

    -- Git operations
    map("n", "<leader>gg", function() vscode.action("workbench.view.scm") end, { desc = "Source Control" })
    map("n", "<leader>gb", function() vscode.action("gitlens.toggleLineBlame") end, { desc = "Toggle Git Blame" })
    map("n", "]c", function() vscode.action("workbench.action.editor.nextChange") end, { desc = "Next Change" })
    map("n", "[c", function() vscode.action("workbench.action.editor.previousChange") end, { desc = "Previous Change" })

    -- Folding
    map("n", "za", function() vscode.action("editor.toggleFold") end, { desc = "Toggle Fold" })
    map("n", "zc", function() vscode.action("editor.fold") end, { desc = "Close Fold" })
    map("n", "zo", function() vscode.action("editor.unfold") end, { desc = "Open Fold" })
    map("n", "zM", function() vscode.action("editor.foldAll") end, { desc = "Close All Folds" })
    map("n", "zR", function() vscode.action("editor.unfoldAll") end, { desc = "Open All Folds" })

    -- Search improvements
    map("n", "*", function()
        vscode.action("editor.action.wordHighlight.next")
    end, { desc = "Next Word Highlight" })
    map("n", "#", function()
        vscode.action("editor.action.wordHighlight.prev")
    end, { desc = "Previous Word Highlight" })
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
