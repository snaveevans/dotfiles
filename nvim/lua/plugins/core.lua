-- place this in one of your configuration file(s)
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
        config = true
    },
    {
        "phaazon/hop.nvim",
        config = function()
            local hop = require('hop')
            local directions = require('hop.hint').HintDirection

            hop.setup { keys = 'etovxqpdygfblzhckisuran' }

            vim.keymap.set('n', '<leader><leader>w', function()
                hop.hint_words({ direction = directions.AFTER_CURSOR })
            end, {})

            vim.keymap.set('n', '<leader><leader>b', function()
                hop.hint_words({ direction = directions.BEFORE_CURSOR })
            end, {})
        end
    },
    {
        "ibhagwan/fzf-lua",
        keys = function()
            return {
                { "<leader>p", function()
                    require('fzf-lua').files()
                end },
                { "<leader>o", function()
                    require('fzf-lua').buffers()
                end },
                { "<leader>s", function()
                    require('fzf-lua').grep()
                end },
                { "<leader>S", function()
                    require('fzf-lua').live_grep()
                end },
            }
        end
    },
    {
        "sbdchd/neoformat",
        keys = {
            { "<leader>fd", ":Neoformat<cr>" }
        }
    },
    {
      "numToStr/Comment.nvim",
      config = true
    }
}
