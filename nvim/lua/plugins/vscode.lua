-- VSCode Neovim integration configuration
if not vim.g.vscode then
    return {}
end

-- Disable plugins that don't work well or aren't needed in VSCode
return {
    -- Disable UI plugins that conflict with VSCode
    { "folke/noice.nvim",                        enabled = false },
    { "rcarriga/nvim-notify",                    enabled = false },
    { "nvim-lualine/lualine.nvim",               enabled = false },
    { "akinsho/bufferline.nvim",                 enabled = false },
    { "lukas-reineke/indent-blankline.nvim",     enabled = false },
    { "nvim-mini/mini.indentscope",              enabled = false },
    { "folke/which-key.nvim",                    enabled = false },
    { "goolord/alpha-nvim",                      enabled = false },
    { "nvim-neo-tree/neo-tree.nvim",             enabled = false },
    { "folke/trouble.nvim",                      enabled = false },
    { "nvim-treesitter/nvim-treesitter-context", enabled = false },
    { "stevearc/dressing.nvim",                  enabled = false },
    { "folke/edgy.nvim",                         enabled = false },
    { "nvim-pack/nvim-spectre",                  enabled = false },

    -- Disable LSP and completion plugins (VSCode handles these)
    { "neovim/nvim-lspconfig",                   enabled = false },
    { "mason-org/mason.nvim",                    enabled = false },
    { "mason-org/mason-lspconfig.nvim",          enabled = false },
    { "hrsh7th/nvim-cmp",                        enabled = false },
    { "hrsh7th/cmp-nvim-lsp",                    enabled = false },
    { "hrsh7th/cmp-buffer",                      enabled = false },
    { "hrsh7th/cmp-path",                        enabled = false },
    { "L3MON4D3/LuaSnip",                        enabled = false },
    { "saadparwaiz1/cmp_luasnip",                enabled = false },
    { "folke/lazydev.nvim",                      enabled = false },

    -- Disable file management plugins (VSCode handles these)
    { "ibhagwan/fzf-lua",                        enabled = false },
    { "nvim-telescope/telescope.nvim",           enabled = false },

    -- Disable formatting plugins (use VSCode's formatter)
    { "stevearc/conform.nvim",                   enabled = false },
    { "mfussenegger/nvim-lint",                  enabled = false },

    -- Disable terminal and task plugins (VSCode handles these)
    { "akinsho/toggleterm.nvim",                 enabled = false },
    { "folke/snacks.nvim",                       enabled = false },

    -- Disable git plugins (VSCode handles these better)
    { "lewis6991/gitsigns.nvim",                 enabled = false },
    { "kdheepak/lazygit.nvim",                   enabled = false },

    -- Disable debugging plugins (use VSCode debugger)
    { "mfussenegger/nvim-dap",                   enabled = false },
    { "rcarriga/nvim-dap-ui",                    enabled = false },
    { "theHamsta/nvim-dap-virtual-text",         enabled = false },

    -- Disable session management (VSCode handles workspaces)
    { "folke/persistence.nvim",                  enabled = false },

    -- Disable colorscheme plugins (VSCode theme takes precedence)
    { "folke/tokyonight.nvim",                   enabled = false },
    { "catppuccin/nvim",                         enabled = false },

    -- Keep useful text manipulation plugins
    { "nvim-mini/mini.surround",                 enabled = true },
    { "nvim-mini/mini.comment",                  enabled = true },
    { "nvim-mini/mini.pairs",                    enabled = true },
    { "nvim-mini/mini.ai",                       enabled = true },

    -- Keep useful editing plugins
    { "folke/flash.nvim",                        enabled = true },

    -- TreeSitter: useful for text objects and syntax
    {
        "nvim-treesitter/nvim-treesitter",
        enabled = true,
        opts = {
            highlight = { enable = false }, -- VSCode handles syntax highlighting
            indent = { enable = false },    -- VSCode handles indentation
        }
    },
    { "nvim-treesitter/nvim-treesitter-textobjects", enabled = true },

    -- Optional: better word motions
    { "chaoren/vim-wordmotion",                      enabled = true },
}
