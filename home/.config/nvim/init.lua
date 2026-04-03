-- VSCode Neovim integration setup
if vim.g.vscode then
    -- Disable Snacks animations (LazyVim compatibility)
    vim.g.snacks_animate = false

    -- Set up basic options for VSCode
    vim.opt.clipboard = "unnamedplus"
    vim.opt.ignorecase = true
    vim.opt.smartcase = true
    vim.opt.hlsearch = true
    vim.opt.incsearch = true

    -- Disable some Neovim features that conflict with VSCode
    vim.opt.backup = false
    vim.opt.writebackup = false
    vim.opt.swapfile = false

    -- Better search behavior
    vim.opt.wrapscan = true
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load vscode module after plugins are loaded (only in VSCode)
if vim.g.vscode then
    vim.schedule(function()
        local vscode = require("vscode")
        -- Set VSCode notifications as default
        vim.notify = vscode.notify
    end)
end
