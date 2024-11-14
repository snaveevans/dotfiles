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
  },
}
