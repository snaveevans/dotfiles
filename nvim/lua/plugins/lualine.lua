return {
  "nvim-lualine/lualine.nvim",
  -- optional = true,
  event = "VeryLazy",
  -- opts = function(_, opts)
  --   local Util = require("util")
  --   local colors = {
  --     [""] = Util.fg("Special"),
  --     ["Normal"] = Util.fg("Special"),
  --     ["Warning"] = Util.fg("DiagnosticError"),
  --     ["InProgress"] = Util.fg("DiagnosticWarn"),
  --   }
  --   table.insert(opts.sections.lualine_x, 2, {
  --     function()
  --       local icon = "CO: "
  --       local status = require("copilot.api").status.data
  --       return icon .. (status.message or "")
  --     end,
  --     cond = function()
  --       local ok, clients = pcall(vim.lsp.get_active_clients, { name = "copilot", bufnr = 0 })
  --       return ok and #clients > 0
  --     end,
  --     color = function()
  --       if not package.loaded["copilot"] then
  --         return
  --       end
  --       local status = require("copilot.api").status.data
  --       return colors[status.status] or colors[""]
  --     end,
  --   })
  -- end,
  config = function()
    local lualine = require("lualine")

    local diagnostics = {
      "diagnostics",
      sources = { "nvim_diagnostic" },
      sections = { "error", "warn" },
      symbols = { error = " :", warn = "! :" },
      colored = false,
      update_in_insert = false,
      always_visible = true,
    }

    local mode = {
      "mode",
      fmt = function(str)
        return "-- " .. str .. " --"
      end,
    }

    local filetype = {
      "filetype",
      icons_enabled = false,
      icon = nil,
    }

    local branch = {
      "branch",
      icons_enabled = true,
      icon = "",
    }

    local filename = {
      "filename",
      file_status = true, -- Displays file status (readonly status, modified status)
      newfile_status = false, -- Display new file status (new file means no write after created)
      path = 1, -- 0: Just the filename
      shorting_target = 40, -- Shortens path to leave 40 spaces in the window
      symbols = {
        modified = "[+]", -- Text to show when the file is modified.
        readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
        unnamed = "[No Name]", -- Text to show for unnamed buffers.
        newfile = "[New]", -- Text to show for newly created file before first write
      },
    }

    -- cool function for progress
    local progress = function()
      local current_line = vim.fn.line(".")
      local total_lines = vim.fn.line("$")
      local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
      local line_ratio = current_line / total_lines
      local index = math.ceil(line_ratio * #chars)
      return chars[index]
    end

    local spaces = function()
      return "spaces: " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
    end

    lualine.setup({
      options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        -- ignore_focus = { "lua", "typescript", "typescriptreact", "javascript", "javascriptreact" },
        disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { branch, diagnostics },
        lualine_b = { mode },
        lualine_c = { filename },
        -- lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_x = { "diff", spaces, "encoding", filetype },
        lualine_y = { "location" },
        lualine_z = { progress },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { filename },
        -- lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_x = { spaces, "encoding", filetype },
        lualine_y = { "location" },
        lualine_z = {},
      },
      tabline = {},
      extensions = {},
    })
  end,
}
