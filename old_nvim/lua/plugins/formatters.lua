return {
  {
    "mhartington/formatter.nvim",
    keys = {
      { "<leader>fd", ":Format<cr>" },
    },
    config = function()
      local util = require "formatter.util"
      local prettierconfig = require("formatter.defaults.prettier")
      local csformatter = function()
        return {
          exe = "dotnet-csharpier",
          args = {
            "--fast",
            "--write-stdout",
            util.escape_path(util.get_current_buffer_file_path())
          },
          stdin = true,
        }
      end

      require("formatter").setup({
        logging = true,
        log_level = vim.log.levels.WARN,
        filetype = {
          lua = {
            require("formatter.filetypes.lua").stylua,
          },

          html = { prettierconfig },
          json = { prettierconfig },
          yaml = { prettierconfig },
          graphql = { prettierconfig },
          markdown = { prettierconfig },
          javascript = { prettierconfig },
          javascriptreact = { prettierconfig },
          typescript = { prettierconfig },
          typescriptreact = { prettierconfig },

          rust = { require("formatter.filetypes.rust").rustfmt },

          toml = { require("formatter.filetypes.toml").taplo },

          cs = { csformatter },

          c = { require("formatter.filetypes.c").clangformat },

          terraform = { require("formatter.filetypes.terraform") },

          ["*"] = {
            require("formatter.filetypes.any").remove_trailing_whitespace,
          },
        },
      })
    end,
  },
}
