
" Sections:
"    -> Plugins Installation
"    -> General
"    -> VIM user interface
"    -> Colors and Fonts
"    -> Files and backups
"    -> Text, tab and indent related
"    -> Visual mode related
"    -> Moving around, tabs and buffers
"    -> Status line
"    -> Editing mappings
"    -> vimgrep searching and cope displaying
"    -> Spell checking
"    -> Misc
"    -> Helper functions
"    -> Plugin Configuration
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins Installation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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

" Vim
Plug 'joshdick/onedark.vim'
Plug 'vim-airline/vim-airline'

" General
Plug 'easymotion/vim-easymotion'
Plug 'jiangmiao/auto-pairs'
Plug '/usr/local/opt/fzf'
" Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'terryma/vim-multiple-cursors'

" Languages > 1
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sheerun/vim-polyglot'
" Plug 'dense-analysis/ale'

" HTML
Plug 'alvan/vim-closetag'

" c#
" Plug 'omnisharp/omnisharp-vim'

" scala
" Plug 'scalameta/coc-metals', {'do': 'yarn install --frozen-lockfile'}
" Plug 'derekwyatt/vim-scala'

" Initialize plugin system
call plug#end()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sets how many lines of history VIM has to remember
set history=500

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread
au CursorHold,CursorHoldI * checktime
au FocusGained,BufEnter * :checktime

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = " "
" map <Space> <Leader>

" Fast saving
nmap <leader>w :w!<cr>
nmap <leader>aw :wa!<cr>
nmap <leader>q :q<cr>
nmap <leader>aq :qa<cr>

" :W sudo saves the file
" (useful for handling the permission-denied error)
command! W w !sudo tee % > /dev/null


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 3 lines to the cursor - when moving vertically using j/k
set so=3

" Enable syntax highlight
syntax on

" Show line numbers
set number

" Highlight line cursor is on
set cursorline

" Show vertical line for tabs, · for spaces, and ¶ end of line
set listchars=tab:\|\ ,space:·,nbsp:␣,trail:•,eol:$,precedes:«,extends:»

" For vertical line tabs
set list

" Set default splits
set splitright
set splitbelow
set diffopt+=vertical


" Avoid garbled characters in Chinese language windows OS
let $LANG='en'
set langmenu=en
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim

" Turn on the Wild menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

"Always show current position
set ruler

" Height of the command bar
set cmdheight=2

" A buffer becomes hidden when it is abandoned
set hidden

" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Properly disable sound on errors on MacVim
if has("gui_macvim")
    autocmd GUIEnter * set vb t_vb=
endif


" Add a bit extra margin to the left
set foldcolumn=1

set omnifunc=syntaxcomplete#Complete

" Don't autoselect first omnicomplete option, show options even if there is only
" one (so the preview documentation is accessible). Remove 'preview' if you
" don't want to see any documentation whatsoever.
set completeopt=longest,menuone,preview
inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
  \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
  \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

set background=dark

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

" This sets swap directory
" Set directory^=$HOME/.vim/tmp//
" Do not store global and local values in a session
" set ssop-=options
" Do not store folds
" set ssop-=folds


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

set tabstop=2     " Size of a hard tabstop (ts).
set shiftwidth=2  " Size of an indentation (sw).
set expandtab     " Always uses spaces instead of tab characters (et).
set softtabstop=0 " Number of spaces a <Tab> counts for. When 0, featuer is off (sts).
set autoindent    " Copy indent from current line when starting a new line.
set smarttab      " Inserts blanks on a <Tab> key (as per sw, ts and sts).


""""""""""""""""""""""""""""""
" => Visual mode related
""""""""""""""""""""""""""""""
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>

"copy and cut to  system
vnoremap <C-c> "+y
vnoremap <C-d> "+d
" delete without yanking \d
vnoremap <leader><leader>d "_d


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Moving around, tabs, windows and buffers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Smart way to move between windows
map <leader>j <C-W>j
map <leader>k <C-W>k
map <leader>h <C-W>h
map <leader>l <C-W>l

" Close the current buffer
map <leader>bd :bd<cr>

" Close all the buffers
map <leader>ba :bufdo bd<cr>

" Useful mappings for managing tabs
map <leader>t<leader> :tabnext

" Easy tab movement in normal mode
map <silent> th  :tabfirst<CR>
map <silent> tk  :tabnext<CR>
map <silent> tj  :tabprev<CR>
map <silent> tl  :tablast<CR>
map tt  :tabedit<Space>
map tn  :tabnext<Space>
map tm  :tabmove<Space>
map <silent> td  :tabclose<CR>
map <silent> ty  :tabonly<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()


" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>tn :tabedit <c-r>=expand("%:p:h")<cr>/

" Move up & down the buffer easier
nnoremap <leader>d  <C-f>
nnoremap <leader>u  <C-b>
nnoremap <C-j>  <C-d>
nnoremap <C-k>  <C-u>

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

nnoremap <leader>z :sus<cr>


""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Editing mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remap VIM 0 to first non-blank character
map 0 ^

" Move a line of text using ALT+[jk] or Command+[jk] on mac
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

if has("mac") || has("macunix")
  nmap <D-j> <M-j>
  nmap <D-k> <M-k>
  vmap <D-j> <M-j>
  vmap <D-k> <M-k>
endif

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


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Spell checking
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

" Shortcuts using <leader>
map <leader>sn ]s
map <leader>sp [s
map <leader>sa zg
map <leader>s? z=


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Misc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
imap jk <Esc>
" Remove the Windows ^M - when the encodings gets messed up
noremap <leader>v mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

" close buffer
map <leader>Q :q<cr>

" Quickly open a markdown buffer for scribble
map <leader>b :tabedit ~/buffer.md<cr>

" Quickly open a [No Name] buffer for scribble
map <leader>x :tabnew<cr>

" Toggle paste mode on and off
" map <leader>pp :setlocal paste!<cr>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Returns true if paste mode is enabled
function! HasPaste()
	if &paste
		return 'PASTE MODE  '
	endif
	return ''
endfunction

" Don't close window, when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
	let l:currentBufNum = bufnr("%")
	let l:alternateBufNum = bufnr("#")

	if buflisted(l:alternateBufNum)
		buffer #
	else
		bnext
	endif

	if bufnr("%") == l:currentBufNum
		new
	endif

	if buflisted(l:currentBufNum)
		execute("bdelete! ".l:currentBufNum)
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
		call CmdLine("Ag '" . l:pattern . "' " )
	elseif a:direction == 'replace'
		call CmdLine("%s" . '/'. l:pattern . '/')
	endif

	let @/ = l:pattern
	let @" = l:saved_reg
endfunction

function! DeleteHiddenBuffers()
	let tpbl=[]
	call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
	for buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
		silent execute 'bwipeout' buf
	endfor
endfunction

let g:prettier_supported_filetypes = ['js', 'jsx', 'ts', 'tsx', 'css', 'scss', 'html', 'vue']
function! FormatCode()
  if &filetype == 'cs'
    execute 'OmniSharpCodeFormat'
  elseif index(g:prettier_supported_filetypes, &filetype) >= 0
    execute 'Prettier'
  else
    execute 'Format'
  endif
endfunction

function! AngularOpenComponent()
	call OpenFileInWdLike(".component.ts", "e")
	call OpenFileInWdLike(".html", "vs")
	call OpenFileInWdLike(".scss", "vs")
	execute("wincmd =")
	execute("wincmd h")
	execute("wincmd h")
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

function! UseTabs()
  set tabstop=4     " Size of a hard tabstop (ts).
  set shiftwidth=4  " Size of an indentation (sw).
  set noexpandtab   " Always uses tabs instead of space characters (noet).
  set autoindent    " Copy indent from current line when starting a new line (ai).
endfunction

function! UseSpaces()
  set tabstop=2     " Size of a hard tabstop (ts).
  set shiftwidth=2  " Size of an indentation (sw).
  set expandtab     " Always uses spaces instead of tab characters (et).
  set softtabstop=0 " Number of spaces a <Tab> counts for. When 0, featuer is off (sts).
  set autoindent    " Copy indent from current line when starting a new line.
  set smarttab      " Inserts blanks on a <Tab> key (as per sw, ts and sts).
endfunction

function! SetTabs()
  if (index(['MakeFile'], &filetype) >= 0)
    call UseTabs()
  else
    call UseSpaces()
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Netrw
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
augroup NetrwCommands
	autocmd!
	" Open Explorer
	nnoremap <silent> <leader>e :Vexplore<cr>

	" Open Explorer in new Tab
	nnoremap <silent> <leader>n :Texplore<cr>
	" Open netrw as side drawer
	" autocmd VimEnter * :Vexplore

	" Ensure netrw doesn't open
	autocmd VimEnter * silent! au! FileExplorer
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Fzf
let $FZF_DEFAULT_COMMAND = 'ag -g ""'
nnoremap <silent><space>p :HFiles<CR>
" nnoremap <silent><space><space> :Buffers<CR>
nnoremap <silent><space>l :HFiles <c-r>=expand("%:p:h")<cr>/<CR>
nnoremap <silent><space>o :Buffers<CR>
nnoremap <leader>o :Buffers<CR>
nnoremap <leader>gh :BCommits<CR>
nnoremap <leader>ft :Filetypes<CR>
nnoremap <leader>hp :Helptags<CR>
nnoremap <leader>m :Maps<CR>
nnoremap <leader>c<space> :Commands<CR>

let g:fzf_action = {
  \ 'ctrl-space': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

nnoremap <leader>s  :Ag<CR>
nnoremap <leader>S  :Ag 
" Search selected using Ag
vnoremap <silent> <leader>s :<C-u>call VisualSelection('', '')<CR>:Ag <C-R>=@/<CR><CR>
vnoremap <silent> <leader>fa :<C-u>call VisualSelection('', '')<CR>:Rg <C-R>=@/<CR><CR>
vnoremap <silent> <leader>fe :<C-u>call VisualSelection('', '')<CR>:Rg \b<C-R>=@/<CR>\b<CR>
nmap <leader>fa :Rg <C-r>=expand("<cword>")<CR><CR>
nmap <leader>fe :Rg \b<C-r>=expand("<cword>")<CR>\b<CR>

" search selected text using :Ack
" vnoremap <leader>a :call SearchSelectedText()<CR>
command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=? -complete=dir HFiles
  \ call fzf#vim#files(<q-args>, {'source': 'ag --hidden --ignore .git -g ""'}, <bang>0)

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-fugitive
nnoremap <leader>gs  :Gstatus<CR>
nnoremap <leader>gd  :Gdiff<CR>
nnoremap <leader>gc  :Gcommit<CR>
nnoremap <leader>gp  :Gpush<CR>
nnoremap <leader>gw  :Gwrite<CR>
nnoremap <leader>gb  :Gblame<CR>

" macro to open file from GStatus in new tab
" nnoremap <leader>gh @x
let @x='_wvg_"hy:tabnew h'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-multiple-cursors
let g:multi_cursor_use_default_mapping=0

" Default mapping
let g:multi_cursor_start_word_key      = '<C-n>'
let g:multi_cursor_select_all_word_key = '<A-n>'
let g:multi_cursor_start_key           = 'g<C-n>'
let g:multi_cursor_select_all_key      = 'g<A-n>'
let g:multi_cursor_next_key            = '<C-n>'
let g:multi_cursor_prev_key            = '<C-p>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => airline
" Show tab number using airline
let g:airline#extensions#tabline#tab_nr_type = 1
" Airline tabs enabled
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline_section_error = '%{airline#util#wrap(airline#extensions#coc#get_error(),0)}'
let g:airline_section_warning = '%{airline#util#wrap(airline#extensions#coc#get_warning(),0)}'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-polyglot

" Set filetypes jsx & tsx
autocmd BufNewFile,BufRead *.jsx set filetype=javascript.jsx
autocmd BufNewFile,BufRead *.tsx set filetype=typescript.tsx
autocmd BufNewFile,BufRead *.vue set filetype=vue
autocmd BufNewFile,BufRead *.sbt set filetype=scala
autocmd BufNewFile,BufRead makefile set filetype=makefile
let g:vue_pre_processors = []

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-closetag

let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.vue,*.jsx,*.tsx'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'
let g:closetag_filetypes = 'html,xhtml,phtml,vue'
let g:closetag_xhtml_filetypes = 'xhtml,jsx,tsx'
let g:closetag_emptyTags_caseSensitive = 1
let g:closetag_regions = {
    \ 'typescript.tsx': 'jsxRegion,tsxRegion',
    \ 'javascript.jsx': 'jsxRegion',
    \ }

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => coc.nvim

 let g:coc_global_extensions=[
     \'coc-vetur',
     \'coc-tsserver',
     \'coc-eslint',
     \'coc-omnisharp',
     \'coc-java',
     \'coc-prettier',
     \'coc-json',
     \'coc-html',
     \'coc-css'
     \]

autocmd FileType vue let b:coc_root_patterns = ['vue.config.js']
autocmd FileType typescript.tsx,javascript.jsx,typescript let b:coc_root_patterns = ['tsconfig.json']

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['cs'], &filetype) >= 0)
    call OmniSharp#TypeLookupWithoutDocumentation()
  elseif (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

augroup coc_general_commands
  autocmd!
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call CocAction('fold', <f-args>)

" Using CocList
" Show all diagnostics
nnoremap <silent> <leader>ca  :<C-u>CocList diagnostics<cr>
" Show commands
nnoremap <silent> <leader>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <leader>co  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <leader>cs  :<C-u>CocList -I symbols<cr>
" Resume latest coc list
nnoremap <silent> <leader>cp  :<C-u>CocListResume<CR>

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use `ap` and `an` to navigate diagnostics
nmap <silent> <leader>ap <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>an <Plug>(coc-diagnostic-next)

" Remap for do codeAction of current line
nmap <silent> <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <silent> <leader>qf  <Plug>(coc-fix-current)

augroup coc__commands
    autocmd!

  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript.tsx,javascript.jsx,typescript,javascript,vue,scala,c,rust setl formatexpr=CocAction('formatSelected')

  " Remap for rename current word
  autocmd FileType typescript.tsx,javascript.jsx,typescript,javascript,vue,scala,c,rust nmap <buffer> <leader>rn <Plug>(coc-rename)
  autocmd FileType typescript.tsx,javascript.jsx,typescript,javascript nmap <buffer> <leader>rw :CocCommand tsserver.organizeImports<CR>
  autocmd FileType typescript.tsx,javascript.jsx,typescript,javascript,vue nmap <buffer> <leader>fx :CocCommand eslint.executeAutofix<CR>
augroup end


" ******* Prettier
command! -nargs=0 Prettier :CocCommand prettier.formatFile
vmap <leader>ff  <Plug>(coc-format-selected)
nmap <leader>ff  <Plug>(coc-format-selected)


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => NERDCommenter
let g:NERDSpaceDelims = 1
let g:ft = ''
nmap gcc <Plug>NERDCommenterToggle
vmap gc <Plug>NERDCommenterSexy

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Misc
" delete without yanking \d
nnoremap <leader><leader>d "_d
" reload buffers
nnoremap <leader>rr :checktime<cr>

au! BufEnter * call SetTabs()

" Universal format mapping
nnoremap <silent> <leader>fd :call FormatCode()<CR>

" Open file
command! -nargs=1 OpenFile :call OpenFileInVsLike(<f-args>)
nnoremap <leader>fo :OpenFile 

" Open angular component
nnoremap <leader>ao :call AngularOpenComponent()<CR>
nnoremap <leader>at :call OpenFileInWdLike(".component.ts", "vs")<CR>
nnoremap <leader>am :call OpenFileInWdLike(".html", "vs")<CR>
nnoremap <leader>as :call OpenFileInWdLike(".scss", "vs")<CR>
" nnoremap <leader>ac :call OpenFileInWdLike(".css", "vs")<CR>

" Create & open folds
let @x='V%zf' " This macro creates a fold using '%'
" nnoremap <silent> <Space> @=(foldlevel('.')?'za':"@x")<CR>
" nnoremap <Space>z zfat
" vnoremap <Space> zf

au! VimLeave * call SaveSession(0)
nnoremap <silent> <F5> :call SaveSession(1)<CR>
nnoremap <silent> <F8> :call LoadSession()<CR>
" Close Hidden Buffers
nnoremap <leader>ch :call DeleteHiddenBuffers()<CR>

command! -nargs=0 UP bufdo e! "command will discard changes and reload files
command! -nargs=0 JK bd
command! -nargs=0 AngularOpenComponent call AngularOpenComponent()
