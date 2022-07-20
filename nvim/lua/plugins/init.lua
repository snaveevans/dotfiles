vim.cmd "packadd packer.nvim"

local plugins = {
    ["nvim-lua/plenary.nvim"] = { module = "plenary" },
    ["wbthomason/packer.nvim"] = {},
    ["joshdick/onedark.vim"] = {
        config = function()
            vim.cmd [[colorscheme onedark]]
        end
    },
    ["tpope/vim-fugitive"] = {},
    ["lewis6991/gitsigns.nvim"] = {
        ft = "gitcommit",
        config = function()
            require("plugins.configs.others").gitsigns()
        end,
    },
}

require("core.packer").run(plugins)
