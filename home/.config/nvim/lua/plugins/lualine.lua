return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
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

    local filetype = {
      "filetype",
      icons_enabled = false,
      icon = nil,
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

    local progress = function()
      local current_line = vim.fn.line(".")
      local total_lines = vim.fn.line("$")
      local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
      local line_ratio = current_line / total_lines
      local index = math.ceil(line_ratio * #chars)
      return chars[index]
    end

    lualine.setup({
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', diagnostics },
        lualine_c = { filename },
        lualine_x = { "diff", "encoding", filetype },
        lualine_y = { "location" },
        lualine_z = { progress },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { filename },
        lualine_x = { "diff", "encoding", filetype },
        lualine_y = { "location" },
        lualine_z = {},
      },
      tabline = {},
      extensions = {},
    })
  end,
}
