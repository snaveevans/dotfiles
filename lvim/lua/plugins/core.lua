return {
  {
    "williamboman/mason.nvim",
    opts = { ensure_installed = { "prettier" } },
  },
  {
    "echasnovski/mini.surround",
    recommended = true,
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local opts = LazyVim.opts("mini.surround")
      local mappings = {
        { opts.mappings.add, desc = "Add Surrounding", mode = { "n", "v" } },
        { opts.mappings.delete, desc = "Delete Surrounding" },
        { opts.mappings.find, desc = "Find Right Surrounding" },
        { opts.mappings.find_left, desc = "Find Left Surrounding" },
        { opts.mappings.highlight, desc = "Highlight Surrounding" },
        { opts.mappings.replace, desc = "Replace Surrounding" },
        { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
      }
      mappings = vim.tbl_filter(function(m)
        return m[1] and #m[1] > 0
      end, mappings)
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      mappings = {
        add = "gsa", -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (to the right)
        find_left = "gsF", -- Find surrounding (to the left)
        highlight = "gsh", -- Highlight surrounding
        replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`
      },
    },
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
        desc = "Save Session",
      },
      {
        "<F8>",
        function()
          require("persistence").load()
        end,
        mode = "n",
        desc = "Load Session",
      },
    },
    config = function()
      require("persistence").setup()
    end,
  },
  {
    "ibhagwan/fzf-lua",
    opts = {
      fzf_opts = {
        ["--layout"] = "default",
      },
      files = {
        rg_opts = [[--color=never --files --no-ignore --hidden --follow -g "!.git" -g "!node_modules" -g "!dist"]],
      },
    },
    cmd = { "Rg" },
    config = function(_, opts)
      vim.api.nvim_create_user_command("Rg", function(args)
        local fargs = table.concat(args.fargs, " ")
        require("fzf-lua").grep_project({ search = fargs, cmd = "rg --hidden" })
      end, { nargs = "?" })

      require("fzf-lua").setup(opts)
    end,
    keys = {
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
      {
        "s",
        function()
          require("fzf-lua").grep_visual()
        end,
        mode = "v",
        desc = "FzF Grep Visual",
      },
      {
        "<leader>fe",
        function()
          require("fzf-lua").grep_cword()
        end,
        mode = "n",
        desc = "FzF Grep cword",
      },
      {
        "<leader>s",
        function()
          require("fzf-lua").live_grep({ cmd = "rg --hidden" })
        end,
        desc = "FzF live Grep",
      },
    },
  },
}
