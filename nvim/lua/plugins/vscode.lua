-- VSCode Neovim integration configuration
if not vim.g.vscode then
    return {}
end

-- Disable plugins that don't work well or aren't needed in VSCode
return {
    -- Disable UI plugins that conflict with VSCode
    { "folke/noice.nvim",                            enabled = false },
    { "rcarriga/nvim-notify",                        enabled = false },
    { "nvim-lualine/lualine.nvim",                   enabled = false },
    { "akinsho/bufferline.nvim",                     enabled = false },
    { "lukas-reineke/indent-blankline.nvim",         enabled = false },
    { "echasnovski/mini.indentscope",                enabled = false },
    { "folke/which-key.nvim",                        enabled = false },
    { "goolord/alpha-nvim",                          enabled = false },
    { "nvim-neo-tree/neo-tree.nvim",                 enabled = false },
    { "folke/trouble.nvim",                          enabled = false },
    { "nvim-treesitter/nvim-treesitter-context",     enabled = false },

    -- Disable LSP and completion plugins (VSCode handles these)
    { "neovim/nvim-lspconfig",                       enabled = false },
    { "williamboman/mason.nvim",                     enabled = false },
    { "williamboman/mason-lspconfig.nvim",           enabled = false },
    { "hrsh7th/nvim-cmp",                            enabled = false },
    { "hrsh7th/cmp-nvim-lsp",                        enabled = false },
    { "hrsh7th/cmp-buffer",                          enabled = false },
    { "hrsh7th/cmp-path",                            enabled = false },
    { "L3MON4D3/LuaSnip",                            enabled = false },
    { "saadparwaiz1/cmp_luasnip",                    enabled = false },

    -- Disable file management plugins (VSCode handles these)
    { "ibhagwan/fzf-lua",                            enabled = false },
    { "nvim-telescope/telescope.nvim",               enabled = false },

    -- Disable formatting plugins (use VSCode's formatter)
    { "stevearc/conform.nvim",                       enabled = false },
    { "mfussenegger/nvim-lint",                      enabled = false },

    -- Disable terminal plugins
    { "akinsho/toggleterm.nvim",                     enabled = false },

    -- Disable colorscheme plugins (VSCode theme takes precedence)
    { "folke/tokyonight.nvim",                       enabled = false },
    { "catppuccin/nvim",                             enabled = false },

    -- Keep useful text manipulation plugins
    { "echasnovski/mini.surround",                   enabled = true },
    { "echasnovski/mini.comment",                    enabled = true },
    { "echasnovski/mini.pairs",                      enabled = true },
    { "echasnovski/mini.ai",                         enabled = true },

    -- Keep useful editing plugins
    { "folke/flash.nvim",                            enabled = true },
    { "nvim-treesitter/nvim-treesitter",             enabled = true },
    { "nvim-treesitter/nvim-treesitter-textobjects", enabled = true },
}
