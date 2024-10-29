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
    "ggandor/leap.nvim",
    keys = {
      {
        "s",
        function()
          require("leap").leap({})
        end,
      },
      {
        "S",
        function()
          require("leap").leap({ backward = true })
        end,
      },
    },
  },
  {
    "ibhagwan/fzf-lua",
    opts = {
      fzf_opts = {
        ["--layout"] = "default",
      },
      files = {
        rg_opts = [[--color=never --files --no-ignore --hidden --follow -g "!.git" -g "!node_modules" -g "!dist" -g "!.next"]],
      },
    },
    cmd = { "Rg" },
    config = function(p, opts)
      vim.api.nvim_create_user_command("Rg", function(args)
        local fargs = table.concat(args.fargs, " ")
        require("fzf-lua").grep_project({ search = fargs, cmd = "rg --hidden" })
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
            require("fzf-lua").live_grep({ cmd = "rg --hidden" })
          end,
        },
      }
    end,
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
