-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * okverride the configuration of LazyVim plugins
return {
  -- change trouble config
  { "folke/trouble.nvim", enabled = false },
  { "folke/noice.nvim", enabled = false },
  { "rcarriga/nvim-notify", enabled = false },
  { "nvim-telescope/telescope.nvim", enabled = false },
  { "akinsho/bufferline.nvim", enabled = false },
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

  -- override nvim-cmp and add cmp-emoji
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
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

  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {},
      },
    },
  },

  -- add tsserver and setup with typescript.nvim instead of lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      init = function()
        require("lazyvim.util").lsp.on_attach(function(_, buffer)
          -- stylua: ignore
          vim.keymap.set( "n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
          vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
        end)
      end,
    },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- tsserver will be automatically installed with mason and loaded with lspconfig
        tsserver = {},
        jdtls = {},
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
        jdtls = function()
          return true -- avoid duplicate servers
        end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
  },

  -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
  -- treesitter, mason and typescript.nvim. So instead of the above, you can use:
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "java",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
  -- would overwrite `ensure_installed` with the new value.
  -- If you'd rather extend the default config, use the code below instead:
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
      })
    end,
  },

  -- use mini.starter instead of alpha
  { import = "lazyvim.plugins.extras.ui.mini-starter" },

  -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
  { import = "lazyvim.plugins.extras.lang.json" },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
        "java-debug-adapter",
        "java-test",
      },
    },
  },
}
