-- VSCode Neovim integration setup
if vim.g.vscode then
    -- Set up basic options for VSCode
    vim.opt.clipboard = "unnamedplus"
    vim.opt.ignorecase = true
    vim.opt.smartcase = true
    vim.opt.hlsearch = true
    vim.opt.incsearch = true
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
