return {
  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "zbirenbaum/copilot-cmp",
    },
    opts = function()
      local cmp = require("cmp")
      return {
        completion = {
          completeopt = "menu,menuone,noinsert,noselect",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<S-CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
          }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = "copilot" },
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "fzf-lua",
      "hrsh7th/nvim-cmp",
      "jose-elias-alvarez/typescript.nvim",
      init = function()
        require("lazyvim.util").lsp.on_attach(function(_, buffer)
          -- stylua: ignore
          vim.keymap.set("n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
          vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
        end)
      end,
    },
    opts = function(opts)
      local Keys = require("lazyvim.plugins.lsp.keymaps").get()
      vim.list_extend(Keys, {
        {
          "gd",
          "<cmd>FzfLua lsp_definitions     jump_to_single_result=true ignore_current_line=true<cr>",
          desc = "Goto Definition",
          has = "definition",
        },
        {
          "gr",
          "<cmd>FzfLua lsp_references      jump_to_single_result=true ignore_current_line=true<cr>",
          desc = "References",
          nowait = true,
        },
        {
          "gI",
          "<cmd>FzfLua lsp_implementations jump_to_single_result=true ignore_current_line=true<cr>",
          desc = "Goto Implementation",
        },
        {
          "gy",
          "<cmd>FzfLua lsp_typedefs        jump_to_single_result=true ignore_current_line=true<cr>",
          desc = "Goto T[y]pe Definition",
        },
      })
      local v = {
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
      }
      -- return require("util").merge(opts, v)
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
    config = function()
      local jdtls = require("jdtls")

      -- Define your JDTLS configuration
      local root_dir = function()
        return vim.fn.getcwd() -- Customize this if you have a specific root directory logic
      end

      -- JDTLS setup
      jdtls.start_or_attach({
        cmd = { "/opt/homebrew/bin/jdtls" }, -- Adjust this path if necessary
        root_dir = root_dir,
        -- You can add more configurations as needed
      })
    end,
  },
}
