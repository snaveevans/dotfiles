return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "lua-language-server",
        "eslint-lsp",
        "prettier",
        "vtsls",
      },
    },
  },
  {
    "ibhagwan/fzf-lua",
    opts = {
      fzf_opts = {
        ["--layout"] = "default",
      },
    },
    keys = {
      {
        "<leader><leader>",
        function()
          require("fzf-lua").files()
        end,
        desc = "FzF Files",
      },
      {
        "<leader>p",
        function()
          require("fzf-lua").files()
        end,
        desc = "FzF Files",
      },
      {
        "<leader>o",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "FzF Buffers",
      },
    },
  },
}
