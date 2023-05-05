return {
  "tpope/vim-surround",
  {
    "joshdick/onedark.vim",
    lazy = false,
    priority = 1000,
    config = function()
      -- load the colorscheme here
      vim.cmd([[colorscheme onedark]])
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = true,
  },
  {
    "phaazon/hop.nvim",
    config = function()
      local hop = require("hop")
      local directions = require("hop.hint").HintDirection

      hop.setup({ keys = "etovxqpdygfblzhckisuran" })

      vim.keymap.set("n", "<leader><leader>w", function()
        hop.hint_words({ direction = directions.AFTER_CURSOR })
      end, {})

      vim.keymap.set("n", "<leader><leader>b", function()
        hop.hint_words({ direction = directions.BEFORE_CURSOR })
      end, {})
    end,
  },
  {
    "ibhagwan/fzf-lua",
    opts = {
      fzf_opts = {
        ["--layout"] = "default",
      },
    },
    cmd = { "Rg" },
    config = function(p, opts)
      vim.api.nvim_create_user_command("Rg", function(args)
        local fargs = table.concat(args.fargs, " ")
        require("fzf-lua").grep_project({ search = fargs })
      end, { nargs = "?" })

      require("fzf-lua").setup(opts)
    end,
    keys = function()
      return {
        {
          "<leader>p",
          function()
            require("fzf-lua").files()
          end,
        },
        {
          "<leader>o",
          function()
            require("fzf-lua").buffers()
          end,
        },
        {
          "s",
          function()
            require("fzf-lua").grep_visual()
          end,
          mode = "v",
        },
        {
          "<leader>fe",
          function()
            require("fzf-lua").grep_cword()
          end,
          mode = "n",
        },
        {
          "<leader>s",
          function()
            require("fzf-lua").live_grep()
          end,
        },
      }
    end,
  },
  {
    "sbdchd/neoformat",
    keys = {
      { "<leader>fd", ":Neoformat<cr>" },
    },
  },
  {
    "numToStr/Comment.nvim",
    config = true,
  },
  {
    "windwp/nvim-ts-autotag",
    config = true,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    module = "persistence",
    keys = {
      {
        "<F5>",
        function()
          require("persistence").save()
        end,
        mode = "n",
      },
      {
        "<F8>",
        function()
          require("persistence").load()
        end,
        mode = "n",
      },
    },
    config = function()
      require("persistence").setup()
    end,
  },
}
