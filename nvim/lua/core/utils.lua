local M = {}

local merge_tb = vim.tbl_deep_extend

M.load_override = function(default_table, plugin_name)
    local user_table = M.load_config().plugins.override[plugin_name] or {}
    user_table = type(user_table) == "table" and user_table or user_table()
    return merge_tb("force", default_table, user_table)
end

M.load_config = function()
    local config = require "core.default_config"

    config.mappings.disabled = nil
    return config
end

M.load_mappings = function(mappings, mapping_opt)
    -- set mapping function with/without whichkey
    local set_maps
    local whichkey_exists, wk = pcall(require, "which-key")

    if whichkey_exists then
        set_maps = function(keybind, mapping_info, opts)
            wk.register({ [keybind] = mapping_info }, opts)
        end
    else
        set_maps = function(keybind, mapping_info, opts)
            local mode = opts.mode
            opts.mode = nil
            vim.api.nvim_set_keymap(mode, keybind, mapping_info[1], opts)
        end
    end

    mappings = mappings or vim.deepcopy(M.load_config().mappings)
    mappings.lspconfig = nil

    for _, section in pairs(mappings) do
        for mode, mode_values in pairs(section) do
            for keybind, mapping_info in pairs(mode_values) do
                -- merge default + user opts
                local default_opts = merge_tb("force", { mode = mode }, mapping_opt or {})
                local opts = merge_tb("force", default_opts, mapping_info.opts or {})

                if mapping_info.opts then
                    mapping_info.opts = nil
                end

                set_maps(keybind, mapping_info, opts)
            end
        end
    end
end

return M
