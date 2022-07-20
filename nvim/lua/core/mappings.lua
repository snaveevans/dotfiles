-- n, v, i, t = mode names

local M = {}

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
        ["<leader>tn"] = { ":tabedit <c-r>=expand(\"%:.:h\")<cr>/", "" },
        ["<c-j>"] = { "<c-d>", "move down buffer" },
        ["<c-k>"] = { "<c-u>", "move up buffer" },
    },
}

return M
