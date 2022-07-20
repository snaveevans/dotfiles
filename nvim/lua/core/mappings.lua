-- n, v, i, t = mode names

local M = {}

M.fugitive = {
  n = {
    ["<leader>gs"] = { "<cmd>Git<cr>", "view git status", { silent = true } },
    ["<leader>gd"] = { "<cmd>Gdiffsplit!<cr>", "view git diff for current buffer", { silent = true } },
    ["<leader>gc"] = { "<cmd>Git commit<cr>", "initate a git commit", { silent = true } },
    ["<leader>gw"] = { "<cmd>GWrite<cr>", "git add current buffer", { silent = true } },
    ["<leader>gp"] = { "<cmd>Git push<cr>", "git push", { silent = true } },
    ["<leader>gb"] = { "<cmd>Git blame<cr>", "show git blame for buffer", { silent = true } },
  }
}

M.fzf = {
  n = {
    ["<leader>p"] = { "<cmd>lua require('fzf-lua').files()<cr>", "fuzzy find files", { silent = true } },
    ["<leader>o"] = { "<cmd>lua require('fzf-lua').buffers()<cr>", "fuzzy find buffers", { silent = true } },
    ["<leader>ft"] = { "<cmd>lua require('fzf-lua').filetypes()<cr>", "fuzzy find & set filetype for buffer",
      { silent = true } },
    ["<leader>s"] = { "<cmd>lua require('fzf-lua').live_grep({ cmd = 'git grep --line-number --column --color=always' })<cr>",
      "start fuzzy find text in files (inc)", { silent = true } },
    ["<leader>S"] = { "<cmd>lua require('fzf-lua').grep_project()<cr>", "start fuzzy find text in files (inc)",
      { silent = true } },
    ["<leader>fa"] = { "<cmd>lua require('fzf-lua').grep_cword()<cr>", "fuzzy find selected text in files",
      { silent = true } },
    ["<leader>fe"] = { "<cmd>lua require('fzf-lua').grep_cWORD()", "fuzzy find selected text in files (exact)",
      { silent = true } },
  },
  v = {
    ["<leader>fa"] = { "<cmd>lua require('fzf-lua').grep_visual()<cr>", "fuzzy find selected text in files",
      { silent = true } },
  }
}

M.general = {
  n = {
    ["<leader><cr>"] = { "<cmd>nohlsearch<cr>", "stop highlighting search" },
    ["th"] = { "<cmd>tabfirst<cr>", "goto first tab" },
    ["tk"] = { "<cmd>tabnext<cr>", "goto next tab" },
    ["tj"] = { "<cmd>tabprev<cr>", "goto previous tab" },
    ["tl"] = { "<cmd>tablast<cr>", "goto last tab" },
    ["tt"] = { ":tabedit<space>", "edit file in new tab" },
    ["tm"] = { ":tabmove<space>", "move current tab to {index}" },
    ["td"] = { "<cmd>tabclose<cr>", "close current tab" },
    ["ty"] = { "<cmd>tabonly<cr>", "close other tabs" },
    [";"] = { "<cmd>BufferSwap<cr>", "goto last buffer" },
    ["<leader>tn"] = { ":tabedit <c-r>=expand(\"%:.:h\")<cr>/", "" },
    ["<c-j>"] = { "<c-d>", "move down buffer" },
    ["<c-k>"] = { "<c-u>", "move up buffer" },
    ["asdf"] = { "<cmd>lua print('buffer: ',vim.api.nvim_buf_get_number(0))<cr>", "testing" },
  },
}

return M
