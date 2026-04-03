-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local options = {
  backup = false,                                    -- creates a backup file
  cmdheight = 1,                                     -- more space in the neovim command line for displaying messages
  completeopt = { "longest", "menuone", "preview" }, -- mostly just for cmp
  fileformats = { "unix", "dos", "mac" },            -- Use Unix as the standard file type
  fileencoding = "utf-8",                            -- the encoding written to a file
  hlsearch = true,                                   -- highlight all matches on previous search pattern
  ignorecase = true,                                 -- ignore case in search patterns
  showmode = false,                                  -- we don't need to see things like -- INSERT -- anymore
  smartcase = true,                                  -- smart case
  smartindent = true,                                -- make indenting smarter again
  splitbelow = true,                                 -- force all horizontal splits to go below current window
  splitright = true,                                 -- force all vertical splits to go to the right of current window
  swapfile = false,                                  -- creates a swapfile
  updatetime = 300,                                  -- faster completion (4000ms default)
  writebackup = false,                               -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  expandtab = true,                                  -- convert tabs to spaces
  softtabstop = 0,                                   -- Number of spaces a <Tab> counts for. When 0, featuer is off (sts).
  autoindent = true,                                 -- Copy indent from current line when starting a new line.
  smarttab = true,                                   -- Inserts blanks on a <Tab> key (as per sw, ts and sts).
  shiftwidth = 2,                                    -- the number of spaces inserted for each indentation
  tabstop = 2,                                       -- insert 2 spaces for a tab
  cursorline = true,                                 -- highlight the current line
  number = true,                                     -- set numbered lines
  relativenumber = false,                            -- set relative numbered lines
  numberwidth = 4,                                   -- set number column width to 2 {default 4}
  signcolumn = "yes",                                -- always show the sign column, otherwise it would shift the text each time
  wrap = true,                                       -- display lines as one long line
  linebreak = true,                                  -- companion to wrap, don't split words
  textwidth = 500,                                   -- wrap after 500 characters
  scrolloff = 3,                                     -- minimal number of screen lines to keep above and below the cursor
  ruler = true,
  lazyredraw = true,                                 -- Don't redraw while executing macros (good performance config)
  incsearch = true,                                  -- Makes search act like search in modern browsers
  showmatch = true,                                  -- Show matching brackets when text indicator is over them
  foldcolumn = "1",                                  -- Add a bit extra margin to the left
  background = "dark",
  grepprg = "rg --vimgrep --smart-case --follow",    -- default command for :grep
  laststatus = 1,
}

-- VSCode-specific options
if vim.g.vscode then
  -- Disable features that conflict with VSCode
  options.list = false       -- disable listchars in VSCode
  options.cursorline = false -- VSCode handles cursor line highlighting
  options.number = false     -- VSCode handles line numbers
  options.signcolumn = "no"  -- VSCode handles sign column
  options.foldcolumn = "0"   -- VSCode handles folding
  options.laststatus = 0     -- Hide status line in VSCode
  options.cmdheight = 0      -- Hide command line in VSCode
else
  options.list = true        -- enable listchars in regular neovim
end

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.opt.shortmess:append("c")                         -- don't give |ins-completion-menu| messages
vim.opt.iskeyword:append("-")                         -- hyphenated words recognized by searches
vim.opt.formatoptions:remove({ "c", "r", "o" })       -- don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode.
vim.opt.runtimepath:remove("/usr/share/vim/vimfiles") -- separate vim plugins from neovim in case vim still in use

-- Only set listchars if not in VSCode
if not vim.g.vscode then
  vim.opt.listchars = {
    space = "·",
    nbsp = "_",
    trail = "•",
    eol = "↲",
    extends = "«",
    precedes = "»",
  }
  vim.opt.listchars["tab"] = "|"
end

vim.opt.diffopt:append({ "vertical" })

-- Configure Neovim to use a fixed Node.js version (bypassing asdf project-specific versions)
-- This ensures consistent behavior across all projects
local node_version = "22.14.0"
local node_path = vim.fn.expand("~/.asdf/installs/nodejs/" .. node_version .. "/bin")
local node_host_prog = node_path .. "/neovim-node-host"

-- Set the node host program for Neovim providers
vim.g.node_host_prog = node_host_prog

-- Prepend the fixed Node.js version to PATH for all Neovim operations
vim.env.PATH = node_path .. ":" .. vim.env.PATH
