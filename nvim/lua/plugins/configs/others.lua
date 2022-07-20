local M = {}

local load_override = require("core.utils").load_override

M.hop = function()
   local present, hop = pcall(require, "hop")

   if not present then
      return
   end
   hop.setup()

   vim.api.nvim_set_keymap('n', '<leader><leader>a', "<cmd>lua require'hop'.hint_words()<cr>", {})
   vim.api.nvim_set_keymap('n', '<leader><leader>w',
      "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR })<cr>", {})
   vim.api.nvim_set_keymap('n', '<leader><leader>b',
      "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR })<cr>", {})
   vim.api.nvim_set_keymap('n', '<leader><leader>l', "<cmd>lua require'hop'.hint_lines()<cr>", {})
end

M.fzf = function()
end

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
