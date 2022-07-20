local M = {}

M.bootstrap = function()
    local fn = vim.fn
    local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"

    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1e222a" })

    if fn.empty(fn.glob(install_path)) > 0 then
        print "Cloning packer .."
        fn.system { "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path }

        -- install plugins + compile their configs
        vim.cmd "packadd packer.nvim"
        require "plugins"
        vim.cmd "PackerSync"
    end
end

M.run = function(plugins)
    local present, packer = pcall(require, "packer")

    if not present then
        return
    end

    packer.init()

    packer.startup(function(use)
        for name, v in pairs(plugins) do
            local options = vim.tbl_deep_extend("force", { [1] = name }, v)
            use(options)
        end
    end)
end

return M
