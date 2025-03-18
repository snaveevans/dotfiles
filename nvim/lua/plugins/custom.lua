return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "c",
        "cmake",
        "comment",
        "c_sharp",
        "css",
        "dockerfile",
        "fish",
        "html",
        "http",
        "graphql",
        "javascript",
        "jsdoc",
        "json",
        "json5",
        "jsonc",
        "lua",
        "markdown_inline",
        "rust",
        "scss",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      })
    end,
  },
}
