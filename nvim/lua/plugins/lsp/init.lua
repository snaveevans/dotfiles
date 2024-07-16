return {
  {
    "L3MON4D3/LuaSnip",
    build = (not jit.os:find("Windows"))
        and "echo -e 'NOTE: jsregexp is optional, so not a big deal if it fails to build\n'; make install_jsregexp"
      or nil,
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
    keys = {
      {
        "<tab>",
        function()
          return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
        end,
        expr = true,
        silent = true,
        mode = "i",
      },
      {
        "<tab>",
        function()
          require("luasnip").jump(1)
        end,
        mode = "s",
      },
      {
        "<s-tab>",
        function()
          require("luasnip").jump(-1)
        end,
        mode = { "i", "s" },
      },
    },
  },

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
      "hrsh7th/nvim-cmp",
    },
    config = function()
      local Util = require("util")
      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        local function buf_set_option(...)
          vim.api.nvim_buf_set_option(bufnr, ...)
        end

        -- Enable completion triggered by <c-x><c-o>
        buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

        -- Mappings.
        local opts = { noremap = true, silent = true, buffer = bufnr }

        -- See `:help vim.lsp.*` for documentation on any of the below functions
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
        vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set("n", "<space>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
        vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "<space>f", function()
          vim.lsp.buf.format({ async = true })
        end, opts)
      end

      -- Add additional capabilities supported by nvim-cmp
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      local lspconfig = require("lspconfig")

      -- Use a loop to conveniently call 'setup' on multiple servers and
      -- map buffer local keybindings when the language server attaches
      local servers = {
        { "tsserver" },
        { "cssls" },
        { "graphql" },
        { "html" },
        { "jsonls" },
        { "eslint" },
        {
          "rust_analyzer",
          {

            settings = {
              ["rust-analyzer"] = {
                imports = {
                  granularity = {
                    group = "module",
                  },
                  prefix = "self",
                },
                cargo = {
                  buildScripts = {
                    enable = true,
                  },
                },
                procMacro = {
                  enable = true,
                },
              },
            },
          },
        },
        { "terraformls" },
        {
          "omnisharp",
          {
            cmd = { "dotnet", "/Users/tylerevans/.bin/omnisharp/OmniSharp.dll" },
            enable_editorconfig_support = true,
            organize_imports_on_format = true,
            enable_import_completion = true,
          },
        },
      }
      local defaultSettings = {
        on_attach = on_attach,
        capabilities = capabilities,
      }
      for _, lsp in ipairs(servers) do
        local server = lsp[1]
        local settings = lsp[2]

        lspconfig[server].setup(Util.merge(defaultSettings, settings))
      end
    end,
  },
}
