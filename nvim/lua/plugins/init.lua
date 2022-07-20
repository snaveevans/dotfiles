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
    ["phaazon/hop.nvim"] = {
        branch = 'v2',
        config = function()
            require("plugins.configs.others").hop()
        end
    },
    ["jiangmiao/auto-pairs"] = {},
    ["junegunn/fzf"] = {
        run = './install --bin',
    },
    ["ibhagwan/fzf-lua"] = {
        requires = "junegunn/fzf",
        config = function()
            require("plugins.configs.others").fzf()
        end,
    },
    ["tpope/vim-surround"] = {},
    ["nvim-treesitter/nvim-treesitter-textobjects"] = {},
    ["nvim-treesitter/nvim-treesitter"] = {
      requires = { "nvim-treesitter/nvim-treesitter-textobjects" },
      run = ":TSUpdate",
    },
    ["lewis6991/gitsigns.nvim"] = {
        ft = "gitcommit",
        config = function()
            require("plugins.configs.others").gitsigns()
        end,
    },
}

require("core.packer").run(plugins)
