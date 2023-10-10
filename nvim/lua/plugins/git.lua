return {
  {
    "tpope/vim-fugitive",
    cmd = { "Gread" },
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
    event = { "BufReadPre", "BufNewFile" },
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
    keys = function()
      local gs = require("gitsigns")
      return {
        {
          "]c",
          function()
            gs.next_hunk()
          end,
        },
        {
          "[c",
          function()
            gs.prev_hunk()
          end,
        },
        {
          "<leader>hs",
          function()
            gs.stage_hunk()
          end,
        },
        {
          "<leader>hr",
          function()
            gs.reset_hunk()
          end,
        },
        {
          "<leader>hs",
          function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          mode = "v",
        },
        {
          "<leader>hr",
          function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          mode = "v",
        },
        {
          "<leader>hu",
          function()
            gs.undo_stage_hunk()
          end,
        },
        {
          "<leader>hp",
          function()
            gs.preview_hunk()
          end,
        },
        {
          "<leader>hb",
          function() 
            gs.blame_line{full=true} 
          end,
        },
      }
    end,
  },
}
