local M = {}

local load_override = require("core.utils").load_override

M.gitsigns = function()
   local present, gitsigns = pcall(require, "gitsigns")

   if not present then
      return
   end

   local options = {
      signs = {
         add = { hl = 'GitGutterAdd', text = '+' },
         change = { hl = 'GitGutterChange', text = '~' },
         delete = { hl = 'GitGutterDelete', text = '_' },
         topdelete = { hl = 'GitGutterDelete', text = '‾' },
         changedelete = { hl = 'GitGutterChange', text = '~' },
      },
      current_line_blame = true,
      current_line_blame_opts = {
         virt_text = true,
         virt_text_pos = 'eol',
         delay = 250,
         ignore_whitespace = false,
      },
   }

   options = load_override(options, "lewis6991/gitsigns.nvim")
   gitsigns.setup(options)
end


return M
