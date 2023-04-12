"======================================================================
" => Plugins Installation
"======================================================================

" Install vim-plug if it isn't
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
" Make sure you use single quotes

Plug 'joshdick/onedark.vim'
Plug 'itchyny/lightline.vim'
Plug 'phaazon/hop.nvim'
Plug 'windwp/nvim-autopairs'
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip'
Plug 'numToStr/Comment.nvim'
Plug 'windwp/nvim-ts-autotag'
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'sbdchd/neoformat'

" Initialize plugin system
call plug#end()


"======================================================================
" => General
"======================================================================
" Sets how many lines of history VIM has to remember
set history=500

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread
au CursorHold,CursorHoldI * checktime
au FocusGained,BufEnter * :checktime

" :W sudo saves the file
" (useful for handling the permission-denied error)
command! W w !sudo tee % > /dev/null


"======================================================================
" => VIM user interface
"======================================================================
" Set 3 lines to the cursor - when moving vertically using j/k
set noshowmode

" Enable syntax highlight
syntax on

" For vertical line tabs
set list

" Set default splits
set diffopt+=vertical

" Turn on the Wild menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" For regular expressions turn magic on
set magic

" How many tenths of a second to blink when matching brackets
set mat=2

set omnifunc=syntaxcomplete#Complete

" Don't autoselect first omnicomplete option, show options even if there is only
" one (so the preview documentation is accessible). Remove 'preview' if you
" don't want to see any documentation whatsoever.
set completeopt=longest,menuone,preview
inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
  \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
  \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'


"======================================================================
" => Colors and Fonts
"======================================================================
" Enable syntax highlighting
syntax enable

" Enable 256 colors palette in Gnome Terminal
if $COLORTERM == 'gnome-terminal'
    set t_Co=256
endif

try
   " The best color scheme
   colorscheme onedark
catch
endtry


"======================================================================
" => Files, backups and undo
"======================================================================
" Turn backup off, since most stuff is in SVN, git et.c anyway...

"======================================================================
" => Text, tab and indent related
"======================================================================
" Linebreak on 500 characters

"======================================================================
" => Visual mode related
"======================================================================
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>


"======================================================================
" => Moving around, tabs, windows and buffers
"======================================================================
" Easy tab movement in normal mode
map <silent> th  :tabfirst<CR>
map <silent> tk  :tabnext<CR>
map <silent> tj  :tabprev<CR>
map <silent> tl  :tablast<CR>
map tt  :tabedit<Space>
map tm  :tabmove<Space>
map <silent> td  :tabclose<CR>
map <silent> ty  :tabonly<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()


" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"======================================================================
" => Editing mappings
"======================================================================
" Delete trailing white space on save, useful for some filetypes ;)
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

if has("autocmd")
    autocmd BufWritePre *.txt,*.js,*.py,*.wiki,*.sh,*.coffee :call CleanExtraSpaces()
endif


"======================================================================
" => Helper functions
"======================================================================

function! SaveLastReg()
    if v:event['regname']==""
        if v:event['operator']=='y'
            for i in range(8,1,-1)
                exe "let @".string(i+1)." = @". string(i) 
            endfor
            if exists("g:last_yank")
                let @1=g:last_yank
            endif
            let g:last_yank=@"
        endif 
    endif
endfunction 

function! CmdLine(str)
	call feedkeys(":" . a:str)
endfunction

function! VisualSelection(direction, extra_filter) range
	let l:saved_reg = @"
	execute "normal! vgvy"

	let l:pattern = escape(@", "\\/.*'$^~[]")
	let l:pattern = substitute(l:pattern, "\n$", "", "")

	if a:direction == 'gv'
		call CmdLine("Rg '" . l:pattern . "' " )
	elseif a:direction == 'replace'
		call CmdLine("%s" . '/'. l:pattern . '/')
	endif

	let @/ = l:pattern
	let @" = l:saved_reg
endfunction

function! OpenFileInVsLike(likeness)
  call OpenFileInWdLike(a:likeness, "vs")
endfunction

function! OpenFileInWdLike(likeness, mode)
	let l:files = split(globpath(expand("%:p:h"), "*"), "\n")
	let l:filteredFiles = filter(l:files, function("FilterComponentFile", [a:likeness]))
	if len(l:filteredFiles) >= 1
		execute a:mode." ".fnameescape(l:filteredFiles[0])
	endif
endfunction

function! FilterComponentFile(desiredFile, idx, filePath)
	if a:filePath =~ a:desiredFile
		return 1
	else
		return 0
	endif
endfunction

function! SaveSession(force)
  if (filereadable("Session.vim") || a:force)
    execute printf('mksession! %s/%s', getcwd(), 'Session.vim')
    echo "Saved Session"
  endif
endfunction
function! LoadSession()
  execute 'source ' . 'Session.vim'
endfunction

"======================================================================
" => Plugin Configuration
"======================================================================

"======================================================================
" => Netrw

let g:netrw_banner = 0
let g:netrw_liststyle = 1
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
let g:netrw_keepdir = 0
hi! link netrwMarkFile Search

augroup NetrwCommands
	autocmd!
	" Ensure netrw doesn't open
	autocmd VimEnter * silent! au! FileExplorer
augroup END


"======================================================================
" => itchyny/lightline.vim

let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'relativepath', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'FugitiveHead'
      \ },
      \ }


"======================================================================
" => phaazon/hop.nvim

lua << EOF
  require'hop'.setup()

  vim.api.nvim_set_keymap('n', '<space><space>a', "<cmd>lua require'hop'.hint_words()<cr>", {})
  vim.api.nvim_set_keymap('n', '<space><space>w', "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR })<cr>", {})
  vim.api.nvim_set_keymap('n', '<space><space>b', "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR })<cr>", {})

  vim.api.nvim_set_keymap('n', '<space><space>l', "<cmd>lua require'hop'.hint_lines()<cr>", {})

EOF

"======================================================================
" => windwp/nvim-autopairs
lua << EOF
require("nvim-autopairs").setup {}
EOF

"======================================================================
" => Fzf

" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1
" - Popup window (anchored to the bottom of the current window)
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'yoffset': 1.0 } }
let g:fzf_preview_window = ['right:50%', 'ctrl-/']

nnoremap <silent> <Leader>p :Files<CR>
nnoremap <silent> <Leader>P :AllFiles<CR>
nnoremap <silent> <Leader>l :Files <c-r>=expand("%:p:h")<cr>/<CR>
nnoremap <silent> <Leader>o :Buffers<CR>
nnoremap <silent> <c-space> :Buffers<CR>
nnoremap <silent> <Leader>ft :Filetypes<CR>
nnoremap <silent> <Leader>m :Maps<CR>
nnoremap <silent> <Leader>/ :BLines<CR>
nnoremap <silent> <Leader>' :Marks<CR>
nnoremap <silent> <Leader>g :Commits<CR>
nnoremap <silent> <Leader>H :Helptags<CR>
nnoremap <silent> <Leader>hh :History<CR>
nnoremap <silent> <Leader>h: :History:<CR>
nnoremap <silent> <Leader>h/ :History/<CR>

let g:fzf_action = {
  \ 'ctrl-space': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

nnoremap <silent> <leader>s  :Rg <CR>
nnoremap <silent> <leader>S  :Rg 
vnoremap <silent> <leader>s :<C-u>call VisualSelection('', '')<CR>:Rg <C-R>=@/<CR><CR>
vnoremap <silent> <leader>fa :<C-u>call VisualSelection('', '')<CR>:Rg <C-R>=@/<CR><CR>
vnoremap <silent> <leader>fe :<C-u>call VisualSelection('', '')<CR>:Rg \b<C-R>=@/<CR>\b<CR>
nmap <silent> <leader>fa :Rg <C-r>=expand("<cword>")<CR><CR>
nmap <silent> <leader>fe :Rg \b<C-r>=expand("<cword>")<CR>\b<CR>

command! -bang -nargs=? -complete=dir Files
      \ call fzf#vim#files(<q-args>, {'source': 'rg --files --hidden --follow --glob=\!.git'}, <bang>0)

command! -bang -nargs=? -complete=dir AllFiles
      \ call fzf#vim#files(<q-args>, {'source': 'rg --files --hidden --follow --no-ignore'}, <bang>0)

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>),
  \   1,
  \   fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)
" set internal grep to use rg
set grepprg=rg\ --vimgrep\ --smart-case\ --follow

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

"======================================================================
" => vim-fugitive

nnoremap <leader>gs  :Git<CR>
nnoremap <leader>gd  :Gdiffsplit!<CR>
nnoremap <leader>gc  :Git commit<CR>
nnoremap <leader>gw  :Gwrite<CR>
nnoremap <leader>gp  :Git push<CR>
nnoremap <leader>gb  :Git blame<CR>
nnoremap <leader>gm  :Git mergetool<CR>
nnoremap <leader>gt  :Git difftool<CR>
nnoremap <leader>gv  :GMove <c-r>=expand("%:.")<cr>

" macro to open file from GStatus in new tab
" nnoremap <leader>gh @x
let @x='_wvg_"hy:tabnew h'

"======================================================================
" => vim-closetag

let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.vue,*.jsx,*.tsx,*.js'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'
let g:closetag_filetypes = 'html,xhtml,phtml,vue'
let g:closetag_xhtml_filetypes = 'xhtml,jsx,tsx'
let g:closetag_emptyTags_caseSensitive = 1
let g:closetag_regions = {
    \ 'typescript.tsx': 'jsxRegion,tsxRegion',
    \ 'javascript.jsx': 'jsxRegion',
    \ }

"======================================================================
" => nvim-treesitter 

lua <<EOF
require('nvim-treesitter.configs').setup {
  ensure_installed = { 'bash', 'c', 'cmake', 'comment', 'c_sharp', 'css', 'dockerfile', 'fish', 'html', 'http', 'graphql', 'java', 'javascript', 'jsdoc', 'json', 'json5', 'jsonc', 'lua', 'rust', 'scss', 'tsx', 'typescript', 'vim', 'yaml' },
  sync_install = false,
  highlight = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  indent = {
    enable = true,
  },
  autotag = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['aa'] = '@call.outer',
        ['ia'] = '@call.inner',
        ['ao'] = '@conditional.outer',
        ['io'] = '@conditional.inner',
        ['ar'] = '@parameter.outer',
        ['ir'] = '@parameter.inner',
        ['ab'] = '@block.outer',
        ['ib'] = '@block.inner',
        ['al'] = '@loop.outer',
        ['il'] = '@loop.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@block.outer',
        [']]'] = '@call.outer',
      },
      goto_next_end = {
        [']M'] = '@block.outer',
        [']['] = '@call.outer',
      },
      goto_previous_start = {
        ['[m'] = '@block.outer',
        ['[['] = '@call.outer',
      },
      goto_previous_end = {
        ['[M'] = '@block.outer',
        ['[]'] = '@call.outer',
      },
    },
  },
}
EOF


"======================================================================
" => neovim/nvim-lspconfig 

lua << EOF
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  buf_set_keymap('n', '<leader>fx', ':EslintFixAll<CR>', opts)
  -- buf_set_keymap('n', '<space>fd', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

end

-- Add additional capabilities supported by nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local lspconfig = require('lspconfig')

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { 'tsserver', 'cssls', 'graphql', 'html', 'jsonls', 'eslint', 'rls' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end,
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}
EOF

"======================================================================
" => numToStr/Comment.nvim

lua << EOF
require('Comment').setup()
EOF

"======================================================================
" => lewis6991/gitsigns.nvim

lua << EOF
require('gitsigns').setup {
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
EOF

"======================================================================
" => sbdchd/neoformat

nmap <leader>fd :Neoformat<cr>

"======================================================================
" => Misc
" save last reg into the next reg
au! TextYankPost * call SaveLastReg()

nmap <leader>ve :tabedit ~/.config/nvim/init.vim<cr>
nmap <leader>vr :source ~/.config/nvim/init.vim<cr>

au! VimLeave * call SaveSession(0)
nnoremap <silent> <F5> :call SaveSession(1)<CR>
nnoremap <silent> <F8> :call LoadSession()<CR>

" find & replace
vnoremap <leader>fr :<C-u>call VisualSelection('', '')<CR>:%s/<C-R>=@/<CR>/
nnoremap <leader>fr :%s/<C-r>=expand("<cword>")<CR>/
