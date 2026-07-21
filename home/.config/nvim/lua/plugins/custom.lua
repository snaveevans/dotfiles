return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          imports = {
            gradle = {
              wrapper = {
                checksums = {
                  {
                    sha256 = "55243ef57851f12b070ad14f7f5bb8302daceeebc5bce5ece5fa6edb23e1145c",
                    allowed = true,
                  },
                },
              },
            },
          },
        },
      })
      return opts
    end,
  },

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
        "xml",
      })
    end,
  },
}
