return {
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gs", ":Git<cr>" },
      { "<leader>gd", ":Gdiffsplit!<cr>" },
      { "<leader>gc", ":Git commit<cr>" },
      { "<leader>gw", ":Gwrite<cr>" },
      { "<leader>gp", ":Git push<cr>" },
      { "<leader>gb", ":Git blame<cr>" },
      { "<leader>gm", ":Git mergetool<cr>" },
      { "<leader>gt", ":Git difftool<cr>" },
      { "<leader>gv", ':GMove <c-r>=expand("%:.")<cr>' },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { hl = "GitGutterAdd", text = "+" },
        change = { hl = "GitGutterChange", text = "~" },
        delete = { hl = "GitGutterDelete", text = "_" },
        topdelete = { hl = "GitGutterDelete", text = "‾" },
        changedelete = { hl = "GitGutterChange", text = "~" },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 250,
        ignore_whitespace = false,
      },
    },
  },
}
