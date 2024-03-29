return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
      ensure_installed = {
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
        "java",
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
      },
      highlight = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },
      indent = {
        enable = true,
      },
      autotag = {
        enable = true,
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@call.outer",
            ["ia"] = "@call.inner",
            ["ao"] = "@conditional.outer",
            ["io"] = "@conditional.inner",
            ["ar"] = "@parameter.outer",
            ["ir"] = "@parameter.inner",
            ["ab"] = "@block.outer",
            ["ib"] = "@block.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]m"] = "@block.outer",
            ["]]"] = "@call.outer",
          },
          goto_next_end = {
            ["]M"] = "@block.outer",
            ["]["] = "@call.outer",
          },
          goto_previous_start = {
            ["[m"] = "@block.outer",
            ["[["] = "@call.outer",
          },
          goto_previous_end = {
            ["[M"] = "@block.outer",
            ["[]"] = "@call.outer",
          },
          goto_next = {
            ["]d"] = "@conditional.outer",
          },
          goto_previous = {
            ["[d"] = "@conditional.outer",
          },
        },
      },
    },
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })
    end,
    config = function(opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
