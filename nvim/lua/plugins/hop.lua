-- place this in one of your configuration file(s)
return {
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
}
