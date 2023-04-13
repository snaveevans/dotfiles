return {
    {
        "joshdick/onedark.vim",
        lazy = false,
        priority = 1000,
        config = function()
            -- load the colorscheme here
            vim.cmd([[colorscheme onedark]])
        end,
    }
}
